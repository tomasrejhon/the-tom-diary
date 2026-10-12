import Foundation
import UserNotifications

/// Srozumitelné chyby nastavení a systémového oprávnění pro obrazovku oznámení.
enum ReminderError: LocalizedError {
    case invalidTime, emptyTitle, emptyBody, permissionDenied
    var errorDescription: String? {
        switch self {
        case .invalidTime: "Vyber platný čas oznámení."
        case .emptyTitle: "Doplň nadpis oznámení."
        case .emptyBody: "Doplň text oznámení."
        case .permissionDenied: "Oznámení jsou v nastavení systému vypnutá. Povol je pro aplikaci a nastavení ulož znovu."
        }
    }
}

/// Uložitelné nastavení připomínky. Hodina a minuta nemají datum; platí každý den.
/// Codable umožní zapsat hodnotu jako JSON do UserDefaults, Equatable ji porovnat v testu.
struct ReminderPreferences: Codable, Equatable {
    var enabled: Bool
    var hour: Int
    var minute: Int
    var title: String
    var body: String
    static let initial = ReminderPreferences(enabled: false, hour: 20, minute: 0,
                                            title: "Chvilka pro tvůj deník",
                                            body: "Zastav se a napiš odpověď na dnešní otázku.")
    // Stálé ID zaručí jednu připomínku: změna času nebo textu nahradí stejný požadavek.
    static let requestIdentifier = "daily-diary-reminder"

    var trimmed: Self {
        var result = self
        result.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        result.body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return result
    }

    /// Čas musí být platný vždy; neprázdný obsah je nutný jen při zapnuté připomínce.
    func validate() throws {
        guard (0..<24).contains(hour), (0..<60).contains(minute) else { throw ReminderError.invalidTime }
        if enabled {
            guard !trimmed.title.isEmpty else { throw ReminderError.emptyTitle }
            guard !trimmed.body.isEmpty else { throw ReminderError.emptyBody }
        }
    }

    /// Vytvoří opakovaný lokální požadavek. Neposílá nic na server a sám nic nenaplánuje.
    func request() throws -> UNNotificationRequest {
        try validate()
        let content = UNMutableNotificationContent()
        content.title = trimmed.title
        content.body = trimmed.body
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: minute), repeats: true)
        return UNNotificationRequest(identifier: Self.requestIdentifier, content: content, trigger: trigger)
    }
}

/// Malé nastavení patří do UserDefaults; samotné odpovědi zůstávají ve SwiftData.
/// Vadné či neplatné uložené nastavení se nepoužije.
struct ReminderPreferencesStore {
    let defaults: UserDefaults
    private let key = "diary.reminder.preferences.v1"
    func load() -> ReminderPreferences? {
        guard let data = defaults.data(forKey: key),
              let preferences = try? JSONDecoder().decode(ReminderPreferences.self, from: data),
              (try? preferences.validate()) != nil else { return nil }
        return preferences
    }
    func save(_ preferences: ReminderPreferences) throws {
        defaults.set(try JSONEncoder().encode(preferences), forKey: key)
    }
}

/// Spojuje uložené nastavení s UNUserNotificationCenter. `async` čeká na odpověď
/// systému bez blokování UI; případnou chybu předá zpět do formuláře.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private let store: ReminderPreferencesStore
    private init() {
        var defaults = UserDefaults.standard
        // Stejné UUID jako databáze oddělí také nastavení UI testu od běžné instalace.
        #if DEBUG
        if let token = DiaryDate.argument("--diary-test-store"), let id = UUID(uuidString: token),
           let isolated = UserDefaults(suiteName: "diary-test-\(id.uuidString)") { defaults = isolated }
        #endif
        store = ReminderPreferencesStore(defaults: defaults)
    }

    /// Nejprve uložená hodnota; při přechodu ze starší verze převezme její připomínku.
    func loadPreferences() async -> ReminderPreferences {
        if let preferences = store.load() { return preferences }
        // Zachováme připomínku zapnutou ve starší verzi, která ještě neměla formulář.
        if let existing = await center.pendingNotificationRequests().first(where: { $0.identifier == ReminderPreferences.requestIdentifier }),
           let trigger = existing.trigger as? UNCalendarNotificationTrigger {
            let preferences = ReminderPreferences(enabled: true, hour: trigger.dateComponents.hour ?? 20,
                                                  minute: trigger.dateComponents.minute ?? 0,
                                                  title: existing.content.title, body: existing.content.body)
            if (try? preferences.validate()) != nil {
                try? store.save(preferences)
                return preferences
            }
        }
        return .initial
    }

    func authorizationDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    /// O oprávnění požádá až při zapnutí. Zamítnutí neobchází a novou hodnotu
    /// zapíše až po úspěšném naplánování, aby UI nehlásilo uloženou nefunkční změnu.
    func update(_ preferences: ReminderPreferences) async throws {
        let preferences = preferences.trimmed
        try preferences.validate()
        if preferences.enabled {
            var status = await center.notificationSettings().authorizationStatus
            if status == .notDetermined {
                guard try await center.requestAuthorization(options: [.alert, .sound]) else { throw ReminderError.permissionDenied }
                status = await center.notificationSettings().authorizationStatus
            }
            guard status == .authorized || status == .provisional || status == .ephemeral else { throw ReminderError.permissionDenied }
            // Změna stejného ID nahradí starý požadavek; předem ho nemažeme.
            // Oznámení je nezávislé na odpovědi: denní připomínka může přijít i po zápisu.
            try await center.add(preferences.request())
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [ReminderPreferences.requestIdentifier])
        }
        try store.save(preferences)
    }
}
