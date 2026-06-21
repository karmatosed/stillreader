import Foundation

final class ICloudStorageAdapter: StorageProvider, @unchecked Sendable {
    private let localAdapter: LocalStorageAdapter
    private(set) var storageLocation: StorageLocation

    init(fileManager: FileManager = .default) {
        let resolved = SharedStorageRoot.makeStorage(fileManager: fileManager)
        localAdapter = resolved.storage
        storageLocation = resolved.location
    }

    var isCloudAvailable: Bool {
        storageLocation == .iCloudDrive
    }

    func ensureLayout() async throws {
        try await localAdapter.ensureLayout()
    }

    func read(path: String) async throws -> String {
        try await localAdapter.read(path: path)
    }

    func write(path: String, content: String) async throws {
        try await localAdapter.write(path: path, content: content)
    }

    func delete(path: String) async throws {
        try await localAdapter.delete(path: path)
    }

    func list(prefix: String) async throws -> [String] {
        try await localAdapter.list(prefix: prefix)
    }

    func exists(path: String) async throws -> Bool {
        try await localAdapter.exists(path: path)
    }
}
