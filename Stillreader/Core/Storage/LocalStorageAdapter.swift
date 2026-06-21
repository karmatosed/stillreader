import Foundation

final class LocalStorageAdapter: StorageProvider, @unchecked Sendable {
    private let rootURL: URL
    private let fileManager: FileManager

    init(rootURL: URL, fileManager: FileManager = .default) {
        self.rootURL = rootURL
        self.fileManager = fileManager
    }

    private func url(for path: String) -> URL {
        rootURL.appendingPathComponent(path)
    }

    private func relativePath(for fileURL: URL) -> String {
        let root = rootURL.standardizedFileURL.path
        let full = fileURL.standardizedFileURL.path
        guard full.hasPrefix(root + "/") else {
            return fileURL.lastPathComponent
        }
        return String(full.dropFirst(root.count + 1))
    }

    func ensureLayout() async throws {
        for directory in StoragePath.layoutDirectories {
            try fileManager.createDirectory(
                at: url(for: directory),
                withIntermediateDirectories: true
            )
        }
    }

    func read(path: String) async throws -> String {
        let fileURL = url(for: path)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw StorageError.notFound(path)
        }
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    func write(path: String, content: String) async throws {
        let fileURL = url(for: path)
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    func delete(path: String) async throws {
        let fileURL = url(for: path)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// Lists all `.md` files under `prefix`, recursively (supports sharded subfolders).
    func list(prefix: String) async throws -> [String] {
        let directoryURL = url(for: prefix)
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return []
        }

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var results: [String] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }
            results.append(relativePath(for: fileURL))
        }
        return results.sorted()
    }

    func exists(path: String) async throws -> Bool {
        fileManager.fileExists(atPath: url(for: path).path)
    }
}
