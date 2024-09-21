//
//  Types.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum FocusedField: Hashable {
    case userName, // ScriptContentView
         level,
         yourName,
         yourFirstName,
         page,
         pageName,
         staffLevel,
         firstFeature,
         rawTag,
         communityTag,
         hubTag,
         featureScript,
         commentScript,
         originalPostScript,
         newMembershipScript,
         
         pagePicker // Content view
}

enum MembershipCase: String, CaseIterable, Identifiable, Codable {
    case none = "None",

         commonArtist = "Artist",
         commonMember = "Member",
         commonPlatinumMember = "Platinum Member",

         // snap
         snapVipMember = "VIP Member",
         snapVipGoldMember = "VIP Gold Member",
         snapEliteMember = "Elite Member",
         snapHallOfFameMember = "Hall of Fame Member",
         snapDiamondMember = "Diamond Member",

         // click
         clickBronzeMember = "Bronze Member",
         clickSilverMember = "Silver Member",
         clickGoldMember = "Gold Member"

    var id: Self { self }

    static func allCasesSorted() -> [MembershipCase] {
        return [
            .none,
            .commonArtist,
            .commonMember,
            .snapVipMember,
            .snapVipGoldMember,
            .clickBronzeMember,
            .clickSilverMember,
            .clickGoldMember,
            .commonPlatinumMember,
            .snapEliteMember,
            .snapHallOfFameMember,
            .snapDiamondMember
        ]
    }
    
    static func casesFor(hub: String?) -> [MembershipCase] {
        if hub == "snap" {
            return [
                .none,
                .commonArtist,
                .commonMember,
                .snapVipMember,
                .snapVipGoldMember,
                .commonPlatinumMember,
                .snapEliteMember,
                .snapHallOfFameMember,
                .snapDiamondMember
            ]
        }
        if hub == "click" {
            return [
                .none,
                .commonArtist,
                .commonMember,
                .clickBronzeMember,
                .clickSilverMember,
                .clickGoldMember,
                .commonPlatinumMember
            ]
        }
        return [
            .none,
            .commonArtist
        ]
    }

    static func caseValidFor(hub: String?, _ value: MembershipCase) -> Bool {
        if hub == "snap" {
            return [
                none,
                commonArtist,
                commonMember,
                snapVipMember,
                snapVipGoldMember,
                commonPlatinumMember,
                snapEliteMember,
                snapHallOfFameMember,
                snapDiamondMember
            ].contains(value)
        }
        if hub == "click" {
            return [
                none,
                commonArtist,
                commonMember,
                clickBronzeMember,
                clickSilverMember,
                clickGoldMember,
                commonPlatinumMember
            ].contains(value)
        }
        return [
            none,
            commonArtist
        ].contains(value)
    }
}

enum TagSourceCase: String, CaseIterable, Identifiable, Codable {
    case commonPageTag = "Page tag",

         // snap
         snapRawPageTag = "RAW page tag",
         snapCommunityTag = "Snap community tag",
         snapRawCommunityTag = "RAW community tag",
         snapMembershipTag = "Snap membership tag",

         // click
         clickCommunityTag = "Click community tag",
         clickHubTag = "Click hub tag"

    var id: Self { self }

    static func casesFor(hub: String?) -> [TagSourceCase] {
        if hub == "snap" {
            return [
                .commonPageTag,
                .snapRawPageTag,
                .snapCommunityTag,
                .snapRawCommunityTag,
                .snapMembershipTag
            ]
        }
        if hub == "click" {
            return [
                .commonPageTag,
                .clickCommunityTag,
                .clickHubTag
            ]
        }
        return [
            .commonPageTag
        ]
    }

    static func caseValidFor(hub: String?, _ value: TagSourceCase) -> Bool {
        if hub == "snap" {
            return [
                commonPageTag,
                snapRawPageTag,
                snapCommunityTag,
                snapRawCommunityTag,
                snapMembershipTag
            ].contains(value)
        }
        if hub == "click" {
            return [
                commonPageTag,
                clickCommunityTag,
                clickHubTag
            ].contains(value)
        }
        return [
            commonPageTag
        ].contains(value)
    }
}

