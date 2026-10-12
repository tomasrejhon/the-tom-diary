import Foundation

/// Společná pravidla data pro otázky, ukládání i testy. Oddělujeme vybraný den
/// k prohlížení od skutečného „dnes“, které rozhoduje o právu zapisovat.
enum DiaryDate {
    /// Gregoriánský kalendář v aktuálním časovém pásmu telefonu.
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    static func components(_ date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }

    /// Přijme jen přesné RRRR-MM-DD a existující datum. Hodina 12 omezuje potíže
    /// kolem posunů času; zpětná kontrola zabrání automatickému převodu 31. 4. na 1. 5.
    static func parse(_ value: String) -> Date? {
        let fields = value.split(separator: "-", omittingEmptySubsequences: false)
        guard fields.count == 3, fields[0].count == 4, fields[1].count == 2, fields[2].count == 2,
              fields.allSatisfy({ $0.allSatisfy({ $0.isASCII && $0.isNumber }) }) else { return nil }
        let pieces = fields.compactMap { Int($0) }
        guard pieces.count == 3, pieces[0] > 0 else { return nil }
        let components = DateComponents(year: pieces[0], month: pieces[1], day: pieces[2], hour: 12)
        guard let date = calendar.date(from: components) else { return nil }
        let actual = self.components(date)
        guard actual.year == pieces[0], actual.month == pieces[1], actual.day == pieces[2] else { return nil }
        return date
    }

    /// Stabilní technický formát pro testy a identifikátory; UI datum formátuje česky.
    static func string(_ date: Date) -> String {
        let c = components(date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// Běžně systémový čas. Simulované hodiny lze nastavit pouze v izolovaném UI testu.
    static var now: Date {
        #if DEBUG
        if let testingNow { return testingNow }
        #endif
        return Date()
    }

    /// Stejný kalendářní den, nikoli rozdíl menší než 24 hodin.
    /// Ruční změna systémového času není chráněna serverem; tato verze funguje offline.
    static func canWrite(on date: Date, now: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: now)
    }

    /// Úvodní prohlížený den. Debug přepis data sám o sobě nemění právo zapisovat.
    static var initialDate: Date {
        #if DEBUG
        if let value = argument("--diary-test-date") ?? testDate, let date = parse(value) { return date }
        #endif
        return now
    }

    static var hasOverride: Bool {
        #if DEBUG
        argument("--diary-test-date") != nil || testDate != nil
        #else
        false
        #endif
    }

    #if DEBUG
    // Změň nil například na "2024-02-29". Release tuto hodnotu nikdy nepoužívá.
    static let testDate: String? = nil

    // Vyžadujeme platné UUID testovací databáze i argument hodin. Samotné prohlížení
    // jiného data v tajném nastavení nikdy neposune skutečný den pro ukládání.
    static var testingNow: Date? = {
        guard let token = argument("--diary-test-store"), UUID(uuidString: token) != nil,
              let value = argument("--diary-clock-date") else { return nil }
        return parse(value)
    }()

    /// Vrátí hodnotu následující za pojmenovaným argumentem spuštění. Jen pro Debug.
    static func argument(_ name: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: name), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
    #endif
}
