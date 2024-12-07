//
//  Types.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum FocusField: Hashable {
    case copyFeatureScript, // ScriptContentView
         featureScript,
         copyCommentScript,
         commentScript,
         copyOriginalPostScript,
         originalPostScript,
         newMembership,
         copyNewMembershipScript,
         newMembershipScript,

         pagePicker, // Content view
         staffLevel,
         copyTag,
         yourName,
         yourFirstName,
         addFeature,
         removeFeature,
         featureList,

         picked, // Feature editor
         postLink,
         userAlias,
         userName,
         userLevel,
         teammate,
         tagSource,
         photoFeatureOnPage,
         photoFeatureOnHub,
         photoLastFeaturedOnHub,
         photoLastFeaturedPage,
         description,
         userHasFeaturesOnPage,
         lastFeaturedOnPage,
         featureCountOnPage,
         userHasFeaturesOnHub,
         lastFeaturedOnHub,
         lastFeaturedPage,
         featureCountOnHub,
         featureCountOnRawPage,
         featureCountOnRawHub,
         tooSoonToFeatureUser,
         tinEyeResults,
         aiCheckResults,

         postUserName, // Post downloader
         postUserLevel,
         postTeammate,
         postDescription,
         postPhotoFeaturedOnPage,
         postPhotoFeaturedOnHub,
         postPhotoLastFeaturedOnHub,
         postPhotoLastFeaturedPage,

         openFolder, // Statistics
         statsPagePicker
}

enum MembershipCase: String, CaseIterable, Identifiable, Codable {
    case none = "None"
    case commonArtist = "Artist"
    case commonMember = "Member"
    case commonPlatinumMember = "Platinum Member"

    // snap
    case snapVipMember = "VIP Member"
    case snapVipGoldMember = "VIP Gold Member"
    case snapEliteMember = "Elite Member"
    case snapHallOfFameMember = "Hall of Fame Member"
    case snapDiamondMember = "Diamond Member"

    // click
    case clickBronzeMember = "Bronze Member"
    case clickSilverMember = "Silver Member"
    case clickGoldMember = "Gold Member"

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
            .snapDiamondMember,
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
                .snapDiamondMember,
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
                .commonPlatinumMember,
            ]
        }
        return [
            .none,
            .commonArtist,
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
                snapDiamondMember,
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
                commonPlatinumMember,
            ].contains(value)
        }
        return [
            none,
            commonArtist,
        ].contains(value)
    }
}

enum TagSourceCase: String, CaseIterable, Identifiable, Codable {
    case commonPageTag = "Page tag"
    // snap
    case snapRawPageTag = "RAW page tag"
    case snapCommunityTag = "Snap community tag"
    case snapRawCommunityTag = "RAW community tag"
    case snapMembershipTag = "Snap membership tag"

    // click
    case clickCommunityTag = "Click community tag"
    case clickHubTag = "Click hub tag"

    var id: Self { self }

    static func casesFor(hub: String?) -> [TagSourceCase] {
        if hub == "snap" {
            return [
                .commonPageTag,
                .snapRawPageTag,
                .snapCommunityTag,
                .snapRawCommunityTag,
                .snapMembershipTag,
            ]
        }
        if hub == "click" {
            return [
                .commonPageTag,
                .clickCommunityTag,
                .clickHubTag,
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
                snapMembershipTag,
            ].contains(value)
        }
        if hub == "click" {
            return [
                commonPageTag,
                clickCommunityTag,
                clickHubTag,
            ].contains(value)
        }
        return [
            commonPageTag
        ].contains(value)
    }
}

enum StaffLevelCase: String, CaseIterable, Identifiable, Codable {
    case mod = "Mod"
    case coadmin = "Co-Admin"
    case admin = "Admin"

    var id: Self { self }
}

enum PlaceholderSheetCase {
    case featureScript,
        commentScript,
        originalPostScript
}

enum NewMembershipCase: String, CaseIterable, Identifiable, Codable {
    case none = "None"

    // snap
    case snapMemberFeature = "Member (feature comment)"
    case snapMemberOriginalPost = "Member (original post comment)"
    case snapVipMemberFeature = "VIP Member (feature comment)"
    case snapVipMemberOriginalPost = "VIP Member (original post comment)"

    // click
    case clickMember = "Member"
    case clickBronzeMember = "Bronze Member"
    case clickSilverMember = "Silver Member"
    case clickGoldMember = "Gold Member"
    case clickPlatinumMember = "Platinum Member"

    var id: Self { self }

    static func casesFor(hub: String?) -> [NewMembershipCase] {
        if hub == "snap" {
            return [
                .none,
                .snapMemberFeature,
                .snapMemberOriginalPost,
                .snapVipMemberFeature,
                .snapVipMemberOriginalPost,
            ]
        }
        if hub == "click" {
            return [
                .none,
                .clickMember,
                .clickBronzeMember,
                .clickSilverMember,
                .clickGoldMember,
                .clickPlatinumMember,
            ]
        }
        return [
            .none
        ]
    }

    static func scriptFor(hub: String?, _ value: NewMembershipCase) -> String {
        if hub == "snap" {
            switch value {
            case .snapMemberFeature:
                return "snap:member feature"
            case .snapMemberOriginalPost:
                return "snap:member original post"
            case .snapVipMemberFeature:
                return "snap:vip member feature"
            case .snapVipMemberOriginalPost:
                return "snap:vip member original post"
            default:
                return ""
            }
        } else if hub == "click" {
            return "\(hub ?? ""):\(value.rawValue.replacingOccurrences(of: " ", with: "_").lowercased())"
        }
        return ""
    }

