//
//  FeatureListView.swift
//  Feature Logging Pad
//
//  Created by Andrew Forget on 2025-01-16.
//

import SwiftUI
import SwiftyBeaver
import UniformTypeIdentifiers

struct FeatureListView: View {
    // THEME
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @Environment(\.showAbout) private var showAbout: ShowAboutAction?
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
    @State private var showingSettings = false
    private var updateStaffLevelForPage: () -> Void
    private var storeStaffLevelForPage: () -> Void
    private var saveLog: (_ file: URL) -> Void
    private var logger = SwiftyBeaver.self

    init(
        _ viewModel: ContentView.ViewModel,
        _ logURL: Binding<URL?>,
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
            Color.backgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                // Page / staff level picker
                PageSelectorView()

                Divider()
                    .padding(.bottom, 8)

                // You
                ModeratorView()

                Divider()
                    .padding(.top, 8)

                // Feature list buttons
                FeatureListButtonView()
                    .padding([.trailing], 2)

                // Feature list
                ScrollViewReader { proxy in
                    FeatureList(
                        viewModel
                    )
                    .frame(maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                    .presentationBackground(.clear)
                    .onChange(
                        of: shouldScrollFeatureListToSelection.wrappedValue,
                        {
                            withAnimation {
                                proxy.scrollTo(viewModel.selectedFeature)
                            }
                        }
                    )
                }
                .scrollContentBackground(.hidden)
                .background(Color.secondaryBackgroundColor)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()

                    // New log
                    Button(action: {
                        logger.verbose("Tapped new log", context: "User")
                        if viewModel.isDirty {
                            documentDirtyAfterSaveAction.wrappedValue = {
                                logURL.wrappedValue = nil
                                viewModel.selectedFeature = nil
                                viewModel.features = [ObservableFeature]()
                                viewModel.clearDocumentDirty()
                                logger.verbose("New log created", context: "System")
                            }
                            documentDirtyAfterDismissAction.wrappedValue = {
                                logURL.wrappedValue = nil
                                viewModel.selectedFeature = nil
                                viewModel.features = [ObservableFeature]()
                                viewModel.clearDocumentDirty()
                                logger.verbose("New log created", context: "System")
                            }
                            documentDirtyAlertConfirmation.wrappedValue = "Would you like to save this log file before creating a new log?"
                            viewModel.isShowingDocumentDirtyAlert.toggle()
                        } else {
                            logURL.wrappedValue = nil
                            viewModel.selectedFeature = nil
                            viewModel.features = [ObservableFeature]()
                            viewModel.clearDocumentDirty()
                            logger.verbose("New log created", context: "System")
                        }
                    }) {
                        HStack {
                            if #available(iOS 18.0, *) {
                                Image(systemName: "document.badge.plus")
                                    .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            } else {
                                Image(systemName: "doc.badge.plus")
                                    .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            }
                            Text("New log")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil)

                    // Open log
                    Button(action: {
                        logger.verbose("Tapped open log", context: "User")
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
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("Open log")
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
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("Save log")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil)

                    // Save report
                    Button(action: {
                        logger.verbose("Tapped save report", context: "User")
                        reportDocument.wrappedValue = ReportDocument(initialText: viewModel.generateReport(personalMessageFormat, personalMessageFirstFormat))
                        showReportFileExporter.wrappedValue.toggle()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "square.and.arrow.down.on.square")
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("Save report")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil)

                    // Settings
                    Button(action: {
                        logger.verbose("Tapped settings", context: "User")
                        showingSettings.toggle()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundStyle(Color(UIColor.secondaryLabel), Color(UIColor.secondaryLabel))
                            Text("Settings")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts)

                    // About
                    Button(action: {
                        logger.verbose("Tapped about", context: "User")
                        showAbout?()
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                            Text("About")
                        }
                        .padding(4)
                    }
                    .disabled(viewModel.hasModalToasts)

                    Spacer()
                }
            }
            .safeToolbarVisibility(.visible, for: .bottomBar)
            .padding([.leading, .top, .trailing])
        }
        .sheet(isPresented: $showingSettings) {
            SettingsPane()
                .onAppear {
                    logger.verbose("Opened settings pane", context: "User")
                }
                .onDisappear {
                    logger.verbose("Closed settings pane", context: "User")
                }
        }
        .testBackground()
    }