enum StaffLevelCase: String, CaseIterable, Identifiable, Codable {
    case mod = "Mod",
         coadmin = "Co-Admin",
         admin = "Admin"
    var id: Self { self }
}

enum PlaceholderSheetCase {
    case featureScript,
         commentScript,
         originalPostScript
}

enum NewMembershipCase: String, CaseIterable, Identifiable, Codable {
    case none = "None",

         // common
         commonMember = "Member",

         // snap
         snapVipMember = "VIP Member",

         // click
         clickBronzeMember = "Bronze Member",
         clickSilverMember = "Silver Member",
         clickGoldMember = "Gold Member",
         clickPlatinumMember = "Platinum Member"

    var id: Self { self }

    static func casesFor(hub: String?) -> [NewMembershipCase] {
        if hub == "snap" {
            return [
                .none,
                .commonMember,
                .snapVipMember
            ]
        }
        if hub == "click" {
            return [
                .none,
                .commonMember,
                .clickBronzeMember,
                .clickSilverMember,
                .clickGoldMember,
                .clickPlatinumMember
            ]
        }
        return [
            .none
        ]
    }

    static func caseValidFor(hub: String?, _ value: NewMembershipCase) -> Bool {
        if hub == "snap" {
            return [
                none,
                commonMember,
                snapVipMember
            ].contains(value)
        }
        if hub == "click" {
            return [
                none,
                commonMember,
                clickBronzeMember,
                clickSilverMember,
                clickGoldMember,
                clickPlatinumMember
            ].contains(value)
        }
        return [
            none
        ].contains(value)
    }
}

enum TinEyeResults: String, CaseIterable, Identifiable, Codable {
    case zeroMatches = "0 matches",
         noMatches = "no matches",
         matchFound = "matches found"

    var id: Self { self }
}

enum AiCheckResults: String, CaseIterable, Identifiable, Codable {
    case human = "human",
         ai = "ai"

    var id: Self { self }
}

class FeaturesViewModel: ObservableObject  {
    @Published var features = [Feature]()
    var sortedFeatures: [Feature] {
        return features.sorted(by: compareFeatures)
    }

    init() {}

