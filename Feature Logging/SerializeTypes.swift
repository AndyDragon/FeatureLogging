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

    init(feature: ObservableFeature) {
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
        self.page = try container.decode(String.self, forKey: .page)
        self.features = try container.decode([LogFeature].self, forKey: .features)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(page, forKey: .page)
        try container.encode(features, forKey: .features)
    }

    func getFeatures() -> [ObservableFeature] {
        var featuresFromLog = [ObservableFeature]()
        for logFeature in features {
            let feature = ObservableFeature()
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
