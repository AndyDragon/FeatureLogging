//
//  PostData.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-27.
//

import Foundation
import SwiftUI

// MARK: - Old data (Codable)

// MARK: - PostData

struct PostData: Codable {
    let loaderData: LoaderData?
}

struct PostData2: Codable {
    let loaderData: LoaderData2?
}

// MARK: - LoaderData

struct LoaderData: Codable {
    let entry1: LoaderEntry?
    let entry2: LoaderEntry?
    let entry3: LoaderEntry?
    let entry4: LoaderEntry?
    let entry5: LoaderEntry?

    var entry: LoaderEntry? {
        entry1 ?? entry2 ?? entry3 ?? entry4 ?? entry5
    }

    enum CodingKeys: String, CodingKey {
        case entry1 = "0-1"
        case entry2 = "0-2"
        case entry3 = "0-3"
        case entry4 = "0-4"
        case entry5 = "0-5"
    }
}

struct LoaderData2: Codable {
    let entry1: LoaderEntry2?
    let entry2: LoaderEntry2?
    let entry3: LoaderEntry2?
    let entry4: LoaderEntry2?
    let entry5: LoaderEntry2?

    var entry: LoaderEntry2? {
        entry1 ?? entry2 ?? entry3 ?? entry4 ?? entry5
    }

    enum CodingKeys: String, CodingKey {
        case entry1 = "0-1"
        case entry2 = "0-2"
        case entry3 = "0-3"
        case entry4 = "0-4"
        case entry5 = "0-5"
    }
}

// MARK: - LoaderEntry

struct LoaderEntry: Codable {
    let profile: LoaderEntryProfile?
    let post: LoaderEntryPost?
}

struct LoaderEntry2: Codable {
    let profile: Profile?
    let post: LoaderEntryPost?
}

// MARK: - LoaderEntryProfile

struct LoaderEntryProfile: Codable {
    let profile: Profile?
}

// MARK: - Profile

struct Profile: Codable {
    let id: String?
    let name: String?
    let picture: Picture?
    let username: String?
    let bio: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name = "firstname"
        case picture
        case username
        case bio
        case url
    }
}

// MARK: - LoaderEntryPost

struct LoaderEntryPost: Codable {
    let post: Post?
    let comments: [Comment]?
}

// MARK: - Comment

struct Comment: Codable {
    let id: String?
    let text: String?
    let timestamp: String?
    let author: Author?
    let content: [Segment]?

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case timestamp
        case author
        case content
    }
}

// MARK: - Picture

struct Picture: Codable {
    let url: String?
}

// MARK: - Post

struct Post: Codable {
    let id: String?
    let author: Author?
    let title: String?
    let caption: [Segment]?
    let url: String?
    let images: [PostImage]?
    let likes: Int?
    let comments: Int?
    let timestamp: String?

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case title
        case caption
        case url
        case images
        case likes
        case comments
        case timestamp
    }
}

// MARK: - Author

struct Author: Codable {
    let id: String?
    let name: String?
    let picture: Picture?
    let username: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name = "firstname"
        case username
        case picture
        case url
    }
}

// MARK: - Segment

struct Segment: Codable {
    let type: String? // [text, tag, person, url]
    let value: String?
    let label: String?
    let id: String?
    let url: String?
}

// MARK: - PostImage

