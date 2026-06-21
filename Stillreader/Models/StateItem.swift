import Foundation

enum StateItemStatus: String, Equatable, Sendable {
    case read
    case readLater = "read_later"
}

struct StateItem: Equatable, Sendable {
    let id: String
    var status: StateItemStatus
    var readAt: Date?
    var taggedAt: Date?
    var tags: [String]

    init(
        id: String,
        status: StateItemStatus,
        readAt: Date? = nil,
        taggedAt: Date? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.status = status
        self.readAt = readAt
        self.taggedAt = taggedAt
        self.tags = tags
    }

    init?(yaml: [String: Any]) {
        guard let id = yaml["id"] as? String,
              let statusRaw = yaml["status"] as? String,
              let status = StateItemStatus(rawValue: statusRaw)
        else {
            return nil
        }

        self.id = id
        self.status = status

        if let readAtString = yaml["read_at"] as? String {
            readAt = MarkdownDates.parse(readAtString)
        } else {
            readAt = nil
        }

        if let taggedAtString = yaml["tagged_at"] as? String {
            taggedAt = MarkdownDates.parse(taggedAtString)
        } else {
            taggedAt = nil
        }

        tags = yaml["tags"] as? [String] ?? []
    }

    var yamlDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "status": status.rawValue,
        ]
        if let readAt {
            dict["read_at"] = MarkdownDates.format(readAt)
        }
        if let taggedAt {
            dict["tagged_at"] = MarkdownDates.format(taggedAt)
        }
        if !tags.isEmpty {
            dict["tags"] = tags
        }
        return dict
    }
}
