import XCTest

/// Walks the app through the scenes filmed for the promo videos. scripts/promo/capture.sh
/// records the simulator screen while each test runs; these aren't part of the layout matrix.
///
/// Each step prints "PROMO-MARK <name> <unix time>" and each tap "PROMO-TAP <x> <y> <unix time>"
/// (x and y as fractions of the screen), so the edit can cut scenes and draw the taps.
/// The app starts with -promo-demo: a sample second grader, Maya, with ten days of quests.
final class PromoCaptureUITests: XCTestCase {
    private static let missionTitles = ["Start Quest", "Find My Starting Quest"]
    private static let modalCTATitles = ["Awesome!", "Launch On!", "So Sweet!", "Keep Going", "See My Route"]
    private static let themes = ["candyland", "axolotl", "rainbowUnicorn", "starsSpace", "superhero", "turboCars"]

    /// A beat between taps, so viewers can follow what's happening.
    private static let beat: TimeInterval = 0.8

    /// iPads are filmed in landscape for the wide videos, iPhones in portrait.
    private var isPad: Bool {
        ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]?.hasPrefix("iPad") ?? false
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    // MARK: - Scenes

    /// Home in each of the six themes.
    @MainActor
    func testSceneThemes() {
        for theme in Self.themes {
            let app = launch(theme: theme)
            guard missionButton(app).waitForExistence(timeout: 20) else {
                XCTFail("Home did not appear in \(theme)")
                app.terminate()
                continue
            }
            pause(1.5)
            mark("theme-\(theme)")
            pause(2.5)
            scroll(app, by: app.frame.height * 0.3)
            pause(1.5)
            scroll(app, by: -app.frame.height * 0.3)
            pause(0.8)
            mark("theme-\(theme)-end")
            app.terminate()
        }
    }

    /// Column addition: a forgotten carry, the coaching note, the fix, then the rest of the
    /// quest and its celebration.
    @MainActor
    func testSceneColumnAddition() {
        let app = launch(theme: "candyland", unit: "g2AddWithin100")
        guard app.staticTexts["problemPrompt"].waitForExistence(timeout: 20) else {
            XCTFail("The quest did not open")
            return
        }
        pause(1.5)
        mark("quest-start")
        var showedSlip = false
        var shownPlain = false
        for _ in 0..<14 {
            guard !reachedQuestEnd(app) else { break }
            let prompt = app.staticTexts["problemPrompt"].label
            if let problem = WrittenProblem(prompt), app.buttons["Digit 1"].exists {
                if !showedSlip && problem.carries {
                    mark("slip-start")
                    work(problem, in: app, forgettingTheCarry: true)
                    showedSlip = true
                    mark("slip-end")
                } else {
                    mark(shownPlain ? "column-quick" : "column-start")
                    work(problem, in: app, forgettingTheCarry: false, quick: shownPlain)
                    shownPlain = true
                }
            } else {
                answerAnything(app)
            }
            waitForNextItem(app, after: prompt)
        }
        celebrate(app)
    }

    /// Column subtraction with a trade: cross out a ten, make ten more ones.
    @MainActor
    func testSceneColumnSubtraction() {
        let app = launch(theme: "axolotl", unit: "g2SubWithin100")
        guard app.staticTexts["problemPrompt"].waitForExistence(timeout: 20) else {
            XCTFail("The quest did not open")
            return
        }
        pause(1.2)
        var showedTrade = false
        for _ in 0..<8 where !showedTrade {
            guard !reachedQuestEnd(app) else { break }
            let prompt = app.staticTexts["problemPrompt"].label
            if let problem = WrittenProblem(prompt), app.buttons["Digit 1"].exists, problem.trades {
                mark("trade-start")
                work(problem, in: app, forgettingTheCarry: false)
                showedTrade = true
                mark("trade-end")
                pause(2.5)
            } else if let problem = WrittenProblem(prompt), app.buttons["Digit 1"].exists {
                work(problem, in: app, forgettingTheCarry: false, quick: true)
            } else {
                answerAnything(app)
            }
            waitForNextItem(app, after: prompt)
        }
    }

