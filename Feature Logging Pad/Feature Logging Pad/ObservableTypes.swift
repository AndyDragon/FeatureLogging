//
//  ObservableTypes.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-12-17.
//

import SwiftUI

@Observable
class ObservableFeature: Identifiable, Hashable {
    var id = UUID()
    var isPicked = false
    var postLink = ""
    var userName = ""
    var userAlias = ""
    var userLevel = MembershipCase.none
    var userIsTeammate = false
    var tagSource = TagSourceCase.commonPageTag
    var photoFeaturedOnPage = false
    var photoFeaturedOnHub = false
    var photoLastFeaturedOnHub = ""
    var photoLastFeaturedPage = ""
    var featureDescription = ""
    var userHasFeaturesOnPage = false
    var lastFeaturedOnPage = ""
    var featureCountOnPage = "many"
    var userHasFeaturesOnHub = false
    var lastFeaturedOnHub = ""
    var lastFeaturedPage = ""
    var featureCountOnHub = "many"
    var tooSoonToFeatureUser = false
    var tinEyeResults = TinEyeResults.zeroMatches
    var aiCheckResults = AiCheckResults.human
    var personalMessage = ""

    var isPickAllowed: Bool {
        !tooSoonToFeatureUser && !photoFeaturedOnPage && tinEyeResults != .matchFound && aiCheckResults != .ai
    }

    var isPickedAndAllowed: Bool {
        isPicked && !tooSoonToFeatureUser && !photoFeaturedOnPage && tinEyeResults != .matchFound && aiCheckResults != .ai
    }

    init() {}

    var validationResult: ValidationResult {
        if postLink.isEmpty || postLink.contains(where: \.isNewline) {
            return .Failure
        }
        if userAlias.isEmpty || userAlias.starts(with: "@") || userAlias.count <= 1 || userAlias.contains(where: \.isNewline) {
            return .Failure
        }
        if userName.isEmpty || userName.contains(where: \.isNewline) {
            return .Failure
        }
        if userLevel == MembershipCase.none {
            return .Failure
        }
        if photoFeaturedOnHub && (photoLastFeaturedOnHub.isEmpty || photoLastFeaturedPage.isEmpty) {
            return .Warning
        }
        if featureDescription.isEmpty {
            return .Warning
        }
        if userHasFeaturesOnPage && lastFeaturedOnPage.isEmpty {
            return .Warning
        }
        if userHasFeaturesOnHub && (lastFeaturedOnHub.isEmpty || lastFeaturedPage.isEmpty) {
            return .Warning
        }
        return .Success
    }

    static func == (lhs: ObservableFeature, rhs: ObservableFeature) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable
class ObservableFeatureWrapper: Identifiable, Hashable {
    var id = UUID()
    var feature: ObservableFeature
    var userLevel: MembershipCase
    var firstFeature: Bool
    var newLevel: NewMembershipCase

    init(using page: ObservablePage, from feature: ObservableFeature) {
        self.feature = feature
        userLevel = feature.userLevel
        firstFeature = !feature.userHasFeaturesOnPage
        newLevel = NewMembershipCase.none
        if page.hub == "click" {
            let totalFeatures = calculateFeatureCount(feature.featureCountOnHub)
            if totalFeatures + 1 == 5 {
                newLevel = NewMembershipCase.clickMember
                userLevel = MembershipCase.commonMember
            } else if totalFeatures + 1 == 15 {
                newLevel = NewMembershipCase.clickBronzeMember
                userLevel = MembershipCase.clickBronzeMember
            } else if totalFeatures + 1 == 30 {
                newLevel = NewMembershipCase.clickSilverMember
                userLevel = MembershipCase.clickSilverMember
            } else if totalFeatures + 1 == 50 {
                newLevel = NewMembershipCase.clickGoldMember
                userLevel = MembershipCase.clickGoldMember
            } else if totalFeatures + 1 == 75 {
                newLevel = NewMembershipCase.clickPlatinumMember
                userLevel = MembershipCase.commonPlatinumMember
            }
        } else if page.hub == "snap" {
            let totalFeatures = calculateFeatureCount(feature.featureCountOnHub)
            if totalFeatures + 1 == 5 {
                newLevel = NewMembershipCase.snapMemberFeature
                userLevel = MembershipCase.commonMember
            } else if totalFeatures + 1 == 15 {
                newLevel = NewMembershipCase.snapVipMemberFeature
                userLevel = MembershipCase.snapVipMember
            }
        }
    }

    static func == (lhs: ObservableFeatureWrapper, rhs: ObservableFeatureWrapper) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func calculateFeatureCount(_ count: String) -> Int {
        if count == "many" {
            return 99999
        }
        return Int(count) ?? 0
    }
}

@Observable
class ObservablePage: Identifiable, Hashable {
    var id: String {
        if hub.isEmpty {
            return name
        }
        return "\(hub):\(name)"
    }

    var hub: String
    var name: String
    var pageName: String?
    var title: String?
    var hashTag: String?
    var displayName: String {
        if hub == "other" {
            return name
        }
        return "\(hub)_\(name)"
    }

    var displayTitle: String {
        return title ?? "\(hub) \(name)"
    }

    var hashTags: [String] {
        if hub == "snap" {
            if let basePageName = pageName {
                if basePageName != name {
                    return [hashTag ?? "#snap_\(name)", "#raw_\(name)", "#snap_\(basePageName)", "#raw_\(basePageName)"]
                }
            }
            return [hashTag ?? "#snap_\(name)", "#raw_\(name)"]
        } else if hub == "click" {
            return [hashTag ?? "#click_\(name)"]
        } else {
            return [hashTag ?? name]
        }
    }

    init(hub: String, page: Page) {
        self.hub = hub
        name = page.name
        pageName = page.pageName
        title = page.title
        hashTag = page.hashTag
    }

    private init() {
        hub = ""
        name = ""
        pageName = nil
        title = nil
        hashTag = nil
    }

    static let dummy = ObservablePage()

    static func == (lhs: ObservablePage, rhs: ObservablePage) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
