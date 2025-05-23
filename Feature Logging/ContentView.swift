//
//  ContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import SwiftyBeaver
import UniformTypeIdentifiers

struct ContentView: View {
    // PREFS
    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFormat = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirstFormat = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"

    // THEME
    @EnvironmentObject var commandModel: AppCommandModel

    @Environment(\.openURL) private var openURL

    @State private var viewModel = ViewModel()
    @FocusState private var focusedField: FocusField?

    @ObservedObject var featureScriptPlaceholders = PlaceholderList()
    @ObservedObject var commentScriptPlaceholders = PlaceholderList()
    @ObservedObject var originalPostScriptPlaceholders = PlaceholderList()
    @State private var documentDirtyAlertConfirmation = "Would you like to save this log file?"
    @State private var documentDirtyAfterSaveAction: () -> Void = {}
    @State private var documentDirtyAfterDismissAction: () -> Void = {}
    @State private var showFileImporter = false
    @State private var showFileExporter = false
    @State private var logDocument = LogDocument()
    @State private var logURL: URL? = nil
    @State private var showReportFileExporter = false
    @State private var reportDocument = ReportDocument()
    @State private var shouldScrollFeatureListToSelection = false

    private let logger = SwiftyBeaver.self
    private var descriptionSuffix: String {
        if let description = viewModel.selectedFeature?.feature.featureDescription {
            if !description.isEmpty {
                return ", description: \(description)"
            }
        }
        return ""
    }

    private var titleSuffix: String {
        viewModel.visibleView == .ScriptView
            ? ((viewModel.selectedFeature?.feature.userName ?? "").isEmpty ? " - scripts" : " - scripts for \(viewModel.selectedFeature?.feature.userName ?? "")\(descriptionSuffix)")
            : (viewModel.visibleView == .PostDownloadView
                ? ((viewModel.selectedFeature?.feature.userName ?? "").isEmpty ? " - post viewer" : " - post viewer for \(viewModel.selectedFeature?.feature.userName ?? "")\(descriptionSuffix)")
                : (viewModel.visibleView == .StatisticsView
                    ? " - statistics"
                    : ""))
    }

    private var fileNameDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

#if STANDALONE
    private let appState: VersionCheckAppState
    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }
