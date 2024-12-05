//
//  ContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import AlertToast
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

    @State private var toastType: AlertToast.AlertType = .regular
    @State private var toastText = ""
    @State private var toastSubTitle = ""
    @State private var toastDuration = 3.0
    @State private var toastTapAction: () -> Void = {}
    @State private var toastCompletionAction: () -> Void = {}
    @State private var isShowingToast = false
    @State private var isShowingProgressToast = false
    @State private var toastId: UUID?
    @ObservedObject var featureScriptPlaceholders = PlaceholderList()
    @ObservedObject var commentScriptPlaceholders = PlaceholderList()
    @ObservedObject var originalPostScriptPlaceholders = PlaceholderList()
    @State private var isShowingDocumentDirtyAlert = false
    @State private var documentDirtyAlertConfirmation = "Would you like to save this log file?"
    @State private var documentDirtyAfterSaveAction: () -> Void = {}
    @State private var documentDirtyAfterDismissAction: () -> Void = {}
    @State private var imageValidationImageUrl: URL?
    @State private var showFileImporter = false
    @State private var showFileExporter = false
    @State private var isDirty = false
    @State private var logDocument = LogDocument()
    @State private var logURL: URL? = nil
    @State private var showReportFileExporter = false
    @State private var reportDocument = ReportDocument()
    @State private var isShowingScriptView = false
    @State private var isShowingStatisticsView = false
    @State private var isShowingDownloaderView = false
    @State private var isShowingImageValidationView = false
    @State private var shouldScrollFeatureListToSelection = false
    @FocusState private var focusedField: FocusField?
    @State private var savedFocusFieldForVersionToast: FocusField?
    private var appState: VersionCheckAppState
    private var isAnyToastShowing: Bool {
        isShowingToast || appState.isShowingVersionAvailableToast.wrappedValue || appState.isShowingVersionRequiredToast.wrappedValue
    }
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
                        featureScriptPlaceholders,
                        commentScriptPlaceholders,
                        originalPostScriptPlaceholders,
                        $focusedField,
                        $isShowingToast,
                        { isShowingScriptView.toggle() },
                        navigateToNextFeature,
                        showToast
                    )
                } else if isShowingDownloaderView {
                    if isShowingImageValidationView {
                        ImageValidationView(
                            viewModel,
                            $focusedField,
                            $isShowingToast,
                            $isShowingProgressToast,
                            $imageValidationImageUrl,
                            {
                                isShowingImageValidationView.toggle()
                            },
                            { shouldScrollFeatureListToSelection.toggle() },
                            { isDirty = true },
                            showToast, // show toast
                            {
                                isShowingProgressToast.toggle()
                            })
                    } else {
                        PostDownloaderView(
                            viewModel,
                            $focusedField,
                            $isShowingToast,
                            { isShowingDownloaderView.toggle() },
                            { imageUrl in
                                imageValidationImageUrl = imageUrl
                                isShowingImageValidationView.toggle()
                            },
                            { shouldScrollFeatureListToSelection.toggle() },
                            { isDirty = true },
                            showToast
                        )
                    }
                } else if isShowingStatisticsView {
                    StatisticsContentView(
                        $focusedField,
                        $isShowingToast,
                        { commandModel.showStatistics = false },
                        showToast
                    )
                } else {
                    MainContentView(
                        viewModel,
                        $logURL,
                        $focusedField,
                        $isDirty,
                        $logDocument,
                        $showFileImporter,
                        $showFileExporter,
                        $reportDocument,
                        $showReportFileExporter,
                        $isShowingToast,
                        $isShowingDocumentDirtyAlert,
                        $documentDirtyAlertConfirmation,
                        $documentDirtyAfterSaveAction,
                        $documentDirtyAfterDismissAction,
                        $shouldScrollFeatureListToSelection,
                        { isShowingScriptView.toggle() },
                        { isShowingDownloaderView.toggle() },
                        updateStaffLevelForPage,
                        storeStaffLevelForPage,
                        saveLog,
                        setTheme,
                        showToast
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
                            isDirty = false
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
                            print("Saved to \(url)")
                            logURL = url
                            isDirty = false
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
                        case .success(let url):
                            print("Exported to \(url)")
                        case .failure(let error):
                            debugPrint(error)
                        }
                    }
                    .fileExporterFilenameLabel("Save report as: ")
                    .fileDialogConfirmationLabel("Save report")
            }
            .allowsHitTesting(!isAnyToastShowing)
            ToastDismissShield(
                isAnyToastShowing: isAnyToastShowing,
                isShowingToast: $isShowingToast,
                toastId: $toastId,
                isShowingVersionAvailableToast: appState.isShowingVersionAvailableToast)
        }
        #if TESTING
            .navigationTitle("Feature Logging v2.1 - Script Testing\(titleSuffix)")
        #else
            .navigationTitle("Feature Logging v2.1\(titleSuffix)")
        #endif
        .blur(radius: isAnyToastShowing ? 4 : 0)
        .frame(minWidth: 1024, minHeight: 720)
        .background(Color.BackgroundColor)
        .onChange(of: commandModel.newLog) {
            if isDirty {
                documentDirtyAfterSaveAction = {
                    logURL = nil
                    viewModel.selectedFeature = nil
                    viewModel.features = [Feature]()
                    isDirty = false
                }
                documentDirtyAfterDismissAction = {
                    logURL = nil
                    viewModel.selectedFeature = nil
                    viewModel.features = [Feature]()
                    isDirty = false
                }
                documentDirtyAlertConfirmation = "Would you like to save this log file before creating a new log?"
                isShowingDocumentDirtyAlert.toggle()
            } else {
                logURL = nil
                viewModel.selectedFeature = nil
                viewModel.features = [Feature]()
                isDirty = false
            }
        }
        .onChange(of: commandModel.openLog) {
            if isDirty {
                documentDirtyAfterSaveAction = {
                    showFileImporter.toggle()
                }
                documentDirtyAfterDismissAction = {
                    showFileImporter.toggle()
                }
                documentDirtyAlertConfirmation = "Would you like to save this log file before opening another log?"
                isShowingDocumentDirtyAlert.toggle()
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
                isDirty = false
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
        .onChange(of: appState.isShowingVersionAvailableToast.wrappedValue) {
            clearFocusForVersionToast(appState.isShowingVersionAvailableToast.wrappedValue)
        }
        .onChange(of: appState.isShowingVersionRequiredToast.wrappedValue) {
            clearFocusForVersionToast(appState.isShowingVersionRequiredToast.wrappedValue)
        }
        .sheet(isPresented: $isShowingDocumentDirtyAlert) {
            DocumentDirtySheet(
                isShowing: $isShowingDocumentDirtyAlert,
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
        .toast(
            isPresenting: $isShowingToast,
            duration: 0,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: toastType,
                    title: toastText,
                    subTitle: toastSubTitle)
            },
            onTap: toastTapAction,
            completion: toastCompletionAction
        )
        .toast(
            isPresenting: $isShowingProgressToast,
            duration: 0,
            tapToDismiss: false,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .loading,
                    title: "Loading image data...")
            }
        )
        .toast(
            isPresenting: appState.isShowingVersionAvailableToast,
            duration: 10,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("exclamationmark.triangle.fill", .yellow),
                    title: "New version available",
                    subTitle: getVersionSubTitle())
            },
            onTap: {
                if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                    openURL(url)
                }
            },
            completion: {
                appState.resetCheckingForUpdates()
                focusedField = savedFocusFieldForVersionToast
            }
        )
        .toast(
            isPresenting: appState.isShowingVersionRequiredToast,
            duration: 0,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: .systemImage("xmark.octagon.fill", .red),
                    title: "New version required",
                    subTitle: getVersionSubTitle())
            },
            onTap: {
                if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                    openURL(url)
                    NSApplication.shared.terminate(nil)
                }
            },
            completion: {
                appState.resetCheckingForUpdates()
                focusedField = savedFocusFieldForVersionToast
            }
        )
        .onAppear(perform: {
            setTheme(theme)
            DocumentManager.default.registerReceiver(receiver: self)
        })
        .navigationSubtitle(isDirty ? "edited" : "")
        .task {
            await loadPageCatalog()
        }
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }

    private func delayAndTerminate() {
        isDirty = false
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.2,
            execute: {
                NSApplication.shared.terminate(nil)
            })
    }

    private func clearFocusForVersionToast(_ value: Bool) {
        if value {
            savedFocusFieldForVersionToast = focusedField
            focusedField = nil
        }
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

    private func showToast(
        _ type: AlertToast.AlertType,
        _ text: String,
        subTitle: String = "",
        duration: ToastDuration = .Success,
        onTap: @escaping () -> Void = {}
    ) {
        if isShowingToast {
            toastId = nil
            isShowingToast.toggle()
        }
        let savedFocusedField = focusedField
        withAnimation {
            toastType = type
            toastText = text
            toastSubTitle = subTitle
            toastTapAction = onTap
            toastCompletionAction = {}
            focusedField = nil
            toastId = UUID()
            isShowingToast.toggle()
        }

        if duration != .Blocking {
            let expectedToastId = toastId
            DispatchQueue.main.asyncAfter(
                deadline: .now() + .seconds(duration.rawValue),
                execute: {
                    if isShowingToast && toastId == expectedToastId {
                        toastId = nil
                        isShowingToast.toggle()
                        focusedField = savedFocusedField
                    }
                })
        }
    }

    private func showToastWithCompletion(
        _ type: AlertToast.AlertType,
        _ text: String,
        subTitle: String = "",
        duration: ToastDuration = .Success,
        onTap: @escaping () -> Void = {},
        onCompletion: @escaping () -> Void = {}
    ) {
        if isShowingToast {
            toastId = nil
            isShowingToast.toggle()
        }
        let savedFocusedField = focusedField
        withAnimation {
            toastType = type
            toastText = text
            toastSubTitle = subTitle
            toastTapAction = onTap
            toastCompletionAction = onCompletion
            focusedField = nil
            toastId = UUID()
            isShowingToast.toggle()
        }

        if duration != .Blocking {
            let expectedToastId = toastId
            DispatchQueue.main.asyncAfter(
                deadline: .now() + .seconds(duration.rawValue),
                execute: {
                    if isShowingToast && toastId == expectedToastId {
                        toastId = nil
                        isShowingToast.toggle()
                        focusedField = savedFocusedField
                    }
                })
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
            var pages = [LoadedPage]()
            for hubPair in (pagesCatalog.hubs) {
                for hubPage in hubPair.value {
                    pages.append(LoadedPage(hub: hubPair.key, page: hubPage))
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
            showToastWithCompletion(
                .error(.red),
                "Failed to load pages",
                subTitle: "The application requires the catalog to perform its operations: \(error.localizedDescription)\n\n" +
                    "Click here to try again immediately or wait \(ToastDuration.CatalogLoadFailure.rawValue) seconds to automatically try again.",
                duration: .CatalogLoadFailure,
                onTap: {
                    DispatchQueue.main.async {
                        Task {
                            await loadPageCatalog()
                        }
                    }
                },
                onCompletion: {
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
            print("No access?")
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
                showToast(
                    .complete(.green),
                    "Loaded features",
                    subTitle: "Loaded \(viewModel.sortedFeatures.count) features from the log file",
                    duration: .Success) {}
            } catch {
                debugPrint("Error parsing JSON: \(error.localizedDescription)")
            }
        }

        file.stopAccessingSecurityScopedResource()
    }

    private func saveLog(to file: URL) {
        let gotAccess = file.startAccessingSecurityScopedResource()
        if !gotAccess {
            print("No access?")
            return
        }

        do {
            let jsonData = Data(logDocument.text.replacingOccurrences(of: "\\/", with: "/").utf8)
            try jsonData.write(to: file)
            showToast(
                .complete(.green),
                "Saved features",
                subTitle: "Saved \(viewModel.sortedFeatures.count) features to the log file",
                duration: .Success)
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
                            viewModel.selectedFeature = SharedFeature(using: page, from: viewModel.sortedFeatures[nextIndex])

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

#Preview {
    @Previewable @State var checkingForUpdates = false
    @Previewable @State var isShowingVersionAvailableToast = false
    @Previewable @State var isShowingVersionRequiredToast = false
    @Previewable @State var versionCheckToast = VersionCheckToast()

    var localAppState = VersionCheckAppState(
        isCheckingForUpdates: $checkingForUpdates,
        isShowingVersionAvailableToast: $isShowingVersionAvailableToast,
        isShowingVersionRequiredToast: $isShowingVersionRequiredToast,
        versionCheckToast: $versionCheckToast,
        versionLocation: "https://vero.andydragon.com/static/data/trackingtags/version.json")
    localAppState.isPreviewMode = true

    return ContentView(localAppState)
}

extension ContentView: DocumentManagerDelegate {
    func onCanTerminate() -> Bool {
        if isDirty {
            documentDirtyAfterDismissAction = {
                delayAndTerminate()
            }
            documentDirtyAfterSaveAction = {
                delayAndTerminate()
            }
            documentDirtyAlertConfirmation = "Would you like to save this log file before leaving the app?"
            isShowingDocumentDirtyAlert.toggle()
        }
        return !isDirty
    }
}

extension ContentView {
    @Observable
    class ViewModel {
        var loadedCatalogs = LoadedCatalogs()
        var selectedPage: LoadedPage?
        var selectedPageStaffLevel: StaffLevelCase = .mod
        var features = [Feature]()
        var selectedFeature: SharedFeature?
        var sortedFeatures: [Feature] {
            return features.sorted(by: compareFeatures)
        }
        var pickedFeatures: [Feature] {
            return sortedFeatures.filter({ $0.isPicked })
        }
        var yourName = UserDefaults.standard.string(forKey: "YourName") ?? ""
        var yourFirstName = UserDefaults.standard.string(forKey: "YourFirstName") ?? ""

        init() {}

        func generateReport(
            _ personalMessageFormat: String,
            _ personalMessageFirstFormat: String
        ) -> String {
            var lines = [String]()
            var personalLines = [String]()
            if let selectedPage = selectedPage {
                if selectedPage.hub == "click" {
                    lines.append("Picks for #\(selectedPage.displayName)")
                    lines.append("")
                    var wasLastItemPicked = true
                    for feature in sortedFeatures {
                        var isPicked = feature.isPicked
                        var indent = ""
                        var prefix = ""
                        if feature.photoFeaturedOnPage {
                            prefix = "[already featured] "
                            indent = "    "
                            isPicked = false
                        } else if feature.tooSoonToFeatureUser {
                            prefix = "[too soon] "
                            indent = "    "
                            isPicked = false
                        } else if feature.tinEyeResults == .matchFound {
                            prefix = "[tineye match] "
                            indent = "    "
                        } else if feature.aiCheckResults == .ai {
                            prefix = "[AI] "
                            indent = "    "
                        } else if !feature.isPicked {
                            prefix = "[not picked] "
                            indent = "    "
                        }
                        if !isPicked && wasLastItemPicked {
                            lines.append("---------------")
                            lines.append("")
                        }
                        wasLastItemPicked = isPicked
                        lines.append("\(indent)\(prefix)\(feature.postLink)")
                        lines.append("\(indent)user - \(feature.userName) @\(feature.userAlias)")
                        lines.append("\(indent)member level - \(feature.userLevel.rawValue)")
                        if feature.userHasFeaturesOnPage {
                            lines.append("\(indent)last feature on page - \(feature.lastFeaturedOnPage) (features on page \(feature.featureCountOnPage))")
                        } else {
                            lines.append("\(indent)last feature on page - never (features on page 0)")
                        }
                        if feature.userHasFeaturesOnHub {
                            lines.append("\(indent)last feature - \(feature.lastFeaturedOnHub) \(feature.lastFeaturedPage) (features \(feature.featureCountOnHub))")
                        } else {
                            lines.append("\(indent)last feature - never (features 0)")
                        }
                        let photoFeaturedOnPage = feature.photoFeaturedOnPage ? "YES" : "no"
                        let photoFeaturedOnHub = feature.photoFeaturedOnHub ? "\(feature.photoLastFeaturedOnHub) \(feature.photoLastFeaturedPage)" : "no"
                        lines.append("\(indent)feature - \(feature.featureDescription), featured on page - \(photoFeaturedOnPage), featured on hub - \(photoFeaturedOnHub)")
                        lines.append("\(indent)teammate - \(feature.userIsTeammate ? "yes" : "no")")
                        switch feature.tagSource {
                        case .commonPageTag:
                            lines.append("\(indent)hashtag = #\(selectedPage.hub)_\(selectedPage.pageName ?? selectedPage.name)")
                            break
                        case .clickCommunityTag:
                            lines.append("\(indent)hashtag = #\(selectedPage.hub)_community")
                            break
                        case .clickHubTag:
                            lines.append("\(indent)hashtag = #\(selectedPage.hub)_hub")
                            break
                        default:
                            lines.append("\(indent)hashtag = other")
                            break
                        }
                        lines.append("\(indent)tineye: \(feature.tinEyeResults.rawValue)")
                        lines.append("\(indent)ai check: \(feature.aiCheckResults.rawValue)")
                        lines.append("")

                        if isPicked {
                            let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
                            let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
                            let fullPersonalMessage =
                            personalMessageTemplate
                                .replacingOccurrences(of: "%%PAGENAME%%", with: selectedPage.displayName)
                                .replacingOccurrences(of: "%%HUBNAME%%", with: selectedPage.hub)
                                .replacingOccurrences(of: "%%USERNAME%%", with: feature.userName)
                                .replacingOccurrences(of: "%%USERALIAS%%", with: feature.userAlias)
                                .replacingOccurrences(of: "%%PERSONALMESSAGE%%", with: personalMessage)
                            personalLines.append(fullPersonalMessage)
                        }
                    }
                } else if selectedPage.hub == "snap" {
                    lines.append("Picks for #\(selectedPage.displayName)")
                    lines.append("")
                    var wasLastItemPicked = true
                    for feature in sortedFeatures {
                        var isPicked = feature.isPicked
                        var indent = ""
                        var prefix = ""
                        if feature.photoFeaturedOnPage {
                            prefix = "[already featured] "
                            indent = "    "
                            isPicked = false
                        } else if feature.tooSoonToFeatureUser {
                            prefix = "[too soon] "
                            indent = "    "
                            isPicked = false
                        } else if feature.tinEyeResults == .matchFound {
                            prefix = "[tineye match] "
                            indent = "    "
                        } else if feature.aiCheckResults == .ai {
                            prefix = "[AI] "
                            indent = "    "
                        } else if !feature.isPicked {
                            prefix = "[not picked] "
                            indent = "    "
                        }
                        if !isPicked && wasLastItemPicked {
                            lines.append("---------------")
                            lines.append("")
                        }
                        wasLastItemPicked = isPicked
                        lines.append("\(indent)\(prefix)\(feature.postLink)")
                        lines.append("\(indent)user - \(feature.userName) @\(feature.userAlias)")
                        lines.append("\(indent)member level - \(feature.userLevel.rawValue)")
                        if feature.userHasFeaturesOnPage {
                            lines.append(
                                "\(indent)last feature on page - \(feature.lastFeaturedOnPage) (features on page \(feature.featureCountOnPage) Snap + \(feature.featureCountOnRawPage) RAW)"
                            )
                        } else {
                            lines.append("\(indent)last feature on page - never (features on page 0 Snap + 0 RAW)")
                        }
                        if feature.userHasFeaturesOnHub {
                            lines.append(
                                "\(indent)last feature - \(feature.lastFeaturedOnHub) \(feature.lastFeaturedPage) (features \(feature.featureCountOnHub) Snap + \(feature.featureCountOnRawHub) RAW)"
                            )
                        } else {
                            lines.append("\(indent)last feature - never (features 0 Snap + 0 RAW)")
                        }
                        let photoFeaturedOnPage = feature.photoFeaturedOnPage ? "YES" : "no"
                        let photoFeaturedOnHub = feature.photoFeaturedOnHub ? "\(feature.photoLastFeaturedOnHub) \(feature.photoLastFeaturedPage)" : "no"
                        lines.append("\(indent)feature - \(feature.featureDescription), featured on page - \(photoFeaturedOnPage), featured on hub - \(photoFeaturedOnHub)")
                        lines.append("\(indent)teammate - \(feature.userIsTeammate ? "yes" : "no")")
                        switch feature.tagSource {
                        case .commonPageTag:
                            lines.append("\(indent)hashtag = #\(selectedPage.hub)_\(selectedPage.pageName ?? selectedPage.name)")
                            break
                        case .snapRawPageTag:
                            lines.append("\(indent)hashtag = #raw_\(selectedPage.pageName ?? selectedPage.name)")
                            break
                        case .snapCommunityTag:
                            lines.append("\(indent)hashtag = #\(selectedPage.hub)_community")
                            break
                        case .snapRawCommunityTag:
                            lines.append("\(indent)hashtag = #raw_community")
                            break
                        default:
                            lines.append("\(indent)hashtag = other")
                            break
                        }
                        lines.append("\(indent)tineye: \(feature.tinEyeResults.rawValue)")
                        lines.append("\(indent)ai check: \(feature.aiCheckResults.rawValue)")
                        lines.append("")

                        if isPicked {
                            let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
                            let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
                            let fullPersonalMessage =
                            personalMessageTemplate
                                .replacingOccurrences(of: "%%PAGENAME%%", with: selectedPage.displayName)
                                .replacingOccurrences(of: "%%HUBNAME%%", with: selectedPage.hub)
                                .replacingOccurrences(of: "%%USERNAME%%", with: feature.userName)
                                .replacingOccurrences(of: "%%USERALIAS%%", with: feature.userAlias)
                                .replacingOccurrences(of: "%%PERSONALMESSAGE%%", with: personalMessage)
                            personalLines.append(fullPersonalMessage)
                        }
                    }
                } else {
                    lines.append("Picks for #\(selectedPage.displayName)")
                    lines.append("")
                    var wasLastItemPicked = true
                    for feature in sortedFeatures {
                        var isPicked = feature.isPicked
                        var indent = ""
                        var prefix = ""
                        if feature.photoFeaturedOnPage {
                            prefix = "[already featured] "
                            indent = "    "
                            isPicked = false
                        } else if feature.tooSoonToFeatureUser {
                            prefix = "[too soon] "
                            indent = "    "
                            isPicked = false
                        } else if feature.tinEyeResults == .matchFound {
                            prefix = "[tineye match] "
                            indent = "    "
                            isPicked = false
                        } else if feature.aiCheckResults == .ai {
                            prefix = "[AI] "
                            indent = "    "
                            isPicked = false
                        } else if !feature.isPicked {
                            prefix = "[not picked] "
                            indent = "    "
                            isPicked = false
                        }
                        if !isPicked && wasLastItemPicked {
                            lines.append("---------------")
                            lines.append("")
                        }
                        wasLastItemPicked = isPicked
                        lines.append("\(indent)\(prefix)\(feature.postLink)")
                        lines.append("\(indent)user - \(feature.userName) @\(feature.userAlias)")
                        lines.append("\(indent)member level - \(feature.userLevel.rawValue)")
                        let photoFeaturedOnPage = feature.photoFeaturedOnPage ? "YES" : "no"
                        lines.append("\(indent)feature - \(feature.featureDescription), featured on page - \(photoFeaturedOnPage)")
                        lines.append("\(indent)teammate - \(feature.userIsTeammate ? "yes" : "no")")
                        switch feature.tagSource {
                        case .commonPageTag:
                            lines.append("\(indent)hashtag = #\(selectedPage.hub)_\(selectedPage.pageName ?? selectedPage.name)")
                            break
                        default:
                            lines.append("\(indent)hashtag = other")
                            break
                        }
                        lines.append("\(indent)tineye - \(feature.tinEyeResults.rawValue)")
                        lines.append("\(indent)ai check - \(feature.aiCheckResults.rawValue)")
                        lines.append("")

                        if isPicked {
                            let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
                            let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
                            let fullPersonalMessage =
                            personalMessageTemplate
                                .replacingOccurrences(of: "%%PAGENAME%%", with: selectedPage.displayName)
                                .replacingOccurrences(of: "%%HUBNAME%%", with: "")
                                .replacingOccurrences(of: "%%USERNAME%%", with: feature.userName)
                                .replacingOccurrences(of: "%%USERALIAS%%", with: feature.userAlias)
                                .replacingOccurrences(of: "%%PERSONALMESSAGE%%", with: personalMessage)
                            personalLines.append(fullPersonalMessage)
                        }
                    }
                }
                var text = ""
                for line in lines { text = text + line + "\n" }
                text = text + "---------------\n\n"
                if !personalLines.isEmpty {
                    for line in personalLines { text = text + line + "\n" }
                    text = text + "\n---------------\n"
                }
                return text
            }
            return ""
        }
    }

    static func compareFeatures(_ lhs: Feature, _ rhs: Feature) -> Bool {
        // Empty names always at the bottom
        if lhs.userName.isEmpty {
            return false
        }
        if rhs.userName.isEmpty {
            return true
        }

        if lhs.photoFeaturedOnPage && rhs.photoFeaturedOnPage {
            return lhs.userName < rhs.userName
        }
        if lhs.photoFeaturedOnPage {
            return false
        }
        if rhs.photoFeaturedOnPage {
            return true
        }

        let lhsTinEye = lhs.tinEyeResults == .matchFound
        let rhsTinEye = rhs.tinEyeResults == .matchFound
        if lhsTinEye && rhsTinEye {
            return lhs.userName < rhs.userName
        }
        if lhsTinEye {
            return false
        }
        if rhsTinEye {
            return true
        }

        let lhAiCheck = lhs.aiCheckResults == .ai
        let rhAiCheck = rhs.aiCheckResults == .ai
        if lhAiCheck && rhAiCheck {
            return lhs.userName < rhs.userName
        }
        if lhAiCheck {
            return false
        }
        if rhAiCheck {
            return true
        }

        if lhs.tooSoonToFeatureUser && rhs.tooSoonToFeatureUser {
            return lhs.userName < rhs.userName
        }
        if lhs.tooSoonToFeatureUser {
            return false
        }
        if rhs.tooSoonToFeatureUser {
            return true
        }

        if !lhs.isPicked && !rhs.isPicked {
            return lhs.userName < rhs.userName
        }
        if !lhs.isPicked {
            return false
        }
        if !rhs.isPicked {
            return true
        }

        return lhs.userName < rhs.userName
    }
}
