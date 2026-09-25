import UIKit
import XCTest

/// Walks every major screen, and one quest per question format, in portrait and landscape
/// on whichever simulator it runs on. Each screen/orientation gets a screenshot plus a
/// findings list, which `scripts/ux-matrix/make_report.py` turns into a side-by-side report.
///
/// Hard failures are limited to things a child would be stuck on: the app stops running,
/// a screen never appears, or a required control can't be reached even by scrolling.
/// Everything else (small tap targets, controls below the fold, overlapping or clipped
/// elements) is recorded as a finding for review, because horizontal carousels and
/// decorative layers make those checks too noisy to fail on.
///
/// Run across a device matrix with `scripts/ux-matrix/run.sh`.
final class LayoutMatrixUITests: XCTestCase {
    private enum Orientation: String, CaseIterable {
        case portrait
        case landscape

        var deviceOrientation: UIDeviceOrientation {
            self == .portrait ? .portrait : .landscapeLeft
        }
    }

    private struct Target {
        let element: XCUIElement
        let name: String
        /// Primary controls that should be visible without scrolling; reported if they aren't.
        var aboveFold = false
        /// Fail the test if the control can't be brought on screen at all.
        var required = true
    }

    /// One quest per question format, so every interaction layout is checked on every device.
    private static let formatSamples: [(format: String, unit: String)] = [
        ("addTwoDigit", "g1AddSub100"),
        ("additionStory", "kAddWithin10"),
        ("angleMeasure", "g4AngleMeasure"),
        ("areaTiling", "g3AreaConcept"),
        ("buildShape", "g1SpatialBuildShapes"),
        ("countAndMatch", "kCountObjects"),
        ("dataPlot", "g2DataIntro"),
        ("decimalsAndVolume", "volumeAndDecimals"),
        ("divisionGroups", "g3DivMeaning"),
        ("factFamily", "g1FactFamilies"),
        ("fractionAddSub", "g4FractionAddSub"),
        ("fractionComparison", "fractionComparison"),
        ("fractionOfWhole", "fractionOfWhole"),
        ("gridPath", "g2SpatialGridPaths"),
        ("groupComparison", "kCompareGroups"),
        ("measureLength", "g1MeasureLength"),
        ("multiplicationArray", "multiplicationArrays"),
        ("netPreview", "g4SpatialNetsPreview"),
        ("numberBond", "kComposeDecompose"),
        ("positionWords", "kSpatialPositionWords"),
        ("ratioTable", "g5PreRatios"),
        ("rotateToMatch", "k2SpatialRotateMatch"),
        ("shapeClassification", "kShapeAttributes"),
        ("shapeHunt", "kSpatialShapeHunt"),
        ("solidAttributes", "g2SpatialSolidAttributes"),
        ("subTwoDigit", "g2SubWithin100"),
        ("subtractionStory", "subtractionStories"),
        ("symmetryMirror", "g1SpatialSymmetryMirror"),
        ("teenPlaceValue", "teenPlaceValue"),
        ("threeDigitComparison", "threeDigitComparison"),
        ("timeMoney", "g2TimeMoney"),
        ("twoDigitComparison", "twoDigitComparison"),
    ]

    private enum FeatureLimits {
        /// Sessions are capped at 10 items (FeatureFlags.maximumSessionItems); allow headroom.
        static let maxItemsPerQuest = 15
    }

    private static let modalCTATitles = ["Awesome!", "Launch On!", "So Sweet!", "Keep Going", "See My Route"]

    private static let controlTypes: Set<XCUIElement.ElementType> = [
        .button, .textField, .secureTextField, .switch, .slider, .stepper, .segmentedControl, .link,
    ]

    private var scrolledSinceTop = false

    override func setUpWithError() throws {
        // Keep going after a failed check so one broken screen doesn't hide the rest of the matrix.
        continueAfterFailure = true
    }

    // MARK: - Flows

