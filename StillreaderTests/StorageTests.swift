import XCTest
@testable import Stillreader

final class StorageTests: XCTestCase {
    func testLocalStorageWriteAndReadFeed() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        try await storage.ensureLayout()

        let feed = Feed(
            title: "Test",
            url: URL(string: "https://example.com/rss")!,
            slug: "test"
        )
        let feedPath = StoragePath.feed("test")
        let content = try MarkdownParser.serialize(feed: feed, slug: "test")
        try await storage.write(path: feedPath, content: content)

        let read = try await storage.read(path: feedPath)
        XCTAssertTrue(read.contains("https://example.com/rss"))

        let listed = try await storage.list(prefix: "feeds/")
        XCTAssertEqual(listed, [feedPath])
    }

    func testEnsureLayoutCreatesDirectories() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        try await storage.ensureLayout()

        for directory in StoragePath.layoutDirectories {
            var isDirectory: ObjCBool = false
            let path = tmp.appendingPathComponent(directory).path
            XCTAssertTrue(FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory))
            XCTAssertTrue(isDirectory.boolValue)
        }
    }

    func testDeleteRemovesFile() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        try await storage.ensureLayout()
        try await storage.write(path: "feeds/t/gone.md", content: "test")
        let existsBeforeDelete = try await storage.exists(path: "feeds/t/gone.md")
        XCTAssertTrue(existsBeforeDelete)

        try await storage.delete(path: "feeds/t/gone.md")
        let existsAfterDelete = try await storage.exists(path: "feeds/t/gone.md")
        XCTAssertFalse(existsAfterDelete)
    }

    func testListFindsNestedMarkdownFiles() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        try await storage.ensureLayout()
        try await storage.write(path: "feeds/a/alpha.md", content: "a")
        try await storage.write(path: "feeds/z/zulu.md", content: "z")

        let listed = try await storage.list(prefix: "feeds/")
        XCTAssertEqual(listed, ["feeds/a/alpha.md", "feeds/z/zulu.md"])
    }

    func testReadMissingFileThrows() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        try await storage.ensureLayout()

        do {
            _ = try await storage.read(path: "feeds/missing.md")
            XCTFail("Expected StorageError.notFound")
        } catch let error as StorageError {
            XCTAssertEqual(error, .notFound("feeds/missing.md"))
        }
    }
}
