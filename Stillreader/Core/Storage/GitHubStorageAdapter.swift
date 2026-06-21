import Foundation

/// v2 — GitHub storage adapter (not implemented).
final class GitHubStorageAdapter: StorageProvider, @unchecked Sendable {
    func ensureLayout() async throws {
        fatalError("GitHub storage not yet implemented")
    }

    func read(path: String) async throws -> String {
        fatalError("GitHub storage not yet implemented")
    }

    func write(path: String, content: String) async throws {
        fatalError("GitHub storage not yet implemented")
    }

    func delete(path: String) async throws {
        fatalError("GitHub storage not yet implemented")
    }

    func list(prefix: String) async throws -> [String] {
        fatalError("GitHub storage not yet implemented")
    }

    func exists(path: String) async throws -> Bool {
        fatalError("GitHub storage not yet implemented")
    }
}
