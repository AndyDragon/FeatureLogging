//
//  MainContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-25.
//

import SwiftUI
import SwiftyBeaver
import UniformTypeIdentifiers

struct MainContentView: View {
    // PREFS
    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFormat = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirstFormat = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false

    @Bindable private var viewModel: ContentView.ViewModel
    @State private var logURL: Binding<URL?>
    @State private var focusedField: FocusState<FocusField?>.Binding
    @State private var logDocument: Binding<LogDocument>
    @State private var showFileImporter: Binding<Bool>
    @State private var showFileExporter: Binding<Bool>
    @State private var reportDocument: Binding<ReportDocument>
    @State private var showReportFileExporter: Binding<Bool>
    @State private var documentDirtyAlertConfirmation: Binding<String>
    @State private var documentDirtyAfterSaveAction: Binding<() -> Void>
    @State private var documentDirtyAfterDismissAction: Binding<() -> Void>
    @State private var shouldScrollFeatureListToSelection: Binding<Bool>
    @State private var yourNameValidation: (valid: Bool, reason: String?) = (true, nil)
    @State private var yourFirstNameValidation: (valid: Bool, reason: String?) = (true, nil)
    private var updateStaffLevelForPage: () -> Void
    private var storeStaffLevelForPage: () -> Void
    private var saveLog: (_ file: URL) -> Void
    private var logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ logURL: Binding<URL?>,
        _ focusedField: FocusState<FocusField?>.Binding,
        _ logDocument: Binding<LogDocument>,
        _ showFileImporter: Binding<Bool>,
        _ showFileExporter: Binding<Bool>,
        _ reportDocument: Binding<ReportDocument>,
        _ showReportFileExporter: Binding<Bool>,
        _ documentDirtyAlertConfirmation: Binding<String>,
        _ documentDirtyAfterSaveAction: Binding<() -> Void>,
        _ documentDirtyAfterDismissAction: Binding<() -> Void>,
        _ shouldScrollFeatureListToSelection: Binding<Bool>,
        _ updateStaffLevelForPage: @escaping () -> Void,
        _ storeStaffLevelForPage: @escaping () -> Void,
        _ saveLog: @escaping (_ file: URL) -> Void
    ) {
        self.viewModel = viewModel
        self.logURL = logURL
        self.focusedField = focusedField
        self.logDocument = logDocument
        self.showFileImporter = showFileImporter
        self.showFileExporter = showFileExporter
        self.reportDocument = reportDocument
        self.showReportFileExporter = showReportFileExporter
        self.documentDirtyAlertConfirmation = documentDirtyAlertConfirmation
        self.documentDirtyAfterSaveAction = documentDirtyAfterSaveAction
        self.documentDirtyAfterDismissAction = documentDirtyAfterDismissAction
        self.shouldScrollFeatureListToSelection = shouldScrollFeatureListToSelection
        self.updateStaffLevelForPage = updateStaffLevelForPage
        self.storeStaffLevelForPage = storeStaffLevelForPage
        self.saveLog = saveLog
    }

    private let labelWidth: CGFloat = 80

    var body: some View {
        ZStack {
            VStack {
                // Page / staff level picker
                PageSelectorView()

                // You
                ModeratorView()

                // Feature editor
                VStack {
                    if let selectedPage = viewModel.selectedPage, let selectedFeature = viewModel.selectedFeature {
                        FeatureEditor(
                            viewModel,
                            selectedPage,
                            selectedFeature,
                            focusedField,
                            { viewModel.selectedFeature = nil },
                            { viewModel.markDocumentDirty() },
                            { shouldScrollFeatureListToSelection.wrappedValue.toggle() }
                        )
                    }
                }
                .frame(height: 360)
                .frame(maxWidth: .infinity)
                .background(Color.controlBackground.opacity(0.5))
                .border(Color.gray.opacity(0.25), width: 1)
                .cornerRadius(2)
                .padding([.bottom], 4)

                // Feature list buttons
                FeatureListButtonView()
                    .padding([.trailing], 2)

                // Feature list
                ScrollViewReader { proxy in
                    FeatureList(
                        viewModel
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(4)
                    .presentationBackground(.clear)
                    .onChange(
                        of: shouldScrollFeatureListToSelection.wrappedValue,
                        {
                            withAnimation {
                                proxy.scrollTo(viewModel.selectedFeature)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation {
                            viewModel.selectedFeature = nil
                        }
                    }
                    .focusable()
                    .focused(focusedField, equals: .featureList)
                }
                .scrollContentBackground(.hidden)
                .background(Color.controlBackground)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
            }
            .toolbar {
                // New log
                Button(action: {
                    logger.verbose("Tapped new log", context: "User")
                    let createNewLog = {
                        logURL.wrappedValue = nil
                        viewModel.selectedFeature = nil
                        viewModel.features = [ObservableFeature]()
                        viewModel.clearDocumentDirty()
                        logger.verbose("New log created", context: "System")
                    }
                    if viewModel.isDirty {
                        documentDirtyAfterSaveAction.wrappedValue = createNewLog
                        documentDirtyAfterDismissAction.wrappedValue = createNewLog
                        documentDirtyAlertConfirmation.wrappedValue = "Would you like to save this log file before creating a new log?"
                        viewModel.isShowingDocumentDirtyAlert.toggle()
                    } else {
                        createNewLog()
                    }
                }) {
                    HStack {
                        if #available(macOS 15.0, *) {
                            Image(systemName: "document.badge.plus")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        } else {
                            Image(systemName: "doc.badge.plus")
                                .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        }
                        Text("New log")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.label, Color.secondaryLabel)
                        Text("    ⌘ N")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.secondaryLabel)
                    }
                    .padding(4)
                }
                .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil || viewModel.features.isEmpty)

                // Open log
                Button(action: {
                    logger.verbose("Tapped open log", context: "User")
                    let openSavedLog = {
                        showFileImporter.wrappedValue.toggle()
                    }
                    if viewModel.isDirty {
                        documentDirtyAfterSaveAction.wrappedValue = openSavedLog
                        documentDirtyAfterDismissAction.wrappedValue = openSavedLog
                        documentDirtyAlertConfirmation.wrappedValue = "Would you like to save this log file before opening another log?"
                        viewModel.isShowingDocumentDirtyAlert.toggle()
                    } else {
                        openSavedLog()
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.on.square")
                            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        Text("Open log")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.label, Color.secondaryLabel)
                        Text("    ⌘ O")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.secondaryLabel)
                    }
                    .padding(4)
                }
                .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil)

                // Save log
                Button(action: {
                    logger.verbose("Tapped save log", context: "User")
                    logDocument.wrappedValue = LogDocument(page: viewModel.selectedPage!, features: viewModel.features)
                    if let file = logURL.wrappedValue {
                        saveLog(file)
                        viewModel.clearDocumentDirty()
                    } else {
                        showFileExporter.wrappedValue.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        Text("Save log")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.label, Color.secondaryLabel)
                        Text("    ⌘ S")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.secondaryLabel)
                    }
                    .padding(4)
                }
                .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil || viewModel.features.isEmpty)

                // Save report
                Button(action: {
                    logger.verbose("Tapped save report", context: "User")
                    reportDocument.wrappedValue = ReportDocument(initialText: viewModel.generateReport(personalMessageFormat, personalMessageFirstFormat))
                    showReportFileExporter.wrappedValue.toggle()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                        Text("Save report")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.label, Color.secondaryLabel)
                        Text("    ⌘ ⇧ S")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.secondaryLabel)
                    }
                    .padding(4)
                }
                .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil || viewModel.features.isEmpty)
            }
            .padding([.leading, .top, .trailing])
        }
        .onAppear {
            focusedField.wrappedValue = .addFeature
        }
        .testBackground()
    }

    // MARK: - sub views

    private func PageSelectorView() -> some View {
        HStack(alignment: .center) {
            Text("Page:")
                .frame(width: labelWidth - 5, alignment: .trailing)
            Picker(
                "",
                selection: $viewModel.selectedPage.onChange { _ in
                    navigateToPage(.same)
                }
            ) {
                ForEach(viewModel.loadedCatalogs.loadedPages) { page in
                    Text(page.displayName).tag(page)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .focusable(viewModel.features.isEmpty)
            .focused(focusedField, equals: .pagePicker)
            .onKeyPress(phases: .down) { keyPress in
                navigateToPageWithArrows(keyPress)
            }
            .onKeyPress(characters: .alphanumerics) { keyPress in
                navigateToPageWithPrefix(keyPress)
            }
            .disabled(!viewModel.features.isEmpty)

            // Page staff level picker
            Text("Page staff level: ")
                .padding([.leading])
                .lineLimit(1)
                .truncationMode(.tail)

            Picker(
                "",
                selection: $viewModel.selectedPageStaffLevel.onChange { _ in
                    navigateToPageStaffLevel(.same)
                }
            ) {
                ForEach(StaffLevelCase.casesFor(hub: viewModel.selectedPage?.hub)) { staffLevelCase in
                    Text(staffLevelCase.rawValue)
                        .tag(staffLevelCase)
                        .foregroundStyle(Color.secondaryLabel, Color.secondaryLabel)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color.label)
            .focusable()
            .focused(focusedField, equals: .staffLevel)
            .onKeyPress(phases: .down) { keyPress in
                navigateToPageStaffLevelWithArrows(keyPress)
            }
            .onKeyPress(characters: .alphanumerics) { keyPress in
                navigateToPageStaffLevelWithPrefix(keyPress)
            }
            .frame(maxWidth: 144)

            Menu("Copy tag", systemImage: "tag.fill") {
                Button(action: {
                    copyToClipboard("\(includeHash ? "#" : "")\(viewModel.selectedPage?.hub ?? "")_\(viewModel.selectedPage?.pageName ?? viewModel.selectedPage?.name ?? "")")
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the page tag to the clipboard")
                }) {
                    Text("Page tag")
                }
                if viewModel.selectedPage?.hub == "snap" {
                    Button(action: {
                        copyToClipboard("\(includeHash ? "#" : "")raw_\(viewModel.selectedPage?.pageName ?? viewModel.selectedPage?.name ?? "")")
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW page tag to the clipboard")
                    }) {
                        Text("RAW page tag")
                    }
                }
                Button(action: {
                    copyToClipboard("\(includeHash ? "#" : "")\(viewModel.selectedPage?.hub ?? "")_community")
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the community tag to the clipboard")
                }) {
                    Text("Community tag")
                }
                if viewModel.selectedPage?.hub == "snap" {
                    Button(action: {
                        copyToClipboard("\(includeHash ? "#" : "")raw_community")
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW community tag to the clipboard")
                    }) {
                        Text("RAW community tag")
                    }
                }
                Button(action: {
                    copyToClipboard("\(includeHash ? "#" : "")\(viewModel.selectedPage?.hub ?? "")_hub")
                    viewModel.showSuccessToast("Copied to clipboard", "Copied the hub tag to the clipboard")
                }) {
                    Text("Hub tag")
                }
                if viewModel.selectedPage?.hub == "snap" {
                    Button(action: {
                        copyToClipboard("\(includeHash ? "#" : "")raw_hub")
                        viewModel.showSuccessToast("Copied to clipboard", "Copied the RAW hub tag to the clipboard")
                    }) {
                        Text("RAW hub tag")
                    }
                }
            }
            .foregroundStyle(Color.accentColor, Color.secondaryLabel)
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .disabled(viewModel.selectedPage?.hub != "click" && viewModel.selectedPage?.hub != "snap")
            .frame(maxWidth: 132)
            .focusable()
            .focused(focusedField, equals: .copyTag)
            .onKeyPress(.space) {
                copyToClipboard("\(includeHash ? "#" : "")\(viewModel.selectedPage?.hub ?? "")_\(viewModel.selectedPage?.pageName ?? viewModel.selectedPage?.name ?? "")")
                viewModel.showSuccessToast("Copied to clipboard", "Copied the page tag to the clipboard")
                return .handled
            }
            .padding([.leading])
        }
    }

    private func ModeratorView() -> some View {
        HStack(alignment: .center) {
            // Your name editor
            ValidationLabel(
                "You:",
                labelWidth: labelWidth,
                validation: yourNameValidation.valid)
            TextField(
                "Enter your user name without '@'",
                text: $viewModel.yourName.onChange { value in
                    if value.count == 0 {
                        yourNameValidation = (false, "Required value")
                    } else if value.first! == "@" {
                        yourNameValidation = (false, "Don't include the '@' in user names")
                    } else {
                        yourNameValidation = (true, nil)
                    }
                    UserDefaults.standard.set(viewModel.yourName, forKey: "YourName")
                }
            )
            .focused(focusedField, equals: .yourName)
            .lineLimit(1)
            .foregroundStyle(Color.label, Color.secondaryLabel)
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.controlBackground.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)

            // Your first name editor
            ValidationLabel(
                "Your first name:",
                validation: yourFirstNameValidation.valid
            )
            .padding([.leading])
            TextField(
                "Enter your first name (capitalized)",
                text: $viewModel.yourFirstName.onChange { value in
                    if value.count == 0 {
                        yourFirstNameValidation = (false, "Required value")
                    } else {
                        yourFirstNameValidation = (true, nil)
                    }
                    UserDefaults.standard.set(viewModel.yourFirstName, forKey: "YourFirstName")
                }
            )
            .focused(focusedField, equals: .yourFirstName)
            .lineLimit(1)
            .foregroundStyle(Color.label, Color.secondaryLabel)
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.controlBackground.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)
        }
    }

    private func FeatureListButtonView() -> some View {
        HStack {
            Spacer()

            // Add feature
            Button(action: {
                logger.verbose("Tapped add feature button", context: "System")
                addFeature()
                shouldScrollFeatureListToSelection.wrappedValue.toggle()
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "person.fill.badge.plus")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Add feature")
                    Text("    ⌘ +")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Color.gray, Color.secondaryLabel)
                }
                .padding(2)
            }
            .disabled(viewModel.loadedCatalogs.waitingForPages || viewModel.selectedPage == nil)
            .keyboardShortcut("+", modifiers: .command)
            .focusable()
            .focused(focusedField, equals: .addFeature)
            .onKeyPress(.space) {
                logger.verbose("Pressed space on add feature button", context: "System")
                addFeature()
                shouldScrollFeatureListToSelection.wrappedValue.toggle()
                return .handled
            }

            Spacer()
                .frame(width: 16)

            // Remove feature
            Button(action: {
                logger.verbose("Tapped remove feature button", context: "System")
                if let currentFeature = viewModel.selectedFeature {
                    viewModel.selectedFeature = nil
                    viewModel.features.removeAll(where: { $0.id == currentFeature.feature.id })
                    viewModel.markDocumentDirty()
                }
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "person.fill.badge.minus")
                        .foregroundStyle(Color.red, Color.secondaryLabel)
                    Text("Remove feature")
                    Text("    ⌘ -")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Color.gray, Color.secondaryLabel)
                }
                .padding(2)
            }
            .disabled(viewModel.selectedFeature == nil)
            .keyboardShortcut("-", modifiers: .command)
            .focusable()
            .focused(focusedField, equals: .removeFeature)
            .onKeyPress(.space) {
                logger.verbose("Pressed space on remove feature button", context: "System")
                if let currentFeature = viewModel.selectedFeature {
                    viewModel.selectedFeature = nil
                    viewModel.features.removeAll(where: { $0.id == currentFeature.feature.id })
                    viewModel.markDocumentDirty()
                }
                return .handled
            }

            Spacer()
                .frame(width: 16)

            // Copy report
            Button(action: {
                logger.verbose("Tapped generate report button", context: "User")
                copyReportToClipboard()
            }) {
                HStack {
                    Image(systemName: "pencil.and.list.clipboard")
                        .foregroundStyle(Color.accentColor, Color.secondaryLabel)
                    Text("Generate report")
                    Text("    ⌘ ⇧ G")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Color.gray, Color.secondaryLabel)
                }
                .padding(2)
            }
            .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil || viewModel.features.isEmpty)
            .keyboardShortcut("G", modifiers: [.command, .shift])
            .focusable()
            .focused(focusedField, equals: .generateReport)
            .onKeyPress(.space) {
                logger.verbose("Pressed space on generate report button", context: "System")
                copyReportToClipboard()
                return .handled
            }
        }
    }

    // MARK: - page navigation

    private func navigateToPage(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(viewModel.loadedCatalogs.loadedPages, viewModel.selectedPage, direction)
        if change {
            if direction != .same {
                viewModel.selectedPage = newValue
            }
            UserDefaults.standard.set(viewModel.selectedPage?.id ?? "", forKey: "Page")
            logURL.wrappedValue = nil
            viewModel.selectedFeature = nil
            viewModel.features = [ObservableFeature]()
            updateStaffLevelForPage()
        }
    }

    private func navigateToPageWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToPage(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToPageWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(viewModel.loadedCatalogs.loadedPages.map({ $0.name }), viewModel.selectedPage?.name ?? "", keyPress.characters.lowercased())
        if change {
            if let newPage = viewModel.loadedCatalogs.loadedPages.first(where: { $0.name == newValue }) {
                viewModel.selectedPage = newPage
                UserDefaults.standard.set(viewModel.selectedPage?.id ?? "", forKey: "Page")
                logURL.wrappedValue = nil
                viewModel.selectedFeature = nil
                viewModel.features = [ObservableFeature]()
                updateStaffLevelForPage()
            }
            return .handled
        }
        return .ignored
    }

    // MARK: - page staff level navigation

    private func navigateToPageStaffLevel(_ direction: Direction) {
        let (change, newValue) = navigateGeneric(StaffLevelCase.allCases, viewModel.selectedPageStaffLevel, direction)
        if change {
            if direction != .same {
                viewModel.selectedPageStaffLevel = newValue
            }
            storeStaffLevelForPage()
        }
    }

    private func navigateToPageStaffLevelWithArrows(_ keyPress: KeyPress) -> KeyPress.Result {
        let direction = directionFromModifiers(keyPress)
        if direction != .same {
            navigateToPageStaffLevel(direction)
            return .handled
        }
        return .ignored
    }

    private func navigateToPageStaffLevelWithPrefix(_ keyPress: KeyPress) -> KeyPress.Result {
        let (change, newValue) = navigateGenericWithPrefix(StaffLevelCase.allCases, viewModel.selectedPageStaffLevel, keyPress.characters.lowercased())
        if change {
            viewModel.selectedPageStaffLevel = newValue
            storeStaffLevelForPage()
            return .handled
        }
        return .ignored
    }
}

extension MainContentView {
    // MARK: - utilities

    private func addFeature() {
        let linkText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        let existingFeature = viewModel.features.first(where: { $0.postLink.lowercased() == linkText.lowercased() })
        if let feature = existingFeature {
            logger.warning("Added a feature which already exists", context: "System")
            viewModel.showToast(
                .warning,
                "Duplicate post link",
                "There is already a feature in the list with that post link, selected the existing feature",
                duration: 2,
                modal: false
            )
            viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
            return
        }
        let feature = ObservableFeature()
        if linkText.starts(with: "https://vero.co/") {
            feature.postLink = linkText
            let possibleUserAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
            // If the user doesn't have an alias, the link will have a single letter, often 'p'
            if possibleUserAlias.count > 1 {
                logger.verbose("Using the link text for the user alias", context: "System")
                feature.userAlias = possibleUserAlias
            }
        }
        viewModel.features.append(feature)
        viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
        viewModel.markDocumentDirty()
    }

    private func copyReportToClipboard() {
        let text = viewModel.generateReport(personalMessageFormat, personalMessageFirstFormat)
        copyToClipboard(text)
        logger.verbose("Generated report", context: "System")
        viewModel.showSuccessToast(
            "Report generated!",
            "Copied the report of features to the clipboard")
    }
}
