// xcode: set sdk=iOS

import Foundation
import Testing
import SwiftData
@testable import The_Tom_Didary

/// Datové testy Swift Testing: otázky, data, ukládání a neměnnost uzavřených dnů.
/// Testy používají vlastní kontexty; trvalý test ukládá do dočasné složky a uklidí ji.
@MainActor
struct DiaryTests {
    @Test func bundledQuestionsCoverEveryCalendarDay() throws {
        let provider = QuestionProvider()
        #expect(provider.loadError == nil)
        #expect(provider.questions.count == 366)
        #expect(Set(provider.questions.map(\.id)).count == 366)
        for year in [2023, 2024] {
            var date = try #require(DiaryDate.parse("\(year)-01-01"))
            while DiaryDate.components(date).year == year {
                let c = DiaryDate.components(date)
                let q = try #require(provider.question(day: c.day!, month: c.month!))
                #expect(!q.prompt.isEmpty)
                #expect((1...2).contains(q.emoji.count))
                date = try #require(DiaryDate.calendar.date(byAdding: .day, value: 1, to: date))
            }
        }
        #expect(provider.question(day: 29, month: 2)?.prompt == "Jak hodnotíš zpětně 4 roky od posledního 29.2.?")
        #expect(provider.question(day: 13, month: 9)?.displayPrompt == "Co by ti nyní zlepšilo náladu? 🌤️")
    }

    @Test func datesRejectInvalidLeapDays() {
        #expect(DiaryDate.parse("2024-02-29") != nil)
        #expect(DiaryDate.parse("2023-02-29") == nil)
        #expect(DiaryDate.parse("2026-04-31") == nil)
        #expect(DiaryDate.parse("2026-13-01") == nil)
        for value in ["2026-x-09-20", "2026--09-20", "0000-01-01", "2026-9-20"] {
            #expect(DiaryDate.parse(value) == nil)
        }
    }

    @Test func malformedQuestionResourcesFailVisibly() throws {
        let provider = QuestionProvider()
        var rows = provider.questions.map { ["datum": "\($0.day). \(["leden", "únor", "březen", "duben", "květen", "červen", "červenec", "srpen", "září", "říjen", "listopad", "prosinec"][$0.month - 1])", "otazka": $0.prompt, "emoji": $0.emoji] }
        rows[1] = rows[0]
        let data = try JSONSerialization.data(withJSONObject: rows)
        #expect(throws: (any Error).self) { try QuestionProvider.decode(data) }
        #expect(throws: (any Error).self) { try QuestionProvider.decode(Data("[]".utf8)) }
    }

    @Test func savingUpdatesOneAnswerAndIgnoresWhitespace() throws {
        let container = try ModelContainer(for: Answer.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let date = try #require(DiaryDate.parse("2024-02-29"))
        try AnswerStore.save(" První odpověď \n", on: date, in: context, now: date)
        try AnswerStore.save("Upravená odpověď", on: date, in: context, now: date)
        try AnswerStore.save(" \n ", on: date, in: context, now: date)
        let rows = try context.fetch(FetchDescriptor<Answer>())
        #expect(rows.count == 1)
        #expect(rows.first?.text == "Upravená odpověď")
        #expect(rows.first?.day == 29)
        #expect(rows.first?.month == 2)
        #expect(rows.first?.year == 2024)
    }

    @Test func historyMatchesMonthAndDayAndExcludesFutureYears() throws {
        let container = try ModelContainer(for: Answer.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        for value in ["2023-03-01", "2024-03-01", "2025-03-01", "2026-03-01", "2024-02-29", "2024-04-01"] {
            let date = try #require(DiaryDate.parse(value))
            try AnswerStore.save(value, on: date, in: context, now: date)
        }
        let rows = try context.fetch(FetchDescriptor<Answer>())
        let history = AnswerStore.previousYears(on: try #require(DiaryDate.parse("2025-03-01")), in: rows)
        #expect(history.map(\.year) == [2024, 2023])
        #expect(history.map(\.text) == ["2024-03-01", "2023-03-01"])
    }

    // Nový kontejner se stejným souborem ověří disk, nejen hodnoty žijící v paměti.
    @Test func answerSurvivesReopeningPersistentStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let date = try #require(DiaryDate.parse("2024-12-31"))
        do {
            let container = try ModelContainer(for: Answer.self, configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
            let context = ModelContext(container)
            try AnswerStore.save("Původní odpověď", on: date, in: context, now: date)
            try AnswerStore.save("Přetrvá po zavření", on: date, in: context, now: date)
            try AnswerStore.save("Přetrvá po zavření", on: date, in: context, now: date)
            let nextDay = try #require(DiaryDate.parse("2025-01-01"))
            try AnswerStore.save("Nový rok", on: nextDay, in: context, now: nextDay)
        }
        let reopened = try ModelContainer(for: Answer.self, configurations: ModelConfiguration(url: url, cloudKitDatabase: .none))
        let rows = try ModelContext(reopened).fetch(FetchDescriptor<Answer>())
        #expect(AnswerStore.answer(on: date, in: rows)?.text == "Přetrvá po zavření")
        #expect(rows.count == 2)
        #expect(AnswerStore.answer(on: try #require(DiaryDate.parse("2025-01-01")), in: rows)?.text == "Nový rok")
    }
    @Test func leapDayHistoryNeverIncludesFebruary28OrMarch1() throws {
        let container = try ModelContainer(for: Answer.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        for value in ["2020-02-29", "2024-02-29", "2023-02-28", "2023-03-01", "2028-02-29"] {
            let date = try #require(DiaryDate.parse(value))
            try AnswerStore.save(value, on: date, in: context, now: date)
        }
        let rows = try context.fetch(FetchDescriptor<Answer>())
        let history = AnswerStore.previousYears(on: try #require(DiaryDate.parse("2028-02-29")), in: rows)
        #expect(history.map(\.text) == ["2024-02-29", "2020-02-29"])
    }

    @Test func closedDaysCannotBeCreatedOrEdited() throws {
        let container = try ModelContainer(for: Answer.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let day = try #require(DiaryDate.parse("2026-12-31"))
        let nextDay = try #require(DiaryDate.parse("2027-01-01"))
        try AnswerStore.save("Původní odpověď", on: day, in: context, now: day)
        #expect(throws: AnswerStoreError.self) {
            try AnswerStore.save("Zakázaná úprava", on: day, in: context, now: nextDay)
        }
        #expect(throws: AnswerStoreError.self) {
            try AnswerStore.save("Budoucí zápis", on: nextDay, in: context, now: day)
        }
        let rows = try context.fetch(FetchDescriptor<Answer>())
        #expect(rows.count == 1)
        #expect(rows.first?.text == "Původní odpověď")
    }

    @Test func editPermissionExpiresAtMidnight() throws {
        let day = try #require(DiaryDate.parse("2026-10-11"))
        let midnight = DiaryDate.calendar.startOfDay(for: try #require(DiaryDate.parse("2026-10-12")))
        #expect(DiaryDate.canWrite(on: day, now: midnight.addingTimeInterval(-1)))
        #expect(!DiaryDate.canWrite(on: day, now: midnight))
        #expect(!DiaryDate.canWrite(on: day, now: midnight.addingTimeInterval(1)))
    }

}
