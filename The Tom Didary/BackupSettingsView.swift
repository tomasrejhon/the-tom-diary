import SwiftUI
import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Výběr složky udělí přístup přes systém Soubory. CloudKit ani vlastní iCloud
/// kontejner se nezapíná; doručení souboru do cloudu spravuje poskytovatel složky.
struct BackupSettingsView: View {
    @ObservedObject var backup: BackupManager
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false
    @State private var pickingFolder = true
    @State private var proposedRestore: DiaryBackup?
    @State private var showRestoreConfirmation = false
    @State private var message: String?
    @State private var reading = false
    private var busy: Bool { backup.isWriting || reading }

    var body: some View {
        NavigationStack {
            Form {
                Section("Automatická záloha") {
                    Label(backup.status, systemImage: backup.symbol)
                        .accessibilityIdentifier("backupSettingsStatus")
                    if let name = backup.folderName { LabeledContent("Vybraná složka", value: name) }
                    if let date = backup.lastWritten {
                        LabeledContent("Poslední zápis", value: date.formatted(.dateTime.day().month().year().hour().minute().locale(Locale(identifier: "cs_CZ"))))
                    }
                    if let problem = backup.problem { Text(problem).font(.footnote).foregroundStyle(.orange) }
                    Button(backup.isConfigured ? "Změnit složku zálohy" : "Vybrat složku zálohy") {
                        pickingFolder = true; showPicker = true
                    }.accessibilityIdentifier("chooseBackupFolder")
                    if backup.isConfigured {
                        Button("Aktualizovat zálohu teď") { backup.update(context: context, force: true) }
                            .accessibilityIdentifier("retryBackup")
                        Button("Vypnout automatickou zálohu") { backup.disable() }
                    }
                }
                Section("Obnova deníku") {
                    Button("Obnovit ze záložního souboru") { pickingFolder = false; showPicker = true }
                        .accessibilityIdentifier("restoreBackup")
                    Text("Vyber diary-backup.json, případně diary-backup-previous.json. Obnova doplní chybějící dny. Odpovědi už uložené v tomto telefonu zůstanou zachované.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Text("Záloha je čitelný JSON se všemi odpověďmi. Ukládej ji do své soukromé složky.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Text("Po každém uložení nebo úpravě odpovědi se do vybrané složky zapíše celý deník. Soubor diary-backup.json a předchozí kopie jsou ve složce The Tom Diary Backups.")
                    Text("Vyber složku v iCloud Drive, aby záloha mohla přežít ztrátu telefonu. Složka pouze v telefonu před ztrátou zařízení nechrání.")
                    Text("Potvrzení znamená úspěšný zápis souboru. Jeho odeslání do cloudu zajišťuje iOS a může čekat na internet. V aplikaci Soubory lze ověřit stav přenosu.")
                }.font(.footnote).foregroundStyle(.secondary)
                if busy { ProgressView("Pracuji se zálohou…") }
            }
            .disabled(busy)
            .navigationTitle("Záloha a obnova")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zavřít") { dismiss() } } }
            .fileImporter(isPresented: $showPicker, allowedContentTypes: pickingFolder ? [.folder] : [.json], allowsMultipleSelection: false) { result in
                switch result {
                case .failure(let error):
                    let cocoa = error as NSError
                    if cocoa.domain != NSCocoaErrorDomain || cocoa.code != NSUserCancelledError {
                        message = error.localizedDescription
                    }
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let folder = pickingFolder
                    Task {
                        do {
                            if folder { try await backup.configure(url, context: context) }
                            else {
                                reading = true
                                defer { reading = false }
                                proposedRestore = try await backup.read(url)
                                showRestoreConfirmation = true
                            }
                        } catch { message = error.localizedDescription }
                    }
                }
            }
            .confirmationDialog("Obnovit deník ze zálohy?", isPresented: $showRestoreConfirmation, titleVisibility: .visible) {
                Button("Doplnit chybějící odpovědi") {
                    guard let document = proposedRestore else { return }
                    do {
                        let summary = try backup.restore(document, context: context)
                        message = "Obnova dokončena. Přidáno: \(summary.added). Zachováno současných odpovědí: \(summary.kept)."
                    } catch { message = "Obnova se nepodařila. \(error.localizedDescription)" }
                    proposedRestore = nil
                }
                Button("Zrušit", role: .cancel) { proposedRestore = nil }
            } message: {
                Text("Záloha obsahuje \(proposedRestore?.answers.count ?? 0) odpovědí. Existující zápisy se nepřepíšou.")
            }
            .alert("Záloha deníku", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") { message = nil }
            } message: { Text(message ?? "") }
        }
    }
}
