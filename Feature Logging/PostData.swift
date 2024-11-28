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
//    let actionData: JSONNull?
//    let errors: JSONNull?
}

// MARK: - LoaderData
struct LoaderData: Codable {
    let index0: LoaderEntry?
//    let root: JSONNull?

    enum CodingKeys: String, CodingKey {
        case index0 = "0-1"
//        case root
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
//    let embeddedMode: Bool?
//    let posts: [PostElement]?
}

// MARK: - PostElement
//struct PostElement: Codable {
//    let id: String?
//    let time: Int?
//    let action: String?
//    let object: String?
//    let author: Author?
//    let title: String?
//    let caption: [PurpleCaption]?
//    let nsfwPost: Bool?
//    let loop: String?
//    let url: String?
//    let images: [PostImage]?
//    let likes: Int?
//    let comments: Int?
//    let views: Int?
//    let timestamp: String?
//    let language: String?
//    
//    enum CodingKeys: String, CodingKey {
//        case id, time, action, object, author, title, caption
//        case nsfwPost = "nsfw_post"
//        case loop, url, images, likes, comments, views, timestamp, language
//    }
//}

// MARK: - PurpleCaption
//struct PurpleCaption: Codable {
//    let type: String?
//    let value: String?
//    let label: String?
//    let id: String?
//    let url: String?
//}

// MARK: - Profile
struct Profile: Codable {
//    let browsable: Bool?
//    let id: String?
    let firstname: String?
    let lastname: String?
    let picture: Picture?
//    let connectable: Bool?
    let username: String?
    let bio: String?
//    let bioLang: String?
    let url: String?
//    let followable: Bool?
//    let followers: Int?
//    let leads: Int?
//    let connectionsCount: Int?
//    let shorturl: String?
    
    enum CodingKeys: String, CodingKey {
//        case browsable
//        case id
        case firstname
        case lastname
        case picture
//        case connectable
        case username
        case bio
//        case bioLang = "bio_lang"
        case url
//        case followable
//        case followers
//        case leads
//        case connectionsCount = "connections_count"
//        case shorturl
    }
}


// MARK: - LoaderEntryPost
struct LoaderEntryPost: Codable {
    let post: Post?
    let comments: [Comment]?
//    let embeddedMode: Bool?
}

// MARK: - Comment
struct Comment: Codable {
//    let id: String?
    let text: String?
    let timestamp: String?
    let author: Author?
//    let content: [Content]?
//    let repliedByAuthor: Bool?

    enum CodingKeys: String, CodingKey {
//        case id
        case text
        case timestamp
        case author
//        case content
//        case repliedByAuthor = "replied_by_author"
    }
}

// MARK: - Author
struct Author: Codable {
//    let id: String?
    let firstname: String?
    let lastname: String?
    let username: String?
    let picture: Picture?
//    let connectable: Bool?
//    let verified: Bool?
//    let followable: Bool?
//    let following: Bool?
//    let follower: Bool?
    let url: String?
}

// MARK: - Picture
struct Picture: Codable {
//    let thumbnail: String?
    let url: String?
}

// MARK: - Content
//struct Content: Codable {
//    let type: String?
//    let value: String?
//    let label: String?
//    let id: String?
//    let url: String?
//}

// MARK: - Post
struct Post: Codable {
//    let id: String?
//    let time: Int?
//    let action: String?
//    let object: String?
    let author: Author?
//    let title: String?
    let caption: [Caption]?
//    let nsfwPost: Bool?
//    let loop: String?
    let url: String?
    let images: [PostImage]?
    let likes: Int?
    let comments: Int?
//    let views: Int?
//    let timestamp: String?

    enum CodingKeys: String, CodingKey {
//        case id
//        case time
//        case action
//        case object
        case author
//        case title
        case caption
//        case nsfwPost = "nsfw_post"
//        case loop
        case url
        case images
        case likes
        case comments
//        case views
//        case timestamp
    }
}

// MARK: - Caption
struct Caption: Codable {
    let type: String? // text or tag
    let value: String?
}

// MARK: - PostImage
struct PostImage: Codable {
    let url: String?
//    let width: Int?
//    let height: Int?
//    let thumbnail: String?
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
