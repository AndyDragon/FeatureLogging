//
//  ContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import UniformTypeIdentifiers
import AlertToast

enum FocusedField {
    case pagePicker
}

struct ContentView: View {
    // THEME
    @AppStorage(
        Constants.THEME_APP_STORE_KEY,
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var theme = Theme.notSet
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var isDarkModeOn = true

    @AppStorage(
        "preference_includehash",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var includeHash = false
    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFormat = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirstFormat = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"

    @EnvironmentObject var commandModel: AppCommandModel

    @Environment(\.openURL) private var openURL
    @State private var page: String = UserDefaults.standard.string(forKey: "Page") ?? ""
    @State private var toastType: AlertToast.AlertType = .regular
    @State private var toastText = ""
    @State private var toastSubTitle = ""
    @State private var toastDuration = 3.0
    @State private var toastTapAction: () -> Void = {}
    @State private var isShowingToast = false
    @State private var hoveredFeature: Feature? = nil
    @State private var loadedPages = [LoadedPage]()
    private var loadedPage: LoadedPage? {
        loadedPages.first(where: { $0.id == page })
    }
    @State private var featuresViewModel = FeaturesViewModel()
    @State private var sortedFeatures = [Feature]()
    @State private var selectedFeature: Feature? = nil
    @State private var shouldScrollFeatureListToSelection = false
    @State private var isShowingDocumentDirtyAlert = false
    @State private var documentDirtyAlertConfirmation = "Would you like to save this log file?"
    @State private var documentDirtyAfterSaveAction: () -> Void = {}
    @State private var documentDirtyAfterDismissAction: () -> Void = {}
    @State private var showFileImporter = false
    @State private var showFileExporter = false
    @State private var isDirty = false
    @State private var logDocument = LogDocument()
    @State private var logURL: URL? = nil
    @State private var showReportFileExporter = false
    @State private var reportDocument = ReportDocument()
    @FocusState private var focusedField: FocusedField?
    private var appState: VersionCheckAppState
    private var isAnyToastShowing: Bool {
        isShowingToast ||
        appState.isShowingVersionAvailableToast.wrappedValue ||
        appState.isShowingVersionRequiredToast.wrappedValue
    }
    private var fileNameDateFormatter: DateFormatter {
        get {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }
    }

    init(_ appState: VersionCheckAppState) {
        self.appState = appState
    }

    var body: some View {
        ZStack {
            Color.BackgroundColor.edgesIgnoringSafeArea(.all)

            VStack {
                // Page picker
                HStack(alignment: .center) {
                    Text("Page:")
                        .frame(width: 108, alignment: .trailing)

                    Picker("", selection: $page.onChange { value in
                        UserDefaults.standard.set(page, forKey: "Page")
                        isDirty = true
                        logURL = nil
                        selectedFeature = nil
                        featuresViewModel = FeaturesViewModel()
                        sortedFeatures = featuresViewModel.sortedFeatures
                    }) {
                        ForEach(loadedPages) { page in
                            if page.name != "default" {
                                Text(page.displayName).tag(page.id)
                            }
                        }
                    }
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .foregroundStyle(Color.AccentColor, Color.TextColorPrimary)
                    .focusable()
                    .focused($focusedField, equals: .pagePicker)

                    Menu("Copy tag", systemImage: "tag.fill") {
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(loadedPage?.hub ?? "")_\(loadedPage?.pageName ?? loadedPage?.name ?? "")")
                            showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the page tag to the clipboard", duration: 2) { }
                        }) {
                            Text("Page tag")
                        }
                        if loadedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_\(loadedPage?.pageName ?? loadedPage?.name ?? "")")
                                showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the RAW page tag to the clipboard", duration: 2) { }
                            }) {
                                Text("RAW page tag")
                            }
                        }
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(loadedPage?.hub ?? "")_community")
                            showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the community tag to the clipboard", duration: 2) { }
                        }) {
                            Text("Community tag")
                        }
                        if loadedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_community")
                                showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the RAW community tag to the clipboard", duration: 2) { }
                            }) {
                                Text("RAW community tag")
                            }
                        }
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(loadedPage?.hub ?? "")_hub")
                            showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the hub tag to the clipboard", duration: 2) { }
                        }) {
                            Text("Hub tag")
                        }
                        if loadedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_hub")
                                showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the RAW hub tag to the clipboard", duration: 2) { }
                            }) {
                                Text("RAW hub tag")
                            }
                        }
                    }
                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                    .tint(Color.AccentColor)
                    .accentColor(Color.AccentColor)
                    .disabled(isAnyToastShowing || (loadedPage?.hub != "click" && loadedPage?.hub != "snap"))
                    .frame(maxWidth: 132)
                    .focusable()
                }

                // Feature editor
                VStack {
                    if let currentFeature = selectedFeature {
                        FeatureEditor(feature: currentFeature, loadedPage: loadedPage, close: {
                            selectedFeature = nil
                        }, updateList: {
                            sortedFeatures = featuresViewModel.sortedFeatures
                            shouldScrollFeatureListToSelection.toggle()
                        }, markDocumentDirty: {
                            isDirty = true
                        }, showToast: showToast)
                    } else {
                        Spacer()
                    }
                }
                .frame(height: 380)

                // Feature list buttons
                HStack {
                    Spacer()

                    // Add feature
                    Button(action: {
                        let linkText = stringFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                        let existingFeature = featuresViewModel.features.first(where: { $0.postLink.lowercased() == linkText.lowercased() })
                        if existingFeature != nil {
                            showToast(
                                .systemImage("exclamationmark.triangle.fill", .orange),
                                "Found duplicate post link",
                                subTitle: "There is already a feature in the list with that post link, selected the existing feature",
                                duration: 3)
                            selectedFeature = existingFeature
                            return
                        }
                        let feature = Feature()
                        if linkText.starts(with: "https://vero.co/") {
                            feature.postLink = linkText
                            let possibleUserAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
                            // If the user doesn't have an alias, the link will have a single letter, often 'p'
                            if possibleUserAlias.count > 1 {
                                feature.userAlias = possibleUserAlias
                            }
                        }
                        featuresViewModel.features.append(feature)
                        sortedFeatures = featuresViewModel.sortedFeatures
                        selectedFeature = feature
                        isDirty = true
                        shouldScrollFeatureListToSelection.toggle()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Add feature")
                        }
                    }
                    .disabled(isAnyToastShowing)
                    .keyboardShortcut("+", modifiers: .command)

                    Spacer()
                        .frame(width: 16)

                    // Remove feature
                    Button(action: {
                        if let currentFeature = selectedFeature {
                            selectedFeature = nil
                            featuresViewModel.features.removeAll(where: { $0.id == currentFeature.id })
                            sortedFeatures = featuresViewModel.sortedFeatures
                            isDirty = true
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.minus")
                                .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                            Text("Remove feature")
                        }
                    }
                    .disabled(isAnyToastShowing || selectedFeature == nil)
                    .keyboardShortcut("-", modifiers: .command)

                    Spacer()
                        .frame(width: 16)

                    // Remove all
                    Button(action: {
                        selectedFeature = nil
                        featuresViewModel = FeaturesViewModel()
                        sortedFeatures = featuresViewModel.sortedFeatures
                        isDirty = true
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                            Text("Remove all")
                        }
                    }
                    .disabled(isAnyToastShowing || featuresViewModel.features.isEmpty)
                    .keyboardShortcut(.delete, modifiers: .command)
                }

                // Feature list
                ScrollViewReader { proxy in
                    List {
                        ForEach(sortedFeatures, id: \.self) { feature in
                            FeatureListRow(feature: feature, loadedPage: loadedPage!, markDocumentDirty: {
                                isDirty = true
                            }, ensureSelected: {
                                selectedFeature = feature
                            }, showToast: showToast)
                            .padding([.top, .bottom], 8)
                            .padding([.leading, .trailing])
                            .foregroundStyle(Color(nsColor: hoveredFeature == feature
                                                   ? NSColor.selectedControlTextColor
                                                   : NSColor.labelColor), Color(nsColor: .labelColor))
                            .background(selectedFeature == feature
                                        ? Color.BackgroundColorListSelected
                                        : hoveredFeature == feature
                                        ? Color.BackgroundColorListSelected.opacity(0.33)
                                        : Color.BackgroundColorList)
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
                                    selectedFeature = feature
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(4)
                    .presentationBackground(.clear)
                    .onChange(of: shouldScrollFeatureListToSelection, {
                        withAnimation {
                            proxy.scrollTo(selectedFeature)
                        }
                    })
                    .onTapGesture {
                        withAnimation {
                            selectedFeature = nil
                        }
                    }
                    .focusable()
                }
                .scrollContentBackground(.hidden)
                .background(Color.BackgroundColorList)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
            }
            .toolbar {
                // Open log
                Button(action: {
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
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.on.square")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Open log...")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    }
                    .padding(4)
                    .buttonStyle(.plain)
                }
                .fileImporter(
                    isPresented: $showFileImporter,
                    allowedContentTypes: [.json]
                ) { result in
                    switch result {
                    case .success(let file):
                        loadLog(from: file)
                        isDirty = false
                    case .failure(let error):
                        print(error)
                    }
                }
                .disabled(isAnyToastShowing || loadedPage == nil)

                // Save log
                Button(action: {
                    logDocument = LogDocument(page: loadedPage!, features: featuresViewModel.features)
                    if let file = logURL {
                        saveLog(to: file)
                        isDirty = false
                    } else {
                        showFileExporter.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Save log...")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    }
                    .padding(4)
                    .buttonStyle(.plain)
                }
                .fileExporter(
                    isPresented: $showFileExporter,
                    document: logDocument,
                    contentType: .json,
                    defaultFilename: "\(loadedPage?.hub ?? "hub")_\(loadedPage?.pageName ?? loadedPage?.name ?? "page") - \(fileNameDateFormatter.string(from: Date.now)).json"
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
                        debugPrint(error)
                    }
                }
                .disabled(isAnyToastShowing || loadedPage == nil)

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
                    .buttonStyle(.plain)
                }
                .disabled(isAnyToastShowing || loadedPage == nil)

                // Save report
                Button(action: {
                    reportDocument = ReportDocument(initialText: generateReport())
                    showReportFileExporter.toggle()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                        Text("Save report...")
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
                    }
                    .padding(4)
                    .buttonStyle(.plain)
                }
                .fileExporter(
                    isPresented: $showReportFileExporter,
                    document: reportDocument,
                    contentType: UTType.features,
                    defaultFilename: logURL != nil ?
                    "\(logURL!.deletingPathExtension().lastPathComponent).features" :
                        "\(loadedPage?.hub ?? "hub")_\(loadedPage?.pageName ?? loadedPage?.name ?? "page") - \(fileNameDateFormatter.string(from: Date.now)).features"
                ) { result in
                    switch result {
                    case .success(let url):
                        print("Exported to \(url)")
                    case .failure(let error):
                        debugPrint(error)
                    }
                }
                .disabled(isAnyToastShowing || loadedPage == nil)

                // Theme
                Menu("Theme", systemImage: "paintpalette") {
                    Picker("Theme:", selection: $theme.onChange(setTheme)) {
                        ForEach(Theme.allCases) { itemTheme in
                            if itemTheme != .notSet {
                                Text(itemTheme.rawValue).tag(itemTheme)
                            }
                        }
                    }
                    .pickerStyle(.inline)
                }
                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                .disabled(isAnyToastShowing)
            }
            .padding()
            .allowsHitTesting(!isAnyToastShowing)
            ToastDismissShield(
                isAnyToastShowing: isAnyToastShowing,
                isShowingToast: $isShowingToast,
                isShowingVersionAvailableToast: appState.isShowingVersionAvailableToast)
        }
        .blur(radius: isAnyToastShowing ? 4 : 0)
        .frame(minWidth: 1024, minHeight: 720)
        .background(Color.BackgroundColor)
        .onChange(of: commandModel.newLog) {
            logURL = nil
            selectedFeature = nil
            featuresViewModel = FeaturesViewModel()
            sortedFeatures = featuresViewModel.sortedFeatures
        }
        .onChange(of: commandModel.openLog) {
            showFileImporter.toggle()
        }
        .onChange(of: commandModel.saveLog) {
            logDocument = LogDocument(page: loadedPage!, features: featuresViewModel.features)
            if let file = logURL {
                saveLog(to: file)
                documentDirtyAfterSaveAction()
                documentDirtyAfterSaveAction = {}
                documentDirtyAfterDismissAction = {}
            } else {
                showFileExporter.toggle()
            }
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
            onTap: toastTapAction)
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
            })
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
            })
        .onAppear(perform: {
            setTheme(theme)
            focusedField = .pagePicker
            DocumentManager.default.registerReceiver(receiver: self)
        })
        .navigationSubtitle(isDirty ? "edited" : "")
        .task {
            do {
                let pagesUrl = URL(string: "https://vero.andydragon.com/static/data/pages.json")!
                let pagesCatalog = try await URLSession.shared.decode(ScriptsCatalog.self, from: pagesUrl)
                var pages = [LoadedPage]()
                for hubPair in (pagesCatalog.hubs) {
                    for hubPage in hubPair.value {
                        pages.append(LoadedPage.from(hub: hubPair.key, page: hubPage))
                    }
                }
                loadedPages.removeAll()
                loadedPages.append(contentsOf: pages.sorted(by: {
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
                if page.isEmpty {
                    page = loadedPages.first?.id ?? ""
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
                debugPrint("Failure in initialization task")
                debugPrint(error.localizedDescription)
            }
        }
        .preferredColorScheme(isDarkModeOn ? .dark : .light)
    }

    private func delayAndTerminate() {
        isDirty = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            NSApplication.shared.terminate(nil)
        })
    }

    private func setTheme(_ newTheme: Theme) {
        if (newTheme == .notSet) {
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
        duration: Int = 3,
        onTap: @escaping () -> Void = {}
    ) {
        let savedfocusedField = focusedField
        withAnimation {
            toastType = type
            toastText = text
            toastSubTitle = subTitle
            toastTapAction = onTap
            focusedField = nil
            isShowingToast.toggle()
        }

        if duration != 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration), execute: {
                if (isShowingToast) {
                    isShowingToast.toggle()
                    focusedField = savedfocusedField
                }
            })
        }
    }

    private func getVersionSubTitle() -> String {
        if appState.isShowingVersionAvailableToast.wrappedValue {
            return "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) " +
            "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is available" +
            "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click here to open your browser") " +
            "(this will go away in 10 seconds)"
        } else if appState.isShowingVersionRequiredToast.wrappedValue {
            return "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) " +
            "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is required" +
            "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click here to open your browser") " +
            "or ⌘ + Q to Quit"
        }
        return ""
    }

    private func loadLog(from file: URL) {
        let gotAccess = file.startAccessingSecurityScopedResource()
        if (!gotAccess) {
            print("No access?")
            return
        }

        let fileContents = FileManager.default.contents(atPath: file.path)
        if let json = fileContents {
            let jsonString = String(String(decoding: json, as: UTF8.self))
            do {
                let decoder = JSONDecoder()
                let loadedLog = try decoder.decode(Log.self, from: jsonString.data(using: .utf8)!)
                if let loadedPage = loadedPages.first(where: { $0.id == loadedLog.page }) {
                    selectedFeature = nil
                    page = loadedPage.id
                    featuresViewModel.features = loadedLog.getFeatures()
                    sortedFeatures = featuresViewModel.sortedFeatures
                }
                logURL = file
                showToast(
                    .complete(.green),
                    "Loaded features",
                    subTitle: "Loaded \(sortedFeatures.count) features from the log file",
                    duration: 2)
            } catch {
                debugPrint("Error parsing JSON: \(error.localizedDescription)")
            }
        }

        file.stopAccessingSecurityScopedResource()
    }

    private func saveLog(to file: URL) {
        let gotAccess = file.startAccessingSecurityScopedResource()
        if (!gotAccess) {
            print("No access?")
            return
        }

        do {
            let jsonData = Data(logDocument.text.replacingOccurrences(of: "\\/", with: "/").utf8)
            try jsonData.write(to: file)
            showToast(
                .complete(.green),
                "Saved features",
                subTitle: "Saved \(sortedFeatures.count) features to the log file",
                duration: 2)
        } catch {
            debugPrint(error)
        }

        file.stopAccessingSecurityScopedResource()
    }

    private func generateReport() -> String {
        var lines = [String]()
        var personalLines = [String]()
        if loadedPage!.hub == "click" {
            lines.append("Picks for #\(loadedPage!.displayName)")
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
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                case .clickCommunityTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_community")
                    break;
                case .clickHubTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_hub")
                    break;
                default:
                    lines.append("\(indent)hashtag = other")
                    break;
                }
                lines.append("\(indent)tineye: \(feature.tinEyeResults.rawValue)")
                lines.append("\(indent)ai check: \(feature.aiCheckResults.rawValue)")
                lines.append("")

                if isPicked {
                    let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
                    let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
                    let fullPersonalMessage = personalMessageTemplate
                        .replacingOccurrences(of: "%%PAGENAME%%", with: loadedPage!.displayName)
                        .replacingOccurrences(of: "%%HUBNAME%%", with: loadedPage!.hub)
                        .replacingOccurrences(of: "%%USERNAME%%", with: feature.userName)
                        .replacingOccurrences(of: "%%USERALIAS%%", with: feature.userAlias)
                        .replacingOccurrences(of: "%%PERSONALMESSAGE%%", with: personalMessage)
                    personalLines.append(fullPersonalMessage)
                }
            }
        } else if loadedPage!.hub == "snap" {
            lines.append("Picks for #\(loadedPage!.displayName)")
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
                    lines.append("\(indent)last feature on page - \(feature.lastFeaturedOnPage) (features on page \(feature.featureCountOnPage) Snap + \(feature.featureCountOnRawPage) RAW)")
                } else {
                    lines.append("\(indent)last feature on page - never (features on page 0 Snap + 0 RAW)")
                }
                if feature.userHasFeaturesOnHub {
                    lines.append("\(indent)last feature - \(feature.lastFeaturedOnHub) \(feature.lastFeaturedPage) (features \(feature.featureCountOnHub) Snap + \(feature.featureCountOnRawHub) RAW)")
                } else {
                    lines.append("\(indent)last feature - never (features 0 Snap + 0 RAW)")
                }
                let photoFeaturedOnPage = feature.photoFeaturedOnPage ? "YES" : "no"
                let photoFeaturedOnHub = feature.photoFeaturedOnHub ? "\(feature.photoLastFeaturedOnHub) \(feature.photoLastFeaturedPage)" : "no"
                lines.append("\(indent)feature - \(feature.featureDescription), featured on page - \(photoFeaturedOnPage), featured on hub - \(photoFeaturedOnHub)")
                lines.append("\(indent)teammate - \(feature.userIsTeammate ? "yes" : "no")")
                switch feature.tagSource {
                case .commonPageTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                case .snapRawPageTag:
                    lines.append("\(indent)hashtag = #raw_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                case .snapCommunityTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_community")
                    break;
                case .snapRawCommunityTag:
                    lines.append("\(indent)hashtag = #raw_community")
                    break;
                default:
                    lines.append("\(indent)hashtag = other")
                    break;
                }
                lines.append("\(indent)tineye: \(feature.tinEyeResults.rawValue)")
                lines.append("\(indent)ai check: \(feature.aiCheckResults.rawValue)")
                lines.append("")

                if isPicked {
                    let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
                    let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
                    let fullPersonalMessage = personalMessageTemplate
                        .replacingOccurrences(of: "%%PAGENAME%%", with: loadedPage!.displayName)
                        .replacingOccurrences(of: "%%HUBNAME%%", with: loadedPage!.hub)
                        .replacingOccurrences(of: "%%USERNAME%%", with: feature.userName)
                        .replacingOccurrences(of: "%%USERALIAS%%", with: feature.userAlias)
                        .replacingOccurrences(of: "%%PERSONALMESSAGE%%", with: personalMessage)
                    personalLines.append(fullPersonalMessage)
                }
            }
        } else {
            lines.append("Picks for #\(loadedPage!.displayName)")
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
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                default:
                    lines.append("\(indent)hashtag = other")
                    break;
                }
                lines.append("\(indent)tineye - \(feature.tinEyeResults.rawValue)")
                lines.append("\(indent)ai check - \(feature.aiCheckResults.rawValue)")
                lines.append("")

                if isPicked {
                    let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
                    let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
                    let fullPersonalMessage = personalMessageTemplate
                        .replacingOccurrences(of: "%%PAGENAME%%", with: loadedPage!.displayName)
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

    private func copyReportToClipboard() {
        let text = generateReport()
        copyToClipboard(text)
        showToast(
            .complete(.green),
            "Report generated!",
            subTitle: "Copied the report of features to the clipboard",
            duration: 2)
    }
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

#Preview {
    @State var checkingForUpdates = false
    @State var isShowingVersionAvailableToast = false
    @State var isShowingVersionRequiredToast = false
    @State var versionCheckToast = VersionCheckToast()

    var localAppState = VersionCheckAppState(
        isCheckingForUpdates: $checkingForUpdates,
        isShowingVersionAvailableToast: $isShowingVersionAvailableToast,
        isShowingVersionRequiredToast: $isShowingVersionRequiredToast,
        versionCheckToast: $versionCheckToast,
        versionLocation: "https://vero.andydragon.com/static/data/trackingtags/version.json")
    localAppState.isPreviewMode = true

    return ContentView(localAppState)
}

