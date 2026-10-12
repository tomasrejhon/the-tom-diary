import Foundation

/// Neměnná otázka pro konkrétní den a měsíc. Otázky se každý rok opakují.
struct Question: Identifiable, Equatable {
    let prompt: String
    let day: Int
    let month: Int
    let emoji: String
    // Například 13. září má ID 913; přestupný den neposouvá ostatní otázky.
    var id: Int { month * 100 + day }
    var displayPrompt: String { "\(prompt) \(emoji)" }
}

/// Načte a ověří celý vestavěný JSON. Chybu předá obrazovce k zobrazení,
/// místo aby potichu použil jinou otázku nebo neúplný seznam.
struct QuestionProvider {
    let questions: [Question]
    let loadError: String?

    /// `Bundle` je balíček aplikace, nikoli síťová služba; otázky fungují offline.
    init(bundle: Bundle = .main) {
        do {
            guard let url = bundle.url(forResource: "denik_otazky_kompletni_final_v2", withExtension: "json") else {
                throw QuestionError.invalid("Soubor s otázkami není součástí aplikace.")
            }
            questions = try Self.decode(Data(contentsOf: url))
            loadError = nil
        } catch {
            questions = []
            loadError = error.localizedDescription
        }
    }

    func question(day: Int, month: Int) -> Question? {
        questions.first { $0.day == day && $0.month == month }
    }

    /// Překládá české datum z JSONu na číselný den a měsíc a kontroluje všech 366 dnů.
    /// `String.count` počítá uživatelsky vnímané znaky, takže složené emoji má délku 1.
    static func decode(_ data: Data) throws -> [Question] {
        struct RawQuestion: Decodable {
            let datum: String
            let otazka: String
            let emoji: String
        }
        let rows = try JSONDecoder().decode([RawQuestion].self, from: data)
        // Názvy porovnáváme bez diakritiky a bez ohledu na velikost písmen.
        let months = ["leden", "unor", "brezen", "duben", "kveten", "cerven", "cervenec", "srpen", "zari", "rijen", "listopad", "prosinec"]
        var ids = Set<Int>()
        let questions = try rows.map { row -> Question in
            let parts = row.datum.split(separator: ".", maxSplits: 1)
            guard parts.count == 2, let day = Int(parts[0].trimmingCharacters(in: .whitespaces)),
                  let index = months.firstIndex(of: parts[1].trimmingCharacters(in: .whitespaces).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "cs_CZ"))) else {
                throw QuestionError.invalid("Neplatné datum: \(row.datum)")
            }
            let month = index + 1
            let maximum = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][index]
            guard (1...maximum).contains(day), !row.otazka.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  (1...2).contains(row.emoji.count), ids.insert(month * 100 + day).inserted else {
                throw QuestionError.invalid("Neplatná nebo opakovaná otázka: \(row.datum)")
            }
            return Question(prompt: row.otazka, day: day, month: month, emoji: row.emoji)
        }
        // Jedinečnost a platné rozsahy spolu s počtem 366 zaručují úplný kalendář.
        guard questions.count == 366 else {
            throw QuestionError.invalid("Soubor musí obsahovat všech 366 dnů včetně 29. února.")
        }
        return questions.sorted { $0.id < $1.id }
    }
}

enum QuestionError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        switch self { case .invalid(let message): return message }
    }
}
