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

/// The `PostDownloaderView` provides a view which shows data from a user's post as well as their user profile bio.
///
/// If the post cannot be downloaded, the feature must be done directly from VERO instead. This usually happens when
/// the user's profile is marked as private.
///
struct PostDownloaderView: View {
    @State private var imageUrls: [(URL, String)] = []
    @State private var tagCheck = ""
    @State private var missingTag = false
    @State private var postLoaded = false
    @State private var userLoaded = false
    @State private var description = ""
    @State private var userName = ""
    @State private var logging: [(Color, String)] = []
    @State private var loggingComplete = false
    @State private var userProfileLink = ""
    @State private var userBio = ""

    var pageTitle: Binding<String>
    var pageHashTags: Binding<[String]>
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
                        HStack (alignment: .center) {
                            ValidationLabel("Page: \(pageTitle.wrappedValue)", validation: true, validColor: .green)
                        }
                        .frame(height: 20)
                        HStack (alignment: .center) {
                            ValidationLabel("Page tags: \(pageHashTags.wrappedValue.joined(separator: ", "))", validation: true, validColor: .green)
                        }
                        .frame(height: 20)
                        HStack (alignment: .center) {
                            ValidationLabel("Post URL: \(postUrl.wrappedValue)", validation: true, validColor: .green)
                        }
                        .frame(height: 20)
                        Spacer()
                            .frame(height: 6)
                        HStack {
                            Button(action: {
                                loadFeature()
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                    Text("Load post")
                                }
                            }
                        }
                        Spacer()
                            .frame(height: 6)
                        if postLoaded {
                            HStack (alignment: .center) {
                                ValidationLabel("User name: \(userName)", validation: !userName.isEmpty, validColor: .green)
                                HStack (alignment: .center) {
                                    Button(action: {
                                        //savePostUserName(userName)
                                        copyToClipboard(userName)
                                    }) {
                                        HStack(alignment: .center) {
                                            Image(systemName: "pencil.and.list.clipboard" /*"pencil.line"*/)
                                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                            Text("Copy user name" /* "Save user name" */)
                                        }
                                    }
                                }
                            }
                            .frame(height: 20)
                            if userLoaded {
                                ValidationLabel("User BIO:", validation: !userBio.isEmpty, validColor: .green)
                                if #available(macOS 14.0, *) {
                                    TextEditor(text: .constant(userBio))
                                        .scrollIndicators(.never)
                                        .frame(maxWidth: 640.0, maxHeight: 80.0, alignment: .leading)
                                        .textEditorStyle(.plain)
                                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                        .scrollContentBackground(.hidden)
                                        .padding(4)
                                        .padding([.bottom], 6)
                                        .autocorrectionDisabled(false)
                                        .disableAutocorrection(false)
                                        .font(.system(size: 18, design: .serif))
                                } else {
                                    TextEditor(text: .constant(userBio))
                                        .scrollIndicators(.never)
                                        .frame(maxWidth: 640.0, maxHeight: 80.0, alignment: .leading)
                                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                        .scrollContentBackground(.hidden)
                                        .padding(4)
                                        .padding([.bottom], 6)
                                        .autocorrectionDisabled(false)
                                        .disableAutocorrection(false)
                                        .font(.system(size: 18, design: .serif))
                                }
                            }
                            HStack (alignment: .center) {
                                ValidationLabel(tagCheck, validation: !missingTag, validColor: .green)
                            }
                            .frame(height: 20)
                            HStack (alignment: .center) {
                                ValidationLabel("\(imageUrls.count) image\(imageUrls.count == 1 ? "" : "s") found", validation: imageUrls.count > 0, validColor: .green)
                            }
                            .frame(height: 20)
                            ValidationLabel("Description:", validation: !description.isEmpty, validColor: .green)
                            if #available(macOS 14.0, *) {
                                TextEditor(text: .constant(description))
                                    .scrollIndicators(.never)
                                    .frame(maxWidth: 640.0, maxHeight: 200.0, alignment: .leading)
                                    .textEditorStyle(.plain)
                                    .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                    .scrollContentBackground(.hidden)
                                    .padding(4)
                                    .padding([.bottom], 6)
                                    .autocorrectionDisabled(false)
                                    .disableAutocorrection(false)
                                    .font(.system(size: 14))
                            } else {
                                TextEditor(text: .constant(description))
                                    .scrollIndicators(.never)
                                    .frame(maxWidth: 640.0, maxHeight: 200.0, alignment: .leading)
                                    .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                    .scrollContentBackground(.hidden)
                                    .padding(4)
                                    .padding([.bottom], 6)
                                    .autocorrectionDisabled(false)
                                    .disableAutocorrection(false)
                                    .font(.system(size: 14))
                            }
                            HStack {
                                ForEach (Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                    PostDownloaderImageView(imageUrl: imageUrl.0, name: imageUrl.1, index: index, showToast: showToast)
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
    
    /// Account error enumeration for throwing account-specifc error codes.
    enum AccountError: String, LocalizedError {
        case PrivateAccount = "Could not find any images, this account might be private"
        case MissingImages = "Could not find any images"
        public var errorDescription: String? { self.rawValue }
    }
    
    /// Loads the feature using the postUrl.
    private func loadFeature() -> Void {
        postLoaded = false
        userLoaded = false
        tagCheck = ""
        missingTag = false
        imageUrls = []
        logging = []
        loggingComplete = false
        userProfileLink = ""
        userBio = ""
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
                if let userProfileUrl = try! getMetaTagContent(document, "property", "og:url") {
                    let urlParts = userProfileUrl.split(separator: "/", omittingEmptySubsequences: true)
                    print("User profile parts \(urlParts)")
                    if urlParts.count == 2 {
                        userProfileLink = "https://vero.co/\(urlParts[0])"
                    }
                }
                var hashTags: [String] = []
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
                                let linkText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                                description = description + nextSpace + linkText
                                if linkText.hasPrefix("#") {
                                    hashTags.append(linkText.lowercased())
                                }
                                nextSpace = " "
                            }
                        }
                    }
                }
                var pageHashTagFound = ""
                if hashTags.firstIndex(where: { hashTag in
                    return pageHashTags.wrappedValue.firstIndex(where: { pageHashTag in
                        if hashTag.lowercased() == pageHashTag.lowercased() {
                            pageHashTagFound = pageHashTag.lowercased()
                            return true
                        }
                        return false
                    }) != nil
                }) != nil {
                    tagCheck = "Contains page hashtag \(pageHashTagFound)"
                } else {
                    tagCheck = "MISSING page hashtag!!"
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
                
                // Debugging
                //print(try document.outerHtml())

                if imageUrls.isEmpty && likelyPrivate {
                    throw AccountError.PrivateAccount
                } else if imageUrls.isEmpty {
                    throw AccountError.MissingImages
                }
                
                loadUserProfile();
                
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

    /// Loads the user profile using the userProfileLink.
    private func loadUserProfile() {
        if let url = URL(string: userProfileLink) {
            do {
                let contents = try String(contentsOf: url, encoding: .utf8)
                logging.append((.blue, "Loaded the user profile from the server"))
                let document = try SwiftSoup.parse(contents)
                
                if let description = try! getMetaTagContent(document, "property", "og:description") {
                    userBio = description
                }
                
                // Debugging
                //print(try document.outerHtml())
                
                userLoaded = true
            } catch let error as AccountError {
                logging.append((.red, "Failed to download and parse the user profile information - \(error.errorDescription ?? "unknown")"))
                logging.append((.red, "User info must be handled manually in VERO app"))
                showToast(
                    .error(.red),
                    "Failed to load and parse user profile",
                    String {
                        "Failed to download and parse the user profile information - \(error.errorDescription ?? "unknown")"
                    },
                    3) {}
            } catch {
                logging.append((.red, "Failed to download and parse the user profile information - \(error.localizedDescription)"))
                logging.append((.red, "User info must be handled manually in VERO app"))
                showToast(
                    .error(.red),
                    "Failed to load and parse user profile",
                    String {
                        "Failed to download and parse the user profile information - \(error.localizedDescription)"
                    },
                    3) {}
            }
        }
    }
    
    /// Gets the `content` value of the `meta` tag with the given `key`/`value` pair.
    /// - Parameters:
    ///   - document: The `SoupSwift` document object.
    ///   - key: The key for the match in the `meta` tags.
    ///   - value: The value for the match in the `meta` tags.
    /// - Returns: The `content` value for the meta tag if found.
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
