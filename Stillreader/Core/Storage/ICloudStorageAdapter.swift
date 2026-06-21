import Foundation

final class ICloudStorageAdapter: StorageProvider, @unchecked Sendable {
    private let localAdapter: LocalStorageAdapter
    private(set) var isCloudAvailable: Bool

    init(
        containerIdentifier: String = "iCloud.com.stillreader.app",
        fallbackRoot: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let rootURL: URL
        if let container = fileManager.url(forUbiquityContainerIdentifier: containerIdentifier) {
            rootURL = container.appendingPathComponent("Documents/Stillreader", isDirectory: true)
            isCloudAvailable = true
        } else if let fallbackRoot {
            rootURL = fallbackRoot
            isCloudAvailable = false
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            rootURL = appSupport.appendingPathComponent("Stillreader", isDirectory: true)
            isCloudAvailable = false
        }

        localAdapter = LocalStorageAdapter(rootURL: rootURL, fileManager: fileManager)
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
