//
//  FeatureEditor.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import AlertToast
import SwiftUI

struct FeatureEditor: View {
    @State private var viewModel: ContentView.ViewModel
    @State private var focusedField: FocusState<FocusField?>.Binding
    private var close: () -> Void
    private var updateList: () -> Void
    private var markDocumentDirty: () -> Void
    private var showDownloaderView: () -> Void
    private var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void

    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false

    private let labelWidth: CGFloat = 108

    init(
        _ viewModel: ContentView.ViewModel,
        _ focusedField: FocusState<FocusField?>.Binding,
        _ close: @escaping () -> Void,
        _ updateList: @escaping () -> Void,
        _ markDocumentDirty: @escaping () -> Void,
        _ showDownloaderView: @escaping () -> Void,
        _ showToast: @escaping (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void
    ) {
        self.viewModel = viewModel
        self.focusedField = focusedField
        self.close = close
        self.updateList = updateList
        self.markDocumentDirty = markDocumentDirty
        self.showDownloaderView = showDownloaderView
        self.showToast = showToast
    }

    var body: some View {
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
                // Is picked
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, alignment: .trailing)

                    Toggle(
                        isOn: selectedFeature.feature.isPicked.onChange { value in
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
                        selectedFeature.feature.isPicked.wrappedValue.toggle()
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
                        validation: !selectedFeature.feature.postLink.wrappedValue.isEmpty && !selectedFeature.feature.postLink.wrappedValue.contains(where: \.isNewline))
                    TextField(
                        "enter the post link",
                        text: selectedFeature.feature.postLink.onChange { value in
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
                        pasteClipboardToPostLink(selectedFeature)
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Paste")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        pasteClipboardToPostLink(selectedFeature)
                        return .handled
                    }

                    Button(action: {
                        if !selectedFeature.feature.postLink.wrappedValue.isEmpty {
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
                    .disabled(!selectedFeature.feature.postLink.wrappedValue.starts(with: "https://vero.co/"))
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
                            !(selectedFeature.feature.userAlias.wrappedValue.isEmpty || selectedFeature.feature.userAlias.wrappedValue.starts(with: "@")
                              || selectedFeature.feature.userAlias.wrappedValue.count <= 1) && !selectedFeature.feature.userAlias.wrappedValue.contains(where: \.isNewline))
                    TextField(
                        "enter the user alias",
                        text: selectedFeature.feature.userAlias.onChange { value in
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
                        pasteClipboardToUserAlias(selectedFeature)
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Paste")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        pasteClipboardToUserAlias(selectedFeature)
                        return .handled
                    }
                }

                // User name
                HStack(alignment: .center) {
                    ValidationLabel(
                        "User name:", labelWidth: labelWidth,
                        validation: !selectedFeature.feature.userName.wrappedValue.isEmpty && !selectedFeature.feature.userName.wrappedValue.contains(where: \.isNewline))
                    TextField(
                        "enter the user name",
                        text: selectedFeature.feature.userName.onChange { value in
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
                        pasteClipboardToUserName(selectedFeature)
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "list.clipboard.fill")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Paste")
                        }
                    }
                    .focusable()
                    .onKeyPress(.space) {
                        pasteClipboardToUserName(selectedFeature)
                        return .handled
                    }
                }

                // Member level and team mate
                HStack(alignment: .center) {
                    ValidationLabel("User level:", labelWidth: labelWidth, validation: selectedFeature.feature.userLevel.wrappedValue != MembershipCase.none)
                    Picker(
                        "",
                        selection: selectedFeature.feature.userLevel.onChange { value in
                            navigateToUserLevel(selectedPage.hub.wrappedValue, selectedFeature, .same)
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
                    .focused(focusedField, equals: .userLevel)
                    .onKeyPress(phases: .down) { keyPress in
                        let direction = directionFromModifiers(keyPress)
                        if direction != .same {
                            navigateToUserLevel(selectedPage.hub.wrappedValue, selectedFeature, direction)
                            return .handled
                        }
                        return .ignored
                    }

                    Text("|")
                        .padding([.leading, .trailing])

                    Toggle(
                        isOn: selectedFeature.feature.userIsTeammate.onChange { value in
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
                        selectedFeature.feature.userIsTeammate.wrappedValue.toggle();
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
                        selection: selectedFeature.feature.tagSource.onChange { value in
                            navigateToTagSource(selectedPage.hub.wrappedValue, selectedFeature, .same)
                        }
                    ) {
                        ForEach(TagSourceCase.casesFor(hub: selectedPage.hub.wrappedValue)) { source in
                            Text(source.rawValue)
                                .tag(source)
                                .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                        }
                    }
                    .focusable()
                    .focused(focusedField, equals: .tagSource)
                    .onKeyPress(phases: .down) { keyPress in
                        let direction = directionFromModifiers(keyPress, horizontal: true)
                        if direction != .same {
                            navigateToTagSource(selectedPage.hub.wrappedValue, selectedFeature, direction)
                            return .handled
                        }
                        return .ignored
                    }
                    .pickerStyle(.segmented)
                }

                // Photo featured
                HStack(alignment: .center) {
                    Spacer()
                        .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                    // Photo featured on page
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
                    .focused(focusedField, equals: .photoFeatureOnPage)
                    .onKeyPress(.space) {
                        selectedFeature.feature.photoFeaturedOnPage.wrappedValue.toggle();
                        updateList()
                        markDocumentDirty()
                        return .handled
                    }

                    Text("|")
                        .padding([.leading, .trailing])

                    // Photo featured on hub
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
                    .focused(focusedField, equals: .photoFeatureOnHub)
                    .onKeyPress(.space) {
                        selectedFeature.feature.photoFeaturedOnHub.wrappedValue.toggle();
                        updateList()
                        markDocumentDirty()
                        return .handled
                    }

                    if selectedFeature.feature.photoFeaturedOnHub.wrappedValue {
                        Text("|")
                            .padding([.leading, .trailing])

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
                        .focused(focusedField, equals: .photoLastFeaturedOnHub)
                        .autocorrectionDisabled(false)
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.BackgroundColorEditor)
                        .border(Color.gray.opacity(0.25))
                        .cornerRadius(4)

                        TextField(
                            "on page",
                            text: selectedFeature.feature.photoLastFeaturedPage.onChange { value in
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
                    ValidationLabel("Description:", labelWidth: labelWidth, validation: !selectedFeature.feature.featureDescription.wrappedValue.isEmpty)
                    TextField(
                        "enter the description of the feature (not used in scripts)",
                        text: selectedFeature.feature.featureDescription.onChange { value in
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
                if selectedPage.hub.wrappedValue == "click" {
                    // User featured on page
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                        Toggle(
                            isOn: selectedFeature.feature.userHasFeaturesOnPage.onChange { value in
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
                            selectedFeature.feature.userHasFeaturesOnPage.wrappedValue.toggle();
                            markDocumentDirty()
                            return .handled
                        }

                        Text("|")
                            .padding([.leading, .trailing])
                            .opacity(selectedFeature.feature.userHasFeaturesOnPage.wrappedValue ? 1 : 0)

                        if selectedFeature.feature.userHasFeaturesOnPage.wrappedValue {
                            ValidationLabel(
                                "Last date featured:",
                                validation: !selectedFeature.feature.lastFeaturedOnPage.wrappedValue.isEmpty)
                            TextField(
                                "",
                                text: selectedFeature.feature.lastFeaturedOnPage.onChange { value in
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
                                selection: selectedFeature.feature.featureCountOnPage.onChange { value in
                                    navigateToFeatureCountOnPage(75, selectedFeature, .same)
                                    markDocumentDirty()
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
                                let direction = directionFromModifiers(keyPress)
                                if direction != .same {
                                    navigateToFeatureCountOnPage(75, selectedFeature, direction)
                                    return .handled
                                }
                                return .ignored
                            }
                        }

                        Spacer()

                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the page feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                        .onKeyPress(.space) {
                            copyToClipboard("\(includeHash ? "#" : "")click_\(selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the page feature tag for the user to the clipboard", .Success) {}
                            return .handled
                        }
                    }

                    // User featured on hub
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                        Toggle(
                            isOn: selectedFeature.feature.userHasFeaturesOnHub.onChange { value in
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
                            selectedFeature.feature.userHasFeaturesOnHub.wrappedValue.toggle();
                            markDocumentDirty()
                            return .handled
                        }

                        Text("|")
                            .padding([.leading, .trailing])
                            .opacity(selectedFeature.feature.userHasFeaturesOnHub.wrappedValue ? 1 : 0)

                        if selectedFeature.feature.userHasFeaturesOnHub.wrappedValue {
                            ValidationLabel(
                                "Last date featured:",
                                validation: !(selectedFeature.feature.lastFeaturedOnHub.wrappedValue.isEmpty || selectedFeature.feature.lastFeaturedPage.wrappedValue.isEmpty))
                            TextField(
                                "",
                                text: selectedFeature.feature.lastFeaturedOnHub.onChange { value in
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
                                text: selectedFeature.feature.lastFeaturedPage.onChange { value in
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
                                selection: selectedFeature.feature.featureCountOnHub.onChange { value in
                                    navigateToFeatureCountOnHub(75, selectedFeature, .same)
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
                                let direction = directionFromModifiers(keyPress)
                                if direction != .same {
                                    navigateToFeatureCountOnHub(75, selectedFeature, direction)
                                    return .handled
                                }
                                return .ignored
                            }
                        }

                        Spacer()

                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")click_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the hub feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                        .onKeyPress(.space) {
                            copyToClipboard("\(includeHash ? "#" : "")click_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the hub feature tag for the user to the clipboard", .Success) {}
                            return .handled
                        }
                    }
                } else if selectedPage.hub.wrappedValue == "snap" {
                    // User featured on page
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                        Toggle(
                            isOn: selectedFeature.feature.userHasFeaturesOnPage.onChange { value in
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
                            selectedFeature.feature.userHasFeaturesOnPage.wrappedValue.toggle();
                            markDocumentDirty()
                            return .handled
                        }

                        Text("|")
                            .padding([.leading, .trailing])
                            .opacity(selectedFeature.feature.userHasFeaturesOnPage.wrappedValue ? 1 : 0)

                        if selectedFeature.feature.userHasFeaturesOnPage.wrappedValue {
                            ValidationLabel(
                                "Last date featured:",
                                validation: !selectedFeature.feature.lastFeaturedOnPage.wrappedValue.isEmpty)
                            TextField(
                                "",
                                text: selectedFeature.feature.lastFeaturedOnPage.onChange { value in
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
                                selection: selectedFeature.feature.featureCountOnPage.onChange { value in
                                    navigateToFeatureCountOnPage(20, selectedFeature, .same)
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
                                let direction = directionFromModifiers(keyPress)
                                if direction != .same {
                                    navigateToFeatureCountOnPage(20, selectedFeature, direction)
                                    return .handled
                                }
                                return .ignored
                            }

                            Text("|")
                                .padding([.leading, .trailing])

                            Text("Number of features on RAW page:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.featureCountOnRawPage.onChange { value in
                                    navigateToFeatureCountOnRawPage(20, selectedFeature, .same)
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
                                let direction = directionFromModifiers(keyPress)
                                if direction != .same {
                                    navigateToFeatureCountOnRawPage(20, selectedFeature, direction)
                                    return .handled
                                }
                                return .ignored
                            }
                        }

                        Spacer()

                        Button(action: {
                            copyToClipboard(
                                "\(includeHash ? "#" : "")snap_\(selectedPage.pageName.wrappedValue ?? selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)"
                            )
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard", .Success) {}
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
                                "\(includeHash ? "#" : "")snap_\(selectedPage.pageName.wrappedValue ?? selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)"
                            )
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap page feature tag for the user to the clipboard", .Success) {}
                            return .handled
                        }

                        Button(action: {
                            copyToClipboard(
                                "\(includeHash ? "#" : "")raw_\(selectedPage.pageName.wrappedValue ?? selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)"
                            )
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard", .Success) {}
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
                                "\(includeHash ? "#" : "")raw_\(selectedPage.pageName.wrappedValue ?? selectedPage.name.wrappedValue)_\(selectedFeature.feature.userAlias.wrappedValue)"
                            )
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW page feature tag for the user to the clipboard", .Success) {}
                            return .handled
                        }
                    }

                    // User featured on hub
                    HStack(alignment: .center) {
                        Spacer()
                            .frame(width: labelWidth + 16, height: 28, alignment: .trailing)

                        Toggle(
                            isOn: selectedFeature.feature.userHasFeaturesOnHub.onChange { value in
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
                            selectedFeature.feature.userHasFeaturesOnHub.wrappedValue.toggle();
                            markDocumentDirty()
                            return .handled
                        }

                        Text("|")
                            .padding([.leading, .trailing])
                            .opacity(selectedFeature.feature.userHasFeaturesOnPage.wrappedValue ? 1 : 0)

                        if selectedFeature.feature.userHasFeaturesOnHub.wrappedValue {
                            ValidationLabel(
                                "Last date featured:",
                                validation: !(selectedFeature.feature.lastFeaturedOnHub.wrappedValue.isEmpty || selectedFeature.feature.lastFeaturedPage.wrappedValue.isEmpty))
                            TextField(
                                "",
                                text: selectedFeature.feature.lastFeaturedOnHub.onChange { value in
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
                                text: selectedFeature.feature.lastFeaturedPage.onChange { value in
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
                                selection: selectedFeature.feature.featureCountOnHub.onChange { value in
                                    navigateToFeatureCountOnHub(20, selectedFeature, .same)
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
                                let direction = directionFromModifiers(keyPress)
                                if direction != .same {
                                    navigateToFeatureCountOnHub(20, selectedFeature, direction)
                                    return .handled
                                }
                                return .ignored
                            }

                            Text("|")
                                .padding([.leading, .trailing])

                            Text("Number of features on RAW:")
                            Picker(
                                "",
                                selection: selectedFeature.feature.featureCountOnRawHub.onChange { value in
                                    navigateToFeatureCountOnRawHub(20, selectedFeature, .same)
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
                                let direction = directionFromModifiers(keyPress)
                                if direction != .same {
                                    navigateToFeatureCountOnRawHub(20, selectedFeature, direction)
                                    return .handled
                                }
                                return .ignored
                            }
                        }

                        Spacer()

                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy tag")
                            }
                        }
                        .focusable()
                        .onKeyPress(.space) {
                            copyToClipboard("\(includeHash ? "#" : "")snap_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the Snap hub feature tag for the user to the clipboard", .Success) {}
                            return .handled
                        }

                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard", .Success) {}
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Copy RAW tag")
                            }
                        }
                        .focusable()
                        .onKeyPress(.space) {
                            copyToClipboard("\(includeHash ? "#" : "")raw_featured_\(selectedFeature.feature.userAlias.wrappedValue)")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the RAW hub feature tag for the user to the clipboard", .Success) {}
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
                        isOn: selectedFeature.feature.tooSoonToFeatureUser.onChange { value in
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
                        selectedFeature.feature.tooSoonToFeatureUser.wrappedValue.toggle();
                        updateList()
                        markDocumentDirty()
                        return .handled
                    }

                    Text("|")
                        .padding([.leading, .trailing])

                    Text("TinEye:")
                    Picker(
                        "",
                        selection: selectedFeature.feature.tinEyeResults.onChange { value in
                            navigateToTinEyeResult(selectedFeature, .same)
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
                        let direction = directionFromModifiers(keyPress)
                        if direction != .same {
                            navigateToTinEyeResult(selectedFeature, direction)
                            return .handled
                        }
                        return .ignored
                    }

                    Text("|")
                        .padding([.leading, .trailing])

                    Text("AI Check:")
                    Picker(
                        "",
                        selection: selectedFeature.feature.aiCheckResults.onChange { value in
                            navigateToAiCheckResult(selectedFeature, .same)
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
                        let direction = directionFromModifiers(keyPress)
                        if direction != .same {
                            navigateToAiCheckResult(selectedFeature, direction)
                            return .handled
                        }
                        return .ignored
                    }
                }
            }
            .padding()

            Spacer()
        }
    }

    private func pasteClipboardToPostLink(_ selectedFeature: Binding<SharedFeature>) {
        let linkText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        if linkText.starts(with: "https://vero.co/") {
            selectedFeature.feature.postLink.wrappedValue = linkText
            let possibleUserAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
            // If the user doesn't have an alias, the link will have a single letter, often 'p'
            if possibleUserAlias.count > 1 {
                selectedFeature.feature.userAlias.wrappedValue = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
            }
        }
    }

    private func pasteClipboardToUserAlias(_ selectedFeature: Binding<SharedFeature>) {
        let aliasText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        if aliasText.starts(with: "@") {
            selectedFeature.feature.userAlias.wrappedValue = String(aliasText.dropFirst(1))
        } else {
            selectedFeature.feature.userAlias.wrappedValue = aliasText
        }
        markDocumentDirty()
    }

    private func pasteClipboardToUserName(_ selectedFeature: Binding<SharedFeature>) {
        let userText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        if userText.contains("@") {
            selectedFeature.feature.userName.wrappedValue = (userText.split(separator: "@").first ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            selectedFeature.feature.userAlias.wrappedValue = (userText.split(separator: "@").last ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            selectedFeature.feature.userName.wrappedValue = userText
        }
        markDocumentDirty()
    }

    private func navigateToUserLevel(_ selectedHub: String, _ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        let result = navigateGeneric(MembershipCase.casesFor(hub: selectedHub), selectedFeature.feature.userLevel.wrappedValue, direction)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.userLevel.wrappedValue = result.1
            }
            markDocumentDirty()
        }
    }

    private func navigateToTagSource(_ selectedHub: String, _ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        let result = navigateGeneric(TagSourceCase.casesFor(hub: selectedHub), selectedFeature.feature.tagSource.wrappedValue, direction, allowWrap: false)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.tagSource.wrappedValue = result.1
            }
            markDocumentDirty()
        }
    }

    private func navigateToFeatureCountOnPage(_ maxCount: Int, _ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        var values = ["many"];
        for value in (0..<(maxCount+1)) {
            values.append("\(value)")
        }
        let result = navigateGeneric(values, selectedFeature.feature.featureCountOnPage.wrappedValue, direction, allowWrap: false)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.featureCountOnPage.wrappedValue = result.1
            }
            markDocumentDirty()
        }
    }

    private func navigateToFeatureCountOnHub(_ maxCount: Int, _ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        var values = ["many"];
        for value in (0..<(maxCount+1)) {
            values.append("\(value)")
        }
        let result = navigateGeneric(values, selectedFeature.feature.featureCountOnHub.wrappedValue, direction, allowWrap: false)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.featureCountOnHub.wrappedValue = result.1
            }
            markDocumentDirty()
        }
    }

    private func navigateToFeatureCountOnRawPage(_ maxCount: Int, _ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        var values = ["many"];
        for value in (0..<(maxCount+1)) {
            values.append("\(value)")
        }
        let result = navigateGeneric(values, selectedFeature.feature.featureCountOnRawPage.wrappedValue, direction, allowWrap: false)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.featureCountOnRawPage.wrappedValue = result.1
            }
            markDocumentDirty()
        }
    }

    private func navigateToFeatureCountOnRawHub(_ maxCount: Int, _ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        var values = ["many"];
        for value in (0..<(maxCount+1)) {
            values.append("\(value)")
        }
        let result = navigateGeneric(values, selectedFeature.feature.featureCountOnRawHub.wrappedValue, direction, allowWrap: false)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.featureCountOnRawHub.wrappedValue = result.1
            }
            markDocumentDirty()
        }
    }

    private func navigateToTinEyeResult(_ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        let result = navigateGeneric(TinEyeResults.allCases, selectedFeature.feature.tinEyeResults.wrappedValue, direction)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.tinEyeResults.wrappedValue = result.1
            }
            updateList()
            markDocumentDirty()
        }
    }

    private func navigateToAiCheckResult(_ selectedFeature: Binding<SharedFeature>, _ direction: Direction) {
        let result = navigateGeneric(AiCheckResults.allCases, selectedFeature.feature.aiCheckResults.wrappedValue, direction)
        if result.0 {
            if direction != .same {
                selectedFeature.feature.aiCheckResults.wrappedValue = result.1
            }
            updateList()
            markDocumentDirty()
        }
    }
}
