//
//  ContentView.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import AlertToast

struct ContentView: View {
    @AppStorage(
        Constants.THEME_APP_STORE_KEY,
        store: UserDefaults(suiteName: "com.andydragon.com.Post-Maker")
    ) var theme = Theme.notSet
    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    @State private var isDarkModeOn = true

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
    @State private var users = [FeatureUser]()
    @State private var selectedUser: FeatureUser? = nil
    private var appState: VersionCheckAppState
    private var isAnyToastShowing: Bool {
        isShowingToast ||
        appState.isShowingVersionAvailableToast.wrappedValue ||
        appState.isShowingVersionRequiredToast.wrappedValue
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
                        selectedUser = nil
                        users = [FeatureUser]()
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
                }
                
                VStack {
                    if let currentUser = selectedUser {
                        FeatureEditor(user: currentUser, loadedPage: loadedPage)
                    } else {
                        Spacer()
                    }
                }
                .frame(height: 360)

                HStack {
                    Spacer()
                    
                    Button(action: {
                        let user = FeatureUser()
                        let linkText = pasteFromClipboard().trimmingCharacters(in: .whitespacesAndNewlines)
                        if linkText.starts(with: "https://vero.co/") {
                            user.postLink = linkText
                            user.userAlias = String(linkText.dropFirst(16).split(separator: "/").first ?? "")
                        }
                        users.append(user)
                        selectedUser = user
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.plus")
                            Text("Add feature")
                        }
                    }
                    .disabled(isAnyToastShowing)

                    Spacer()
                        .frame(width: 16)
                    
                    Button(action: {
                        if let currentUser = selectedUser {
                            selectedUser = nil
                            users.removeAll(where: { $0.id == currentUser.id })
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "person.fill.badge.minus")
                            Text("Remove feature")
                        }
                    }
                    .disabled(isAnyToastShowing || selectedUser == nil)

                    Spacer()
                        .frame(width: 16)
                    
                    Button(action: {
                        selectedUser = nil
                        users = [FeatureUser]()
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "trash")
                            Text("Remove all")
                        }
                    }
                    .disabled(isAnyToastShowing || selectedUser == nil)
                }
                ScrollViewReader { proxy in
                    List {
                        ForEach(users, id: \.self) { user in
                            FeatureUserRow(user: user, loadedPage: loadedPage!)
                            .padding([.top, .bottom], 8)
                            .padding([.leading, .trailing])
                            .foregroundStyle(Color(nsColor: overUser == user 
                                                   ? NSColor.selectedControlTextColor
                                                   : NSColor.labelColor), Color(nsColor: .labelColor))
                            .background(overUser == user
                                        ? Color.BackgroundColorListHover
                                        : selectedUser == user
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
                                    selectedUser = user
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
                        selectedUser = nil
                    }
                }
                .focusable()
            }
            .toolbar {
                Button(action: {
                    generateReport()
                }) {
                    HStack {
                        Image(systemName: "pencil.and.list.clipboard")
                            .foregroundStyle(Color.TextColorPrimary, Color.TextColorSecondary)
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
        } else {
            if let details = ThemeDetails[newTheme] {
                Color.currentTheme = details.colorTheme
                isDarkModeOn = details.darkTheme
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration), execute: {
            if (isShowingToast) {
                isShowingToast.toggle()
            }
        })
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
    
    private func generateReport() {
        var lines = [String]()
        var personalLines = [String]()
        if loadedPage!.hub == "click" {
            lines.append("Picks for #\(loadedPage!.displayName) / #click_community / #click_hub")
            lines.append("")
            for featureUser in users.sorted(by: {
                let isFirstPicked = !$0.photoFeaturedOnPage &&
                    !$0.tooSoonToFeatureUser &&
                    $0.tinEyeResults != TinEyeResults.matchFound.rawValue &&
                    $0.aiCheckResults != AiCheckResults.ai.rawValue &&
                    $0.isPicked
                let isSecondPicked = !$1.photoFeaturedOnPage &&
                    !$1.tooSoonToFeatureUser &&
                    $1.tinEyeResults != TinEyeResults.matchFound.rawValue &&
                    $1.aiCheckResults != AiCheckResults.ai.rawValue &&
                    $1.isPicked

                if !isFirstPicked && !isSecondPicked {
                    return $0.userName < $1.userName
                }
                
                if !isSecondPicked {
                    return true
                }
                
                if !isFirstPicked {
                    return false
                }
                
                return $0.userName < $1.userName
            }) {
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
                } else if featureUser.tinEyeResults == TinEyeResults.matchFound.rawValue {
                    prefix = "[tineye match] "
                    indent = "    "
                } else if featureUser.aiCheckResults == AiCheckResults.ai.rawValue {
                    prefix = "[AI] "
                    indent = "    "
                } else if !featureUser.isPicked {
                    prefix = "[not picked] "
                    indent = "    "
                }
                lines.append("\(indent)\(prefix)\(featureUser.postLink)")
                lines.append("\(indent)user - \(featureUser.userName) @\(featureUser.userAlias)")
                lines.append("\(indent)member level - \(featureUser.userLevel)")
                if featureUser.userHasFeaturesOnPage {
                    lines.append("\(indent)last feature on page - \(featureUser.lastFeaturedOnPage) (features on page \(featureUser.featureCountOnPage))")
                } else {
                    lines.append("\(indent)last feature on page - never (features on page 0)")
                }
                lines.append("\(indent)feature - \(featureUser.featureDescription), featured - \(featureUser.photoFeaturedOnPage ? "YES" : "no")")
                lines.append("\(indent)teammate - \(featureUser.userIsTeammate ? "yes" : "no")")
                switch TagSourceCases(rawValue: featureUser.tagSource) ?? TagSourceCases.commonPageTag {
                case TagSourceCases.commonPageTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                case TagSourceCases.clickCommunityTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_community")
                    break;
                case TagSourceCases.clickHubTag:
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
            for featureUser in users.sorted(by: {
                let isFirstPicked = !$0.photoFeaturedOnPage &&
                    !$0.tooSoonToFeatureUser &&
                    $0.tinEyeResults != TinEyeResults.matchFound.rawValue &&
                    $0.aiCheckResults != AiCheckResults.ai.rawValue &&
                    $0.isPicked
               let isSecondPicked = !$1.photoFeaturedOnPage &&
                    !$1.tooSoonToFeatureUser &&
                    $1.tinEyeResults != TinEyeResults.matchFound.rawValue &&
                    $1.aiCheckResults != AiCheckResults.ai.rawValue &&
                    $1.isPicked

                if !isFirstPicked && !isSecondPicked {
                    return $0.userName < $1.userName
                }
                
                if !isSecondPicked {
                    return true
                }
                
                if !isFirstPicked {
                    return false
                }
                
                return $0.userName < $1.userName
            }) {
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
                } else if featureUser.tinEyeResults == TinEyeResults.matchFound.rawValue {
                    prefix = "[tineye match] "
                    indent = "    "
                } else if featureUser.aiCheckResults == AiCheckResults.ai.rawValue {
                    prefix = "[AI] "
                    indent = "    "
                } else if !featureUser.isPicked {
                    prefix = "[not picked] "
                    indent = "    "
                }
                lines.append("\(indent)\(prefix)\(featureUser.postLink)")
                lines.append("\(indent)user - \(featureUser.userName) @\(featureUser.userAlias)")
                lines.append("\(indent)member level - \(featureUser.userLevel)")
                if featureUser.userHasFeaturesOnHub {
                    lines.append("\(indent)last feature - \(featureUser.lastFeaturedOnHub) \(featureUser.lastFeaturedPage) (features \(featureUser.featureCountOnSnap) Snap + \(featureUser.featureCountOnRaw) RAW)")
                } else {
                    lines.append("\(indent)last feature - never (features 0 Snap + 0 RAW)")
                }
                if featureUser.userHasFeaturesOnPage {
                    lines.append("\(indent)last feature on page - \(featureUser.lastFeaturedOnPage) (features on page \(featureUser.featureCountOnPage) Snap + \(featureUser.featureCountOnRawPage) RAW)")
                } else {
                    lines.append("\(indent)last feature on page - never (features on page 0 Snap + 0 RAW)")
                }
                lines.append("\(indent)feature - \(featureUser.featureDescription), featured - \(featureUser.photoFeaturedOnPage ? "YES" : "no")")
                lines.append("\(indent)teammate - \(featureUser.userIsTeammate ? "yes" : "no")")
                switch TagSourceCases(rawValue: featureUser.tagSource) ?? TagSourceCases.commonPageTag {
                case TagSourceCases.commonPageTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                case TagSourceCases.snapRawPageTag:
                    lines.append("\(indent)hashtag = #raw_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                case TagSourceCases.snapCommunityTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_community")
                    break;
                case TagSourceCases.snapRawCommunityTag:
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
            lines.append("Picks for #\(loadedPage!.displayName) / #click_community / #click_hub")
            lines.append("")
            for featureUser in users.sorted(by: {
                let isFirstPicked = !$0.photoFeaturedOnPage && 
                    !$0.tooSoonToFeatureUser &&
                    $0.tinEyeResults != TinEyeResults.matchFound.rawValue &&
                    $0.aiCheckResults != AiCheckResults.ai.rawValue && 
                    $0.isPicked
                let isSecondPicked = !$1.photoFeaturedOnPage && 
                    !$1.tooSoonToFeatureUser &&
                    $1.tinEyeResults != TinEyeResults.matchFound.rawValue &&
                    $1.aiCheckResults != AiCheckResults.ai.rawValue &&
                    $1.isPicked
                
                if !isFirstPicked && !isSecondPicked {
                    return $0.userName < $1.userName
                }
                
                if !isSecondPicked {
                    return true
                }
                
                if !isFirstPicked {
                    return false
                }
                
                return $0.userName < $1.userName
            }) {
                var indent = ""
                var prefix = ""
                if featureUser.photoFeaturedOnPage {
                    prefix = "[already featured] "
                    indent = "    "
                } else if featureUser.tooSoonToFeatureUser {
                    prefix = "[too soon] "
                    indent = "    "
                } else if featureUser.tinEyeResults == TinEyeResults.matchFound.rawValue {
                    prefix = "[tineye match] "
                    indent = "    "
                } else if featureUser.aiCheckResults == AiCheckResults.ai.rawValue {
                    prefix = "[AI] "
                    indent = "    "
                } else if !featureUser.isPicked {
                    prefix = "[not picked] "
                    indent = "    "
                }
                lines.append("\(indent)\(prefix)\(featureUser.postLink)")
                lines.append("\(indent)user - \(featureUser.userName) @\(featureUser.userAlias)")
                lines.append("\(indent)member level - \(featureUser.userLevel)")
                lines.append("\(indent)feature - \(featureUser.featureDescription), featured - \(featureUser.photoFeaturedOnPage ? "YES" : "no")")
                lines.append("\(indent)teammate - \(featureUser.userIsTeammate ? "yes" : "no")")
                switch TagSourceCases(rawValue: featureUser.tagSource) ?? TagSourceCases.commonPageTag {
                case TagSourceCases.commonPageTag:
                    lines.append("\(indent)hashtag = #\(loadedPage!.hub)_\(loadedPage!.pageName ?? loadedPage!.name)")
                    break;
                default:
                    lines.append("\(indent)hashtag = other")
                    break;
                }
                lines.append("\(indent)tineye - \(featureUser.tinEyeResults)")
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
    @ObservedObject var user: FeatureUser
    var loadedPage: LoadedPage
    @State var userName: String = ""
    @State var userAlias: String = ""
    @State var featureDescription: String = ""
    @State var postLink: String = ""
    
    var body: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
            if user.photoFeaturedOnPage {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
            } else if user.tooSoonToFeatureUser {
                Image(systemName: "stopwatch.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
            } else if user.tinEyeResults == TinEyeResults.matchFound.rawValue {
                Image(systemName: "eye.trianglebadge.exclamationmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
            } else if user.aiCheckResults == AiCheckResults.ai.rawValue {
                Image(systemName: "gear.badge.xmark")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
            } else if user.isPicked {
                Image(systemName: "star.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
                    .frame(width: 32, height: 32)
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
                        do {
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
                            let json = try encoder.encode(CodableFeatureUser(using: loadedPage, from: user))
                            copyToClipboard(String(decoding: json, as: UTF8.self))
                        } catch {
                            debugPrint(error)
                        }
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "pencil.and.list.clipboard")
                            Text("Copy for Vero Scripts")
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
}
