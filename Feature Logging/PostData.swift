//
//  PostData.swift
//  Feature Logging
//
//  Created by Andrew Forget on 2024-11-27.
//

import Foundation
import SwiftUI

// MARK: - PostData
struct PostData: Codable {
    let loaderData: LoaderData?
}

// MARK: - LoaderData
struct LoaderData: Codable {
    let entry0: LoaderEntry?
    
    enum CodingKeys: String, CodingKey {
        case entry0 = "0-1"
    }
}

// MARK: - LoaderEntry
struct LoaderEntry: Codable {
    let profile: LoaderEntryProfile?
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
