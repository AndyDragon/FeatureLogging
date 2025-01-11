//
//  ContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import UniformTypeIdentifiers

enum ToastDuration: Int {
    case Blocking = 0
    case Success = 1
    case Failure = 5
    case CatalogLoadFailure = 10
    case LongFailure = 30
}

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
    @AppStorage(
        Constants.THEME_APP_STORE_KEY,
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var theme = Theme.notSet
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var isDarkModeOn = true

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
    @State private var imageValidationImageUrl: URL?
    @State private var showFileImporter = false
    @State private var showFileExporter = false
    @State private var logDocument = LogDocument()
    @State private var logURL: URL? = nil
    @State private var showReportFileExporter = false
    @State private var reportDocument = ReportDocument()
    @State private var isShowingScriptView = false
    @State private var isShowingStatisticsView = false
    @State private var isShowingDownloaderView = false
    @State private var isShowingImageValidationView = false
    @State private var shouldScrollFeatureListToSelection = false

    private var appState: VersionCheckAppState
    private var descriptionSuffix: String {
        if let description = viewModel.selectedFeature?.feature.featureDescription {
            if !description.isEmpty {
                return ", description: \(description)"
            }
        }
        return ""
    }
    private var titleSuffix: String {
        isShowingScriptView
        ? ((viewModel.selectedFeature?.feature.userName ?? "").isEmpty ? " - scripts" : " - scripts for \(viewModel.selectedFeature?.feature.userName ?? "")\(descriptionSuffix)")
            : (isShowingDownloaderView
                ? ((viewModel.selectedFeature?.feature.userName ?? "").isEmpty ? " - post viewer" : " - post viewer for \(viewModel.selectedFeature?.feature.userName ?? "")\(descriptionSuffix)")
                : (isShowingStatisticsView
                    ? " - statistics"
                    : ""))
    }
    private var fileNameDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }


    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                if isShowingScriptView {
                    ScriptContentView(
                        viewModel,
                        viewModel.selectedPage!,
                        viewModel.selectedFeature!,
                        featureScriptPlaceholders,
                        commentScriptPlaceholders,
                        originalPostScriptPlaceholders,
                        $focusedField,
                        { isShowingScriptView = false },
                        navigateToNextFeature
                    )
                } else if isShowingDownloaderView {
                    if isShowingImageValidationView {
                        ImageValidationView(
                            viewModel,
                            $focusedField,
                            $imageValidationImageUrl,
                            { isShowingImageValidationView = false },
                            { shouldScrollFeatureListToSelection.toggle() }
                        )
                    } else {
                        PostDownloaderView(
                            viewModel,
                            viewModel.selectedPage!,
                            viewModel.selectedFeature!,
                            $focusedField,
                            { isShowingDownloaderView = false },
                            { imageUrl in
                                imageValidationImageUrl = imageUrl
                                isShowingImageValidationView = true
                            },
                            { shouldScrollFeatureListToSelection.toggle() }
                        )
                    }
                } else if isShowingStatisticsView {
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
                        { isShowingScriptView = true },
                        { isShowingDownloaderView = true },
                        updateStaffLevelForPage,
                        storeStaffLevelForPage,
                        saveLog,
                        setTheme
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
                        case .success(let file):
                            loadLog(from: file)
                            viewModel.clearDocumentDirty()
                        case .failure(let error):
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
                        case .success(let url):
                            logURL = url
                            viewModel.clearDocumentDirty()
                            documentDirtyAfterSaveAction()
                            documentDirtyAfterSaveAction = {}
                            documentDirtyAfterDismissAction = {}
                        case .failure(let error):
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
                            break
                        case .failure(let error):
                            debugPrint(error)
                        }
                    }
                    .fileExporterFilenameLabel("Save report as: ")
                    .fileDialogConfirmationLabel("Save report")
            }
        }
#if TESTING
        .navigationTitle("Feature Logging v2.1 - Script Testing\(titleSuffix)")
#else
        .navigationTitle("Feature Logging v2.1\(titleSuffix)")