    private func compareFeatures(_ lhs: Feature, _ rhs: Feature) -> Bool {
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

struct LogFeature: Codable {
    var isPicked: Bool
    var postLink: String
    var userName: String
    var userAlias: String
    var userLevel: MembershipCase
    var userIsTeammate: Bool
    var tagSource: TagSourceCase
    var photoFeaturedOnPage: Bool
    var photoFeaturedOnHub: Bool
    var photoLastFeaturedOnHub: String
    var photoLastFeaturedPage: String
    var featureDescription: String
    var userHasFeaturesOnPage: Bool
    var lastFeaturedOnPage: String
    var featureCountOnPage: String
    var featureCountOnRawPage: String
    var userHasFeaturesOnHub: Bool
    var lastFeaturedOnHub: String
    var lastFeaturedPage: String
    var featureCountOnHub: String
    var featureCountOnRawHub: String
    var tooSoonToFeatureUser: Bool
    var tinEyeResults: TinEyeResults
    var aiCheckResults: AiCheckResults
    var personalMessage: String

    init(feature: Feature) {
        self.isPicked = feature.isPicked
        self.postLink = feature.postLink
        self.userName = feature.userName
        self.userAlias = feature.userAlias
        self.userLevel = feature.userLevel
        self.userIsTeammate = feature.userIsTeammate
        self.tagSource = feature.tagSource
        self.photoFeaturedOnPage = feature.photoFeaturedOnPage
        self.photoFeaturedOnHub = feature.photoFeaturedOnHub
        self.photoLastFeaturedOnHub = feature.photoLastFeaturedOnHub
        self.photoLastFeaturedPage = feature.photoLastFeaturedPage
        self.featureDescription = feature.featureDescription
        self.userHasFeaturesOnPage = feature.userHasFeaturesOnPage
        self.lastFeaturedOnPage = feature.lastFeaturedOnPage
        self.featureCountOnPage = feature.featureCountOnPage
        self.featureCountOnRawPage = feature.featureCountOnRawPage
        self.userHasFeaturesOnHub = feature.userHasFeaturesOnHub
        self.lastFeaturedOnHub = feature.lastFeaturedOnHub
        self.lastFeaturedPage = feature.lastFeaturedPage
        self.featureCountOnHub = feature.featureCountOnHub
        self.featureCountOnRawHub = feature.featureCountOnRawHub
        self.tooSoonToFeatureUser = feature.tooSoonToFeatureUser
        self.tinEyeResults = feature.tinEyeResults
        self.aiCheckResults = feature.aiCheckResults
        self.personalMessage = feature.personalMessage
    }

    enum CodingKeys: CodingKey {
        case isPicked
        case postLink
        case userName
        case userAlias
        case userLevel
        case userIsTeammate
        case tagSource
        case photoFeaturedOnPage
        case photoFeaturedOnHub
        case photoLastFeaturedOnHub
        case photoLastFeaturedPage
        case featureDescription
        case userHasFeaturesOnPage
        case lastFeaturedOnPage
        case featureCountOnPage
        case featureCountOnRawPage
        case userHasFeaturesOnHub
        case lastFeaturedOnHub
        case lastFeaturedPage
        case featureCountOnHub
        case featureCountOnRawHub
        case tooSoonToFeatureUser
        case tinEyeResults
        case aiCheckResults
        case personalMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isPicked = try container.decode(Bool.self, forKey: .isPicked)
        self.postLink = try container.decode(String.self, forKey: .postLink)
        self.userName = try container.decode(String.self, forKey: .userName)
        self.userAlias = try container.decode(String.self, forKey: .userAlias)
        self.userLevel = try container.decode(MembershipCase.self, forKey: .userLevel)
        self.userIsTeammate = try container.decode(Bool.self, forKey: .userIsTeammate)
        self.tagSource = try container.decode(TagSourceCase.self, forKey: .tagSource)
        self.photoFeaturedOnPage = try container.decode(Bool.self, forKey: .photoFeaturedOnPage)
        self.photoFeaturedOnHub = try container.decodeIfPresent(Bool.self, forKey: .photoFeaturedOnHub) ?? false
        self.photoLastFeaturedOnHub = try container.decodeIfPresent(String.self, forKey: .photoLastFeaturedOnHub) ?? ""
        self.photoLastFeaturedPage = try container.decodeIfPresent(String.self, forKey: .photoLastFeaturedPage) ?? ""
        self.featureDescription = try container.decode(String.self, forKey: .featureDescription)
        self.userHasFeaturesOnPage = try container.decode(Bool.self, forKey: .userHasFeaturesOnPage)
        self.lastFeaturedOnPage = try container.decode(String.self, forKey: .lastFeaturedOnPage)
        self.featureCountOnPage = try container.decode(String.self, forKey: .featureCountOnPage)
        self.featureCountOnRawPage = try container.decode(String.self, forKey: .featureCountOnRawPage)
        self.userHasFeaturesOnHub = try container.decode(Bool.self, forKey: .userHasFeaturesOnHub)
        self.lastFeaturedOnHub = try container.decode(String.self, forKey: .lastFeaturedOnHub)
        self.lastFeaturedPage = try container.decode(String.self, forKey: .lastFeaturedPage)
        self.featureCountOnHub = try container.decode(String.self, forKey: .featureCountOnHub)
        self.featureCountOnRawHub = try container.decode(String.self, forKey: .featureCountOnRawHub)
        self.tooSoonToFeatureUser = try container.decode(Bool.self, forKey: .tooSoonToFeatureUser)
        self.tinEyeResults = try container.decode(TinEyeResults.self, forKey: .tinEyeResults)
        self.aiCheckResults = try container.decode(AiCheckResults.self, forKey: .aiCheckResults)
        self.personalMessage = try container.decodeIfPresent(String.self, forKey: .personalMessage) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isPicked, forKey: .isPicked)
        try container.encode(postLink, forKey: .postLink)
        try container.encode(userName, forKey: .userName)
        try container.encode(userAlias, forKey: .userAlias)
        try container.encode(userLevel, forKey: .userLevel)
        try container.encode(userIsTeammate, forKey: .userIsTeammate)
        try container.encode(tagSource, forKey: .tagSource)
        try container.encode(photoFeaturedOnPage, forKey: .photoFeaturedOnPage)
        try container.encode(photoFeaturedOnHub, forKey: .photoFeaturedOnHub)
        try container.encode(photoLastFeaturedOnHub, forKey: .photoLastFeaturedOnHub)
        try container.encode(photoLastFeaturedPage, forKey: .photoLastFeaturedPage)
        try container.encode(featureDescription, forKey: .featureDescription)
        try container.encode(userHasFeaturesOnPage, forKey: .userHasFeaturesOnPage)
        try container.encode(lastFeaturedOnPage, forKey: .lastFeaturedOnPage)
        try container.encode(featureCountOnPage, forKey: .featureCountOnPage)
        try container.encode(featureCountOnRawPage, forKey: .featureCountOnRawPage)
        try container.encode(userHasFeaturesOnHub, forKey: .userHasFeaturesOnHub)
        try container.encode(lastFeaturedOnHub, forKey: .lastFeaturedOnHub)
        try container.encode(lastFeaturedPage, forKey: .lastFeaturedPage)
        try container.encode(featureCountOnHub, forKey: .featureCountOnHub)
        try container.encode(featureCountOnRawHub, forKey: .featureCountOnRawHub)
        try container.encode(tooSoonToFeatureUser, forKey: .tooSoonToFeatureUser)
        try container.encode(tinEyeResults, forKey: .tinEyeResults)
        try container.encode(aiCheckResults, forKey: .aiCheckResults)
        try container.encode(personalMessage, forKey: .personalMessage)
    }
}

struct Log: Codable {
    var page: String
    var features: [LogFeature]

