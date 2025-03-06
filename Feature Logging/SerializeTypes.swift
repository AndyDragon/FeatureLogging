//
//  SerializeTypes.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-12-17.
//

import SwiftUI
import UniformTypeIdentifiers

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
    var userHasFeaturesOnHub: Bool
    var lastFeaturedOnHub: String
    var lastFeaturedPage: String
    var featureCountOnHub: String
    var tooSoonToFeatureUser: Bool
    var tinEyeResults: TinEyeResults
    var aiCheckResults: AiCheckResults
    var personalMessage: String
    var userLevelString: String? = nil
    var pageFeatureCount: String? = nil
    var rawPageFeatureCount: String? = nil
    var hubFeatureCount: String? = nil
    var rawHubFeatureCount: String? = nil

    init(feature: ObservableFeature) {
        isPicked = feature.isPicked
        postLink = feature.postLink
        userName = feature.userName
        userAlias = feature.userAlias
        userLevel = feature.userLevel
        userIsTeammate = feature.userIsTeammate
        tagSource = feature.tagSource
        photoFeaturedOnPage = feature.photoFeaturedOnPage
        photoFeaturedOnHub = feature.photoFeaturedOnHub
        photoLastFeaturedOnHub = feature.photoLastFeaturedOnHub
        photoLastFeaturedPage = feature.photoLastFeaturedPage
        featureDescription = feature.featureDescription
        userHasFeaturesOnPage = feature.userHasFeaturesOnPage
        lastFeaturedOnPage = feature.lastFeaturedOnPage
        featureCountOnPage = feature.featureCountOnPage
        userHasFeaturesOnHub = feature.userHasFeaturesOnHub
        lastFeaturedOnHub = feature.lastFeaturedOnHub
        lastFeaturedPage = feature.lastFeaturedPage
        featureCountOnHub = feature.featureCountOnHub
        tooSoonToFeatureUser = feature.tooSoonToFeatureUser
        tinEyeResults = feature.tinEyeResults
        aiCheckResults = feature.aiCheckResults
        personalMessage = feature.personalMessage
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
        case featureCountOnRawPage // Obsolete
        case userHasFeaturesOnHub
        case lastFeaturedOnHub
        case lastFeaturedPage
        case featureCountOnHub
        case featureCountOnRawHub // Obsolete
        case tooSoonToFeatureUser
        case tinEyeResults
        case aiCheckResults
        case personalMessage
    }

    static func collateRawFeatureCount(_ featureCount: String, _ rawFeatureCount: String) -> String {
        if featureCount == "many" || rawFeatureCount == "many" {
            return "many"
        }
        if rawFeatureCount == "0" {
            return featureCount
        }
        let count = Int(featureCount) ?? 0
        let rawCount = Int(rawFeatureCount) ?? 0
        return "\(count + rawCount)"
    }

    static func clipFeatureCount(_ hub: String, _ featureCount: String) -> String {
        if featureCount == "many" || featureCount == "0" {
            return featureCount
        }
        let featureCountValue = Int(featureCount) ?? 0
        switch hub {
        case "snap":
            if featureCountValue > 20 {
                return "many"
            }
        case "click":
            if featureCountValue > 75 {
                return "many"
            }
        default:
            if featureCountValue > 50 {
                return "many"
            }
        }
        return featureCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isPicked = try container.decode(Bool.self, forKey: .isPicked)
        postLink = try container.decode(String.self, forKey: .postLink)
        userName = try container.decode(String.self, forKey: .userName)
        userAlias = try container.decode(String.self, forKey: .userAlias)
        userLevel = try container.decode(MembershipCase.self, forKey: .userLevel)
        if userLevel == .none {
            userLevelString = try container.decode(String.self, forKey: .userLevel)
        }
        userIsTeammate = try container.decode(Bool.self, forKey: .userIsTeammate)
        tagSource = try container.decode(TagSourceCase.self, forKey: .tagSource)
        photoFeaturedOnPage = try container.decode(Bool.self, forKey: .photoFeaturedOnPage)
        photoFeaturedOnHub = try container.decodeIfPresent(Bool.self, forKey: .photoFeaturedOnHub) ?? false
        photoLastFeaturedOnHub = try container.decodeIfPresent(String.self, forKey: .photoLastFeaturedOnHub) ?? ""
        photoLastFeaturedPage = try container.decodeIfPresent(String.self, forKey: .photoLastFeaturedPage) ?? ""
        featureDescription = try container.decode(String.self, forKey: .featureDescription)
        userHasFeaturesOnPage = try container.decode(Bool.self, forKey: .userHasFeaturesOnPage)
        lastFeaturedOnPage = try container.decode(String.self, forKey: .lastFeaturedOnPage)
        pageFeatureCount = try container.decode(String.self, forKey: .featureCountOnPage)
        rawPageFeatureCount = try container.decodeIfPresent(String.self, forKey: .featureCountOnRawPage)
        if rawPageFeatureCount == nil, let pageFeatureCount {
            featureCountOnPage = Self.collateRawFeatureCount(pageFeatureCount, "0")
        } else {
            featureCountOnPage = "many"
        }
        userHasFeaturesOnHub = try container.decode(Bool.self, forKey: .userHasFeaturesOnHub)
        lastFeaturedOnHub = try container.decode(String.self, forKey: .lastFeaturedOnHub)
        lastFeaturedPage = try container.decode(String.self, forKey: .lastFeaturedPage)
        hubFeatureCount = try container.decode(String.self, forKey: .featureCountOnHub)
        rawHubFeatureCount = try container.decodeIfPresent(String.self, forKey: .featureCountOnRawHub)
        if rawHubFeatureCount == nil, let hubFeatureCount {
            featureCountOnHub = Self.collateRawFeatureCount(hubFeatureCount, "0")
        } else {
            featureCountOnHub = "many"
        }
        tooSoonToFeatureUser = try container.decode(Bool.self, forKey: .tooSoonToFeatureUser)
        tinEyeResults = try container.decode(TinEyeResults.self, forKey: .tinEyeResults)
        aiCheckResults = try container.decode(AiCheckResults.self, forKey: .aiCheckResults)
        personalMessage = try container.decodeIfPresent(String.self, forKey: .personalMessage) ?? ""
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
        try container.encode(userHasFeaturesOnHub, forKey: .userHasFeaturesOnHub)
        try container.encode(lastFeaturedOnHub, forKey: .lastFeaturedOnHub)
        try container.encode(lastFeaturedPage, forKey: .lastFeaturedPage)
        try container.encode(featureCountOnHub, forKey: .featureCountOnHub)
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

    init(page: ObservablePage, features: [ObservableFeature]) {
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
        page = try container.decode(String.self, forKey: .page)
        features = try container.decode([LogFeature].self, forKey: .features)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(page, forKey: .page)
        try container.encode(features, forKey: .features)
    }

    func getFeatures(_ hub: String) -> [ObservableFeature] {
        var featuresFromLog = [ObservableFeature]()
        for logFeature in features {
            let feature = ObservableFeature()
            feature.isPicked = logFeature.isPicked
            feature.postLink = logFeature.postLink
            feature.userName = logFeature.userName
            feature.userAlias = logFeature.userAlias
            feature.userLevel = logFeature.userLevel
            if feature.userLevel == .none, let userLevelString = logFeature.userLevelString {
                feature.userLevel = MembershipCase.mapFromString(page, userLevelString)
            }
            feature.userIsTeammate = logFeature.userIsTeammate
            feature.tagSource = logFeature.tagSource
            feature.photoFeaturedOnPage = logFeature.photoFeaturedOnPage
            feature.photoFeaturedOnHub = logFeature.photoFeaturedOnHub
            feature.photoLastFeaturedOnHub = logFeature.photoLastFeaturedOnHub
            feature.photoLastFeaturedPage = logFeature.photoLastFeaturedPage
            feature.featureDescription = logFeature.featureDescription
            feature.userHasFeaturesOnPage = logFeature.userHasFeaturesOnPage
            feature.lastFeaturedOnPage = logFeature.lastFeaturedOnPage
            if let pageFeatureCount = logFeature.pageFeatureCount, let rawPageFeatureCount = logFeature.rawPageFeatureCount {
                feature.featureCountOnPage = LogFeature.clipFeatureCount(hub, LogFeature.collateRawFeatureCount(pageFeatureCount, hub == "snap" ? rawPageFeatureCount : "0"))
            } else {
                feature.featureCountOnPage = LogFeature.clipFeatureCount(hub, logFeature.featureCountOnPage)
            }
            feature.userHasFeaturesOnHub = logFeature.userHasFeaturesOnHub
            feature.lastFeaturedOnHub = logFeature.lastFeaturedOnHub
            feature.lastFeaturedPage = logFeature.lastFeaturedPage
            if let hubFeatureCount = logFeature.hubFeatureCount, let rawHubFeatureCount = logFeature.rawHubFeatureCount {
                feature.featureCountOnHub = LogFeature.clipFeatureCount(hub, LogFeature.collateRawFeatureCount(hubFeatureCount, hub == "snap" ? rawHubFeatureCount : "0"))
            } else {
                feature.featureCountOnHub = LogFeature.clipFeatureCount(hub, logFeature.featureCountOnHub)
            }
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

    init(page: ObservablePage, features: [ObservableFeature]) {
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