    private func PageSelectorView() -> some View {
        HStack(alignment: .center) {
            Text("Page:")
                .lineLimit(1)
                .truncationMode(.tail)
            Picker(
                "",
                selection: $viewModel.selectedPage.onChange { _ in
                    UserDefaults.standard.set(viewModel.selectedPage?.id ?? "", forKey: "Page")
                    logURL.wrappedValue = nil
                    viewModel.selectedFeature = nil
                    viewModel.features = [ObservableFeature]()
                    updateStaffLevelForPage()
                }
            ) {
                ForEach(viewModel.loadedCatalogs.loadedPages) { page in
                    Text(page.displayName).tag(page)
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color(UIColor.label))
            .disabled(!viewModel.features.isEmpty)
            .frame(minWidth: 200, maxWidth: 240)

            // Page staff level picker
            Text("Page staff level: ")
                .padding([.leading])
                .lineLimit(1)
                .truncationMode(.tail)

            Picker(
                "",
                selection: $viewModel.selectedPageStaffLevel.onChange { _ in
                    storeStaffLevelForPage()
                }
            ) {
                ForEach(StaffLevelCase.casesFor(hub: viewModel.selectedPage?.hub)) { staffLevelCase in
                    Text(staffLevelCase.shortString)
                        .tag(staffLevelCase)
                        .foregroundStyle(Color(UIColor.secondaryLabel), Color(UIColor.secondaryLabel))
                }
            }
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .foregroundStyle(Color.accentColor, Color(UIColor.label))
            .frame(minWidth: 120, maxWidth: 160)

            Spacer()

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
            .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
            .tint(Color.accentColor)
            .accentColor(Color.accentColor)
            .disabled(viewModel.selectedPage?.hub != "click" && viewModel.selectedPage?.hub != "snap")
            .frame(maxWidth: 132)
            .padding([.leading])
            .buttonStyle(.bordered)
            .lineLimit(1)
            .truncationMode(.tail)
        }
    }

    private func ModeratorView() -> some View {
        HStack(alignment: .center) {
            // Your name editor
            ValidationLabel(
                validation: yourNameValidation.valid
            )
            TextField(
                "enter your user alias without '@'",
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
            .lineLimit(1)
            .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.backgroundColor.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)
            .autocapitalization(.none)
            .autocorrectionDisabled()

            // Your first name editor
            ValidationLabel(
                validation: yourFirstNameValidation.valid
            )
            .padding([.leading])
            TextField(
                "enter your first name (capitalized)",
                text: $viewModel.yourFirstName.onChange { value in
                    if value.count == 0 {
                        yourFirstNameValidation = (false, "Required value")
                    } else {
                        yourFirstNameValidation = (true, nil)
                    }
                    UserDefaults.standard.set(viewModel.yourFirstName, forKey: "YourFirstName")
                }
            )
            .lineLimit(1)
            .foregroundStyle(Color(UIColor.label), Color(UIColor.secondaryLabel))
            .textFieldStyle(.plain)
            .padding(4)
            .background(Color.backgroundColor.opacity(0.5))
            .border(Color.gray.opacity(0.25))
            .cornerRadius(4)
            .autocapitalization(.none)
            .autocorrectionDisabled()
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
                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                    Text("Add feature")
                }
            }
            .disabled(viewModel.loadedCatalogs.waitingForPages)
            .buttonStyle(.bordered)

            // Copy report
            Button(action: {
                logger.verbose("Tapped generate report", context: "User")
                copyReportToClipboard()
            }) {
                HStack(alignment: .center) {
                    Image(systemName: "pencil.and.list.clipboard")
                        .foregroundStyle(Color.accentColor, Color(UIColor.secondaryLabel))
                    Text("Copy report")
                }
            }
            .disabled(viewModel.hasModalToasts || viewModel.selectedPage == nil)
            .buttonStyle(.bordered)
        }
    }

    private func addFeature() {
        let linkText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
        let existingFeature = viewModel.features.first(where: { $0.postLink.lowercased() == linkText.lowercased() })
        if let feature = existingFeature, !linkText.isEmpty {
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
        viewModel.visibleView = .FeatureEditorView
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
