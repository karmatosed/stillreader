import Foundation

/// Copies new markdown files from the App Group inbox into primary storage (iCloud or local).
enum AppGroupReconciler {
    static func importPending(into storage: StorageProvider, fileManager: FileManager = .default) async throws {
        #if os(iOS)
        guard let groupRoot = SharedStorageRoot.appGroupRoot(fileManager: fileManager) else { return }
        let (primaryRoot, _) = SharedStorageRoot.resolvePrimary(fileManager: fileManager)

        // Skip if share extension and main app already share the same folder.
        if groupRoot.standardizedFileURL == primaryRoot.standardizedFileURL { return }

        let groupStorage = LocalStorageAdapter(rootURL: groupRoot, fileManager: fileManager)
        try await importPrefix("feeds/", from: groupStorage, into: storage)
        try await importPrefix("links/", from: groupStorage, into: storage)
        #endif
    }

    #if os(iOS)
    private static func importPrefix(
        _ prefix: String,
        from source: LocalStorageAdapter,
        into destination: StorageProvider
    ) async throws {
        let paths = try await source.list(prefix: prefix)
        for path in paths {
            if try await destination.exists(path: path) { continue }
            let content = try await source.read(path: path)
            try await destination.write(path: path, content: content)
        }
    }
    #endif
}
