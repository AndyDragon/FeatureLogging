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
    
    private var viewModel: ContentView.ViewModel
    private var toastManager: ContentView.ToastManager
    private var selectedPage: ObservablePage
    @Bindable private var selectedFeature: ObservableFeatureWrapper
    @State private var focusedField: FocusState<FocusField?>.Binding
    private var hideDownloaderView: () -> Void
    private var showImageValidationView: (_ imageUrl: URL) -> Void
    private var updateList: () -> Void

    @State private var imageUrls: [URL] = []
    @State private var pageHashtagCheck = ""
    @State private var missingTag = false
    @State private var excludedHashtagCheck = ""
    @State private var hasExcludedHashtag = false
    @State private var excludedHashtags = ""
    @State private var postHashtags: [String] = []
    @State private var postLoaded = false
    @State private var description = ""
    @State private var userAlias = ""
    @State private var userName = ""
    @State private var logging: [(Color, String)] = []
    @State private var pageComments: [(String, String, Date?, String)] = []; // PageId, Comment, Date, PageName
    @State private var hubComments: [(String, String, Date?, String)] = []; // PageId, Comment, Date, PageName
    @State private var moreComments = false
    @State private var commentCount = 0
    @State private var likeCount = 0
    @State private var userProfileLink = ""
    @State private var userBio = ""

    private let languagePrefix = Locale.preferredLanguageCode
    private let mainLabelWidth: CGFloat = -128
    private let labelWidth: CGFloat = 108
    
    init(
        _ viewModel: ContentView.ViewModel,
        _ toastManager: ContentView.ToastManager,
        _ selectedPage: ObservablePage,
        _ selectedFeature: ObservableFeatureWrapper,
        _ focusedField: FocusState<FocusField?>.Binding,
        _ hideDownloaderView: @escaping () -> Void,
        _ showImageValidationView: @escaping (_ imageUrl: URL) -> Void,
        _ updateList: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.toastManager = toastManager
        self.selectedPage = selectedPage
        self.selectedFeature = selectedFeature
        self.focusedField = focusedField
        self.hideDownloaderView = hideDownloaderView
        self.showImageValidationView = showImageValidationView
        self.updateList = updateList
    }

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)

            ScrollView(.vertical) {
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .center) {
                            // Page scope
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    HStack(alignment: .center) {
                                        ValidationLabel("Page: ", labelWidth: -mainLabelWidth, validation: true, validColor: .green)
                                        ValidationLabel(selectedPage.displayTitle, validation: true, validColor: .AccentColor)
                                        Spacer()
                                    }
                                    .frame(height: 20)
                                    HStack(alignment: .center) {
                                        ValidationLabel("Page tags: ", labelWidth: -mainLabelWidth, validation: true, validColor: .green)
                                        ValidationLabel(selectedPage.hashTags.joined(separator: ", "), validation: true, validColor: .AccentColor)
                                        Spacer()
                                    }
                                    .frame(height: 20)
                                    HStack(alignment: .center) {
                                        ValidationLabel("Excluded hashtags: ", labelWidth: -mainLabelWidth, validation: true, validColor: .green)
                                        HStack(alignment: .center) {
                                            TextField(
                                                "add excluded hashtags without the '#' separated by comma",
                                                text: $excludedHashtags.onChange { value in
                                                    storeExcludedTagsForPage()
                                                }
                                            )
                                            .focusable()
                                            .focused(focusedField, equals: .postUserName)
                                        }
                                        .autocorrectionDisabled(false)
                                        .textFieldStyle(.plain)
                                        .padding(4)
                                        .background(Color.BackgroundColorEditor)
                                        .border(Color.gray.opacity(0.25))
                                        .cornerRadius(4)
                                        .frame(maxWidth: 480)
                                        Spacer()
                                    }
                                    .frame(height: 20)
                                    HStack(alignment: .center) {
                                        ValidationLabel("Post URL: ", labelWidth: -mainLabelWidth, validation: !selectedFeature.feature.postLink.isEmpty, validColor: .green)
                                        ValidationLabel(selectedFeature.feature.postLink, validation: true, validColor: .AccentColor)
                                        Spacer()
                                        Button(action: {
                                            copyToClipboard(selectedFeature.feature.postLink)
                                            toastManager.showCompletedToast("Copied to clipboard", "Copied the post URL to the clipboard")
                                        }) {
                                            HStack(alignment: .center) {
                                                Image(systemName: "pencil.and.list.clipboard")
                                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                Text("Copy URL")
                                            }
                                        }
                                        .focusable()
                                        .onKeyPress(.space) {
                                            copyToClipboard(selectedFeature.feature.postLink)
                                            toastManager.showCompletedToast("Copied to clipboard", "Copied the post URL to the clipboard")
                                            return .handled
                                        }
                                        Spacer()
                                            .frame(width: 10)
                                        Button(action: {
                                            if let url = URL(string: selectedFeature.feature.postLink) {
                                                openURL(url)
                                            }
                                        }) {
                                            HStack(alignment: .center) {
                                                Image(systemName: "globe")
                                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                Text("Launch")
                                            }
                                        }
                                        .disabled(selectedFeature.feature.postLink.isEmpty)
                                        .focusable(!selectedFeature.feature.postLink.isEmpty)
                                        .onKeyPress(.space) {
                                            if let url = URL(string: selectedFeature.feature.postLink) {
                                                openURL(url)
                                            }
                                            return .handled
                                        }
                                    }
                                    .frame(height: 20)
                                    HStack(alignment: .center) {
                                        ValidationLabel("User profile URL: ", labelWidth: -mainLabelWidth, validation: !userProfileLink.isEmpty, validColor: .green)
                                        ValidationLabel(userProfileLink, validation: true, validColor: .AccentColor)
                                        Spacer()
                                        Button(action: {
                                            copyToClipboard(userProfileLink)
                                            toastManager.showCompletedToast("Copied to clipboard", "Copied the user profile URL to the clipboard")
                                        }) {
                                            HStack(alignment: .center) {
                                                Image(systemName: "pencil.and.list.clipboard")
                                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                Text("Copy URL")
                                            }
                                        }
                                        .focusable()
                                        .onKeyPress(.space) {
                                            copyToClipboard(userProfileLink)
                                            toastManager.showCompletedToast("Copied to clipboard", "Copied the user profile URL to the clipboard")
                                            return .handled
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
                                        .focusable(!userProfileLink.isEmpty)
                                        .onKeyPress(.space) {
                                            if let url = URL(string: userProfileLink) {
                                                openURL(url)
                                            }
                                            return .handled
                                        }
                                    }
                                    .frame(height: 20)
                                }
                                .frame(maxWidth: 1280)
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
                                            ValidationLabel("User name: ", labelWidth: -mainLabelWidth, validation: !userName.isEmpty, validColor: .green)
                                            ValidationLabel(userName, validation: true, validColor: .AccentColor)
                                            Spacer()
                                            ValidationLabel(
                                                "User name:", labelWidth: labelWidth,
                                                validation: !selectedFeature.feature.userName.isEmpty && !selectedFeature.feature.userName.contains(where: \.isNewline))
                                            HStack(alignment: .center) {
                                                TextField(
                                                    "enter the user name",
                                                    text: $selectedFeature.feature.userName.onChange { value in
                                                        updateList()
                                                        viewModel.markDocumentDirty()
                                                    }
                                                )
                                                .focusable()
                                                .focused(focusedField, equals: .postUserName)
                                            }
                                            .autocorrectionDisabled(false)
                                            .textFieldStyle(.plain)
                                            .padding(4)
                                            .background(Color.BackgroundColorEditor)
                                            .border(Color.gray.opacity(0.25))
                                            .cornerRadius(4)
                                            .frame(maxWidth: 240)
                                            Button(action: {
                                                selectedFeature.feature.userName = userName
                                            }) {
                                                HStack(alignment: .center) {
                                                    Image(systemName: "pencil.line")
                                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                    Text("Transfer")
                                                }
                                            }
                                            .disabled(userName.isEmpty)
                                            .focusable(!userName.isEmpty)
                                            .onKeyPress(.space) {
                                                if !userName.isEmpty {
                                                    selectedFeature.feature.userName = userName
                                                }
                                                return .handled
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 20)
                                        HStack(alignment: .center) {
                                            ValidationLabel("User BIO:", validation: !userBio.isEmpty, validColor: .green)
                                            Spacer()
                                            ValidationLabel("User level:", labelWidth: labelWidth, validation: selectedFeature.feature.userLevel != MembershipCase.none)
                                            Picker(
                                                "",
                                                selection: $selectedFeature.feature.userLevel.onChange { value in
                                                    navigateToUserLevel(.same)
                                                }
                                            ) {
                                                ForEach(MembershipCase.casesFor(hub: selectedPage.hub)) { level in
                                                    Text(level.rawValue)
                                                        .tag(level)
                                                        .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                                                }
                                            }
                                            .tint(Color.AccentColor)
                                            .accentColor(Color.AccentColor)
                                            .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                                            .focusable()
                                            .focused(focusedField, equals: .postUserLevel)
                                            .frame(maxWidth: 240)
                                            .onKeyPress(phases: .down) { keyPress in
                                                return navigateToUserLevelWithArrows(keyPress)
                                            }
                                            .onKeyPress(characters: .alphanumerics) { keyPress in
                                                return navigateToUserLevelWithPrefix(keyPress)
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        HStack(alignment: .top) {
                                            ScrollView {
                                                if #available(macOS 14.0, *) {
                                                    TextEditor(text: .constant(userBio))
                                                        .scrollIndicators(.never)
                                                        .focusable(false)
                                                        .frame(maxWidth: 620, maxHeight: .infinity, alignment: .leading)
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
                                                        .focusable(false)
                                                        .frame(maxWidth: 620, maxHeight: .infinity, alignment: .leading)
                                                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                                        .scrollContentBackground(.hidden)
                                                        .padding(4)
                                                        .autocorrectionDisabled(false)
                                                        .disableAutocorrection(false)
                                                        .font(.system(size: 18, design: .serif))
                                                }
                                            }
                                            .frame(maxHeight: 80)
                                            Spacer()
                                            Toggle(
                                                isOn: $selectedFeature.feature.userIsTeammate.onChange { value in
                                                    viewModel.markDocumentDirty()
                                                }
                                            ) {
                                                Text("User is a Team Mate")
                                                    .lineLimit(1)
                                                    .truncationMode(.tail)
                                            }
                                            .tint(Color.AccentColor)
                                            .accentColor(Color.AccentColor)
                                            .focusable()
                                            .focused(focusedField, equals: .postTeammate)
                                            .onKeyPress(.space) {
                                                selectedFeature.feature.userIsTeammate.toggle();
                                                viewModel.markDocumentDirty()
                                                return .handled
                                            }
                                        }
                                    }
                                    .frame(maxWidth: 1280)
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
                                            ValidationLabel(pageHashtagCheck, validation: !missingTag, validColor: .green)
                                            Spacer()
                                        }
                                        .frame(height: 20)
                                        HStack(alignment: .center) {
                                            ValidationLabel(excludedHashtagCheck, validation: !hasExcludedHashtag, validColor: .green)
                                            Spacer()
                                        }
                                        .frame(height: 20)
                                        HStack(alignment: .center) {
                                            ValidationLabel("Post description:", validation: !description.isEmpty, validColor: .green)
                                            Spacer()
                                            ValidationLabel("Description:", labelWidth: labelWidth, validation: !selectedFeature.feature.featureDescription.isEmpty)
                                            TextField(
                                                "enter the description",
                                                text: $selectedFeature.feature.featureDescription.onChange { value in
                                                    viewModel.markDocumentDirty()
                                                }
                                            )
                                            .focusable()
                                            .focused(focusedField, equals: .postDescription)
                                            .autocorrectionDisabled(false)
                                            .textFieldStyle(.plain)
                                            .padding(4)
                                            .background(Color.BackgroundColorEditor)
                                            .border(Color.gray.opacity(0.25))
                                            .cornerRadius(4)
                                            .frame(maxWidth: 320)
                                        }
                                        .frame(maxWidth: .infinity)
                                        ScrollView {
                                            HStack {
                                                if #available(macOS 14.0, *) {
                                                    TextEditor(text: .constant(description))
                                                        .scrollIndicators(.never)
                                                        .focusable(false)
                                                        .frame(maxWidth: 960, maxHeight: .infinity, alignment: .leading)
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
                                                        .focusable(false)
                                                        .frame(maxWidth: 960, maxHeight: .infinity, alignment: .leading)
                                                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                                                        .scrollContentBackground(.hidden)
                                                        .padding(4)
                                                        .autocorrectionDisabled(false)
                                                        .disableAutocorrection(false)
                                                        .font(.system(size: 14))
                                                }
                                                Spacer()
                                            }
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: 200)
                                    }
                                    .frame(maxWidth: 1280)
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
                                                    ValidationLabel("Found comments from page (possibly already featured on page): ", validation: true, validColor: .red)
                                                    Spacer()
                                                    Toggle(
                                                        isOn: $selectedFeature.feature.photoFeaturedOnPage.onChange { value in
                                                            updateList()
                                                            viewModel.markDocumentDirty()
                                                        }
                                                    ) {
                                                        Text("Photo already featured on page")
                                                            .lineLimit(1)
                                                            .truncationMode(.tail)
                                                    }
                                                    .tint(Color.AccentColor)
                                                    .accentColor(Color.AccentColor)
                                                    .focusable()
                                                    .focused(focusedField, equals: .postPhotoFeaturedOnPage)
                                                    .onKeyPress(.space) {
                                                        selectedFeature.feature.photoFeaturedOnPage.toggle();
                                                        updateList()
                                                        viewModel.markDocumentDirty()
                                                        return .handled
                                                    }
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
                                                                selectedFeature.feature.photoFeaturedOnPage = true
                                                                updateList()
                                                                viewModel.markDocumentDirty()
                                                            }) {
                                                                HStack(alignment: .center) {
                                                                    Image(systemName: "checkmark.square")
                                                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                                    Text("Mark post")
                                                                }
                                                            }
                                                            .focusable()
                                                            .onKeyPress(.space) {
                                                                selectedFeature.feature.photoFeaturedOnPage = true
                                                                updateList()
                                                                viewModel.markDocumentDirty()
                                                                return .handled
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
                                                    ValidationLabel("Found comments from hub (possibly already featured on another page): ", validation: true, validColor: .orange)
                                                    Spacer()
                                                    Toggle(
                                                        isOn: $selectedFeature.feature.photoFeaturedOnHub.onChange { value in
                                                            updateList()
                                                            viewModel.markDocumentDirty()
                                                        }
                                                    ) {
                                                        Text("Photo featured on hub")
                                                            .lineLimit(1)
                                                            .truncationMode(.tail)
                                                    }
                                                    .tint(Color.AccentColor)
                                                    .accentColor(Color.AccentColor)
                                                    .focusable()
                                                    .focused(focusedField, equals: .postPhotoFeaturedOnHub)
                                                    .onKeyPress(.space) {
                                                        selectedFeature.feature.photoFeaturedOnHub.toggle();
                                                        updateList()
                                                        viewModel.markDocumentDirty()
                                                        return .handled
                                                    }

                                                    if selectedFeature.feature.photoFeaturedOnHub {
                                                        Text("|")
                                                            .padding([.leading, .trailing], 8)

                                                        ValidationLabel(
                                                            "Last date featured:",
                                                            validation: !(selectedFeature.feature.photoLastFeaturedOnHub.isEmpty || selectedFeature.feature.photoLastFeaturedPage.isEmpty)
                                                        )
                                                        TextField(
                                                            "",
                                                            text: $selectedFeature.feature.photoLastFeaturedOnHub.onChange { value in
                                                                viewModel.markDocumentDirty()
                                                            }
                                                        )
                                                        .focusable()
                                                        .focused(focusedField, equals: .postPhotoLastFeaturedOnHub)
                                                        .autocorrectionDisabled(false)
                                                        .textFieldStyle(.plain)
                                                        .padding(4)
                                                        .background(Color.BackgroundColorEditor)
                                                        .border(Color.gray.opacity(0.25))
                                                        .cornerRadius(4)
                                                        .frame(maxWidth: 160)

                                                        TextField(
                                                            "on page",
                                                            text: $selectedFeature.feature.photoLastFeaturedPage.onChange { value in
                                                                viewModel.markDocumentDirty()
                                                            }
                                                        )
                                                        .focusable()
                                                        .focused(focusedField, equals: .postPhotoLastFeaturedPage)
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
                                                                selectedFeature.feature.photoFeaturedOnHub = true
                                                                selectedFeature.feature.photoLastFeaturedPage = comment.3
                                                                selectedFeature.feature.photoLastFeaturedOnHub = comment.2.formatTimestamp()
                                                                viewModel.markDocumentDirty()
                                                            }) {
                                                                HStack(alignment: .center) {
                                                                    Image(systemName: "checkmark.square")
                                                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                                                    Text("Mark post")
                                                                }
                                                            }
                                                            .focusable()
                                                            .onKeyPress(.space) {
                                                                selectedFeature.feature.photoFeaturedOnHub = true
                                                                selectedFeature.feature.photoLastFeaturedPage = comment.3
                                                                selectedFeature.feature.photoLastFeaturedOnHub = comment.2.formatTimestamp()
                                                                viewModel.markDocumentDirty()
                                                                return .handled
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
                                VStack(alignment: .center) {
                                    HStack(alignment: .center) {
                                        ValidationLabel("Image\(imageUrls.count == 1 ? "" : "s") found: ", validation: imageUrls.count > 0, validColor: .green)
                                        ValidationLabel("\(imageUrls.count)", validation: imageUrls.count > 0, validColor: .AccentColor)
                                        Spacer()
                                    }
                                    .frame(height: 20)
                                    .frame(maxWidth: 1280)
                                    .padding([.leading, .trailing])
                                    ScrollView(.horizontal) {
                                        VStack(alignment: .center) {
                                            HStack {
                                                ForEach(Array(imageUrls.enumerated()), id: \.offset) { index, imageUrl in
                                                    PostDownloaderImageView(
                                                        toastManager: toastManager,
                                                        imageUrl: imageUrl,
                                                        userName: userName,
                                                        index: index,
                                                        showImageValidationView: showImageValidationView)
                                                    .padding(.all, 0.001)
                                                }
                                            }
                                            .frame(minWidth: 20)
                                        }
                                        .padding([.leading, .bottom, .trailing])
                                    }
                                    .frame(minWidth: 20, maxWidth: 1280)
                                }
                                .padding([.top])
                                .frame(maxWidth: .infinity)
                                .background {
                                    Rectangle()
                                        .foregroundStyle(Color.BackgroundColorList)
                                        .cornerRadius(8)
                                        .opacity(0.5)
                                }
                            }

                            // Logging
                            VStack(alignment: .center) {
                                HStack(alignment: .top) {
                                    ValidationLabel("LOGGING: ", validation: true, validColor: .orange)
                                    Spacer()
                                    Button(action: {
                                        copyToClipboard(logging.map { $0.1 }.joined(separator: "\n"))
                                        toastManager.showCompletedToast("Copied to clipboard", "Copied the logging data to the clipboard")
                                    }) {
                                        HStack(alignment: .center) {
                                            Image(systemName: "pencil.and.list.clipboard")
                                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                            Text("Copy log")
                                        }
                                    }
                                    .focusable()
                                    .onKeyPress(.space) {
                                        copyToClipboard(logging.map { $0.1 }.joined(separator: "\n"))
                                        toastManager.showCompletedToast("Copied to clipboard", "Copied the logging data to the clipboard")
                                        return .handled
                                    }
                                }
                                .frame(maxWidth: 1280)
                                ScrollView(.horizontal) {
                                    ForEach(Array(logging.enumerated()), id: \.offset) { index, log in
                                        Text(log.1)
                                            .foregroundStyle(log.0, .black)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .frame(maxWidth: 1280, maxHeight: .infinity)
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
                }
                .keyboardShortcut(languagePrefix == "en" ? "`" : "x", modifiers: languagePrefix == "en" ? .command : [.command, .option])
                .disabled(toastManager.isShowingAnyToast)
            }
            .allowsHitTesting(!toastManager.isShowingAnyToast)
        }
        .frame(minWidth: 1024, minHeight: 600)
        .background(Color.BackgroundColor)
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
            pageComments = [];
            hubComments = [];
            moreComments = false
            commentCount = 0
            likeCount = 0
            toastManager.showProgressToast("Loading post data...")
            loadExcludedTagsForPage()
            Task.detached {
                await loadFeature()
            }
        }
    }
    
    @MainActor
    func parsePost(_ contents: String) {
        do {
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
                            let jsonString = String(scriptText[start..<end])
                                .replacingOccurrences(of: "\\\"", with: "\"")
                                .replacingOccurrences(of: "\\\"", with: "\"")
                            if let jsonData = jsonString.data(using: .utf8) {
                                let postData = try JSONDecoder().decode(PostData.self, from: jsonData)
                                if let profile = postData.loaderData?.entry0?.profile?.profile {
                                    userAlias = profile.username ?? ""
                                    logging.append((.blue, "User's alias: \(userAlias)"))
                                    userName = profile.name ?? ""
                                    logging.append((.blue, "User's name: \(userName)"))
                                    userProfileLink = profile.url ?? ""
                                    logging.append((.blue, "User's profile link: \(userProfileLink)"))
                                    userBio = (profile.bio ?? "").removeExtraSpaces()
                                    logging.append((.blue, "User's bio: \(userBio)"))
                                } else {
                                    logging.append((.red, "Failed to find the profile information, the account is likely private"))
                                    logging.append((.red, "Post must be handled manually in VERO app"))
                                }
                                if let post = postData.loaderData?.entry0?.post {
                                    postHashtags = []
                                    description = joinSegments(post.post?.caption, &postHashtags).removeExtraSpaces(includeNewlines: false)

                                    checkPageHashtags()
                                    checkExcludedHashtags()
                                    
                                    if let postImages = post.post?.images {
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
                                                                String(userName[userName.index(userName.startIndex, offsetBy: selectedPage.hub.count + 1)..<userName.endIndex].lowercased())
                                                            ))
                                                            logging.append((.red, "Found comment from page - possibly already featured on page"))
                                                        } else {
                                                            hubComments.append((
                                                                comment.author?.name ?? userName,
                                                                joinSegments(comment.content).removeExtraSpaces(),
                                                                (comment.timestamp ?? "").timestamp(),
                                                                String(userName[userName.index(userName.startIndex, offsetBy: selectedPage.hub.count + 1)..<userName.endIndex].lowercased())
                                                            ))
                                                            logging.append((.orange, "Found comment from another hub page - possibly already feature on another page"))
                                                        }
                                                    }
                                                }
                                            }
                                        } else {
                                            moreComments = commentCount != 0
                                            if moreComments {
                                                logging.append((.orange, "Not all comments found in post, check VERO app to see all comments"))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    debugPrint(error.localizedDescription)
                    toastManager.showToast(
                        .error(.orange),
                        "Failed to parse the post data on the post",
                        "Failed to parse the post information from the downloaded post - \(error.localizedDescription)",
                        .Failure,
                        {})
                }
            }
            
            if imageUrls.isEmpty {
                throw AccountError.PrivateAccount
            }
            
            postLoaded = true
        } catch let error as AccountError {
            logging.append((.red, "Failed to download and parse the post information - \(error.errorDescription ?? "unknown")"))
            logging.append((.red, "Post must be handled manually in VERO app"))
            toastManager.showFailureToast(
                "Failed to load and parse post",
                "Failed to download and parse the post information - \(error.errorDescription ?? "unknown")")
        } catch {
            logging.append((.red, "Failed to download and parse the post information - \(error.localizedDescription)"))
            logging.append((.red, "Post must be handled manually in VERO app"))
            toastManager.showFailureToast(
                "Failed to load and parse post",
                "Failed to download and parse the post information - \(error.localizedDescription)")
        }
    }
    
    /// Account error enumeration for throwing account-specifc error codes.
    enum AccountError: String, LocalizedError {
        case PrivateAccount = "Could not find any images, this account might be private"
        public var errorDescription: String? { self.rawValue }
    }
    
    /// Loads the feature using the postUrl.
    private func loadFeature() async {
        if let url = URL(string: selectedFeature.feature.postLink) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let session = URLSession.init(configuration: URLSessionConfiguration.default)
            session.dataTask(with: request) { data, response, error in
                if let data = data {
                    let contents = String(data: data, encoding: .utf8)!
                    Task { @MainActor in
                        parsePost(contents)
                        toastManager.hideAnyToast(true)
                    }
                } else if let error = error {
                    Task { @MainActor in
                        logging.append((.red, "Failed to download and parse the post information - \(error.localizedDescription)"))
                        logging.append((.red, "Post must be handled manually in VERO app"))
                        toastManager.hideAnyToast(true)
                        toastManager.showFailureToast(
                            "Failed to load and parse post",
                            "Failed to download and parse the post information - \(error.localizedDescription)")
                    }
                }
            }.resume()
        } else {
            Task { @MainActor in
                toastManager.hideAnyToast(true)
            }
        }
    }
    
    /// Navigates to a user level using the given direction.
    /// - Parameters:
    ///   - direction: The `Direction` for the navigation.
    private func navigateToUserLevel(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(MembershipCase.casesFor(hub: selectedPage.hub), selectedFeature.feature.userLevel, direction)
        if change {
            if direction != .same {
                selectedFeature.feature.userLevel = newValue
            }
            viewModel.markDocumentDirty()
        }
    }
    
    /// Navigates to a user level using the key press arrows.
    /// - Parameters:
    ///   - keyPress: The key press for the arrows.
    /// - Returns: The key press result.
    private func navigateToUserLevelWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToUserLevel(direction)
            return .handled
        }
        return .ignored
    }
    
    /// Navigates to a user level using the key press characters as a prefix.
    /// - Parameters:
    ///   - keyPress: The key press for the characters.
    /// - Returns: The key press result.
    private func navigateToUserLevelWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(MembershipCase.casesFor(hub: selectedPage.hub), selectedFeature.feature.userLevel, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.userLevel = newValue
            viewModel.markDocumentDirty()
            return .handled
        }
        return .ignored
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
            return pageHashTags.firstIndex(where: { pageHashTag in
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
