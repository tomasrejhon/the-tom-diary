import XCTest

/// Ověří zámek orientace i při spuštění telefonu otočeného na šířku.
/// Rozhoduje skutečný rozměr okna, nikoli jen nastavení projektu.
final class The_Tom_DidaryUITestsLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchStaysPortraitWhenPhoneRotates() {
        let app = XCUIApplication()
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        XCTAssertTrue(app.textViews["answerEditor"].waitForExistence(timeout: 10))

        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            let portrait = NSPredicate { _, _ in
                let frame = app.windows.firstMatch.frame
                return frame.width > 0 && frame.height > frame.width
            }
            expectation(for: portrait, evaluatedWith: nil)
            waitForExpectations(timeout: 5)
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Portrait layout after rotating the phone"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
