//
//  MainContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-25.
//

import AlertToast
import SwiftUI
import UniformTypeIdentifiers

struct MainContentView: View {
    // THEME
    @AppStorage(
        Constants.THEME_APP_STORE_KEY,
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var theme = Theme.notSet
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var isDarkModeOn = true

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
    private var showScriptView: () -> Void
    private var showDownloaderView: () -> Void
    private var updateStaffLevelForPage: () -> Void
    private var storeStaffLevelForPage: () -> Void
    private var saveLog: (_ file: URL) -> Void
    private var setTheme: (_ newTheme: Theme) -> Void
    private var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void

    @State private var hoveredFeature: ObservableFeature? = nil

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
        _ showScriptView: @escaping () -> Void,
        _ showDownloaderView: @escaping () -> Void,
        _ updateStaffLevelForPage: @escaping () -> Void,
        _ storeStaffLevelForPage: @escaping () -> Void,
        _ saveLog: @escaping (_ file: URL) -> Void,
        _ setTheme: @escaping (_ newTheme: Theme) -> Void,
        _ showToast: @escaping (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: ToastDuration, _ onTap: @escaping () -> Void) -> Void
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
        self.showScriptView = showScriptView
        self.showDownloaderView = showDownloaderView
        self.updateStaffLevelForPage = updateStaffLevelForPage
        self.storeStaffLevelForPage = storeStaffLevelForPage
        self.saveLog = saveLog
        self.setTheme = setTheme
        self.showToast = showToast
    }

