import Foundation

/// Výpočty menu bez závislosti na SwiftData nebo SwiftUI. Přijímá pouze data
/// skutečných odpovědí a čas, což umožňuje přesné testování kalendářních hranic.
struct DiaryStatistics {
    /// `pending` je dnešní dosud nevyplněný den; ještě se nepočítá jako vynechaný.
    enum DayStatus: String {
        case answered, missed, pending, future
    }

    struct Day: Identifiable {
        let date: Date
        let status: DayStatus
        var id: Date { date }
    }

    let calendar: Calendar
    let today: Date
    let answeredDays: Set<Date>
    let year: Int

    /// Normalizace na začátek dne odstraní vliv hodin; Set odstraní duplicity.
    /// Budoucí záznamy se do žádného aktuálního součtu nezahrnou.
    init(answerDates: [Date], now: Date, calendar: Calendar) {
        self.calendar = calendar
        let currentDay = calendar.startOfDay(for: now)
        today = currentDay
        year = calendar.component(.year, from: now)
        answeredDays = Set(answerDates.map { calendar.startOfDay(for: $0) }.filter { $0 <= currentDay })
    }

    var thisYearCount: Int {
        answeredDays.filter { calendar.component(.year, from: $0) == year }.count
    }

    var totalCount: Int { answeredDays.count }

    /// Druhý součet odkryjeme až rok a jeden den po prvním zaznamenaném dni.
    /// Počítáme kalendářní rok: výročí 29. 2. vychází na 28. 2., odkrytí pak na 1. 3.
    var showTotalCount: Bool {
        guard let first = answeredDays.min(),
              let anniversary = calendar.date(byAdding: .year, value: 1, to: first),
              let revealDay = calendar.date(byAdding: .day, value: 1, to: anniversary) else { return false }
        return today >= revealDay
    }

    /// Počet navazujících vyplněných dnů končících dnes, případně včera.
    var currentStreak: Int {
        // Nevyplněný dnešek zachová včerejší sérii; celý vynechaný včerejšek ji přeruší.
        var cursor = today
        if !answeredDays.contains(cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        var count = 0
        while answeredDays.contains(cursor) {
            count += 1
            // Přičítáme kalendářní dny, nikoli 86 400 sekund: funguje i změna času.
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    /// Sloupce týdnů od pondělí, každý má 7 řádků. `nil` je prázdné místo před
    /// 1. lednem nebo za 31. prosincem, nikoli chybějící odpověď uvnitř roku.
    var weeks: [[Day?]] {
        guard let first = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let nextYear = calendar.date(byAdding: .year, value: 1, to: first),
              let days = calendar.dateComponents([.day], from: first, to: nextYear).day else { return [] }
        let leadingDays = (calendar.component(.weekday, from: first) + 5) % 7 // Převod Sunday=1 na Monday=0.
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: first) else { return [] }
        return (0..<((leadingDays + days + 6) / 7)).map { week in
            (0..<7).map { weekday in
                guard let date = calendar.date(byAdding: .day, value: week * 7 + weekday, to: gridStart),
                      date >= first, date < nextYear else { return nil }
                let status: DayStatus
                if answeredDays.contains(date) { status = .answered }
                else if date > today { status = .future }
                else if date == today { status = .pending }
                else { status = .missed }
                return Day(date: date, status: status)
            }
        }
    }
}
