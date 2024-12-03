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
    
    func print() {
        Swift.print("loaderData")
        loaderData?.print(1)
    }
}

// MARK: - LoaderData
struct LoaderData: Codable {
    let entry0: LoaderEntry?
    
    enum CodingKeys: String, CodingKey {
        case entry0 = "0-1"
    }
    
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)entry[0]")
        entry0?.print(indent + 1);
    }
}

// MARK: - LoaderEntry
struct LoaderEntry: Codable {
    let profile: LoaderEntryProfile?
    let post: LoaderEntryPost?
    
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)profile")
        profile?.print(indent + 1);
        Swift.print("\("   " * indent)post")
        post?.print(indent + 1);
    }
}

// MARK: - LoaderEntryProfile
struct LoaderEntryProfile: Codable {
    let profile: Profile?
    
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)profile")
        profile?.print(indent + 1);
    }
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
    
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)id = \(id ?? "nil")")
        Swift.print("\("   " * indent)name = \(name ?? "nil")")
        Swift.print("\("   " * indent)picture")
        picture?.print(indent + 1);
        Swift.print("\("   " * indent)username = \(username ?? "nil")")
        Swift.print("\("   " * indent)bio = \(bio ?? "nil")")
        Swift.print("\("   " * indent)url = \(url ?? "nil")")
    }
}

// MARK: - LoaderEntryPost
struct LoaderEntryPost: Codable {
    let post: Post?
    let comments: [Comment]?
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)post")
        post?.print(indent + 1);
        for (index, comment) in (comments ?? []).enumerated() {
            Swift.print("\("   " * indent)comment[\(index)]")
            comment.print(indent + 1)
        }
    }
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
    
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)id = \(id ?? "nil")")
        Swift.print("\("   " * indent)text = \(text ?? "nil")")
        Swift.print("\("   " * indent)timestamp = \(timestamp ?? "nil")")
        Swift.print("\("   " * indent)author")
        author?.print(indent + 1)
        for (index, segment) in (content ?? []).enumerated() {
            Swift.print("\("   " * indent)content[\(index)]")
            segment.print(indent + 1)
        }
    }
}

// MARK: - Picture
struct Picture: Codable {
    let url: String?

    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)url = \(url ?? "nil")")
    }
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
    
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)id = \(id ?? "nil")")
        Swift.print("\("   " * indent)author")
        author?.print(indent + 1);
        Swift.print("\("   " * indent)title = \(title ?? "nil")")
        for (index, segment) in (caption ?? []).enumerated() {
            Swift.print("\("   " * indent)caption[\(index)]")
            segment.print(indent + 1)
        }
        Swift.print("\("   " * indent)url = \(url ?? "nil")")
        for (index, image) in (images ?? []).enumerated() {
            Swift.print("\("   " * indent)image[\(index)]")
            image.print(indent + 1)
        }
        Swift.print("\("   " * indent)likes = \(likes ?? 0)")
        Swift.print("\("   " * indent)comments = \(comments ?? 0)")
        Swift.print("\("   " * indent)timestamp = \(timestamp ?? "nil")")
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
    
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)id = \(id ?? "nil")")
        Swift.print("\("   " * indent)name = \(name ?? "nil")")
        Swift.print("\("   " * indent)picture")
        picture?.print(indent + 1);
        Swift.print("\("   " * indent)username = \(username ?? "nil")")
        Swift.print("\("   " * indent)url = \(url ?? "nil")")
    }
}

// MARK: - Segment
struct Segment: Codable {
    let type: String? // [text, tag, person, url]
    let value: String?
    let label: String?
    let id: String?
    let url: String?

    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)type = \(type ?? "nil")")
        if type == "text" {
            Swift.print("\("   " * indent)value = \(value ?? "nil")")
        } else if type == "tag" {
            Swift.print("\("   " * indent)value = \(value ?? "nil")")
        } else if type == "person" {
            Swift.print("\("   " * indent)label = \(label ?? "nil")")
            Swift.print("\("   " * indent)id = \(id ?? "nil")")
            Swift.print("\("   " * indent)url = \(url ?? "nil")")
        } else if type == "url" {
            Swift.print("\("   " * indent)value = \(value ?? "nil")")
            Swift.print("\("   " * indent)label = \(label ?? "nil")")
        } else {
            Swift.print("\("   " * indent)value = \(value ?? "nil")")
            Swift.print("\("   " * indent)label = \(label ?? "nil")")
            Swift.print("\("   " * indent)id = \(id ?? "nil")")
            Swift.print("\("   " * indent)url = \(url ?? "nil")")
        }
    }
}

// MARK: - PostImage
struct PostImage: Codable {
    let url: String?
    
    fileprivate func print(_ indent: Int) {
        Swift.print("\("   " * indent)url = \(url ?? "nil")")
    }
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
