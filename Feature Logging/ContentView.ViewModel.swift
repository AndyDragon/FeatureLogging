//
//  ContentView.ViewModel.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-12-17.
//

import SwiftUI

extension ContentView {
    @Observable
    class ViewModel {
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

        init() {}

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

    static func compareFeatures(_ lhs: ObservableFeature, _ rhs: ObservableFeature) -> Bool {
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
