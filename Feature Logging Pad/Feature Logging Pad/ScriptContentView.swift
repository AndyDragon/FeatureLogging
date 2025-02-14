//
//  ScriptContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-01-03.
//

import CloudKit
import SwiftUI
import SwiftyBeaver

struct ScriptContentView: View {
    @AppStorage(
        "preference_includespace",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeSpace = false

    private var viewModel: ContentView.ViewModel
    private var selectedPage: ObservablePage
    private var selectedFeature: ObservableFeatureWrapper
    @ObservedObject private var featureScriptPlaceholders: PlaceholderList
    @ObservedObject private var commentScriptPlaceholders: PlaceholderList
    @ObservedObject private var originalPostScriptPlaceholders: PlaceholderList
    private var navigateToNextFeature: (_ forward: Bool) -> Void

    @State private var membershipValidation: ValidationResult = .valid
    @State private var userAliasValidation: ValidationResult = .valid
    @State private var userNameValidation: ValidationResult = .valid
    @State private var yourNameValidation: ValidationResult = .valid
    @State private var yourFirstNameValidation: ValidationResult = .valid
    @State private var pageValidation: ValidationResult = .valid
    @State private var featureScript = ""
    @State private var commentScript = ""
    @State private var originalPostScript = ""
    @State private var newMembership = NewMembershipCase.none
    @State private var newMembershipValidation: ValidationResult = .valid
    @State private var newMembershipScript = ""
    @State private var placeholderSheetCase = PlaceholderSheetCase.featureScript
    @State private var showingPlaceholderSheet = false
    @State private var scriptWithPlaceholdersInPlace = ""
    @State private var scriptWithPlaceholders = ""

    private let languagePrefix = Locale.preferredLanguageCode
    private let logger = SwiftyBeaver.self

    private var canCopyScripts: Bool {
        return !membershipValidation.isError
            && !userAliasValidation.isError
            && !yourNameValidation.isError
            && !yourFirstNameValidation.isError
            && !pageValidation.isError
    }

    private var canCopyNewMembershipScript: Bool {
        return newMembership != NewMembershipCase.none
            && !newMembershipValidation.isError
            && !userAliasValidation.isError
    }

    private var accordionHeightRatio = 3.5

    init(
        _ viewModel: ContentView.ViewModel,
        _ selectedPage: ObservablePage,
        _ selectedFeature: ObservableFeatureWrapper,
        _ featureScriptPlaceholders: PlaceholderList,
        _ commentScriptPlaceholders: PlaceholderList,
        _ originalPostScriptPlaceholders: PlaceholderList,
        _ navigateToNextFeature: @escaping (_ forward: Bool) -> Void
    ) {
        self.viewModel = viewModel
        self.selectedPage = selectedPage
        self.selectedFeature = selectedFeature
        self.featureScriptPlaceholders = featureScriptPlaceholders
        self.commentScriptPlaceholders = commentScriptPlaceholders
        self.originalPostScriptPlaceholders = originalPostScriptPlaceholders
        self.navigateToNextFeature = navigateToNextFeature
    }

    var body: some View {
        ZStack {
            VStack {
                // Fields
                FieldSummaryView()

                // Scripts
                MainScriptEditorsView()

                // New membership
                NewMembershipEditorView()
            }
            .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
            .padding()
            .sheet(isPresented: $showingPlaceholderSheet) {
                PlaceholderSheet(
                    placeholders: placeholderSheetCase == .featureScript
                        ? featureScriptPlaceholders
                        : placeholderSheetCase == .commentScript
                        ? commentScriptPlaceholders
                        : originalPostScriptPlaceholders,
                    scriptWithPlaceholders: $scriptWithPlaceholders,
                    scriptWithPlaceholdersInPlace: $scriptWithPlaceholdersInPlace,
                    isPresenting: $showingPlaceholderSheet,
                    transferPlaceholders: {
                        switch placeholderSheetCase {
                        case .featureScript:
                            transferPlaceholderValues(
                                featureScriptPlaceholders,
                                [commentScriptPlaceholders, originalPostScriptPlaceholders])
                            break
                        case .commentScript:
                            transferPlaceholderValues(
                                commentScriptPlaceholders,
                                [featureScriptPlaceholders, originalPostScriptPlaceholders])
                            break
                        case .originalPostScript:
                            transferPlaceholderValues(
                                originalPostScriptPlaceholders,
                                [featureScriptPlaceholders, commentScriptPlaceholders])
                            break
                        }
                    },
                    toastCopyToClipboard: { copiedSuffix in
                        var scriptName: String
                        switch placeholderSheetCase {
                        case .featureScript:
                            scriptName = "feature"
                            break
                        case .commentScript:
                            scriptName = "comment"
                            break
                        case .originalPostScript:
                            scriptName = "original post"
                            break
                        }
                        let suffix = copiedSuffix.isEmpty ? "" : " \(copiedSuffix)"
                        logger.verbose("Copied the \(scriptName) script", context: "system")
                        viewModel.showSuccessToast(
                            "Copied",
                            "Copied the \(scriptName) script\(suffix) to the clipboard")
                    })
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    if viewModel.pickedFeatures.count >= 2 {
                        Button(action: {
                            navigateToNextFeature(false)
                            populateFromSharedFeature()
                        }) {
                            HStack {
                                Image(systemName: "arrowtriangle.backward.fill")
                                    .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                                Text("Previous feature")
                            }
                            .padding(4)
                        }
                        .disabled(viewModel.hasModalToasts)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.visibleView = .FeatureListView
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("Close")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts)

                    Spacer()

                    if viewModel.pickedFeatures.count >= 2 {
                        Button(action: {
                            navigateToNextFeature(true)
                            populateFromSharedFeature()
                        }) {
                            HStack {
                                Image(systemName: "arrowtriangle.forward.fill")
                                    .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                                Text("Next feature")
                            }
                            .padding(4)
                        }
                        .disabled(viewModel.hasModalToasts)
                    }
                }
            }
            .safeToolbarVisibility(.visible, for: .bottomBar)
        }
        .onAppear {
            populateFromSharedFeature()
        }
        .onChange(of: includeSpace) {
            updateScripts()
        }
    }

