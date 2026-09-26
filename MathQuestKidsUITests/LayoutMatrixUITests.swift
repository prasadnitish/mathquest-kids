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
/// Each check reads one accessibility snapshot per orientation. Querying elements one by
/// one costs a round trip to the app each time, which made a full device pass take hours.
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

    /// One element from an accessibility snapshot.
    private struct Node {
        let type: XCUIElement.ElementType
        let label: String
        let identifier: String
        let frame: CGRect
    }

    private struct Target {
        /// Live query, used only when the control has to be scrolled into view.
        let element: XCUIElement
        let name: String
        /// Finds the control in a snapshot.
        let matches: (Node) -> Bool
        /// Primary controls that should be visible without scrolling; reported if they aren't.
        var aboveFold = false
        /// Fail the test if the control can't be brought on screen at all.
        var required = true
        /// Lives in the quest's pinned bottom bar, so it's judged against the whole screen
        /// rather than the scrolling area above the bar.
        var pinned = false
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

    private static let missionTitles = ["Start Quest", "Find My Starting Quest"]
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
        let app = XCUIApplication()
        defer { finish(app) }
        XCUIDevice.shared.orientation = .portrait

        app.launchArguments = ["-deterministic-session", "-ui-test"]
        app.launch()

        let nameField = app.textFields["Child name"]
        guard nameField.waitForExistence(timeout: 10) else {
            XCTFail("Profile setup did not appear")
            return
        }
        checkpoint("01-ProfileSetup", app, targets: [
            field("Child name", app, aboveFold: true),
            button("Start Adventure", app, aboveFold: true),
        ])

        let mission = app.buttons.matching(NSPredicate(format: "label IN %@", argumentArray: [Self.missionTitles])).firstMatch
        type("Mia\n", into: nameField)
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
            buttonAmong(Self.missionTitles, app, name: "Mission button", aboveFold: true),
            button("Settings", app, aboveFold: true),
            button("Explore Quest Trail", app),
            button("Open Sticker Book", app),
        ])

        let trail = app.buttons["Explore Quest Trail"]
        if reveal(trail, in: app) {
            trail.tap()
            let back = app.buttons["Go back to home"]
            if back.waitForExistence(timeout: 5) {
                checkpoint("03-QuestMap", app, targets: [
                    button("Go back to home", app, name: "Back", aboveFold: true),
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
                    button("Close sticker book", app, name: "Done", aboveFold: true),
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

        guard app.staticTexts["problemPrompt"].waitForExistence(timeout: 8) else {
            XCTFail("Starting the mission did not open a quest")
            return
        }
        checkpoint("07-Session", app, targets: sessionTargets(app))

        answerCurrentItem(app)
        // Submit sits in the pinned bottom bar, so it never needs scrolling.
        let submit = app.buttons["Submit Answer"]
        if submit.exists, submit.isEnabled {
            submit.tap()
        }
        settle()
        checkpoint("08-SessionFeedback", app, targets: [])

        guard finishSession(app) else {
            // Record where it stopped, so the report shows what the loop couldn't get past.
            checkpoint("08b-SessionStuck", app, targets: [])
            XCTFail("Could not reach the quest summary")
            return
        }

        var modalIndex = 0
        let modalCTA = app.buttons.matching(NSPredicate(format: "label IN %@", argumentArray: [Self.modalCTATitles])).firstMatch
        while modalIndex < 3, modalCTA.waitForExistence(timeout: 3) {
            modalIndex += 1
            checkpoint("09-Celebration\(modalIndex)", app, targets: [
                buttonAmong(Self.modalCTATitles, app, name: "Celebration button", aboveFold: true),
            ])
            reveal(modalCTA, in: app)
            modalCTA.tap()
            settle()
        }

        checkpoint("10-Summary", app, targets: [
            button("Back to Home", app),
            button("Start next recommended quest", app, name: "Start Next Quest", required: false),
        ])
    }

    @MainActor
    func testQuestCheckLayouts() throws {
        let app = XCUIApplication()
        defer { finish(app) }
        XCUIDevice.shared.orientation = .portrait

        // No "-ui-test": the quest check only runs for a real first launch.
        app.launchArguments = ["-deterministic-diagnostic"]
        app.launch()

        let nameField = app.textFields["Child name"]
        guard nameField.waitForExistence(timeout: 10) else {
            throw XCTSkip("A profile already exists on this simulator; erase it to check the first-launch quest check.")
        }
        type("Mia\n", into: nameField)

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
            text("Diagnostic problem prompt", app, name: "Quest check prompt", aboveFold: true),
            button("Read Aloud", app, aboveFold: true),
            buttonPrefixed("Option ", app, name: "First answer"),
            button("I don't know yet", app),
            button("Maybe later", app, required: false),
        ])
    }

    // The formats run in four slices so scripts/ux-matrix/run.sh can give each one a freshly
    // booted simulator: a launch hiccup then costs one slice, not the whole format pass.
    @MainActor
    func testQuestionFormatLayouts1() throws {
        checkFormats(Self.formatSamples[0..<8])
    }

    @MainActor
    func testQuestionFormatLayouts2() throws {
        checkFormats(Self.formatSamples[8..<16])
    }

    @MainActor
    func testQuestionFormatLayouts3() throws {
        checkFormats(Self.formatSamples[16..<24])
    }

    @MainActor
    func testQuestionFormatLayouts4() throws {
        checkFormats(Self.formatSamples[24...])
    }

    @MainActor
    private func checkFormats(_ samples: ArraySlice<(format: String, unit: String)>) {
        let app = XCUIApplication()
        defer { finish(app) }

        for sample in samples {
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

    /// Leaves the simulator as the next test expects it: portrait, with the app closed.
    /// Otherwise the next test's first launch has to force-quit this one's app, which
    /// sometimes fails ("Failed to terminate") and aborts that whole test.
    @MainActor
    private func finish(_ app: XCUIApplication) {
        XCUIDevice.shared.orientation = .portrait
        if app.state != .notRunning {
            app.terminate()
        }
    }

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
            type("2468", into: createField)
            type("2468", into: confirmField)
            app.buttons["Save PIN"].tap()
        }

        let pinField = app.secureTextFields["Parent PIN"]
        guard pinField.waitForExistence(timeout: 5) else {
            XCTFail("Parent gate did not appear")
            return
        }
        checkpoint("05-ParentGate", app, targets: [
            field("Parent PIN", app, secure: true, aboveFold: true),
            button("Unlock Settings", app, aboveFold: true),
        ], scrolls: false)

        type("2468", into: pinField)
        app.buttons["Unlock Settings"].tap()

        guard app.staticTexts["Parent Settings"].waitForExistence(timeout: 5) else {
            XCTFail("Parent Settings did not open after entering the PIN")
            return
        }
        checkpoint("06-ParentSettings", app, targets: [
            button("Done", app, aboveFold: true),
        ], scrolls: false)
    }

    /// Taps a field until it actually has keyboard focus, then types. On slower simulators
    /// a single tap can land before the field is ready, and typeText then fails outright.
    @MainActor
    private func type(_ text: String, into field: XCUIElement) {
        // Just after a rotation a field can briefly report a sideways frame and refuse taps.
        _ = waitUntil(timeout: 3) {
            let frame = field.frame
            return frame.width > frame.height
        }
        for _ in 0..<3 {
            field.tap()
            if waitUntil(timeout: 2, { (field.value(forKey: "hasKeyboardFocus") as? Bool) == true }) {
                break
            }
        }
        field.typeText(text)
    }

    @MainActor
    private func sessionTargets(_ app: XCUIApplication) -> [Target] {
        [
            text("problemPrompt", app, name: "Question prompt", aboveFold: true),
            button("Read Aloud", app, aboveFold: true, pinned: true),
            button("Submit Answer", app, aboveFold: true, pinned: true),
            button("Hint", app, required: false, pinned: true),
            buttonPrefixed("Option ", app, name: "First answer", required: false),
        ]
    }

    /// Picks an answer so Submit is enabled; correctness doesn't matter for layout checks.
    @MainActor
    private func answerCurrentItem(_ app: XCUIApplication) {
        let option = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Option ")).firstMatch
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

    /// Where the quest is ("3 of 7"), read from the progress bar's combined label. It changes on
    /// every new item, even when consecutive items share a prompt ("How many dots?").
    @MainActor
    private func itemPosition(_ app: XCUIApplication) -> String {
        let progress = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label MATCHES %@", ".*[0-9]+ of [0-9]+.*"))
            .firstMatch
        guard progress.exists, let range = progress.label.range(of: #"\d+ of \d+"#, options: .regularExpression) else {
            return ""
        }
        return String(progress.label[range])
    }

    /// Answers until `isDone`. Wrong answers retry once, then show a correction to acknowledge.
    @MainActor
    private func submitUntil(_ app: XCUIApplication, _ isDone: () -> Bool) -> Bool {
        for _ in 0..<8 {
            let acknowledge = app.buttons["Acknowledge correction and continue"]
            if acknowledge.exists {
                reveal(acknowledge, in: app)
                acknowledge.tap()
            } else {
                answerCurrentItem(app)
                let submit = app.buttons["Submit Answer"]
                if submit.exists, submit.isEnabled {
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
        let start = itemPosition(app)
        return submitUntil(app) {
            !reviewMarker.exists || itemPosition(app) != start
        }
    }

    @MainActor
    private func finishSession(_ app: XCUIApplication) -> Bool {
        let backToHome = app.buttons["Back to Home"]
        var items = 0
        while !backToHome.exists && items < FeatureLimits.maxItemsPerQuest {
            items += 1
            let start = itemPosition(app)
            let advanced = submitUntil(app) {
                backToHome.exists || itemPosition(app) != start
            }
            if !advanced {
                break
            }
        }
        return backToHome.waitForExistence(timeout: 5)
    }

    // MARK: - Targets

    @MainActor
    private func button(
        _ label: String,
        _ app: XCUIApplication,
        name: String? = nil,
        aboveFold: Bool = false,
        required: Bool = true,
        pinned: Bool = false
    ) -> Target {
        Target(
            element: app.buttons[label],
            name: name ?? label,
            matches: { $0.type == .button && ($0.label == label || $0.identifier == label) },
            aboveFold: aboveFold,
            required: required,
            pinned: pinned
        )
    }

    @MainActor
    private func buttonAmong(_ labels: [String], _ app: XCUIApplication, name: String, aboveFold: Bool = false) -> Target {
        Target(
            element: app.buttons.matching(NSPredicate(format: "label IN %@", argumentArray: [labels])).firstMatch,
            name: name,
            matches: { $0.type == .button && labels.contains($0.label) },
            aboveFold: aboveFold
        )
    }

    @MainActor
    private func buttonPrefixed(_ prefix: String, _ app: XCUIApplication, name: String, required: Bool = true) -> Target {
        Target(
            element: app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch,
            name: name,
            matches: { $0.type == .button && $0.label.hasPrefix(prefix) },
            required: required
        )
    }

    /// A static text found by accessibility identifier or label.
    @MainActor
    private func text(_ key: String, _ app: XCUIApplication, name: String, aboveFold: Bool = false) -> Target {
        Target(
            element: app.staticTexts[key],
            name: name,
            matches: { $0.type == .staticText && ($0.identifier == key || $0.label == key) },
            aboveFold: aboveFold
        )
    }

    @MainActor
    private func field(_ label: String, _ app: XCUIApplication, secure: Bool = false, aboveFold: Bool = false) -> Target {
        let kind: XCUIElement.ElementType = secure ? .secureTextField : .textField
        return Target(
            element: secure ? app.secureTextFields[label] : app.textFields[label],
            name: label,
            matches: { $0.type == kind && ($0.label == label || $0.identifier == label) },
            aboveFold: aboveFold
        )
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
            rotate(app, to: orientation)
            guard app.state == .runningForeground else {
                XCTFail("\(screen) [\(orientation.rawValue)]: the app is no longer running")
                return
            }
            if scrolls {
                scrollToTop(app)
            }

            // The whole screen: an element screenshot of the app is mis-cropped in landscape.
            let screenshot = XCTAttachment(screenshot: screenCapture(matching: orientation))
            screenshot.name = "LX__\(screen)__\(orientation.rawValue)"
            screenshot.lifetime = .keepAlways
            add(screenshot)

            let root = try? app.snapshot()
            let nodes = root.map { flatten($0) } ?? []
            let bounds = root?.frame ?? app.frame
            let content = contentArea(nodes, bounds: bounds)

            var findings = notes
            findings += root == nil ? ["[audit] Could not read the accessibility tree"] : auditLayout(nodes, bounds: bounds)
            for target in targets {
                findings += check(target, nodes: nodes, area: target.pinned ? bounds : content, screen: screen, orientation: orientation, app: app, scrolls: scrolls)
            }

            // The application element reports "unspecified"; its window carries the real size classes.
            let window = root?.children.first { $0.elementType == .window }
            let sizeClass = window.map { "\(describe($0.horizontalSizeClass))×\(describe($0.verticalSizeClass))" } ?? "unknown"
            let header = [
                "screen: \(screen)",
                "orientation: \(orientation.rawValue)",
                "device: \(ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "unknown")",
                "size-class: \(sizeClass)",
                "screen-size: \(Int(bounds.width))×\(Int(bounds.height)) pt",
                "---",
            ]
            let report = XCTAttachment(string: (header + capped(findings)).joined(separator: "\n"))
            report.name = "LX__\(screen)__\(orientation.rawValue)__findings"
            report.lifetime = .keepAlways
            add(report)
        }

        rotate(app, to: .portrait)
        if scrolls {
            scrollToTop(app)
        }
    }

    @MainActor
    private func check(
        _ target: Target,
        nodes: [Node],
        area: CGRect,
        screen: String,
        orientation: Orientation,
        app: XCUIApplication,
        scrolls: Bool
    ) -> [String] {
        let visible = area.insetBy(dx: -1, dy: -1)
        if let node = nodes.first(where: { target.matches($0) && !$0.frame.isEmpty && visible.contains($0.frame) }) {
            return smallTarget(type: node.type, label: node.label, frame: node.frame)
        }

        // Optional controls only apply to some screens; don't scroll around looking for them.
        if !target.required && !nodes.contains(where: target.matches) {
            return []
        }

        // Slow path: below the fold or not loaded yet, so scroll to it with live queries.
        if scrolls, reveal(target.element, in: app, within: area) {
            var findings = target.aboveFold ? ["[below-fold] \"\(target.name)\" is only reachable by scrolling"] : []
            findings += smallTarget(type: target.element.elementType, label: target.element.label, frame: target.element.frame)
            return findings
        }

        if target.required {
            XCTFail("\(screen) [\(orientation.rawValue)]: \"\(target.name)\" can't be brought on screen")
        }
        return ["[unreachable] \"\(target.name)\" can't be brought on screen"]
    }

    private func auditLayout(_ nodes: [Node], bounds: CGRect) -> [String] {
        let dockFrames = dock(nodes, bounds: bounds).map(\.frame)
        var controls: [(name: String, frame: CGRect)] = []
        var texts: [(name: String, frame: CGRect)] = []
        for node in nodes {
            let frame = node.frame
            // Only judge elements fully on screen vertically; the rest are scrolled away.
            let onScreenVertically = frame.minY >= bounds.minY - 1 && frame.maxY <= bounds.maxY + 1
            // Skip elements scrolled entirely off the side (e.g. later carousel items).
            let touchesScreenHorizontally = frame.maxX > bounds.minX && frame.minX < bounds.maxX
            guard !frame.isEmpty, onScreenVertically, touchesScreenHorizontally else { continue }
            let name = shortName(node.label.isEmpty ? node.identifier : node.label)
            if Self.controlTypes.contains(node.type) {
                controls.append((name, frame))
            } else if node.type == .staticText {
                texts.append((name, frame))
            }
        }

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

        // Only controls: overlapping tap areas cause mis-taps. Text overlaps were mostly labels
        // inside their own buttons; hidden content shows up in the screenshots instead.
        for i in controls.indices {
            for j in controls.indices where j > i {
                let a = controls[i]
                let b = controls[j]
                // Answers pass under the pinned quest bar as they scroll; that's not a collision.
                if dockFrames.contains(a.frame) != dockFrames.contains(b.frame) {
                    continue
                }
                let ratio = overlapRatio(a.frame, b.frame)
                // Near-total overlap is nesting (a control inside its card), not a collision.
                if ratio >= 0.2 && ratio < 0.95 {
                    findings.append("[overlap] \"\(a.name)\" and \"\(b.name)\" overlap by \(Int(ratio * 100))%")
                }
            }
        }
        return findings
    }

    // MARK: - Small helpers

    @MainActor
    private func flatten(_ root: XCUIElementSnapshot) -> [Node] {
        var nodes: [Node] = []
        func visit(_ element: XCUIElementSnapshot) {
            if element.elementType == .keyboard {
                return
            }
            nodes.append(Node(type: element.elementType, label: element.label, identifier: element.identifier, frame: element.frame))
            for child in element.children {
                visit(child)
            }
        }
        visit(root)
        return nodes
    }

    /// The part of the screen where scrolling content is visible: everything above the quest's
    /// pinned bottom bar (Read Aloud, Hint, Submit) when it's showing, otherwise the whole screen.
    private func contentArea(_ nodes: [Node], bounds: CGRect) -> CGRect {
        guard let top = dock(nodes, bounds: bounds).map(\.frame.minY).min() else {
            return bounds
        }
        // The bar has 12 pt of padding above its buttons.
        return CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: max(0, top - 12 - bounds.minY))
    }

    /// The quest's pinned bottom bar buttons, when the bar is showing.
    private func dock(_ nodes: [Node], bounds: CGRect) -> [Node] {
        let labels: Set<String> = ["Read Aloud", "Hint", "Submit Answer"]
        let dock = nodes.filter {
            $0.type == .button && labels.contains($0.label) && $0.frame.minY > bounds.midY
        }
        return dock.contains(where: { $0.label == "Submit Answer" }) ? dock : []
    }

    @MainActor
    private func contentArea(_ app: XCUIApplication) -> CGRect {
        guard let root = try? app.snapshot() else { return app.frame }
        return contentArea(flatten(root), bounds: root.frame)
    }

    @MainActor
    private func isFullyVisible(_ element: XCUIElement, in area: CGRect) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        return !frame.isEmpty && area.insetBy(dx: -1, dy: -1).contains(frame)
    }

    /// Scrolls until `element` is fully inside `area` (default: the visible content area).
    /// Uses slow drags without momentum aimed at the element's position; flick swipes
    /// overshot on short landscape screens, so the element never settled in view.
    @MainActor
    @discardableResult
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, within area: CGRect? = nil) -> Bool {
        let area = area ?? contentArea(app)
        if isFullyVisible(element, in: area) {
            return true
        }
        var lastFrame = CGRect.null
        var blindSteps = 0
        var stalls = 0
        var trail: [String] = []
        // Enough for the Home screen on an iPhone SE in landscape: about 3,000 pt of content
        // at about 200 pt per drag. Stalling ends the loop early when it can't get closer.
        for _ in 0..<30 {
            let offset: CGFloat
            if element.exists, !element.frame.isEmpty {
                let frame = element.frame
                trail.append("\(Int(frame.minY))")
                if frame == lastFrame {
                    // A drag that doesn't move it either hit the end of the content or started
                    // on something that kept the touch. Try once more from the middle.
                    stalls += 1
                    if stalls > 1 {
                        break
                    }
                } else {
                    stalls = 0
                }
                lastFrame = frame
                // Aim for its center a third of the way down the visible area.
                offset = frame.midY - (area.minY + area.height / 3)
            } else {
                // Not loaded yet (lazy content): move down to load more, a few times at most.
                trail.append("-")
                blindSteps += 1
                if blindSteps > 4 {
                    break
                }
                offset = area.height * 0.6
            }
            // Up to 60% of the area per drag. Start near the edge the content moves away
            // from, so the whole drag stays inside the area, or from the middle on a retry.
            let fraction: CGFloat = max(-0.6, min(0.6, offset / max(area.height, 1)))
            // Already where it's aimed but still not fully in view (too big, or cut off at a
            // side): scrolling can't help, and a drag this short would just be a tap.
            if abs(fraction) < 0.03 {
                break
            }
            let start: CGFloat = stalls > 0 ? 0.5 + fraction / 2 : (fraction > 0 ? 0.8 : 0.2)
            drag(app, in: area, from: start, to: start - fraction)
            scrolledSinceTop = true
            if isFullyVisible(element, in: area) {
                return true
            }
        }
        print("LXDIAG reveal gave up on \(element.description): minY after each drag \(trail.joined(separator: " ")), area \(area), app \(app.frame), state \(app.state.rawValue)")
        return false
    }

    /// Drags between two points on the vertical center line of `area`, given as fractions of
    /// its height. Slow drags hold at the end so the content stops exactly; fast ones fling.
    @MainActor
    private func drag(_ app: XCUIApplication, in area: CGRect, from: CGFloat, to: CGFloat, fast: Bool = false) {
        let bounds = app.frame
        guard bounds.height > 0, bounds.width > 0, area.height > 0 else { return }
        func point(_ fraction: CGFloat) -> XCUICoordinate {
            app.coordinate(withNormalizedOffset: CGVector(
                dx: (area.midX - bounds.minX) / bounds.width,
                dy: (area.minY + area.height * fraction - bounds.minY) / bounds.height
            ))
        }
        point(from).press(
            forDuration: fast ? 0.05 : 0.1,
            thenDragTo: point(to),
            withVelocity: fast ? .fast : .slow,
            thenHoldForDuration: fast ? 0 : 0.2
        )
    }

    /// Rotates and waits until the app's frame actually matches, since frames read mid-rotation
    /// come back sideways and every check against them fails.
    @MainActor
    private func rotate(_ app: XCUIApplication, to orientation: Orientation) {
        XCUIDevice.shared.orientation = orientation.deviceOrientation
        settle()
        _ = waitUntil(timeout: 5) {
            let frame = app.frame
            return orientation == .landscape ? frame.width > frame.height : frame.height > frame.width
        }
    }

    /// Flicks back to the top, starting well inside the content. app.swipeDown() pulled down
    /// Notification Center on the iPhone SE in landscape, which then covered the app.
    @MainActor
    private func scrollToTop(_ app: XCUIApplication) {
        guard scrolledSinceTop else { return }
        let area = contentArea(app)
        for _ in 0..<4 {
            drag(app, in: area, from: 0.3, to: 0.9, fast: true)
        }
        settle(0.6)
        scrolledSinceTop = false
    }

    /// Captures the screen once it has caught up with a rotation. Right after one, a capture
    /// can still come back in the old orientation (once, an all-black portrait frame).
    @MainActor
    private func screenCapture(matching orientation: Orientation) -> XCUIScreenshot {
        var capture = XCUIScreen.main.screenshot()
        for _ in 0..<3 {
            let size = capture.image.size
            if (size.width > size.height) == (orientation == .landscape) {
                break
            }
            settle(0.5)
            capture = XCUIScreen.main.screenshot()
        }
        return capture
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

    private func smallTarget(type: XCUIElement.ElementType, label: String, frame: CGRect) -> [String] {
        guard type != .staticText, frame.width < 44 || frame.height < 44 else { return [] }
        return ["[small-target] \"\(shortName(label))\" is \(Int(frame.width))×\(Int(frame.height)) pt (minimum 44×44)"]
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
