import Foundation
import Testing
@testable import MathQuestKids

struct MathQuestKidsTests {
    @Test
    func masteryPromotionAndRegression() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")
        let engine = MasteryEngine(repository: repo)

        let sessionA = UUID()
        let sessionB = UUID()

        var lastState: MasteryStateRecord?
        for idx in 0..<20 {
            let sessionID = idx < 10 ? sessionA : sessionB
            let isCorrect = idx < 17
            let attempt = AttemptInput(
                childID: profile.id,
                skillID: "sub_within_10",
                unit: .subtractionStories,
                itemID: "item-\(idx)",
                sessionID: sessionID,
                response: isCorrect ? "5" : "4",
                correct: isCorrect,
                latencyMs: 900,
                hintsUsed: 0,
                inputMode: .tap
            )
            lastState = try engine.recordAttempt(attempt)
        }

        #expect(lastState?.status == .mastered)

        for idx in 20..<23 {
            let attempt = AttemptInput(
                childID: profile.id,
                skillID: "sub_within_10",
                unit: .subtractionStories,
                itemID: "item-\(idx)",
                sessionID: sessionB,
                response: "0",
                correct: false,
                latencyMs: 1100,
                hintsUsed: 1,
                inputMode: .tap
            )
            lastState = try engine.recordAttempt(attempt)
        }

