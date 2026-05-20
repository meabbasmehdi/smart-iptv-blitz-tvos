import Foundation

struct LiveTVCategory: Identifiable, Equatable {
    let id: String
    let title: String
    let count: Int
}

struct LiveTVChannel: Identifiable, Equatable {
    let id: Int
    let title: String
    let categoryID: String
    let categoryTitle: String
    let streamID: String?
    let streamIcon: String?
    let directSource: String?

    var imageURL: URL? {
        guard let streamIcon, !streamIcon.isEmpty else { return nil }
        return URL(string: streamIcon)
    }
}

struct LiveTVContent {
    let categories: [LiveTVCategory]
    let channels: [LiveTVChannel]
}

struct DefaultPlaylistStreamListResponse: Decodable {
    let success: Bool
    let data: [DefaultPlaylistStreamResponse]?
    let message: String?
    let pagesEmitted: Int?
    let nextPageToEmit: Int?
    let pageNum: Int?
    let totalCount: Int?

    enum CodingKeys: String, CodingKey {
        case success
        case data
        case message
        case pagesEmitted = "pages_emitted"
        case nextPageToEmit = "next_page_to_emit"
        case pageNum = "page_num"
        case totalCount = "total_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = container.decodeFlexibleBool(forKey: .success, default: true)
        data = try? container.decode([DefaultPlaylistStreamResponse].self, forKey: .data)
        message = try? container.decode(String.self, forKey: .message)
        pagesEmitted = container.decodeFlexibleInt(forKey: .pagesEmitted)
        nextPageToEmit = container.decodeFlexibleInt(forKey: .nextPageToEmit)
        pageNum = container.decodeFlexibleInt(forKey: .pageNum)
        totalCount = container.decodeFlexibleInt(forKey: .totalCount)
    }
}

struct DefaultPlaylistStreamResponse: Decodable {
    let title: String?
    let altTitle: String?
    let categoryID: String?
    let categoryName: String?
    let streamID: String?
    let streamIcon: String?
    let streamType: String?
    let directSource: String?

    enum CodingKeys: String, CodingKey {
        case title
        case altTitle = "name"
        case categoryID = "category_id"
        case categoryName = "category_name"
        case streamID = "stream_id"
        case streamIcon = "stream_icon"
        case streamType = "stream_type"
        case directSource = "direct_source"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = container.decodeFlexibleString(forKey: .title)
        altTitle = container.decodeFlexibleString(forKey: .altTitle)
        categoryID = container.decodeFlexibleString(forKey: .categoryID)
        categoryName = container.decodeFlexibleString(forKey: .categoryName)
        streamID = container.decodeFlexibleString(forKey: .streamID)
        streamIcon = container.decodeFlexibleString(forKey: .streamIcon)
        streamType = container.decodeFlexibleString(forKey: .streamType)
        directSource = container.decodeFlexibleString(forKey: .directSource)
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) -> String? {
        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }
        if let int64Value = try? decode(Int64.self, forKey: key) {
            return String(int64Value)
        }
        if let doubleValue = try? decode(Double.self, forKey: key) {
            return String(doubleValue)
        }
        return nil
    }

    func decodeFlexibleInt(forKey key: Key) -> Int? {
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }
        if let stringValue = try? decode(String.self, forKey: key) {
            return Int(stringValue)
        }
        return nil
    }

    func decodeFlexibleBool(forKey key: Key, default defaultValue: Bool) -> Bool {
        if let boolValue = try? decode(Bool.self, forKey: key) {
            return boolValue
        }
        if let stringValue = try? decode(String.self, forKey: key) {
            return !["false", "0", "no"].contains(stringValue.lowercased())
        }
        return defaultValue
    }
}
