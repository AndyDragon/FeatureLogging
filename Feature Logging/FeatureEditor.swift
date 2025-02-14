//
//  FeatureEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import SwiftyBeaver

struct FeatureEditor: View {
    private var viewModel: ContentView.ViewModel
    private var selectedPage: ObservablePage
    @Bindable private var selectedFeature: ObservableFeatureWrapper
    @State private var focusedField: FocusState<FocusField?>.Binding
    private var close: () -> Void
    private var markDocumentDirty: () -> Void
    private var updateList: () -> Void

    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false

    private let labelWidth: CGFloat = 108
    private let logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ selectedPage: ObservablePage,
        _ selectedFeature: ObservableFeatureWrapper,
        _ focusedField: FocusState<FocusField?>.Binding,
        _ close: @escaping () -> Void,
        _ markDocumentDirty: @escaping () -> Void,
        _ updateList: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.selectedPage = selectedPage
        self.selectedFeature = selectedFeature
        self.focusedField = focusedField
        self.close = close
        self.markDocumentDirty = markDocumentDirty
        self.updateList = updateList
    }

    var body: some View {
        VStack {
            // Is picked
            IsPickedView()

            // Post link
            PostLinkView()

            // User alias
            UserAliasView()

            // User name
            UserNameView()

            // Member level and team mate
            UserLevelView()

            // Tag source
            TagSourceView()

            // Photo featured
            PhotoFeaturedView()

            // Feature description
            FeatureDescriptionView()

            // User featured
            if selectedPage.hub == "click" {
                ClickUserFeaturedView()
            } else if selectedPage.hub == "snap" {
                SnapUserFeaturedView()
            } else {
                OtherUserFeaturedView()
            }

            // Verification results
            VerificationResultsView()
        }
        .padding()
        .testBackground()
        .onAppear {
            focusedField.wrappedValue = .postLink
        }

        Spacer()
    }

    // MARK: - sub views

    fileprivate func IsPickedView() -> some View {
        HStack(alignment: .center) {
            Spacer()
                .frame(width: labelWidth + 16, alignment: .trailing)

            Toggle(
                isOn: $selectedFeature.feature.isPicked.onChange { _ in
                    updateList()
                    markDocumentDirty()
                }
            ) {
                Text("Picked as feature")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .picked)
            .onKeyPress(.space) {
                selectedFeature.feature.isPicked.toggle()
                updateList()
                markDocumentDirty()
                return .handled
            }

            Spacer()

            Button(action: {
                close()
            }) {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.label, Color.secondaryLabel)
            }
            .focusable()
            .onKeyPress(.space) {
                close()
                return .handled
            }
        }
    }

    fileprivate func PostLinkView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel("Post link:", labelWidth: labelWidth, validation: selectedFeature.feature.validatePostLink())
            TextField(
                "enter the post link",
                text: $selectedFeature.feature.postLink.onChange { _ in
                    markDocumentDirty()
                }
            )
            .focused(focusedField, equals: .postLink)
            .autocorrectionDisabled(false)
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.controlBackground.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)

            Button(action: {
                logger.verbose("Tapped on paste link button", context: "User")
                pasteClipboardToPostLink()
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "list.clipboard.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Paste")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                logger.verbose("Pressed space on paste link button", context: "User")
                pasteClipboardToPostLink()
                return .handled
            }

            Button(action: {
                logger.verbose("Tapped load post button", context: "User")
                if !selectedFeature.feature.postLink.isEmpty {
                    viewModel.visibleView = .PostDownloadView
                }
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Load post")
                        .font(.system(.body, design: .rounded).bold())
                        .foregroundStyle(Color.label, Color.secondaryLabel)
                    Text("  ⌘ L")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Color.gray, Color.secondaryLabel)
                }
            }
            .disabled(!selectedFeature.feature.postLink.starts(with: "https://vero.co/"))
            .keyboardShortcut("l", modifiers: .command)
            .focusable()
            .onKeyPress(.space) {
                logger.verbose("Pressed space on paste link button", context: "User")
                viewModel.visibleView = .PostDownloadView
                return .handled
            }
        }
    }

    fileprivate func UserAliasView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel("User alias:", labelWidth: labelWidth, validation: selectedFeature.feature.validateUserAlias(viewModel))
            TextField(
                "enter the user alias",
                text: $selectedFeature.feature.userAlias.onChange { _ in
                    markDocumentDirty()
                }
            )
            .focused(focusedField, equals: .userAlias)
            .autocorrectionDisabled(false)
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.controlBackground.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)

            Button(action: {
                pasteClipboardToUserAlias()
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "list.clipboard.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Paste")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                pasteClipboardToUserAlias()
                return .handled
            }
        }
    }
    
    fileprivate func UserNameView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel("User name:", labelWidth: labelWidth, validation: selectedFeature.feature.validateUserName())
            TextField(
                "enter the user name",
                text: $selectedFeature.feature.userName.onChange { _ in
                    updateList()
                    markDocumentDirty()
                }
            )
            .focused(focusedField, equals: .userName)
            .autocorrectionDisabled(false)
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.controlBackground.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)

            Button(action: {
                logger.verbose("Tapped on paste user name button", context: "User")
                pasteClipboardToUserName()
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "list.clipboard.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Paste")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                logger.verbose("Pressed space on paste user name button", context: "User")
                pasteClipboardToUserName()
                return .handled
            }
        }
    }

    fileprivate func UserLevelView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel("User level:", labelWidth: labelWidth, validation: selectedFeature.feature.validateUserLevel())
            Picker(
                "",
                selection: $selectedFeature.feature.userLevel.onChange { _ in
                    navigateToUserLevel(.same)
                }
            ) {
                ForEach(MembershipCase.casesFor(hub: selectedPage.hub)) { level in
                    Text(level.rawValue)
                        .tag(level)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .focusable()
            .focused(focusedField, equals: .userLevel)
            .onKeyPress(phases: .down) { keyPress in
                navigateToUserLevelWithArrows(keyPress)
            }
            .onKeyPress(characters: .alphanumerics) { keyPress in
                navigateToUserLevelWithPrefix(keyPress)
            }
            .frame(maxWidth: 320)

            Text("|")
                .padding([.leading, .trailing])

            Toggle(
                isOn: $selectedFeature.feature.userIsTeammate.onChange { _ in
                    markDocumentDirty()
                }
            ) {
                Text("User is a Team Mate")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .teammate)
            .onKeyPress(.space) {
                selectedFeature.feature.userIsTeammate.toggle()
                markDocumentDirty()
                return .handled
            }

            Spacer()
        }
    }

    fileprivate func TagSourceView() -> some View {
        HStack(alignment: .center) {
            Text("Found using:")
                .frame(width: labelWidth, alignment: .trailing)
            Picker(
                "",
                selection: $selectedFeature.feature.tagSource.onChange { _ in
                    navigateToTagSource(.same)
                }
            ) {
                ForEach(TagSourceCase.casesFor(hub: selectedPage.hub)) { source in
                    Text(source.rawValue)
                        .tag(source)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .focusable()
            .focused(focusedField, equals: .tagSource)
            .onKeyPress(phases: .down) { keyPress in
                navigateToTagSourceWithArrows(keyPress)
            }
            .onKeyPress(characters: .alphanumerics) { keyPress in
                navigateToTagSourceWithPrefix(keyPress)
            }
            .pickerStyle(.segmented)
        }
    }

    fileprivate func PhotoFeaturedView() -> some View {
        HStack(alignment: .center) {
            Spacer()
                .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

            // Photo featured on page
            Toggle(
                isOn: $selectedFeature.feature.photoFeaturedOnPage.onChange { _ in
                    updateList()
                    markDocumentDirty()
                }
            ) {
                Text("Photo already featured on page")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .photoFeatureOnPage)
            .onKeyPress(.space) {
                selectedFeature.feature.photoFeaturedOnPage.toggle()
                updateList()
                markDocumentDirty()
                return .handled
            }

            Text("|")
                .padding([.leading, .trailing])

            // Photo featured on hub
            Toggle(
                isOn: $selectedFeature.feature.photoFeaturedOnHub.onChange { _ in
                    updateList()
                    markDocumentDirty()
                }
            ) {
                Text("Photo featured on hub")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .photoFeatureOnHub)
            .onKeyPress(.space) {
                selectedFeature.feature.photoFeaturedOnHub.toggle()
                updateList()
                markDocumentDirty()
                return .handled
            }

            if selectedFeature.feature.photoFeaturedOnHub {
                Text("|")
                    .padding([.leading, .trailing])

                ValidationLabel("Last date featured:", validation: selectedFeature.feature.validatePhotoFeaturedOnHub())
                TextField(
                    "",
                    text: $selectedFeature.feature.photoLastFeaturedOnHub.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .photoLastFeaturedOnHub)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                TextField(
                    "on page",
                    text: $selectedFeature.feature.photoLastFeaturedPage.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .photoLastFeaturedPage)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
            }

            Spacer()
        }
    }

    fileprivate func FeatureDescriptionView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel("Description:", labelWidth: labelWidth, validation: selectedFeature.feature.validateDescription())
            TextField(
                "enter the description of the feature (not used in scripts)",
                text: $selectedFeature.feature.featureDescription.onChange { _ in
                    markDocumentDirty()
                }
            )
            .focused(focusedField, equals: .description)
            .autocorrectionDisabled(false)
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.controlBackground.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)
        }
    }

    fileprivate func ClickUserFeaturedOnPageView() -> some View {
        HStack(alignment: .center) {
            Spacer()
                .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

            Toggle(
                isOn: $selectedFeature.feature.userHasFeaturesOnPage.onChange { _ in
                    markDocumentDirty()
                }
            ) {
                Text("User featured on page")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .userHasFeaturesOnPage)
            .onKeyPress(.space) {
                selectedFeature.feature.userHasFeaturesOnPage.toggle()
                markDocumentDirty()
                return .handled
            }

            Text("|")
                .padding([.leading, .trailing])
                .opacity(selectedFeature.feature.userHasFeaturesOnPage ? 1 : 0)

            if selectedFeature.feature.userHasFeaturesOnPage {
                ValidationLabel("Last featured:", validation: selectedFeature.feature.validateUserFeaturedOnPage())
                TextField(
                    "last date featured",
                    text: $selectedFeature.feature.lastFeaturedOnPage.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .lastFeaturedOnPage)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                Text("|")
                    .padding([.leading, .trailing])

                Text("Feature count:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.featureCountOnPage.onChange { _ in
                        navigateToFeatureCountOnPage(75, .same)
                    }
                ) {
                    Text("many").tag("many")
                    ForEach(0 ..< 76) { value in
                        Text("\(value)").tag("\(value)")
                    }
                }
                .frame(maxWidth: 200)
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color.label)
                .focusable()
                .focused(focusedField, equals: .featureCountOnPage)
                .onKeyPress(phases: .down) { keyPress in
                    navigateToFeatureCountOnPageWithArrows(75, keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    navigateToFeatureCountOnPageWithPrefix(75, keyPress)
                }
            }

            Spacer()

            Button(action: {
                copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name)_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the page feature tag for the user to the clipboard")
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Copy tag")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name)_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the page feature tag for the user to the clipboard")
                return .handled
            }
        }
    }

    fileprivate func ClickUserFeaturedOnHubView() -> some View {
        HStack(alignment: .center) {
            Spacer()
                .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

            Toggle(
                isOn: $selectedFeature.feature.userHasFeaturesOnHub.onChange { _ in
                    markDocumentDirty()
                }
            ) {
                Text("User featured on Click")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .userHasFeaturesOnHub)
            .onKeyPress(.space) {
                selectedFeature.feature.userHasFeaturesOnHub.toggle()
                markDocumentDirty()
                return .handled
            }

            Text("|")
                .padding([.leading, .trailing])
                .opacity(selectedFeature.feature.userHasFeaturesOnHub ? 1 : 0)

            if selectedFeature.feature.userHasFeaturesOnHub {
                ValidationLabel("Last featured:", validation: selectedFeature.feature.validateUserFeaturedOnHub())
                TextField(
                    "last date featured",
                    text: $selectedFeature.feature.lastFeaturedOnHub.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .lastFeaturedOnHub)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                TextField(
                    "on page",
                    text: $selectedFeature.feature.lastFeaturedPage.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .lastFeaturedPage)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                Text("|")
                    .padding([.leading, .trailing])

                Text("Feature count:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.featureCountOnHub.onChange { _ in
                        navigateToFeatureCountOnHub(75, .same)
                    }
                ) {
                    Text("many").tag("many")
                    ForEach(0 ..< 76) { value in
                        Text("\(value)").tag("\(value)")
                    }
                }
                .frame(maxWidth: 200)
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color.label)
                .focusable()
                .focused(focusedField, equals: .featureCountOnHub)
                .onKeyPress(phases: .down) { keyPress in
                    navigateToFeatureCountOnHubWithArrows(75, keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    navigateToFeatureCountOnHubWithPrefix(75, keyPress)
                }
            }

            Spacer()

            Button(action: {
                copyToClipboard("\(includeHash ? "#" : "")click_featured_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the hub feature tag for the user to the clipboard")
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Copy tag")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                copyToClipboard("\(includeHash ? "#" : "")click_featured_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the hub feature tag for the user to the clipboard")
                return .handled
            }
        }
    }

    fileprivate func ClickUserFeaturedView() -> some View {
        VStack {
            // User featured on page
            ClickUserFeaturedOnPageView()

            //  User featured on hub
            ClickUserFeaturedOnHubView()
        }
    }

    fileprivate func SnapUserFeaturedOnPageView() -> some View {
        HStack(alignment: .center) {
            Spacer()
                .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

            Toggle(
                isOn: $selectedFeature.feature.userHasFeaturesOnPage.onChange { _ in
                    markDocumentDirty()
                }
            ) {
                Text("User featured on page")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .userHasFeaturesOnPage)
            .onKeyPress(.space) {
                selectedFeature.feature.userHasFeaturesOnPage.toggle()
                markDocumentDirty()
                return .handled
            }

            Text("|")
                .padding([.leading, .trailing])
                .opacity(selectedFeature.feature.userHasFeaturesOnPage ? 1 : 0)

            if selectedFeature.feature.userHasFeaturesOnPage {
                ValidationLabel("Last featured:", validation: selectedFeature.feature.validateUserFeaturedOnPage())
                TextField(
                    "last date featured",
                    text: $selectedFeature.feature.lastFeaturedOnPage.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .lastFeaturedOnPage)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                Text("|")
                    .padding([.leading, .trailing])

                Text("Feature count:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.featureCountOnPage.onChange { _ in
                        navigateToFeatureCountOnPage(20, .same)
                    }
                ) {
                    Text("many").tag("many")
                    ForEach(0 ..< 21) { value in
                        Text("\(value)").tag("\(value)")
                    }
                }
                .frame(maxWidth: 200)
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color.label)
                .focusable()
                .focused(focusedField, equals: .featureCountOnPage)
                .onKeyPress(phases: .down) { keyPress in
                    navigateToFeatureCountOnPageWithArrows(20, keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    navigateToFeatureCountOnPageWithPrefix(20, keyPress)
                }
            }

            Spacer()

            Button(action: {
                copyToClipboard(
                    "\(includeHash ? "#" : "")snap_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                )
                viewModel.showSuccessToast("Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard")
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Copy tag")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                copyToClipboard(
                    "\(includeHash ? "#" : "")snap_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                )
                viewModel.showSuccessToast("Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard")
                return .handled
            }

            Button(action: {
                copyToClipboard(
                    "\(includeHash ? "#" : "")raw_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                )
                viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard")
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Copy RAW tag")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                copyToClipboard(
                    "\(includeHash ? "#" : "")raw_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                )
                viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard")
                return .handled
            }
        }
    }

    fileprivate func SnapUserFeaturedOnHubView() -> some View {
        HStack(alignment: .center) {
            Spacer()
                .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

            Toggle(
                isOn: $selectedFeature.feature.userHasFeaturesOnHub.onChange { _ in
                    markDocumentDirty()
                }
            ) {
                Text("User featured on Snap / RAW")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .userHasFeaturesOnHub)
            .onKeyPress(.space) {
                selectedFeature.feature.userHasFeaturesOnHub.toggle()
                markDocumentDirty()
                return .handled
            }

            Text("|")
                .padding([.leading, .trailing])
                .opacity(selectedFeature.feature.userHasFeaturesOnHub ? 1 : 0)

            if selectedFeature.feature.userHasFeaturesOnHub {
                ValidationLabel("Last featured:", validation: selectedFeature.feature.validateUserFeaturedOnHub())
                TextField(
                    "last date featured",
                    text: $selectedFeature.feature.lastFeaturedOnHub.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .lastFeaturedOnHub)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                TextField(
                    "on page",
                    text: $selectedFeature.feature.lastFeaturedPage.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .lastFeaturedPage)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                Text("|")
                    .padding([.leading, .trailing])

                Text("Feature count:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.featureCountOnHub.onChange { _ in
                        navigateToFeatureCountOnHub(20, .same)
                    }
                ) {
                    Text("many").tag("many")
                    ForEach(0 ..< 21) { value in
                        Text("\(value)").tag("\(value)")
                    }
                }
                .frame(maxWidth: 200)
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color.label)
                .focusable()
                .focused(focusedField, equals: .featureCountOnHub)
                .onKeyPress(phases: .down) { keyPress in
                    navigateToFeatureCountOnHubWithArrows(20, keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    navigateToFeatureCountOnHubWithPrefix(20, keyPress)
                }
            }

            Spacer()

            Button(action: {
                copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard")
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Copy tag")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard")
                return .handled
            }

            Button(action: {
                copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard")
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Copy RAW tag")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard")
                return .handled
            }
        }
    }

    fileprivate func SnapUserFeaturedView() -> some View {
        VStack {
            // User featured on page
            SnapUserFeaturedOnPageView()

            // User featured on hub
            SnapUserFeaturedOnHubView()
        }
    }

    fileprivate func OtherUserFeaturedOnPageView() -> some View {
        HStack(alignment: .center) {
            Spacer()
                .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

            Toggle(
                isOn: $selectedFeature.feature.userHasFeaturesOnPage.onChange { _ in
                    markDocumentDirty()
                }
            ) {
                Text("User featured on page")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .userHasFeaturesOnPage)
            .onKeyPress(.space) {
                selectedFeature.feature.userHasFeaturesOnPage.toggle()
                markDocumentDirty()
                return .handled
            }

            Text("|")
                .padding([.leading, .trailing])
                .opacity(selectedFeature.feature.userHasFeaturesOnPage ? 1 : 0)

            if selectedFeature.feature.userHasFeaturesOnPage {
                ValidationLabel("Last featured:", validation: selectedFeature.feature.validateUserFeaturedOnPage())
                TextField(
                    "last date featured",
                    text: $selectedFeature.feature.lastFeaturedOnPage.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .focused(focusedField, equals: .lastFeaturedOnPage)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                Text("|")
                    .padding([.leading, .trailing])

                Text("Feature count:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.featureCountOnPage.onChange { _ in
                        navigateToFeatureCountOnPage(75, .same)
                    }
                ) {
                    Text("many").tag("many")
                    ForEach(0 ..< 51) { value in
                        Text("\(value)").tag("\(value)")
                    }
                }
                .frame(maxWidth: 200)
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color.label)
                .focusable()
                .focused(focusedField, equals: .featureCountOnPage)
                .onKeyPress(phases: .down) { keyPress in
                    navigateToFeatureCountOnPageWithArrows(50, keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    navigateToFeatureCountOnPageWithPrefix(50, keyPress)
                }
            }

            Spacer()

            Button(action: {
                copyToClipboard("\(includeHash ? "#" : "")\(selectedPage.name)_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the page feature tag for the user to the clipboard")
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Copy tag")
                }
            }
            .focusable()
            .onKeyPress(.space) {
                copyToClipboard("\(includeHash ? "#" : "")\(selectedPage.name)_\(selectedFeature.feature.userAlias)")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the page feature tag for the user to the clipboard")
                return .handled
            }
        }
    }

    fileprivate func OtherUserFeaturedView() -> some View {
        VStack {
            // User featured on page
            OtherUserFeaturedOnPageView()
        }
    }

    fileprivate func VerificationResultsView() -> some View {
        HStack(alignment: .center) {
            Text("Validation:")
                .frame(width: labelWidth, alignment: .trailing)
                .padding([.trailing], 8)

            Toggle(
                isOn: $selectedFeature.feature.tooSoonToFeatureUser.onChange { _ in
                    updateList()
                    markDocumentDirty()
                }
            ) {
                Text("Too soon to feature user")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .focusable()
            .focused(focusedField, equals: .tooSoonToFeatureUser)
            .onKeyPress(.space) {
                selectedFeature.feature.tooSoonToFeatureUser.toggle()
                updateList()
                markDocumentDirty()
                return .handled
            }

            Text("|")
                .padding([.leading, .trailing])

            Text("TinEye:")
            Picker(
                "",
                selection: $selectedFeature.feature.tinEyeResults.onChange { _ in
                    navigateToTinEyeResult(.same)
                }
            ) {
                ForEach(TinEyeResults.allCases) { source in
                    Text(source.rawValue)
                        .tag(source)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .focusable()
            .focused(focusedField, equals: .tinEyeResults)
            .onKeyPress(phases: .down) { keyPress in
                navigateToTinEyeResultWithArrows(keyPress)
            }
            .onKeyPress(characters: .alphanumerics) { keyPress in
                navigateToTinEyeResultWithPrefix(keyPress)
            }
            .frame(maxWidth: 320)

            Text("|")
                .padding([.leading, .trailing])

            Text("AI Check:")
            Picker(
                "",
                selection: $selectedFeature.feature.aiCheckResults.onChange { _ in
                    navigateToAiCheckResult(.same)
                }
            ) {
                ForEach(AiCheckResults.allCases) { source in
                    Text(source.rawValue)
                        .tag(source)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .focusable()
            .focused(focusedField, equals: .aiCheckResults)
            .onKeyPress(phases: .down) { keyPress in
                navigateToAiCheckResultWithArrows(keyPress)
            }
            .onKeyPress(characters: .alphanumerics) { keyPress in
                navigateToAiCheckResultWithPrefix(keyPress)
            }
            .frame(maxWidth: 320)

            Spacer()
        }
    }

    // MARK: - user level navigation

    private func navigateToUserLevel(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(MembershipCase.casesFor(hub: selectedPage.hub), selectedFeature.feature.userLevel, direction)
        if change {
            if direction != .same {
                selectedFeature.feature.userLevel = newValue
            }
            markDocumentDirty()
        }
    }

    private func navigateToUserLevelWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToUserLevel(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToUserLevelWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(MembershipCase.casesFor(hub: selectedPage.hub), selectedFeature.feature.userLevel, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.userLevel = newValue
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    // MARK: - tag source navigation

    private func navigateToTagSource(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(TagSourceCase.casesFor(hub: selectedPage.hub), selectedFeature.feature.tagSource, direction, allowWrap: false)
        if change {
            if direction != .same {
                selectedFeature.feature.tagSource = newValue
            }
            markDocumentDirty()
        }
    }

    private func navigateToTagSourceWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress, horizontal: true)
        if direction != .same {
            navigateToTagSource(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToTagSourceWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(TagSourceCase.casesFor(hub: selectedPage.hub), selectedFeature.feature.tagSource, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.tagSource = newValue
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    // MARK: - feature count on page navigation

    private func navigateToFeatureCountOnPage(_ maxCount: Int, _ direction: Direction) {
        let (change, newValue) = navigateGeneric(["many"] + (0 ..< (maxCount + 1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnPage, direction, allowWrap: false)
        if change {
            if direction != .same {
                selectedFeature.feature.featureCountOnPage = newValue
            }
            markDocumentDirty()
        }
    }

    private func navigateToFeatureCountOnPageWithArrows(_ maxCount: Int, _ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToFeatureCountOnPage(maxCount, direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToFeatureCountOnPageWithPrefix(_ maxCount: Int, _ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(["many"] + (0 ..< (maxCount + 1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnPage, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.featureCountOnPage = newValue
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    // MARK: - feature count on hub navigation

    private func navigateToFeatureCountOnHub(_ maxCount: Int, _ direction: Direction) {
        let (change, newValue) = navigateGeneric(["many"] + (0 ..< (maxCount + 1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnHub, direction, allowWrap: false)
        if change {
            if direction != .same {
                selectedFeature.feature.featureCountOnHub = newValue
            }
            markDocumentDirty()
        }
    }

    private func navigateToFeatureCountOnHubWithArrows(_ maxCount: Int, _ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToFeatureCountOnHub(maxCount, direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToFeatureCountOnHubWithPrefix(_ maxCount: Int, _ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(["many"] + (0 ..< (maxCount + 1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnHub, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.featureCountOnHub = newValue
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    // MARK: - tin eye result navigation

    private func navigateToTinEyeResult(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(TinEyeResults.allCases, selectedFeature.feature.tinEyeResults, direction)
        if change {
            if direction != .same {
                selectedFeature.feature.tinEyeResults = newValue
            }
            updateList()
            markDocumentDirty()
        }
    }

    private func navigateToTinEyeResultWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToTinEyeResult(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToTinEyeResultWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(TinEyeResults.allCases, selectedFeature.feature.tinEyeResults, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.tinEyeResults = newValue
            updateList()
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    // MARK: - ai check result navigation

    private func navigateToAiCheckResult(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(AiCheckResults.allCases, selectedFeature.feature.aiCheckResults, direction)
        if change {
            if direction != .same {
                selectedFeature.feature.aiCheckResults = newValue
            }
            updateList()
            markDocumentDirty()
        }
    }

    private func navigateToAiCheckResultWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToAiCheckResult(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToAiCheckResultWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(AiCheckResults.allCases, selectedFeature.feature.aiCheckResults, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.aiCheckResults = newValue
            updateList()
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }
}

extension FeatureEditor {
    // MARK: - clipboard utilities

    private func pasteClipboardToPostLink() {
        let linkText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        if linkText.starts(with: "https://vero.co/") {
            selectedFeature.feature.postLink = linkText
            let possibleUserAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
            // If the user doesn't have an alias, the link will have a single letter, often 'p'
            if possibleUserAlias.count > 1 {
                selectedFeature.feature.userAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
            }
        }
    }

    private func pasteClipboardToUserAlias() {
        let aliasText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        if aliasText.starts(with: "@") {
            selectedFeature.feature.userAlias = String(aliasText.dropFirst(1))
        } else {
            selectedFeature.feature.userAlias = aliasText
        }
        markDocumentDirty()
    }

    private func pasteClipboardToUserName() {
        let userText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        if userText.contains("@") {
            selectedFeature.feature.userName = (userText.split(separator: "@").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            selectedFeature.feature.userAlias = (userText.split(separator: "@").last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            selectedFeature.feature.userName = userText
        }
        markDocumentDirty()
    }
}
