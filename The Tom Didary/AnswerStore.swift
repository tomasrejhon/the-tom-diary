import Foundation
import SwiftData

/// Chyba obchodního pravidla: zápis je dovolený pouze v aktuálním kalendářním dni.
enum AnswerStoreError: LocalizedError {
    case dayClosed

    var errorDescription: String? {
        "Odpověď lze uložit nebo upravit pouze v den, ke kterému patří."
    }
}

/// Jediné místo pro ukládání odpovědí. Obrazovka zajišťuje ovládání, tento typ
/// hlídá přiřazení k datu, opakované uložení a chyby databáze i bez přítomnosti UI.
/// `@MainActor` drží práci s kontextem SwiftData na hlavním aktoru.
@MainActor
enum AnswerStore {
    /// Vyhledá přesně tento den včetně roku; časová část `date` nerozhoduje.
    static func answer(on date: Date, in answers: [Answer]) -> Answer? {
        let c = DiaryDate.components(date)
        return answers.first { $0.day == c.day && $0.month == c.month && $0.year == c.year }
    }

    /// Stejný den a měsíc ve starších letech, od nejnovější odpovědi k nejstarší.
    /// 29. únor se nikdy nenahrazuje 28. únorem ani 1. březnem.
    static func previousYears(on date: Date, in answers: [Answer]) -> [Answer] {
        let c = DiaryDate.components(date)
        return answers.filter { $0.day == c.day && $0.month == c.month && $0.year < (c.year ?? 0) }
            .sorted { $0.year > $1.year }
    }

    /// Odstraní krajní mezery a buď aktualizuje záznam dne, nebo vytvoří nový.
    /// Prázdný text vrací `nil` a nic nemaže. Parametr `now` umožňuje jednotkovým
    /// testům zadat čas; běžné volání vždy použije aktuální hodiny aplikace.
    @discardableResult
    static func save(_ text: String, on date: Date, in context: ModelContext, now: Date? = nil) throws -> Answer? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // Kontrola musí být i zde: otevřený editor mohl mezitím překročit půlnoc.
        guard DiaryDate.canWrite(on: date, now: now ?? DiaryDate.now) else { throw AnswerStoreError.dayClosed }
        let all = try context.fetch(FetchDescriptor<Answer>())
        let c = DiaryDate.components(date)
        if let existing = answer(on: date, in: all) {
            // Při selhání save obnovíme předchozí hodnotu také v živém modelu.
            let oldText = existing.text
            existing.text = trimmed
            do { try context.save() } catch { existing.text = oldText; throw error }
            return existing
        }
        let answer = Answer(day: c.day!, month: c.month!, year: c.year!, date: date, text: trimmed)
        context.insert(answer)
        // Selhaný nový zápis odstraníme z kontextu, aby nevypadal jako uložený.
        do { try context.save() } catch { context.delete(answer); throw error }
        return answer
    }
}
