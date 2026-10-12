import Foundation
import Testing
@testable import The_Tom_Didary

/// Jednotkové testy pravidel menu. Vstupní datum je explicitní, nečekáme rok ani půlnoc.
/// Test změny letního času se vyhodnocuje v aktuálním pásmu; referenční běh byl Europe/Prague.
@MainActor
struct DiaryStatisticsTests {
    private func statistics(_ dates: [String], today: String) throws -> DiaryStatistics {
        let now = try #require(DiaryDate.parse(today))
        let answers = try dates.map { try #require(DiaryDate.parse($0)) }
        return DiaryStatistics(answerDates: answers, now: now, calendar: DiaryDate.calendar)
    }

    @Test func countsUniqueDaysAndIgnoresFutureAnswers() throws {
        let stats = try statistics(["2025-12-31", "2026-01-01", "2026-01-01", "2026-01-03"], today: "2026-01-02")
        #expect(stats.thisYearCount == 1)
        #expect(stats.totalCount == 2)
        #expect(stats.currentStreak == 2)
        #expect(!stats.showTotalCount)
    }

    @Test func todayExtendsYesterdayStreakWithoutBreakingAnUnfinishedDay() throws {
        let dates = ["2026-10-09", "2026-10-10"]
        #expect(try statistics(dates, today: "2026-10-11").currentStreak == 2)
        #expect(try statistics(dates + ["2026-10-11"], today: "2026-10-11").currentStreak == 3)
    }

    @Test func missedFullDayBreaksStreak() throws {
        #expect(try statistics(["2026-10-09"], today: "2026-10-11").currentStreak == 0)
        #expect(try statistics(["2026-10-09", "2026-10-11"], today: "2026-10-11").currentStreak == 1)
        #expect(try statistics([], today: "2026-10-11").currentStreak == 0)
    }

    @Test func streakCrossesYearAndDaylightSavingBoundaries() throws {
        #expect(try statistics(["2026-12-30", "2026-12-31", "2027-01-01"], today: "2027-01-02").currentStreak == 3)
        #expect(try statistics(["2026-03-28", "2026-03-29", "2026-03-30"], today: "2026-03-30").currentStreak == 3)
        #expect(try statistics(["2026-10-24", "2026-10-25", "2026-10-26"], today: "2026-10-26").currentStreak == 3)
    }

    @Test func totalAppearsOnlyOneYearAndOneDayAfterFirstAnswer() throws {
        #expect(try !statistics(["2025-10-11"], today: "2026-10-11").showTotalCount)
        #expect(try statistics(["2025-10-11"], today: "2026-10-12").showTotalCount)
        #expect(try !statistics([], today: "2026-10-12").showTotalCount)
    }

    @Test func leapDayAnniversaryAppearsOnMarch1() throws {
        #expect(try !statistics(["2024-02-29"], today: "2025-02-28").showTotalCount)
        #expect(try statistics(["2024-02-29"], today: "2025-03-01").showTotalCount)
    }

    @Test func heatmapCoversLeapYearAndDistinguishesStatuses() throws {
        let stats = try statistics(["2024-02-29"], today: "2024-03-01")
        let days = stats.weeks.flatMap { $0 }.compactMap { $0 }
        #expect(days.count == 366)
        #expect(Set(days.map(\.date)).count == 366)
        #expect(days.allSatisfy { DiaryDate.components($0.date).year == 2024 })
        #expect(stats.weeks[0][0]?.date == DiaryDate.calendar.startOfDay(for: try #require(DiaryDate.parse("2024-01-01"))))
        let byDate = Dictionary(uniqueKeysWithValues: days.map { (DiaryDate.string($0.date), $0.status) })
        #expect(byDate["2024-02-28"] == .missed)
        #expect(byDate["2024-02-29"] == .answered)
        #expect(byDate["2024-03-01"] == .pending)
        #expect(byDate["2024-03-02"] == .future)
        let ordinary = try statistics([], today: "2026-10-11")
        #expect(ordinary.weeks.flatMap { $0 }.compactMap { $0 }.count == 365)
        #expect(ordinary.weeks[0].prefix(3).allSatisfy { $0 == nil })
    }
}