#endif

    var body: some View {
        ZStack {
            Color.backgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                if viewModel.visibleView == .ScriptView {
                    ScriptContentView(
                        viewModel,
                        viewModel.selectedPage!,
                        viewModel.selectedFeature!,
                        featureScriptPlaceholders,
                        commentScriptPlaceholders,
                        originalPostScriptPlaceholders,
                        $focusedField,
                        navigateToNextFeature
                    )
                } else if viewModel.visibleView == .ImageValidationView {
                    ImageValidationView(
                        viewModel,
                        $focusedField,
                        { shouldScrollFeatureListToSelection.toggle() }
                    )
                } else if viewModel.visibleView == .PostDownloadView {
                    PostDownloaderView(
                        viewModel,
                        viewModel.selectedPage!,
                        viewModel.selectedFeature!,
                        $focusedField,
                        { shouldScrollFeatureListToSelection.toggle() }
                    )
                } else if viewModel.visibleView == .StatisticsView {
                    StatisticsContentView(
                        viewModel,
                        $focusedField,
                        { commandModel.showStatistics = false }
                    )
                } else {
                    MainContentView(
                        viewModel,
                        $logURL,
                        $focusedField,
                        $logDocument,
                        $showFileImporter,
                        $showFileExporter,
                        $reportDocument,
                        $showReportFileExporter,
                        $documentDirtyAlertConfirmation,
                        $documentDirtyAfterSaveAction,
                        $documentDirtyAfterDismissAction,
                        $shouldScrollFeatureListToSelection,
                        updateStaffLevelForPage,
                        storeStaffLevelForPage,
                        saveLog
                    )
                }

                // Log importer
                HStack { }
                    .frame(width: 0, height: 0)
                    .fileImporter(
                        isPresented: $showFileImporter,
                        allowedContentTypes: [.json]
                    ) { result in
                        switch result {
                        case let .success(file):
                            loadLog(from: file)
                            viewModel.clearDocumentDirty()
                        case let .failure(error):
                            debugPrint(error.localizedDescription)
                        }
                    }
                    .fileDialogConfirmationLabel("Open log")

                // Log exporter
                HStack { }
                    .frame(width: 0, height: 0)
                    .fileExporter(
                        isPresented: $showFileExporter,
                        document: logDocument,
                        contentType: .json,
                        defaultFilename: "\(viewModel.selectedPage?.hub ?? "hub")_\(viewModel.selectedPage?.pageName ?? viewModel.selectedPage?.name ?? "page") - \(fileNameDateFormatter.string(from: Date.now)).json"
                    ) { result in
                        switch result {
                        case let .success(url):
                            logger.verbose("Saved the feature log", context: "System")
                            logURL = url
                            viewModel.clearDocumentDirty()
                            documentDirtyAfterSaveAction()
                            documentDirtyAfterSaveAction = {}
                            documentDirtyAfterDismissAction = {}
                        case let .failure(error):
                            debugPrint(error.localizedDescription)
                        }
                    }
                    .fileExporterFilenameLabel("Save log as: ") // filename label
                    .fileDialogConfirmationLabel("Save log")

                // Report exporter
                HStack { }
                    .frame(width: 0, height: 0)
                    .fileExporter(
                        isPresented: $showReportFileExporter,
                        document: reportDocument,
                        contentType: UTType.features,
                        defaultFilename: logURL != nil
                            ? "\(logURL!.deletingPathExtension().lastPathComponent).features"
                            : "\(viewModel.selectedPage?.hub ?? "hub")_\(viewModel.selectedPage?.pageName ?? viewModel.selectedPage?.name ?? "page") - \(fileNameDateFormatter.string(from: Date.now)).features"
                    ) { result in
                        switch result {
                        case .success:
                            logger.verbose("Saved the feature report", context: "System")
                        case let .failure(error):
                            debugPrint(error)
                        }
                    }
                    .fileExporterFilenameLabel("Save report as: ")
                    .fileDialogConfirmationLabel("Save report")
            }
        }
#if STANDALONE
        .navigationTitle("Feature Logging - Standalone Version\(titleSuffix)")
        .attachVersionCheckState(viewModel, appState) { url in
            openURL(url)
        }
#else
        .navigationTitle("Feature Logging\(titleSuffix)")