struct DocumentDirtySheet: View {
    @Binding var isShowing: Bool
    @Binding var confirmationText: String
    var saveAction: () -> Void
    var dismissAction: () -> Void
    var cancelAction: () -> Void

    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.black, Color.yellow)
                    .font(.largeTitle)
                Spacer()
                    .frame(width: 16)
                Text("The log file has been edited and not saved")
                    .font(.title)
                Spacer()
            }
            Spacer()
                .frame(height: 16)
            Text(confirmationText)
            Spacer()
                .frame(height: 16)
            HStack(alignment: .bottom) {
                Spacer()
                Button("Yes", action: {
                    isShowing.toggle()
                    saveAction()
                })
                Spacer()
                    .frame(width: 8)
                Button("No", role: .destructive, action: {
                    isShowing.toggle()
                    dismissAction()
                })
                Spacer()
                    .frame(width: 8)
                Button("Cancel", role: .cancel, action: {
                    isShowing.toggle()
                    cancelAction()
                })
                Spacer()
            }
        }
        .padding(24)
    }
}

struct FeatureListRow: View {
    // SHARED FEATURE
    @AppStorage(
        "feature",
        store: UserDefaults(suiteName: "group.com.andydragon.VeroTools")
    ) var sharedFeature = ""

    @ObservedObject var feature: Feature
    var loadedPage: LoadedPage
    var markDocumentDirty: () -> Void
    var ensureSelected: () -> Void
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void

