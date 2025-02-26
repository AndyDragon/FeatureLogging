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

    func validationResult(_ viewModel: ContentView.ViewModel) -> ValidationResult {
        let postValidation = validatePostLink()
        if postValidation != .valid {
            return postValidation
        }
        let userAliasValidation = validateUserAlias(viewModel)
        if userAliasValidation != .valid {
            return userAliasValidation
        }
        let userNameValidation = validateUserName()
        if userNameValidation != .valid {
            return userNameValidation
        }
        let userLevelValidation = validateUserLevel()
        if userLevelValidation != .valid {
            return userLevelValidation
        }
        let photoFeaturedOnHubValidation = validatePhotoFeaturedOnHub()
        if photoFeaturedOnHubValidation != .valid {
            return photoFeaturedOnHubValidation
        }
        let featureDescriptionValidation = validateDescription()
        if featureDescriptionValidation != .valid {
            return featureDescriptionValidation
        }
        let userFeaturedOnPageValidation = validateUserFeaturedOnPage()
        if userFeaturedOnPageValidation != .valid {
            return userFeaturedOnPageValidation
        }
        let userFeaturedOnHubValidation = validateUserFeaturedOnHub()
        if userFeaturedOnHubValidation != .valid {
            return userFeaturedOnHubValidation
        }
        return .valid
    }

    static func == (lhs: ObservableFeature, rhs: ObservableFeature) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func validatePostLink() -> ValidationResult {
        if postLink.isEmpty {
            return .error("Required value")
        }
        if postLink.contains(where: \.isNewline) {
            return .error("Cannot contain newline characters")
        }
        return .valid
    }

    func validateUserAlias(_ viewModel: ContentView.ViewModel) -> ValidationResult {
        if userAlias.isEmpty {
            return .error("Required value")
        }
        if userAlias.starts(with: "@") {
            return .error("Cannot start with '@'")
        }
        if userAlias.count <= 1 {
            return .error("Must be longer than 1 character")
        }
        if userAlias.contains(where: \.isNewline) {
            return .error("Cannot contain newline characters")
        }
        if userAlias.contains(where: \.isWhitespace) {
            return .error("Cannot contain whitepace characters")
        }
        if viewModel.loadedCatalogs.disallowLists[viewModel.selectedPage?.hub ?? ""]?.contains(where: { $0 == userAlias }) ?? false {
            return .error("User is on disallowed list")
        }
        if viewModel.loadedCatalogs.cautionLists[viewModel.selectedPage?.hub ?? ""]?.contains(where: { $0 == userAlias }) ?? false {
            return .warning("User is on caution list")
        }
        return .valid
    }

    func validateUserName() -> ValidationResult {
        if userName.isEmpty {
            return .error("Required value")
        }
        if userName.contains(where: \.isNewline) {
            return .error("Cannot contain newline characters")
        }
        return .valid
    }

    func validateUserLevel() -> ValidationResult {
        if userLevel == MembershipCase.none {
            return .error("Required value")
        }
        return .valid
    }

    func validateDescription() -> ValidationResult {
        if featureDescription.isEmpty {
            return .warning("Should specify a description")
        }
        return .valid
    }

    func validatePhotoFeaturedOnHub() -> ValidationResult {
        if photoFeaturedOnHub && (photoLastFeaturedOnHub.isEmpty || photoLastFeaturedPage.isEmpty) {
            return .warning("Should specify when photo last featured on hub")
        }
        return .valid
    }

    func validateUserFeaturedOnPage() -> ValidationResult {
        if userHasFeaturesOnPage && lastFeaturedOnPage.isEmpty {
            return .warning("Should specify when user last featured on page")
        }
        return .valid
    }

    func validateUserFeaturedOnHub() -> ValidationResult {
        if userHasFeaturesOnHub && (lastFeaturedOnHub.isEmpty || lastFeaturedPage.isEmpty) {
            return .warning("Should specify when user last featured on hub")
        }
        return .valid
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
                userLevel = MembershipCase.clickMember
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
                userLevel = MembershipCase.clickPlatinumMember
            }
        } else if page.hub == "snap" {
            let totalFeatures = calculateFeatureCount(feature.featureCountOnHub)
            if totalFeatures + 1 == 5 {
                newLevel = NewMembershipCase.snapMemberFeature
                userLevel = MembershipCase.snapMember
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
