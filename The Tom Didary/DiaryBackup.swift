import Foundation
import CryptoKit
import SwiftData

/// Přenosný formát zálohy. Žádné interní identifikátory SwiftData ani testovací ukázky.
/// Kalendářní klíč je nezávislý na časovém pásmu telefonu, který zálohu obnovuje.
nonisolated struct DiaryBackup: Codable, Equatable, Sendable {
    struct Entry: Codable, Equatable, Sendable {
        let day: String
        let text: String
    }
    let format: String
    let version: Int
    let diaryID: UUID
    let savedAt: Date
    let answers: [Entry]
    static let maximumBytes = 10 * 1024 * 1024

    init(diaryID: UUID, answers: [Entry], savedAt: Date = Date()) {
        format = "TheTomDiary"
        version = 1
        self.diaryID = diaryID
        self.savedAt = savedAt
        self.answers = answers.sorted { $0.day < $1.day }
    }

    func validate() throws {
        guard format == "TheTomDiary", version == 1 else { throw BackupError.invalidFormat }
        guard answers.count <= 20_000 else { throw BackupError.tooLarge }
        var days = Set<String>()
        for entry in answers {
            guard Self.date(entry.day) != nil, days.insert(entry.day).inserted,
                  !entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw BackupError.invalidEntries
            }
            guard entry.text.utf8.count <= 1_000_000 else { throw BackupError.tooLarge }
        }
    }

    /// Kontroluje i přestupné dny a odmítá normalizaci neexistujícího data.
    static func date(_ key: String) -> Date? {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              parts.allSatisfy({ $0.allSatisfy({ $0.isASCII && $0.isNumber }) }) else { return nil }
        let numbers = parts.compactMap { Int($0) }
        guard numbers.count == 3, numbers[0] > 0 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = DateComponents(year: numbers[0], month: numbers[1], day: numbers[2], hour: 12)
        guard let date = calendar.date(from: components) else { return nil }
        let actual = calendar.dateComponents([.year, .month, .day], from: date)
        return actual.year == numbers[0] && actual.month == numbers[1] && actual.day == numbers[2] ? date : nil
    }

    func encoded() throws -> Data {
        try validate()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(self)
        guard data.count <= Self.maximumBytes else { throw BackupError.tooLarge }
        return data
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count <= maximumBytes else { throw BackupError.tooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup: Self
        do { backup = try decoder.decode(Self.self, from: data) }
        catch { throw BackupError.invalidFormat }
        try backup.validate()
        return backup
    }

    /// Čas souboru nerozhoduje o změně deníku. Hash zahrnuje ID a stabilně seřazené zápisy.
    var contentHash: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = (try? encoder.encode(answers.sorted { $0.day < $1.day })) ?? Data()
        return diaryID.uuidString + ":" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

nonisolated enum BackupError: LocalizedError {
    case invalidFormat, invalidEntries, tooLarge, accessLost, anotherDiary, unreadableExisting
    var errorDescription: String? {
        switch self {
        case .invalidFormat: "Soubor není podporovaná záloha The Tom Diary."
        case .invalidEntries: "Záloha obsahuje neplatné datum, prázdnou odpověď nebo opakovaný den."
        case .tooLarge: "Záloha je příliš velká. Maximální velikost souboru je 10 MB."
        case .accessLost: "Ke složce zálohy se nepodařilo získat přístup. Vyber ji prosím znovu."
        case .anotherDiary: "Složka už obsahuje zálohu jiného deníku. Nejprve ji obnov, nebo vyber jinou složku. Původní soubor zůstal zachovaný."
        case .unreadableExisting: "Existující záloha je nečitelná. Nebyla přepsaná; vyber jinou složku nebo obnov předchozí kopii."
        }
    }
}

/// Obnova doplňuje pouze chybějící dny. Nikdy nepřepíše současné odpovědi,
/// nevymaže deník a nepovolí běžným editorem změny uzavřených dnů.
@MainActor
enum BackupRestore {
    struct Summary: Equatable {
        let added: Int
        let kept: Int
    }
    static func snapshot(in context: ModelContext, diaryID: UUID) throws -> DiaryBackup {
        let rows = try context.fetch(FetchDescriptor<Answer>())
        let entries = rows.map { DiaryBackup.Entry(day: String(format: "%04d-%02d-%02d", $0.year, $0.month, $0.day), text: $0.text) }
        let backup = DiaryBackup(diaryID: diaryID, answers: entries)
        try backup.validate()
        return backup
    }
    static func merge(_ backup: DiaryBackup, into context: ModelContext) throws -> Summary {
        try backup.validate()
        let existing = try context.fetch(FetchDescriptor<Answer>())
        var keys = Set(existing.map { String(format: "%04d-%02d-%02d", $0.year, $0.month, $0.day) })
        var inserted = [Answer]()
        var kept = 0
        for entry in backup.answers {
            guard keys.insert(entry.day).inserted else { kept += 1; continue }
            let parts = entry.day.split(separator: "-").compactMap { Int($0) }
            // validace výše už ověřila existenci data; lokální poledne zachová běžné chování modelu.
            let date = DiaryDate.parse(entry.day) ?? DiaryBackup.date(entry.day)!
            let answer = Answer(day: parts[2], month: parts[1], year: parts[0], date: date, text: entry.text)
            context.insert(answer)
            inserted.append(answer)
        }
        do { try context.save() }
        catch { for answer in inserted { context.delete(answer) }; throw error }
        return Summary(added: inserted.count, kept: kept)
    }
}
