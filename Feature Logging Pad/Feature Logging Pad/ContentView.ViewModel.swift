//
//  ContentView.ViewModel.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-12-17.
//

import SwiftUI
import SwiftyBeaver

extension View {
    func attachVersionCheckState(_ viewModel: ContentView.ViewModel, _ appState: VersionCheckAppState, _ launchUrl: @escaping (_ url: URL) -> Void) -> some View {
        self.onChange(of: appState.versionCheckResult.wrappedValue) {
            viewModel.handleVersionCheck(appState) { url in
                launchUrl(url)
            }
        }
    }
}

extension ContentView {
    enum VisibleView {
        case FeatureListView
        case FeatureEditorView
        case PostDownloadView
        case ImageValidationView
        case ScriptView
        case StatisticsView
    }

    @Observable
    class ViewModel {
        init() {}

        private let logger = SwiftyBeaver.self
        
        // MARK: Visible view
        var visibleView: VisibleView = .FeatureListView

        // MARK: Catalog and Features
        var loadedCatalogs = LoadedCatalogs()
        var selectedPage: ObservablePage?
        var selectedPageStaffLevel: StaffLevelCase = .mod
        var features = [ObservableFeature]()
        var selectedFeature: ObservableFeatureWrapper?
        var sortedFeatures: [ObservableFeature] {
            return features.sorted(by: compareFeatures)
        }
        var pickedFeatures: [ObservableFeature] {
            return sortedFeatures.filter({ $0.isPicked })
        }
        var yourName = UserDefaults.standard.string(forKey: "YourName") ?? ""
        var yourFirstName = UserDefaults.standard.string(forKey: "YourFirstName") ?? ""
        private(set) var isDirty = false
        var isShowingDocumentDirtyAlert = false

        // MARK: Document
        func markDocumentDirty() {
            if !isDirty {
                isDirty = true
            }
        }

        func clearDocumentDirty() {
            if isDirty {
                isDirty = false
            }
        }

        // MARK: Version check
        private var lastVersionCheckResult = VersionCheckResult.complete

