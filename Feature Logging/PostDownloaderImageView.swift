//
//  PostDownloaderImageView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-23.
//

import Kingfisher
import SwiftSoup
import SwiftUI
import SwiftyBeaver

struct PostDownloaderImageView: View {
    @Environment(\.openURL) private var openURL
    
    @State private var width = 0
    @State private var height = 0
    @State private var data: Data?
    @State private var fileExtension = ".png"
    @State private var scale: Float = 0.000000001
    
    var viewModel: ContentView.ViewModel
    var imageUrl: URL
    var userName: String
    var index: Int
    
    private let logger = SwiftyBeaver.self
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    KFImage(imageUrl)
                        .onSuccess { result in
                            let pixelSize = (result.image.pixelSize ?? result.image.size)
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
                        .interpolation(.high)
                        .antialiased(true)
                        .forceRefresh()
                        .cornerRadius(2)
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
            .cornerRadius(4)
            .background(Color(red: 0.9, green: 0.9, blue: 0.92))
            HStack {
                Button(action: {
                    viewModel.imageValidationImageUrl = imageUrl
                    viewModel.visibleView = .ImageValidationView
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "photo.badge.checkmark.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Validate")
                    }
                }
                .focusable()
                .disabled(data == nil)
                .onKeyPress(.space) {
                    if self.data != nil {
                        viewModel.imageValidationImageUrl = imageUrl
                        viewModel.visibleView = .ImageValidationView
                    }
                    return .handled
                }
                
                Spacer()
                    .frame(width: 10)
                
                Button(action: {
                    saveImage()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Save image")
                    }
                }
                .focusable()
                .disabled(data == nil)
                .onKeyPress(.space) {
                    if data != nil {
                        saveImage()
                    }
                    return .handled
                }
                
                Spacer()
                    .frame(width: 10)
                
                Button(action: {
                    logger.verbose("Tapped copy URL for image URL", context: "User")
                    copyToClipboard(imageUrl.absoluteString)
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the image URL to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Copy URL")
                    }
                }
                .focusable()
                .onKeyPress(.space) {
                    logger.verbose("Pressed space on copy URL for image URL", context: "User")
                    copyToClipboard(imageUrl.absoluteString)
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the image URL to the clipboard")
                    return .handled
                }
                
                Spacer()
                    .frame(width: 10)
                
                Button(action: {
                    logger.verbose("Tapped launch for image URL", context: "User")
                    openURL(imageUrl)
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "globe")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Launch")
                    }
                }
                .focusable()
                .onKeyPress(.space) {
                    logger.verbose("Pressed space on launch for image URL", context: "User")
                    openURL(imageUrl)
                    return .handled
                }
            }
        }
    }
}

extension PostDownloaderImageView {
    // MARK: - utilities
    
    private func saveImage() {
        let folderURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("VERO")
        do {
            if !FileManager.default.fileExists(atPath: folderURL.path, isDirectory: nil) {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            }
            let fileURL = folderURL.appendingPathComponent("\(userName).\(fileExtension)")
            try data!.write(to: fileURL, options: [.atomic, .completeFileProtection])
            logger.verbose("Saved the image to file \(fileURL.path)", context: "System")
            viewModel.showSuccessToast("Saved", "Saved the image to file \(fileURL.lastPathComponent) to your Pictures/VERO folder")
        } catch {
            logger.error("Failed to save the image file: \(error.localizedDescription)", context: "System")
            debugPrint("Failed to save file")
            debugPrint(error.localizedDescription)
            viewModel.showToast(.error, "Failed to save", "Failed to saved the image to your Pictures/VERO folder - \(error.localizedDescription)")
        }
    }
}