    /// Teen place value: the bouncing +/- buttons, then building the number.
    @MainActor
    func testSceneTeenPlaceValue() {
        let app = launch(theme: "turboCars", unit: "teenPlaceValue")
        guard app.staticTexts["problemPrompt"].waitForExistence(timeout: 20) else {
            XCTFail("The quest did not open")
            return
        }
        var built = 0
        for _ in 0..<6 where built < 2 {
            guard !reachedQuestEnd(app) else { break }
            let prompt = app.staticTexts["problemPrompt"].label
            let addTen = app.buttons["+1 Ten"]
            guard addTen.exists, let target = firstNumber(in: prompt), (10...19).contains(target) else {
                answerAnything(app)
                waitForNextItem(app, after: prompt)
                continue
            }
            bringIntoView([addTen, app.buttons["+1 One"]], in: app)
            mark("teen-start")
            pause(built == 0 ? 2.5 : 1.0)
            for _ in 0..<(target / 10) {
                tap(addTen, in: app)
                pause(Self.beat)
            }
            for _ in 0..<(target % 10) {
                tap(app.buttons["+1 One"], in: app)
                pause(0.5)
            }
            pause(0.6)
            submit(app)
            mark("teen-end")
            built += 1
            waitForNextItem(app, after: prompt)
        }
    }

    /// Spatial questions with their pictures: turning a shape, completing a mirror picture.
    @MainActor
    func testSceneSpatial() {
        for (unit, theme) in [("k2SpatialRotateMatch", "starsSpace"), ("g1SpatialSymmetryMirror", "rainbowUnicorn")] {
            let app = launch(theme: theme, unit: unit)
            guard app.staticTexts["problemPrompt"].waitForExistence(timeout: 20) else {
                XCTFail("The \(unit) quest did not open")
                app.terminate()
                continue
            }
            pause(1.2)
            mark("spatial-\(unit)")
            pause(2.5)
            let firstOption = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Option ")).firstMatch
            if firstOption.exists {
                bringIntoView([firstOption], in: app)
            }
            pause(3)
            mark("spatial-\(unit)-end")
            app.terminate()
        }
    }

    /// The sticker book and the quest trail.
    @MainActor
    func testSceneStickersAndTrail() {
        let app = launch(theme: "rainbowUnicorn")
        guard missionButton(app).waitForExistence(timeout: 20) else {
            XCTFail("Home did not appear")
            return
        }
        pause(1)
        let stickerBook = app.buttons["Open Sticker Book"]
        bringIntoView([stickerBook], in: app)
        tap(stickerBook, in: app)
        if app.buttons["Close sticker book"].waitForExistence(timeout: 8) {
            pause(1)
            mark("stickers")
            pause(2.5)
            scroll(app, by: app.frame.height * 0.35)
            pause(2)
            mark("stickers-end")
            tap(app.buttons["Close sticker book"], in: app)
        }

        guard missionButton(app).waitForExistence(timeout: 8) else { return }
        let trail = app.buttons["Explore Quest Trail"]
        bringIntoView([trail], in: app)
        tap(trail, in: app)
        if app.buttons["Go back to home"].waitForExistence(timeout: 8) {
            pause(1)
            mark("trail")
            pause(2.5)
            scroll(app, by: app.frame.height * 0.35)
            pause(2)
            scroll(app, by: app.frame.height * 0.35)
            pause(2)
            mark("trail-end")
        }
    }

    /// The parent gate and the progress dashboard.
    @MainActor
    func testSceneParentDashboard() {
        let app = launch(theme: "superhero")
        guard missionButton(app).waitForExistence(timeout: 20) else {
            XCTFail("Home did not appear")
            return
        }
        pause(1)
        mark("parent-start")
        tap(app.buttons["Settings"], in: app)
        let pinField = app.secureTextFields["Parent PIN"]
        guard pinField.waitForExistence(timeout: 8) else {
            XCTFail("Parent gate did not appear")
            return
        }
        pause(1)
        mark("parent-gate")
        tap(pinField, in: app)
        pause(0.8)
        for digit in "2468" {
            pinField.typeText(String(digit))
            pause(0.35)
        }
        tap(app.buttons["Unlock Settings"], in: app)
        guard app.staticTexts["Parent Settings"].waitForExistence(timeout: 8) else {
            XCTFail("Parent Settings did not open")
            return
        }
        pause(1.5)
        mark("parent-settings")
        // The sheet closes on a downward swipe, so only ever scroll it up.
        let report = app.buttons["View child progress report"]
        for _ in 0..<4 where !(report.exists && report.isHittable) {
            scroll(app, by: app.frame.height * 0.3)
            pause(0.6)
        }
        pause(1)
        tap(report, in: app)
        guard app.staticTexts["PARENT VIEW"].waitForExistence(timeout: 8) else {
            XCTFail("The progress report did not open")
            return
        }
        pause(1.2)
        mark("dashboard")
        pause(3)
        for _ in 0..<3 {
            scroll(app, by: app.frame.height * 0.3)
            pause(2.2)
        }
        mark("dashboard-end")
    }

    // MARK: - Working a column problem