    private let labelWidth: CGFloat = 80

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                // Page / staff level picker
                HStack(alignment: .center) {
                    Text("Page:")
                        .frame(width: labelWidth - 5, alignment: .trailing)
                    Picker(
                        "",
                        selection: $viewModel.selectedPage.onChange { value in
                            navigateToPage(.same)
                        }
                    ) {
                        ForEach(viewModel.loadedCatalogs.loadedPages) { page in
                            Text(page.displayName).tag(page)
                        }
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                    .focusable(viewModel.features.isEmpty)
                    .focused(focusedField, equals: .pagePicker)
                    .onKeyPress(phases: .down) { keyPress in
                        return navigateToPageWithArrows(keyPress)
                    }
                    .onKeyPress(characters: .alphanumerics) { keyPress in
                        return navigateToPageWithPrefix(keyPress)
                    }
                    .disabled(!viewModel.features.isEmpty)

                    // Page staff level picker
                    Text("Page staff level: ")
                        .padding([.leading])
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Picker(
                        "",
                        selection: $viewModel.selectedPageStaffLevel.onChange { value in
                            navigateToPageStaffLevel(.same)
                        }
                    ) {
                        ForEach(StaffLevelCase.allCases) { staffLevelCase in
                            Text(staffLevelCase.rawValue)
                                .tag(staffLevelCase)
                                .foregroundStyle(Color.TextColorSecondary, Color.TextColorSecondary)
                        }
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                    .focusable()
                    .focused(focusedField, equals: .staffLevel)
                    .onKeyPress(phases: .down) { keyPress in
                        return navigateToPageStaffLevelWithArrows(keyPress)
                    }
                    .onKeyPress(characters: .alphanumerics) { keyPress in
                        return navigateToPageStaffLevelWithPrefix(keyPress)
                    }
                    .frame(maxWidth: 144)

                    Menu("Copy tag", systemImage: "tag.fill") {
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(viewModel.selectedPage?.hub ?? "")_\(viewModel.selectedPage?.pageName ?? viewModel.selectedPage?.name ?? "")")
                            showToast(.complete(.green), "Copied to clipboard", "Copied the page tag to the clipboard", .Success) {}
                        }) {
                            Text("Page tag")
                        }
                        if viewModel.selectedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_\(viewModel.selectedPage?.pageName ?? viewModel.selectedPage?.name ?? "")")
                                showToast(.complete(.green), "Copied to clipboard", "Copied the RAW page tag to the clipboard", .Success) {}
                            }) {
                                Text("RAW page tag")
                            }
                        }
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(viewModel.selectedPage?.hub ?? "")_community")
                            showToast(.complete(.green), "Copied to clipboard",  "Copied the community tag to the clipboard", .Success) {}
                        }) {
                            Text("Community tag")
                        }
                        if viewModel.selectedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_community")
                                showToast(.complete(.green), "Copied to clipboard",  "Copied the RAW community tag to the clipboard", .Success) {}
                            }) {
                                Text("RAW community tag")
                            }
                        }
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(viewModel.selectedPage?.hub ?? "")_hub")
                            showToast(.complete(.green), "Copied to clipboard",  "Copied the hub tag to the clipboard", .Success) {}
                        }) {
                            Text("Hub tag")
                        }
                        if viewModel.selectedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_hub")
                                showToast(.complete(.green), "Copied to clipboard",  "Copied the RAW hub tag to the clipboard", .Success) {}
                            }) {
                                Text("RAW hub tag")
                            }
                        }
                    }
                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .disabled(viewModel.isShowingToast || (viewModel.selectedPage?.hub != "click" && viewModel.selectedPage?.hub != "snap"))
                    .frame(maxWidth: 132)
                    .focusable()
                    .focused(focusedField, equals: .copyTag)
                    .onKeyPress(.space) {
                        copyToClipboard("\(includeHash ? "#" : "")\(viewModel.selectedPage?.hub ?? "")_\(viewModel.selectedPage?.pageName ?? viewModel.selectedPage?.name ?? "")")
                        showToast(.complete(.green), "Copied to clipboard", "Copied the page tag to the clipboard", .Success) {}
                        return .handled
                    }
                    .padding([.leading])
                }

                // You
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
                    .focusable()
                    .focused(focusedField, equals: .yourName)
                    .lineLimit(1)
                    .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)

                    // Your first name editor
                    ValidationLabel(
                        "Your first name:",
                        validation: yourFirstNameValidation.valid)
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
                    .focusable()
                    .focused(focusedField, equals: .yourFirstName)
                    .lineLimit(1)
                    .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    .textFieldStyle(.plain)
                    .padding(4)
                    .background(Color.BackgroundColorEditor)
                    .border(Color.gray.opacity(0.25))
                    .cornerRadius(4)
                }

                // Feature editor
                VStack {
                    if let selectedPage = viewModel.selectedPage, let selectedFeature = viewModel.selectedFeature {
                        FeatureEditor(
//                            viewModel,
                            selectedPage,
                            selectedFeature,
                            focusedField,
                            { viewModel.selectedFeature = nil },
                            { viewModel.markDocumentDirty() },
                            { shouldScrollFeatureListToSelection.wrappedValue.toggle() },
                            showDownloaderView,
                            showToast
                        )
                    }
                }
                .frame(height: 360)
                .frame(maxWidth: .infinity)
                .background(Color.BackgroundColorEditor)
                .border(Color.gray.opacity(0.25), width: 1)
                .cornerRadius(2)
                .padding([.bottom], 4)

                // Feature list buttons
                HStack {
                    Spacer()

                    // Add feature
                    Button(action: {
                        addFeature()
                        shouldScrollFeatureListToSelection.wrappedValue.toggle()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Add feature")
                        }
                    }
                    .disabled(viewModel.isShowingToast || viewModel.loadedCatalogs.waitingForPages)
                    .keyboardShortcut("+", modifiers: .command)
                    .focusable()
                    .focused(focusedField, equals: .addFeature)
                    .onKeyPress(.space) {
                        addFeature()
                        shouldScrollFeatureListToSelection.wrappedValue.toggle()
                        return .handled
                    }

                    Spacer()
                        .frame(width: 16)

                    // Remove feature
                    Button(action: {
                        if let currentFeature = viewModel.selectedFeature {
                            viewModel.selectedFeature = nil
                            viewModel.features.removeAll(where: { $0.id == currentFeature.feature.id })
                            viewModel.markDocumentDirty()
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.minus")
                                .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                            Text("Remove feature")
                        }
                    }
                    .disabled(viewModel.isShowingToast || viewModel.selectedFeature == nil)
                    .keyboardShortcut("-", modifiers: .command)
                    .focusable()
                    .focused(focusedField, equals: .removeFeature)
                    .onKeyPress(.space) {
                        if let currentFeature = viewModel.selectedFeature {
                            viewModel.selectedFeature = nil
                            viewModel.features.removeAll(where: { $0.id == currentFeature.feature.id })
                            viewModel.markDocumentDirty()
                        }
                        return .handled
                    }
                }
                .padding([.trailing], 2)

                // Feature list
                ScrollViewReader { proxy in
                    List {
                        ForEach(viewModel.sortedFeatures, id: \.self) { feature in
                            FeatureListRow(
                                viewModel,
                                feature,
                                showScriptView,
                                showToast
                            )
                            .padding([.top, .bottom], 8)
                            .padding([.leading, .trailing])
                            .foregroundStyle(
                                Color(
                                    nsColor: hoveredFeature == feature
                                    ? NSColor.selectedControlTextColor
                                    : NSColor.labelColor), Color(nsColor: .labelColor)
                            )
                            .background(
                                viewModel.selectedFeature?.feature == feature
                                ? Color.BackgroundColorListSelected
                                : hoveredFeature == feature
                                ? Color.BackgroundColorListSelected.opacity(0.33)
                                : Color.BackgroundColorList
                            )
                            .cornerRadius(4)
                            .onHover(perform: { hovering in
                                if hoveredFeature == feature {
                                    if !hovering {
                                        hoveredFeature = nil
                                    }
                                } else if hovering {
                                    hoveredFeature = feature
                                }
                            })
                            .onTapGesture {
                                withAnimation {
                                    viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
                                }
                            }
                        }
                    }
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
                .background(Color.BackgroundColorList)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
            }
            .toolbar {
                // Open log
                Button(action: {
                    if viewModel.isDirty {
                        documentDirtyAfterSaveAction.wrappedValue = {
                            showFileImporter.wrappedValue.toggle()
                        }
                        documentDirtyAfterDismissAction.wrappedValue = {
                            showFileImporter.wrappedValue.toggle()
                        }
                        documentDirtyAlertConfirmation.wrappedValue = "Would you like to save this log file before opening another log?"
                        viewModel.isShowingDocumentDirtyAlert.toggle()
                    } else {
                        showFileImporter.wrappedValue.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.on.square")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Open log")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                        Text("    ⌘ O")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.TextColorSecondary)
                    }
                    .padding(4)
                }
                .disabled(viewModel.isShowingToast || viewModel.selectedPage == nil)

                // Save log
                Button(action: {
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
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Save log")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                        Text("    ⌘ S")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.TextColorSecondary)
                    }
                    .padding(4)
                }
                .disabled(viewModel.isShowingToast || viewModel.selectedPage == nil)

                // Copy report
                Button(action: {
                    copyReportToClipboard()
                }) {
                    HStack {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Generate report")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    }
                    .padding(4)
                }
                .disabled(viewModel.isShowingToast || viewModel.selectedPage == nil)

                // Save report
                Button(action: {
                    reportDocument.wrappedValue = ReportDocument(initialText: viewModel.generateReport(personalMessageFormat, personalMessageFirstFormat))
                    showReportFileExporter.wrappedValue.toggle()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Save report")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                        Text("    ⌘ ⇧ S")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.gray, Color.TextColorSecondary)
                    }
                    .padding(4)
                }
                .disabled(viewModel.isShowingToast || viewModel.selectedPage == nil)

                // Theme
                Menu("Theme", systemImage: "paintpalette") {
                    Picker("Theme:", selection: $theme.onChange({ newTheme in
                        setTheme(newTheme)
                        setThemeLocal(newTheme)
                    })) {
                        ForEach(Theme.allCases) { itemTheme in
                            if itemTheme != .notSet {
                                Text(itemTheme.rawValue).tag(itemTheme)
                            }
                        }
                    }
                    .pickerStyle(.inline)
                }
                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                .disabled(viewModel.isShowingToast)
            }
            .padding([.leading, .top, .trailing])
        }
        .onAppear(perform: {
            focusedField.wrappedValue = .pagePicker
            setTheme(theme)
        })
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }

    private func setThemeLocal(_ newTheme: Theme) {
        if newTheme == .notSet {
            isDarkModeOn = colorScheme != .dark
            isDarkModeOn = colorScheme == .dark
        } else {
            if let details = ThemeDetails[newTheme] {
                isDarkModeOn = !details.darkTheme
                isDarkModeOn = details.darkTheme
                theme = newTheme
            }
        }
    }

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

    private func addFeature() {
        let linkText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        let existingFeature = viewModel.features.first(where: { $0.postLink.lowercased() == linkText.lowercased() })
        if let feature = existingFeature {
            showToast(
                .systemImage("exclamationmark.triangle.fill", .orange),
                "Found duplicate post link",
                "There is already a feature in the list with that post link, selected the existing feature",
                .Failure) {}
            viewModel.selectedFeature = ObservableFeatureWrapper(using: viewModel.selectedPage!, from: feature)
            return
        }
        let feature = ObservableFeature()
        if linkText.starts(with: "https://vero.co/") {
            feature.postLink = linkText
            let possibleUserAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
            // If the user doesn't have an alias, the link will have a single letter, often 'p'
            if possibleUserAlias.count > 1 {
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
        showToast(
            .complete(.green),
            "Report generated!",
            "Copied the report of features to the clipboard",
            .Success) {}
    }
}
