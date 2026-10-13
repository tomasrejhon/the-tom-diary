import Foundation
import Testing
import UserNotifications
@testable import The_Tom_Didary

@MainActor
struct SigningReminderTests {
    @Test func readsExpiryFromEmbeddedXMLAndRejectsNonDevelopmentProfile() throws {
        let expiration = Date(timeIntervalSince1970: 1_800_000_000)
        var properties: [String: Any] = ["UUID": "profile-unit", "ExpirationDate": expiration, "Entitlements": ["get-task-allow": true]]
        let xml = try PropertyListSerialization.data(fromPropertyList: properties, format: .xml, options: 0)
        let wrapped = Data([0x30, 0x82, 0xff]) + xml + Data([0xff, 0x00])
        #expect(SigningProfile.read(wrapped) == .init(identifier: "profile-unit", expires: expiration))
        properties["Entitlements"] = ["get-task-allow": false]
        #expect(SigningProfile.read(try PropertyListSerialization.data(fromPropertyList: properties, format: .xml, options: 0)) == nil)
        #expect(SigningProfile.read(Data("neplatný profil".utf8)) == nil)
    }
    @Test func requestUsesRealExpiryAndDoesNotRepeat() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let profile = SigningProfile(identifier: "new-profile", expires: now.addingTimeInterval(7 * 86400))
        let request = try #require(profile.request(now: now))
        let trigger = try #require(request.trigger as? UNTimeIntervalNotificationTrigger)
        #expect(request.identifier != ReminderPreferences.requestIdentifier)
        #expect(request.identifier == "diary-signing-expiration")
        #expect(trigger.timeInterval == 6 * 86400)
        #expect(!trigger.repeats)
        #expect(profile.request(now: now.addingTimeInterval(86400))?.trigger != nil)
        #expect(profile.reminderDate(now: now) == profile.reminderDate(now: now.addingTimeInterval(86400)))
    }
    @Test func lateLaunchWarnsBeforeExpiryAndExpiredProfileSchedulesNothing() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let late = SigningProfile(identifier: "late", expires: now.addingTimeInterval(3600))
        #expect(late.reminderDate(now: now) == now.addingTimeInterval(60))
        #expect(SigningProfile(identifier: "expired", expires: now).request(now: now) == nil)
        #expect(SigningProfile(identifier: "almost-expired", expires: now.addingTimeInterval(30)).request(now: now) == nil)
    }
}
