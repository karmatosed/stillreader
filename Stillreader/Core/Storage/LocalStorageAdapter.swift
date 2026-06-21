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

    func list(prefix: String) async throws -> [String] {
        let directoryURL = url(for: prefix)
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return []
        }

        let urls = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil
        )

        return urls
            .filter { $0.pathExtension == "md" }
            .map { prefix + $0.lastPathComponent }
            .sorted()
    }

    func exists(path: String) async throws -> Bool {
        fileManager.fileExists(atPath: url(for: path).path)
    }
}