    /// "47 + 36 = ?" read from the prompt.
    private struct WrittenProblem {
        let top: Int
        let bottom: Int
        let isAddition: Bool

        init?(_ prompt: String) {
            let parts = prompt.replacingOccurrences(of: "−", with: "-").split(separator: " ")
            guard parts.count == 5, parts[3] == "=", parts[4] == "?",
                  let top = Int(parts[0]), let bottom = Int(parts[2]),
                  parts[1] == "+" || parts[1] == "-" else { return nil }
            self.top = top
            self.bottom = bottom
            isAddition = parts[1] == "+"
        }

        var answer: Int { isAddition ? top + bottom : top - bottom }
        var carries: Bool { isAddition && top % 10 + bottom % 10 >= 10 }
        var trades: Bool { !isAddition && top % 10 < bottom % 10 }

        /// The answer's digits from the ones leftwards, with a 0 in any column of the numbers
        /// that has nothing left (the app wants every column filled).
        var digitsFromOnes: [Int] {
            let places = max(String(top).count, String(bottom).count, String(answer).count)
            var digits: [Int] = []
            var rest = answer
            for _ in 0..<places {
                digits.append(rest % 10)
                rest /= 10
            }
            return digits
        }

        /// Whether adding the column `place` places from the ones carries into the next one.
        func carriesOut(ofPlace place: Int) -> Bool {
            guard isAddition else { return false }
            var unit = 1
            for _ in 0...place { unit *= 10 }
            return top % unit + bottom % unit >= unit
        }
    }

    private static let placeNames = ["ones", "tens", "hundreds", "thousands"]

    @MainActor
    private func work(_ problem: WrittenProblem, in app: XCUIApplication, forgettingTheCarry slip: Bool, quick: Bool = false) {
        let pace: TimeInterval = quick ? 0.45 : Self.beat
        // The whole sum and the digit pad, from the carry (or trade) row down.
        let topRow = problem.isAddition ? app.buttons["Carry into the tens"] : app.buttons["Trade 1 ten for 10 ones"]
        bringIntoView([topRow, app.buttons["ones answer box"], app.buttons["Digit 0"]], in: app)
        pause(quick ? 0.4 : 1.2)

        if problem.trades {
            tap(app.buttons["Trade 1 ten for 10 ones"], in: app)
            pause(pace * 1.6)
        }

        let digits = problem.digitsFromOnes
        for (place, digit) in digits.enumerated() {
            var written = digit
            if slip && place == 1 {
                // Leave out the carried 1 in the tens, as children often do.
                written = (digit + 9) % 10
            }
            tap(app.buttons["Digit \(written)"], in: app)
            pause(pace)
            let carryBox = app.buttons["Carry into the \(Self.placeNames[min(place + 1, 3)])"]
            if problem.carriesOut(ofPlace: place), !(slip && place == 0), carryBox.exists, place + 1 < digits.count {
                tap(carryBox, in: app)
                pause(pace)
            }
        }
        submit(app)

        guard slip else { return }
        // The tens box turns red and the note names the slip; give viewers time to read it.
        pause(1.2)
        mark("slip-coaching")
        pause(3.2)
        tap(app.buttons["Carry into the tens"], in: app)
        pause(Self.beat)
        tap(app.buttons["tens answer box"], in: app)
        pause(0.5)
        tap(app.buttons["Digit \(digits[1])"], in: app)
        pause(Self.beat)
        mark("slip-fixed")
        submit(app)
    }

    // MARK: - Getting through a quest

    @MainActor
    private func submit(_ app: XCUIApplication) {
        let submit = app.buttons["Submit Answer"]
        if submit.exists, submit.isEnabled {
            tap(submit, in: app)
        }
    }

    /// Anything that isn't being filmed: pick the first choice (or build something) and move on.
    @MainActor
    private func answerAnything(_ app: XCUIApplication) {
        let prompt = app.staticTexts["problemPrompt"].label
        for _ in 0..<3 {
            let acknowledge = app.buttons["Acknowledge correction and continue"]
            if acknowledge.exists {
                bringIntoView([acknowledge], in: app)
                acknowledge.tap()
                return
            }
            let option = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Option ")).firstMatch
            if option.exists {
                bringIntoView([option], in: app)
                option.tap()
            } else if app.buttons["Digit 1"].exists {
                for _ in 0..<4 where !app.buttons["Submit Answer"].isEnabled {
                    app.buttons["Digit 1"].tap()
                }
            } else if app.buttons["+1 Ten"].exists {
                app.buttons["+1 Ten"].tap()
            }
            let submit = app.buttons["Submit Answer"]
            if submit.exists, submit.isEnabled {
                submit.tap()
            }
            pause(1.6)
            let current = app.staticTexts["problemPrompt"]
            if reachedQuestEnd(app) || !current.exists || current.label != prompt
                || app.staticTexts["You Did It"].exists {
                return
            }
        }
    }