    private func FieldSummaryView() -> some View {
        Group {
            // User
            HStack {
                // User alias
                if userAliasValidation != .valid {
                    userAliasValidation.getImage()
                }
                Text("User: ")
                    .foregroundStyle(
                        userAliasValidation.getColor(),
                        Color(UIColor.secondaryLabel)
                    )
                    .lineLimit(1)
                    .truncationMode(.tail)
                ZStack {
                    Text(selectedFeature.feature.userAlias)
                        .tint(Color.accentColor)
                        .accentColor(Color.accentColor)
                        .foregroundStyle(Color.accentColor, Color(UIColor.label))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.leading, .trailing], 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .overlay(VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.gray.opacity(0.25))
                }, alignment: .bottom)

                Text(" / ")
                    .foregroundStyle(
                        Color(UIColor.label),
                        Color(UIColor.secondaryLabel)
                    )
                    .lineLimit(1)
                    .truncationMode(.tail)

                // User name
                if userNameValidation != .valid {
                    userNameValidation.getImage()
                }
                ZStack {
                    Text(selectedFeature.feature.userName)
                        .tint(Color.accentColor)
                        .accentColor(Color.accentColor)
                        .foregroundStyle(Color.accentColor, Color(UIColor.label))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.leading, .trailing], 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .overlay(VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.gray.opacity(0.25))
                }, alignment: .bottom)

                // User level
                if membershipValidation != .valid {
                    membershipValidation.getImage()
                        .padding([.leading], 8)
                }
                Text("Level: ")
                    .foregroundStyle(
                        membershipValidation.getColor(),
                        Color(UIColor.secondaryLabel)
                    )
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding([.leading], 8)
                ZStack {
                    Text(selectedFeature.userLevel.rawValue)
                        .tint(Color.accentColor)
                        .accentColor(Color.accentColor)
                        .foregroundStyle(Color.accentColor, Color(UIColor.label))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.leading, .trailing], 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .overlay(VStack {
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundStyle(Color.gray.opacity(0.25))
                }, alignment: .bottom)
            }

            // Options
            HStack {
                HStack {
                    Text(selectedFeature.firstFeature ? "☑" : "☐")
                        .font(.system(size: 22, design: .monospaced))
                        .tint(Color.accentColor)
                        .accentColor(Color.accentColor)
                        .foregroundStyle(Color.accentColor, Color(UIColor.label))
                        .frame(alignment: .trailing)
                    Text("First feature on page")
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(alignment: .leading)
                }
                .padding([.leading], 8)

                let tagSource = selectedFeature.feature.tagSource
                if selectedPage.hub == "click" {
                    HStack {
                        Text(tagSource == TagSourceCase.clickCommunityTag ? "☑" : "☐")
                            .font(.system(size: 22, design: .monospaced))
                            .tint(Color.accentColor)
                            .accentColor(Color.accentColor)
                            .foregroundStyle(Color.accentColor, Color(UIColor.label))
                            .frame(alignment: .trailing)
                        Text("From community tag")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(alignment: .leading)
                    }
                    .padding([.leading], 8)

                    HStack {
                        Text(tagSource == TagSourceCase.clickHubTag ? "☑" : "☐")
                            .font(.system(size: 22, design: .monospaced))
                            .tint(Color.accentColor)
                            .accentColor(Color.accentColor)
                            .foregroundStyle(Color.accentColor, Color(UIColor.label))
                            .frame(alignment: .trailing)
                        Text("From hub tag")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(alignment: .leading)
                    }
                    .padding([.leading], 8)
                } else if selectedPage.hub == "snap" {
                    HStack {
                        Text((tagSource == TagSourceCase.snapRawPageTag || tagSource == TagSourceCase.snapRawCommunityTag) ? "☑" : "☐")
                            .font(.system(size: 22, design: .monospaced))
                            .tint(Color.accentColor)
                            .accentColor(Color.accentColor)
                            .foregroundStyle(Color.accentColor, Color(UIColor.label))
                            .frame(alignment: .trailing)
                        Text("From RAW tag")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(alignment: .leading)
                    }
                    .padding([.leading], 8)

                    HStack {
                        Text((tagSource == TagSourceCase.snapCommunityTag || tagSource == TagSourceCase.snapRawCommunityTag) ? "☑" : "☐")
                            .font(.system(size: 22, design: .monospaced))
                            .tint(Color.accentColor)
                            .accentColor(Color.accentColor)
                            .foregroundStyle(Color.accentColor, Color(UIColor.label))
                            .frame(alignment: .trailing)
                        Text("From community tag")
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(alignment: .leading)
                    }
                    .padding([.leading], 8)
                }

                Spacer()
            }
        }
    }

    private func MainScriptEditorsView() -> some View {
        Group {
            // Feature script output
            ScriptEditor(
                title: "Feature script:",
                script: $featureScript,
                minHeight: 72,
                maxHeight: .infinity,
                canCopy: canCopyScripts,
                hasPlaceholders: scriptHasPlaceholders(featureScript),
                copy: { force, withPlaceholders in
                    placeholderSheetCase = .featureScript
                    if copyScript(
                        featureScript,
                        featureScriptPlaceholders,
                        [commentScriptPlaceholders, originalPostScriptPlaceholders],
                        force: force,
                        withPlaceholders: withPlaceholders
                    ) {
                        logger.verbose("Copied the feature script", context: "system")
                        viewModel.showSuccessToast(
                            "Copied",
                            String {
                                "Copied the feature script\(withPlaceholders ? " with placeholders" : "") "
                                "to the clipboard"
                            })
                    }
                })

            // Comment script output
            ScriptEditor(
                title: "Comment script:",
                script: $commentScript,
                minHeight: 36,
                maxHeight: 36 * accordionHeightRatio,
                canCopy: canCopyScripts,
                hasPlaceholders: scriptHasPlaceholders(commentScript),
                copy: { force, withPlaceholders in
                    placeholderSheetCase = .commentScript
                    if copyScript(
                        commentScript,
                        commentScriptPlaceholders,
                        [featureScriptPlaceholders, originalPostScriptPlaceholders],
                        force: force,
                        withPlaceholders: withPlaceholders
                    ) {
                        logger.verbose("Copied the comment script", context: "system")
                        viewModel.showSuccessToast(
                            "Copied",
                            String {
                                "Copied the comment script\(withPlaceholders ? " with placeholders" : "") "
                                "to the clipboard"
                            })
                    }
                })

            // Original post script output
            ScriptEditor(
                title: "Original post script:",
                script: $originalPostScript,
                minHeight: 24,
                maxHeight: 24 * accordionHeightRatio,
                canCopy: canCopyScripts,
                hasPlaceholders: scriptHasPlaceholders(originalPostScript),
                copy: { force, withPlaceholders in
                    placeholderSheetCase = .originalPostScript
                    if copyScript(
                        originalPostScript,
                        originalPostScriptPlaceholders,
                        [featureScriptPlaceholders, commentScriptPlaceholders],
                        force: force,
                        withPlaceholders: withPlaceholders
                    ) {
                        logger.verbose("Copied the original post script", context: "system")
                        viewModel.showSuccessToast(
                            "Copied",
                            String {
                                "Copied the original post script\(withPlaceholders ? " with placeholders" : "") "
                                "to the clipboard"
                            })
                    }
                })
        }
    }

    private func NewMembershipEditorView() -> some View {
        Group {
            // New membership picker and script output
            NewMembershipEditor(
                newMembership: $newMembership,
                script: $newMembershipScript,
                selectedPage: selectedPage,
                minHeight: 36,
                maxHeight: 36 * accordionHeightRatio,
                onChanged: { newValue in
                    newMembershipValidation = validateNewMembership(value: newMembership)
                    newMembershipChanged(to: newValue)
                },
                valid: !newMembershipValidation.isError && !userAliasValidation.isError,
                canCopy: canCopyNewMembershipScript,
                copy: {
                    copyToClipboard(newMembershipScript)
                    logger.verbose("Copied the new membership script", context: "system")
                    viewModel.showSuccessToast(
                        "Copied",
                        "Copied the new membership script to the clipboard")
                })
        }
    }

    private func populateFromSharedFeature() {
        pageValidation = validatePage()
        yourNameValidation = validateYourName()
        yourFirstNameValidation = validateYourFirstName()
        userAliasValidation = validateUserAlias()
        userNameValidation = validateUserName()
        membershipValidation = validateMembership()
        newMembership = viewModel.selectedFeature!.newLevel
        newMembershipChanged(to: newMembership)

        clearPlaceholders()
        copyToClipboard("")

        updateScripts()
        updateNewMembershipScripts()
    }

    private func clearPlaceholders() {
        featureScriptPlaceholders.placeholderDict.removeAll()
        featureScriptPlaceholders.longPlaceholderDict.removeAll()
        commentScriptPlaceholders.placeholderDict.removeAll()
        commentScriptPlaceholders.longPlaceholderDict.removeAll()
        originalPostScriptPlaceholders.placeholderDict.removeAll()
        originalPostScriptPlaceholders.longPlaceholderDict.removeAll()
    }

    private func validatePage() -> ValidationResult {
        if viewModel.selectedPage == nil {
            return .error("Page is required")
        }
        return .valid
    }

    private func validateYourName() -> ValidationResult {
        if viewModel.yourName.count == 0 {
            return .error("Required value")
        } else if viewModel.yourName.first == "@" {
            return .error("Don't include the '@' in user names")
        }
        return .valid
    }

    private func validateYourFirstName() -> ValidationResult {
        if viewModel.yourFirstName.count == 0 {
            return .error("Required value")
        }
        return .valid
    }

    private func validateMembership() -> ValidationResult {
        if let page = viewModel.selectedPage {
            if let value = viewModel.selectedFeature?.userLevel {
                if value == MembershipCase.none {
                    return .error("Required value")
                }
                if !MembershipCase.caseValidFor(hub: page.hub, value) {
                    return .error("Not a valid value")
                }
                return .valid
            }
            return .error("No feature user level")
        }
        return .error("No page")
    }

    private func validateUserAlias() -> ValidationResult {
        if let page = viewModel.selectedPage {
            if let value = viewModel.selectedFeature?.feature.userAlias {
                if value.count == 0 {
                    return .error("Required value")
                } else if value.first! == "@" {
                    return .error("Don't include the '@' in user names")
                } else if value.count <= 1 {
                    return .error("Must be longer than one character")
                } else if value.contains(where: \.isNewline) {
                    return .error("Cannot contain newline characters")
                } else if value.contains(where: \.isWhitespace) {
                    return .error("Cannot contain whitespace characters")
                } else if viewModel.loadedCatalogs.disallowLists[page.hub]?.first(where: { disallow in disallow == value }) != nil {
                    return .error("User is on the disallow list")
                } else if viewModel.loadedCatalogs.cautionLists[page.hub]?.first(where: { caution in caution == value }) != nil {
                    return .warning("User is on the caution list")
                }
                return .valid
            }
            return .error("No feature user alias")
        }
        return .error("No page")
    }

    private func validateUserName() -> ValidationResult {
        if viewModel.selectedPage != nil {
            if let value = viewModel.selectedFeature?.feature.userName {
                if value.count == 0 {
                    return .error("Required value")
                } else if value.contains(where: \.isNewline) {
                    return .error("Cannot contain newline characters")
                }
                return .valid
            }
            return .error("No feature user name")
        }
        return .error("No page")
    }

    private func newMembershipChanged(to value: NewMembershipCase) {
        updateNewMembershipScripts()
    }

    private func validateNewMembership(value: NewMembershipCase) -> ValidationResult {
        if !NewMembershipCase.caseValidFor(hub: viewModel.selectedPage?.hub, value) {
            return .error("Not a valid value")
        }
        return .valid
    }

    private func copyScript(
        _ script: String,
        _ placeholders: PlaceholderList,
        _ otherPlaceholders: [PlaceholderList],
        force: Bool = false,
        withPlaceholders: Bool = false
    ) -> Bool {
        scriptWithPlaceholders = script
        scriptWithPlaceholdersInPlace = script
        placeholders.placeholderDict.forEach({ placeholder in
            scriptWithPlaceholders = scriptWithPlaceholders.replacingOccurrences(
                of: placeholder.key, with: placeholder.value.value)
        })
        placeholders.longPlaceholderDict.forEach({ placeholder in
            scriptWithPlaceholders = scriptWithPlaceholders.replacingOccurrences(
                of: placeholder.key, with: placeholder.value.value)
        })
        if withPlaceholders {
            copyToClipboard(scriptWithPlaceholdersInPlace)
            return true
        } else if !checkForPlaceholders(
            scriptWithPlaceholdersInPlace,
            placeholders,
            otherPlaceholders,
            force: force
        ) {
            copyToClipboard(scriptWithPlaceholders)
            return true
        }
        return false
    }

    private func transferPlaceholderValues(
        _ scriptPlaceholders: PlaceholderList,
        _ otherPlaceholders: [PlaceholderList]
    ) {
        scriptPlaceholders.placeholderDict.forEach { placeholder in
            otherPlaceholders.forEach { destinationPlaceholders in
                let destinationPlaceholderEntry = destinationPlaceholders.placeholderDict[placeholder.key]
                if destinationPlaceholderEntry != nil {
                    destinationPlaceholderEntry!.value = placeholder.value.value
                }
            }
        }
        scriptPlaceholders.longPlaceholderDict.forEach { placeholder in
            otherPlaceholders.forEach { destinationPlaceholders in
                let destinationPlaceholderEntry = destinationPlaceholders.longPlaceholderDict[placeholder.key]
                if destinationPlaceholderEntry != nil {
                    destinationPlaceholderEntry!.value = placeholder.value.value
                }
            }
        }
    }

    private func scriptHasPlaceholders(_ script: String) -> Bool {
        return !matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script).isEmpty || !matches(of: "\\[\\{([^\\}]*)\\}\\]", in: script).isEmpty
    }

    private func checkForPlaceholders(
        _ script: String,
        _ placeholders: PlaceholderList,
        _ otherPlaceholders: [PlaceholderList],
        force: Bool = false
    ) -> Bool {
        var needEditor: Bool = false
        var foundPlaceholders: [String] = []
        foundPlaceholders.append(contentsOf: matches(of: "\\[\\[([^\\]]*)\\]\\]", in: script))
        if foundPlaceholders.count != 0 {
            for placeholder in foundPlaceholders {
                let placeholderEntry = placeholders.placeholderDict[placeholder]
                if placeholderEntry == nil {
                    needEditor = true
                    var value: String?
                    otherPlaceholders.forEach { sourcePlaceholders in
                        let sourcePlaceholderEntry = sourcePlaceholders.placeholderDict[placeholder]
                        if (value == nil || value!.isEmpty)
                            && sourcePlaceholderEntry != nil
                            && !(sourcePlaceholderEntry?.value ?? "").isEmpty {
                            value = sourcePlaceholderEntry?.value
                        }
                    }
                    placeholders.placeholderDict[placeholder] = PlaceholderValue()
                    if value != nil {
                        placeholders.placeholderDict[placeholder]?.value = value!
                    }
                }
            }
        }
        var foundLongPlaceholders: [String] = []
        foundLongPlaceholders.append(contentsOf: matches(of: "\\[\\{([^\\}]*)\\}\\]", in: script))
        if foundLongPlaceholders.count != 0 {
            for placeholder in foundLongPlaceholders {
                let placeholderEntry = placeholders.longPlaceholderDict[placeholder]
                if placeholderEntry == nil {
                    needEditor = true
                    var value: String?
                    otherPlaceholders.forEach { sourcePlaceholders in
                        let sourcePlaceholderEntry = sourcePlaceholders.longPlaceholderDict[placeholder]
                        if (value == nil || value!.isEmpty)
                            && sourcePlaceholderEntry != nil
                            && !(sourcePlaceholderEntry?.value ?? "").isEmpty {
                            value = sourcePlaceholderEntry?.value
                        }
                    }
                    placeholders.longPlaceholderDict[placeholder] = PlaceholderValue()
                    if value != nil {
                        placeholders.longPlaceholderDict[placeholder]?.value = value!
                    }
                }
            }
        }
        if foundPlaceholders.count != 0 || foundLongPlaceholders.count != 0 {
            if (force || needEditor) && !showingPlaceholderSheet {
                logger.verbose("Script has manual placeholders, opening editor", context: "System")
                showingPlaceholderSheet.toggle()
                return true
            }
        }
        return false
    }

    private func updateScripts() {
        let currentPageName = viewModel.selectedPage?.id ?? ""
        let currentPageDisplayName = viewModel.selectedPage?.name ?? ""
        let scriptPageName = viewModel.selectedPage?.pageName ?? currentPageDisplayName
        let scriptPageHash = viewModel.selectedPage?.hashTag ?? currentPageDisplayName
        let scriptPageTitle = viewModel.selectedPage?.title ?? currentPageDisplayName
        let currentHubName = viewModel.selectedPage?.hub
        if !canCopyScripts {
            var validationErrors = ""
            if userAliasValidation != .valid {
                validationErrors += "User: " + userAliasValidation.unwrappedMessage + "\n"
            }
            if userNameValidation != .valid {
                validationErrors += "User: " + userNameValidation.unwrappedMessage + "\n"
            }
            if membershipValidation != .valid {
                validationErrors += "Level: " + membershipValidation.unwrappedMessage + "\n"
            }
            if yourNameValidation != .valid {
                validationErrors += "You: " + yourNameValidation.unwrappedMessage + "\n"
            }
            if yourFirstNameValidation != .valid {
                validationErrors += "Your first name: " + yourFirstNameValidation.unwrappedMessage + "\n"
            }
            if pageValidation != .valid {
                validationErrors += "Page: " + pageValidation.unwrappedMessage + "\n"
            }
            featureScript = validationErrors
            originalPostScript = ""
            commentScript = ""
        } else {
            var rawTag = false
            var communityTag = false
            var hubTag = false
            let tagSource = viewModel.selectedFeature?.feature.tagSource
            if currentHubName == "click" {
                communityTag = tagSource == .clickCommunityTag
                hubTag = tagSource == .clickHubTag
            } else if currentHubName == "snap" {
                rawTag = tagSource == .snapRawPageTag
                communityTag = tagSource == .snapCommunityTag
                hubTag = tagSource == .snapMembershipTag
            }
            let membershipString = viewModel.selectedFeature?.feature.userLevel.scriptMembershipStringForHub(hub: viewModel.selectedPage?.hub)

            featureScript = getTemplateFromCatalog(
                "feature",
                from: currentPageName,
                firstFeature: viewModel.selectedFeature?.firstFeature ?? false,
                rawTag: rawTag,
                communityTag: communityTag,
                hubTag: hubTag
            )
            .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
            .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageDisplayName)
            .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
            .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
            .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString ?? MembershipCase.commonArtist.rawValue)
            .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.selectedFeature?.feature.userAlias ?? "")
            .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
            .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
            .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.selectedPageStaffLevel.rawValue)
            .insertSpacesInUserTags(includeSpace)

            commentScript = getTemplateFromCatalog(
                "comment",
                from: currentPageName,
                firstFeature: viewModel.selectedFeature?.firstFeature ?? false,
                rawTag: rawTag,
                communityTag: communityTag,
                hubTag: hubTag
            )
            .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
            .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageDisplayName)
            .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
            .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
            .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString ?? MembershipCase.commonArtist.rawValue)
            .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.selectedFeature?.feature.userAlias ?? "")
            .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
            .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
            .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.selectedPageStaffLevel.rawValue)
            .insertSpacesInUserTags(includeSpace)

            originalPostScript = getTemplateFromCatalog(
                "original post",
                from: currentPageName,
                firstFeature: viewModel.selectedFeature?.firstFeature ?? false,
                rawTag: rawTag,
                communityTag: communityTag,
                hubTag: hubTag
            )
            .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
            .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageDisplayName)
            .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
            .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
            .replacingOccurrences(of: "%%MEMBERLEVEL%%", with: membershipString ?? MembershipCase.commonArtist.rawValue)
            .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.selectedFeature?.feature.userAlias ?? "")
            .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
            .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
            .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.selectedPageStaffLevel.rawValue)
            .insertSpacesInUserTags(includeSpace)
        }
    }

    private func getTemplateFromCatalog(
        _ templateName: String,
        from pageId: String,
        firstFeature: Bool,
        rawTag: Bool,
        communityTag: Bool,
        hubTag: Bool
    ) -> String {
        var template: Template!
        if viewModel.loadedCatalogs.waitingForTemplates {
            return ""
        }
        let templatePage = viewModel.loadedCatalogs.templatesCatalog.pages.first(where: { page in
            page.id == pageId
        })

        // check first feature AND raw AND community
        if firstFeature && rawTag && communityTag {
            template = templatePage?.templates.first(where: { template in
                template.name == "first raw community " + templateName
            })
        }

        // next check first feature AND raw
        if firstFeature && rawTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "first raw " + templateName
            })
        }

        // next check first feature AND community
        if firstFeature && communityTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "first community " + templateName
            })
        }

        // next check first feature AND hub
        if firstFeature && hubTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "first hub " + templateName
            })
        }

        // next check first feature
        if firstFeature && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "first " + templateName
            })
        }

        // next check raw
        if rawTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "raw " + templateName
            })
        }

        // next check raw AND community
        if rawTag && communityTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "raw community " + templateName
            })
        }

        // next check community
        if communityTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "community " + templateName
            })
        }

        // next check hub
        if hubTag && template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == "hub " + templateName
            })
        }

        // last check standard
        if template == nil {
            template = templatePage?.templates.first(where: { template in
                template.name == templateName
            })
        }

        return template?.template ?? ""
    }

    private func updateNewMembershipScripts() {
        if viewModel.loadedCatalogs.waitingForTemplates {
            newMembershipScript = ""
            return
        }
        let currentPageName = viewModel.selectedPage?.displayName ?? ""
        let scriptPageName = viewModel.selectedPage?.pageName ?? currentPageName
        let scriptPageHash = viewModel.selectedPage?.hashTag ?? currentPageName
        let scriptPageTitle = viewModel.selectedPage?.title ?? currentPageName
        let currentHubName = viewModel.selectedPage?.hub
        if !canCopyNewMembershipScript {
            var validationErrors = ""
            if newMembership != NewMembershipCase.none {
                if userAliasValidation != .valid {
                    validationErrors += "User: " + userAliasValidation.unwrappedMessage + "\n"
                }
                if userNameValidation != .valid {
                    validationErrors += "User: " + userNameValidation.unwrappedMessage + "\n"
                }
                if newMembershipValidation != .valid {
                    validationErrors += "New level: " + newMembershipValidation.unwrappedMessage + "\n"
                }
            }
            newMembershipScript = validationErrors
        } else {
            let templateName = NewMembershipCase.scriptFor(hub: currentHubName, newMembership)
            let template = viewModel.loadedCatalogs.templatesCatalog.specialTemplates.first(where: { template in
                template.name == templateName
            })
            if template == nil {
                newMembershipScript = ""
                return
            }
            newMembershipScript = template!.template
                .replacingOccurrences(of: "%%PAGENAME%%", with: scriptPageName)
                .replacingOccurrences(of: "%%FULLPAGENAME%%", with: currentPageName)
                .replacingOccurrences(of: "%%PAGETITLE%%", with: scriptPageTitle)
                .replacingOccurrences(of: "%%PAGEHASH%%", with: scriptPageHash)
                .replacingOccurrences(of: "%%USERNAME%%", with: viewModel.selectedFeature?.feature.userAlias ?? "")
                .replacingOccurrences(of: "%%YOURNAME%%", with: viewModel.yourName)
                .replacingOccurrences(of: "%%YOURFIRSTNAME%%", with: viewModel.yourFirstName)
                .replacingOccurrences(of: "%%STAFFLEVEL%%", with: viewModel.selectedPageStaffLevel.rawValue)
                .insertSpacesInUserTags(includeSpace)
        }
    }
}
