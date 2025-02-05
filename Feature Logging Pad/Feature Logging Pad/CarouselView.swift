//
//  CarouselView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2025-02-05.
//

import SwiftUI

struct CarouselView: View {
    var viewModel: ContentView.ViewModel
    var images: [URL]
    var userName: String

    @State private var selectedImageIndex: Int = 0
    @State private var width = 0
    @State private var height = 0
    @State private var data: Data?
    @State private var fileExtension = ".png"

    var body: some View {
        VStack {
            if selectedImageIndex >= 0 && selectedImageIndex < images.count {
                PostDownloaderImageView(
                    viewModel: viewModel,
                    imageUrl: images[selectedImageIndex],
                    userName: userName,
                    index: selectedImageIndex)
            }

            if images.count > 1 {
                HStack(alignment: .center) {
                    Button(action: {
                        selectedImageIndex = (selectedImageIndex + (images.count - 1)) % images.count
                    }) {
                        Image(systemName: "arrowtriangle.left.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.accentColor.opacity((selectedImageIndex > 0) ? 1 : 0.33))
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing)
                    .disabled(selectedImageIndex == 0)

                    ForEach(0..<images.count, id: \.self) { index in
                        Capsule()
                            .fill(Color.accentColor.opacity(selectedImageIndex == index ? 1 : 0.33))
                            .frame(width: 28, height: 12)
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                    }

                    Button(action: {
                        selectedImageIndex = (selectedImageIndex + 1) % images.count
                    }) {
                        Image(systemName: "arrowtriangle.right.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.accentColor.opacity((selectedImageIndex < images.count - 1) ? 1 : 0.33))
                    }
                    .buttonStyle(.borderless)
                    .padding(.leading)
                    .disabled(selectedImageIndex == images.count - 1)
                }
            }
        }
        .padding()
    }
}

#Preview {
    let viewModel = ContentView.ViewModel()
    CarouselView(
        viewModel: viewModel,
        images: [
            URL(string: "https://d1dpu3msttfsqg.cloudfront.net/9f958950-713a-11e9-a7f4-a9050a1da8d8/9c4cd26d-07f1-4044-b099-f46799959f60")!,
            URL(string: "https://d1dpu3msttfsqg.cloudfront.net/9f958950-713a-11e9-a7f4-a9050a1da8d8/89a6a2b0-f037-420a-8085-d5a39c0f5032")!
        ],
        userName: "AndyDragon Photography")
}
