import Foundation

final class DirectFeedFetcher: FeedFetcher {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Stillreader/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw FeedFetchError(message: "HTTP error fetching \(url.absoluteString)")
        }
        return data
    }
}
