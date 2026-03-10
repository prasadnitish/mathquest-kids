import Foundation

struct ReviewScheduler {
    let intervalsInDays = [1, 3, 7, 14, 30]

    func scheduleAfterMastery(from date: Date = .now) -> ReviewScheduleRecord {
        ReviewScheduleRecord(
            childID: UUID(),
            skillID: "",
            nextDueAt: Calendar.current.date(byAdding: .day, value: intervalsInDays[0], to: date) ?? date,
            intervalIndex: 0,
            lapseCount: 0
        )
    }

    func nextDate(currentIndex: Int, from date: Date = .now) -> (Int, Date) {
        let nextIndex = min(currentIndex + 1, intervalsInDays.count - 1)
        let nextDate = Calendar.current.date(byAdding: .day, value: intervalsInDays[nextIndex], to: date) ?? date
        return (nextIndex, nextDate)
    }

    func resetAfterLapse(from date: Date = .now, lapseCount: Int) -> (Int, Int, Date) {
        let nextDate = Calendar.current.date(byAdding: .day, value: intervalsInDays[0], to: date) ?? date
        return (0, lapseCount + 1, nextDate)
    }
}
