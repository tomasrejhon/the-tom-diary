import Foundation
import Testing
import UserNotifications
@testable import The_Tom_Didary

/// Ověří obsah požadavku a přetrvání nastavení bez žádosti o systémové oprávnění.
/// Tyto testy nedokazují doručení notifikace na uzamčený fyzický telefon.
@MainActor
struct ReminderTests {
    @Test func dailyRequestUsesCustomTimeAndTrimmedContent() throws {
        let preferences = ReminderPreferences(enabled: true, hour: 23, minute: 7,
                                              title: " Vlastní nadpis ", body: " Vlastní připomínka.\n")
        let request = try preferences.request()
        let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)
        #expect(request.identifier == "daily-diary-reminder")
        #expect(request.content.title == "Vlastní nadpis")
        #expect(request.content.body == "Vlastní připomínka.")
        #expect(request.content.sound != nil)
        #expect(trigger.repeats)
        #expect(trigger.dateComponents.hour == 23)
        #expect(trigger.dateComponents.minute == 7)
        #expect(trigger.dateComponents.day == nil)
    }

    @Test func reminderRejectsInvalidTimeOrEmptyEnabledContent() {
        var preferences = ReminderPreferences.initial
        preferences.hour = 24
        #expect(throws: ReminderError.self) { try preferences.validate() }
        preferences.hour = 20
        preferences.minute = -1
        #expect(throws: ReminderError.self) { try preferences.validate() }
        preferences.minute = 0
        preferences.enabled = true
        preferences.title = " \n"
        #expect(throws: ReminderError.self) { try preferences.validate() }
        preferences.title = "Deník"
        preferences.body = " "
        #expect(throws: ReminderError.self) { try preferences.validate() }
        preferences.enabled = false
        #expect(throws: Never.self) { try preferences.validate() }
    }

    @Test func preferencesSurviveReopeningTheirStore() throws {
        let suite = "diary-reminder-unit-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = ReminderPreferences(enabled: false, hour: 7, minute: 35,
                                              title: "Ranní deník", body: "Co ti dnes udělalo radost?")
        try ReminderPreferencesStore(defaults: defaults).save(preferences)
        let reopened = try #require(UserDefaults(suiteName: suite))
        #expect(ReminderPreferencesStore(defaults: reopened).load() == preferences)
    }
}
