//
//  PostDownloaderView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-22.
//

import SwiftUI
import SwiftSoup
import Kingfisher
import AlertToast

struct PostDownloaderView: View {
    @State private var imageUrls: [(URL, String)] = []
    @State private var tagCheck = ""
    @State private var missingTag = false
    @State private var postLoaded = false
    @State private var description = ""
    @State private var userName = ""
    @State private var logging: [(Color, String)] = []
    @State private var loggingComplete = false

    var page: Binding<String>
    var postUrl: Binding<String>
    var isShowingToast: Binding<Bool>
    var hideDownloaderView: () -> Void
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void
    var savePostUserName: (_ userName: String) -> Void

    private let languagePrefix = Locale.preferredLanguageCode

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Page: \(page.wrappedValue)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Post URL: \(postUrl.wrappedValue)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HStack {
                            Button(action: {
                                loadFeature()
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(Color.primary, Color.accentColor)
                                    Text("Load post")
                                }
                            }
                        }
                        if postLoaded {
                            HStack {
                                ValidationLabel("User name: \(userName)", validation: !userName.isEmpty, validColor: .green)
                                HStack {
                                    Button(action: {
                                        //savePostUserName(userName)
                                        copyToClipboard(userName)
                                    }) {
                                        HStack(alignment: .center) {
                                            Image(systemName: "pencil.and.list.clipboard" /*"pencil.line"*/)
                                                .foregroundStyle(Color.primary, Color.accentColor)
                                            Text("Copy user name" /* "Save user name" */)
                                        }
                                    }
                                }
                            }
                            ValidationLabel("Page tag: \(tagCheck)", validation: !missingTag, validColor: .green)
                            ValidationLabel("\(imageUrls.count) image\(imageUrls.count == 1 ? "" : "s") found", validation: imageUrls.count > 0, validColor: .green)
                            TextEditor(text: .constant(description))
                                .scrollIndicators(.automatic)
                                .frame(maxWidth: 640.0, maxHeight: 320.0, alignment: .leading)
                            HStack {
                                ForEach (Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                    ImageView(imageUrl: imageUrl.0, name: imageUrl.1, index: index, showToast: showToast)
                                        .padding(.all, 0.001)
                                }
                            }
                        }
                        if loggingComplete {
                            VStack {
                                Text("LOGGING:")
                                    .foregroundStyle(.orange, .black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                ForEach (Array(logging.enumerated()), id: \.offset) { index, log in
                                    Text(log.1)
                                        .foregroundStyle(log.0, .black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
            .padding()
            .toolbar {
                Button(action: {
                    hideDownloaderView()
                }) {
                    HStack {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Close")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                        Text(languagePrefix == "en" ? "    ⌘ `" : "    ⌘ ⌥ x")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.TextColorSecondary)
                    }
                    .padding(4)
                    .buttonStyle(.plain)
                }
                .keyboardShortcut(languagePrefix == "en" ? "`" : "x", modifiers: languagePrefix == "en" ? .command : [.command, .option])
                .disabled(isShowingToast.wrappedValue)
            }
            .allowsHitTesting(!isShowingToast.wrappedValue)
        }
        .frame(minWidth: 1024, minHeight: 600)
        .background(Color.BackgroundColor)
        .onAppear {
            loadFeature()
        }
    }
    
    enum AccountError: String, LocalizedError {
        case PrivateAccount = "Could not find any images, this account might be private"
        case MissingImages = "Could not find any images"
        public var errorDescription: String? { self.rawValue }
    }
    
    private func loadFeature() {
        postLoaded = false
        tagCheck = ""
        missingTag = false
        imageUrls = []
        logging = []
        loggingComplete = false
        var likelyPrivate = false
        if let url = URL(string: postUrl.wrappedValue) {
            do {
                let contents = try String(contentsOf: url, encoding: .utf8)
                logging.append((.blue, "Loaded the post from the server"))
                let document = try SwiftSoup.parse(contents)
                if let user = try! getMetaTagContent(document, "name", "username") {
                    print("User: \(user)")
                    logging.append((.blue, "User: \(user)"))
                }
                userName = ""
                if let title = try! getMetaTagContent(document, "property", "og:title") {
                    if title.hasSuffix(" shared a photo on VERO™") {
                        userName = title.replacingOccurrences(of: " shared a photo on VERO™", with: "")
                        print("User's name: \(userName)")
                        logging.append((.blue, "User's name: \(userName)"))
                    } else if title.hasSuffix(" shared photos on VERO™") {
                        userName = title.replacingOccurrences(of: " shared photos on VERO™", with: "")
                        print("User's name: \(userName)")
                        logging.append((.blue, "User's name: \(userName)"))
                    } else if title.hasSuffix(" on VERO™") {
                        userName = title.replacingOccurrences(of: " on VERO™", with: "")
                        print("User's name: \(userName)")
                        logging.append((.blue, "User's name: \(userName)"))
                        likelyPrivate = true
                    }
                }
                if let captionsDiv = try! document.body()?.getElementsByTag("div").first(where: { element in
                    do {
                        return try element.classNames().contains(where: { className in
                            return className.hasPrefix("_user-post-captions")
                        })
                    } catch {
                        return false
                    }
                }) {
                    description = ""
                    var nextSpace = ""
                    captionsDiv.children().forEach { element in
                        if (element.tagNameNormal() == "span") {
                            let text = try! element.text()
                            if !text.isEmpty {
                                description = description + nextSpace + text.trimmingCharacters(in: .whitespacesAndNewlines)
                                nextSpace = " "
                            }
                        } else if (element.tagNameNormal() == "br") {
                            description = description + "\n"
                            nextSpace = ""
                        } else if (element.tagNameNormal() == "a") {
                            let text = try! element.text()
                            if !text.isEmpty {
                                description = description + nextSpace + text.trimmingCharacters(in: .whitespacesAndNewlines)
                                nextSpace = " "
                            }
                        }
                    }
                }
                if description.contains("#\(page.wrappedValue)") {
                    tagCheck = "Contains page tag #\(page.wrappedValue)"
                } else {
                    tagCheck = "MISSING page tag #\(page.wrappedValue)!!"
                    missingTag = true
                }
                if let imagesInBody = try! document.body()?.getElementsByTag("img") {
                    let carouselImages = imagesInBody.filter({ image in
                        do {
                            return try image.classNames().contains(where: { className in
                                return className.hasPrefix("_carousel-image")
                            })
                        } catch {
                            return false
                        }
                    })
                    imageUrls = carouselImages.map({ image in
                        var imageSrc = try! image.attr("src")
                        if imageSrc.hasSuffix("_thumb.jpg") {
                            imageSrc = imageSrc.replacingOccurrences(of: "_thumb.jpg", with: "")
                        } else if imageSrc.hasSuffix("_thumb.png") {
                            imageSrc = imageSrc.replacingOccurrences(of: "_thumb.png", with: "")
                        }
                        print("Image source: \(imageSrc)")
                        logging.append((.blue, "Image source: \(imageSrc)"))
                        return (URL(string: imageSrc)!, userName)
                    })
                }
                
                if imageUrls.isEmpty && likelyPrivate {
                    throw AccountError.PrivateAccount
                } else if imageUrls.isEmpty {
                    throw AccountError.MissingImages
                }
                
                // Debugging
                //print(try document.outerHtml())
                
                postLoaded = true
            } catch let error as AccountError {
                logging.append((.red, "Failed to download and parse the post information - \(error.errorDescription ?? "unknown")"))
                logging.append((.red, "Post must be handled manually in VERO app"))
                showToast(
                    .error(.red),
                    "Failed to load and parse post",
                    String {
                        "Failed to download and parse the post information - \(error.errorDescription ?? "unknown")"
                    },
                    3) {}
            } catch {
                logging.append((.red, "Failed to download and parse the post information - \(error.localizedDescription)"))
                logging.append((.red, "Post must be handled manually in VERO app"))
                showToast(
                    .error(.red),
                    "Failed to load and parse post",
                    String {
                        "Failed to download and parse the post information - \(error.localizedDescription)"
                    },
                    3) {}
            }
            loggingComplete = true
        }
    }
    
    private func getMetaTagContent(_ document: Document, _ key: String, _ value: String) throws -> String? {
        let headMetaTags = try document.head()?.getElementsByTag("meta")
        let ogImageTag = headMetaTags?.first(where: { element in
            do {
                let tagProperty = try element.attr(key)
                return tagProperty == value
            } catch {
                return false
            }
        })
        return try! ogImageTag?.attr("content")
    }
}

private struct ImageView : View {
    @State private var width = 0
    @State private var height = 0
    @State private var data: Data?
    @State private var scale: Float = 0.0000001
    var imageUrl: URL
    var name: String
    var index: Int
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void

    var body: some View {
        VStack {
            VStack {
                HStack {
                    KFImage(imageUrl).onSuccess { result in
                        print("\(result.image.size.width) x \(result.image.size.height)")
                        width = Int(result.image.size.width)
                        height = Int(result.image.size.height)
                        scale = min(400.0 / Float(width), 360.0 / Float(height))
                        data = result.data()!
                    }
                }
                .scaleEffect(CGFloat(scale))
                .frame(width: 400, height: 360)
                .clipped()
                Slider(value: $scale, in: 0.01...1)
                Text("Size: \(width) x \(height)")
                    .foregroundStyle(.black, .secondary)
            }
            .frame(width: 400, height: 410)
            .padding(.all, 4)
            .background(Color.white)
            Button("Save") {
                let folderURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0].appendingPathComponent("VERO")
                do {
                    if !FileManager.default.fileExists(atPath: folderURL.path, isDirectory: nil) {
                        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
                    }
                    let fileURL = folderURL.appendingPathComponent("\(name).png")
                    try data!.write(to: fileURL)
                    showToast(
                        .complete(.green),
                        "Saved",
                        String {
                            "Saved the image to file \(fileURL)"
                        },
                        3) {}
                } catch {
                    print("Failed to save file")
                    debugPrint(error.localizedDescription)
                    showToast(
                        .error(.red),
                        "Failed to save",
                        String {
                            "Failed to saved the image to your Pictures folder - \(error.localizedDescription)"
                        },
                        3) {}
                }
            }
        }
    }
}
