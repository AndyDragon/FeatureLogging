//
//  FeatureEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import AlertToast
import SwiftUI

struct FeatureEditor: View {
    private var toastManager: ContentView.ToastManager
    private var selectedPage: ObservablePage
    @Bindable private var selectedFeature: ObservableFeatureWrapper
    @State private var focusedField: FocusState<FocusField?>.Binding
    private var close: () -> Void
    private var markDocumentDirty: () -> Void
    private var updateList: () -> Void
    private var showDownloaderView: () -> Void

    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false

    private let labelWidth: CGFloat = 108

    init(
        _ toastManager: ContentView.ToastManager,
        _ selectedPage: ObservablePage,
        _ selectedFeature: ObservableFeatureWrapper,
        _ focusedField: FocusState<FocusField?>.Binding,
        _ close: @escaping () -> Void,
        _ markDocumentDirty: @escaping () -> Void,
        _ updateList: @escaping () -> Void,
        _ showDownloaderView: @escaping () -> Void
    ) {
        self.toastManager = toastManager
        self.selectedPage = selectedPage
        self.selectedFeature = selectedFeature
        self.focusedField = focusedField
        self.close = close
        self.markDocumentDirty = markDocumentDirty
        self.updateList = updateList
        self.showDownloaderView = showDownloaderView
    }

    var body: some View {
        VStack {
            // Is picked
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: labelWidth + 16, alignment: .trailing)

                Toggle(
                    isOn: $selectedFeature.feature.isPicked.onChange { value in
                        updateList()
                        markDocumentDirty()
                    }
                ) {
                    Text("Picked as feature")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .tint(Color.AccentColor)
                .accentColor(Color.AccentColor)
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
                        .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                }
                .focusable()
                .onKeyPress(.space) {
                    close()
                    return .handled
                }
            }

            // Post link
            HStack(alignment: .center) {
                ValidationLabel(
                    "Post link:", labelWidth: labelWidth,
                    validation: !selectedFeature.feature.postLink.isEmpty && !selectedFeature.feature.postLink.contains(where: \.isNewline))
                TextField(
                    "enter the post link",
                    text: $selectedFeature.feature.postLink.onChange { value in
                        markDocumentDirty()
                    }
                )
                .focusable()
                .focused(focusedField, equals: .postLink)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                Button(action: {
                    pasteClipboardToPostLink()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Paste")
                    }
                }
                .focusable()
                .onKeyPress(.space) {
                    pasteClipboardToPostLink()
                    return .handled
                }

                Button(action: {
                    if !selectedFeature.feature.postLink.isEmpty {
                        showDownloaderView()
                    }
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Load post")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                        Text("  ⌘ L")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.TextColorSecondary)
                    }
                }
                .disabled(!selectedFeature.feature.postLink.starts(with: "https://vero.co/"))
                .keyboardShortcut("l", modifiers: .command)
                .focusable()
                .onKeyPress(.space) {
                    showDownloaderView()
                    return .handled
                }
            }

            // User alias
            HStack(alignment: .center) {
                ValidationLabel(
                    "User alias:", labelWidth: labelWidth,
                    validation:
                        !(selectedFeature.feature.userAlias.isEmpty || selectedFeature.feature.userAlias.starts(with: "@")
                          || selectedFeature.feature.userAlias.count <= 1) && !selectedFeature.feature.userAlias.contains(where: \.isNewline))
                TextField(
                    "enter the user alias",
                    text: $selectedFeature.feature.userAlias.onChange { value in
                        markDocumentDirty()
                    }
                )
                .focusable()
                .focused(focusedField, equals: .userAlias)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                Button(action: {
                    pasteClipboardToUserAlias()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Paste")
                    }
                }
                .focusable()
                .onKeyPress(.space) {
                    pasteClipboardToUserAlias()
                    return .handled
                }
            }

            // User name
            HStack(alignment: .center) {
                ValidationLabel(
                    "User name:", labelWidth: labelWidth,
                    validation: !selectedFeature.feature.userName.isEmpty && !selectedFeature.feature.userName.contains(where: \.isNewline))
                TextField(
                    "enter the user name",
                    text: $selectedFeature.feature.userName.onChange { value in
                        updateList()
                        markDocumentDirty()
                    }
                )
                .focusable()
                .focused(focusedField, equals: .userName)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)

