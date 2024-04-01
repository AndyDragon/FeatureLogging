//
//  Types.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum MembershipCase: String, CaseIterable, Identifiable {
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

enum TagSourceCases: String, CaseIterable, Identifiable {
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
    
    static func casesFor(hub: String?) -> [TagSourceCases] {
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
    
    static func caseValidFor(hub: String?, _ value: TagSourceCases) -> Bool {
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

enum TinEyeResults: String, CaseIterable, Identifiable {
    case zeroMatches = "0 matches",
         noMatches = "no matches",
         matchFound = "found match"
    
    var id: Self { self }
}

enum AiCheckResults: String, CaseIterable, Identifiable {
    case human = "human",
         ai = "ai"
    
    var id: Self { self }
}

enum NewMembershipCase: String, CaseIterable, Identifiable {
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

class FeatureUsersViewModel: ObservableObject {
    @Published var features = [FeatureUser]()
    var sortedFeatures: [FeatureUser] {
        return features.sorted(by: compareUsers)
    }

    init() {}
    
    private func compareUsers(_ lhs: FeatureUser, _ rhs: FeatureUser) -> Bool {
        if lhs.photoFeaturedOnPage && rhs.photoFeaturedOnPage {
            return lhs.userName < rhs.userName
        }
        if lhs.photoFeaturedOnPage {
            return false
        }
        if rhs.photoFeaturedOnPage {
            return true
        }

        let lhsTinEye = TinEyeResults(rawValue: lhs.tinEyeResults) == .matchFound
        let rhsTinEye = TinEyeResults(rawValue: rhs.tinEyeResults) == .matchFound
        if lhsTinEye && rhsTinEye {
            return lhs.userName < rhs.userName
        }
        if lhsTinEye {
            return false
        }
        if rhsTinEye {
            return true
        }
        
        let lhAiCheck = AiCheckResults(rawValue: lhs.aiCheckResults) == .ai
        let rhAiCheck = AiCheckResults(rawValue: rhs.aiCheckResults) == .ai
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
    var userLevel: String
    var userIsTeammate: Bool
    var tagSource: String
    var photoFeaturedOnPage: Bool
    var featureDescription: String
    var userHasFeaturesOnPage: Bool
    var lastFeaturedOnPage: String
    var featureCountOnPage: String
    var featureCountOnRawPage: String
    var userHasFeaturesOnHub: Bool
    var lastFeaturedOnHub: String
    var lastFeaturedPage: String
    var featureCountOnSnap: String
    var featureCountOnRaw: String
    var tooSoonToFeatureUser: Bool
    var tinEyeResults: String
    var aiCheckResults: String
    
    init(featureUser: FeatureUser) {
        self.isPicked = featureUser.isPicked
        self.postLink = featureUser.postLink
        self.userName = featureUser.userName
        self.userAlias = featureUser.userAlias
        self.userLevel = featureUser.userLevel
        self.userIsTeammate = featureUser.userIsTeammate
        self.tagSource = featureUser.tagSource
        self.photoFeaturedOnPage = featureUser.photoFeaturedOnPage
        self.featureDescription = featureUser.featureDescription
        self.userHasFeaturesOnPage = featureUser.userHasFeaturesOnPage
        self.lastFeaturedOnPage = featureUser.lastFeaturedOnPage
        self.featureCountOnPage = featureUser.featureCountOnPage
        self.featureCountOnRawPage = featureUser.featureCountOnRawPage
        self.userHasFeaturesOnHub = featureUser.userHasFeaturesOnHub
        self.lastFeaturedOnHub = featureUser.lastFeaturedOnHub
        self.lastFeaturedPage = featureUser.lastFeaturedPage
        self.featureCountOnSnap = featureUser.featureCountOnSnap
        self.featureCountOnRaw = featureUser.featureCountOnRaw
        self.tooSoonToFeatureUser = featureUser.tooSoonToFeatureUser
        self.tinEyeResults = featureUser.tinEyeResults
        self.aiCheckResults = featureUser.aiCheckResults
    }
}

struct Log: Codable {
    var page: String
    private var features: [LogFeature]
    
    init() {
        page = ""
        features = [LogFeature]()
    }
    
    init(page: LoadedPage, featureUsers: [FeatureUser]) {
        self.page = page.id
        self.features = featureUsers.map({ featureUser in
            LogFeature(featureUser: featureUser)
        })
    }
    
    func getFeatureUsers() -> [FeatureUser] {
        var featureUsers = [FeatureUser]()
        for feature in features {
            let featureUser = FeatureUser()
            featureUser.isPicked = feature.isPicked
            featureUser.postLink = feature.postLink
            featureUser.userName = feature.userName
            featureUser.userAlias = feature.userAlias
            featureUser.userLevel = feature.userLevel
            featureUser.userIsTeammate = feature.userIsTeammate
            featureUser.tagSource = feature.tagSource
            featureUser.photoFeaturedOnPage = feature.photoFeaturedOnPage
            featureUser.featureDescription = feature.featureDescription
            featureUser.userHasFeaturesOnPage = feature.userHasFeaturesOnPage
            featureUser.lastFeaturedOnPage = feature.lastFeaturedOnPage
            featureUser.featureCountOnPage = feature.featureCountOnPage
            featureUser.featureCountOnRawPage = feature.featureCountOnRawPage
            featureUser.userHasFeaturesOnHub = feature.userHasFeaturesOnHub
            featureUser.lastFeaturedOnHub = feature.lastFeaturedOnHub
            featureUser.lastFeaturedPage = feature.lastFeaturedPage
            featureUser.featureCountOnSnap = feature.featureCountOnSnap
            featureUser.featureCountOnRaw = feature.featureCountOnRaw
            featureUser.tooSoonToFeatureUser = feature.tooSoonToFeatureUser
            featureUser.tinEyeResults = feature.tinEyeResults
            featureUser.aiCheckResults = feature.aiCheckResults
            featureUsers.append(featureUser)
        }
        return featureUsers
    }
}

struct LogDocument: FileDocument {
    static var readableContentTypes = [UTType.json]
    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(page: LoadedPage, featureUsers: [FeatureUser]) {
        let log = Log(page: page, featureUsers: featureUsers)
        do {
            let jsonEncoder = JSONEncoder()
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

class FeatureUser: Identifiable, Hashable, ObservableObject {
    var id = UUID()
    @Published var isPicked = false
    @Published var postLink = ""
    @Published var userName = ""
    @Published var userAlias = ""
    @Published var userLevel = MembershipCase.none.rawValue
    @Published var userIsTeammate = false
    @Published var tagSource = TagSourceCases.commonPageTag.rawValue
    @Published var photoFeaturedOnPage = false
    @Published var featureDescription = ""
    @Published var userHasFeaturesOnPage = false
    @Published var lastFeaturedOnPage = ""
    @Published var featureCountOnPage = "many"
    @Published var featureCountOnRawPage = "many"
    @Published var userHasFeaturesOnHub = false
    @Published var lastFeaturedOnHub = ""
    @Published var lastFeaturedPage = ""
    @Published var featureCountOnSnap = "many"
    @Published var featureCountOnRaw = "many"
    @Published var tooSoonToFeatureUser = false
    @Published var tinEyeResults = TinEyeResults.zeroMatches.rawValue
    @Published var aiCheckResults = AiCheckResults.human.rawValue
    
    init() { }
    
    static func == (lhs: FeatureUser, rhs: FeatureUser) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct CodableFeatureUser: Codable {
    var page: String
    var userName: String
    var userAlias: String
    var userLevel: String
    var tagSource: String
    var firstFeature: Bool
    var newLevel: String
    
    init(using page: LoadedPage, from user: FeatureUser) {
        self.page = page.id;
        self.userName = user.userName
        self.userAlias = user.userAlias
        self.userLevel = user.userLevel
        self.tagSource = user.tagSource
        self.firstFeature = !user.userHasFeaturesOnPage
        self.newLevel = "None"
        if page.hub == "click" {
            let totalFeatures = Int(user.featureCountOnPage) ?? 0
            if totalFeatures + 1 == 5 {
                self.newLevel = "Member"
            } else if totalFeatures + 1 == 15 {
                self.newLevel = "Bronze Member"
            } else if totalFeatures + 1 == 30 {
                self.newLevel = "Silver Member"
            } else if totalFeatures + 1 == 50 {
                self.newLevel = "Gold Member"
            } else if totalFeatures + 1 == 75 {
                self.newLevel = "Platinum Member"
            }
        } else if page.hub == "snap" {
            let totalFeatures = Int(user.featureCountOnPage) ?? 0
            if totalFeatures + 1 == 5 {
                self.newLevel = "Member"
            } else if totalFeatures + 1 == 15 {
                self.newLevel = "VIP Member"
            }
        }
    }
}

struct ScriptsCatalog: Codable {
    var hubs: [String: [Page]]
}

struct Page: Codable {
    var id: String { self.name }
    let name: String
    let pageName: String?
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
    let hashTag: String?
    var displayName: String {
        if hub == "other" {
            return name
        }
        return "\(hub)_\(name)"
    }

    static func from(hub: String, page: Page) -> LoadedPage {
        return LoadedPage(hub: hub, name: page.name, pageName: page.pageName, hashTag: page.hashTag)
    }
}

enum ToastDuration: Int {
    case disabled = 0,
         short = 3,
         medium = 10,
         long = 20
}
