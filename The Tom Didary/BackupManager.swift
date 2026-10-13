import Foundation
import SwiftData
import Combine

/// Nastavení obsahuje jen oprávnění ke složce a údaje o posledním zápisu.
/// Samotné odpovědi jsou ve SwiftData a v uživatelem vybrané záloze, ne v UserDefaults.
@MainActor
final class BackupManager: ObservableObject {
    @Published private(set) var folderName: String?
    @Published private(set) var lastWritten: Date?
    @Published private(set) var status = "Automatická záloha není nastavená"
    @Published private(set) var problem: String?
    @Published private(set) var isWriting = false
    private let defaults: UserDefaults
    private let worker = BackupFileWorker()
    private var bookmark: Data?
    private var diaryID: UUID
    private var lastHash: String?
    private var pending: DiaryBackup?
    private var task: Task<Void, Never>?
    private let prefix = "diary.backup.v1."
    var isConfigured: Bool { bookmark != nil }
    var symbol: String {
        if problem != nil { return "exclamationmark.triangle" }
        if isWriting { return "arrow.triangle.2.circlepath" }
        return lastWritten == nil ? "externaldrive" : "checkmark.circle"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        diaryID = defaults.string(forKey: prefix + "diaryID").flatMap(UUID.init(uuidString:)) ?? UUID()
        defaults.set(diaryID.uuidString, forKey: prefix + "diaryID")
        bookmark = defaults.data(forKey: prefix + "bookmark")
        folderName = defaults.string(forKey: prefix + "folder")
        lastWritten = defaults.object(forKey: prefix + "written") as? Date
        lastHash = defaults.string(forKey: prefix + "hash")
        if bookmark != nil { status = "Ověřuji záložní soubor…" }
    }

    /// Novou složku uloží až po úspěšné první záloze. Chybné nastavení nepřepíše
    /// stávající fungující složku a cizí či poškozené soubory se automaticky nemažou.
    func configure(_ directory: URL, context: ModelContext) async throws {
        guard !isWriting else { return }
        isWriting = true
        defer {
            isWriting = false
            if pending != nil { update(context: context, force: true) }
        }
        let access = directory.startAccessingSecurityScopedResource()
        defer { if access { directory.stopAccessingSecurityScopedResource() } }
        let candidate = try BackupFileWorker.bookmark(for: directory)
        let snapshot = try BackupRestore.snapshot(in: context, diaryID: diaryID)
        let date = try await worker.write(snapshot, bookmark: candidate)
        bookmark = candidate
        folderName = directory.lastPathComponent
        defaults.set(candidate, forKey: prefix + "bookmark")
        defaults.set(folderName, forKey: prefix + "folder")
        recordSuccess(snapshot, date: date)
    }

    /// Sloučí rychlé navazující požadavky. Další snapshot se načte až po úspěšném
    /// místním save; neuložené texty ani demo se do zálohy nikdy nedostanou.
    func update(context: ModelContext, force: Bool = false) {
        guard bookmark != nil else { return }
        do {
            let snapshot = try BackupRestore.snapshot(in: context, diaryID: diaryID)
            guard force || snapshot.contentHash != lastHash || problem != nil else { return }
            pending = snapshot
            status = "Aktualizuji záložní soubor…"
            guard task == nil, !isWriting else { return }
            isWriting = true
            task = Task {
                while let snapshot = pending, let bookmark {
                    pending = nil
                    do {
                        let date = try await worker.write(snapshot, bookmark: bookmark)
                        recordSuccess(snapshot, date: date)
                    } catch {
                        problem = error.localizedDescription
                        status = "Uloženo v telefonu · záloha čeká"
                    }
                }
                isWriting = false
                task = nil
            }
        } catch {
            problem = error.localizedDescription
            status = "Uloženo v telefonu · záloha čeká"
        }
    }

    func read(_ url: URL) async throws -> DiaryBackup { try await worker.read(url) }

    /// Převzetí identity umožní na novém telefonu znovu vybrat původní složku.
    /// U již nastaveného zálohování zůstává identita současného deníku zachovaná.
    func restore(_ backup: DiaryBackup, context: ModelContext) throws -> BackupRestore.Summary {
        let wasEmpty = try context.fetchCount(FetchDescriptor<Answer>()) == 0
        let result = try BackupRestore.merge(backup, into: context)
        if wasEmpty && !isConfigured {
            diaryID = backup.diaryID
            defaults.set(diaryID.uuidString, forKey: prefix + "diaryID")
        }
        update(context: context, force: true)
        return result
    }

    func disable() {
        guard !isWriting else { return }
        bookmark = nil
        folderName = nil
        lastWritten = nil
        lastHash = nil
        problem = nil
        pending = nil
        for key in ["bookmark", "folder", "written", "hash"] { defaults.removeObject(forKey: prefix + key) }
        status = "Automatická záloha není nastavená"
        // Soubor ve vybrané složce zůstává zachovaný i při vypnutí funkce.
    }

    private func recordSuccess(_ snapshot: DiaryBackup, date: Date) {
        lastWritten = date
        lastHash = snapshot.contentHash
        problem = nil
        status = "Záložní soubor aktualizován"
        defaults.set(date, forKey: prefix + "written")
        defaults.set(lastHash, forKey: prefix + "hash")
    }

    #if DEBUG
    /// Pouze izolovaný UI scénář: nikdy nesahá do osobní cloudové složky.
    func configureTestFolderIfNeeded(context: ModelContext) async {
        guard !isConfigured, let token = DiaryDate.argument("--diary-test-store"), UUID(uuidString: token) != nil,
              ProcessInfo.processInfo.arguments.contains("--diary-test-backup") else { return }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("backup-ui-\(token)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try await configure(folder, context: context)
        } catch { problem = error.localizedDescription; status = "Testovací záloha selhala" }
    }
    #endif
}
