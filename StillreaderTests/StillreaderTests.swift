import XCTest
@testable import Stillreader

final class StillreaderTests: XCTestCase {
    @MainActor
    func testAppStateBootstrap() async {
        let state = AppState()
        XCTAssertFalse(state.isReady)
        await state.bootstrap()
        XCTAssertTrue(state.isReady)
    }
}
