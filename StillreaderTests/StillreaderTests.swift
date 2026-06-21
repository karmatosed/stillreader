import XCTest
@testable import Stillreader

final class StillreaderTests: XCTestCase {
    @MainActor
    func testAppStateBootstrap() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let storage = LocalStorageAdapter(rootURL: tmp)
        let cache = try ArticleCache.inMemory()
        let state = AppState(storage: storage, cache: cache)

        XCTAssertFalse(state.isReady)
        await state.bootstrap()
        XCTAssertTrue(state.isReady)
    }
}
