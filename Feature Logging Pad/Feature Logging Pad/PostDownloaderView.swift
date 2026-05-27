//
//  PostDownloaderView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-22.
//

import Kingfisher
import SwiftSoup
import SwiftUI
import SwiftyBeaver

/// The `PostDownloaderView` provides a view which shows data from a user's post as well as their user profile bio.
///
/// If the post cannot be downloaded, the feature must be done directly from VERO instead. This usually happens when
/// the user's profile is marked as private.
///
struct PostDownloaderView: View {
    @Environment(\.openURL) private var openURL

    private var viewModel: ContentView.ViewModel
    private var selectedPage: ObservablePage
    @Bindable private var selectedFeature: ObservableFeatureWrapper
    private var updateList: () -> Void

    @State private var imageUrls: [URL] = []
    @State private var pageHashtagCheck = ""
    @State private var missingTag = false
    @State private var excludedHashtagCheck = ""
    @State private var hasExcludedHashtag = false
    @State private var excludedHashtags = ""
    @State private var postHashtags: [String] = []
    @State private var postLoaded = false
    @State private var profileLoaded = false
    @State private var description = ""
    @State private var userAlias = ""
    @State private var userName = ""
    @State private var logging: [(Color, String)] = []
    @State private var pageComments: [(String, String, Date?, String)] = [] // PageId, Comment, Date, PageName
    @State private var hubComments: [(String, String, Date?, String)] = [] // PageId, Comment, Date, PageName
    @State private var moreComments = false
    @State private var commentCount = 0
    @State private var likeCount = 0
    @State private var userProfileLink = ""
    @State private var userBio = ""
    @State private var detectedPostDataMode = "unknown"

