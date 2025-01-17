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
    var featureCountOnRawPage = "0"
    var userHasFeaturesOnHub = false
    var lastFeaturedOnHub = ""
    var lastFeaturedPage = ""
    var featureCountOnHub = "many"
    var featureCountOnRawHub = "0"
    var tooSoonToFeatureUser = false
    var tinEyeResults = TinEyeResults.zeroMatches
    var aiCheckResults = AiCheckResults.human
    var personalMessage = ""

    var isPickedAndAllowed: Bool {
        isPicked && !tooSoonToFeatureUser && !photoFeaturedOnPage && tinEyeResults != .matchFound && aiCheckResults != .ai
    }

    init() {}

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
        self.userLevel = feature.userLevel
        self.firstFeature = !feature.userHasFeaturesOnPage
        self.newLevel = NewMembershipCase.none
        if page.hub == "click" {
            let totalFeatures = calculateFeatureCount(feature.featureCountOnHub)
            if totalFeatures + 1 == 5 {
                self.newLevel = NewMembershipCase.clickMember
                self.userLevel = MembershipCase.commonMember
            } else if totalFeatures + 1 == 15 {
                self.newLevel = NewMembershipCase.clickBronzeMember
                self.userLevel = MembershipCase.clickBronzeMember
            } else if totalFeatures + 1 == 30 {
                self.newLevel = NewMembershipCase.clickSilverMember
                self.userLevel = MembershipCase.clickSilverMember
            } else if totalFeatures + 1 == 50 {
                self.newLevel = NewMembershipCase.clickGoldMember
                self.userLevel = MembershipCase.clickGoldMember
            } else if totalFeatures + 1 == 75 {
                self.newLevel = NewMembershipCase.clickPlatinumMember
                self.userLevel = MembershipCase.commonPlatinumMember
            }
        } else if page.hub == "snap" {
            let totalFeatures = calculateFeatureCount(feature.featureCountOnHub) + calculateFeatureCount(feature.featureCountOnRawHub)
            if totalFeatures + 1 == 5 {
                self.newLevel = NewMembershipCase.snapMemberFeature
                self.userLevel = MembershipCase.commonMember
            } else if totalFeatures + 1 == 15 {
                self.newLevel = NewMembershipCase.snapVipMemberFeature
                self.userLevel = MembershipCase.snapVipMember
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
        if self.hub.isEmpty {
            return self.name
        }
        return "\(self.hub):\(self.name)"
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
        self.name = page.name
        self.pageName = page.pageName
        self.title = page.title
        self.hashTag = page.hashTag
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