                Button(action: {
                    pasteClipboardToUserName()
                }) {
                    HStack(alignment: .center) {
                        Image(systemName: "list.clipboard.fill")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Paste")
                    }
                }
                .focusable()
                .onKeyPress(.space) {
                    pasteClipboardToUserName()
                    return .handled
                }
            }

            // Member level and team mate
            HStack(alignment: .center) {
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
                .focused(focusedField, equals: .userLevel)
                .onKeyPress(phases: .down) { keyPress in
                    return navigateToUserLevelWithArrows(keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    return navigateToUserLevelWithPrefix(keyPress)
                }

                Text("|")
                    .padding([.leading, .trailing])

                Toggle(
                    isOn: $selectedFeature.feature.userIsTeammate.onChange { value in
                        markDocumentDirty()
                    }
                ) {
                    Text("User is a Team Mate")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .tint(Color.AccentColor)
                .accentColor(Color.AccentColor)
                .focusable()
                .focused(focusedField, equals: .teammate)
                .onKeyPress(.space) {
                    selectedFeature.feature.userIsTeammate.toggle();
                    markDocumentDirty()
                    return .handled
                }
            }

            // Tag source
            HStack(alignment: .center) {
                Text("Found using:")
                    .frame(width: labelWidth, alignment: .trailing)
                Picker(
                    "",
                    selection: $selectedFeature.feature.tagSource.onChange { value in
                        navigateToTagSource(.same)
                    }
                ) {
                    ForEach(TagSourceCase.casesFor(hub: selectedPage.hub)) { source in
                        Text(source.rawValue)
                            .tag(source)
                            .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                    }
                }
                .focusable()
                .focused(focusedField, equals: .tagSource)
                .onKeyPress(phases: .down) { keyPress in
                    return navigateToTagSourceWithArrows(keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    return navigateToTagSourceWithPrefix(keyPress)
                }
                .pickerStyle(.segmented)
            }

            // Photo featured
            HStack(alignment: .center) {
                Spacer()
                    .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                // Photo featured on page
                Toggle(
                    isOn: $selectedFeature.feature.photoFeaturedOnPage.onChange { value in
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
                .focused(focusedField, equals: .photoFeatureOnPage)
                .onKeyPress(.space) {
                    selectedFeature.feature.photoFeaturedOnPage.toggle();
                    updateList()
                    markDocumentDirty()
                    return .handled
                }

                Text("|")
                    .padding([.leading, .trailing])

                // Photo featured on hub
                Toggle(
                    isOn: $selectedFeature.feature.photoFeaturedOnHub.onChange { value in
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
                .focused(focusedField, equals: .photoFeatureOnHub)
                .onKeyPress(.space) {
                    selectedFeature.feature.photoFeaturedOnHub.toggle();
                    updateList()
                    markDocumentDirty()
                    return .handled
                }

                if selectedFeature.feature.photoFeaturedOnHub {
                    Text("|")
                        .padding([.leading, .trailing])

                    ValidationLabel(
                        "Last date featured:",
                        validation: !(selectedFeature.feature.photoLastFeaturedOnHub.isEmpty || selectedFeature.feature.photoLastFeaturedPage.isEmpty)
                    )
                    TextField(
                        "",
                        text: $selectedFeature.feature.photoLastFeaturedOnHub.onChange { value in
                            markDocumentDirty()
                        }
                    )
                    .focusable()
                    .focused(focusedField, equals: .photoLastFeaturedOnHub)
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)

                    TextField(
                        "on page",
                        text: $selectedFeature.feature.photoLastFeaturedPage.onChange { value in
                            markDocumentDirty()
                        }
                    )
                    .focusable()
                    .focused(focusedField, equals: .photoLastFeaturedPage)
                    .autocorrectionDisabled(false)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                }

                Spacer()
            }

            // Feature description
            HStack(alignment: .center) {
                ValidationLabel("Description:", labelWidth: labelWidth, validation: !selectedFeature.feature.featureDescription.isEmpty)
                TextField(
                    "enter the description of the feature (not used in scripts)",
                    text: $selectedFeature.feature.featureDescription.onChange { value in
                        markDocumentDirty()
                    }
                )
                .focusable()
                .focused(focusedField, equals: .description)
                .autocorrectionDisabled(false)
                .textFieldStyle(.plain)
                .padding(4)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
            }

            // User featured
            if selectedPage.hub == "click" {
                // User featured on page
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                    Toggle(
                        isOn: $selectedFeature.feature.userHasFeaturesOnPage.onChange { value in
                            markDocumentDirty()
                        }
                    ) {
                        Text("User featured on page")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    .focused(focusedField, equals: .userHasFeaturesOnPage)
                    .onKeyPress(.space) {
                        selectedFeature.feature.userHasFeaturesOnPage.toggle();
                        markDocumentDirty()
                        return .handled
                    }

                    Text("|")
                        .padding([.leading, .trailing])
                        .opacity(selectedFeature.feature.userHasFeaturesOnPage ? 1 : 0)

                    if selectedFeature.feature.userHasFeaturesOnPage {
                        ValidationLabel(
                            "Last date featured:",
                            validation: !selectedFeature.feature.lastFeaturedOnPage.isEmpty)
                        TextField(
                            "",
                            text: $selectedFeature.feature.lastFeaturedOnPage.onChange { value in
                                markDocumentDirty()
                            }
                        )
                        .focusable()
                        .focused(focusedField, equals: .lastFeaturedOnPage)
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)

                        Text("|")
                            .padding([.leading, .trailing])

                        Text("Number of features on page:")
                        Picker(
                            "",
                            selection: $selectedFeature.feature.featureCountOnPage.onChange { value in
                                navigateToFeatureCountOnPage(75, .same)
                            }
                        ) {
                            Text("many").tag("many")
                            ForEach(0..<76) { value in
                                Text("\(value)").tag("\(value)")
                            }
                        }
                        .frame(maxWidth: 200)
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                        .focusable()
                        .focused(focusedField, equals: .featureCountOnPage)
                        .onKeyPress(phases: .down) { keyPress in
                            return navigateToFeatureCountOnPageWithArrows(75, keyPress)
                        }
                        .onKeyPress(characters: .alphanumerics) { keyPress in
                            return navigateToFeatureCountOnPageWithPrefix(75, keyPress)
                        }
                    }

                    Spacer()

                    Button(action: {
                        copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name)_\(selectedFeature.feature.userAlias)")
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the page feature tag for the user to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Copy tag")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name)_\(selectedFeature.feature.userAlias)")
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the page feature tag for the user to the clipboard")
                        return .handled
                    }
                }

                // User featured on hub
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                    Toggle(
                        isOn: $selectedFeature.feature.userHasFeaturesOnHub.onChange { value in
                            markDocumentDirty()
                        }
                    ) {
                        Text("User featured on Click")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    .focused(focusedField, equals: .userHasFeaturesOnHub)
                    .onKeyPress(.space) {
                        selectedFeature.feature.userHasFeaturesOnHub.toggle();
                        markDocumentDirty()
                        return .handled
                    }

                    Text("|")
                        .padding([.leading, .trailing])
                        .opacity(selectedFeature.feature.userHasFeaturesOnHub ? 1 : 0)

                    if selectedFeature.feature.userHasFeaturesOnHub {
                        ValidationLabel(
                            "Last date featured:",
                            validation: !(selectedFeature.feature.lastFeaturedOnHub.isEmpty || selectedFeature.feature.lastFeaturedPage.isEmpty))
                        TextField(
                            "",
                            text: $selectedFeature.feature.lastFeaturedOnHub.onChange { value in
                                markDocumentDirty()
                            }
                        )
                        .focusable()
                        .focused(focusedField, equals: .lastFeaturedOnHub)
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)

                        TextField(
                            "on page",
                            text: $selectedFeature.feature.lastFeaturedPage.onChange { value in
                                markDocumentDirty()
                            }
                        )
                        .focusable()
                        .focused(focusedField, equals: .lastFeaturedPage)
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)

                        Text("|")
                            .padding([.leading, .trailing])

                        Text("Number of features on Click:")
                        Picker(
                            "",
                            selection: $selectedFeature.feature.featureCountOnHub.onChange { value in
                                navigateToFeatureCountOnHub(75, .same)
                            }
                        ) {
                            Text("many").tag("many")
                            ForEach(0..<76) { value in
                                Text("\(value)").tag("\(value)")
                            }
                        }
                        .frame(maxWidth: 200)
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                        .focusable()
                        .focused(focusedField, equals: .featureCountOnHub)
                        .onKeyPress(phases: .down) { keyPress in
                            return navigateToFeatureCountOnHubWithArrows(75, keyPress)
                        }
                        .onKeyPress(characters: .alphanumerics) { keyPress in
                            return navigateToFeatureCountOnHubWithPrefix(75, keyPress)
                        }
                    }

                    Spacer()

                    Button(action: {
                        copyToClipboard("\(includeHash ? "#" : "")click_featured_\(selectedFeature.feature.userAlias)")
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the hub feature tag for the user to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Copy tag")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        copyToClipboard("\(includeHash ? "#" : "")click_featured_\(selectedFeature.feature.userAlias)")
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the hub feature tag for the user to the clipboard")
                        return .handled
                    }
                }
            } else if selectedPage.hub == "snap" {
                // User featured on page
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                    Toggle(
                        isOn: $selectedFeature.feature.userHasFeaturesOnPage.onChange { value in
                            markDocumentDirty()
                        }
                    ) {
                        Text("User featured on page")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    .focused(focusedField, equals: .userHasFeaturesOnPage)
                    .onKeyPress(.space) {
                        selectedFeature.feature.userHasFeaturesOnPage.toggle();
                        markDocumentDirty()
                        return .handled
                    }

                    Text("|")
                        .padding([.leading, .trailing])
                        .opacity(selectedFeature.feature.userHasFeaturesOnPage ? 1 : 0)

                    if selectedFeature.feature.userHasFeaturesOnPage {
                        ValidationLabel(
                            "Last date featured:",
                            validation: !selectedFeature.feature.lastFeaturedOnPage.isEmpty)
                        TextField(
                            "",
                            text: $selectedFeature.feature.lastFeaturedOnPage.onChange { value in
                                markDocumentDirty()
                            }
                        )
                        .focusable()
                        .focused(focusedField, equals: .lastFeaturedOnPage)
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)

                        Text("|")
                            .padding([.leading, .trailing])

                        Text("Number of features on Snap page:")
                        Picker(
                            "",
                            selection: $selectedFeature.feature.featureCountOnPage.onChange { value in
                                navigateToFeatureCountOnPage(20, .same)
                            }
                        ) {
                            Text("many").tag("many")
                            ForEach(0..<21) { value in
                                Text("\(value)").tag("\(value)")
                            }
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                        .focusable()
                        .focused(focusedField, equals: .featureCountOnPage)
                        .onKeyPress(phases: .down) { keyPress in
                            return navigateToFeatureCountOnPageWithArrows(20, keyPress)
                        }
                        .onKeyPress(characters: .alphanumerics) { keyPress in
                            return navigateToFeatureCountOnPageWithPrefix(20, keyPress)
                        }

                        Text("|")
                            .padding([.leading, .trailing])

                        Text("Number of features on RAW page:")
                        Picker(
                            "",
                            selection: $selectedFeature.feature.featureCountOnRawPage.onChange { value in
                                navigateToFeatureCountOnRawPage(20, .same)
                            }
                        ) {
                            Text("many").tag("many")
                            ForEach(0..<21) { value in
                                Text("\(value)").tag("\(value)")
                            }
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                        .focusable()
                        .focused(focusedField, equals: .featureCountOnRawPage)
                        .onKeyPress(phases: .down) { keyPress in
                            return navigateToFeatureCountOnRawPageWithArrows(20, keyPress)
                        }
                        .onKeyPress(characters: .alphanumerics) { keyPress in
                            return navigateToFeatureCountOnRawPageWithPrefix(20, keyPress)
                        }
                    }

                    Spacer()

                    Button(action: {
                        copyToClipboard(
                            "\(includeHash ? "#" : "")snap_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                        )
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Copy tag")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        copyToClipboard(
                            "\(includeHash ? "#" : "")snap_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                        )
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard")
                        return .handled
                    }

                    Button(action: {
                        copyToClipboard(
                            "\(includeHash ? "#" : "")raw_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                        )
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Copy RAW tag")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        copyToClipboard(
                            "\(includeHash ? "#" : "")raw_\(selectedPage.pageName ?? selectedPage.name)_\(selectedFeature.feature.userAlias)"
                        )
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard")
                        return .handled
                    }
                }

                // User featured on hub
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                    Toggle(
                        isOn: $selectedFeature.feature.userHasFeaturesOnHub.onChange { value in
                            markDocumentDirty()
                        }
                    ) {
                        Text("User featured on Snap / RAW")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .focusable()
                    .focused(focusedField, equals: .userHasFeaturesOnHub)
                    .onKeyPress(.space) {
                        selectedFeature.feature.userHasFeaturesOnHub.toggle();
                        markDocumentDirty()
                        return .handled
                    }

                    Text("|")
                        .padding([.leading, .trailing])
                        .opacity(selectedFeature.feature.userHasFeaturesOnHub ? 1 : 0)

                    if selectedFeature.feature.userHasFeaturesOnHub {
                        ValidationLabel(
                            "Last date featured:",
                            validation: !(selectedFeature.feature.lastFeaturedOnHub.isEmpty || selectedFeature.feature.lastFeaturedPage.isEmpty))
                        TextField(
                            "",
                            text: $selectedFeature.feature.lastFeaturedOnHub.onChange { value in
                                markDocumentDirty()
                            }
                        )
                        .focusable()
                        .focused(focusedField, equals: .lastFeaturedOnHub)
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)

                        TextField(
                            "on page",
                            text: $selectedFeature.feature.lastFeaturedPage.onChange { value in
                                markDocumentDirty()
                            }
                        )
                        .focusable()
                        .focused(focusedField, equals: .lastFeaturedPage)
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)

                        Text("|")
                            .padding([.leading, .trailing])

                        Text("Number of features on Snap:")
                        Picker(
                            "",
                            selection: $selectedFeature.feature.featureCountOnHub.onChange { value in
                                navigateToFeatureCountOnHub(20, .same)
                            }
                        ) {
                            Text("many").tag("many")
                            ForEach(0..<21) { value in
                                Text("\(value)").tag("\(value)")
                            }
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                        .focusable()
                        .focused(focusedField, equals: .featureCountOnHub)
                        .onKeyPress(phases: .down) { keyPress in
                            return navigateToFeatureCountOnHubWithArrows(20, keyPress)
                        }
                        .onKeyPress(characters: .alphanumerics) { keyPress in
                            return navigateToFeatureCountOnHubWithPrefix(20, keyPress)
                        }

                        Text("|")
                            .padding([.leading, .trailing])

                        Text("Number of features on RAW:")
                        Picker(
                            "",
                            selection: $selectedFeature.feature.featureCountOnRawHub.onChange { value in
                                navigateToFeatureCountOnRawHub(20, .same)
                            }
                        ) {
                            Text("many").tag("many")
                            ForEach(0..<21) { value in
                                Text("\(value)").tag("\(value)")
                            }
                        }
                        .tint(Color.AccentColor)
                        .accentColor(Color.AccentColor)
                        .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                        .focusable()
                        .focused(focusedField, equals: .featureCountOnRawHub)
                        .onKeyPress(phases: .down) { keyPress in
                            return navigateToFeatureCountOnRawHubWithArrows(20, keyPress)
                        }
                        .onKeyPress(characters: .alphanumerics) { keyPress in
                            return navigateToFeatureCountOnRawHubWithPrefix(20, keyPress)
                        }
                    }

                    Spacer()

                    Button(action: {
                        copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(selectedFeature.feature.userAlias)")
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Copy tag")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(selectedFeature.feature.userAlias)")
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard")
                        return .handled
                    }

                    Button(action: {
                        copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(selectedFeature.feature.userAlias)")
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard")
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Copy RAW tag")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(selectedFeature.feature.userAlias)")
                        toastManager.showCompletedToast("Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard")
                        return .handled
                    }
                }
            }

            // Verification results
            HStack(alignment: .center) {
                Text("Validation:")
                    .frame(width: labelWidth, alignment: .trailing)
                    .padding([.trailing], 8)

                Toggle(
                    isOn: $selectedFeature.feature.tooSoonToFeatureUser.onChange { value in
                        updateList()
                        markDocumentDirty()
                    }
                ) {
                    Text("Too soon to feature user")
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .tint(Color.AccentColor)
                .accentColor(Color.AccentColor)
                .focusable()
                .focused(focusedField, equals: .tooSoonToFeatureUser)
                .onKeyPress(.space) {
                    selectedFeature.feature.tooSoonToFeatureUser.toggle();
                    updateList()
                    markDocumentDirty()
                    return .handled
                }

                Text("|")
                    .padding([.leading, .trailing])

                Text("TinEye:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.tinEyeResults.onChange { value in
                        navigateToTinEyeResult(.same)
                    }
                ) {
                    ForEach(TinEyeResults.allCases) { source in
                        Text(source.rawValue)
                            .tag(source)
                            .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                    }
                }
                .tint(Color.AccentColor)
                .accentColor(Color.AccentColor)
                .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                .focusable()
                .focused(focusedField, equals: .tinEyeResults)
                .onKeyPress(phases: .down) { keyPress in
                    return navigateToTinEyeResultWithArrows(keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    return navigateToTinEyeResultWithPrefix(keyPress)
                }

                Text("|")
                    .padding([.leading, .trailing])

                Text("AI Check:")
                Picker(
                    "",
                    selection: $selectedFeature.feature.aiCheckResults.onChange { value in
                        navigateToAiCheckResult(.same)
                    }
                ) {
                    ForEach(AiCheckResults.allCases) { source in
                        Text(source.rawValue)
                            .tag(source)
                            .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                    }
                }
                .tint(Color.AccentColor)
                .accentColor(Color.AccentColor)
                .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                .focusable()
                .focused(focusedField, equals: .aiCheckResults)
                .onKeyPress(phases: .down) { keyPress in
                    return navigateToAiCheckResultWithArrows(keyPress)
                }
                .onKeyPress(characters: .alphanumerics) { keyPress in
                    return navigateToAiCheckResultWithPrefix(keyPress)
                }
            }
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

    // MARK: - user level navigation
    private func navigateToUserLevel( _ direction: Direction) {
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
        let (change, newValue) = navigateGeneric(["many"] + (0..<(maxCount+1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnPage, direction, allowWrap: false)
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
        let (change, newValue) = navigateGenericWithPrefix(["many"] + (0..<(maxCount+1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnPage, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.featureCountOnPage = newValue
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    // MARK: - feature count on hub navigation
    private func navigateToFeatureCountOnHub(_ maxCount: Int, _ direction: Direction) {
        let (change, newValue) = navigateGeneric(["many"] + (0..<(maxCount+1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnHub, direction, allowWrap: false)
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
        let (change, newValue) = navigateGenericWithPrefix(["many"] + (0..<(maxCount+1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnHub, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.featureCountOnHub = newValue
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    // MARK: - feature count on raw page navigation
    private func navigateToFeatureCountOnRawPage(_ maxCount: Int, _ direction: Direction) {
        let (change, newValue) = navigateGeneric(["many"] + (0..<(maxCount+1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnRawPage, direction, allowWrap: false)
        if change {
            if direction != .same {
                selectedFeature.feature.featureCountOnRawPage = newValue
            }
            markDocumentDirty()
        }
    }

    private func navigateToFeatureCountOnRawPageWithArrows(_ maxCount: Int, _ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToFeatureCountOnRawPage(maxCount, direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToFeatureCountOnRawPageWithPrefix(_ maxCount: Int, _ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(["many"] + (0..<(maxCount+1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnRawPage, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.featureCountOnRawPage = newValue
            markDocumentDirty()
            return .handled
        }
        return .ignored
    }

    // MARK: - feature count on raw hub navigation
    private func navigateToFeatureCountOnRawHub(_ maxCount: Int, _ direction: Direction) {
        let (change, newValue) = navigateGeneric(["many"] + (0..<(maxCount+1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnRawHub, direction, allowWrap: false)
        if change {
            if direction != .same {
                selectedFeature.feature.featureCountOnRawHub = newValue
            }
            markDocumentDirty()
        }
    }

    private func navigateToFeatureCountOnRawHubWithArrows(_ maxCount: Int, _ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToFeatureCountOnRawHub(maxCount, direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToFeatureCountOnRawHubWithPrefix(_ maxCount: Int, _ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(["many"] + (0..<(maxCount+1)).map({ "\($0)" }), selectedFeature.feature.featureCountOnRawHub, keyPress.characters.lowercased())
        if change {
            selectedFeature.feature.featureCountOnRawHub = newValue
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