#endif
        .frame(minWidth: 1024, minHeight: 720)
        .background(Color.BackgroundColor)
        .onChange(of: commandModel.newLog) {
            if viewModel.isDirty {
                documentDirtyAfterSaveAction = {
                    logURL = nil
                    viewModel.selectedFeature = nil
                    viewModel.features = [ObservableFeature]()
                    viewModel.clearDocumentDirty()
                }
                documentDirtyAfterDismissAction = {
                    logURL = nil
                    viewModel.selectedFeature = nil
                    viewModel.features = [ObservableFeature]()
                    viewModel.clearDocumentDirty()
                }
                documentDirtyAlertConfirmation = "Would you like to save this log file before creating a new log?"
                viewModel.isShowingDocumentDirtyAlert.toggle()
            } else {
                logURL = nil
                viewModel.selectedFeature = nil
                viewModel.features = [ObservableFeature]()
                viewModel.clearDocumentDirty()
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
            isShowingStatisticsView = commandModel.showStatistics
        }
        .onChange(of: commandModel.reloadPageCatalog) {
            if !viewModel.features.isEmpty {
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
        .onChange(of: appState.isShowingVersionAvailableToast.wrappedValue) {
            if appState.isShowingVersionAvailableToast.wrappedValue {
                viewModel.dismissAllNonBlockingToasts()
                viewModel.showToast(
                    .alert,
                    "New version available",
                    getVersionSubTitle(),
                    width: 720,
                    buttonTitle: "Download",
                    onButtonTapped: {
                        if let url = URL(string: "https://vero.andydragon.com/app/featurelogging/macInstall_v2") {
                            openURL(url)
                            let terminationTask = DispatchWorkItem {
                                NSApplication.shared.terminate(nil)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: terminationTask)
                        }
                    },
                    onDismissed: {
                        appState.resetCheckingForUpdates()
                    }
                )
            }
        }
        .onChange(of: appState.isShowingVersionRequiredToast.wrappedValue) {
            if appState.isShowingVersionRequiredToast.wrappedValue {
                viewModel.dismissAllNonBlockingToasts()
                viewModel.showToast(
                    .fatal,
                    "New version required",
                    getVersionSubTitle(),
                    width: 720,
                    buttonTitle: "Download",
                    onButtonTapped: {
                        if let url = URL(string: "https://vero.andydragon.com/app/featurelogging/macInstall_v2") {
                            openURL(url)
                            let terminationTask = DispatchWorkItem {
                                NSApplication.shared.terminate(nil)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: terminationTask)
                        }
                    }
                )
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
        .onAppear(perform: {
            setTheme(theme)
            DocumentManager.default.registerReceiver(receiver: self)
        })
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
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }

    private func delayAndTerminate() {
        viewModel.clearDocumentDirty()
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.2,
            execute: {
                NSApplication.shared.terminate(nil)
            })
    }

    private func setTheme(_ newTheme: Theme) {
        if newTheme == .notSet {
            isDarkModeOn = colorScheme == .dark
            Color.isDarkModeOn = colorScheme == .dark
        } else {
            if let details = ThemeDetails[newTheme] {
                Color.currentTheme = details.colorTheme
                isDarkModeOn = details.darkTheme
                Color.isDarkModeOn = details.darkTheme
                theme = newTheme
            }
        }
    }

    private func getVersionSubTitle() -> String {
        if appState.isShowingVersionAvailableToast.wrappedValue {
            return "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) " + "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is available"
                + "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click here to open your browser") " + "(this will go away in 10 seconds)"
        } else if appState.isShowingVersionRequiredToast.wrappedValue {
            return "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) " + "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is required"
                + "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click here to open your browser") " + "or ⌘ + Q to Quit"
        }
        return ""
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
        do {
#if TESTING
            let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/testing/pages.json")!
#else
            let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
#endif
            let pagesCatalog = try await URLSession.shared.decode(ScriptsCatalog.self, from: pagesUrl)
            var pages = [ObservablePage]()
            for hubPair in (pagesCatalog.hubs) {
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

            // Delay the start of the templates download so the window can be ready faster
            try await Task.sleep(nanoseconds: 200_000_000)

#if TESTING
            let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/testing/templates.json")!
#else
            let templatesUrl = URL(string: "https://vero.andydragon.com/static/data/templates.json")!
#endif
            viewModel.loadedCatalogs.templatesCatalog = try await URLSession.shared.decode(TemplateCatalog.self, from: templatesUrl)
            viewModel.loadedCatalogs.waitingForTemplates = false

            do {
                // Delay the start of the disallowed list download so the window can be ready faster
                try await Task.sleep(nanoseconds: 1_000_000_000)

#if TESTING
                let disallowListUrl = URL(string: "https://vero.andydragon.com/static/data/testing/disallowlists.json")!
#else
                let disallowListUrl = URL(string: "https://vero.andydragon.com/static/data/disallowlists.json")!
#endif
                viewModel.loadedCatalogs.disallowList = try await URLSession.shared.decode([String: [String]].self, from: disallowListUrl)
                viewModel.loadedCatalogs.waitingForDisallowList = false
            } catch {
                // do nothing, the disallow list is not critical
                debugPrint(error.localizedDescription)
            }

            do {
                // Delay the start of the disallowed list download so the window can be ready faster
                try await Task.sleep(nanoseconds: 100_000_000)

                appState.checkForUpdates()
            } catch {
                // do nothing, the version check is not critical
                debugPrint(error.localizedDescription)
            }
        } catch {
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
                    DispatchQueue.main.async {
                        Task {
                            await loadPageCatalog()
                        }
                    }
                },
                onDismissed: {
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
                    viewModel.features = loadedLog.getFeatures()
                }
                logURL = file
                viewModel.showSuccessToast(
                    "Loaded features",
                    "Loaded \(viewModel.sortedFeatures.count) features from the log file")
            } catch {
                debugPrint("Error parsing JSON: \(error.localizedDescription)")
            }
        }

        file.stopAccessingSecurityScopedResource()
    }

    private func saveLog(to file: URL) {
        let gotAccess = file.startAccessingSecurityScopedResource()
        if !gotAccess {
            debugPrint("No access to save log")
            return
        }

        do {
            let jsonData = Data(logDocument.text.replacingOccurrences(of: "\\/", with: "/").utf8)
            try jsonData.write(to: file)
            viewModel.showSuccessToast(
                "Saved features",
                "Saved \(viewModel.sortedFeatures.count) features to the log file")
        } catch {
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
                            isShowingScriptView = true
                            return
                        }
                    }
                } while nextIndex != startingIndex
            }
        }
    }
}

extension ContentView: DocumentManagerDelegate {
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
