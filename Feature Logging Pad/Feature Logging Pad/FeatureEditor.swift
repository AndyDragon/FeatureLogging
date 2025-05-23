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
    private var close: () -> Void
    private var markDocumentDirty: () -> Void
    private var updateList: () -> Void

    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false

    private let labelWidth: CGFloat = 128
    private let logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ selectedPage: ObservablePage,
        _ selectedFeature: ObservableFeatureWrapper,
        _ close: @escaping () -> Void,
        _ markDocumentDirty: @escaping () -> Void,
        _ updateList: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.selectedPage = selectedPage
        self.selectedFeature = selectedFeature
        self.close = close
        self.markDocumentDirty = markDocumentDirty
        self.updateList = updateList
    }

    fileprivate func IsPackedView() -> some View {
        HStack(alignment: .center) {
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
            .frame(maxWidth: 200)

            Spacer()
        }
        .padding(.vertical, 2)
    }

    fileprivate func PostLinkView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel(validation: selectedFeature.feature.validatePostLink())
            TextField(
                "enter the post link",
                text: $selectedFeature.feature.postLink.onChange { _ in
                    markDocumentDirty()
                }
            )
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.backgroundColor.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)
            .autocapitalization(.none)
            .autocorrectionDisabled()

            Button(action: {
                logger.verbose("Tapped load post button", context: "User")
                if !selectedFeature.feature.postLink.isEmpty {
                    viewModel.visibleView = .PostDownloadView
                }
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                    Text("Load post")
                        .font(.system(.body, design: .rounded).bold())
                }
            }
            .disabled(!selectedFeature.feature.postLink.starts(with: "https://vero.co/"))
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 2)
    }

    fileprivate func UserAliasView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel(validation: selectedFeature.feature.validateUserAlias(viewModel))
            TextField(
                "enter the user alias without '@'",
                text: $selectedFeature.feature.userAlias.onChange { _ in
                    markDocumentDirty()
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
        .padding(.vertical, 2)
    }

    fileprivate func UserNameView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel(validation: selectedFeature.feature.validateUserName())
            TextField(
                "enter the user name",
                text: $selectedFeature.feature.userName.onChange { _ in
                    updateList()
                    markDocumentDirty()
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
        .padding(.vertical, 2)
    }

    fileprivate func MembershipView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel(validation: selectedFeature.feature.validateUserLevel())
            Text("User level:")
                .frame(alignment: .trailing)
            Picker(
                "",
                selection: $selectedFeature.feature.userLevel.onChange { _ in
                    markDocumentDirty()
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
            .frame(maxWidth: 240)

            Spacer()
        }
        .padding(.vertical, 2)
    }

    fileprivate func TagSourceView() -> some View {
        HStack(alignment: .center) {
            Picker(
                "",
                selection: $selectedFeature.feature.tagSource.onChange { _ in
                    markDocumentDirty()
                }
            ) {
                ForEach(TagSourceCase.casesFor(hub: selectedPage.hub)) { source in
                    Text(source.rawValue)
                        .tag(source)
                        .foregroundStyle(Color(UIColor.secondaryLabel), Color(UIColor.secondaryLabel))
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 2)
    }

    fileprivate func PhotoFeaturedOnPageView() -> some View {
        HStack(alignment: .center) {
            Toggle(
                isOn: $selectedFeature.feature.photoFeaturedOnPage.onChange { _ in
                    updateList()
                    markDocumentDirty()
                }
            ) {
                Text("Photo featured on page")
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .frame(minWidth: 280, maxWidth: 280)

            Spacer()
        }
        .padding(.vertical, 2)
    }

    fileprivate func PhotoFeaturedOnHubView() -> some View {
        HStack(alignment: .center) {
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
            .frame(minWidth: 280, maxWidth: 280)
            .padding(.trailing, 8)

            if selectedFeature.feature.photoFeaturedOnHub {
                Text("|")
                    .padding([.leading, .trailing])

                ValidationLabel(validation: selectedFeature.feature.validatePhotoFeaturedOnHub())
                TextField(
                    "last date featured",
                    text: $selectedFeature.feature.photoLastFeaturedOnHub.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocapitalization(.none)
                .autocorrectionDisabled()

                TextField(
                    "on page",
                    text: $selectedFeature.feature.photoLastFeaturedPage.onChange { _ in
                        markDocumentDirty()
                    }
                )
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.backgroundColor.opacity(0.5))
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            } else {
                Spacer()
            }
        }
        .padding(.vertical, 2)
    }

    fileprivate func FeatureDescriptionView() -> some View {
        HStack(alignment: .center) {
            ValidationLabel(validation: selectedFeature.feature.validateDescription())
            TextField(
                "enter the description of the feature (not used in scripts)",
                text: $selectedFeature.feature.featureDescription.onChange { _ in
                    markDocumentDirty()
                }
            )
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.backgroundColor.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)
            .autocapitalization(.none)
            .autocorrectionDisabled()
        }
        .padding(.vertical, 2)
        .padding(.bottom, 6)
        .overlay(VStack {
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.gray.opacity(0.25))
        }, alignment: .bottom)
    }

    fileprivate func ClickUserFeaturedOnPageView() -> some View {
        VStack {
            HStack(alignment: .center) {
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
                .frame(minWidth: 240, maxWidth: 240)
                .padding(.trailing, 8)

                // User featured on page
                if selectedFeature.feature.userHasFeaturesOnPage {
                    Text("|")
                        .padding([.leading, .trailing])

                    ValidationLabel(validation: selectedFeature.feature.validateUserFeaturedOnPage())
                    TextField(
                        "last date featured",
                        text: $selectedFeature.feature.lastFeaturedOnPage.onChange { _ in
                            markDocumentDirty()
                        }
                    )
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.backgroundColor.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }
                Spacer()
            }
            .padding(.vertical, 2)

            // User featured on page
            if selectedFeature.feature.userHasFeaturesOnPage {
                HStack(alignment: .center) {
                    Text("Feature count:")
                    Picker(
                        "",
                        selection: $selectedFeature.feature.featureCountOnPage.onChange { _ in
                            markDocumentDirty()
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
                    .foregroundStyle(Color.accentColor, Color(UIColor.label))

                    Spacer()
                }
                .padding(.vertical, 2)
            }

            // Copy tag
            HStack(alignment: .center) {
                Spacer()

                Button(action: {
                    copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name)_\(selectedFeature.feature.userAlias)")
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the page feature tag for the user to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy tag")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 2)
        }
    }

    fileprivate func ClickUserFeaturedOnHubView() -> some View {
        VStack {
            HStack(alignment: .center) {
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
                .frame(minWidth: 240, maxWidth: 240)
                .padding(.trailing, 8)

                // User featured on hub
                if selectedFeature.feature.userHasFeaturesOnHub {
                    Text("|")
                        .padding([.leading, .trailing])

                    ValidationLabel(validation: selectedFeature.feature.validateUserFeaturedOnHub())
                    TextField(
                        "last date featured",
                        text: $selectedFeature.feature.lastFeaturedOnHub.onChange { _ in
                            markDocumentDirty()
                        }
                    )
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.backgroundColor.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                    TextField(
                        "on page",
                        text: $selectedFeature.feature.lastFeaturedPage.onChange { _ in
                            markDocumentDirty()
                        }
                    )
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.backgroundColor.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }

                Spacer()
            }
            .padding(.vertical, 2)

            // User featured on hub
            if selectedFeature.feature.userHasFeaturesOnHub {
                HStack(alignment: .center) {
                    Text("Feature count:")
                    Picker(
                        "",
                        selection: $selectedFeature.feature.featureCountOnHub.onChange { _ in
                            markDocumentDirty()
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
                    .foregroundStyle(Color.accentColor, Color(UIColor.label))

                    Spacer()
                }
                .padding(.vertical, 2)
            }

            // Copy tag
            HStack(alignment: .center) {
                Spacer()

                Button(action: {
                    copyToClipboard("\(includeHash ? "#" : "")click_featured_\(selectedFeature.feature.userAlias)")
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the hub feature tag for the user to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy tag")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 2)
        }
    }

    fileprivate func ClickUserFeaturedView() -> some View {
        VStack {
            // User featured on page
            ClickUserFeaturedOnPageView()
                .padding(.bottom, 6)
                .overlay(VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.gray.opacity(0.25))
                }, alignment: .bottom)

            // User featured on hub
            ClickUserFeaturedOnHubView()
                .padding(.bottom, 6)
                .overlay(VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.gray.opacity(0.25))
                }, alignment: .bottom)
        }
    }

    fileprivate func SnapUserFeaturedOnPageView() -> some View {
        VStack {
            HStack(alignment: .center) {
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
                .frame(minWidth: 290, maxWidth: 290)

                // User featured on page
                if selectedFeature.feature.userHasFeaturesOnPage {
                    Text("|")
                        .padding([.leading, .trailing])

                    ValidationLabel(validation: selectedFeature.feature.validateUserFeaturedOnPage())
                    TextField(
                        "last date featured",
                        text: $selectedFeature.feature.lastFeaturedOnPage.onChange { _ in
                            markDocumentDirty()
                        }
                    )
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.backgroundColor.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }

                Spacer()
            }
            .padding(.vertical, 2)

            // User featured on page
            if selectedFeature.feature.userHasFeaturesOnPage {
                HStack(alignment: .center) {
                    Text("Feature count:")
                    Picker(
                        "",
                        selection: $selectedFeature.feature.featureCountOnPage.onChange { _ in
                            markDocumentDirty()
                        }
                    ) {
                        Text("many").tag("many")
                        ForEach(0 ..< 21) { value in
                            Text("\(value)").tag("\(value)")
                        }
                    }
                    .tint(Color.accentColor)
                    .accentColor(Color.accentColor)
                    .foregroundStyle(Color.accentColor, Color(UIColor.label))

                    Spacer()
                }
                .padding(.vertical, 2)
            }

            // Copy Tags
            HStack(alignment: .center) {
                Spacer()

                Button(action: {
                    copyToClipboard(
                        "\(includeHash ? "#" : "")snap_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                    )
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy tag")
                    }
                }
                .buttonStyle(.bordered)

                Button(action: {
                    copyToClipboard(
                        "\(includeHash ? "#" : "")raw_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                    )
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy RAW tag")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    fileprivate func SnapUserFeaturedOnHubView() -> some View {
        VStack {
            HStack(alignment: .center) {
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
                .frame(minWidth: 290, maxWidth: 290)

                // User featured on hub
                if selectedFeature.feature.userHasFeaturesOnHub {
                    Text("|")
                        .padding([.leading, .trailing])

                    ValidationLabel(validation: selectedFeature.feature.validateUserFeaturedOnHub())
                    TextField(
                        "last date featured",
                        text: $selectedFeature.feature.lastFeaturedOnHub.onChange { _ in
                            markDocumentDirty()
                        }
                    )
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.backgroundColor.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                    TextField(
                        "on page",
                        text: $selectedFeature.feature.lastFeaturedPage.onChange { _ in
                            markDocumentDirty()
                        }
                    )
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.backgroundColor.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }

                Spacer()
            }
            .padding(.vertical, 2)

            // User featured on hub
            if selectedFeature.feature.userHasFeaturesOnHub {
                HStack(alignment: .center) {
                    Text("Feature count:")
                    Picker(
                        "",
                        selection: $selectedFeature.feature.featureCountOnHub.onChange { _ in
                            markDocumentDirty()
                        }
                    ) {
                        Text("many").tag("many")
                        ForEach(0 ..< 21) { value in
                            Text("\(value)").tag("\(value)")
                        }
                    }
                    .tint(Color.accentColor)
                    .accentColor(Color.accentColor)
                    .foregroundStyle(Color.accentColor, Color(UIColor.label))

                    Spacer()
                }
                .padding(.vertical, 2)
            }

            HStack(alignment: .center) {
                Spacer()

                Button(action: {
                    copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(selectedFeature.feature.userAlias)")
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy tag")
                    }
                }
                .buttonStyle(.bordered)

                Button(action: {
                    copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(selectedFeature.feature.userAlias)")
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy RAW tag")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    fileprivate func SnapUserFeaturedView() -> some View {
        VStack {
            // User featured on page
            SnapUserFeaturedOnPageView()
                .padding(.bottom, 6)
                .overlay(VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.gray.opacity(0.25))
                }, alignment: .bottom)

            // User featured on hub
            SnapUserFeaturedOnHubView()
                .padding(.bottom, 6)
                .overlay(VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.gray.opacity(0.25))
                }, alignment: .bottom)
        }
    }

    fileprivate func OtherUserFeaturedOnPageView() -> some View {
        VStack {
            HStack(alignment: .center) {
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
                .frame(minWidth: 240, maxWidth: 240)
                .padding(.trailing, 8)

                // User featured on page
                if selectedFeature.feature.userHasFeaturesOnPage {
                    ValidationLabel(validation: selectedFeature.feature.validateUserFeaturedOnPage())
                    TextField(
                        "last date featured",
                        text: $selectedFeature.feature.lastFeaturedOnPage.onChange { _ in
                            markDocumentDirty()
                        }
                    )
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.backgroundColor.opacity(0.5))
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }
                Spacer()
            }
            .padding(.vertical, 2)

            // User featured on page
            if selectedFeature.feature.userHasFeaturesOnPage {
                HStack(alignment: .center) {
                    Text("Feature count:")
                    Picker(
                        "",
                        selection: $selectedFeature.feature.featureCountOnPage.onChange { _ in
                            markDocumentDirty()
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
                    .foregroundStyle(Color.accentColor, Color(UIColor.label))

                    Spacer()
                }
                .padding(.vertical, 2)
            }

            // Copy tag
            HStack(alignment: .center) {
                Spacer()

                Button(action: {
                    copyToClipboard("\(includeHash ? "#" : "")\(selectedPage.name)_\(selectedFeature.feature.userAlias)")
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the page feature tag for the user to the clipboard")
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                        Text("Copy tag")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 2)
        }
    }

    fileprivate func OtherUserFeaturedView() -> some View {
        VStack {
            // User featured on page
            OtherUserFeaturedOnPageView()
                .padding(.bottom, 6)
                .overlay(VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.gray.opacity(0.25))
                }, alignment: .bottom)
        }
    }

    fileprivate func ValidationResultsView() -> some View {
        VStack {
            HStack(alignment: .center) {
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
                .frame(minWidth: 320, maxWidth: 320)

                Spacer()
            }
            .padding(.vertical, 2)

            HStack(alignment: .center) {
                Text("TinEye:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.tinEyeResults.onChange { _ in
                        updateList()
                        markDocumentDirty()
                    }
                ) {
                    ForEach(TinEyeResults.allCases) { source in
                        Text(source.rawValue)
                            .tag(source)
                            .foregroundStyle(Color(UIColor.secondaryLabel), Color(UIColor.secondaryLabel))
                    }
                }
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color(UIColor.label))

                Text("|")
                    .padding([.leading, .trailing])

                Text("AI Check:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.aiCheckResults.onChange { _ in
                        updateList()
                        markDocumentDirty()
                    }
                ) {
                    ForEach(AiCheckResults.allCases) { source in
                        Text(source.rawValue)
                            .tag(source)
                            .foregroundStyle(Color(UIColor.secondaryLabel), Color(UIColor.secondaryLabel))
                    }
                }
                .tint(Color.accentColor)
                .accentColor(Color.accentColor)
                .foregroundStyle(Color.accentColor, Color(UIColor.label))

                Spacer()
            }
        }
    }

    var body: some View {
        VStack {
            // Is picked
            IsPackedView()

            // Post link
            PostLinkView()

            // User alias
            UserAliasView()

            // User name
            UserNameView()

            // Member level and team mate
            MembershipView()

            // Tag source
            TagSourceView()

            // Photo featured on page
            PhotoFeaturedOnPageView()

            // Photo featured on hub
            if selectedPage.hub == "click" || selectedPage.hub == "snap" {
                PhotoFeaturedOnHubView()
            }

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
            ValidationResultsView()
        }
        .padding()
        .testBackground()

        Spacer()
    }

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
