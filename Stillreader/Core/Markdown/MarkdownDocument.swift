import Foundation

struct MarkdownDocument: Sendable {
    let path: String
    let frontmatter: [String: Any]
    let body: String
}

enum MarkdownParseError: Error, Equatable {
    case missingFrontmatter
    case missingRequiredField(String)
    case invalidYAML(String)
}

enum MarkdownDates {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ string: String) -> Date? {
        iso8601.date(from: string)
    }

    static func format(_ date: Date) -> String {
        iso8601.string(from: date)
    }
}