    init() {
        page = ""
        features = [LogFeature]()
    }

    init(page: LoadedPage, features: [Feature]) {
        self.page = page.id
        self.features = features.map({ feature in
            LogFeature(feature: feature)
        })
    }

    enum CodingKeys: CodingKey {
        case page
        case features
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.page = try container.decode(String.self, forKey: .page)
        self.features = try container.decode([LogFeature].self, forKey: .features)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(page, forKey: .page)
        try container.encode(features, forKey: .features)
    }

    func getFeatures() -> [Feature] {
        var featuresFromLog = [Feature]()
        for logFeature in features {
            let feature = Feature()
            feature.isPicked = logFeature.isPicked
            feature.postLink = logFeature.postLink
            feature.userName = logFeature.userName
            feature.userAlias = logFeature.userAlias
            feature.userLevel = logFeature.userLevel
            feature.userIsTeammate = logFeature.userIsTeammate
            feature.tagSource = logFeature.tagSource
            feature.photoFeaturedOnPage = logFeature.photoFeaturedOnPage
            feature.photoFeaturedOnHub = logFeature.photoFeaturedOnHub
            feature.photoLastFeaturedOnHub = logFeature.photoLastFeaturedOnHub
            feature.photoLastFeaturedPage = logFeature.photoLastFeaturedPage
            feature.featureDescription = logFeature.featureDescription
            feature.userHasFeaturesOnPage = logFeature.userHasFeaturesOnPage
            feature.lastFeaturedOnPage = logFeature.lastFeaturedOnPage
            feature.featureCountOnPage = logFeature.featureCountOnPage
            feature.featureCountOnRawPage = logFeature.featureCountOnRawPage
            feature.userHasFeaturesOnHub = logFeature.userHasFeaturesOnHub
            feature.lastFeaturedOnHub = logFeature.lastFeaturedOnHub
            feature.lastFeaturedPage = logFeature.lastFeaturedPage
            feature.featureCountOnHub = logFeature.featureCountOnHub
            feature.featureCountOnRawHub = logFeature.featureCountOnRawHub
            feature.tooSoonToFeatureUser = logFeature.tooSoonToFeatureUser
            feature.tinEyeResults = logFeature.tinEyeResults
            feature.aiCheckResults = logFeature.aiCheckResults
            feature.personalMessage = logFeature.personalMessage
            featuresFromLog.append(feature)
        }
        return featuresFromLog
    }
}

struct LogDocument: FileDocument {
    static var readableContentTypes = [UTType.json]
    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(page: LoadedPage, features: [Feature]) {
        let log = Log(page: page, features: features)
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = [.sortedKeys, .prettyPrinted]
            let json = try jsonEncoder.encode(log)
            text = String(decoding: json, as: UTF8.self)
        } catch {
            debugPrint(error)
        }
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

extension UTType {
    static let features = UTType(exportedAs: "com.andydragon.features-report", conformingTo: .plainText)
}

struct ReportDocument: FileDocument {
    static var readableContentTypes = [UTType.features]
    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

class Feature: Identifiable, Hashable, ObservableObject {
    var id = UUID()
    @Published var isPicked = false
    @Published var postLink = ""
    @Published var userName = ""
    @Published var userAlias = ""
    @Published var userLevel = MembershipCase.none
    @Published var userIsTeammate = false
    @Published var tagSource = TagSourceCase.commonPageTag
    @Published var photoFeaturedOnPage = false
    @Published var photoFeaturedOnHub = false
    @Published var photoLastFeaturedOnHub = ""
    @Published var photoLastFeaturedPage = ""
    @Published var featureDescription = ""
    @Published var userHasFeaturesOnPage = false
    @Published var lastFeaturedOnPage = ""
    @Published var featureCountOnPage = "many"
    @Published var featureCountOnRawPage = "0"
    @Published var userHasFeaturesOnHub = false
    @Published var lastFeaturedOnHub = ""
    @Published var lastFeaturedPage = ""
    @Published var featureCountOnHub = "many"
    @Published var featureCountOnRawHub = "0"
    @Published var tooSoonToFeatureUser = false
    @Published var tinEyeResults = TinEyeResults.zeroMatches
    @Published var aiCheckResults = AiCheckResults.human
    @Published var personalMessage = ""