struct PostImage: Codable {
    let url: String?
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {
    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public init() {}

    public func hash(into hasher: inout Hasher) {
        // No-op
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

func joinSegments(_ segments: [Segment]?) -> String {
    var ignored: [String] = []
    return joinSegments(segments, &ignored)
}

func joinSegments(_ segments: [Segment]?, _ hashTags: inout [String]) -> String {
    var result = ""
    if segments == nil {
        return result
    }
    for segment in segments! {
        switch segment.type {
        case "text":
            result = result + segment.value!
        case "tag":
            result = result + "#\(segment.value!)"
            hashTags.append("#\(segment.value!)")
        case "person":
            if let label = segment.label {
                result = result + "@\(label)"
            } else {
                result = result + segment.value!
            }
        case "url":
            if let label = segment.label {
                result = result + label
            } else {
                result = result + segment.value!
            }
        default:
            debugPrint("Unhandled segment type: \(segment.type!)")
        }
    }
    return result.replacingOccurrences(of: "\\n", with: "\n")
}

// MARK: - New data (React index object parser)

class ReactIndexObject {
    private(set) var properties: [String: Any] = [:]

    init() {}

    init(reactData: [Any], indices: Any) {
        loadIndices(reactData: reactData, indices: indices)
    }

    func loadIndices(reactData: [Any], indices: Any) {
        guard let indexMap = indices as? [String: Any] else { return }

        for (name, indexValue) in indexMap {
            guard name.hasPrefix("_") else {
                fatalError("Dynamic property name index malformed")
            }

            let keyIndexString = String(name.dropFirst())
            guard let keyIndex = Int(keyIndexString), keyIndex >= 0, keyIndex < reactData.count else {
                continue
            }

            guard let propertyName = reactData[keyIndex] as? String else {
                continue
            }

            guard let valueIndex = asInt(indexValue) else {
                continue
            }

            if valueIndex == -5 {
                properties[propertyName] = NSNull()
            } else if valueIndex >= 0 && valueIndex < reactData.count {
                let propertyValue = reactData[valueIndex]
                if let arrayValue = propertyValue as? [Any] {
                    properties[propertyName] = arrayValue
                } else {
                    properties[propertyName] = propertyValue
                }
            }
        }
    }

    func hasProperty(_ propertyName: String, treatNullAsMissing: Bool = false) -> Bool {
        guard let value = properties[propertyName] else { return false }
        if treatNullAsMissing {
            return !(value is NSNull)
        }
        return true
    }

    func getProperty<T>(_ propertyName: String, _ defaultValue: T) -> T {
        guard let raw = properties[propertyName], !(raw is NSNull) else {
            return defaultValue
        }

        if let cast = raw as? T {
            return cast
        }

        if T.self == Int.self, let value = asInt(raw) {
            return value as! T
        }

        if T.self == Int64.self, let value = asInt64(raw) {
            return value as! T
        }

        if T.self == Double.self, let value = asDouble(raw) {
            return value as! T
        }

        if T.self == Bool.self, let value = asBool(raw) {
            return value as! T
        }

        if T.self == Date.self, let value = asDate(raw) {
            return value as! T
        }

        return defaultValue
    }

    func getAnyProperty(_ propertyName: String) -> Any? {
        guard let raw = properties[propertyName], !(raw is NSNull) else {
            return nil
        }
        return raw
    }

    func asInt(_ value: Any) -> Int? {
        if let intValue = value as? Int { return intValue }
        if let int64Value = value as? Int64 { return Int(int64Value) }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String, let parsed = Int(string) { return parsed }
        return nil
    }

    func asInt64(_ value: Any) -> Int64? {
        if let int64Value = value as? Int64 { return int64Value }
        if let intValue = value as? Int { return Int64(intValue) }
        if let number = value as? NSNumber { return number.int64Value }
        if let string = value as? String, let parsed = Int64(string) { return parsed }
        return nil
    }

    func asDouble(_ value: Any) -> Double? {
        if let doubleValue = value as? Double { return doubleValue }
        if let floatValue = value as? Float { return Double(floatValue) }
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String, let parsed = Double(string) { return parsed }
        return nil
    }

    func asBool(_ value: Any) -> Bool? {
        if let boolValue = value as? Bool { return boolValue }
        if let number = value as? NSNumber { return number.boolValue }
        if let string = value as? String {
            switch string.lowercased() {
            case "true", "1", "yes": return true
            case "false", "0", "no": return false
            default: return nil
            }
        }
        return nil
    }

    func asDate(_ value: Any) -> Date? {
        if let dateValue = value as? Date { return dateValue }
        if let number = value as? NSNumber { return Date(timeIntervalSince1970: number.doubleValue) }
        if let string = value as? String {
            let iso8601 = ISO8601DateFormatter()
            if let parsed = iso8601.date(from: string) {
                return parsed
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let parsed = formatter.date(from: string) {
                return parsed
            }
        }
        return nil
    }

    // Debug placeholders to keep a 1:1 shape with the C# model.
    func dump(_ name: String, excludes: [String] = [], skipUnhandled: Bool = false) {}
    func dumpValue(_ property: String, _ value: Any) {}
    func resetIndent() {}
    func indent() {}
    func unindent() {}

    var name: String { "" }
    var knownRawProperties: Set<String> { [] }

    func unknownRawPropertyNames() -> [String] {
        properties.keys
            .filter { !knownRawProperties.contains($0) }
            .sorted()
    }
}

final class ReactData: ReactIndexObject {
    var loaderData: ReactLoaderData?
    var actionData: ReactActionData?
    var errors: ReactErrors?

    override var name: String { "Global" }
    override var knownRawProperties: Set<String> { ["loaderData", "actionData", "errors"] }

    init(reactData: [Any]) {
        super.init(reactData: reactData, indices: reactData[0])
        loaderData = hasProperty("loaderData") ? ReactLoaderData(reactData: reactData, indices: getAnyProperty("loaderData") as Any) : nil
        actionData = hasProperty("actionData", treatNullAsMissing: true) ? ReactActionData(reactData: reactData, indices: getAnyProperty("actionData") as Any) : nil
        errors = hasProperty("errors", treatNullAsMissing: true) ? ReactErrors(reactData: reactData, indices: getAnyProperty("errors") as Any) : nil
    }
}

final class ReactLoaderData: ReactIndexObject {
    var root: ReactRoot?
    var userPost: ReactUserPost?
    var postOnly: ReactPostOnly?

    override var name: String { "loaderData" }
    override var knownRawProperties: Set<String> { ["root", "user-post", "post-only"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
        root = hasProperty("root") ? ReactRoot(reactData: reactData, indices: getAnyProperty("root") as Any) : nil
        userPost = hasProperty("user-post") ? ReactUserPost(reactData: reactData, indices: getAnyProperty("user-post") as Any) : nil
        postOnly = hasProperty("post-only") ? ReactPostOnly(reactData: reactData, indices: getAnyProperty("post-only") as Any) : nil
    }
}

final class ReactRoot: ReactIndexObject {
    var config: ReactConfig?
    var systemInformation: ReactSystemInformation?

    override var name: String { "root" }
    override var knownRawProperties: Set<String> { ["config", "systemInformation"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
        config = hasProperty("config") ? ReactConfig(reactData: reactData, indices: getAnyProperty("config") as Any) : nil
        systemInformation = hasProperty("systemInformation") ? ReactSystemInformation(reactData: reactData, indices: getAnyProperty("systemInformation") as Any) : nil
    }
}

final class ReactConfig: ReactIndexObject {
    override var name: String { "config" }
    override var knownRawProperties: Set<String> {
        [
            "CLIENT_API_URL", "CHAKRAY_API_URL", "USER_STORAGE_API_URL", "WEBVIEWS_URL", "VERO_WEBAPP_URL", "SLEEVE_WEBAPP_URL", "ITUNES_URL",
            "TMDB_URL", "APPLE_MUSIC_URL", "FEATURE_FLAG_WEBAPP", "FEATURE_FLAG_WIDGETS", "FEATURE_FLAG_COMMUNITY_TAGS", "FEATURE_FLAG_NSFW",
            "FEATURE_FLAG_VERO_3_CREATORS", "GROWTHBOOK_CLIENT_ID", "SPREECOMMERCE_API_URL", "VERO_FEATURED_API_URL", "VERO_VAULT_API_URL"
        ]
    }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
    }

    var clientApiUrl: String { getProperty("CLIENT_API_URL", "") }
    var chakrayApiUrl: String { getProperty("CHAKRAY_API_URL", "") }
    var userStorageApiUrl: String { getProperty("USER_STORAGE_API_URL", "") }
    var webViewsUrl: String { getProperty("WEBVIEWS_URL", "") }
    var veroWebAppUrl: String { getProperty("VERO_WEBAPP_URL", "") }
    var sleeveWebAppUrl: String { getProperty("SLEEVE_WEBAPP_URL", "") }
    var iTunesUrl: String { getProperty("ITUNES_URL", "") }
    var theMovieDBUrl: String { getProperty("TMDB_URL", "") }
    var appleMusicUrl: String { getProperty("APPLE_MUSIC_URL", "") }
    var webApp: Bool { getProperty("FEATURE_FLAG_WEBAPP", false) }
    var widgets: Bool { getProperty("FEATURE_FLAG_WIDGETS", false) }
    var communityTags: Bool { getProperty("FEATURE_FLAG_COMMUNITY_TAGS", false) }
    var nsfw: Bool { getProperty("FEATURE_FLAG_NSFW", false) }
    var vero3Creators: Bool { getProperty("FEATURE_FLAG_VERO_3_CREATORS", false) }
    var growthBookClientId: String { getProperty("GROWTHBOOK_CLIENT_ID", "") }
    var spreeCommerceApiUrl: String { getProperty("SPREECOMMERCE_API_URL", "") }
    var veroFeaturedApiUrl: String { getProperty("VERO_FEATURED_API_URL", "") }
    var veroVaultApiUrl: String { getProperty("VERO_VAULT_API_URL", "") }
}

final class ReactSystemInformation: ReactIndexObject {
    override var name: String { "systemInformation" }
    override var knownRawProperties: Set<String> { ["preferredLanguage", "isMobileDevice", "userAgent", "osName"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
    }

    var preferredLanguage: String { getProperty("preferredLanguage", "") }
    var isMobileDevice: Bool { getProperty("isMobileDevice", false) }
    var userAgent: String { getProperty("userAgent", "") }
    var osName: String { getProperty("osName", "") }
}

final class ReactUserPost: ReactIndexObject {
    var profile: ReactProfile?
    var post: ReactPost?
    var communityTagsOverview: [ReactCommunityTagsOverview] = []
    var dehydratedQueryClient: ReactDehydratedQueryClient?

    override var name: String { "user-post" }
    override var knownRawProperties: Set<String> { ["profile", "post", "communityTagsOverview", "dehydratedQueryClient"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)

        var tags: [ReactCommunityTagsOverview] = []
        if let indexes = getAnyProperty("communityTagsOverview") as? [Any] {
            for index in indexes {
                if let objectIndex = asInt(index) {
                    tags.append(ReactCommunityTagsOverview(reactData: reactData, objectIndex: objectIndex))
                }
            }
        }
        communityTagsOverview = tags

        dehydratedQueryClient = hasProperty("dehydratedQueryClient") ? ReactDehydratedQueryClient(reactData: reactData, indices: getAnyProperty("dehydratedQueryClient") as Any) : nil
        profile = hasProperty("profile") ? ReactProfile(reactData: reactData, indices: getAnyProperty("profile") as Any) : nil
        post = hasProperty("post") ? ReactPost(reactData: reactData, indices: getAnyProperty("post") as Any) : nil
    }
}

final class ReactProfile: ReactIndexObject {
    var picture: ReactPicture?

    override var name: String { "profile" }
    override var knownRawProperties: Set<String> {
        ["picture", "browsable", "id", "firstname", "lastname", "connectable", "username", "bio", "bio_lang", "url", "followable", "followers", "connections_count", "leads", "shorturl", "verified"]
    }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
        picture = hasProperty("picture") ? ReactPicture(reactData: reactData, indices: getAnyProperty("picture") as Any) : nil
    }

    var browsable: Bool { getProperty("browsable", false) }
    var id: String { getProperty("id", "") }
    var firstName: String { getProperty("firstname", "") }
    var lastName: String { getProperty("lastname", "") }
    var connectable: Bool { getProperty("connectable", false) }
    var userName: String { getProperty("username", "") }
    var bio: String { getProperty("bio", "") }
    var bioLang: String { getProperty("bio_lang", "") }
    var followable: Bool { getProperty("followable", false) }
    var followers: Int64 { getProperty("followers", Int64(0)) }
    var connections: Int64 { getProperty("connections_count", Int64(0)) }
    var leads: Int64 { getProperty("leads", Int64(0)) }
    var shortUrl: String { getProperty("shorturl", "") }
    var url: String { getProperty("url", "") }
    var verified: Bool { getProperty("verified", false) }
}

final class ReactPicture: ReactIndexObject {
    override var name: String { "picture" }
    override var knownRawProperties: Set<String> { ["thumbnail", "url"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
    }

    var thumbnail: String { getProperty("thumbnail", "") }
    var url: String { getProperty("url", "") }
}

final class ReactPost: ReactIndexObject {
    var comments: [ReactComment] = []
    var post: ReactPostPost?

    override var name: String { "post" }
    override var knownRawProperties: Set<String> { ["comments", "post", "embeddedMode"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)

        var list: [ReactComment] = []
        if let indexes = getAnyProperty("comments") as? [Any] {
            for index in indexes {
                if let objectIndex = asInt(index) {
                    list.append(ReactComment(reactData: reactData, objectIndex: objectIndex))
                }
            }
        }
        comments = list

        post = hasProperty("post") ? ReactPostPost(reactData: reactData, indices: getAnyProperty("post") as Any) : nil
    }

    var embeddedMode: Bool { getProperty("embeddedMode", false) }
}

final class ReactComment: ReactIndexObject {
    var author: ReactAuthor?
    var content: [ReactContent] = []

    override var name: String { "comment" }
    override var knownRawProperties: Set<String> { ["id", "text", "timestamp", "author", "content", "replied_by_author", "language"] }

    init(reactData: [Any], objectIndex: Int) {
        super.init(reactData: reactData, indices: reactData[objectIndex])
        author = hasProperty("author") ? ReactAuthor(reactData: reactData, indices: getAnyProperty("author") as Any) : nil

        var list: [ReactContent] = []
        if let indexes = getAnyProperty("content") as? [Any] {
            for index in indexes {
                if let contentIndex = asInt(index) {
                    list.append(ReactContent(reactData: reactData, objectIndex: contentIndex))
                }
            }
        }
        content = list
    }

    var id: String { getProperty("id", "") }
    var text: String { getProperty("text", "") }
    var timestamp: Date { getProperty("timestamp", Date.distantPast) }
    var repliedByAuthor: Bool { getProperty("replied_by_author", false) }
    var language: String { getProperty("language", "") }
}

final class ReactScores: ReactIndexObject {
    override var name: String { "scores" }
    override var knownRawProperties: Set<String> { ["nsfw"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
    }

    var nsfw: Double { getProperty("nsfw", 0.0) }
}

final class ReactAuthor: ReactIndexObject {
    var picture: ReactPicture?

    override var name: String { "author" }
    override var knownRawProperties: Set<String> { ["id", "firstname", "username", "picture", "connectable", "verified", "followable", "following", "follower", "url"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
        picture = hasProperty("picture") ? ReactPicture(reactData: reactData, indices: getAnyProperty("picture") as Any) : nil
    }

    var id: String { getProperty("id", "") }
    var firstName: String { getProperty("firstname", "") }
    var userName: String { getProperty("username", "") }
    var connectable: Bool { getProperty("connectable", false) }
    var verified: Bool { getProperty("verified", false) }
    var followable: Bool { getProperty("followable", false) }
    var following: Bool { getProperty("following", false) }
    var follower: Bool { getProperty("follower", false) }
    var url: String { getProperty("url", "") }
}

final class ReactContent: ReactIndexObject {
    override var name: String { "content" }
    override var knownRawProperties: Set<String> { ["type", "value", "label", "id", "url"] }

    init(reactData: [Any], objectIndex: Int) {
        super.init(reactData: reactData, indices: reactData[objectIndex])
        validateProperties(allowedByType: [
            "text": ["value"],
            "tag": ["value"],
            "person": ["label", "id", "url"],
            "url": ["value", "label"]
        ])
    }

    private func validateProperties(allowedByType: [String: [String]]) {
        guard let allowed = allowedByType[type] else { return }
        for key in properties.keys {
            if key != "type" && !allowed.contains(key) {
                fatalError("Found unhandled property for type \(type)")
            }
        }
    }

    var type: String { getProperty("type", "") }
    var value: String { getProperty("value", "") }
    var label: String { getProperty("label", "") }
    var id: String { getProperty("id", "") }
    var url: String { getProperty("url", "") }
}

final class ReactPostPost: ReactIndexObject {
    var author: ReactAuthor?
    var caption: [ReactContent] = []
    var veroTags: [String] = []
    var images: [ReactImage] = []
    var scores: ReactScores?
    var attributes: ReactAttributes?

    override var name: String { "post" }
    override var knownRawProperties: Set<String> {
        [
            "id", "time", "action", "object", "author", "title", "caption", "nsfw_post", "effective_nsfw_post", "loop", "url", "veroTags", "images",
            "likes", "comments", "views", "featured", "timestamp", "scores", "attributes", "language"
        ]
    }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)

        author = hasProperty("author") ? ReactAuthor(reactData: reactData, indices: getAnyProperty("author") as Any) : nil

        var captionItems: [ReactContent] = []
        if let indexes = getAnyProperty("caption") as? [Any] {
            for index in indexes {
                if let contentIndex = asInt(index) {
                    captionItems.append(ReactContent(reactData: reactData, objectIndex: contentIndex))
                }
            }
        }
        caption = captionItems

        var tags: [String] = []
        if let indexes = getAnyProperty("veroTags") as? [Any] {
            for index in indexes {
                if let tagIndex = asInt(index), tagIndex >= 0, tagIndex < reactData.count,
                   let tag = reactData[tagIndex] as? String {
                    tags.append(tag)
                }
            }
        }
        veroTags = tags

        var imageItems: [ReactImage] = []
        if let indexes = getAnyProperty("images") as? [Any] {
            for index in indexes {
                if let imageIndex = asInt(index) {
                    imageItems.append(ReactImage(reactData: reactData, objectIndex: imageIndex))
                }
            }
        }
        images = imageItems

        scores = hasProperty("scores") ? ReactScores(reactData: reactData, indices: getAnyProperty("scores") as Any) : nil
        attributes = hasProperty("attributes") ? ReactAttributes(reactData: reactData, indices: getAnyProperty("attributes") as Any) : nil
    }

    var id: String { getProperty("id", "") }
    var time: Int64 { getProperty("time", Int64(0)) }
    var action: String { getProperty("action", "") }
    var object: String { getProperty("object", "") }
    var title: String { getProperty("title", "") }
    var nsfwPost: Bool { getProperty("nsfw_post", false) }
    var effectiveNsfwPost: Bool { getProperty("effective_nsfw_post", false) }
    var loop: String { getProperty("loop", "") }
    var url: String { getProperty("url", "") }
    var likes: Int64 { getProperty("likes", Int64(0)) }
    var comments: Int64 { getProperty("comments", Int64(0)) }
    var views: Int64 { getProperty("views", Int64(0)) }
    var featured: Bool { getProperty("featured", false) }
    var timestamp: Date { getProperty("timestamp", Date.distantPast) }
    var language: String { getProperty("language", "") }
}

final class ReactAttributes: ReactIndexObject {
    override var name: String { "attributes" }
    override var knownRawProperties: Set<String> { [] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
    }
}

final class ReactImage: ReactIndexObject {
    override var name: String { "image" }
    override var knownRawProperties: Set<String> { ["url", "width", "height", "thumbnail"] }

    init(reactData: [Any], objectIndex: Int) {
        super.init(reactData: reactData, indices: reactData[objectIndex])
    }

    var url: String { getProperty("url", "") }
    var width: Int64 { getProperty("width", Int64(0)) }
    var height: Int64 { getProperty("height", Int64(0)) }
    var thumbnail: String { getProperty("thumbnail", "") }
}

final class ReactPostOnly: ReactIndexObject {
    var post: ReactPost?
    var profile: ReactProfile?
    var dehydratedQueryClient: ReactDehydratedQueryClient?

    override var name: String { "post-only" }
    override var knownRawProperties: Set<String> { ["post", "profile", "dehydratedQueryClient"] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
        post = hasProperty("post") ? ReactPost(reactData: reactData, indices: getAnyProperty("post") as Any) : nil
        profile = hasProperty("profile") ? ReactProfile(reactData: reactData, indices: getAnyProperty("profile") as Any) : nil
        dehydratedQueryClient = hasProperty("dehydratedQueryClient") ? ReactDehydratedQueryClient(reactData: reactData, indices: getAnyProperty("dehydratedQueryClient") as Any) : nil
    }
}

final class ReactCommunityTagsOverview: ReactIndexObject {
    override var name: String { "communityTagsOverview" }
    override var knownRawProperties: Set<String> { ["tagId", "tagName"] }

    init(reactData: [Any], objectIndex: Int) {
        super.init(reactData: reactData, indices: reactData[objectIndex])
    }

    var tagId: String { getProperty("tagId", "") }
    var tagName: String { getProperty("tagName", "") }
}

final class ReactDehydratedQueryClient: ReactIndexObject {
    override var name: String { "dehydratedQueryClient" }
    override var knownRawProperties: Set<String> { [] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
    }
}

final class ReactActionData: ReactIndexObject {
    override var name: String { "actionData" }
    override var knownRawProperties: Set<String> { [] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
    }
}

final class ReactErrors: ReactIndexObject {
    override var name: String { "errors" }
    override var knownRawProperties: Set<String> { [] }

    override init(reactData: [Any], indices: Any) {
        super.init(reactData: reactData, indices: indices)
    }
}
