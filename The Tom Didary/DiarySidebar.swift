import SwiftUI

/// Obsah celostránkového menu. Velikost, sklo a animaci zajišťuje ContentView.
/// Dostává hotové statistiky a akce; samo databázi nenačítá ani nic neukládá.
struct DiarySidebar: View {
    let statistics: DiaryStatistics
    let developerToolsUnlocked: Bool
    let close: () -> Void
    let notificationSettings: () -> Void
    @ObservedObject var backup: BackupManager
    @ObservedObject var signing: SigningReminder
    let backupSettings: () -> Void
    let testSettings: () -> Void
    let unlockDeveloperTools: () -> Void
    @State private var versionTapCount = 0
    @State private var lastVersionTap: Date?

    /// Viditelná verze pochází z MARKETING_VERSION v nastavení hlavního targetu.
    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("The Tom Diary").font(.title2.bold())
                Spacer(minLength: 0)
                Button(action: close) {
                    Image(systemName: "xmark").font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Zavřít menu")
                .accessibilityIdentifier("closeDiaryMenu")
            }
            .padding(.horizontal, 22).padding(.top, 16).padding(.bottom, 12)
            Divider().padding(.horizontal, 22)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 12) {
                        countRow("Letos zapsáno", count: statistics.thisYearCount, identifier: "thisYearAnswerCount")
                        if statistics.showTotalCount {
                            countRow("Za celou dobu", count: statistics.totalCount, identifier: "totalAnswerCount")
                        }
                    }
                    YearActivityView(statistics: statistics)
                    HStack(spacing: 12) {
                        Image(systemName: "flame.fill").foregroundStyle(.orange).font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Aktuální streak").font(.subheadline).foregroundStyle(.secondary)
                            Text("\(statistics.currentStreak) \(dayWord(statistics.currentStreak)) v řadě")
                                .font(.headline).monospacedDigit()
                                .accessibilityIdentifier("currentStreak")
                        }
                    }
                    Divider()
                    Button(action: notificationSettings) {
                        Label("Nastavení oznámení", systemImage: "bell")
                            .font(.body.weight(.medium)).frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("notificationSettings")
                    Button(action: backupSettings) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Záloha a obnova", systemImage: "externaldrive")
                                .font(.body.weight(.medium))
                            Text(backup.status).font(.caption).foregroundStyle(.secondary)
                            if let date = backup.lastWritten {
                                Text("Poslední zápis: \(date.formatted(.dateTime.day().month().year().hour().minute().locale(Locale(identifier: "cs_CZ"))))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("backupSettings")
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Label(signing.menuText, systemImage: "clock")
                            .font(.caption).foregroundStyle(.secondary)
                            .accessibilityIdentifier("signingExpiration")
                        if signing.profile != nil {
                            Toggle("Připomenout obnovení", isOn: Binding(get: { signing.enabled }, set: { value in
                                Task { await signing.setEnabled(value) }
                            })).font(.subheadline).accessibilityIdentifier("signingReminderToggle")
                            Text(signing.status).font(.caption).foregroundStyle(.secondary)
                            if signing.enabled && signing.status == "Pro připomínku povol oznámení" {
                                Button("Povolit oznámení") { Task { await signing.refresh(requestPermission: true) } }
                                    .font(.caption).accessibilityIdentifier("allowSigningNotifications")
                            }
                        }
                    }
                    if developerToolsUnlocked {
                        Button(action: testSettings) {
                            Label("Testovací nastavení", systemImage: "wrench.and.screwdriver")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 10).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("testDateSettings")
                    }
                }
                .padding(22)
            }
            VStack(spacing: 4) {
                Text("fully vibecoded")
                Button("v\(version)", action: versionTapped)
                    .buttonStyle(.plain)
                    .frame(minWidth: 70, minHeight: 30)
                    .accessibilityIdentifier("appVersion")
            }
            .font(.caption).foregroundStyle(.secondary)
            .padding(.bottom, 16).padding(.top, 8)
        }
        // Zachováme jednotlivé prvky přístupné VoiceOveru a testům. Identifikátor
        // na celém kontejneru by v SwiftUI mohl přepsat identifikátory jeho potomků.
        .accessibilityElement(children: .contain)
    }

    private func countRow(_ label: String, count: Int, identifier: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text("\(count) \(answerWord(count))").font(.headline).monospacedDigit()
                .accessibilityIdentifier(identifier)
        }
    }

    private func answerWord(_ count: Int) -> String {
        count == 1 ? "odpověď" : (2...4).contains(count) ? "odpovědi" : "odpovědí"
    }

    private func dayWord(_ count: Int) -> String {
        count == 1 ? "den" : (2...4).contains(count) ? "dny" : "dnů"
    }

    /// Pět navazujících klepnutí s nejvýše dvousekundovou pauzou odemkne nástroje.
    /// Odemčení si pamatuje rodič jen v paměti; neukládá se do UserDefaults.
    private func versionTapped() {
        let now = Date()
        if let lastVersionTap, now.timeIntervalSince(lastVersionTap) <= 2 {
            versionTapCount += 1
        } else {
            versionTapCount = 1
        }
        lastVersionTap = now
        if versionTapCount == 5 {
            versionTapCount = 0
            unlockDeveloperTools()
        }
    }
}