    @MainActor
    func testCoreFlowLayouts() throws {
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments = ["-deterministic-session", "-ui-test"]
        app.launch()

        let nameField = app.textFields["Child name"]
        guard nameField.waitForExistence(timeout: 10) else {
            XCTFail("Profile setup did not appear")
            return
        }
        checkpoint("01-ProfileSetup", app, targets: [
            Target(element: nameField, name: "Child name", aboveFold: true),
            Target(element: app.buttons["Start Adventure"], name: "Start Adventure", aboveFold: true),
        ])

        let mission = missionButton(app)
        nameField.tap()
        nameField.typeText("Mia\n")
        if !mission.waitForExistence(timeout: 3) {
            let start = app.buttons["Start Adventure"]
            if reveal(start, in: app) {
                start.tap()
            }
        }
        guard mission.waitForExistence(timeout: 8) else {
            XCTFail("Home did not appear after profile setup")
            return
        }
        checkpoint("02-Home", app, targets: [
            Target(element: mission, name: "Mission button", aboveFold: true),
            Target(element: app.buttons["Settings"], name: "Settings", aboveFold: true),
            Target(element: app.buttons["Explore Quest Trail"], name: "Explore Quest Trail"),
            Target(element: app.buttons["Open Sticker Book"], name: "Open Sticker Book"),
        ])

        let trail = app.buttons["Explore Quest Trail"]
        if reveal(trail, in: app) {
            trail.tap()
            let back = app.buttons["Go back to home"]
            if back.waitForExistence(timeout: 5) {
                checkpoint("03-QuestMap", app, targets: [
                    Target(element: back, name: "Back", aboveFold: true),
                ])
                reveal(back, in: app)
                back.tap()
            } else {
                XCTFail("Quest map did not open")
            }
        }

        let stickerBook = app.buttons["Open Sticker Book"]
        if mission.waitForExistence(timeout: 5), reveal(stickerBook, in: app) {
            stickerBook.tap()
            let close = app.buttons["Close sticker book"]
            if close.waitForExistence(timeout: 5) {
                checkpoint("04-StickerBook", app, targets: [
                    Target(element: close, name: "Done", aboveFold: true),
                ])
                reveal(close, in: app)
                close.tap()
            } else {
                XCTFail("Sticker book did not open")
            }
        }

        let settings = app.buttons["Settings"]
        if mission.waitForExistence(timeout: 5), reveal(settings, in: app) {
            settings.tap()
            checkParentSettings(app)
            // Close the sheet even if a step inside it failed, so the rest of the flow can run.
            if app.buttons["Done"].exists {
                app.buttons["Done"].tap()
            }
        }

        guard mission.waitForExistence(timeout: 5), reveal(mission, in: app) else {
            XCTFail("Could not return to Home to start a quest")
            return
        }
        mission.tap()

        let prompt = app.staticTexts["problemPrompt"]
        guard prompt.waitForExistence(timeout: 8) else {
            XCTFail("Starting the mission did not open a quest")
            return
        }
        checkpoint("07-Session", app, targets: sessionTargets(app))

        answerCurrentItem(app)
        let submit = app.buttons["Submit Answer"]
        if submit.exists, submit.isEnabled {
            reveal(submit, in: app)
            submit.tap()
        }
        settle()
        checkpoint("08-SessionFeedback", app, targets: [])

        guard finishSession(app) else {
            XCTFail("Could not reach the quest summary")
            return
        }

        var modalIndex = 0
        let modalCTA = app.buttons.matching(NSPredicate(format: "label IN %@", argumentArray: [Self.modalCTATitles])).firstMatch
        while modalIndex < 3, modalCTA.waitForExistence(timeout: 3) {
            modalIndex += 1
            checkpoint("09-Celebration\(modalIndex)", app, targets: [
                Target(element: modalCTA, name: modalCTA.label, aboveFold: true),
            ])
            reveal(modalCTA, in: app)
            modalCTA.tap()
            settle()
        }

        checkpoint("10-Summary", app, targets: [
            Target(element: app.buttons["Back to Home"], name: "Back to Home"),
            Target(element: app.buttons["Start next recommended quest"], name: "Start Next Quest", required: false),
        ])
    }

    @MainActor
    func testQuestCheckLayouts() throws {
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .portrait

        // No "-ui-test": the quest check only runs for a real first launch.
        let app = XCUIApplication()
        app.launchArguments = ["-deterministic-diagnostic"]
        app.launch()

        let nameField = app.textFields["Child name"]
        guard nameField.waitForExistence(timeout: 10) else {
            throw XCTSkip("A profile already exists on this simulator; erase it to check the first-launch quest check.")
        }
        nameField.tap()
        nameField.typeText("Mia\n")

        let prompt = app.staticTexts["Diagnostic problem prompt"]
        if !prompt.waitForExistence(timeout: 3) {
            let start = app.buttons["Start Adventure"]
            if reveal(start, in: app) {
                start.tap()
            }
        }
        guard prompt.waitForExistence(timeout: 8) else {
            XCTFail("The quest check did not start after profile setup")
            return
        }

        checkpoint("05b-QuestCheck", app, targets: [
            Target(element: prompt, name: "Quest check prompt", aboveFold: true),
            Target(element: app.buttons["Read Aloud"], name: "Read Aloud", aboveFold: true),
            Target(element: firstOption(app), name: "First answer"),
            Target(element: app.buttons["I don't know yet"], name: "I don't know yet"),
            Target(element: app.buttons["Maybe later"], name: "Maybe later", required: false),
        ])
    }