    @State var userName = ""
    @State var userAlias = ""
    @State var featureDescription = ""
    @State var postLink = ""
    @State var showingMessageEditor = false

    @AppStorage(
        "preference_personalMessage",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFormat = "🎉💫 Congratulations on your @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"
    @AppStorage(
        "preference_personalMessageFirst",
        store: UserDefaults(suiteName: "com.andydragon.com.Feature-Logging")
    ) var personalMessageFirstFormat = "🎉💫 Congratulations on your first @%%PAGENAME%% feature %%USERNAME%% @%%USERALIAS%%! %%PERSONALMESSAGE%% 💫🎉"

    var body: some View {
        HStack(alignment: .center) {
            if feature.photoFeaturedOnPage {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Photo is already featured on this page")
            } else if feature.tooSoonToFeatureUser {
                Image(systemName: "stopwatch.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Too soon to feature this user")
            } else if feature.tinEyeResults == .matchFound {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("TinEye matches found, possibly stolen photo")
            } else if feature.aiCheckResults == .ai {
                Image(systemName: "gear.badge.xmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("AI check verdict is image is AI generated")
            } else if feature.isPicked {
                Image(systemName: "star.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Photo is picked for feature")
            } else {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .opacity(0.0000001)
            }

            VStack {
                HStack {
                    Text("Feature: ")

                    if !userName.isEmpty {
                        Text(userName)
                    } else {
                        Text("user name")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }

                    Text(" | ")

                    if !userAlias.isEmpty {
                        Text("@\(userAlias)")
                    } else {
                        Text("user alias")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }

                    Text(" | ")

                    if !featureDescription.isEmpty {
                        Text(featureDescription)
                    } else {
                        Text("description")
                            .foregroundStyle(.gray, .secondary)
                            .italic()
                    }

                    Spacer()

                    if feature.isPickedAndAllowed {
                        Button(action: {
                            ensureSelected()
                            showingMessageEditor.toggle()
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "square.and.pencil.circle")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Edit personal message")
                            }
                        }
                        .disabled(!feature.isPickedAndAllowed)

                        Spacer()
                            .frame(width: 8)

                        Button(action: {
                            ensureSelected()
                            launchVeroScripts()
                        }) {
                            HStack(alignment: .center) {
                                Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                Text("Open Vero Scripts")
                            }
                        }
                    }
                }
                HStack {
                    Text(postLink)
                        .font(.footnote)

                    Spacer()
                }
            }
            .sheet(isPresented: $showingMessageEditor, content: {
                ZStack {
                    Color.BackgroundColor.edgesIgnoringSafeArea(.all)

                    VStack(alignment: .leading)  {
                        Text("Person message for feature: \(feature.userName) - \(feature.featureDescription)")

                        Spacer()
                            .frame(height: 8)

                        HStack(alignment: .center) {
                            Text("Personal message (from your account): ")
                            TextField("", text: $feature.personalMessage.onChange { value in
                                markDocumentDirty()
                            })
                            .focusable()
                            .autocorrectionDisabled(false)
                            .textFieldStyle(.plain)
                            .padding(4)
                            .background(Color.BackgroundColorEditor)
                            .border(Color.gray.opacity(0.25))
                            .cornerRadius(4)
                        }

                        Spacer()

                        HStack(alignment: .center)  {
                            Spacer()

                            Button(action: {
                                let personalMessage = feature.personalMessage.isEmpty ? "[PERSONAL MESSAGE]" : feature.personalMessage
                                let personalMessageTemplate = feature.userHasFeaturesOnPage ? personalMessageFormat : personalMessageFirstFormat
                                let fullPersonalMessage = personalMessageTemplate
                                    .replacingOccurrences(of: "%%PAGENAME%%", with: loadedPage.displayName)
                                    .replacingOccurrences(of: "%%HUBNAME%%", with: loadedPage.hub == "other" ? "" : loadedPage.hub)
                                    .replacingOccurrences(of: "%%USERNAME%%", with: feature.userName)
                                    .replacingOccurrences(of: "%%USERALIAS%%", with: feature.userAlias)
                                    .replacingOccurrences(of: "%%PERSONALMESSAGE%%", with: personalMessage)
                                copyToClipboard(fullPersonalMessage)
                                showingMessageEditor.toggle()
                                showToast(.complete(.green), "Copied to clipboard", "The personal message was copied to the clipboard", 2) { }
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "pencil.and.list.clipboard")
                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                    Text("Copy full text")
                                }
                            }

                            Button(action: {
                                showingMessageEditor.toggle()
                            }) {
                                HStack(alignment: .center) {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                                    Text("Close")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
                .frame(width: 800, height: 160)
            })
        }
        .onChange(of: feature, initial: true) {
            userName = feature.userName
            userAlias = feature.userAlias
            featureDescription = feature.featureDescription
            postLink = feature.postLink
        }
        .onChange(of: feature.userName) {
            userName = feature.userName
        }
        .onChange(of: feature.userAlias) {
            userAlias = feature.userAlias
        }
        .onChange(of: feature.featureDescription) {
            featureDescription = feature.featureDescription
        }
        .onChange(of: feature.postLink) {
            postLink = feature.postLink
        }
    }

    private func launchVeroScripts() {
        if feature.photoFeaturedOnPage {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "That photo has already been featured on this page", 0) { }
            return
        }
        if feature.tinEyeResults == .matchFound {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "This photo had a TinEye match", 0) { }
            return
        }
        if feature.aiCheckResults == .ai {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "This photo was flagged as AI", 0) { }
            return
        }
        if feature.tooSoonToFeatureUser {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "The user has been featured too recently", 0) { }
            return
        }
        if !feature.isPicked {
            showToast(.systemImage("exclamationmark.triangle.fill", .yellow), "Should not feature photo", "The photo is not marked as picked, mark the photo as picked and try again", 0) { }
            return
        }
        do {
            // Encode the feature for Vero Scripts and copy to the clipboard
            let encoder = JSONEncoder()
            let json = try encoder.encode(CodableFeature(using: loadedPage, from: feature))
            let jsonString = String(decoding: json, as: UTF8.self)
            copyToClipboard(jsonString)

            // Store the feature in the shared storage
            sharedFeature = jsonString

            // Launch the Vero Scripts app
            guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.andydragon.Vero-Scripts") else { return }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.promptsUserIfNeeded = true
            configuration.arguments = []
            NSWorkspace.shared.openApplication(at: url, configuration: configuration)

            showToast(.complete(.green), "Launched Vero Scripts", "The feature was copied to the clipboard", 2) { }
        } catch {
            debugPrint(error)
        }
    }
}
