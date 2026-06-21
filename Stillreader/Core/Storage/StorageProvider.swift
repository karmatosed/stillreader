import Foundation

protocol StorageProvider: Sendable {
    func ensureLayout() async throws
    func read(path: String) async throws -> String
    func write(path: String, content: String) async throws
    func delete(path: String) async throws
    func list(prefix: String) async throws -> [String]
    func exists(path: String) async throws -> Bool
}

enum StorageError: Error, Equatable {
    case notFound(String)
    case encodingFailed
}