    @MainActor
    func testQuestionFormatLayouts() throws {
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = XCUIApplication()

        for sample in Self.formatSamples {
            XCUIDevice.shared.orientation = .portrait
            app.launchArguments = ["-deterministic-session", "-ui-test", "-ui-test-start-unit", sample.unit]
            app.launch()
            scrolledSinceTop = false

            guard app.staticTexts["problemPrompt"].waitForExistence(timeout: 10) else {
                XCTFail("\(sample.unit): the quest did not open")
                continue
            }

            // Quests open with one warm-up review item from another unit; move past it
            // so the screenshot shows this unit's own format.
            let notes = advancePastReviewItem(app)
                ? []
                : ["[flow] Could not get past the warm-up review item, so this shows the review item"]
            checkpoint("Q-\(sample.format)", app, targets: sessionTargets(app), notes: notes)
        }
    }

    // MARK: - Flow helpers

    @MainActor
    private func checkParentSettings(_ app: XCUIApplication) {
        // The Settings sheet is dismissed by a downward swipe, so never scroll inside it.
        let createButton = app.buttons["Create Parent PIN"]
        if createButton.waitForExistence(timeout: 2) {
            createButton.tap()
            let createField = app.secureTextFields["Create PIN"]
            let confirmField = app.secureTextFields["Confirm PIN"]
            guard createField.waitForExistence(timeout: 3) else {
                XCTFail("PIN setup did not appear")
                return
            }
            createField.tap()
            createField.typeText("2468")
            confirmField.tap()
            confirmField.typeText("2468")
            app.buttons["Save PIN"].tap()
        }

        let pinField = app.secureTextFields["Parent PIN"]
        guard pinField.waitForExistence(timeout: 5) else {
            XCTFail("Parent gate did not appear")
            return
        }
        checkpoint("05-ParentGate", app, targets: [
            Target(element: pinField, name: "Parent PIN", aboveFold: true),
            Target(element: app.buttons["Unlock Settings"], name: "Unlock Settings", aboveFold: true),
        ], scrolls: false)

        pinField.tap()
        pinField.typeText("2468")
        app.buttons["Unlock Settings"].tap()

        guard app.staticTexts["Parent Settings"].waitForExistence(timeout: 5) else {
            XCTFail("Parent Settings did not open after entering the PIN")
            return
        }
        checkpoint("06-ParentSettings", app, targets: [
            Target(element: app.buttons["Done"], name: "Done", aboveFold: true),
        ], scrolls: false)
    }

    @MainActor
    private func missionButton(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", argumentArray: [["Start Quest", "Find My Starting Quest"]])).firstMatch
    }

    @MainActor
    private func firstOption(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Option ")).firstMatch
    }

    @MainActor
    private func sessionTargets(_ app: XCUIApplication) -> [Target] {
        [
            Target(element: app.staticTexts["problemPrompt"], name: "Question prompt", aboveFold: true),
            Target(element: app.buttons["Read Aloud"], name: "Read Aloud", aboveFold: true),
            Target(element: app.buttons["Submit Answer"], name: "Submit Answer", aboveFold: true),
            Target(element: app.buttons["Hint"], name: "Hint", required: false),
            Target(element: firstOption(app), name: "First answer", required: false),
        ]
    }

    /// Picks an answer so Submit is enabled; correctness doesn't matter for layout checks.
    @MainActor
    private func answerCurrentItem(_ app: XCUIApplication) {
        let option = firstOption(app)
        if option.exists {
            reveal(option, in: app)
            option.tap()
        } else {
            // Place-value items use steppers instead of options.
            for stepper in ["+1 Ten", "+1 One"] where app.buttons[stepper].exists {
                app.buttons[stepper].tap()
            }
        }
    }