#endif
        .background(Color.backgroundColor)
        .onChange(of: commandModel.newLog) {
            if viewModel.isDirty {
                documentDirtyAfterSaveAction = {
                    logURL = nil
                    viewModel.selectedFeature = nil
                    viewModel.features = [ObservableFeature]()
                    viewModel.clearDocumentDirty()
                    logger.verbose("New log created", context: "System")
                }
                documentDirtyAfterDismissAction = {
                    logURL = nil
                    viewModel.selectedFeature = nil
                    viewModel.features = [ObservableFeature]()
                    viewModel.clearDocumentDirty()
                    logger.verbose("New log created", context: "System")
                }
                documentDirtyAlertConfirmation = "Would you like to save this log file before creating a new log?"
                viewModel.isShowingDocumentDirtyAlert.toggle()
            } else {
                logURL = nil
                viewModel.selectedFeature = nil
                viewModel.features = [ObservableFeature]()
                viewModel.clearDocumentDirty()
                logger.verbose("New log created", context: "System")
            }
        }
        .onChange(of: commandModel.openLog) {
            if viewModel.isDirty {
                documentDirtyAfterSaveAction = {
                    showFileImporter.toggle()
                }
                documentDirtyAfterDismissAction = {
                    showFileImporter.toggle()
                }
                documentDirtyAlertConfirmation = "Would you like to save this log file before opening another log?"
                viewModel.isShowingDocumentDirtyAlert.toggle()
            } else {
                showFileImporter.toggle()
            }
        }
        .onChange(of: commandModel.saveLog) {
            logDocument = LogDocument(page: viewModel.selectedPage!, features: viewModel.features)
            if let file = logURL {
                saveLog(to: file)
                documentDirtyAfterSaveAction()
                documentDirtyAfterSaveAction = {}
                documentDirtyAfterDismissAction = {}
                viewModel.clearDocumentDirty()
            } else {
                showFileExporter.toggle()
            }
        }
        .onChange(of: commandModel.saveReport) {
            reportDocument = ReportDocument(initialText: viewModel.generateReport(personalMessageFormat, personalMessageFirstFormat))
            showReportFileExporter.toggle()
        }
        .onChange(of: commandModel.showStatistics) {
            if commandModel.showStatistics {
                viewModel.visibleView = .StatisticsView
            } else {
                viewModel.visibleView = .FeatureView
            }
        }
        .onChange(of: commandModel.reloadPageCatalog) {
            if !viewModel.features.isEmpty {
                logger.warning("Could not reload pages with features", context: "System")
                viewModel.showToast(
                    .alert,
                    "Cannot load pages",
                    "Cannot reload pages while there are features",
                    modal: false,
                    blocking: false
                )
            } else {
                viewModel.loadedCatalogs = LoadedCatalogs()
                Task {
                    await loadPageCatalog()
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingDocumentDirtyAlert) {
            DocumentDirtySheet(
                isShowing: $viewModel.isShowingDocumentDirtyAlert,
                confirmationText: $documentDirtyAlertConfirmation,
                saveAction: {
                    commandModel.saveLog.toggle()
                },
                dismissAction: {
                    logger.warning("Ignored dirty document", context: "System")
                    documentDirtyAfterDismissAction()
                    documentDirtyAfterSaveAction = {}
                    documentDirtyAfterDismissAction = {}
                },
                cancelAction: {
                    documentDirtyAfterSaveAction = {}
                    documentDirtyAfterDismissAction = {}
                })
        }
        .advancedToastView(toasts: $viewModel.toastViews)
        .navigationSubtitle(viewModel.isDirty ? "edited" : "")
        .task {
            let loadingPagesToast = viewModel.showToast(
                .progress,
                "Loading pages...",
                "Loading the page catalog from the server"
            )

            await loadPageCatalog()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                viewModel.dismissToast(loadingPagesToast)
            }
        }
        .onAppear {
            DocumentManager.default.registerReceiver(receiver: self)
        }
        .testBackground(true)
    }
}

extension ContentView {
    // MARK: - utilities

