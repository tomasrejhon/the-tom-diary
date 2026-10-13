import Foundation
import UserNotifications
import Combine

/// Datum získáváme z profilu skutečně vloženého při podpisu. Profil je CMS obálka
/// s XML plist; čteme jen metadata zabalená v podepsané aplikaci. Neověřujeme tím
/// kryptografickou platnost podpisu (tu kontroluje systém) a nic neodhadujeme podle build data.
nonisolated struct SigningProfile: Equatable, Sendable {
    let identifier: String
    let expires: Date
    static func read(_ data: Data) -> Self? {
        let startMarker = Data("<?xml".utf8)
        let endMarker = Data("</plist>".utf8)
        guard let start = data.range(of: startMarker),
              let end = data.range(of: endMarker, in: start.lowerBound..<data.endIndex),
              let values = try? PropertyListSerialization.propertyList(from: Data(data[start.lowerBound..<end.upperBound]), format: nil) as? [String: Any],
              let id = values["UUID"] as? String, !id.isEmpty,
              let expires = values["ExpirationDate"] as? Date,
              let entitlements = values["Entitlements"] as? [String: Any],
              entitlements["get-task-allow"] as? Bool == true else { return nil }
        return Self(identifier: id, expires: expires)
    }

    /// Je-li aplikace poprvé otevřená až v posledních 24 hodinách, připomene
    /// obnovu za minutu; nikdy neplánuje již minulý čas ani čas po expiraci.
    func reminderDate(now: Date) -> Date? {
        guard expires > now.addingTimeInterval(60) else { return nil }
        return max(expires.addingTimeInterval(-24 * 60 * 60), now.addingTimeInterval(60))
    }
    func request(now: Date) -> UNNotificationRequest? {
        guard let date = reminderDate(now: now) else { return nil }
        let content = UNMutableNotificationContent()
        content.title = "Obnov instalaci deníku"
        content.body = "Platnost aplikace brzy končí. Připoj iPhone k Macu a nahraj ji znovu přes Xcode. Aplikaci nemaž, aby zůstaly tvoje odpovědi."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: date.timeIntervalSince(now), repeats: false)
        return UNNotificationRequest(identifier: "diary-signing-expiration", content: content, trigger: trigger)
    }
}

/// Připomínka podpisu je nezávislá na denní otázce a používá vlastní ID.
/// Přepočte se jen při změně profilu, nepřesouvá se při každém otevření aplikace.
@MainActor
final class SigningReminder: ObservableObject {
    @Published private(set) var profile: SigningProfile?
    @Published private(set) var enabled: Bool
    @Published private(set) var status = ""
    private let defaults: UserDefaults
    private let center = UNUserNotificationCenter.current()
    private let enabledKey = "diary.signing.reminder.enabled"
    private let scheduledKey = "diary.signing.reminder.scheduledProfile"
    private let requestID = "diary-signing-expiration"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        enabled = defaults.object(forKey: enabledKey) as? Bool ?? true
        if let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
           let data = try? Data(contentsOf: url) { profile = SigningProfile.read(data) }
        #if DEBUG
        if DiaryDate.argument("--diary-test-store") != nil,
           ProcessInfo.processInfo.arguments.contains("--diary-test-signing") {
            profile = SigningProfile(identifier: "isolated-signing-test", expires: Date().addingTimeInterval(48 * 60 * 60))
        }
        #endif
    }

    var menuText: String {
        guard let profile else {
            #if targetEnvironment(simulator)
            return "Simulátor · podpis nevyprší"
            #else
            return "Datum platnosti podpisu není dostupné"
            #endif
        }
        return "Platnost instalace do \(profile.expires.formatted(.dateTime.day().month().year().hour().minute().locale(Locale(identifier: "cs_CZ"))))"
    }

    func setEnabled(_ value: Bool) async {
        enabled = value
        defaults.set(value, forKey: enabledKey)
        await refresh(requestPermission: value)
    }

    func refresh(requestPermission: Bool = false) async {
        // UI test nemění systémové požadavky běžné instalace stejného simulátoru.
        #if DEBUG
        if DiaryDate.argument("--diary-test-store") != nil {
            status = profile == nil ? "" : "Testovací profil · doručení se neplánuje"
            return
        }
        #endif
        guard enabled, let profile else {
            center.removePendingNotificationRequests(withIdentifiers: [requestID])
            defaults.removeObject(forKey: scheduledKey)
            status = enabled ? "" : "Připomínka obnovení je vypnutá"
            return
        }
        do {
            var authorization = await center.notificationSettings().authorizationStatus
            if requestPermission && authorization == .notDetermined {
                _ = try await center.requestAuthorization(options: [.alert, .sound])
                authorization = await center.notificationSettings().authorizationStatus
            }
            guard authorization.permitsDiaryAlerts else {
                status = "Pro připomínku povol oznámení"
                return
            }
            let key = profile.identifier + ":" + String(profile.expires.timeIntervalSince1970)
            let now = Date()
            guard let request = profile.request(now: now) else {
                center.removePendingNotificationRequests(withIdentifiers: [requestID])
                status = "Obnov instalaci přes Xcode"
                return
            }
            let stillPending = await center.pendingNotificationRequests().contains { $0.identifier == requestID }
            let futureReminderMissing = !stillPending && profile.expires.addingTimeInterval(-86400) > now
            if defaults.string(forKey: scheduledKey) != key || futureReminderMissing {
                try await center.add(request)
                defaults.set(key, forKey: scheduledKey)
            }
            status = "Připomínka 24 hodin před koncem platnosti"
        } catch { status = "Připomínku se nepodařilo naplánovat" }
    }
}