        func handleVersionCheck(
            _ appState: VersionCheckAppState,
            _ launchURL: @escaping (_ url: URL) -> Void
        ) {
            if appState.versionCheckResult.wrappedValue == lastVersionCheckResult {
                return;
            }
            lastVersionCheckResult = appState.versionCheckResult.wrappedValue
            switch appState.versionCheckResult.wrappedValue {
            case .newAvailable:
                logger.info("New version of the application is available", context: "Version")
                dismissAllNonBlockingToasts()
                showToast(
                    .alert,
                    "New version available",
                    String {
                        "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) "
                        "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is available"
                        "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click Download to open your browser") "
                        "(this will go away in \(AdvancedToastStyle.alert.duration) seconds)"
                    },
                    width: 720,
                    buttonTitle: "Download",
                    onButtonTapped: {
                        if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                            self.logger.verbose("Launching browser to get new application version", context: "User")
                            launchURL(url)
                            let terminationTask = DispatchWorkItem {
#if os(macOS)
                                NSApplication.shared.terminate(nil)
#else
                                // TODO andydragon
#endif
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: terminationTask)
                        }
                    },
                    onDismissed: {
                        self.logger.verbose("New version of the application ignored", context: "User")
                        appState.resetCheckingForUpdates()
                    }
                )
                break
            case .newRequired:
                logger.info("New version of the application is required", context: "Version")
                dismissAllNonBlockingToasts()
                showToast(
                    .fatal,
                    "New version required",
                    String {
                        "You are using v\(appState.versionCheckToast.wrappedValue.appVersion) "
                        "and v\(appState.versionCheckToast.wrappedValue.currentVersion) is required"
                        "\(appState.versionCheckToast.wrappedValue.linkToCurrentVersion.isEmpty ? "" : ", click Download to open your browser") "
                        "or ⌘ + Q to Quit"
                    },
                    width: 720,
                    buttonTitle: "Download",
                    onButtonTapped: {
                        if let url = URL(string: appState.versionCheckToast.wrappedValue.linkToCurrentVersion) {
                            self.logger.verbose("Launching browser to get new application version", context: "User")
                            launchURL(url)
                            let terminationTask = DispatchWorkItem {
#if os(macOS)
                                NSApplication.shared.terminate(nil)
#else
                                // TODO andydragon
#endif
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: terminationTask)
                        }
                    }
                )
                break
            case .manualCheckComplete:
                self.logger.verbose("Using latest application version", context: "Version")
                showToast(
                    .info,
                    "Latest version",
                    "You are using the latest version v\(appState.versionCheckToast.wrappedValue.appVersion)",
                    onDismissed: {
                        appState.resetCheckingForUpdates()
                    }
                )
                break
            case .checkFailed:
                self.logger.verbose("Version check failed", context: "Version")
                dismissAllNonBlockingToasts()
                showToast(
                    .alert,
                    "Failed to check version",
                    String {
                        "Failed to check the app version. You are using v\(appState.versionCheckToast.wrappedValue.appVersion)"
                        "(this will go away in \(AdvancedToastStyle.alert.duration) seconds)"
                    },
                    width: 720,
                    buttonTitle: "Retry",
                    onButtonTapped: {
                        appState.resetCheckingForUpdates()
                        appState.checkForUpdates()
                    },
                    onDismissed: {
                        appState.resetCheckingForUpdates()
                    }
                )
                break
            default:
                // do nothing
                break
            }
        }

        // MARK: Reports
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

        // MARK: Toasts
        var toastViews = [AdvancedToast]()
        var hasModalToasts: Bool {
            return toastViews.count(where: { $0.modal }) > 0
        }

        func dismissToast(
            _ toast: AdvancedToast
        ) {
            toastViews.removeAll(where: { $0 == toast })
        }

        func dismissAllNonBlockingToasts(includeProgress: Bool = false) {
            toastViews.removeAll(where: { !$0.blocking })
            if includeProgress {
                toastViews.removeAll(where: { $0.type == .progress })
            }
        }

        @discardableResult func showToast(
            _ type: AdvancedToastStyle,
            _ title: String,
            _ message: String,
            duration: Double? = nil,
            modal: Bool? = nil,
            blocking: Bool? = nil,
            width: CGFloat? = nil,
            buttonTitle: String? = nil,
            onButtonTapped: (() -> Void)? = nil,
            onDismissed: (() -> Void)? = nil
        ) -> AdvancedToast {
            let advancedToastView = AdvancedToast(
                type: type,
                title: title,
                message: message,
                duration: duration,
                modal: modal,
                blocking: blocking,
                width: width,
                buttonTitle: buttonTitle,
                onButtonTapped: onButtonTapped,
                onDismissed: onDismissed
            )
            toastViews.append(advancedToastView)
            while toastViews.count > 5 {
                toastViews.remove(at: 0)
            }
            return advancedToastView
        }

        @discardableResult func showSuccessToast(
            _ title: String,
            _ message: String
        ) -> AdvancedToast {
            return showToast(.success, title, message)
        }

        @discardableResult func showInfoToast(
            _ title: String,
            _ message: String
        ) -> AdvancedToast {
            return showToast(.info, title, message)
        }
    }

    static func compareFeatures(_ lhs: ObservableFeature, _ rhs: ObservableFeature) -> Bool {
        // Empty names always at the bottom
        if lhs.userName.isEmpty {
            return false
        }
        if rhs.userName.isEmpty {
            return true
        }

        let compareUserName = lhs.userName.localizedStandardCompare(rhs.userName) == .orderedAscending

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
            return compareUserName
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
            return compareUserName
        }
        if lhAiCheck {
            return false
        }
        if rhAiCheck {
            return true
        }

        if lhs.tooSoonToFeatureUser && rhs.tooSoonToFeatureUser {
            return compareUserName
        }
        if lhs.tooSoonToFeatureUser {
            return false
        }
        if rhs.tooSoonToFeatureUser {
            return true
        }

        if !lhs.isPicked && !rhs.isPicked {
            return compareUserName
        }
        if !lhs.isPicked {
            return false
        }
        if !rhs.isPicked {
            return true
        }

        return compareUserName
    }
}
