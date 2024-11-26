//
//  PostDownloaderView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-22.
//

import AlertToast
import Kingfisher
import SwiftSoup
import SwiftUI

/// The `PostDownloaderView` provides a view which shows data from a user's post as well as their user profile bio.
///
/// If the post cannot be downloaded, the feature must be done directly from VERO instead. This usually happens when
/// the user's profile is marked as private.
///
struct PostDownloaderView: View {
    @State private var viewModel: ContentView.ViewModel
    @State private var isShowingToast: Binding<Bool>
    private var hideDownloaderView: () -> Void
    private var updateList: () -> Void
    private var markDocumentDirty: () -> Void
    private var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void
    
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
    
    private let languagePrefix = Locale.preferredLanguageCode
    
    init(
        _ viewModel: ContentView.ViewModel,
        _ isShowingToast: Binding<Bool>,
        _ hideDownloaderView: @escaping () -> Void,
        _ updateList: @escaping () -> Void,
        _ markDocumentDirty: @escaping () -> Void,
        _ showToast: @escaping (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void
    ) {
        self.viewModel = viewModel
        self.isShowingToast = isShowingToast
        self.hideDownloaderView = hideDownloaderView
        self.updateList = updateList
        self.markDocumentDirty = markDocumentDirty
        self.showToast = showToast
    }

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)

            if viewModel.selectedPage != nil && viewModel.selectedFeature != nil {
                let selectedPage = Binding<LoadedPage>(
                    get: { viewModel.selectedPage! },
                    set: { viewModel.selectedPage = $0 }
                )
                
                let selectedFeature = Binding<SharedFeature>(
                    get: { viewModel.selectedFeature! },
                    set: { viewModel.selectedFeature = $0 }
                )
                
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            HStack(alignment: .center) {
                                ValidationLabel("Page: \(selectedPage.wrappedValue.displayTitle)", validation: true, validColor: .green)
                            }
                            .frame(height: 20)
                            HStack(alignment: .center) {
                                ValidationLabel("Page tags: \(selectedPage.wrappedValue.hashTags.joined(separator: ", "))", validation: true, validColor: .green)
                            }
                            .frame(height: 20)
                            HStack(alignment: .center) {
                                ValidationLabel("Post URL: \(selectedFeature.feature.postLink.wrappedValue)", validation: true, validColor: .green)
                            }
                            .frame(height: 20)
                            Spacer()
                                .frame(height: 6)
                            if postLoaded {
                                HStack(alignment: .top) {
                                    ValidationLabel("User name: \(userName)", validation: !userName.isEmpty, validColor: .green)
                                    Spacer()
                                    HStack(alignment: .center) {
                                        Button(action: {
                                            selectedFeature.feature.userName.wrappedValue = userName
                                        }) {
                                            HStack(alignment: .center) {
                                                Image(systemName: "pencil.and.list.clipboard" /*"pencil.line"*/)
                                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                Text("Set user name")
                                            }
                                        }
                                    }
                                    TextField(
                                        "enter the user name",
                                        text: selectedFeature.feature.userName.onChange { value in
                                            updateList()
                                            markDocumentDirty()
                                        }
                                    )
                                    .focusable()
                                    .autocorrectionDisabled(false)
                                    .textFieldStyle(.plain)
                                    .padding(4)
                                    .background(Color.BackgroundColorEditor)
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .frame(maxWidth: 160)
                                }
                                .frame(maxWidth: 640)
                                .frame(height: 20)
                                if userLoaded {
                                    HStack(alignment: .top) {
                                        ValidationLabel("User BIO:", validation: !userBio.isEmpty, validColor: .green)
                                        Spacer()
                                        Picker(
                                            "",
                                            selection: selectedFeature.feature.userLevel.onChange { value in
                                                markDocumentDirty()
                                            }
                                        ) {
                                            ForEach(MembershipCase.casesFor(hub: selectedPage.hub.wrappedValue)) { level in
                                                Text(level.rawValue)
                                                    .tag(level)
                                                    .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                                            }
                                        }
                                        .tint(Color.AccentColor)
                                        .accentColor(Color.AccentColor)
                                        .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                                        .focusable()
                                        .frame(maxWidth: 160)
                                    }
                                    .frame(maxWidth: 640)
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
                                HStack(alignment: .center) {
                                    ValidationLabel(tagCheck, validation: !missingTag, validColor: .green)
                                }
                                .frame(height: 20)
                                HStack(alignment: .center) {
                                    ValidationLabel("\(imageUrls.count) image\(imageUrls.count == 1 ? "" : "s") found", validation: imageUrls.count > 0, validColor: .green)
                                }
                                .frame(height: 20)
                                HStack(alignment: .top) {
                                    ValidationLabel("Description:", validation: !description.isEmpty, validColor: .green)
                                    Spacer()
                                    TextField(
                                        "enter the description",
                                        text: selectedFeature.feature.featureDescription.onChange { value in
                                            markDocumentDirty()
                                        }
                                    )
                                    .focusable()
                                    .autocorrectionDisabled(false)
                                    .textFieldStyle(.plain)
                                    .padding(4)
                                    .background(Color.BackgroundColorEditor)
                                    .border(Color.gray.opacity(0.25))
                                    .cornerRadius(4)
                                    .frame(maxWidth: 160)
                                }
                                .frame(maxWidth: 640)
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
                                    ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
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
                                    ForEach(Array(logging.enumerated()), id: \.offset) { index, log in
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
    private func loadFeature() {
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
        if let url = URL(string: viewModel.selectedFeature!.feature.postLink) {
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
                        if element.tagNameNormal() == "span" {
                            let text = try! element.text()
                            if !text.isEmpty {
                                description = description + nextSpace + text.trimmingCharacters(in: .whitespacesAndNewlines)
                                nextSpace = " "
                            }
                        } else if element.tagNameNormal() == "br" {
                            description = description + "\n"
                            nextSpace = ""
                        } else if element.tagNameNormal() == "a" {
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
                let pageHashTags = viewModel.selectedPage!.hashTags
                if hashTags.firstIndex(where: { hashTag in
                    return pageHashTags.firstIndex(where: { pageHashTag in
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

                loadUserProfile()

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
                    .Failure
                ) {}
            } catch {
                logging.append((.red, "Failed to download and parse the post information - \(error.localizedDescription)"))
                logging.append((.red, "Post must be handled manually in VERO app"))
                showToast(
                    .error(.red),
                    "Failed to load and parse post",
                    String {
                        "Failed to download and parse the post information - \(error.localizedDescription)"
                    },
                    .Failure
                ) {}
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
                    .Failure
                ) {}
            } catch {
                logging.append((.red, "Failed to download and parse the user profile information - \(error.localizedDescription)"))
                logging.append((.red, "User info must be handled manually in VERO app"))
                showToast(
                    .error(.red),
                    "Failed to load and parse user profile",
                    String {
                        "Failed to download and parse the user profile information - \(error.localizedDescription)"
                    },
                    .Failure
                ) {}
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
