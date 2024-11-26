//
//  PostDownloaderImageView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-23.
//

import AlertToast
import Kingfisher
import SwiftSoup
import SwiftUI

struct PostDownloaderImageView: View {
    @State private var width = 0
    @State private var height = 0
    @State private var data: Data?
    @State private var fileExtension = ".png"
    @State private var scale: Float = 0.000000001
    
    var imageUrl: URL
    var name: String
    var index: Int
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void

    var body: some View {
        VStack {
            VStack {
                HStack {
                    KFImage(imageUrl)
                        .onSuccess { result in
                            let pixelSize = (result.image.pixelSize ?? result.image.size)
                            print("result.image: \(pixelSize.width) x \(pixelSize.height)")
                            if let cgImage = result.image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                                let imageRepresentation = NSBitmapImageRep(cgImage: cgImage)
                                imageRepresentation.size = result.image.size
                                data = imageRepresentation.representation(using: .png, properties: [:])
                                fileExtension = ".png"
                            } else {
                                data = result.data()
                                fileExtension = ".jpg"
                            }
                            width = Int(pixelSize.width)
                            height = Int(pixelSize.height)
                            scale = min(400.0 / Float(result.image.size.width), 360.0 / Float(result.image.size.height))
                        }
                        .forceRefresh()
                }
                .scaleEffect(CGFloat(scale))
                .frame(width: 400, height: 360)
                .clipped()
                Slider(value: $scale, in: 0.01...2)
                Text("Size: \(width)px x \(height)px")
                    .foregroundStyle(.black, .secondary)
            }
            .frame(width: 400, height: 410)
            .padding(.all, 4)
            .background(Color(red: 0.9, green: 0.9, blue: 0.92))
            HStack {
                Button(action: {
                    let folderURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("VERO")
                    do {
                        if !FileManager.default.fileExists(atPath: folderURL.path, isDirectory: nil) {
                            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
                        }
                        let fileURL = folderURL.appendingPathComponent("\(name).\(fileExtension)")
                        try data!.write(to: fileURL, options: [.atomic, .completeFileProtection])
                        showToast(
                            .complete(.green),
                            "Saved",
                            String {
                                "Saved the image to file \(fileURL)"
                            },
                            .Success
                        ) {}
                    } catch {
                        print("Failed to save file")
                        debugPrint(error.localizedDescription)
                        showToast(
                            .error(.red),
                            "Failed to save",
                            String {
                                "Failed to saved the image to your Pictures folder - \(error.localizedDescription)"
                            },
                            .Failure
                        ) {}
                    }
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Save image")
                    }
                }
                Spacer()
                    .frame(width: 10)
                Button(action: {
                    copyToClipboard(imageUrl.absoluteString)
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Copy URL")
                    }
                }
            }
        }
    }
}
