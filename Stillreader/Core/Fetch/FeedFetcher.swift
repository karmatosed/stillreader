import Foundation

protocol FeedFetcher: Sendable {
    func fetch(url: URL) async throws -> Data
}

struct FeedFetchError: Error, LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