    /// Answers until the item changes. Wrong answers retry once, then show a correction to acknowledge.
    @MainActor
    @discardableResult
    private func submitUntilItemChanges(_ app: XCUIApplication, isDone: () -> Bool) -> Bool {
        for _ in 0..<8 {
            let acknowledge = app.buttons["Acknowledge correction and continue"]
            if acknowledge.exists {
                reveal(acknowledge, in: app)
                acknowledge.tap()
            } else {
                answerCurrentItem(app)
                let submit = app.buttons["Submit Answer"]
                if submit.exists, submit.isEnabled {
                    reveal(submit, in: app)
                    submit.tap()
                }
            }
            if waitUntil(timeout: 3, isDone) {
                settle()
                return true
            }
        }
        return false
    }

    @MainActor
    private func advancePastReviewItem(_ app: XCUIApplication) -> Bool {
        let reviewMarker = app.staticTexts["This is a review item"]
        guard reviewMarker.exists else { return true }
        let prompt = app.staticTexts["problemPrompt"]
        let reviewPrompt = prompt.label
        return submitUntilItemChanges(app) {
            !reviewMarker.exists || (prompt.exists && prompt.label != reviewPrompt)
        }
    }

    @MainActor
    private func finishSession(_ app: XCUIApplication) -> Bool {
        let backToHome = app.buttons["Back to Home"]
        let prompt = app.staticTexts["problemPrompt"]
        var items = 0
        while !backToHome.exists && items < FeatureLimits.maxItemsPerQuest {
            items += 1
            let current = prompt.exists ? prompt.label : ""
            let advanced = submitUntilItemChanges(app) {
                backToHome.exists || (prompt.exists && prompt.label != current)
            }
            if !advanced {
                break
            }
        }
        return backToHome.waitForExistence(timeout: 5)
    }

    // MARK: - Checkpoint

    @MainActor
    private func checkpoint(
        _ screen: String,
        _ app: XCUIApplication,
        targets: [Target],
        scrolls: Bool = true,
        notes: [String] = []
    ) {
        for orientation in Orientation.allCases {
            XCUIDevice.shared.orientation = orientation.deviceOrientation
            settle()
            guard app.state == .runningForeground else {
                XCTFail("\(screen) [\(orientation.rawValue)]: the app is no longer running")
                return
            }
            if scrolls {
                scrollToTop(app)
            }

            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "LX__\(screen)__\(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)

            var findings = notes + auditLayout(app)
            for target in targets {
                findings += check(target, screen: screen, orientation: orientation, app: app, scrolls: scrolls)
            }

            let size = app.frame.size
            let header = [
                "screen: \(screen)",
                "orientation: \(orientation.rawValue)",
                "device: \(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "unknown")",
                "size-class: \(describe(app.horizontalSizeClass))×\(describe(app.verticalSizeClass))",
                "screen-size: \(Int(size.width))×\(Int(size.height)) pt",
                "---",
            ]
            let report = XCTAttachment(string: (header + capped(findings)).joined(separator: "\n"))
            report.name = "LX__\(screen)__\(orientation.rawValue)__findings"
            report.lifetime = .keepAlways
            add(report)
        }

        XCUIDevice.shared.orientation = .portrait
        settle()
        if scrolls {
            scrollToTop(app)
        }
    }

    @MainActor
    private func check(
        _ target: Target,
        screen: String,
        orientation: Orientation,
        app: XCUIApplication,
        scrolls: Bool
    ) -> [String] {
        let element = target.element
        var findings: [String] = []

        // Optional controls only apply to some screens; don't scroll around looking for them.
        if !target.required && !element.exists {
            return []
        }

        if !isFullyOnScreen(element, in: app) {
            if scrolls, reveal(element, in: app) {
                if target.aboveFold {
                    findings.append("[below-fold] \"\(target.name)\" is only reachable by scrolling")
                }
            } else {
                if target.required {
                    XCTFail("\(screen) [\(orientation.rawValue)]: \"\(target.name)\" can't be brought on screen")
                }
                return ["[unreachable] \"\(target.name)\" can't be brought on screen"]
            }
        }

        if element.elementType != .staticText {
            let frame = element.frame
            if frame.width < 44 || frame.height < 44 {
                findings.append("[small-target] \"\(shortName(element.label))\" is \(Int(frame.width))×\(Int(frame.height)) pt (minimum 44×44)")
            }
        }
        return findings
    }

