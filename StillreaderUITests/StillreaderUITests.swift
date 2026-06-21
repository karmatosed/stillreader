import XCTest

final class StillreaderUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTabBarAndDemoFeedsButtonRespond() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-SkipAutoLoadDemoFeeds", "-FreshInstall"]
        app.launch()

        tapTab(app, named: "Feeds")

        let loadDemoFeeds = app.buttons["loadDemoFeedsButton"]
        if loadDemoFeeds.waitForExistence(timeout: 3) {
            loadDemoFeeds.tap()
        } else {
            tapTab(app, named: "Inbox")
            app.buttons["Load demo feeds"].tap()
        }

        let feedAppeared = app.staticTexts["The Verge"].waitForExistence(timeout: 15)
            || app.staticTexts["Hacker News"].waitForExistence(timeout: 1)
        let okButton = app.buttons["OK"]
        if okButton.waitForExistence(timeout: 2) {
            okButton.tap()
        }
        XCTAssertTrue(feedAppeared, "Demo feeds should appear after tapping Load demo feeds")

        tapTab(app, named: "Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))

        tapTab(app, named: "Inbox")
        XCTAssertTrue(app.navigationBars["Inbox"].waitForExistence(timeout: 3))
    }

    /// Matches a normal app launch (auto-load enabled). Tabs must stay tappable while data loads.
    func testTabsWorkWithAutoLoadEnabled() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-FreshInstall"]
        app.launch()

        tapTab(app, named: "Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3), "Settings should open")

        // Wait for auto bootstrap + deferred article fetch.
        sleep(5)

        tapTab(app, named: "Feeds")
        XCTAssertTrue(app.navigationBars["Feeds"].waitForExistence(timeout: 5), "Feeds should open after auto-load")

        let feedLoaded = app.staticTexts["The Verge"].waitForExistence(timeout: 8)
            || app.staticTexts["Hacker News"].waitForExistence(timeout: 1)
        XCTAssertTrue(feedLoaded, "Demo feeds should appear in Feeds list")

        tapTab(app, named: "Inbox")
        XCTAssertTrue(app.navigationBars["Inbox"].waitForExistence(timeout: 5), "Inbox should open after auto-load")
    }

    private func tapTab(_ app: XCUIApplication, named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab \(name) should exist", file: file, line: line)

        for _ in 0..<5 {
            if tab.isHittable {
                tab.tap()
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }

        tab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}