    private let languagePrefix = Locale.preferredLanguageCode
    private let mainLabelWidth: CGFloat = 148
    private let logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ selectedPage: ObservablePage,
        _ selectedFeature: ObservableFeatureWrapper,
        _ updateList: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.selectedPage = selectedPage
        self.selectedFeature = selectedFeature
        self.updateList = updateList
    }

    var body: some View {
        ZStack {
            Color.backgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .center) {
                        // Page scope
                        PageScopeView()
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background {
                                Rectangle()
                                    .foregroundStyle(Color.secondaryBackgroundColor)
                                    .cornerRadius(8)
                                    .opacity(0.5)
                            }

                        if profileLoaded {
                            // User alias, name and bio
                            ProfileView()
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background {
                                    Rectangle()
                                        .foregroundStyle(Color.secondaryBackgroundColor)
                                        .cornerRadius(8)
                                        .opacity(0.5)
                                }
                        }

                        if postLoaded {
                            // Tag check and description
                            TagCheckAndDescriptionView()
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background {
                                    Rectangle()
                                        .foregroundStyle(Color.secondaryBackgroundColor)
                                        .cornerRadius(8)
                                        .opacity(0.5)
                                }

                            // Page and hub comments
                            if !pageComments.isEmpty || !hubComments.isEmpty {
                                PageAndHubCommentsView()
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.secondaryBackgroundColor)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }
                            } else if moreComments {
                                MoreCommentsView()
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background {
                                        Rectangle()
                                            .foregroundStyle(Color.secondaryBackgroundColor)
                                            .cornerRadius(8)
                                            .opacity(0.5)
                                    }
                            }

                            // Images
                            ImagesView()
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background {
                                    Rectangle()
                                        .foregroundStyle(Color.secondaryBackgroundColor)
                                        .cornerRadius(8)
                                        .opacity(0.5)
                                }
                        }

                        // Logging
                        LoggingView()
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background {
                                Rectangle()
                                    .foregroundStyle(Color.secondaryBackgroundColor)
                                    .cornerRadius(8)
                                    .opacity(0.5)
                            }
                    }
                    .padding(10)
                }
                Spacer()
            }
            .padding()
            .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()

                    Button(action: {
                        viewModel.visibleView = .FeatureEditorView
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("Close")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts)

                    Button(action: {
                        viewModel.visibleView = .FeatureListView
                    }) {
                        HStack {
                            Image(systemName: "house.circle")
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("Home")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts)

                    Button(action: {
                        logger.verbose("Tapped remove feature button", context: "System")
                        if let currentFeature = viewModel.selectedFeature {
                            viewModel.selectedFeature = nil
                            viewModel.features.removeAll(where: { $0.id == currentFeature.feature.id })
                            viewModel.markDocumentDirty()
                            viewModel.visibleView = .FeatureListView
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.minus")
                                .foregroundStyle(Color.red, Color(UIColor.secondaryLabel))
                            Text("Remove feature")
                        }
                    }
                    .disabled(viewModel.hasModalToasts || viewModel.selectedFeature == nil)

                    Spacer()
                }
            }
            .safeToolbarVisibility(.visible, for: .bottomBar)
        }
        .frame(minHeight: 600)
        .background(Color.backgroundColor)
        .onAppear {
            postLoaded = false
            pageHashtagCheck = ""
            missingTag = false
            excludedHashtagCheck = ""
            hasExcludedHashtag = false
            imageUrls = []
            logging = []
            userProfileLink = ""
            userBio = ""
            pageComments = []
            hubComments = []
            moreComments = false
            commentCount = 0
            likeCount = 0
            detectedPostDataMode = "unknown"
            viewModel.showToast(.progress, "Loading", "Loading the post data from the server...")
            loadExcludedTagsForPage()
            Task.detached {
                await loadFeature()
            }
        }
    }

    // MARK: Subviews

    private func PageScopeView() -> some View {
        VStack(alignment: .leading) {
            // Page
            HStack(alignment: .center) {
                ValidationLabel("Page: ", labelWidth: mainLabelWidth, validation: true, validColor: .green)
                    .font(.system(size: 14))
                ValidationLabel(selectedPage.displayTitle, validation: true, validColor: .accentColor)

                Spacer()
            }
            .frame(height: 20)

            // Page tags
            HStack(alignment: .center) {
                ValidationLabel("Page tags: ", labelWidth: mainLabelWidth, validation: true, validColor: .green)
                    .font(.system(size: 14))
                ValidationLabel(selectedPage.hashTags.joined(separator: ", "), validation: true, validColor: .accentColor)

                Spacer()
            }
            .frame(height: 20)

            // Page excluded tags
            HStack(alignment: .center) {
                ValidationLabel("Excluded hashtags: ", labelWidth: mainLabelWidth, validation: true, validColor: .green)
                    .font(.system(size: 14))
                HStack(alignment: .center) {
                    TextField(
                        "add excluded hashtags without the '#' separated by comma",
                        text: $excludedHashtags.onChange { _ in
                            storeExcludedTagsForPage()
                        }
                    )
                }
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .frame(maxWidth: .infinity)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .frame(maxWidth: 400)

                Spacer()
            }
            .frame(height: 20)

            HStack(alignment: .center) {
                ValidationLabel("Post data mode: ", labelWidth: mainLabelWidth, validation: true, validColor: .green)
                    .font(.system(size: 14))
                ValidationLabel(detectedPostDataMode, validation: detectedPostDataMode != "unknown", validColor: .accentColor)

                Spacer()
            }
            .frame(height: 20)

            // Post URL
            HStack(alignment: .center) {
                ValidationLabel("Post URL: ", labelWidth: mainLabelWidth, validation: selectedFeature.feature.validatePostLink(), validColor: .green)
                    .font(.system(size: 14))
                ValidationLabel(selectedFeature.feature.postLink, validation: true, validColor: .accentColor)

                Spacer()
            }
            .frame(height: 20)

            // Post URL actions
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: mainLabelWidth + 8)

                Button(action: {
                    logger.verbose("Tapped copy URL for post", context: "User")
                    copyToClipboard(selectedFeature.feature.postLink)
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the post URL to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy URL")
                    }
                }
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)

                Spacer()
                    .frame(width: 10)

                Button(action: {
                    if let url = URL(string: selectedFeature.feature.postLink) {
                        logger.verbose("Tapped launch for post", context: "User")
                        openURL(url)
                    }
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "globe")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Launch")
                    }
                }
                .disabled(selectedFeature.feature.postLink.isEmpty)
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)

                Spacer()
            }
            .frame(height: 20)

            // Profile URL
            HStack(alignment: .center) {
                ValidationLabel("User profile URL: ", labelWidth: mainLabelWidth, validation: !userProfileLink.isEmpty, validColor: .green)
                    .font(.system(size: 14))
                ValidationLabel(userProfileLink, validation: true, validColor: .accentColor)

                Spacer()
            }
            .frame(height: 20)

            // Profile URL action
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: mainLabelWidth + 8)

                Button(action: {
                    logger.verbose("Tapped copy URL for profile", context: "User")
                    copyToClipboard(userProfileLink)
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the user profile URL to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy URL")
                    }
                }
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)

                Spacer()
                    .frame(width: 10)

                Button(action: {
                    if let url = URL(string: userProfileLink) {
                        logger.verbose("Tapped launch for profile", context: "User")
                        openURL(url)
                    }
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "globe")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Launch")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(userProfileLink.isEmpty)
                .scaleEffect(0.75, anchor: .leading)

                Spacer()
            }
            .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }

    private func ProfileView() -> some View {
        VStack(alignment: .leading) {
            // User alias
            HStack(alignment: .center) {
                ValidationLabel("User alias: ", labelWidth: mainLabelWidth, validation: !userAlias.isEmpty, validColor: .green)
                    .font(.system(size: 14))
                ValidationLabel(userAlias, validation: true, validColor: .accentColor)

                Spacer()
                    .frame(width: 12)

                ValidationLabel(validation: selectedFeature.feature.validateUserAlias(viewModel))
                HStack(alignment: .center) {
                    TextField(
                        "enter the user alias",
                        text: $selectedFeature.feature.userAlias.onChange { _ in
                            updateList()
                            viewModel.markDocumentDirty()
                        }
                    )
                }
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .frame(maxWidth: 240)
                .autocapitalization(.none)
                .autocorrectionDisabled()

                Button(action: {
                    selectedFeature.feature.userAlias = userAlias
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.line")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Transfer")
                    }
                }
                .disabled(userAlias.isEmpty)
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)

                Spacer()
            }
            .frame(height: 24)

            // User name
            HStack(alignment: .center) {
                ValidationLabel("User name: ", labelWidth: mainLabelWidth, validation: !userName.isEmpty, validColor: .green)
                    .font(.system(size: 14))
                ValidationLabel(userName, validation: true, validColor: .accentColor)

                Spacer()
                    .frame(width: 12)

                ValidationLabel(validation: selectedFeature.feature.validateUserName())
                HStack(alignment: .center) {
                    TextField(
                        "enter the user name",
                        text: $selectedFeature.feature.userName.onChange { _ in
                            updateList()
                            viewModel.markDocumentDirty()
                        }
                    )
                }
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .frame(maxWidth: 240)
                .autocapitalization(.none)
                .autocorrectionDisabled()

                Button(action: {
                    selectedFeature.feature.userName = userName
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.line")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Transfer")
                    }
                }
                .disabled(userName.isEmpty)
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .leading)

                Spacer()
            }
            .frame(height: 24)

            // User BIO
            ValidationLabel("User BIO:", validation: !userBio.isEmpty, validColor: .green)
                .font(.system(size: 14))
            ScrollView {
                HStack {
                    TextEditor(text: .constant("\(userBio)\n\n\n"))
                        .scrollIndicators(.never)
                        .frame(maxWidth: 480, maxHeight: .infinity, alignment: .leading)
                        .textEditorStyle(.plain)
                        .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 4)
                        .autocorrectionDisabled(false)
                        .disableAutocorrection(false)
                        .font(.system(size: 16, design: .serif))
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 110)

            // User level actions
            HStack(alignment: .center) {
                ValidationLabel("User level:", labelWidth: mainLabelWidth, validation: selectedFeature.feature.validateUserLevel())
                    .font(.system(size: 14))
                Picker(
                    "",
                    selection: $selectedFeature.feature.userLevel.onChange { _ in
                        viewModel.markDocumentDirty()
                    }
                ) {
                    ForEach(MembershipCase.casesFor(hub: selectedPage.hub)) { level in
                        Text(level.rawValue)
                            .tag(level)
                            .foregroundStyle(Color(UIColor.secondaryLabel), Color(UIColor.secondaryLabel))
                    }
                }
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color(UIColor.label))
                .frame(maxWidth: 160)

                Toggle(
                    isOn: $selectedFeature.feature.userIsTeammate.onChange { _ in
                        viewModel.markDocumentDirty()
                    }
                ) {
                    Text("User is a Team Mate")
                        .font(.system(size: 14))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .frame(minWidth: 240, maxWidth: 240)

                Spacer()
            }
            .frame(height: 20)
        }
    }

    private func TagCheckAndDescriptionView() -> some View {
        VStack(alignment: .leading) {
            // Tag check
            HStack(alignment: .center) {
                ValidationLabel(pageHashtagCheck, validation: !missingTag, validColor: .green)
                    .font(.system(size: 14))

                Spacer()
            }
            .frame(height: 20)

            // Excluded tag check
            HStack(alignment: .center) {
                ValidationLabel(excludedHashtagCheck, validation: !hasExcludedHashtag, validColor: .green)
                    .font(.system(size: 14))

                Spacer()
            }
            .frame(height: 20)

            // Description
            ValidationLabel("Post description:", validation: !description.isEmpty, isWarning: true, validColor: .green)
                .font(.system(size: 14))
            ScrollView {
                HStack {
                    TextEditor(text: .constant("\(description)\n\n\n"))
                        .scrollIndicators(.never)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .textEditorStyle(.plain)
                        .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 4)
                        .autocorrectionDisabled(false)
                        .disableAutocorrection(false)
                        .font(.system(size: 12))
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 140)

            // Description actions
            HStack(alignment: .center) {
                ValidationLabel(validation: selectedFeature.feature.validateDescription())
                TextField(
                    "enter the description",
                    text: $selectedFeature.feature.featureDescription.onChange { _ in
                        viewModel.markDocumentDirty()
                    }
                )
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .frame(maxWidth: 320)
                .autocapitalization(.none)
                .autocorrectionDisabled()

                Spacer()
            }
            .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }

    private func PageAndHubCommentsView() -> some View {
        VStack(alignment: .leading) {
            if !pageComments.isEmpty {
                HStack(alignment: .center) {
                    ValidationLabel("Found comments from page (possibly already featured on page): ", validation: true, validColor: .red)
                        .font(.system(size: 14))

                    Spacer()
                }
                .frame(height: 20)

                HStack(alignment: .center) {
                    Toggle(
                        isOn: $selectedFeature.feature.photoFeaturedOnPage.onChange { _ in
                            updateList()
                            viewModel.markDocumentDirty()
                        }
                    ) {
                        Text("Already featured on page")
                            .font(.system(size: 14))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.accentColor)
                    .accentColor(Color.accentColor)
                    .frame(minWidth: 220, maxWidth: 220)
                    Spacer()
                }
                .frame(height: 20)

                ScrollView {
                    ForEach(pageComments.sorted { $0.2 ?? .distantPast < $1.2 ?? .distantPast }, id: \.0) { comment in
                        HStack(alignment: .center) {
                            Text("\(comment.0) [\(comment.2.formatTimestamp())]: \(comment.1)")
                                .foregroundStyle(.red, .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 12))

                            Spacer()
                                .frame(width: 10)

                            Button(action: {
                                selectedFeature.feature.photoFeaturedOnPage = true
                                updateList()
                                viewModel.markDocumentDirty()
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "checkmark.square")
                                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                                    Text("Mark post")
                                }
                            }
                            .buttonStyle(.bordered)
                            .scaleEffect(0.75, anchor: .trailing)
                        }
                    }
                }
                .frame(maxHeight: 60)
            }

            if !pageComments.isEmpty && !hubComments.isEmpty {
                Divider()
            }

            if !hubComments.isEmpty {
                HStack(alignment: .center) {
                    ValidationLabel("Found comments from hub (possibly already featured on another page): ", validation: true, validColor: .orange)
                        .font(.system(size: 14))

                    Spacer()
                }
                .frame(height: 20)

                HStack(alignment: .center) {
                    Toggle(
                        isOn: $selectedFeature.feature.photoFeaturedOnHub.onChange { _ in
                            updateList()
                            viewModel.markDocumentDirty()
                        }
                    ) {
                        Text("Photo featured on hub")
                            .font(.system(size: 14))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.accentColor)
                    .accentColor(Color.accentColor)
                    .frame(minWidth: 220, maxWidth: 220)

                    if selectedFeature.feature.photoFeaturedOnHub {
                        Text("|")
                            .padding([.leading, .trailing], 8)

                        ValidationLabel(validation: selectedFeature.feature.validatePhotoFeaturedOnHub())
                        TextField(
                            "last date featured",
                            text: $selectedFeature.feature.photoLastFeaturedOnHub.onChange { _ in
                                viewModel.markDocumentDirty()
                            }
                        )
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.backgroundColor.opacity(0.5))
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)
                        .frame(maxWidth: 160)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                        TextField(
                            "on page",
                            text: $selectedFeature.feature.photoLastFeaturedPage.onChange { _ in
                                viewModel.markDocumentDirty()
                            }
                        )
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.backgroundColor.opacity(0.5))
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)
                        .frame(maxWidth: 160)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    }

                    Spacer()
                }
                .frame(height: 20)

                ScrollView {
                    ForEach(hubComments.sorted { $0.2 ?? .distantPast < $1.2 ?? .distantPast }, id: \.0) { comment in
                        HStack(alignment: .center) {
                            Text("\(comment.0) [\(comment.2.formatTimestamp())]: \(comment.1)")
                                .foregroundStyle(.orange, .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .font(.system(size: 12))

                            Spacer()
                                .frame(width: 10)

                            Button(action: {
                                selectedFeature.feature.photoFeaturedOnHub = true
                                selectedFeature.feature.photoLastFeaturedPage = comment.3
                                selectedFeature.feature.photoLastFeaturedOnHub = comment.2.formatTimestamp()
                                viewModel.markDocumentDirty()
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "checkmark.square")
                                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                                    Text("Mark post")
                                }
                            }
                            .buttonStyle(.bordered)
                            .scaleEffect(0.75, anchor: .trailing)
                        }
                        .frame(maxHeight: .infinity)
                    }
                }
                .frame(maxHeight: 60)
            }

            if moreComments {
                Divider()

                HStack(alignment: .center) {
                    ValidationLabel("There were more comments than downloaded in the post, open the post IN VERO to check to previous features.", validation: true, validColor: .orange)
                        .font(.system(size: 14))

                    Spacer()
                }
                .frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func MoreCommentsView() -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                ValidationLabel("There were more comments than downloaded in the post, open the post IN VERO to check to previous features.", validation: true, validColor: .orange)
                    .font(.system(size: 14))

                Spacer()
            }
            .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
    }

    private func ImagesView() -> some View {
        VStack(alignment: .center) {
            HStack(alignment: .center) {
                ValidationLabel("Image\(imageUrls.count == 1 ? "" : "s") found: ", validation: imageUrls.count > 0, validColor: .green)
                    .font(.system(size: 14))
                ValidationLabel("\(imageUrls.count)", validation: imageUrls.count > 0, validColor: .accentColor)
                    .font(.system(size: 14))

                Spacer()
            }
            .frame(height: 20)
            .frame(maxWidth: .infinity)
            .padding([.leading, .trailing])

            CarouselView(viewModel: viewModel, images: imageUrls, userName: userName)
                .frame(minWidth: 20, maxWidth: .infinity)
        }
    }

    private func LoggingView() -> some View {
        VStack {
            HStack(alignment: .top) {
                ValidationLabel("LOGGING: ", validation: true, validColor: .orange)
                    .font(.system(size: 14))

                Spacer()

                Button(action: {
                    logger.verbose("Tapped copy for log", context: "User")
                    copyToClipboard(logging.map { $0.1 }.joined(separator: "\n"))
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the logging data to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy log")
                    }
                }
                .buttonStyle(.bordered)
                .scaleEffect(0.75, anchor: .trailing)
            }
            .frame(maxWidth: .infinity)

            ScrollView(.horizontal) {
                ForEach(Array(logging.enumerated()), id: \.offset) { _, log in
                    Text(log.1)
                        .foregroundStyle(log.0, .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 12))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension PostDownloaderView {
    private struct ParsedProfilePayload {
        let alias: String
        let name: String
        let url: String
        let bio: String
    }

    private struct ParsedCommentPayload {
        let userName: String
        let authorName: String
        let text: String
        let timestamp: Date?
    }

    private struct ParsedPostPayload {
        let description: String
        let hashtags: [String]
        let imageSources: [String]
        let comments: [ParsedCommentPayload]
        let commentsAvailable: Bool
        let commentCount: Int
        let likeCount: Int
    }

    private struct ParsedPostLoadPayload {
        let profile: ParsedProfilePayload?
        let post: ParsedPostPayload?
        let profileSource: String
        let postSource: String
    }

    private enum DecodeMode {
        case jsonDoubleQuotedString
        case javaScriptSingleQuotedString
    }

    @MainActor
    func parsePost(_ contents: String) {
        do {
            logger.verbose("Loaded the post from the server", context: "System")
            logging.append((.blue, "Loaded the post from the server"))

            imageUrls = []
            pageComments = []
            hubComments = []
            postHashtags = []
            description = ""
            pageHashtagCheck = ""
            excludedHashtagCheck = ""
            missingTag = false
            hasExcludedHashtag = false
            postLoaded = false
            profileLoaded = false
            moreComments = false
            commentCount = 0
            likeCount = 0

            let parsedPayload = try parsePayload(contents)
            detectedPostDataMode = derivedPostDataMode(parsedPayload)

            if let profile = parsedPayload.profile {
                userAlias = profile.alias
                userName = profile.name
                userProfileLink = profile.url
                userBio = profile.bio

                var populatedFeatureValues = false
                if selectedFeature.feature.userAlias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !userAlias.isEmpty {
                    selectedFeature.feature.userAlias = userAlias
                    populatedFeatureValues = true
                }
                if selectedFeature.feature.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !userName.isEmpty {
                    selectedFeature.feature.userName = userName
                    populatedFeatureValues = true
                }
                if populatedFeatureValues {
                    updateList()
                    viewModel.markDocumentDirty()
                }

                profileLoaded = true

                logger.verbose("Loaded the profile", context: "System")
                logging.append((.blue, "Profile source: \(parsedPayload.profileSource)"))
                logging.append((.blue, "User's alias: \(userAlias)"))
                logging.append((.blue, "User's name: \(userName)"))
                logging.append((.blue, "User's profile link: \(userProfileLink)"))
                logging.append((.blue, "User's bio: \(userBio)"))
            } else {
                userAlias = ""
                userName = ""
                userProfileLink = ""
                userBio = ""
                logging.append((.orange, "Profile data was not found in the selected data mode"))
            }

            if let post = parsedPayload.post {
                description = post.description
                postHashtags = post.hashtags
                imageUrls = post.imageSources.compactMap { URL(string: $0) }
                logging.append((.blue, "Post source: \(parsedPayload.postSource)"))
                for imageSource in post.imageSources {
                    logging.append((.blue, "Image source: \(imageSource)"))
                }

                checkPageHashtags()
                checkExcludedHashtags()
                applyComments(post)

                postLoaded = true
                logger.verbose("Loaded the post information", context: "System")
            } else {
                logging.append((.orange, "Post data was not found in the selected data mode"))
            }

            if !profileLoaded && !postLoaded {
                throw AccountError.NoDataFound
            }
        } catch let error as AccountError {
            logger.error("Failed to download and parse the post information - \(error.errorDescription ?? "unknown")", context: "System")
            logging.append((.red, "Failed to download and parse the post information - \(error.errorDescription ?? "unknown")"))
            logging.append((.red, "Post must be handled manually in VERO app"))
            viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            viewModel.showToast(
                .error,
                "Failed to load and parse post",
                "Failed to download and parse the post information - \(error.errorDescription ?? "unknown")")
        } catch {
            logger.error("Failed to download and parse the post information - \(error.localizedDescription)", context: "System")
            logging.append((.red, "Failed to download and parse the post information - \(error.localizedDescription)"))
            logging.append((.red, "Post must be handled manually in VERO app"))
            viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            viewModel.showToast(
                .error,
                "Failed to load and parse post",
                "Failed to download and parse the post information - \(error.localizedDescription)")
        }
    }

    private func parsePayload(_ contents: String) throws -> ParsedPostLoadPayload {
        logging.append((.blue, "Using auto parser (new + legacy fallback)"))
        let reactResult = Result { try parseReactPayload(contents) }
        let legacyResult = Result { try parseLegacyPayload(contents) }

        let reactPayload = try? reactResult.get()
        let legacyPayload = try? legacyResult.get()

        let merged = ParsedPostLoadPayload(
            profile: reactPayload?.profile ?? legacyPayload?.profile,
            post: reactPayload?.post ?? legacyPayload?.post,
            profileSource: reactPayload?.profile != nil ? "new" : (legacyPayload?.profile != nil ? "legacy" : "unavailable"),
            postSource: reactPayload?.post != nil ? "new" : (legacyPayload?.post != nil ? "legacy" : "unavailable")
        )

        if merged.profile == nil, case .failure(let error) = reactResult {
            logging.append((.orange, "New parser did not return profile: \(error.localizedDescription)"))
        }
        if merged.post == nil, case .failure(let error) = reactResult {
            logging.append((.orange, "New parser did not return post: \(error.localizedDescription)"))
        }
        if merged.profile == nil, case .failure(let error) = legacyResult {
            logging.append((.orange, "Legacy parser did not return profile: \(error.localizedDescription)"))
        }
        if merged.post == nil, case .failure(let error) = legacyResult {
            logging.append((.orange, "Legacy parser did not return post: \(error.localizedDescription)"))
        }

        return merged
    }

    private func derivedPostDataMode(_ payload: ParsedPostLoadPayload) -> String {
        let sources = [payload.profileSource, payload.postSource]
        if sources.contains("new") {
            return "new"
        }
        if sources.contains("legacy") {
            return "legacy"
        }
        return "unknown"
    }

    private func parseLegacyPayload(_ contents: String) throws -> ParsedPostLoadPayload {
        let jsonData = try extractLegacyHydrationJSONData(from: contents)
        let postData = try JSONDecoder().decode(PostData.self, from: jsonData)
        let postData2 = try JSONDecoder().decode(PostData2.self, from: jsonData)

        let profile = postData.loaderData?.entry?.profile?.profile ?? postData2.loaderData?.entry?.profile
        let parsedProfile: ParsedProfilePayload? = profile.map {
            let firstName = ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackUserName = ($0.username ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedName = firstName.isEmpty ? fallbackUserName : firstName
            let alias = fallbackUserName.isEmpty ? firstName.replacingOccurrences(of: " ", with: "") : fallbackUserName
            return ParsedProfilePayload(
                alias: alias,
                name: resolvedName,
                url: $0.url ?? "",
                bio: ($0.bio ?? "").removeExtraSpaces()
            )
        }

        let parsedPost: ParsedPostPayload? = postData.loaderData?.entry?.post.map { oldPost in
            var hashTags: [String] = []
            let description = joinSegments(oldPost.post?.caption, &hashTags).removeExtraSpaces(includeNewlines: false)
            let postImages: [PostImage] = oldPost.post?.images ?? []
            var imageSources: [String] = []
            for image in postImages {
                if let url = image.url, url.hasPrefix("https://") {
                    imageSources.append(url)
                }
            }

            let rawComments: [Comment] = oldPost.comments ?? []
            var comments: [ParsedCommentPayload] = []
            for comment in rawComments {
                guard let commentUserName = comment.author?.username else { continue }
                let text = joinSegments(comment.content).removeExtraSpaces()
                comments.append(
                    ParsedCommentPayload(
                        userName: commentUserName,
                        authorName: comment.author?.name ?? commentUserName,
                        text: text,
                        timestamp: (comment.timestamp ?? "").timestamp()
                    )
                )
            }

            return ParsedPostPayload(
                description: description,
                hashtags: hashTags,
                imageSources: imageSources,
                comments: comments,
                commentsAvailable: oldPost.comments != nil,
                commentCount: oldPost.post?.comments ?? 0,
                likeCount: oldPost.post?.likes ?? 0
            )
        }

        return ParsedPostLoadPayload(profile: parsedProfile, post: parsedPost, profileSource: "legacy", postSource: "legacy")
    }

    private func parseReactPayload(_ contents: String) throws -> ParsedPostLoadPayload {
        let reactArray = try extractReactDataArray(from: contents)
        let reactData = ReactData(reactData: reactArray)

        let userPost = reactData.loaderData?.userPost
        let postOnly = reactData.loaderData?.postOnly

        let profile = userPost?.profile ?? postOnly?.profile
        let parsedProfile: ParsedProfilePayload? = profile.map {
            let firstName = $0.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackUserName = $0.userName.trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedName = firstName.isEmpty ? fallbackUserName : firstName
            let alias = fallbackUserName.isEmpty ? resolvedName.replacingOccurrences(of: " ", with: "") : fallbackUserName
            return ParsedProfilePayload(
                alias: alias,
                name: resolvedName,
                url: $0.url,
                bio: $0.bio.removeExtraSpaces()
            )
        }

        let reactPostContainer = userPost?.post ?? postOnly?.post
        let parsedPost: ParsedPostPayload? = reactPostContainer?.post.map { reactPost in
            var hashTags: [String] = []
            let description = joinReactContent(reactPost.caption, &hashTags).removeExtraSpaces(includeNewlines: false)
            let imageSources = reactPost.images
                .map(\.url)
                .filter { $0.hasPrefix("https://") }

            let reactComments: [ReactComment] = reactPostContainer?.comments ?? []
            let comments: [ParsedCommentPayload] = reactComments.compactMap { comment in
                guard let author = comment.author, !author.userName.isEmpty else { return nil }
                return ParsedCommentPayload(
                    userName: author.userName,
                    authorName: author.firstName.isEmpty ? author.userName : author.firstName,
                    text: joinReactContent(comment.content).removeExtraSpaces(),
                    timestamp: comment.timestamp == .distantPast ? nil : comment.timestamp
                )
            }

            return ParsedPostPayload(
                description: description,
                hashtags: hashTags,
                imageSources: imageSources,
                comments: comments,
                commentsAvailable: reactPostContainer?.hasProperty("comments") ?? false,
                commentCount: Int(reactPost.comments),
                likeCount: Int(reactPost.likes)
            )
        }

        return ParsedPostLoadPayload(profile: parsedProfile, post: parsedPost, profileSource: "new", postSource: "new")
    }

    private func applyComments(_ post: ParsedPostPayload) {
        pageComments = []
        hubComments = []
        moreComments = false
        commentCount = 0
        likeCount = 0

        let pageHub = selectedPage.hub
        guard pageHub == "click" || pageHub == "snap" else { return }

        commentCount = post.commentCount
        likeCount = post.likeCount

        if post.commentsAvailable {
            moreComments = post.comments.count < commentCount
            for comment in post.comments {
                let commentUserName = comment.userName.lowercased()
                guard commentUserName.hasPrefix("\(pageHub.lowercased())_") else { continue }

                let pageName = String(commentUserName.dropFirst(pageHub.count + 1))
                if commentUserName == selectedPage.displayName.lowercased() {
                    pageComments.append((comment.authorName, comment.text, comment.timestamp, pageName))
                    logger.verbose("Found comment from page", context: "System")
                    logging.append((.red, "Found comment from page - possibly already featured on page"))
                } else {
                    hubComments.append((comment.authorName, comment.text, comment.timestamp, pageName))
                    logger.verbose("Found comment from another hub page", context: "System")
                    logging.append((.orange, "Found comment from another hub page - possibly already feature on another page"))
                }
            }
        } else {
            moreComments = commentCount != 0
            if moreComments {
                logger.verbose("Not all comments loaded", context: "System")
                logging.append((.orange, "Not all comments found in post, check VERO app to see all comments"))
            }
        }
    }

    private func joinReactContent(_ segments: [ReactContent], _ hashTags: inout [String]) -> String {
        var result = ""
        for segment in segments {
            switch segment.type {
            case "text":
                result += segment.value
            case "tag":
                result += "#\(segment.value)"
                hashTags.append("#\(segment.value)")
            case "person":
                if !segment.label.isEmpty {
                    result += "@\(segment.label)"
                } else {
                    result += segment.value
                }
            case "url":
                if !segment.label.isEmpty {
                    result += segment.label
                } else {
                    result += segment.value
                }
            default:
                logger.warning("Unhandled react content type: \(segment.type)", context: "System")
            }
        }
        return result.replacingOccurrences(of: "\\n", with: "\n")
    }

    private func joinReactContent(_ segments: [ReactContent]) -> String {
        var ignored: [String] = []
        return joinReactContent(segments, &ignored)
    }

    private func extractLegacyHydrationJSONData(from html: String) throws -> Data {
        let document = try SwiftSoup.parse(html)
        for item in try document.select("script") {
            let scriptText = try item.html().trimmingCharacters(in: .whitespaces)
            guard !scriptText.isEmpty else { continue }
            let scriptLines = scriptText.split(whereSeparator: \.isNewline)
            guard let firstLine = scriptLines.first,
                  firstLine.hasPrefix("window.__staticRouterHydrationData = JSON.parse(") else { continue }

            let prefixLength = "window.__staticRouterHydrationData = JSON.parse(".count
            let start = scriptText.index(scriptText.startIndex, offsetBy: prefixLength + 1)
            let end = scriptText.index(scriptText.endIndex, offsetBy: -3)
            let jsonString = String(scriptText[start ..< end])
            let wrappedJsonString = "{\"value\": \"\(jsonString)\"}"

            guard let jsonEncodedData = wrappedJsonString.data(using: .utf8),
                  let jsonStringDecoded = try JSONSerialization.jsonObject(with: jsonEncodedData, options: []) as? [String: Any],
                  let stringValue = jsonStringDecoded["value"] as? String,
                  let jsonData = stringValue.data(using: .utf8) else {
                continue
            }

            return jsonData
        }

        throw AccountError.NoDataFound
    }

    private func extractReactDataArray(from html: String) throws -> [Any] {
        let htmlRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let strategies: [(pattern: String, decodeMode: DecodeMode)] = [
            (#"window\.__reactRouterContext\.streamController\.enqueue\("((?:\\.|[^"\\])*)"\);"#, .jsonDoubleQuotedString),
            (#"__reactRouterContext\.streamController\.enqueue\("((?:\\.|[^"\\])*)"\);"#, .jsonDoubleQuotedString),
            (#"streamController\.enqueue\("((?:\\.|[^"\\])*)"\);"#, .jsonDoubleQuotedString),
            (#"streamController\.enqueue\('((?:\\.|[^'\\])*)'\);"#, .javaScriptSingleQuotedString),
            (#"streamController\.enqueue\(JSON\.parse\("((?:\\.|[^"\\])*)"\)\);"#, .jsonDoubleQuotedString),
            (#"streamController\.enqueue\(JSON\.parse\('((?:\\.|[^'\\])*)'\)\);"#, .javaScriptSingleQuotedString)
        ]

        for strategy in strategies {
            let regex = try NSRegularExpression(pattern: strategy.pattern, options: [.dotMatchesLineSeparators])
            let matches = regex.matches(in: html, options: [], range: htmlRange)
            for match in matches {
                guard let captureRange = Range(match.range(at: 1), in: html) else { continue }
                let payload = String(html[captureRange])
                if let array = try parseReactArray(fromCapturedPayload: payload, mode: strategy.decodeMode) {
                    return array
                }
            }
        }

        throw AccountError.NoDataFound
    }

    private func parseReactArray(fromCapturedPayload payload: String, mode: DecodeMode) throws -> [Any]? {
        let decodedJSONString: String
        switch mode {
        case .jsonDoubleQuotedString:
            decodedJSONString = try decodeJSONEncodedString(payload)
        case .javaScriptSingleQuotedString:
            decodedJSONString = decodeSingleQuotedJavaScriptString(payload)
        }

        guard let decodedData = decodedJSONString.data(using: .utf8) else {
            return nil
        }

        let jsonObject = try JSONSerialization.jsonObject(with: decodedData)
        guard let array = jsonObject as? [Any], array.count > 1 else {
            return nil
        }

        return array
    }

    private func decodeJSONEncodedString(_ payload: String) throws -> String {
        let quotedJSONString = "\"\(payload)\""
        guard let data = quotedJSONString.data(using: .utf8) else {
            throw AccountError.NoDataFound
        }
        return try JSONDecoder().decode(String.self, from: data)
    }

    private func decodeSingleQuotedJavaScriptString(_ payload: String) -> String {
        var output = ""
        var index = payload.startIndex

        func advance() { index = payload.index(after: index) }

        while index < payload.endIndex {
            let char = payload[index]
            if char != "\\" {
                output.append(char)
                advance()
                continue
            }

            let next = payload.index(after: index)
            guard next < payload.endIndex else { break }
            let escape = payload[next]

            switch escape {
            case "n": output.append("\n")
            case "r": output.append("\r")
            case "t": output.append("\t")
            case "b": output.append("\u{0008}")
            case "f": output.append("\u{000C}")
            case "\\": output.append("\\")
            case "\"": output.append("\"")
            case "'": output.append("'")
            case "/": output.append("/")
            case "u":
                let hexStart = payload.index(after: next)
                let hexEnd = payload.index(hexStart, offsetBy: 4, limitedBy: payload.endIndex) ?? payload.endIndex
                if hexEnd <= payload.endIndex {
                    let hex = String(payload[hexStart..<hexEnd])
                    if let scalarValue = UInt32(hex, radix: 16), let scalar = UnicodeScalar(scalarValue) {
                        output.append(Character(scalar))
                        index = payload.index(before: hexEnd)
                    }
                }
            default:
                output.append(escape)
            }

            index = payload.index(after: next)
        }

        return output
    }

    /// Account error enumeration for throwing account-specifc error codes.
    enum AccountError: String, LocalizedError {
        case NoDataFound = "Could not find profile or post data for this URL"
        public var errorDescription: String? { rawValue }
    }

    /// Loads the feature using the postUrl.
    private func loadFeature() async {
        logger.verbose("Loading feature post", context: "System")
        if let url = URL(string: selectedFeature.feature.postLink) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let session = URLSession(configuration: URLSessionConfiguration.default)
            session.dataTask(with: request) { data, _, error in
                if let data = data {
                    let contents = String(data: data, encoding: .utf8)!
                    Task { @MainActor in
                        parsePost(contents)
                        viewModel.dismissAllNonBlockingToasts(includeProgress: true)
                    }
                } else if let error = error {
                    Task { @MainActor in
                        logger.error("Failed to download and parse the post information - \(error.localizedDescription)", context: "System")
                        logging.append((.red, "Failed to download and parse the post information - \(error.localizedDescription)"))
                        logging.append((.red, "Post must be handled manually in VERO app"))
                        viewModel.dismissAllNonBlockingToasts(includeProgress: true)
                        viewModel.showToast(
                            .error,
                            "Failed to load and parse post",
                            "Failed to download and parse the post information - \(error.localizedDescription)")
                    }
                }
            }.resume()
        } else {
            Task { @MainActor in
                viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            }
        }
    }

    /// Loads the excluded hashtags for the current page.
    private func loadExcludedTagsForPage() {
        excludedHashtags = UserDefaults.standard.string(forKey: "ExcludedHashtags_" + selectedPage.id) ?? ""
    }

    /// Stores the excluded hashtags for the current page.
    private func storeExcludedTagsForPage() {
        UserDefaults.standard.set(excludedHashtags, forKey: "ExcludedHashtags_" + selectedPage.id)
        checkExcludedHashtags()
    }

    /// Checks for the page hashtag.
    private func checkPageHashtags() {
        var pageHashTagFound = ""
        let pageHashTags = selectedPage.hashTags
        if postHashtags.firstIndex(where: { postHashTag in
            pageHashTags.firstIndex(where: { pageHashTag in
                if postHashTag.lowercased() == pageHashTag.lowercased() {
                    pageHashTagFound = pageHashTag.lowercased()
                    return true
                }
                return false
            }) != nil
        }) != nil {
            pageHashtagCheck = "Contains page hashtag \(pageHashTagFound)"
            logging.append((.blue, pageHashtagCheck))
        } else {
            pageHashtagCheck = "MISSING page hashtag!!"
            logging.append((.orange, "\(pageHashtagCheck)"))
            missingTag = true
        }
    }

    /// Checks for any excluded hashtags.
    private func checkExcludedHashtags() {
        hasExcludedHashtag = false
        excludedHashtagCheck = ""
        if !excludedHashtags.isEmpty {
            let excludedTags = excludedHashtags.split(separator: ",", omittingEmptySubsequences: true)
            for excludedTag in excludedTags {
                if postHashtags.includes("#\(String(excludedTag))") {
                    hasExcludedHashtag = true
                    excludedHashtagCheck = "Post has excluded hashtag \(excludedTag)!"
                    logging.append((.red, excludedHashtagCheck))
                    break
                }
            }
        }
        if excludedHashtagCheck.isEmpty {
            if excludedHashtags.isEmpty {
                excludedHashtagCheck = "Post does not contain any excluded hashtags"
                logging.append((.blue, excludedHashtagCheck))
            } else {
                excludedHashtagCheck = "No excluded hashtags to check"
                logging.append((.blue, excludedHashtagCheck))
            }
        }
    }
}