    static func caseValidFor(hub: String?, _ value: NewMembershipCase) -> Bool {
        if hub == "snap" {
            return [
                none,
                snapMemberFeature,
                snapMemberOriginalPost,
                snapVipMemberFeature,
                snapVipMemberOriginalPost,
            ].contains(value)
        }
        if hub == "click" {
            return [
                none,
                clickMember,
                clickBronzeMember,
                clickSilverMember,
                clickGoldMember,
                clickPlatinumMember,
            ].contains(value)
        }
        return [
            none
        ].contains(value)
    }
}

enum TinEyeResults: String, CaseIterable, Identifiable, Codable {
    case zeroMatches = "0 matches"
    case
        noMatches = "no matches"
    case
        matchFound = "matches found"

    var id: Self { self }
}

enum AiCheckResults: String, CaseIterable, Identifiable, Codable {
    case human = "human"
    case
        ai = "ai"

    var id: Self { self }
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

    init() {}

    static func == (lhs: Feature, rhs: Feature) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@Observable
class SharedFeature: Identifiable, Hashable/*, ObservableObject*/ {
    var id = UUID()
    /*@Published*/ var feature: Feature
    /*@Published*/ var userLevel: MembershipCase
    /*@Published*/ var firstFeature: Bool
    /*@Published*/ var newLevel: NewMembershipCase

    init(using page: LoadedPage, from feature: Feature) {
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

    static func == (lhs: SharedFeature, rhs: SharedFeature) -> Bool {
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

struct ScriptsCatalog: Codable {
    var hubs: [String: [Page]]
}

struct Page: Codable {
    var id: String { self.name }
    let name: String
    let pageName: String?
    let title: String?
    let hashTag: String?

    private init() {
        name = ""
        pageName = nil
        title = nil
        hashTag = nil
    }

    static let dummy = Page()
}

@Observable
class LoadedPage: Identifiable, Hashable {
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

    static let dummy = LoadedPage()

    static func == (lhs: LoadedPage, rhs: LoadedPage) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    var disallowList = [String: [String]]()
}

struct ServerResponse: Decodable {
    var id: String
    var created_at: String
    var report: ServerReport
    var facets: ResultFacets
}

struct ServerMessage: Decodable {
    var request_id: String
    var message: String
    var current_limit: String?
    var current_usage: String?
}

struct ServerReport: Decodable {
    var verdict: String
    var ai: DetectionResult
    var human: DetectionResult
}

struct DetectionResult: Decodable {
    var is_detected: Bool
}

struct ResultFacets: Decodable {
    var quality: Facet?
    var nsfw: Facet
}

struct Facet: Decodable {
    var version: String
    var is_detected: Bool
}

// Hive response sample
//{
//    "data": {
//        "classes": [
//            {
//                "class": "not_ai_generated",
//                "score": 0.9693848106949524
//            },
//            {
//                "class": "ai_generated",
//                "score": 0.030615189305047447
//            },
//            {
//                "class": "bingimagecreator",
//                "score": 4.447964208631009e-6
//            },
//            {
//                "class": "adobefirefly",
//                "score": 0.0006803195345384442
//            },
//            {
//                "class": "lcm",
//                "score": 3.1231433663692784e-8
//            },
//            {
//                "class": "dalle",
//                "score": 0.00003966318182581463
//            },
//            {
//                "class": "pixart",
//                "score": 5.551102965745605e-9
//            },
//            {
//                "class": "glide",
//                "score": 1.6027302158245824e-8
//            },
//            {
//                "class": "stablediffusion",
//                "score": 0.026461982953911948
//            },
//            {
//                "class": "imagen",
//                "score": 2.0150044870977677e-7
//            },
//            {
//                "class": "inconclusive",
//                "score": 0.0007316304156370474
//            },
//            {
//                "class": "amused",
//                "score": 5.797843840265209e-9
//            },
//            {
//                "class": "stablecascade",
//                "score": 1.8435211880087412e-8
//            },
//            {
//                "class": "midjourney",
//                "score": 0.00011036623754636568
//            },
//            {
//                "class": "hive",
//                "score": 6.0945842729890835e-6
//            },
//            {
//                "class": "deepfloyd",
//                "score": 7.780853317893922e-9
//            },
//            {
//                "class": "gan",
//                "score": 8.79620019163719e-6
//            },
//            {
//                "class": "stablediffusionxl",
//                "score": 0.000023775003147293175
//            },
//            {
//                "class": "vqdiffusion",
//                "score": 1.142599946654217e-7
//            },
//            {
//                "class": "kandinsky",
//                "score": 1.899167144949832e-6
//            },
//            {
//                "class": "wuerstchen",
//                "score": 5.14374021779188e-7
//            },
//            {
//                "class": "titan",
//                "score": 4.6770593033650576e-8
//            },
//            {
//                "class": "none",
//                "score": 0.9719300630287688
//            }
//        ]
//    },
//    "message": "success",
//    "status_code": 200
//}

struct HiveResponse: Decodable {
    var data: HiveData
    var message: String
    var status_code: Int
}

struct HiveData: Decodable {
    var classes: [HiveClass]
}

struct HiveClass: Decodable {
    var `class`: String
    var score: Double
}
