import XCTest

final class MathQuestKidsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testMissionEntryAndParentGate() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-deterministic-session", "-ui-test"]
        app.launch()

        navigateToHome(app: app)

        let missionButton = currentMissionButton(app: app)
        XCTAssertTrue(missionButton.waitForExistence(timeout: 5),
                      "Expected the primary mission CTA on the home screen.")
        missionButton.tap()
        XCTAssertTrue(app.staticTexts["problemPrompt"].waitForExistence(timeout: 3))
        relaunchToHome(app: app)

        app.buttons["Settings"].tap()
        let configureButton = app.buttons["Create Parent PIN"]
        if configureButton.waitForExistence(timeout: 3) {
            configureButton.tap()
            let createField = app.secureTextFields["Create PIN"]
            let confirmField = app.secureTextFields["Confirm PIN"]
            XCTAssertTrue(createField.waitForExistence(timeout: 2))
            createField.tap()
            createField.typeText("2468")
            confirmField.tap()
            confirmField.typeText("2468")
            app.buttons["Save PIN"].tap()
        }

        let unlockButton = app.buttons["Unlock Settings"]
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 3))
        let pinField = app.secureTextFields["Parent PIN"]
        XCTAssertTrue(pinField.waitForExistence(timeout: 2))
        pinField.tap()
        pinField.typeText("2468")
        unlockButton.tap()
        XCTAssertTrue(app.staticTexts["Parent Settings"].waitForExistence(timeout: 3))
    }

    @MainActor
    private func navigateToHome(app: XCUIApplication) {
        let missionButton = currentMissionButton(app: app)
        if missionButton.waitForExistence(timeout: 2) {
            return
        }

        let nameField = app.textFields["Child name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Mia\n")
        if !missionButton.waitForExistence(timeout: 2) {
            let startAdventureButton = app.buttons["Start Adventure"]
            XCTAssertTrue(startAdventureButton.waitForExistence(timeout: 2))
            startAdventureButton.tap()
        }
        XCTAssertTrue(missionButton.waitForExistence(timeout: 5))
    }

    @MainActor
    private func currentMissionButton(app: XCUIApplication) -> XCUIElement {
        let startQuest = app.buttons["Start Quest"]
        if startQuest.exists {
            return startQuest
        }
        let findStartingQuest = app.buttons["Find My Starting Quest"]
        if findStartingQuest.exists {
            return findStartingQuest
        }
        return startQuest
    }

    @MainActor
    private func completeCurrentSession(app: XCUIApplication, returnToHome: Bool = true) {
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
        if returnToHome {
            app.buttons["Back to Home"].tap()
        }
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

        let missionButton = currentMissionButton(app: app)
        XCTAssertTrue(missionButton.waitForExistence(timeout: 3),
                      "Expected the primary mission CTA on the home screen.")
        assertMinTapTarget(missionButton, label: "Mission CTA")
        attachScreenshot(app: app, name: "Home")

        missionButton.tap()
        XCTAssertTrue(app.staticTexts["problemPrompt"].waitForExistence(timeout: 3))
        assertMinTapTarget(app.buttons["Hint"], label: "Hint")
        assertMinTapTarget(app.buttons["Read Aloud"], label: "Read Aloud")
        assertMinTapTarget(app.buttons["Submit Answer"], label: "Submit Answer")
        attachScreenshot(app: app, name: "Session")
    }

    @MainActor
    func testStickerBookFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-deterministic-session", "-ui-test"]
        app.launch()

        navigateToHome(app: app)

        let stickerBookButton = app.buttons["Open Sticker Book"]
        scrollToElement(stickerBookButton, in: app)
        XCTAssertTrue(stickerBookButton.waitForExistence(timeout: 3))
        stickerBookButton.tap()

        XCTAssertTrue(stickerBookTitle(app: app).waitForExistence(timeout: 3))
        attachScreenshot(app: app, name: "StickerBook")
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

    private func stickerBookTitle(app: XCUIApplication) -> XCUIElement {
        let titles = ["Sweet Sticker Pantry", "Galaxy Sticker Atlas", "Sticker Book"]
        for title in titles {
            let match = app.staticTexts[title]
            if match.exists {
                return match
            }
        }
        return app.staticTexts[titles[0]]
    }

    @MainActor
    private func relaunchToHome(app: XCUIApplication) {
        app.terminate()
        app.launch()
        navigateToHome(app: app)
    }

    @MainActor
    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) {
        var attempts = 0
        while !element.exists && attempts < maxSwipes {
            app.swipeUp()
            attempts += 1
        }
    }
}
