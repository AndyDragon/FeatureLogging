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
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("Close")
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

            // Post URL
            HStack(alignment: .center) {
                ValidationLabel("Post URL: ", labelWidth: mainLabelWidth, validation: !selectedFeature.feature.postLink.isEmpty, validColor: .green)
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

                ValidationLabel(
                    validation: !(selectedFeature.feature.userAlias.isEmpty || selectedFeature.feature.userAlias.starts(with: "@")
                        || selectedFeature.feature.userAlias.count <= 1) && !selectedFeature.feature.userAlias.contains(where: \.isNewline)
                )
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

                ValidationLabel(
                    validation: !selectedFeature.feature.userName.isEmpty && !selectedFeature.feature.userName.contains(where: \.isNewline)
                )
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
                ValidationLabel("User level:", labelWidth: mainLabelWidth, validation: selectedFeature.feature.userLevel != MembershipCase.none)
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
                ValidationLabel(
                    validation: !selectedFeature.feature.featureDescription.isEmpty,
                    isWarning: true
                )
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

                        ValidationLabel(
                            validation: !(selectedFeature.feature.photoLastFeaturedOnHub.isEmpty || selectedFeature.feature.photoLastFeaturedPage.isEmpty),
                            isWarning: true
                        )
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

            ScrollView(.horizontal) {
                VStack(alignment: .center) {
                    HStack {
                        ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                            PostDownloaderImageView(
                                viewModel: viewModel,
                                imageUrl: imageUrl,
                                userName: userName,
                                index: index
                            )
                            .padding(.all, 0.001)
                        }
                    }
                    .frame(minWidth: 20)
                }
                .padding([.leading, .bottom, .trailing])
            }
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
    @MainActor
    func parsePost(_ contents: String) {
        do {
            logger.verbose("Loaded the post from the server", context: "System")
            logging.append((.blue, "Loaded the post from the server"))
            let document = try SwiftSoup.parse(contents)
            for item in try document.select("script") {
                do {
                    let scriptText = try item.html().trimmingCharacters(in: .whitespaces)
                    if !scriptText.isEmpty {
                        let scriptLines = scriptText.split(whereSeparator: \.isNewline)
                        if scriptLines.first!.hasPrefix("window.__staticRouterHydrationData = JSON.parse(") {
                            let prefixLength = "window.__staticRouterHydrationData = JSON.parse(".count
                            let start = scriptText.index(scriptText.startIndex, offsetBy: prefixLength + 1)
                            let end = scriptText.index(scriptText.endIndex, offsetBy: -3)
                            let jsonString = String(scriptText[start ..< end])
                            // The JSON string is a JSON-encoded string, so use a wrapped JSON fragment and the JSON serialization
                            // utility to get the unencoded string which is then decoded using the JSON decoder utility.
                            let wrappedJsonString = "{\"value\": \"\(jsonString)\"}"
                            if let jsonEncodedData = wrappedJsonString.data(using: .utf8) {
                                if let jsonStringDecoded = try JSONSerialization.jsonObject(with: jsonEncodedData, options: []) as? [String: Any] {
                                    if let stringValue = (jsonStringDecoded["value"] as? String) {
                                        if let jsonData = stringValue.data(using: .utf8) {
                                            let postData = try JSONDecoder().decode(PostData.self, from: jsonData)
                                            if let profile = postData.loaderData?.entry?.profile?.profile {
                                                userAlias = profile.username ?? ""
                                                if userAlias.isEmpty && profile.name != nil {
                                                    userAlias = profile.name!.replacingOccurrences(of: " ", with: "")
                                                }
                                                logger.verbose("Loaded the profile", context: "System")
                                                logging.append((.blue, "User's alias: \(userAlias)"))
                                                userName = profile.name ?? ""
                                                logging.append((.blue, "User's name: \(userName)"))
                                                userProfileLink = profile.url ?? ""
                                                logging.append((.blue, "User's profile link: \(userProfileLink)"))
                                                userBio = (profile.bio ?? "").removeExtraSpaces()
                                                logging.append((.blue, "User's bio: \(userBio)"))

                                                profileLoaded = true
                                            } else {
                                                logger.error("Failed to find the profile information", context: "System")
                                                logging.append((.red, "Failed to find the profile information, the account is likely private"))
                                                logging.append((.red, "Post must be handled manually in VERO app"))
                                                // debugPrint(jsonString)
                                            }
                                            if let post = postData.loaderData?.entry?.post {
                                                postHashtags = []
                                                description = joinSegments(post.post?.caption, &postHashtags).removeExtraSpaces(includeNewlines: false)

                                                logger.verbose("Loaded the post information", context: "System")

                                                checkPageHashtags()
                                                checkExcludedHashtags()

                                                if let postImages = post.post?.images {
                                                    logger.verbose("Found images in the post information", context: "System")
                                                    let postImageUrls = postImages.filter({ $0.url != nil && $0.url!.hasPrefix("https://") }).map { $0.url! }
                                                    for imageUrl in postImageUrls {
                                                        logging.append((.blue, "Image source: \(imageUrl)"))
                                                        imageUrls.append(URL(string: imageUrl)!)
                                                    }
                                                }

                                                if selectedPage.hub == "click" || selectedPage.hub == "snap" {
                                                    commentCount = post.post?.comments ?? 0
                                                    likeCount = post.post?.likes ?? 0
                                                    if let comments = post.comments {
                                                        moreComments = comments.count < commentCount
                                                        for comment in comments {
                                                            if let userName = comment.author?.username {
                                                                if userName.lowercased().hasPrefix("\(selectedPage.hub.lowercased())_") {
                                                                    if userName.lowercased() == selectedPage.displayName.lowercased() {
                                                                        pageComments.append((
                                                                            comment.author?.name ?? userName,
                                                                            joinSegments(comment.content).removeExtraSpaces(),
                                                                            (comment.timestamp ?? "").timestamp(),
                                                                            String(userName[userName.index(userName.startIndex, offsetBy: selectedPage.hub.count + 1) ..< userName.endIndex].lowercased())
                                                                        ))
                                                                        logger.verbose("Found comment from page", context: "System")
                                                                        logging.append((.red, "Found comment from page - possibly already featured on page"))
                                                                    } else {
                                                                        hubComments.append((
                                                                            comment.author?.name ?? userName,
                                                                            joinSegments(comment.content).removeExtraSpaces(),
                                                                            (comment.timestamp ?? "").timestamp(),
                                                                            String(userName[userName.index(userName.startIndex, offsetBy: selectedPage.hub.count + 1) ..< userName.endIndex].lowercased())
                                                                        ))
                                                                        logger.verbose("Found comment from another hub page", context: "System")
                                                                        logging.append((.orange, "Found comment from another hub page - possibly already feature on another page"))
                                                                    }
                                                                }
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
                                            } else {
                                                logger.error("Failed to find the post information", context: "System")
                                                logging.append((.red, "Failed to find the post information, the account is likely private"))
                                                logging.append((.red, "Post must be handled manually in VERO app"))
                                                // debugPrint(jsonString)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    logger.error("Failed to parse the post information: \(error.localizedDescription)", context: "System")
                    debugPrint(error.localizedDescription)
                    viewModel.dismissAllNonBlockingToasts(includeProgress: true)
                    viewModel.showToast(
                        .alert,
                        "Failed to parse the post data on the post",
                        "Failed to parse the post information from the downloaded post - \(error.localizedDescription)"
                    )
                }
            }

            if imageUrls.isEmpty {
                throw AccountError.PrivateAccount
            }

            postLoaded = true
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

    /// Account error enumeration for throwing account-specifc error codes.
    enum AccountError: String, LocalizedError {
        case PrivateAccount = "Could not find any images, this account might be private"
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