        #expect(lastState?.status == .reviewDue)
    }

    @Test
    func reviewSchedulerIntervalsAndLapseReset() {
        let scheduler = ReviewScheduler()
        let date = Date(timeIntervalSince1970: 0)

        let next = scheduler.nextDate(currentIndex: 0, from: date)
        #expect(next.0 == 1)
        #expect(Calendar.current.dateComponents([.day], from: date, to: next.1).day == 3)

        let reset = scheduler.resetAfterLapse(from: date, lapseCount: 2)
        #expect(reset.0 == 0)
        #expect(reset.1 == 3)
        #expect(Calendar.current.dateComponents([.day], from: date, to: reset.2).day == 1)
    }

    @Test
    func contentPackValidationFailure() throws {
        let invalid = ContentPack(
            units: [],
            lessons: [],
            itemTemplates: [],
            hints: [],
            rewards: []
        )

        #expect(throws: (any Error).self) {
            try invalid.validate()
        }
    }

    @Test
    func hintEngineTiering() {
        let pack = ContentPack(
            units: [],
            lessons: [],
            itemTemplates: [],
            hints: [
                HintTemplate(skill: "compare_2digit", concrete: "Concrete", strategy: "Strategy", worked: "Worked")
            ],
            rewards: []
        )

        let engine = DeterministicHintEngine(contentPack: pack)

        let payload = ItemPayload(left: 38, right: 83)
        let low = engine.nextHint(for: AttemptContext(unit: .twoDigitComparison, skillID: "compare_2digit", prompt: "", payload: payload, incorrectAttempts: 0, recentMisconceptions: [], supports: []))
        let mid = engine.nextHint(for: AttemptContext(unit: .twoDigitComparison, skillID: "compare_2digit", prompt: "", payload: payload, incorrectAttempts: 1, recentMisconceptions: [], supports: []))
        let high = engine.nextHint(for: AttemptContext(unit: .twoDigitComparison, skillID: "compare_2digit", prompt: "", payload: payload, incorrectAttempts: 2, recentMisconceptions: [], supports: []))

        switch low {
        case .showConcreteSupport(let text):
            #expect(text == "Concrete")
        default:
            Issue.record("Expected concrete hint for first error tier")
        }

        switch mid {
        case .strategyPrompt(let text):
            #expect(text == "Strategy")
        default:
            Issue.record("Expected strategy hint for second error tier")
        }

        switch high {
        case .workedStep(let text):
            #expect(text == "Worked")
        default:
            Issue.record("Expected worked-step hint for repeated errors")
        }
    }

    @Test
    func integrationAttemptPersistenceAndSessionSummary() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")
        let pack = ContentPack(
            units: [
                UnitDefinition(id: .subtractionStories, title: "Subtraction Stories", order: 1)
            ],
            lessons: [
                LessonDefinition(id: "sub-1", unit: .subtractionStories, title: "Take Away", skill: "sub_within_10")
            ],
            itemTemplates: [
                ItemTemplate(
                    id: "sub-01",
                    unit: .subtractionStories,
                    skill: "sub_within_10",
                    format: .subtractionStory,
                    difficulty: 1,
                    prompt: "9 - 4",
                    answer: "5",
                    supports: [.counters],
                    payload: ItemPayload(left: nil, right: nil, minuend: 9, subtrahend: 4, target: 5, tens: nil, ones: nil)
                )
            ],
            hints: [],
            rewards: [
                RewardDefinition(id: "reward-1", title: "Forest Sticker", description: "desc")
            ]
        )
        let composer = SessionComposer(repository: repo, contentPack: pack, deterministic: true)
        let engine = MasteryEngine(repository: repo)

        try repo.saveReviewSchedule(
            ReviewScheduleRecord(
                childID: profile.id,
                skillID: "sub_within_10",
                nextDueAt: .distantPast,
                intervalIndex: 0,
                lapseCount: 0
            )
        )

        let blueprint = try composer.composeSession(childID: profile.id, focusUnit: .subtractionStories)
        let reviewItems = blueprint.items.filter(\.isReview)
        #expect(reviewItems.count >= 1)
        #expect(Double(reviewItems.count) / Double(blueprint.items.count) >= 0.20)

        for (idx, item) in blueprint.items.enumerated() {
            let attempt = AttemptInput(
                childID: profile.id,
                skillID: item.skillID,
                unit: item.unit,
                itemID: item.id,
                sessionID: blueprint.sessionID,
                response: item.answer,
                correct: true,
                latencyMs: 700,
                hintsUsed: 0,
                inputMode: .tap
            )
            _ = try engine.recordAttempt(attempt)
            #expect(repo.recentAttemptsForSession(sessionID: blueprint.sessionID).count == idx + 1)
        }

        try repo.finishSession(
            sessionID: blueprint.sessionID,
            childID: profile.id,
            unit: blueprint.focusUnit,
            totalItems: Int16(blueprint.items.count),
            correctItems: Int16(blueprint.items.count),
            rewardTitle: "Forest Sticker"
        )

        let log = repo.fetchSessionLog(sessionID: blueprint.sessionID)
        #expect(log?.totalItems == Int16(blueprint.items.count))
        #expect(log?.correctItems == Int16(blueprint.items.count))
        #expect(log?.rewardTitle == "Forest Sticker")
    }

    @Test
    func sessionRuntimeRetriesThenAdvances() {
        let item = PracticeItem(
            id: "sub-1",
            templateID: "sub-1",
            unit: .subtractionStories,
            skillID: "sub_within_10",
            format: .subtractionStory,
            prompt: "9 - 4",
            answer: "5",
            supports: [.counters],
            payload: ItemPayload(left: nil, right: nil, minuend: 9, subtrahend: 4, target: 5, tens: nil, ones: nil),
            options: ["5", "6", "4"],
            isReview: false
        )
        let second = PracticeItem(
            id: "sub-2",
            templateID: "sub-2",
            unit: .subtractionStories,
            skillID: "sub_within_10",
            format: .subtractionStory,
            prompt: "8 - 3",
            answer: "5",
            supports: [.counters],
            payload: ItemPayload(left: nil, right: nil, minuend: 8, subtrahend: 3, target: 5, tens: nil, ones: nil),
            options: ["5", "6", "4"],
            isReview: false
        )
        let blueprint = SessionBlueprint(
            sessionID: UUID(),
            childID: UUID(),
            focusUnit: .subtractionStories,
            items: [item, second],
            startedAt: .now
        )
        var runtime = SessionRuntime(blueprint: blueprint)

        runtime.recordSubmission(correct: false)
        #expect(runtime.index == 0)
        #expect(runtime.isComplete == false)

        runtime.recordSubmission(correct: false)
        #expect(runtime.index == 1)
        #expect(runtime.isComplete == false)

        runtime.recordSubmission(correct: true)
        #expect(runtime.isComplete == true)
    }

    @Test
    func sessionComposerUsesFallbackInterleavingWhenNoDueReviews() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")

        let pack = ContentPack(
            units: [
                UnitDefinition(id: .subtractionStories, title: "Subtraction Stories", order: 1),
                UnitDefinition(id: .teenPlaceValue, title: "Teen Place Value", order: 2)
            ],
            lessons: [],
            itemTemplates: [
                ItemTemplate(
                    id: "sub-1",
                    unit: .subtractionStories,
                    skill: "sub",
                    format: .subtractionStory,
                    difficulty: 1,
                    prompt: "9 - 4",
                    answer: "5",
                    supports: [.counters],
                    payload: ItemPayload(left: nil, right: nil, minuend: 9, subtrahend: 4, target: 5, tens: nil, ones: nil)
                ),
                ItemTemplate(
                    id: "pv-1",
                    unit: .teenPlaceValue,
                    skill: "teen",
                    format: .teenPlaceValue,
                    difficulty: 1,
                    prompt: "Build 14",
                    answer: "1|4",
                    supports: [.placeValueMat],
                    payload: ItemPayload(left: nil, right: nil, minuend: nil, subtrahend: nil, target: 14, tens: 1, ones: 4)
                )
            ],
            hints: [],
            rewards: []
        )

        let composer = SessionComposer(repository: repo, contentPack: pack, deterministic: true)
        let blueprint = try composer.composeSession(childID: profile.id, focusUnit: .subtractionStories)
        let reviewItems = blueprint.items.filter(\.isReview)
        #expect(reviewItems.count >= 1)
    }

    @Test
    func masteredDueReviewAdvancesInterval() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")
        let engine = MasteryEngine(repository: repo)

        let sessionA = UUID()
        let sessionB = UUID()
        for idx in 0..<20 {
            let attempt = AttemptInput(
                childID: profile.id,
                skillID: "sub_within_10",
                unit: .subtractionStories,
                itemID: "item-\(idx)",
                sessionID: idx < 10 ? sessionA : sessionB,
                response: "5",
                correct: true,
                latencyMs: 500,
                hintsUsed: 0,
                inputMode: .tap
            )
            _ = try engine.recordAttempt(attempt)
        }

        let existing = repo.fetchReviewSchedule(childID: profile.id, skillID: "sub_within_10")
        #expect(existing != nil)

        try repo.saveReviewSchedule(
            ReviewScheduleRecord(
                childID: profile.id,
                skillID: "sub_within_10",
                nextDueAt: .distantPast,
                intervalIndex: 0,
                lapseCount: 0
            )
        )

        let nextAttempt = AttemptInput(
            childID: profile.id,
            skillID: "sub_within_10",
            unit: .subtractionStories,
            itemID: "item-21",
            sessionID: sessionA,
            response: "5",
            correct: true,
            latencyMs: 450,
            hintsUsed: 0,
            inputMode: .tap
        )
        _ = try engine.recordAttempt(nextAttempt)

        let advanced = repo.fetchReviewSchedule(childID: profile.id, skillID: "sub_within_10")
        #expect(Int(advanced?.intervalIndex ?? -1) >= 1)
    }

    @Test
    func curriculumCatalogValidationAndCoverage() throws {
        let catalog = CurriculumCatalog(
            grades: GradeBand.allCases.map { grade in
                GradePlan(
                    grade: grade,
                    overview: "\(grade.title) overview",
                    bigIdeas: ["Big idea"],
                    lessons: [
                        LessonPlanItem(
                            id: "lesson-\(grade.rawValue)",
                            grade: grade,
                            title: "Lesson",
                            domain: .operationsAlgebraicThinking,
                            objective: "Objective",
                            standards: ["CCSS"],
                            strategies: [.concretePictorialAbstract, .mathTalk],
                            estimatedMinutes: 20,
                            isPlayableInApp: grade == .grade1,
                            linkedUnit: grade == .grade1 ? .subtractionStories : nil,
                            activityPrompt: "Prompt"
                        )
                    ]
                )
            }
        )

        try catalog.validate()
        #expect(catalog.grades.count == 6)
        #expect(catalog.lessons(for: .grade1).count == 1)
    }

    @Test
    func diagnosticPlacementFeedsAdaptivePlanner() {
        let service = DiagnosticService(deterministic: true)
        var session = service.makeSession()

        for idx in session.questions.indices {
            let question = session.questions[idx]
            let choice = idx < 8 ? question.correctIndex : max(0, question.correctIndex == 0 ? 1 : 0)
            session.submit(choiceIndex: choice)
        }

        let catalog = CurriculumCatalog(
            grades: GradeBand.allCases.map { grade in
                GradePlan(
                    grade: grade,
                    overview: "\(grade.title) overview",
                    bigIdeas: ["Big idea"],
                    lessons: [
                        LessonPlanItem(
                            id: "\(grade.rawValue)-oa",
                            grade: grade,
                            title: "\(grade.title) OA",
                            domain: .operationsAlgebraicThinking,
                            objective: "Objective",
                            standards: ["CCSS"],
                            strategies: [.barModeling, .spiralReview],
                            estimatedMinutes: 20,
                            isPlayableInApp: grade == .grade1 || grade == .grade2,
                            linkedUnit: grade == .grade1 ? .subtractionStories : (grade == .grade2 ? .twoDigitComparison : nil),
                            activityPrompt: "Prompt"
                        ),
                        LessonPlanItem(
                            id: "\(grade.rawValue)-pv",
                            grade: grade,
                            title: "\(grade.title) Place Value",
                            domain: .numberOperationsBaseTen,
                            objective: "Objective",
                            standards: ["CCSS"],
                            strategies: [.concretePictorialAbstract, .variationTheory],
                            estimatedMinutes: 18,
                            isPlayableInApp: grade == .grade1,
                            linkedUnit: grade == .grade1 ? .teenPlaceValue : nil,
                            activityPrompt: "Prompt"
                        )
                    ]
                )
            }
        )

        let result = service.evaluate(session: session, childID: UUID(), catalog: catalog)
        let planner = AdaptiveLessonPlanner()
        let path = planner.buildPath(result: result, catalog: catalog)

        #expect(path.recommendedLessons.isEmpty == false)
        #expect(path.pedagogyHighlights.isEmpty == false)
        #expect(path.placedGrade.order >= GradeBand.kindergarten.order)
    }

    @Test
    func sessionComposerSupportsNewGradeFormats() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")

        let pack = ContentPack(
            units: [
                UnitDefinition(id: .volumeAndDecimals, title: "Volume & Decimals", order: 1),
                UnitDefinition(id: .fractionComparison, title: "Fraction Comparison", order: 2)
            ],
            lessons: [],
            itemTemplates: [
                ItemTemplate(
                    id: "vol-1",
                    unit: .volumeAndDecimals,
                    skill: "volume_prism",
                    format: .volumePrism,
                    difficulty: 1,
                    prompt: "2 x 3 x 4",
                    answer: "24",
                    supports: [.areaModel],
                    payload: ItemPayload(target: 24, length: 2, width: 3, height: 4)
                ),
                ItemTemplate(
                    id: "dec-1",
                    unit: .volumeAndDecimals,
                    skill: "decimal_compare",
                    format: .decimalComparison,
                    difficulty: 1,
                    prompt: "Compare 0.450 and 0.405",
                    answer: ">",
                    supports: [.decimalGrid],
                    payload: ItemPayload(decimalLeft: 0.450, decimalRight: 0.405)
                ),
                ItemTemplate(
                    id: "frac-1",
                    unit: .fractionComparison,
                    skill: "fraction_compare",
                    format: .fractionComparison,
                    difficulty: 1,
                    prompt: "Compare 3/4 and 2/3",
                    answer: ">",
                    supports: [.fractionStrip],
                    payload: ItemPayload(numeratorA: 3, denominatorA: 4, numeratorB: 2, denominatorB: 3)
                )
            ],
            hints: [],
            rewards: []
        )

        let composer = SessionComposer(repository: repo, contentPack: pack, deterministic: true)
        let blueprint = try composer.composeSession(childID: profile.id, focusUnit: UnitType.volumeAndDecimals)

        #expect(blueprint.items.contains(where: { $0.format == ItemFormat.volumePrism && $0.options.isEmpty == false }))
        #expect(blueprint.items.contains(where: { $0.format == ItemFormat.decimalComparison && $0.options == ["<", ">", "="] }))
    }

    @Test
    func expandedContentPackHasGradeTwoToFiveUnits() throws {
        let pack = try ContentLoader.loadDefaultPack()
        let unitIDs = Set(pack.units.map(\.id))

        #expect(unitIDs.contains(UnitType.threeDigitComparison))
        #expect(unitIDs.contains(UnitType.multiplicationArrays))
        #expect(unitIDs.contains(UnitType.fractionComparison))
        #expect(unitIDs.contains(UnitType.fractionOfWhole))
        #expect(unitIDs.contains(UnitType.volumeAndDecimals))
    }

    @Test
    func adaptiveSessionLengthScalesByPlacementAndUnit() {
        #expect(FeatureFlags.adaptiveSessionItems(for: .subtractionStories, placedGrade: .kindergarten) == 5)
        #expect(FeatureFlags.adaptiveSessionItems(for: .teenPlaceValue, placedGrade: .grade1) == 6)
        #expect(FeatureFlags.adaptiveSessionItems(for: .twoDigitComparison, placedGrade: .grade2) == 7)
        #expect(FeatureFlags.adaptiveSessionItems(for: .volumeAndDecimals, placedGrade: .grade5) == 9)
    }

    @Test
    func sessionComposerRespectsRequestedAdaptiveLength() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")

        let pack = ContentPack(
            units: [
                UnitDefinition(id: .subtractionStories, title: "Subtraction Stories", order: 1),
                UnitDefinition(id: .teenPlaceValue, title: "Teen Place Value", order: 2)
            ],
            lessons: [],
            itemTemplates: [
                ItemTemplate(
                    id: "sub-1",
                    unit: .subtractionStories,
                    skill: "sub",
                    format: .subtractionStory,
                    difficulty: 1,
                    prompt: "9 - 4",
                    answer: "5",
                    supports: [.counters],
                    payload: ItemPayload(minuend: 9, subtrahend: 4, target: 5)
                ),
                ItemTemplate(
                    id: "sub-2",
                    unit: .subtractionStories,
                    skill: "sub",
                    format: .subtractionStory,
                    difficulty: 1,
                    prompt: "8 - 3",
                    answer: "5",
                    supports: [.counters],
                    payload: ItemPayload(minuend: 8, subtrahend: 3, target: 5)
                ),
                ItemTemplate(
                    id: "sub-3",
                    unit: .subtractionStories,
                    skill: "sub",
                    format: .subtractionStory,
                    difficulty: 1,
                    prompt: "7 - 2",
                    answer: "5",
                    supports: [.counters],
                    payload: ItemPayload(minuend: 7, subtrahend: 2, target: 5)
                ),
                ItemTemplate(
                    id: "sub-4",
                    unit: .subtractionStories,
                    skill: "sub",
                    format: .subtractionStory,
                    difficulty: 1,
                    prompt: "6 - 1",
                    answer: "5",
                    supports: [.counters],
                    payload: ItemPayload(minuend: 6, subtrahend: 1, target: 5)
                ),
                ItemTemplate(
                    id: "sub-5",
                    unit: .subtractionStories,
                    skill: "sub",
                    format: .subtractionStory,
                    difficulty: 1,
                    prompt: "10 - 5",
                    answer: "5",
                    supports: [.counters],
                    payload: ItemPayload(minuend: 10, subtrahend: 5, target: 5)
                ),
                ItemTemplate(
                    id: "pv-1",
                    unit: .teenPlaceValue,
                    skill: "teen",
                    format: .teenPlaceValue,
                    difficulty: 1,
                    prompt: "Build 14",
                    answer: "1|4",
                    supports: [.placeValueMat],
                    payload: ItemPayload(target: 14, tens: 1, ones: 4)
                )
            ],
            hints: [],
            rewards: []
        )

        let composer = SessionComposer(repository: repo, contentPack: pack, deterministic: true)
        let blueprint = try composer.composeSession(
            childID: profile.id,
            focusUnit: .subtractionStories,
            targetItemCount: 5
        )

        #expect(blueprint.items.count == 5)
        let reviewItems = blueprint.items.filter(\.isReview)
        #expect(reviewItems.count >= 1)
    }

    // MARK: - K-G2 Content Pack Tests

    @Test
    func kContentPackHasCountAndBondUnits() throws {
        let pack = try ContentLoader.loadDefaultPack()
        let unitIDs = Set(pack.units.map(\.id))
        #expect(unitIDs.contains(.kCountObjects))
        #expect(unitIDs.contains(.kComposeDecompose))
        let countTemplates = pack.templates(for: .kCountObjects)
        let bondTemplates = pack.templates(for: .kComposeDecompose)
        #expect(countTemplates.count >= 5)
        #expect(bondTemplates.count >= 5)
    }

    @Test
    func kAndG1AdditionUnitsExistInPack() throws {
        let pack = try ContentLoader.loadDefaultPack()
        let unitIDs = Set(pack.units.map(\.id))
        #expect(unitIDs.contains(.kAddWithin5))
        #expect(unitIDs.contains(.kAddWithin10))
        #expect(unitIDs.contains(.g1AddWithin20))
        #expect(unitIDs.contains(.g1FactFamilies))
        #expect(pack.templates(for: .kAddWithin5).count >= 5)
        #expect(pack.templates(for: .kAddWithin10).count >= 5)
        #expect(pack.templates(for: .g1AddWithin20).count >= 5)
        #expect(pack.templates(for: .g1FactFamilies).count >= 5)
    }

    @Test
    func g2UnitsExistInPack() throws {
        let pack = try ContentLoader.loadDefaultPack()
        let unitIDs = Set(pack.units.map(\.id))
        #expect(unitIDs.contains(.g2AddWithin100))
        #expect(unitIDs.contains(.g2SubWithin100))
        #expect(pack.templates(for: .g2AddWithin100).count >= 5)
        #expect(pack.templates(for: .g2SubWithin100).count >= 5)
    }

    @Test
    func stickerRecordPersistsAndLoads() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")

        try repo.saveStickerEarned(childID: profile.id, unitRaw: "kAddWithin5", dateEarned: .now)
        let stickers = repo.fetchStickers(childID: profile.id)
        #expect(stickers.count == 1)
        #expect(stickers.first?.unitRaw == "kAddWithin5")

        // Verify no duplicates
        try repo.saveStickerEarned(childID: profile.id, unitRaw: "kAddWithin5", dateEarned: .now)
        let stickers2 = repo.fetchStickers(childID: profile.id)
        #expect(stickers2.count == 1)
    }

    @Test
    func stickerCollectionBuildsFromRecords() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")
        try repo.saveStickerEarned(childID: profile.id, unitRaw: "kAddWithin5", dateEarned: .now)

        let records = repo.fetchStickers(childID: profile.id)
        let collection = StickerCollection.build(from: records)

        #expect(collection.earnedCount == 1)
        let sticker = collection.stickers.first(where: { $0.unitType == .kAddWithin5 })
        #expect(sticker?.isUnlocked == true)
    }

    @Test
    func progressReportServiceBuildsReport() throws {
        let stack = CoreDataStack(inMemory: true)
        let repo = ProgressRepository(coreDataStack: stack)
        let profile = try repo.createOrLoadProfile(name: "Kid")
        let catalog = try CurriculumService.loadDefaultCatalog()
        let service = ProgressReportService(repository: repo, catalog: catalog)

        let dashboard = DashboardSnapshot(completedSessions: 2, averageAccuracy: 0.80, streakDays: 3, unitProgress: [])
        let report = service.buildReport(for: profile, dashboard: dashboard, placedGrade: .kindergarten)

        #expect(report.childName == "Kid")
        #expect(report.gradePlacement == GradeBand.kindergarten.title)
        #expect(report.streakDays == 3)
    }

    @Test
    func lessonPlanKindergartenAdditionIsPlayable() throws {
        let catalog = try CurriculumService.loadDefaultCatalog()
        let kLessons = catalog.lessons(for: .kindergarten)
        let playable = kLessons.filter(\.isPlayableInApp)
        let domains = Set(playable.map(\.domain.rawValue))
        #expect(domains.contains("operationsAlgebraicThinking"))
        #expect(playable.count >= 4)
    }

    // MARK: - Recommended Quest Tests

    @Test
    func adaptivePlannerNoResultReturnsKindergartenPath() {
        let catalog = makeMiniCatalog()
        let planner = AdaptiveLessonPlanner()
        let path = planner.buildPath(result: nil, catalog: catalog)

        #expect(path.placedGrade == .kindergarten)
        #expect(path.confidence == 0)
        #expect(path.recommendedLessons.count <= 6)
        #expect(path.supportLessons.isEmpty)
    }

    @Test
    func adaptivePlannerWeakDomainsSortedFirst() {
        let catalog = makeMiniCatalog()
        let planner = AdaptiveLessonPlanner()
        let result = DiagnosticResult(
            childID: UUID(),
            completedAt: .now,
            placedGrade: .grade2,
            confidence: 0.75,
            overallScore: 0.65,
            domainScores: ["operationsAlgebraicThinking": 0.3, "numberOperationsBaseTen": 0.9],
            recommendedLessonIDs: [],
            missedDomains: ["operationsAlgebraicThinking"]
        )
        let path = planner.buildPath(result: result, catalog: catalog)

        #expect(path.placedGrade == .grade2)
        #expect(path.confidence == 0.75)
        // Weak domain lessons should be sorted before strong domain lessons
        if let first = path.recommendedLessons.first {
            #expect(first.domain == .operationsAlgebraicThinking)
        }
    }

    @Test
    func adaptivePlannerBuildsSupportAndStretchLessons() {
        let catalog = makeMiniCatalog()
        let planner = AdaptiveLessonPlanner()
        let result = DiagnosticResult(
            childID: UUID(),
            completedAt: .now,
            placedGrade: .grade2,
            confidence: 0.70,
            overallScore: 0.60,
            domainScores: [:],
            recommendedLessonIDs: [],
            missedDomains: []
        )
        let path = planner.buildPath(result: result, catalog: catalog)

        // Grade 2 should have Grade 1 support lessons and Grade 3 stretch lessons
        #expect(!path.supportLessons.isEmpty)
        #expect(path.supportLessons.allSatisfy { $0.grade == .grade1 })
        #expect(!path.stretchLessons.isEmpty)
        #expect(path.stretchLessons.allSatisfy { $0.grade == .grade3 })
    }

    @Test
    func sessionRuntimeAnsweredCountOnlyIncrementsOnItemCompletion() {
        let items = [
            PracticeItem(
                id: "t1-0", templateID: "t1", unit: .subtractionStories, skillID: "sub",
                format: .subtractionStory, prompt: "9 - 4", spokenForm: nil,
                answer: "5", supports: [], payload: ItemPayload(target: 5),
                options: ["3", "4", "5", "6"], isReview: false
            )
        ]
        let blueprint = SessionBlueprint(
            sessionID: UUID(), childID: UUID(), focusUnit: .subtractionStories,
            items: items, startedAt: .now
        )
        var runtime = SessionRuntime(blueprint: blueprint)

        // First wrong answer: answeredCount should NOT increment (item not complete)
        runtime.recordSubmission(correct: false)
        #expect(runtime.answeredCount == 0)
        #expect(runtime.pendingAdvance == false)

        // Second wrong answer: item completes, answeredCount increments
        runtime.recordSubmission(correct: false)
        #expect(runtime.answeredCount == 1)
        #expect(runtime.pendingAdvance == true)
    }

    @Test
    func sessionRuntimeCorrectAnswerIncrementsAnsweredCount() {
        let items = [
            PracticeItem(
                id: "t1-0", templateID: "t1", unit: .subtractionStories, skillID: "sub",
                format: .subtractionStory, prompt: "9 - 4", spokenForm: nil,
                answer: "5", supports: [], payload: ItemPayload(target: 5),
                options: ["3", "4", "5", "6"], isReview: false
            ),
            PracticeItem(
                id: "t2-0", templateID: "t2", unit: .subtractionStories, skillID: "sub",
                format: .subtractionStory, prompt: "8 - 3", spokenForm: nil,
                answer: "5", supports: [], payload: ItemPayload(target: 5),
                options: ["3", "4", "5", "6"], isReview: false
            )
        ]
        let blueprint = SessionBlueprint(
            sessionID: UUID(), childID: UUID(), focusUnit: .subtractionStories,
            items: items, startedAt: .now
        )
        var runtime = SessionRuntime(blueprint: blueprint)

        runtime.recordSubmission(correct: true)
        #expect(runtime.answeredCount == 1)
        #expect(runtime.correctCount == 1)
        #expect(runtime.pendingAdvance == true)

        // Advance then answer second
        runtime.advanceIfPending()
        #expect(runtime.index == 1)

        runtime.recordSubmission(correct: true)
        #expect(runtime.answeredCount == 2)
        #expect(runtime.isComplete == true)
    }

    @Test
    func adaptivePlannerPrioritizesRecommendedLessonIDs() {
        let catalog = makeMiniCatalog()
        let planner = AdaptiveLessonPlanner()
        let result = DiagnosticResult(
            childID: UUID(),
            completedAt: .now,
            placedGrade: .grade1,
            confidence: 0.80,
            overallScore: 0.75,
            domainScores: [:],
            recommendedLessonIDs: ["grade1-oa"],
            missedDomains: []
        )
        let path = planner.buildPath(result: result, catalog: catalog)

        // Should use the explicit recommended IDs, not fall back to grade lessons
        #expect(path.recommendedLessons.first?.id == "grade1-oa")
    }

    @Test
    func adaptivePlannerG5HasNoStretchLessons() {
        let catalog = makeMiniCatalog()
        let planner = AdaptiveLessonPlanner()
        let result = DiagnosticResult(
            childID: UUID(),
            completedAt: .now,
            placedGrade: .grade5,
            confidence: 0.90,
            overallScore: 0.85,
            domainScores: [:],
            recommendedLessonIDs: [],
            missedDomains: []
        )
        let path = planner.buildPath(result: result, catalog: catalog)

        #expect(path.stretchLessons.isEmpty) // No grade beyond G5
        #expect(!path.supportLessons.isEmpty) // G4 support should exist
    }

    // MARK: - Test Helpers

    private func makeMiniCatalog() -> CurriculumCatalog {
        CurriculumCatalog(
            grades: GradeBand.allCases.map { grade in
                GradePlan(
                    grade: grade,
                    overview: "\(grade.title) overview",
                    bigIdeas: ["Big idea"],
                    lessons: [
                        LessonPlanItem(
                            id: "\(grade.rawValue)-oa",
                            grade: grade,
                            title: "\(grade.title) Operations",
                            domain: .operationsAlgebraicThinking,
                            objective: "Objective",
                            standards: ["CCSS"],
                            strategies: [.barModeling, .spiralReview],
                            estimatedMinutes: 20,
                            isPlayableInApp: true,
                            linkedUnit: .subtractionStories,
                            activityPrompt: "Prompt"
                        ),
                        LessonPlanItem(
                            id: "\(grade.rawValue)-pv",
                            grade: grade,
                            title: "\(grade.title) Place Value",
                            domain: .numberOperationsBaseTen,
                            objective: "Objective",
                            standards: ["CCSS"],
                            strategies: [.concretePictorialAbstract],
                            estimatedMinutes: 18,
                            isPlayableInApp: true,
                            linkedUnit: .teenPlaceValue,
                            activityPrompt: "Prompt"
                        )
                    ]
                )
            }
        )
    }
}