    var isPickedAndAllowed: Bool {
        isPicked && !tooSoonToFeatureUser && !photoFeaturedOnPage && tinEyeResults != .matchFound && aiCheckResults != .ai
    }

    init() { }

    static func == (lhs: Feature, rhs: Feature) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CodableFeature: Codable {
    var page: String
    var pageStaffLevel: StaffLevelCase
    var userName: String
    var userAlias: String
    var userLevel: MembershipCase
    var tagSource: TagSourceCase
    var firstFeature: Bool
    var newLevel: NewMembershipCase
    var description: String

    init(using page: LoadedPage, pageStaffLevel: StaffLevelCase, from feature: Feature) {
        self.page = page.id;
        self.pageStaffLevel = pageStaffLevel
        self.userName = feature.userName
        self.userAlias = feature.userAlias
        self.userLevel = feature.userLevel
        self.tagSource = feature.tagSource
        self.firstFeature = !feature.userHasFeaturesOnPage
        self.newLevel = NewMembershipCase.none
        self.description = feature.featureDescription
        if page.hub == "click" {
            let totalFeatures = calculateFeatureCount(feature.featureCountOnHub)
            if totalFeatures + 1 == 5 {
                self.newLevel = NewMembershipCase.commonMember
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
                self.newLevel = NewMembershipCase.commonMember
                self.userLevel = MembershipCase.commonMember
            } else if totalFeatures + 1 == 15 {
                self.newLevel = NewMembershipCase.snapVipMember
                self.userLevel = MembershipCase.snapVipMember
            }
        }
    }

    func calculateFeatureCount(_ count: String) -> Int {
        if count == "many" {
            return 99999
        }
        return Int(count) ?? 0
    }

    enum CodingKeys: CodingKey {
        case page
        case pageStaffLevel
        case userName
        case userAlias
        case userLevel
        case tagSource
        case firstFeature
        case newLevel
        case description
    }
    
    init(json: Data) throws {
        let decoder = JSONDecoder()
        let feature = try decoder.decode(CodableFeature.self, from: json)
        self.page = feature.page
        self.pageStaffLevel = feature.pageStaffLevel
        self.userName = feature.userName
        self.userAlias = feature.userAlias
        self.userLevel = feature.userLevel
        self.tagSource = feature.tagSource
        self.firstFeature = feature.firstFeature
        self.newLevel = feature.newLevel
        self.description = feature.description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.page = try container.decode(String.self, forKey: .page)
        self.pageStaffLevel = try container.decodeIfPresent(StaffLevelCase.self, forKey: .pageStaffLevel) ?? StaffLevelCase.mod
        self.userName = try container.decode(String.self, forKey: .userName)
        self.userAlias = try container.decode(String.self, forKey: .userAlias)
        self.userLevel = try container.decode(MembershipCase.self, forKey: .userLevel)
        self.tagSource = try container.decode(TagSourceCase.self, forKey: .tagSource)
        self.firstFeature = try container.decode(Bool.self, forKey: .firstFeature)
        self.newLevel = try container.decode(NewMembershipCase.self, forKey: .newLevel)
        self.description = try container.decode(String.self, forKey: .description)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(page, forKey: .page)
        try container.encode(pageStaffLevel, forKey: .pageStaffLevel)
        try container.encode(userName, forKey: .userName)
        try container.encode(userAlias, forKey: .userAlias)
        try container.encode(userLevel, forKey: .userLevel)
        try container.encode(tagSource, forKey: .tagSource)
        try container.encode(firstFeature, forKey: .firstFeature)
        try container.encode(newLevel, forKey: .newLevel)
        try container.encode(description, forKey: .description)
    }
}

struct ScriptsCatalog: Codable {
    var hubs: [String: [Page]]
}

struct Page: Codable {
    var id: String { self.name }
    let name: String
    let pageName: String?
    let title: String?
    let hashTag: String?
}

struct LoadedPage: Codable, Identifiable {
    var id: String {
        if self.hub.isEmpty {
            return self.name
        }
        return "\(self.hub):\(self.name)"
    }
    let hub: String
    let name: String
    let pageName: String?
    let title: String?
    let hashTag: String?
    var displayName: String {
        if hub == "other" {
            return name
        }
        return "\(hub)_\(name)"
    }

    static func from(hub: String, page: Page) -> LoadedPage {
        return LoadedPage(hub: hub, name: page.name, pageName: page.pageName, title: page.title, hashTag: page.hashTag)
    }
}

struct TemplateCatalog: Codable {
    let pages: [TemplatePage]
    let specialTemplates: [Template]
}

struct TemplatePage: Codable, Identifiable {
    var id: String { self.name }
    let name: String
    let templates: [Template]
}

struct HubCatalog: Codable {
    let hubs: [Hub]
}

struct Hub: Codable, Identifiable {
    var id: String { self.name }
    let name: String
    let templates: [Template]
}

struct Template: Codable, Identifiable {
    var id: String { self.name }
    let name: String
    let template: String
}

struct LoadedCatalogs {
    var waitingForPages = true
    var loadedPages = [LoadedPage]()
    var waitingForTemplates = true
    var templatesCatalog = TemplateCatalog(pages: [], specialTemplates: [])
    var waitingForDisallowList = true
    var disallowList = [String]()
}