    @MainActor
    private func waitForNextItem(_ app: XCUIApplication, after prompt: String) {
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline {
            if reachedQuestEnd(app) { return }
            let acknowledge = app.buttons["Acknowledge correction and continue"]
            if acknowledge.exists {
                bringIntoView([acknowledge], in: app)
                acknowledge.tap()
            }
            let current = app.staticTexts["problemPrompt"]
            if current.exists, current.label != prompt { return }
            pause(0.3)
        }
    }

    @MainActor
    private func reachedQuestEnd(_ app: XCUIApplication) -> Bool {
        modalCTA(app).exists || app.buttons["Back to Home"].exists
    }

    @MainActor
    private func celebrate(_ app: XCUIApplication) {
        var index = 0
        while index < 3, modalCTA(app).waitForExistence(timeout: 6) {
            index += 1
            pause(0.8)
            mark("celebration-\(index)")
            pause(2.8)
            tap(modalCTA(app), in: app)
            pause(1)
        }
        if app.buttons["Back to Home"].waitForExistence(timeout: 6) {
            pause(1)
            mark("summary")
            pause(3)
            mark("summary-end")
        }
    }

    // MARK: - Helpers

    @MainActor
    private func launch(theme: String, unit: String? = nil) -> XCUIApplication {
        XCUIDevice.shared.orientation = isPad ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        var arguments = ["-ui-test", "-promo-demo", "-deterministic-session", "-mathquest.selectedTheme", theme]
        if let unit {
            arguments += ["-ui-test-start-unit", unit]
        }
        app.launchArguments = arguments
        app.launch()
        return app
    }

    @MainActor
    private func missionButton(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", argumentArray: [Self.missionTitles])).firstMatch
    }

    @MainActor
    private func modalCTA(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", argumentArray: [Self.modalCTATitles])).firstMatch
    }

    private func firstNumber(in text: String) -> Int? {
        text.split(whereSeparator: { !$0.isNumber }).first.flatMap { Int($0) }
    }

    private func mark(_ name: String) {
        print("PROMO-MARK \(name) " + String(format: "%.3f", Date().timeIntervalSince1970))
    }

    /// Taps like a person would, and logs where so the edit can draw the finger.
    @MainActor
    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        guard element.exists else {
            print("PROMO-MISSING \(element.debugDescription.prefix(120))")
            return
        }
        let screen = app.frame
        let frame = element.frame
        let x = (frame.midX - screen.minX) / max(screen.width, 1)
        let y = (frame.midY - screen.minY) / max(screen.height, 1)
        print(String(format: "PROMO-TAP %.4f %.4f %.3f", x, y, Date().timeIntervalSince1970))
        element.tap()
    }

    /// Scrolls the content up by `distance` points (down for a negative distance) with one
    /// slow drag that stops without a fling. The drag starts in the left margin, clear of
    /// any buttons.
    @MainActor
    private func scroll(_ app: XCUIApplication, by distance: CGFloat) {
        let screen = app.frame
        let travel = max(-screen.height * 0.45, min(screen.height * 0.45, distance))
        let startY: CGFloat = travel > 0 ? 0.72 : 0.28
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 12 / max(screen.width, 1), dy: startY))
        let end = start.withOffset(CGVector(dx: 0, dy: -travel))
        start.press(forDuration: 0.08, thenDragTo: end, withVelocity: XCUIGestureVelocity(rawValue: 700), thenHoldForDuration: 0.25)
    }

    /// Scrolls so all of `elements` sit between the top of the screen and the pinned answer bar.
    @MainActor
    private func bringIntoView(_ elements: [XCUIElement], in app: XCUIApplication) {
        let screen = app.frame
        for _ in 0..<3 {
            let frames = elements.filter(\.exists).map(\.frame)
            guard var union = frames.first else { return }
            for frame in frames.dropFirst() {
                union = union.union(frame)
            }
            let submit = app.buttons["Submit Answer"]
            let bottom = submit.exists ? submit.frame.minY - 20 : screen.maxY - 40
            let top = screen.minY + 70
            var shift: CGFloat = 0
            if union.maxY > bottom {
                shift = min(union.maxY - bottom, union.minY - top)
            } else if union.minY < top {
                shift = union.minY - top
            }
            guard abs(shift) > 8 else { return }
            scroll(app, by: shift)
            pause(0.4)
        }
    }

    private func pause(_ seconds: TimeInterval) {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "pause")], timeout: seconds)
    }
}
