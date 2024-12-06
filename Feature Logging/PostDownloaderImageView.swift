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
    @Environment(\.openURL) private var openURL

    @State private var width = 0
    @State private var height = 0
    @State private var data: Data?
    @State private var fileExtension = ".png"
    @State private var scale: Float = 0.000000001

    var imageUrl: URL
    var userName: String
    var index: Int
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void
    var showImageValidationView: (_ imageUrl: URL) -> Void

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
                    showImageValidationView(imageUrl)
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
                        showImageValidationView(imageUrl)
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
                    copyToClipboard(imageUrl.absoluteString)
                    showToast(.complete(.green), "Copied to clipboard", "Copied the image URL to the clipboard", .Success) {}
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Copy URL")
                    }
                }
                .focusable()
                .onKeyPress(.space) {
                    copyToClipboard(imageUrl.absoluteString)
                    showToast(.complete(.green), "Copied to clipboard", "Copied the image URL to the clipboard", .Success) {}
                    return .handled
                }
                Spacer()
                    .frame(width: 10)
                Button(action: {
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
                    openURL(imageUrl)
                    return .handled
                }
            }
        }
    }
    
    private func saveImage() {
        let folderURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("VERO")
        do {
            if !FileManager.default.fileExists(atPath: folderURL.path, isDirectory: nil) {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            }
            let fileURL = folderURL.appendingPathComponent("\(userName).\(fileExtension)")
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
            debugPrint("Failed to save file")
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
    }
}