    private func delayAndTerminate() {
        viewModel.clearDocumentDirty()
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.2,
            execute: {
#if os(macOS)
                NSApplication.shared.terminate(nil)
#else
                // TODO: andydragon
#endif
            })
    }

    private func updateStaffLevelForPage() {
        if let page = viewModel.selectedPage {
            if let rawPageStaffLevel = UserDefaults.standard.string(forKey: "StaffLevel_" + page.id) {
                if let pageStaffLevelFromRaw = StaffLevelCase(rawValue: rawPageStaffLevel) {
                    viewModel.selectedPageStaffLevel = pageStaffLevelFromRaw
                    return
                }
            }
        } else if let rawPagelessStaffLevel = UserDefaults.standard.string(forKey: "StaffLevel") {
            if let pageStaffLevelFromRaw = StaffLevelCase(rawValue: rawPagelessStaffLevel) {
                viewModel.selectedPageStaffLevel = pageStaffLevelFromRaw
                storeStaffLevelForPage()
                return
            }
        }

        viewModel.selectedPageStaffLevel = StaffLevelCase.mod
        storeStaffLevelForPage()
    }

    private func storeStaffLevelForPage() {
        if let page = viewModel.selectedPage {
            UserDefaults.standard.set(viewModel.selectedPageStaffLevel.rawValue, forKey: "StaffLevel_" + page.id)
        } else {
            UserDefaults.standard.set(viewModel.selectedPageStaffLevel.rawValue, forKey: "StaffLevel")
        }
    }

    private func loadPageCatalog() async {
        logger.verbose("Loading page catalog from server", context: "System")

        do {
            let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
            let pagesCatalog = try await URLSession.shared.decode(ScriptsCatalog.self, from: pagesUrl)
            var pages = [ObservablePage]()
            for hubPair in pagesCatalog.hubs {
                for hubPage in hubPair.value {
                    pages.append(ObservablePage(hub: hubPair.key, page: hubPage))
                }
            }
            viewModel.loadedCatalogs.loadedPages.removeAll()
            viewModel.loadedCatalogs.loadedPages.append(
                contentsOf: pages.sorted(by: {
                    if $0.hub == "other" && $1.hub == "other" {
                        return $0.name < $1.name
                    }
                    if $0.hub == "other" {
                        return false
                    }
                    if $1.hub == "other" {
                        return true
                    }
                    return "\($0.hub)_\($0.name)" < "\($1.hub)_\($1.name)"
                }))
            viewModel.loadedCatalogs.waitingForPages = false
            let lastPage = UserDefaults.standard.string(forKey: "Page") ?? ""
            viewModel.selectedPage = viewModel.loadedCatalogs.loadedPages.first(where: { $0.id == lastPage })
            if viewModel.selectedPage == nil {
                viewModel.selectedPage = viewModel.loadedCatalogs.loadedPages.first ?? nil
            }
            updateStaffLevelForPage()

            logger.verbose("Loaded page catalog from server with \(viewModel.loadedCatalogs.loadedPages.count) pages", context: "System")

            // Delay the start of the templates download so the window can be ready faster
            try await Task.sleep(nanoseconds: 200000000)

            logger.verbose("Loading template catalog from server", context: "System")

            let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/templates.json")!
            viewModel.loadedCatalogs.templatesCatalog = try await URLSession.shared.decode(TemplateCatalog.self, from: templatesUrl)
            viewModel.loadedCatalogs.waitingForTemplates = false

            logger.verbose("Loaded template catalog from server with \(viewModel.loadedCatalogs.templatesCatalog.pages.count) page templates", context: "System")

            do {
                // Delay the start of the disallowed list download so the window can be ready faster
                try await Task.sleep(nanoseconds: 1000000000)

                logger.verbose("Loading disallow lists from server", context: "System")

                let disallowListUrl = URL(string: "https://vero.andydragon.com/static/data/disallowlists.json")!
                viewModel.loadedCatalogs.disallowLists = try await URLSession.shared.decode([String: [String]].self, from: disallowListUrl)

                logger.verbose("Loaded disallow lists from server with \(viewModel.loadedCatalogs.disallowLists.count) entries", context: "System")
            } catch {
                // do nothing, the disallow list is not critical
                logger.error("Failed to load disallow lists from server: \(error.localizedDescription)", context: "System")
                debugPrint(error.localizedDescription)
            }

            do {
                logger.verbose("Loading caution lists from server", context: "System")

                let cautionListsUrl = URL(string: "https://vero.andydragon.com/static/data/cautionlists.json")!
                viewModel.loadedCatalogs.cautionLists = try await URLSession.shared.decode([String: [String]].self, from: cautionListsUrl)

                logger.verbose("Loaded caution lists from server with \(viewModel.loadedCatalogs.cautionLists.count) entries", context: "System")
            } catch {
                // do nothing, the caution lists is not critical
                logger.error("Failed to load caution lists from server: \(error.localizedDescription)", context: "System")
                debugPrint(error.localizedDescription)
            }

            viewModel.loadedCatalogs.waitingForDisallowList = false

#if STANDALONE
            do {
                // Delay the start of the disallowed list download so the window can be ready faster
                try await Task.sleep(nanoseconds: 100000000)

                appState.checkForUpdates()
            } catch {
                // do nothing, the version check is not critical
                debugPrint(error.localizedDescription)
            }
#endif
        } catch {
            logger.error("Failed to load page catalog or template catalog from server: \(error.localizedDescription)", context: "System")
            viewModel.dismissAllNonBlockingToasts(includeProgress: true)
            viewModel.showToast(
                .fatal,
                "Failed to load pages",
                "The application requires the catalog to perform its operations: \(error.localizedDescription)\n\n" +
                    "Click here to try again immediately or wait 15 seconds to automatically try again.",
                duration: 15,
                width: 720,
                buttonTitle: "Retry",
                onButtonTapped: {
                    logger.verbose("Retrying to load pages catalog after failure", context: "System")
                    DispatchQueue.main.async {
                        Task {
                            await loadPageCatalog()
                        }
                    }
                },
                onDismissed: {
                    logger.verbose("Retrying to load pages catalog after failure", context: "System")
                    DispatchQueue.main.async {
                        Task {
                            await loadPageCatalog()
                        }
                    }
                }
            )
        }
    }

    private func loadLog(from file: URL) {
        let gotAccess = file.startAccessingSecurityScopedResource()
        if !gotAccess {
            logger.error("Failed to access the log file to load", context: "System")
            debugPrint("No access to load log")
            return
        }

        let fileContents = FileManager.default.contents(atPath: file.path)
        if let json = fileContents {
            let jsonString = String(String(decoding: json, as: UTF8.self))
            do {
                let decoder = JSONDecoder()
                let loadedLog = try decoder.decode(Log.self, from: jsonString.data(using: .utf8)!)
                if let loadedPage = viewModel.loadedCatalogs.loadedPages.first(where: { $0.id == loadedLog.page }) {
                    viewModel.selectedFeature = nil
                    viewModel.selectedPage = loadedPage
                    viewModel.features = loadedLog.getFeatures(loadedPage.hub)
                }
                logURL = file
                logger.verbose("Loaded log file with \(viewModel.sortedFeatures.count) features", context: "System")
                viewModel.showSuccessToast(
                    "Loaded features",
                    "Loaded \(viewModel.sortedFeatures.count) features from the log file")
            } catch {
                logger.error("Failed to load the log file: \(error.localizedDescription)", context: "System")
                debugPrint("Error parsing JSON: \(error.localizedDescription)")
            }
        }

        file.stopAccessingSecurityScopedResource()
    }

    private func saveLog(to file: URL) {
        let gotAccess = file.startAccessingSecurityScopedResource()
        if !gotAccess {
            logger.error("Failed to access the log file to load", context: "System")
            debugPrint("No access to save log")
            return
        }

        do {
            let jsonData = Data(logDocument.text.replacingOccurrences(of: "\\/", with: "/").utf8)
            try jsonData.write(to: file)
            logger.verbose("Saved log file with \(viewModel.sortedFeatures.count) features", context: "System")
            viewModel.showSuccessToast(
                "Saved features",
                "Saved \(viewModel.sortedFeatures.count) features to the log file")
        } catch {
            logger.error("Failed to save the log file: \(error.localizedDescription)", context: "System")
            debugPrint(error)
        }

        file.stopAccessingSecurityScopedResource()
    }

    private func navigateToNextFeature(forward: Bool) {
        if viewModel.selectedFeature != nil && viewModel.selectedPage != nil {
            let currentIndex = viewModel.sortedFeatures.firstIndex(where: { $0.id == viewModel.selectedFeature?.feature.id })
            if let currentIndex {
                let startingIndex = viewModel.sortedFeatures.distance(from: viewModel.sortedFeatures.startIndex, to: currentIndex)
                var nextIndex = startingIndex
                let featureCount = viewModel.features.count
                repeat {
                    if forward {
                        nextIndex = (nextIndex + 1) % featureCount
                    } else {
                        nextIndex = (nextIndex + featureCount - 1) % featureCount
                    }
                    if let page = viewModel.selectedPage {
                        if viewModel.sortedFeatures[nextIndex].isPickedAndAllowed {
                            viewModel.selectedFeature = ObservableFeatureWrapper(using: page, from: viewModel.sortedFeatures[nextIndex])

                            // Ensure the ScriptContentView is visible
                            viewModel.visibleView = .ScriptView
                            return
                        }
                    }
                } while nextIndex != startingIndex
            }
        }
    }
}

extension ContentView: DocumentManagerDelegate {
    // MARK: - document management

    func onCanTerminate() -> Bool {
        if viewModel.isDirty {
            documentDirtyAfterDismissAction = {
                delayAndTerminate()
            }
            documentDirtyAfterSaveAction = {
                delayAndTerminate()
            }
            documentDirtyAlertConfirmation = "Would you like to save this log file before leaving the app?"
            viewModel.isShowingDocumentDirtyAlert.toggle()
        }
        return !viewModel.isDirty
    }
}