    /// Reads the whole accessibility tree once and checks what is on screen.
    @MainActor
    private func auditLayout(_ app: XCUIApplication) -> [String] {
        guard let root = try? app.snapshot() else {
            return ["[audit] Could not read the accessibility tree"]
        }
        let bounds = root.frame
        var controls: [(name: String, frame: CGRect)] = []
        var texts: [(name: String, frame: CGRect)] = []

        func visit(_ node: XCUIElementSnapshot) {
            if node.elementType == .keyboard {
                return
            }
            let frame = node.frame
            // Only judge elements fully on screen vertically; the rest are scrolled away.
            let onScreenVertically = frame.minY >= bounds.minY - 1 && frame.maxY <= bounds.maxY + 1
            // Skip elements scrolled entirely off the side (e.g. later carousel items).
            let touchesScreenHorizontally = frame.maxX > bounds.minX && frame.minX < bounds.maxX
            if !frame.isEmpty, onScreenVertically, touchesScreenHorizontally {
                let name = shortName(node.label.isEmpty ? node.identifier : node.label)
                if Self.controlTypes.contains(node.elementType) {
                    controls.append((name, frame))
                } else if node.elementType == .staticText {
                    texts.append((name, frame))
                }
            }
            for child in node.children {
                visit(child)
            }
        }
        visit(root)

        var findings: [String] = []
        for item in controls + texts {
            if item.frame.minX < bounds.minX - 1 {
                findings.append("[clipped] \"\(item.name)\" is cut off at the left edge")
            } else if item.frame.maxX > bounds.maxX + 1 {
                findings.append("[clipped] \"\(item.name)\" is cut off at the right edge")
            }
        }
        for control in controls where control.frame.width < 44 || control.frame.height < 44 {
            findings.append("[small-target] \"\(control.name)\" is \(Int(control.frame.width))×\(Int(control.frame.height)) pt (minimum 44×44)")
        }

        let items = controls + texts
        for i in items.indices {
            for j in items.indices where j > i {
                let a = items[i]
                let b = items[j]
                // Full containment is nesting (a label inside its card), not a collision.
                if a.frame.contains(b.frame) || b.frame.contains(a.frame) {
                    continue
                }
                let ratio = overlapRatio(a.frame, b.frame)
                if ratio >= 0.2 {
                    findings.append("[overlap] \"\(a.name)\" and \"\(b.name)\" overlap by \(Int(ratio * 100))%")
                }
            }
        }
        return findings
    }

    // MARK: - Small helpers

    @MainActor
    private func isFullyOnScreen(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        guard !frame.isEmpty else { return false }
        return app.frame.insetBy(dx: -1, dy: -1).contains(frame) && element.isHittable
    }

    @MainActor
    @discardableResult
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 6) -> Bool {
        if isFullyOnScreen(element, in: app) {
            return true
        }
        for _ in 0..<maxSwipes {
            app.swipeUp()
            scrolledSinceTop = true
            if isFullyOnScreen(element, in: app) {
                return true
            }
        }
        for _ in 0..<(maxSwipes + 2) {
            app.swipeDown()
            if isFullyOnScreen(element, in: app) {
                return true
            }
        }
        return false
    }

    @MainActor
    private func scrollToTop(_ app: XCUIApplication) {
        guard scrolledSinceTop else { return }
        for _ in 0..<4 {
            app.swipeDown()
        }
        scrolledSinceTop = false
    }

    /// Lets rotation and state-change animations finish before measuring.
    @MainActor
    private func settle(_ seconds: TimeInterval = 1.2) {
        _ = XCTWaiter.wait(for: [XCTestExpectation(description: "settle")], timeout: seconds)
    }

    @MainActor
    private func waitUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return true
            }
            settle(0.25)
        }
        return condition()
    }

    private func overlapRatio(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        let smaller = min(a.width * a.height, b.width * b.height)
        return smaller > 0 ? (intersection.width * intersection.height) / smaller : 0
    }

    private func shortName(_ label: String) -> String {
        let flat = label.replacingOccurrences(of: "\n", with: " ")
        return flat.count > 48 ? String(flat.prefix(45)) + "…" : flat
    }

    private func describe(_ sizeClass: XCUIElement.SizeClass) -> String {
        switch sizeClass {
        case .compact: return "compact"
        case .regular: return "regular"
        default: return "unspecified"
        }
    }

    private func capped(_ findings: [String], limit: Int = 60) -> [String] {
        var seen = Set<String>()
        let unique = findings.filter { seen.insert($0).inserted }
        guard unique.count > limit else { return unique }
        return Array(unique.prefix(limit)) + ["[more] \(unique.count - limit) more findings not shown"]
    }
}
