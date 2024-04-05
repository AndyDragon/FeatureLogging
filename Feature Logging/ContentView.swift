//
//  ContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import AlertToast

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
    
    @EnvironmentObject var commandModel: AppCommandModel

    @Environment(\.openURL) private var openURL
    @State private var page: String = UserDefaults.standard.string(forKey: "Page") ?? ""
    @State private var toastType: AlertToast.AlertType = .regular
    @State private var toastText = ""
    @State private var toastSubTitle = ""
    @State private var toastDuration = 3.0
    @State private var toastTapAction: () -> Void = {}
    @State private var isShowingToast = false
    @State private var overUser: FeatureUser? = nil
    @State private var loadedPages = [LoadedPage]()
    private var loadedPage: LoadedPage? {
        loadedPages.first(where: { $0.id == page })
    }
    @State private var featureUsersViewModel = FeatureUsersViewModel()
    @State private var sortedFeatures = [FeatureUser]()
    @State private var selectedFeature: FeatureUser? = nil
    @State private var showFileImporter = false
    @State private var showFileExporter = false
    @State private var logDocument = LogDocument()
    @State private var logURL: URL? = nil
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
                        .frame(width: 80, alignment: .trailing)
                    Picker("", selection: $page.onChange { value in
                        UserDefaults.standard.set(page, forKey: "Page")
                        logURL = nil
                        selectedFeature = nil
                        featureUsersViewModel = FeatureUsersViewModel()
                        sortedFeatures = featureUsersViewModel.sortedFeatures
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
                    Menu("Copy tag", systemImage: "tag.fill") {
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(loadedPage?.hub ?? "")_\(loadedPage?.pageName ?? loadedPage?.name ?? "")")
                            showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the page tag to the clipboard", duration: 3) { }
                        }) {
                            Text("Page tag")
                        }
                        if loadedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_\(loadedPage?.pageName ?? loadedPage?.name ?? "")")
                                showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the RAW page tag to the clipboard", duration: 3) { }
                            }) {
                                Text("RAW page tag")
                            }
                        }
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(loadedPage?.hub ?? "")_community")
                            showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the community tag to the clipboard", duration: 3) { }
                        }) {
                            Text("Community tag")
                        }
                        if loadedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_community")
                                showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the RAW community tag to the clipboard", duration: 3) { }
                            }) {
                                Text("RAW community tag")
                            }
                        }
                        Button(action: {
                            copyToClipboard("\(includeHash ? "#" : "")\(loadedPage?.hub ?? "")_hub")
                            showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the hub tag to the clipboard", duration: 3) { }
                        }) {
                            Text("Hub tag")
                        }
                        if loadedPage?.hub == "snap" {
                            Button(action: {
                                copyToClipboard("\(includeHash ? "#" : "")raw_hub")
                                showToast(.complete(.green), "Copied to clipboard", subTitle: "Copied the RAW hub tag to the clipboard", duration: 3) { }
                            }) {
                                Text("RAW hub tag")
                            }
                        }
                    }
                    .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                    .disabled(isAnyToastShowing || (loadedPage?.hub != "click" && loadedPage?.hub != "snap"))
                    .frame(maxWidth: 132)
                    .focusable()
                }
                
                VStack {
                    if let currentUser = selectedFeature {
                        FeatureEditor(user: currentUser, loadedPage: loadedPage, close: {
                            selectedFeature = nil
                        }, updateList: {
                            sortedFeatures = featureUsersViewModel.sortedFeatures
                        }, showToast: showToast)
                    } else {
                        Spacer()
                    }
                }
                .frame(height: 370)

                HStack {
                    Spacer()
                    
                    Button(action: {
                        let user = FeatureUser()
                        let linkText = pasteFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                        if linkText.starts(with: "https://vero.co/") {
                            user.postLink = linkText
                            user.userAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
                        }
                        featureUsersViewModel.features.append(user)
                        sortedFeatures = featureUsersViewModel.sortedFeatures
                        selectedFeature = user
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundStyle(Color.AccentColor, Color.TextColorSecondary)
                            Text("Add feature")
                        }
                    }
                    .disabled(isAnyToastShowing)

                    Spacer()
                        .frame(width: 16)
                    
                    Button(action: {
                        if let currentUser = selectedFeature {
                            selectedFeature = nil
                            featureUsersViewModel.features.removeAll(where: { $0.id == currentUser.id })
                            sortedFeatures = featureUsersViewModel.sortedFeatures
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.minus")
                                .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                            Text("Remove feature")
                                //.foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                        }
                    }
                    .disabled(isAnyToastShowing || selectedFeature == nil)

                    Spacer()
                        .frame(width: 16)
                    
                    Button(action: {
                        selectedFeature = nil
                        featureUsersViewModel = FeatureUsersViewModel()
                        sortedFeatures = featureUsersViewModel.sortedFeatures
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                            Text("Remove all")
                                //.foregroundStyle(Color.TextColorRequired, Color.TextColorSecondary)
                        }
                    }
                    .disabled(isAnyToastShowing || featureUsersViewModel.features.isEmpty)
                }
                ScrollViewReader { proxy in
                    List {
                        ForEach(sortedFeatures, id: \.self) { user in
                            FeatureUserRow(user: user, loadedPage: loadedPage!, showToast: showToast)
                            .padding([.top, .bottom], 8)
                            .padding([.leading, .trailing])
                            .foregroundStyle(Color(nsColor: overUser == user 
                                                   ? NSColor.selectedControlTextColor
                                                   : NSColor.labelColor), Color(nsColor: .labelColor))
                            .background(overUser == user
                                        ? Color.BackgroundColorListHover
                                        : selectedFeature == user
                                        ? Color.BackgroundColorListSelected
                                        : Color.BackgroundColorList)
                            .cornerRadius(4)
                            .onHover(perform: { hovering in
                                if overUser == user {
                                    if !hovering {
                                        overUser = nil
                                    }
                                } else if hovering {
                                    overUser = user
                                }
                            })
                            .onTapGesture {
                                withAnimation {
                                    selectedFeature = user
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(4)
                    .presentationBackground(.clear)
                }
                .scrollContentBackground(.hidden)
                .background(Color.BackgroundColorList)
                .border(Color.gray.opacity(0.25))
                .cornerRadius(4)
                .onTapGesture {
                    withAnimation {
                        selectedFeature = nil
                    }
                }
                .focusable()
            }
            .toolbar {
                Button(action: {
                    showFileImporter.toggle()
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
                    case .failure(let error):
                        print(error)
                    }
                }
                .disabled(isAnyToastShowing || loadedPage == nil)

                Button(action: {
                    logDocument = LogDocument(page: loadedPage!, featureUsers: featureUsersViewModel.features)
                    if let file = logURL {
                        saveLog(to: file)
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
                    case .failure(let error):
                        debugPrint(error)
                    }
                }
                .disabled(isAnyToastShowing || loadedPage == nil)

                Button(action: {
                    generateReport()
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
            featureUsersViewModel = FeatureUsersViewModel()
            sortedFeatures = featureUsersViewModel.sortedFeatures
        }
        .onChange(of: commandModel.openLog) {
            showFileImporter.toggle()
        }
        .onChange(of: commandModel.saveLog) {
            logDocument = LogDocument(page: loadedPage!, featureUsers: featureUsersViewModel.features)
            if let file = logURL {
                saveLog(to: file)
            } else {
                showFileExporter.toggle()
            }
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
        })
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
        withAnimation {
            toastType = type
            toastText = text
            toastSubTitle = subTitle
            toastTapAction = onTap
            isShowingToast.toggle()
        }
        
        if duration != 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration), execute: {
                if (isShowingToast) {
                    isShowingToast.toggle()
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
            let jsonString = String(String(decoding: json, as: UTF8.self)).replacingOccurrences(of: "\\/\\/.*", with: "", options: .regularExpression)
            do {
                let decoder = JSONDecoder()
                let loadedLog = try decoder.decode(Log.self, from: jsonString.data(using: .utf8)!)
                if let loadedPage = loadedPages.first(where: { $0.id == loadedLog.page }) {
                    page = loadedPage.id
                    featureUsersViewModel.features = loadedLog.getFeatureUsers()
                    sortedFeatures = featureUsersViewModel.sortedFeatures
                }
                logURL = file
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
            let jsonData = Data(logDocument.text.utf8)
            try jsonData.write(to: file)
        } catch {
            debugPrint(error)
        }

        file.stopAccessingSecurityScopedResource()
    }
    
    private func generateReport() {
        var lines = [String]()
        var personalLines = [String]()
        if loadedPage!.hub == "click" {
            lines.append("Picks for #\(loadedPage!.displayName) / #click_community / #click_hub")
            lines.append("")
            var wasLastItemPicked = true
            for featureUser in sortedFeatures {
                var isPicked = featureUser.isPicked
                var indent = ""
                var prefix = ""
                if featureUser.photoFeaturedOnPage {
                    prefix = "[already featured] "
                    indent = "    "
                    isPicked = false
                } else if featureUser.tooSoonToFeatureUser {
                    prefix = "[too soon] "
                    indent = "    "
                    isPicked = false
                } else if featureUser.tinEyeResults == .matchFound {
                    prefix = "[tineye match] "
                    indent = "    "
                } else if featureUser.aiCheckResults == .ai {
                    prefix = "[AI] "
                    indent = "    "
                } else if !featureUser.isPicked {
                    prefix = "[not picked] "
                    indent = "    "
                }
                if !isPicked && wasLastItemPicked {
                    lines.append("---------------")
                    lines.append("")
                }
                wasLastItemPicked = isPicked
                lines.append("\(indent)\(prefix)\(featureUser.postLink)")
                lines.append("\(indent)user - \(featureUser.userName) @\(featureUser.userAlias)")
                lines.append("\(indent)member level - \(featureUser.userLevel)")
                if featureUser.userHasFeaturesOnPage {
                    lines.append("\(indent)last feature on page - \(featureUser.lastFeaturedOnPage) (features on page \(featureUser.featureCountOnPage))")
                } else {
                    lines.append("\(indent)last feature on page - never (features on page 0)")
                }
                if featureUser.userHasFeaturesOnHub {
                    lines.append("\(indent)last feature - \(featureUser.lastFeaturedOnHub) \(featureUser.lastFeaturedPage) (features \(featureUser.featureCountOnHub))")
                } else {
                    lines.append("\(indent)last feature - never (features 0)")
                }
                lines.append("\(indent)feature - \(featureUser.featureDescription), featured - \(featureUser.photoFeaturedOnPage ? "YES" : "no")")
                lines.append("\(indent)teammate - \(featureUser.userIsTeammate ? "yes" : "no")")
                switch featureUser.tagSource {
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
                lines.append("\(indent)tineye: \(featureUser.tinEyeResults)")
                lines.append("\(indent)ai check: \(featureUser.aiCheckResults)")
                lines.append("")
                
                if isPicked {
                    if featureUser.userHasFeaturesOnPage {
                        personalLines.append("🎉💫 Congratulations on your @\(loadedPage!.displayName) feature \(featureUser.userName) @\(featureUser.userAlias), [PERSONALIZED MESSAGE]")
                    } else {
                        personalLines.append("🎉💫 Congratulations on your first @\(loadedPage!.displayName) feature \(featureUser.userName) @\(featureUser.userAlias), [PERSONALIZED MESSAGE]")
                    }
                }
            }
        } else if loadedPage!.hub == "snap" {
            lines.append("Picks for #\(loadedPage!.displayName)")
            lines.append("")
            var wasLastItemPicked = true
            for featureUser in sortedFeatures {
                var isPicked = featureUser.isPicked
                var indent = ""
                var prefix = ""
                if featureUser.photoFeaturedOnPage {
                    prefix = "[already featured] "
                    indent = "    "
                    isPicked = false
                } else if featureUser.tooSoonToFeatureUser {
                    prefix = "[too soon] "
                    indent = "    "
                    isPicked = false
                } else if featureUser.tinEyeResults == .matchFound {
                    prefix = "[tineye match] "
                    indent = "    "
                } else if featureUser.aiCheckResults == .ai {
                    prefix = "[AI] "
                    indent = "    "
                } else if !featureUser.isPicked {
                    prefix = "[not picked] "
                    indent = "    "
                }
                if !isPicked && wasLastItemPicked {
                    lines.append("---------------")
                    lines.append("")
                }
                wasLastItemPicked = isPicked
                lines.append("\(indent)\(prefix)\(featureUser.postLink)")
                lines.append("\(indent)user - \(featureUser.userName) @\(featureUser.userAlias)")
                lines.append("\(indent)member level - \(featureUser.userLevel)")
                if featureUser.userHasFeaturesOnPage {
                    lines.append("\(indent)last feature on page - \(featureUser.lastFeaturedOnPage) (features on page \(featureUser.featureCountOnPage) Snap + \(featureUser.featureCountOnRawPage) RAW)")
                } else {
                    lines.append("\(indent)last feature on page - never (features on page 0 Snap + 0 RAW)")
                }
                if featureUser.userHasFeaturesOnHub {
                    lines.append("\(indent)last feature - \(featureUser.lastFeaturedOnHub) \(featureUser.lastFeaturedPage) (features \(featureUser.featureCountOnHub) Snap + \(featureUser.featureCountOnRawHub) RAW)")
                } else {
                    lines.append("\(indent)last feature - never (features 0 Snap + 0 RAW)")
                }
                lines.append("\(indent)feature - \(featureUser.featureDescription), featured - \(featureUser.photoFeaturedOnPage ? "YES" : "no")")
                lines.append("\(indent)teammate - \(featureUser.userIsTeammate ? "yes" : "no")")
                switch featureUser.tagSource {
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
                lines.append("\(indent)tineye: \(featureUser.tinEyeResults)")
                lines.append("\(indent)ai check: \(featureUser.aiCheckResults)")
                lines.append("")

                if isPicked {
                    if featureUser.userHasFeaturesOnPage {
                        personalLines.append("🎉💫 Congratulations on this feature \(featureUser.userName) @\(featureUser.userAlias), [PERSONALIZED MESSAGE]")
                    } else {
                        personalLines.append("🎉💫 Congratulations on your first @\(loadedPage!.displayName) feature \(featureUser.userName) @\(featureUser.userAlias), [PERSONALIZED MESSAGE]")
                    }
                }
            }
        } else {
            lines.append("Picks for #\(loadedPage!.displayName)")
            lines.append("")
            var wasLastItemPicked = true
            for featureUser in sortedFeatures {
                var isPicked = featureUser.isPicked
                var indent = ""
                var prefix = ""
                if featureUser.photoFeaturedOnPage {
                    prefix = "[already featured] "
                    indent = "    "
                    isPicked = false
                } else if featureUser.tooSoonToFeatureUser {
                    prefix = "[too soon] "
                    indent = "    "
                    isPicked = false
                } else if featureUser.tinEyeResults == .matchFound {
                    prefix = "[tineye match] "
                    indent = "    "
                    isPicked = false
                } else if featureUser.aiCheckResults == .ai {
                    prefix = "[AI] "
                    indent = "    "
                    isPicked = false
                } else if !featureUser.isPicked {
                    prefix = "[not picked] "
                    indent = "    "
                    isPicked = false
                }
                if !isPicked && wasLastItemPicked {
                    lines.append("---------------")
                    lines.append("")
                }
                wasLastItemPicked = isPicked
                lines.append("\(indent)\(prefix)\(featureUser.postLink)")
                lines.append("\(indent)user - \(featureUser.userName) @\(featureUser.userAlias)")
                lines.append("\(indent)member level - \(featureUser.userLevel)")
                lines.append("\(indent)feature - \(featureUser.featureDescription), featured - \(featureUser.photoFeaturedOnPage ? "YES" : "no")")
                lines.append("\(indent)teammate - \(featureUser.userIsTeammate ? "yes" : "no")")
                switch featureUser.tagSource {
                case .commonPageTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                default:
                    lines.append("\(indent)hashtag = other")
                    break;
                }
                lines.append("\(indent)tineye - \(featureUser.tinEyeResults)")
                lines.append("\(indent)ai check - \(featureUser.aiCheckResults)")
                lines.append("")
            }
        }
        var text = ""
        for line in lines { text = text + line + "\n" }
        text = text + "---------------\n\n"
        if !personalLines.isEmpty {
            for line in personalLines { text = text + line + "\n" }
            text = text + "\n---------------\n"
        }
        copyToClipboard(text)
        showToast(.complete(.green), "Report generated!", subTitle: "Copied the report of features to the clipboard")
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

struct FeatureUserRow: View {
    // SHARED FEATURE
    @AppStorage(
        "feature",
        store: UserDefaults(suiteName: "group.com.andydragon.VeroTools")
    ) var sharedFeature = ""

    @ObservedObject var user: FeatureUser
    var loadedPage: LoadedPage
    var showToast: (_ type: AlertToast.AlertType, _ text: String, _ subTitle: String, _ duration: Int, _ onTap: @escaping () -> Void) -> Void
    @State var userName: String = ""
    @State var userAlias: String = ""
    @State var featureDescription: String = ""
    @State var postLink: String = ""
    
    var body: some View {
        HStack(alignment: .center) {
            if user.photoFeaturedOnPage {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Photo is already featured on this page")
            } else if user.tooSoonToFeatureUser {
                Image(systemName: "stopwatch.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("Too soon to feature this user")
            } else if user.tinEyeResults == .matchFound {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("TinEye matches found, possibly stolen photo")
            } else if user.aiCheckResults == .ai {
                Image(systemName: "gear.badge.xmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
                    .help("AI check verdict is image is AI generated")
            } else if user.isPicked {
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
                    
                    Button(action: {
                        launchVeroScripts()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                            Text("Open Vero Scripts")
                        }
                    }
                }
                HStack {
                    Text(postLink)
                        .font(.footnote)
                    
                    Spacer()
                }
            }
        }
        .onChange(of: user, initial: true) {
            userName = user.userName
            userAlias = user.userAlias
            featureDescription = user.featureDescription
            postLink = user.postLink
        }
        .onChange(of: user.userName) {
            userName = user.userName
        }
        .onChange(of: user.userAlias) {
            userAlias = user.userAlias
        }
        .onChange(of: user.featureDescription) {
            featureDescription = user.featureDescription
        }
        .onChange(of: user.postLink) {
            postLink = user.postLink
        }
    }
    
    private func launchVeroScripts() {
        if user.photoFeaturedOnPage {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "That photo has already been featured on this page", 0) { }
            return
        }
        if user.tinEyeResults == .matchFound {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "This photo had a TinEye match", 0) { }
            return
        }
        if user.aiCheckResults == .ai {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "This photo was flagged as AI", 0) { }
            return
        }
        if user.tooSoonToFeatureUser {
            showToast(.systemImage("exclamationmark.octagon.fill", .red), "Cannot feature photo", "The user has been featured too recently", 0) { }
            return
        }
        if !user.isPicked {
            showToast(.systemImage("exclamationmark.triangle.fill", .yellow), "Should not feature photo", "The photo is not marked as picked, mark the photo as picked and try again", 0) { }
            return
        }
        do {
            // Encode the feature for Vero Scripts and copy to the clipboard
            let encoder = JSONEncoder()
            let json = try encoder.encode(CodableFeatureUser(using: loadedPage, from: user))
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
            
            showToast(.complete(.green), "Launched Vero Scripts", "The feature was copied to the clipboard", 3) { }
        } catch {
            debugPrint(error)
        }
    }
}
