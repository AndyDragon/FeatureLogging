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
    @Environment(\.openURL) private var openURL

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
    @State private var pageComments: [(String, String, Date?, String)] = []; // Page, Comment, Date
    @State private var hubComments: [(String, String, Date?, String)] = []; // Page, Comment, Date
    @State private var moreComments = false
    @State private var commentCount = 0
    @State private var likeCount = 0
    @State private var loggingComplete = false
    @State private var userProfileLink = ""
    @State private var userBio = ""

    private let languagePrefix = Locale.preferredLanguageCode
    private let mainLabelWidth: CGFloat = -112
    private let labelWidth: CGFloat = 108

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

                ScrollView(.vertical) {
                    VStack {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                // Page scope
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading) {
                                        HStack(alignment: .center) {
                                            ValidationLabel("Page: ", labelWidth: -mainLabelWidth, validation: true, validColor: .green)
                                            ValidationLabel(selectedPage.wrappedValue.displayTitle, validation: true, validColor: .AccentColor)
                                            Spacer()
                                        }
                                        .frame(height: 20)
                                        HStack(alignment: .center) {
                                            ValidationLabel("Page tags: ", labelWidth: -mainLabelWidth, validation: true, validColor: .green)
                                            ValidationLabel(selectedPage.wrappedValue.hashTags.joined(separator: ", "), validation: true, validColor: .AccentColor)
                                            Spacer()
                                        }
                                        .frame(height: 20)
                                        HStack(alignment: .center) {
                                            ValidationLabel("Post URL: ", labelWidth: -mainLabelWidth, validation: !selectedFeature.feature.postLink.wrappedValue.isEmpty, validColor: .green)
                                            ValidationLabel(selectedFeature.feature.postLink.wrappedValue, validation: true, validColor: .AccentColor)
                                            Spacer()
                                            Button(action: {
                                                copyToClipboard(selectedFeature.feature.postLink.wrappedValue)
                                            }) {
                                                HStack(alignment: .center) {
                                                    Image(systemName: "pencil.and.list.clipboard")
                                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                    Text("Copy URL")
                                                }
                                            }
                                            Spacer()
                                                .frame(width: 10)
                                            Button(action: {
                                                if let url = URL(string: selectedFeature.feature.postLink.wrappedValue) {
                                                    openURL(url)
                                                }
                                            }) {
                                                HStack(alignment: .center) {
                                                    Image(systemName: "globe")
                                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                    Text("Launch")
                                                }
                                            }
                                            .disabled(selectedFeature.feature.postLink.wrappedValue.isEmpty)
                                        }
                                        .frame(height: 20)
                                        if userLoaded {
                                            HStack(alignment: .center) {
                                                ValidationLabel("User profile URL: ", labelWidth: -mainLabelWidth, validation: !userProfileLink.isEmpty, validColor: .green)
                                                ValidationLabel(userProfileLink, validation: true, validColor: .AccentColor)
                                                Spacer()
                                                Button(action: {
                                                    copyToClipboard(userProfileLink)
                                                }) {
                                                    HStack(alignment: .center) {
                                                        Image(systemName: "pencil.and.list.clipboard")
                                                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                        Text("Copy URL")
                                                    }
                                                }
                                                Spacer()
                                                    .frame(width: 10)
                                                Button(action: {
                                                    if let url = URL(string: userProfileLink) {
                                                        openURL(url)
                                                    }
                                                }) {
                                                    HStack(alignment: .center) {
                                                        Image(systemName: "globe")
                                                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                        Text("Launch")
                                                    }
                                                }
                                                .disabled(userProfileLink.isEmpty)
                                            }
                                            .frame(height: 20)
                                        }
                                    }
                                    .frame(maxWidth: 1280)
                                    Spacer()
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background {
                                    Rectangle()
                                        .foregroundStyle(Color.BackgroundColorList)
                                        .cornerRadius(8)
                                        .opacity(0.5)
                                }
                                
                                if postLoaded {
                                    // User name and bio
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading) {
                                            HStack(alignment: .center) {
                                                ValidationLabel("User name: ", labelWidth: mainLabelWidth, validation: !userName.isEmpty, validColor: .green)
                                                ValidationLabel(userName, validation: true, validColor: .AccentColor)
                                                Spacer()
                                                ValidationLabel(
                                                    "User name:", labelWidth: labelWidth,
                                                    validation: !selectedFeature.feature.userName.wrappedValue.isEmpty && !selectedFeature.feature.userName.wrappedValue.contains(where: \.isNewline))
                                                HStack(alignment: .center) {
                                                    TextField(
                                                        "enter the user name",
                                                        text: selectedFeature.feature.userName.onChange { value in
                                                            updateList()
                                                            markDocumentDirty()
                                                        }
                                                    )
                                                }
                                                .focusable()
                                                .autocorrectionDisabled(false)
                                                .textFieldStyle(.plain)
                                                .padding(4)
                                                .background(Color.BackgroundColorEditor)
                                                .border(Color.gray.opacity(0.25))
                                                .cornerRadius(4)
                                                .frame(maxWidth: 240)
                                                Button(action: {
                                                    selectedFeature.feature.userName.wrappedValue = userName
                                                }) {
                                                    HStack(alignment: .center) {
                                                        Image(systemName: "pencil.and.list.clipboard" /*"pencil.line"*/)
                                                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                        Text("Transfer")
                                                    }
                                                }
                                                .disabled(userName.isEmpty)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 20)
                                            if userLoaded {
                                                HStack(alignment: .center) {
                                                    ValidationLabel("User BIO:", validation: !userBio.isEmpty, validColor: .green)
                                                    Spacer()
                                                    ValidationLabel("User level:", labelWidth: labelWidth, validation: selectedFeature.feature.userLevel.wrappedValue != MembershipCase.none)
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
                                                    .frame(maxWidth: 240)
                                                }
                                                .frame(maxWidth: .infinity)
                                                if #available(macOS 14.0, *) {
                                                    TextEditor(text: .constant(userBio))
                                                        .scrollIndicators(.never)
                                                        .frame(maxWidth: 640, maxHeight: 80.0, alignment: .leading)
                                                        .textEditorStyle(.plain)
                                                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                                        .scrollContentBackground(.hidden)
                                                        .padding(4)
                                                        .autocorrectionDisabled(false)
                                                        .disableAutocorrection(false)
                                                        .font(.system(size: 18, design: .serif))
                                                } else {
                                                    TextEditor(text: .constant(userBio))
                                                        .scrollIndicators(.never)
                                                        .frame(maxWidth: 640, maxHeight: 80.0, alignment: .leading)
                                                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                                        .scrollContentBackground(.hidden)
                                                        .padding(4)
                                                        .autocorrectionDisabled(false)
                                                        .disableAutocorrection(false)
                                                        .font(.system(size: 18, design: .serif))
                                                }
                                            }
                                        }
                                        .frame(maxWidth: 1280)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.BackgroundColorList)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }
                                    
                                    // Tag check and description
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading) {
                                            HStack(alignment: .center) {
                                                ValidationLabel(tagCheck, validation: !missingTag, validColor: .green)
                                                Spacer()
                                            }
                                            .frame(height: 20)
                                            HStack(alignment: .center) {
                                                ValidationLabel("Post description:", validation: !description.isEmpty, validColor: .green)
                                                Spacer()
                                                ValidationLabel("Description:", labelWidth: labelWidth, validation: !selectedFeature.feature.featureDescription.wrappedValue.isEmpty)
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
                                                .frame(maxWidth: 320)
                                            }
                                            .frame(maxWidth: .infinity)
                                            if #available(macOS 14.0, *) {
                                                TextEditor(text: .constant(description))
                                                    .scrollIndicators(.never)
                                                    .frame(maxWidth: 800, maxHeight: 200.0, alignment: .leading)
                                                    .textEditorStyle(.plain)
                                                    .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                                    .scrollContentBackground(.hidden)
                                                    .padding(4)
                                                    .autocorrectionDisabled(false)
                                                    .disableAutocorrection(false)
                                                    .font(.system(size: 14))
                                            } else {
                                                TextEditor(text: .constant(description))
                                                    .scrollIndicators(.never)
                                                    .frame(maxWidth: 800, maxHeight: 200.0, alignment: .leading)
                                                    .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                                    .scrollContentBackground(.hidden)
                                                    .padding(4)
                                                    .autocorrectionDisabled(false)
                                                    .disableAutocorrection(false)
                                                    .font(.system(size: 14))
                                            }
                                        }
                                        .frame(maxWidth: 1280)
                                        Spacer()
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.BackgroundColorList)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }
                                    
                                    // Page and hub comments
                                    if !pageComments.isEmpty || !hubComments.isEmpty {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading) {
                                                if !pageComments.isEmpty {
                                                    HStack(alignment: .center) {
                                                        ValidationLabel("Found comments from page: ", validation: true, validColor: .red)
                                                        Spacer()
                                                        Toggle(
                                                            isOn: selectedFeature.feature.photoFeaturedOnPage.onChange { value in
                                                                updateList()
                                                                markDocumentDirty()
                                                            }
                                                        ) {
                                                            Text("Photo already featured on page")
                                                                .lineLimit(1)
                                                                .truncationMode(.tail)
                                                        }
                                                        .tint(Color.AccentColor)
                                                        .accentColor(Color.AccentColor)
                                                        .focusable()
                                                    }
                                                    .frame(height: 20)
                                                    ScrollView {
                                                        ForEach(pageComments.sorted { $0.2 ?? .distantPast < $1.2 ?? .distantPast }, id: \.0) { comment in
                                                            HStack(alignment: .center) {
                                                                Text("\(comment.0) [\(comment.2.formatTimestamp())]: \(comment.1)")
                                                                    .foregroundStyle(.red, .black)
                                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                                Spacer()
                                                                    .frame(width: 10)
                                                                Button(action: {
                                                                    selectedFeature.feature.photoFeaturedOnPage.wrappedValue = true
                                                                }) {
                                                                    HStack(alignment: .center) {
                                                                        Image(systemName: "checkmark.square")
                                                                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                                        Text("Mark post")
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .frame(maxHeight: 40)
                                                }
                                                if !pageComments.isEmpty && !hubComments.isEmpty {
                                                    Divider()
                                                }
                                                if !hubComments.isEmpty {
                                                    HStack(alignment: .center) {
                                                        ValidationLabel("Found comments from hub: ", validation: true, validColor: .orange)
                                                        Spacer()
                                                        Toggle(
                                                            isOn: selectedFeature.feature.photoFeaturedOnHub.onChange { value in
                                                                updateList()
                                                                markDocumentDirty()
                                                            }
                                                        ) {
                                                            Text("Photo featured on hub")
                                                                .lineLimit(1)
                                                                .truncationMode(.tail)
                                                        }
                                                        .tint(Color.AccentColor)
                                                        .accentColor(Color.AccentColor)
                                                        .focusable()
                                                        
                                                        if selectedFeature.feature.photoFeaturedOnHub.wrappedValue {
                                                            Text("|")
                                                                .padding([.leading, .trailing], 8)
                                                            
                                                            ValidationLabel(
                                                                "Last date featured:",
                                                                validation: !(selectedFeature.feature.photoLastFeaturedOnHub.wrappedValue.isEmpty || selectedFeature.feature.photoLastFeaturedPage.wrappedValue.isEmpty)
                                                            )
                                                            TextField(
                                                                "",
                                                                text: selectedFeature.feature.photoLastFeaturedOnHub.onChange { value in
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
                                                            
                                                            TextField(
                                                                "on page",
                                                                text: selectedFeature.feature.photoLastFeaturedPage.onChange { value in
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
                                                    }
                                                    .frame(height: 20)
                                                    ScrollView {
                                                        ForEach(hubComments.sorted { $0.2 ?? .distantPast < $1.2 ?? .distantPast }, id: \.0) { comment in
                                                            HStack(alignment: .center) {
                                                                Text("\(comment.0) [\(comment.2.formatTimestamp())]: \(comment.1)")
                                                                    .foregroundStyle(.orange, .black)
                                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                                Spacer()
                                                                    .frame(width: 10)
                                                                Button(action: {
                                                                    selectedFeature.feature.photoFeaturedOnHub.wrappedValue = true
                                                                    selectedFeature.feature.photoLastFeaturedPage.wrappedValue = comment.3
                                                                    selectedFeature.feature.photoLastFeaturedOnHub.wrappedValue = comment.2.formatTimestamp()
                                                                }) {
                                                                    HStack(alignment: .center) {
                                                                        Image(systemName: "checkmark.square")
                                                                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                                        Text("Mark post")
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    .frame(maxHeight: 40)
                                                }
                                                if moreComments {
                                                    Divider()
                                                    HStack(alignment: .center) {
                                                        ValidationLabel("There were more comments than downloaded in the post, open the post IN VERO to check to previous features.", validation: true, validColor: .orange)
                                                        Spacer()
                                                    }
                                                    .frame(height: 20)
                                                }
                                            }
                                            .frame(maxWidth: 1280)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background {
                                            Rectangle()
                                                .foregroundStyle(Color.BackgroundColorList)
                                                .cornerRadius(8)
                                                .opacity(0.5)
                                        }
                                    } else if moreComments {
                                        HStack(alignment: .top) {
                                            VStack(alignment: .leading) {
                                                HStack(alignment: .center) {
                                                    ValidationLabel("There were more comments than downloaded in the post, open the post IN VERO to check to previous features.", validation: true, validColor: .orange)
                                                    Spacer()
                                                }
                                                .frame(height: 20)
                                            }
                                            .frame(maxWidth: 1280)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background {
                                            Rectangle()
                                                .foregroundStyle(Color.BackgroundColorList)
                                                .cornerRadius(8)
                                                .opacity(0.5)
                                        }
                                    }
                                    
                                    // Images
                                    VStack(alignment: .leading) {
                                        HStack(alignment: .center) {
                                            ValidationLabel("Image\(imageUrls.count == 1 ? "" : "s") found: ", validation: imageUrls.count > 0, validColor: .green)
                                            ValidationLabel("\(imageUrls.count)", validation: imageUrls.count > 0, validColor: .AccentColor)
                                            Spacer()
                                        }
                                        .frame(height: 20)
                                        ScrollView(.horizontal) {
                                            HStack {
                                                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                                    PostDownloaderImageView(imageUrl: imageUrl.0, name: imageUrl.1, index: index, showToast: showToast)
                                                        .padding(.all, 0.001)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.BackgroundColorList)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }
                                }
                                
                                if loggingComplete {
                                    // Logging
                                    VStack(alignment: .leading) {
                                        ValidationLabel("LOGGING: ", validation: true, validColor: .orange)
                                        ScrollView {
                                            ForEach(Array(logging.enumerated()), id: \.offset) { index, log in
                                                Text(log.1)
                                                    .foregroundStyle(log.0, .black)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.BackgroundColorList)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }
                                }
                            }
                            .padding(10)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
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
        pageComments = [];
        hubComments = [];
        moreComments = false
        commentCount = 0
        likeCount = 0
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
                
                for item in try document.select("script") {
                    do {
                        let scriptText = try item.html().trimmingCharacters(in: .whitespaces)
                        if !scriptText.isEmpty {
                            //print(scriptText)
                            let scriptLines = scriptText.split(whereSeparator: \.isNewline)
                            if scriptLines.first!.hasPrefix("window.__staticRouterHydrationData = JSON.parse(") {
                                let prefixLength = "window.__staticRouterHydrationData = JSON.parse(".count
                                let start = scriptText.index(scriptText.startIndex, offsetBy: prefixLength + 1)
                                let end = scriptText.index(scriptText.endIndex, offsetBy: -3)
                                let jsonString = String(scriptText[start..<end])
                                    .replacingOccurrences(of: "\\\"", with: "\"")
                                    .replacingOccurrences(of: "\\\"", with: "\"")
                                print(jsonString)
                                if let jsonData = jsonString.data(using: .utf8) {
                                    let postData = try JSONDecoder().decode(PostData.self, from: jsonData)
                                    if let post = postData.loaderData?.index0?.post {
                                        if viewModel.selectedPage!.hub == "click" || viewModel.selectedPage!.hub == "snap" {
                                            commentCount = post.post?.comments ?? 0
                                            likeCount = post.post?.likes ?? 0
                                            if let comments = post.comments {
                                                moreComments = comments.count < commentCount
                                                for comment in comments {
                                                    if let userName = comment.author?.username {
                                                        if userName.lowercased().hasPrefix("\(viewModel.selectedPage!.hub.lowercased())_") {
                                                            if userName.lowercased() == viewModel.selectedPage!.displayName.lowercased() {
                                                                pageComments.append((
                                                                    comment.author?.firstname ?? userName,
                                                                    comment.text ?? "",
                                                                    (comment.timestamp ?? "").timestamp(),
                                                                    String(userName[userName.index(userName.startIndex, offsetBy: viewModel.selectedPage!.hub.count + 1)..<userName.endIndex].lowercased())
                                                                ))
                                                                print("!!! PAGE COMMENT from \(comment.author?.firstname ?? "missing") (\(userName))")
                                                            } else {
                                                                hubComments.append((
                                                                    comment.author?.firstname ?? userName,
                                                                    comment.text ?? "",
                                                                    (comment.timestamp ?? "").timestamp(),
                                                                    String(userName[userName.index(userName.startIndex, offsetBy: viewModel.selectedPage!.hub.count + 1)..<userName.endIndex].lowercased())
                                                                ))
                                                                print("HUB COMMENT from \(comment.author?.firstname ?? "missing") (\(userName))")
                                                            }
                                                        } else {
                                                            print("Comment from \(comment.author?.firstname ?? "missing") (\(userName))")
                                                        }
                                                    }
                                                }
                                            } else {
                                                moreComments = commentCount != 0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        debugPrint(error.localizedDescription)
                        showToast(
                            .error(.orange),
                            "Failed to parse the post data on the post",
                            String {
                                "Failed to parse the post information from the downloaded post - \(error.localizedDescription)"
                            },
                            .Failure
                        ) {}
                    }
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
