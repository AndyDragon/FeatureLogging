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
                                Text(userName)
                                    .foregroundStyle(userName.isEmpty ? .red : .green, .black)
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
                            TextEditor(text: .constant(description))
                                .scrollIndicators(.automatic)
                                .frame(maxWidth: 640.0, maxHeight: 320.0, alignment: .leading)
                            Text(tagCheck)
                                .foregroundStyle(missingTag ? .red : .green, .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(imageUrls.count) image\(imageUrls.count == 1 ? "" : "s") found")
                                .foregroundStyle(imageUrls.count == 0 ? .red : .green, .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                ForEach (Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                    ImageView(imageUrl: imageUrl.0, name: imageUrl.1, index: index, showToast: showToast)
                                        .padding(.all, 0.001)
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
    
    private func loadFeature() {
        postLoaded = false
        tagCheck = ""
        missingTag = false
        imageUrls = []
        if let url = URL(string: postUrl.wrappedValue) {
            do {
                let contents = try String(contentsOf: url, encoding: .utf8)
                let document = try SwiftSoup.parse(contents)
                if let user = try! getMetaTagContent(document, "name", "username") {
                    print("User: \(user)")
                }
                userName = ""
                if let title = try! getMetaTagContent(document, "property", "og:title") {
                    if title.hasSuffix(" shared a photo on VERO™") {
                        userName = title.replacingOccurrences(of: " shared a photo on VERO™", with: "")
                        print("User's name: \(userName)")
                    } else if title.hasSuffix(" shared photos on VERO™") {
                        userName = title.replacingOccurrences(of: " shared photos on VERO™", with: "")
                        print("User's name: \(userName)")
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
                        }
                        print(imageSrc)
                        return (URL(string: imageSrc)!, userName)
                    })
                }
                
                // let body = try document.outerHtml()
                // print(body)
                
                postLoaded = true
            } catch {
                showToast(
                    .error(.red),
                    "Failed to load and parse post",
                    String {
                        "Failed to download and parse the post information - \(error.localizedDescription)"
                    },
                    3) {}
            }
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
    var imageUrl: URL
    var name: String
    var index: Int
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void

    var body: some View {
        VStack {
            VStack {
                KFImage(imageUrl).onSuccess { result in
                    print("\(result.image.size.width) x \(result.image.size.height)")
                    width = Int(result.image.size.width)
                    height = Int(result.image.size.height)
                    data = result.data()!
                }
                .resizable()
                .frame(width: 360, height: 360)
                Text("Size: \(width) x \(height)")
                    .foregroundStyle(.black, .secondary)
            }
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
