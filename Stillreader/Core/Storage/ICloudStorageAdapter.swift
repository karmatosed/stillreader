import Foundation

final class ICloudStorageAdapter: StorageProvider, @unchecked Sendable {
    private let fileManager: FileManager
    private let fallbackRoot: URL
    private var adapter: LocalStorageAdapter
    private var didResolveStorage = false
    private let lock = NSLock()

    private(set) var storageLocation: StorageLocation

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        fallbackRoot = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Stillreader", isDirectory: true)
        adapter = LocalStorageAdapter(rootURL: fallbackRoot, fileManager: fileManager)
        storageLocation = .localFallback
    }

    var isCloudAvailable: Bool {
        lock.withLock { storageLocation == .iCloudDrive }
    }

    func ensureLayout() async throws {
        try await resolvedAdapter().ensureLayout()
    }

    func read(path: String) async throws -> String {
        try await resolvedAdapter().read(path: path)
    }

    func write(path: String, content: String) async throws {
        try await resolvedAdapter().write(path: path, content: content)
    }

    func delete(path: String) async throws {
        try await resolvedAdapter().delete(path: path)
    }

    func list(prefix: String) async throws -> [String] {
        try await resolvedAdapter().list(prefix: prefix)
    }

    func exists(path: String) async throws -> Bool {
        try await resolvedAdapter().exists(path: path)
    }

    private func resolvedAdapter() async -> LocalStorageAdapter {
        let alreadyResolved = lock.withLock { () -> LocalStorageAdapter? in
            didResolveStorage ? adapter : nil
        }
        if let alreadyResolved {
            return alreadyResolved
        }

        let resolved = await resolvePreferredStorage()

        lock.withLock {
            adapter = resolved.storage
            storageLocation = resolved.location
            didResolveStorage = true
        }
        return resolved.storage
    }

    private func resolvePreferredStorage() async -> (storage: LocalStorageAdapter, location: StorageLocation) {
        await withTaskGroup(of: (LocalStorageAdapter, StorageLocation)?.self) { group in
            group.addTask { [fileManager] in
                if let container = fileManager.url(
                    forUbiquityContainerIdentifier: SharedStorageRoot.iCloudContainerID
                ) {
                    let root = container.appendingPathComponent("Documents/Stillreader", isDirectory: true)
                    return (LocalStorageAdapter(rootURL: root, fileManager: fileManager), .iCloudDrive)
                }
                return nil
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                return nil
            }

            for await result in group {
                group.cancelAll()
                if let result {
                    return result
                }
            }

            return (
                LocalStorageAdapter(rootURL: fallbackRoot, fileManager: fileManager),
                StorageLocation.localFallback
            )
        }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
