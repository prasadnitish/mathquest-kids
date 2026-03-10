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

        let startSub = app.buttons["Start Subtraction Stories"]
        XCTAssertTrue(startSub.waitForExistence(timeout: 5))
        startSub.tap()
        completeCurrentSession(app: app)

        app.buttons["Start Teen Place Value"].tap()
        completeCurrentSession(app: app)

        app.buttons["Start 2-Digit Comparison"].tap()
        completeCurrentSession(app: app)

        app.buttons["Settings"].tap()
        let unlockButton = app.buttons["Unlock Settings"]
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 3))
    }

    @MainActor
    private func navigateToHome(app: XCUIApplication) {
        let startSub = app.buttons["Start Subtraction Stories"]
        if startSub.waitForExistence(timeout: 2) {
            return
        }

        let nameField = app.textFields["Child name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Mia")
        app.buttons["Start Adventure"].tap()
        XCTAssertTrue(startSub.waitForExistence(timeout: 5))
    }

    @MainActor
    private func completeCurrentSession(app: XCUIApplication) {
        var guardCounter = 0
        while !app.buttons["Back to Home"].exists && guardCounter < 40 {
            guardCounter += 1
            XCTAssertTrue(app.buttons["Submit Answer"].waitForExistence(timeout: 3))
            solveCurrentItem(app: app)
            app.buttons["Submit Answer"].tap()
        }

        XCTAssertTrue(app.buttons["Back to Home"].waitForExistence(timeout: 3))
        app.buttons["Back to Home"].tap()
    }

    @MainActor
    private func solveCurrentItem(app: XCUIApplication) {
        let promptElement = app.staticTexts["problemPrompt"]
        XCTAssertTrue(promptElement.waitForExistence(timeout: 2))
        let prompt = promptElement.label

        if prompt.contains("Compare ") {
            solveComparison(prompt: prompt, app: app)
            return
        }

        if prompt.contains("Build ") || prompt.contains("Show ") || prompt.contains("Use blocks to make ") {
            solvePlaceValue(prompt: prompt, app: app)
            return
        }

        solveSubtraction(prompt: prompt, app: app)
    }

    @MainActor
    private func solveSubtraction(prompt: String, app: XCUIApplication) {
        let numbers = extractNumbers(from: prompt)
        guard numbers.count >= 2 else {
            let optionButtons = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Option "))
            if optionButtons.count > 0 { optionButtons.element(boundBy: 0).tap() }
            return
        }
        let answer = String(numbers[0] - numbers[1])
        tapOption(answer, app: app)
    }

    @MainActor
    private func solveComparison(prompt: String, app: XCUIApplication) {
        let numbers = extractNumbers(from: prompt)
        guard numbers.count >= 2 else {
            tapOption("<", app: app)
            return
        }
        let symbol: String
        if numbers[0] < numbers[1] {
            symbol = "<"
        } else if numbers[0] > numbers[1] {
            symbol = ">"
        } else {
            symbol = "="
        }
        tapOption(symbol, app: app)
    }

    @MainActor
    private func solvePlaceValue(prompt: String, app: XCUIApplication) {
        let numbers = extractNumbers(from: prompt)
        guard let target = numbers.first else {
            if app.buttons["+1 Ten"].exists { app.buttons["+1 Ten"].tap() }
            if app.buttons["+1 One"].exists { app.buttons["+1 One"].tap() }
            return
        }
        let tens = target / 10
        let ones = target % 10

        if app.buttons["Reset"].exists {
            app.buttons["Reset"].tap()
        }
        for _ in 0..<tens {
            app.buttons["+1 Ten"].tap()
        }
        for _ in 0..<ones {
            app.buttons["+1 One"].tap()
        }
    }

    @MainActor
    private func tapOption(_ value: String, app: XCUIApplication) {
        let exact = app.buttons["Option \(value)"]
        if exact.exists {
            exact.tap()
            return
        }
        let optionButtons = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Option "))
        if optionButtons.count > 0 {
            optionButtons.element(boundBy: 0).tap()
        }
    }

    private func extractNumbers(from text: String) -> [Int] {
        let regex = try? NSRegularExpression(pattern: "\\d+")
        let nsText = text as NSString
        let matches = regex?.matches(in: text, range: NSRange(location: 0, length: nsText.length)) ?? []
        return matches.compactMap { match in
            Int(nsText.substring(with: match.range))
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

        let startSub = app.buttons["Start Subtraction Stories"]
        XCTAssertTrue(startSub.exists)
        assertMinTapTarget(startSub, label: "Start Subtraction Stories")
        attachScreenshot(app: app, name: "Home")

        startSub.tap()
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
