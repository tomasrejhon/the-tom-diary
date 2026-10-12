import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Formulář upravuje vlastní pracovní kopii nastavení. „Zavřít“ ji zahodí,
/// „Uložit“ požádá NotificationManager o naplánování i trvalý zápis.
struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var preferences = ReminderPreferences.initial
    // DatePicker pracuje s Date, z něj ale ukládáme jen hodinu a minutu.
    @State private var time = Date()
    @State private var loaded = false
    @State private var saving = false
    @State private var denied = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Denní připomínka", isOn: $preferences.enabled)
                        .accessibilityIdentifier("reminderEnabled")
                    DatePicker("Čas", selection: $time, displayedComponents: .hourAndMinute)
                        .environment(\.locale, Locale(identifier: "cs_CZ"))
                        .disabled(!preferences.enabled)
                        .accessibilityIdentifier("reminderTime")
                }
                Section("Obsah oznámení") {
                    TextField("Nadpis", text: $preferences.title)
                        .accessibilityIdentifier("reminderTitle")
                    TextField("Text oznámení", text: $preferences.body, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("reminderBody")
                }
                Section("Náhled") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("The Tom Diary", systemImage: "bell.fill")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(preferences.title).font(.headline)
                        Text(preferences.body).font(.subheadline)
                    }.padding(.vertical, 8)
                }
                if denied {
                    Section {
                        Text("Oznámení jsou v nastavení systému vypnutá.")
                            .font(.footnote).foregroundStyle(.secondary)
                        #if os(iOS)
                        Button("Otevřít nastavení systému") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                        #endif
                    }
                }
            }
            .disabled(!loaded || saving)
            .navigationTitle("Nastavení oznámení")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Zavřít") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Uložit") { Task { await save() } }
                        .disabled(!loaded || saving || (preferences.enabled && (preferences.trimmed.title.isEmpty || preferences.trimmed.body.isEmpty)))
                        .accessibilityIdentifier("saveReminderSettings")
                }
            }
            // Dokud se asynchronně nenačte skutečné nastavení, je formulář vypnutý,
            // aby uživatel omylem nepřepsal uložené hodnoty výchozími.
            .task {
                preferences = await NotificationManager.shared.loadPreferences()
                time = DiaryDate.calendar.date(bySettingHour: preferences.hour, minute: preferences.minute, second: 0, of: DiaryDate.now) ?? DiaryDate.now
                denied = await NotificationManager.shared.authorizationDenied()
                loaded = true
            }
            .onChange(of: time) { _, value in
                let components = DiaryDate.calendar.dateComponents([.hour, .minute], from: value)
                preferences.hour = components.hour ?? 20
                preferences.minute = components.minute ?? 0
            }
            .alert("Nastavení se nepodařilo uložit", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
        }
    }

    /// Formulář zavře jen úspěch. Při chybě zůstanou rozepsané hodnoty k opravě.
    /// defer znovu povolí ovládání po dokončení obou větví.
    private func save() async {
        saving = true
        defer { saving = false }
        do {
            try await NotificationManager.shared.update(preferences)
            dismiss()
        } catch {
            denied = await NotificationManager.shared.authorizationDenied()
            self.error = error.localizedDescription
        }
    }
}
