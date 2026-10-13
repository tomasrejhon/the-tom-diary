import Foundation

/// Jedno UUID oddělí nastavení nových funkcí stejně jako testovací databázi.
/// Běžná instalace používá standardní UserDefaults; Debug scénáře nesdílejí složky.
@MainActor
enum DiaryPreferences {
    static var defaults: UserDefaults {
        #if DEBUG
        if let token = DiaryDate.argument("--diary-test-store"), let id = UUID(uuidString: token),
           let isolated = UserDefaults(suiteName: "diary-test-\(id.uuidString)") { return isolated }
        #endif
        return .standard
    }
}
