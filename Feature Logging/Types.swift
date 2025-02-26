//
//  Types.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-03-29.
//

import SwiftUI

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
         generateReport,
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
         tooSoonToFeatureUser,
         tinEyeResults,
         aiCheckResults,

         postUserAlias, // Post downloader
         postUserName,
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

    // snap
    case snapMember = "Snap Member"
    case snapVipMember = "Snap VIP Member"
    case snapVipGoldMember = "Snap VIP Gold Member"
    case snapPlatinumMember = "Snap Platinum Member"
    case snapEliteMember = "Snap Elite Member"
    case snapHallOfFameMember = "Snap Hall of Fame Member"
    case snapDiamondMember = "Snap Diamond Member"

    // click
    case clickMember = "Click Member"
    case clickBronzeMember = "Click Bronze Member"
    case clickSilverMember = "Click Silver Member"
    case clickGoldMember = "Click Gold Member"
    case clickPlatinumMember = "Click Platinum Member"

    var id: Self { self }

    static func allCasesSorted() -> [MembershipCase] {
        return [
            .none,
            .commonArtist,
            .snapMember,
            .snapVipMember,
            .snapVipGoldMember,
            .snapPlatinumMember,
            .snapEliteMember,
            .snapHallOfFameMember,
            .snapDiamondMember,
            .clickMember,
            .clickBronzeMember,
            .clickSilverMember,
            .clickGoldMember,
            .clickPlatinumMember,
        ]
    }

    static func casesFor(hub: String?) -> [MembershipCase] {
        if hub == "snap" {
            return [
                .none,
                .commonArtist,
                .snapMember,
                .snapVipMember,
                .snapVipGoldMember,
                .snapPlatinumMember,
                .snapEliteMember,
                .snapHallOfFameMember,
                .snapDiamondMember,
            ]
        }
        if hub == "click" {
            return [
                .none,
                .commonArtist,
                .clickMember,
                .clickBronzeMember,
                .clickSilverMember,
                .clickGoldMember,
                .clickPlatinumMember,
            ]
        }
        return [
            .none,
            .commonArtist,
        ]
    }

    static func caseValidFor(hub: String?, _ value: MembershipCase) -> Bool {
        return casesFor(hub: hub).contains(value)
    }
}

extension MembershipCase {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedValue = try container.decode(String.self)
        if decodedValue.hasPrefix("Click ") {
            let rawValueWithoutPrefix = String(decodedValue[decodedValue.index(decodedValue.startIndex, offsetBy: "Click ".count)...])
            self = MembershipCase(rawValue: rawValueWithoutPrefix) ?? .none
        } else if decodedValue.hasPrefix("Snap ") {
            let rawValueWithoutPrefix = String(decodedValue[decodedValue.index(decodedValue.startIndex, offsetBy: "Snap ".count)...])
            self = MembershipCase(rawValue: rawValueWithoutPrefix) ?? .none
        } else {
            self = MembershipCase(rawValue: decodedValue) ?? .none
        }
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
            .commonPageTag,
        ]
    }

    static func caseValidFor(hub: String?, _ value: TagSourceCase) -> Bool {
        return casesFor(hub: hub).contains(value)
    }
}

enum StaffLevelCase: String, CaseIterable, Identifiable, Codable {
    case mod = "Mod"
    case coadmin = "Co-Admin"
    case admin = "Admin"

    // snap
    case snapGuestMod = "Guest moderator"

    var id: Self { self }

    static func casesFor(hub: String?) -> [StaffLevelCase] {
        if hub == "snap" {
            return [
                .mod,
                .coadmin,
                .admin,
                .snapGuestMod,
            ]
        }
        if hub == "click" {
            return [
                .mod,
                .coadmin,
                .admin,
            ]
        }
        return [
            .mod,
            .coadmin,
            .admin,
        ]
    }

    static func caseValidFor(hub: String?, _ value: StaffLevelCase) -> Bool {
        return casesFor(hub: hub).contains(value)
    }
}

enum PlaceholderSheetCase {
    case featureScript
    case commentScript
    case originalPostScript
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
            .none,
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
        return casesFor(hub: hub).contains(value)
    }

    func scriptNewMembershipStringForHub(hub: String?) -> String {
        (hub == "snap" && self != .none) ? "Snap \(rawValue)"
            : (hub == "click" && self != .none) ? "Click \(rawValue)"
            : rawValue
    }
}

enum TinEyeResults: String, CaseIterable, Identifiable, Codable {
    case zeroMatches = "0 matches"
    case noMatches = "no matches"
    case matchFound = "matches found"

    var id: Self { self }
}

enum AiCheckResults: String, CaseIterable, Identifiable, Codable {
    case human
    case ai

    var id: Self { self }
}

struct ScriptsCatalog: Codable {
    var hubs: [String: [Page]]
}

struct Page: Codable {
    var id: String { name }
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

struct TemplateCatalog: Codable {
    let pages: [TemplatePage]
    let specialTemplates: [Template]
}

struct TemplatePage: Codable, Identifiable {
    var id: String { name }
    let name: String
    let templates: [Template]
}

struct HubCatalog: Codable {
    let hubs: [Hub]
}

struct Hub: Codable, Identifiable {
    var id: String { name }
    let name: String
    let templates: [Template]
}

struct Template: Codable, Identifiable {
    var id: String { name }
    let name: String
    let template: String
}

struct LoadedCatalogs {
    var waitingForPages = true
    var loadedPages = [ObservablePage]()
    var waitingForTemplates = true
    var templatesCatalog = TemplateCatalog(pages: [], specialTemplates: [])
    var waitingForDisallowList = true
    var disallowLists = [String: [String]]()
    var cautionLists = [String: [String]]()
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
