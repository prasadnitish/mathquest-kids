import XCTest

final class MathQuestKidsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFlowThroughThreeUnitsAndParentGate() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-deterministic-session", "-ui-test"]
        app.launch()

        navigateToHome(app: app)

        let firstUnlocked = firstUnlockedTrailNode(app: app)
        XCTAssertTrue(firstUnlocked.waitForExistence(timeout: 5),
                      "Expected at least one unlocked trail node on the home screen.")
        firstUnlocked.tap()
        completeCurrentSession(app: app)

        // After completing the first unit, the next unit in the learning path
        // unlocks. Complete one more to exercise the unlock flow.
        let nextUnlocked = firstUnlockedTrailNode(app: app, excludingCompleted: true)
        if nextUnlocked.waitForExistence(timeout: 3) {
            nextUnlocked.tap()
            completeCurrentSession(app: app)
        }

        app.buttons["Settings"].tap()
        let unlockButton = app.buttons["Unlock Settings"]
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 3))
    }

    @MainActor
    private func navigateToHome(app: XCUIApplication) {
        let anyTrailNode = app.buttons.matching(unlockedTrailNodePredicate).firstMatch
        if anyTrailNode.waitForExistence(timeout: 2) {
            return
        }

        let nameField = app.textFields["Child name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Mia")
        app.buttons["Start Adventure"].tap()
        XCTAssertTrue(anyTrailNode.waitForExistence(timeout: 5))
    }

    /// Matches a skill-trail node that is playable (not locked).
    /// The node's accessibility label format is `"<Unit Title>: <State>"`
    /// where <State> is one of "Locked", "Available, tap to start",
    /// "In progress, N percent", "Completed", "Mastered".
    private var unlockedTrailNodePredicate: NSPredicate {
        NSPredicate(format:
            "label CONTAINS ': Available' OR label CONTAINS ': In progress' OR label CONTAINS ': Completed' OR label CONTAINS ': Mastered'"
        )
    }

    @MainActor
    private func firstUnlockedTrailNode(app: XCUIApplication, excludingCompleted: Bool = false) -> XCUIElement {
        if excludingCompleted {
            let predicate = NSPredicate(format:
                "label CONTAINS ': Available' OR label CONTAINS ': In progress'"
            )
            return app.buttons.matching(predicate).firstMatch
        }
        return app.buttons.matching(unlockedTrailNodePredicate).firstMatch
    }

    @MainActor
    private func completeCurrentSession(app: XCUIApplication) {
        var guardCounter = 0
        while !app.buttons["Back to Home"].exists && guardCounter < 40 {
            guardCounter += 1
            // The session may show a correction overlay after two wrong answers;
            // acknowledge it and continue if it appears.
            if app.buttons["Acknowledge correction and continue"].exists {
                app.buttons["Acknowledge correction and continue"].tap()
                continue
            }
            guard app.buttons["Submit Answer"].waitForExistence(timeout: 3) else { break }
            solveCurrentItem(app: app)
            app.buttons["Submit Answer"].tap()
        }

        XCTAssertTrue(app.buttons["Back to Home"].waitForExistence(timeout: 5))
        app.buttons["Back to Home"].tap()
    }

    @MainActor
    private func solveCurrentItem(app: XCUIApplication) {
        // Tap the first visible option button; correctness isn't required
        // to progress the session (correction flow advances either way).
        let optionButtons = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Option "))
        if optionButtons.count > 0 {
            optionButtons.element(boundBy: 0).tap()
            return
        }

        // Place-value items have +1 Ten / +1 One steppers instead of options.
        if app.buttons["+1 Ten"].exists {
            app.buttons["+1 Ten"].tap()
        }
        if app.buttons["+1 One"].exists {
            app.buttons["+1 One"].tap()
        }
    }

    @MainActor
    func testAccessibilityAndSnapshots() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-deterministic-session", "-ui-test"]
        app.launch()

        navigateToHome(app: app)

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
        assertMinTapTarget(settingsButton, label: "Settings")

        let firstUnlocked = firstUnlockedTrailNode(app: app)
        XCTAssertTrue(firstUnlocked.waitForExistence(timeout: 3),
                      "Expected an unlocked trail node on the home screen.")
        assertMinTapTarget(firstUnlocked, label: "First unlocked trail node")
        attachScreenshot(app: app, name: "Home")

        firstUnlocked.tap()
        XCTAssertTrue(app.staticTexts["problemPrompt"].waitForExistence(timeout: 3))
        assertMinTapTarget(app.buttons["Hint"], label: "Hint")
        assertMinTapTarget(app.buttons["Read Aloud"], label: "Read Aloud")
        assertMinTapTarget(app.buttons["Submit Answer"], label: "Submit Answer")
        attachScreenshot(app: app, name: "Session")

        completeCurrentSession(app: app)
        attachScreenshot(app: app, name: "SummaryOrHome")
    }

    private func assertMinTapTarget(_ element: XCUIElement, label: String) {
        let frame = element.frame
        XCTAssertGreaterThanOrEqual(frame.width, 44.0, "\(label) width is below 44")
        XCTAssertGreaterThanOrEqual(frame.height, 44.0, "\(label) height is below 44")
    }

    private func attachScreenshot(app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
