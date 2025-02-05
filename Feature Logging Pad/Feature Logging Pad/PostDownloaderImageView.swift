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
#if os(iOS)
import Photos
#endif

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
#if os(macOS)
                            let pixelSize = (result.image.pixelSize ?? result.image.size)
#else
                            let pixelSize = result.image.size
#endif
#if os(macOS)
                            if let cgImage = result.image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                                let imageRepresentation = NSBitmapImageRep(cgImage: cgImage)
                                imageRepresentation.size = result.image.size
                                data = imageRepresentation.representation(using: .png, properties: [:])
                                fileExtension = ".png"
                            } else {
                                data = result.data()
                                fileExtension = ".jpg"
                            }
#else
                            data = result.data()
                            fileExtension = ".jpg"
#endif
                            width = Int(pixelSize.width)
                            height = Int(pixelSize.height)
                            scale = min(608.0 / Float(result.image.size.width), 448.0 / Float(result.image.size.height))
                        }
                        .interpolation(.high)
                        .antialiased(true)
                        .forceRefresh()
                        .cornerRadius(4)
                }
                .scaleEffect(CGFloat(scale))
                .frame(width: 640, height: 480)
                .clipped()

                Slider(value: $scale, in: 0.01 ... 2)
                    .padding(.horizontal, 16)

                Text("Size: \(width)px x \(height)px")
                    .foregroundStyle(.black, .secondary)
                    .font(.system(size: 12))
            }
            .frame(width: 640, height: 530)
            .padding(.bottom, 8)
            .background(Color(red: 0.9, green: 0.9, blue: 0.92))
            .cornerRadius(8)

            HStack {
                Button(action: {
                    viewModel.imageValidationImageUrl = imageUrl
                    viewModel.visibleView = .ImageValidationView
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "photo.badge.checkmark.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Validate")
                    }
                }
                .disabled(data == nil)
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)
                .padding(.trailing, -20)

                Button(action: {
                    saveImage()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Save image")
                    }
                }
                .disabled(data == nil)
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)
                .padding(.trailing, -20)

                Button(action: {
                    logger.verbose("Tapped copy URL for image URL", context: "User")
                    copyToClipboard(imageUrl.absoluteString)
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the image URL to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy URL")
                    }
                }
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)
                .padding(.trailing, -20)

                Button(action: {
                    logger.verbose("Tapped launch for image URL", context: "User")
                    openURL(imageUrl)
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "globe")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Launch")
                    }
                }
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)
                .padding(.trailing, -20)
            }
            .padding(.leading, 4)
        }
    }

    private func saveImage() {
#if os(macOS)
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
#else
        if let data, let image = UIImage(data: data) {
            let imageSaver = ImageSaver(success: {
                logger.verbose("Saved the image to photo library", context: "System")
                viewModel.showSuccessToast("Saved", "Saved the image to your photo library")
            }, failure: { error in
                logger.error("Failed to save the image file to photo library", context: "System")
                debugPrint("Failed to save file")
                debugPrint(error.localizedDescription)
                viewModel.showToast(.error, "Failed to save", "Failed to saved the image to your photo library - \(error.localizedDescription)")
            })
            imageSaver.writeToPhotoAlbum(image: image)
        }
#endif
    }
}

#if os(iOS)
enum ImageSaverError: Error {
    case NotAuthorized
}

class ImageSaver: NSObject {
    private var success: () -> Void
    private var failure: (_ error: Error) -> Void

    init(
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        self.success = success
        self.failure = failure
    }

    func writeToPhotoAlbum(image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.saveCompleted), nil)
            } else {
                self.failure(ImageSaverError.NotAuthorized)
            }
        }
    }

    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error {
            failure(error)
        } else {
            success()
        }
    }
}
#endif
