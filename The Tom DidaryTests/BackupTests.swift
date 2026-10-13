import Foundation
import Testing
import SwiftData
@testable import The_Tom_Didary

@MainActor
struct BackupTests {
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private func memoryContext() throws -> ModelContext {
        let container = try ModelContainer(for: Answer.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }
    private func settle(_ manager: BackupManager) async throws {
        for _ in 0..<200 {
            if !manager.isWriting { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("Záloha se nedokončila v limitu")
    }

    @Test func roundTripPreservesLeapDayUnicodeAndWholeText() throws {
        let text = String(repeating: "Více vět, háčky a emoji 🌍.\n", count: 100)
        let original = DiaryBackup(diaryID: UUID(), answers: [.init(day: "2024-02-29", text: text), .init(day: "2023-01-01", text: "Starší")], savedAt: Date(timeIntervalSince1970: 1000))
        let restored = try DiaryBackup.decode(original.encoded())
        #expect(restored == original)
        #expect(restored.answers.map(\.day) == ["2023-01-01", "2024-02-29"])
        #expect(restored.answers.last?.text == text)
    }

    @Test func damagedFutureVersionAndInvalidEntriesAreRejected() throws {
        let id = UUID()
        for entries in [[DiaryBackup.Entry(day: "2023-02-29", text: "x")], [.init(day: "2024-02-29", text: "x"), .init(day: "2024-02-29", text: "y")], [.init(day: "2026-10-13", text: " \n")]] {
            #expect(throws: BackupError.self) { try DiaryBackup(diaryID: id, answers: entries).encoded() }
        }
        #expect(throws: BackupError.self) { try DiaryBackup.decode(Data("{}".utf8)) }
        let valid = try DiaryBackup(diaryID: id, answers: []).encoded()
        var values = try #require(JSONSerialization.jsonObject(with: valid) as? [String: Any])
        values["version"] = 99
        let wrongVersion = try JSONSerialization.data(withJSONObject: values)
        #expect(throws: BackupError.self) { try DiaryBackup.decode(wrongVersion) }
        #expect(throws: BackupError.self) { try DiaryBackup.decode(Data(repeating: 0, count: DiaryBackup.maximumBytes + 1)) }
    }

    @Test func restoreAddsMissingDaysKeepsExistingAndIsIdempotent() throws {
        let context = try memoryContext()
        let day = try #require(DiaryDate.parse("2026-10-13"))
        try AnswerStore.save("Současná odpověď", on: day, in: context, now: day)
        let document = DiaryBackup(diaryID: UUID(), answers: [.init(day: "2026-10-13", text: "Starší kopie"), .init(day: "2024-02-29", text: "Obnovený přestupný den")])
        #expect(try BackupRestore.merge(document, into: context) == .init(added: 1, kept: 1))
        #expect(try BackupRestore.merge(document, into: context) == .init(added: 0, kept: 2))
        let snapshot = try BackupRestore.snapshot(in: context, diaryID: document.diaryID)
        #expect(snapshot.answers.count == 2)
        #expect(snapshot.answers.first?.text == "Obnovený přestupný den")
        #expect(snapshot.answers.last?.text == "Současná odpověď")
    }

    @Test func writeRetainsPreviousCopyAndUnchangedWriteDoesNotRotate() async throws {
        let root = try folder()
        defer { try? FileManager.default.removeItem(at: root) }
        let bookmark = try BackupFileWorker.bookmark(for: root)
        let worker = BackupFileWorker()
        let id = UUID()
        let first = DiaryBackup(diaryID: id, answers: [.init(day: "2026-10-13", text: "První")])
        let second = DiaryBackup(diaryID: id, answers: [.init(day: "2026-10-13", text: "Druhá")])
        _ = try await worker.write(first, bookmark: bookmark)
        _ = try await worker.write(second, bookmark: bookmark)
        _ = try await worker.write(second, bookmark: bookmark)
        let directory = root.appendingPathComponent(BackupFileWorker.directoryName)
        #expect(try await worker.read(directory.appendingPathComponent(BackupFileWorker.currentName)).answers.first?.text == "Druhá")
        #expect(try await worker.read(directory.appendingPathComponent(BackupFileWorker.previousName)).answers.first?.text == "První")
    }

    @Test func foreignAndCorruptBackupAreNeverOverwritten() async throws {
        let root = try folder()
        defer { try? FileManager.default.removeItem(at: root) }
        let bookmark = try BackupFileWorker.bookmark(for: root)
        let worker = BackupFileWorker()
        let original = DiaryBackup(diaryID: UUID(), answers: [.init(day: "2025-10-13", text: "Cenný původní zápis")])
        _ = try await worker.write(original, bookmark: bookmark)
        let current = root.appendingPathComponent(BackupFileWorker.directoryName).appendingPathComponent(BackupFileWorker.currentName)
        let before = try Data(contentsOf: current)
        do {
            _ = try await worker.write(DiaryBackup(diaryID: UUID(), answers: []), bookmark: bookmark)
            Issue.record("Cizí záloha nesmí být přepsaná")
        } catch { #expect(error is BackupError) }
        #expect(try Data(contentsOf: current) == before)
        try Data("poškozená záloha".utf8).write(to: current)
        do {
            _ = try await worker.write(original, bookmark: bookmark)
            Issue.record("Poškozený původní soubor musí zůstat k obnově")
        } catch { #expect(error is BackupError) }
        #expect(try String(contentsOf: current, encoding: .utf8) == "poškozená záloha")
    }

    @Test func managerBacksUpEditsSurvivesRelaunchAndDisableKeepsFile() async throws {
        let root = try folder()
        defer { try? FileManager.default.removeItem(at: root) }
        let suite = "backup-unit-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let context = try memoryContext()
        let day = try #require(DiaryDate.parse("2026-10-13"))
        try AnswerStore.save("První", on: day, in: context, now: day)
        let manager = BackupManager(defaults: defaults)
        try await manager.configure(root, context: context)
        try AnswerStore.save("Po úpravě", on: day, in: context, now: day)
        manager.update(context: context)
        try await settle(manager)
        let file = root.appendingPathComponent(BackupFileWorker.directoryName).appendingPathComponent(BackupFileWorker.currentName)
        #expect(try await manager.read(file).answers.first?.text == "Po úpravě")
        let reopened = BackupManager(defaults: defaults)
        #expect(reopened.isConfigured)
        reopened.update(context: context, force: true)
        try await settle(reopened)
        #expect(reopened.problem == nil)
        #expect(reopened.lastWritten != nil)
        reopened.disable()
        #expect(!reopened.isConfigured)
        #expect(FileManager.default.fileExists(atPath: file.path))
    }

    @Test func failedBackupKeepsDatabaseAndRetriesAfterFolderReturns() async throws {
        let root = try folder()
        defer { try? FileManager.default.removeItem(at: root) }
        let suite = "backup-failure-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let context = try memoryContext()
        let manager = BackupManager(defaults: defaults)
        try await manager.configure(root, context: context)
        let backupDirectory = root.appendingPathComponent(BackupFileWorker.directoryName)
        // Soubor místo složky simuluje nedostupný / neplatný cíl.
        try FileManager.default.removeItem(at: backupDirectory)
        try Data("blokovaný cíl".utf8).write(to: backupDirectory)
        let day = try #require(DiaryDate.parse("2026-10-13"))
        try AnswerStore.save("Zůstane v databázi", on: day, in: context, now: day)
        manager.update(context: context)
        try await settle(manager)
        #expect(manager.problem != nil)
        #expect(try context.fetch(FetchDescriptor<Answer>()).first?.text == "Zůstane v databázi")
        try FileManager.default.removeItem(at: backupDirectory)
        manager.update(context: context)
        try await settle(manager)
        #expect(manager.problem == nil)
        #expect(try await manager.read(backupDirectory.appendingPathComponent(BackupFileWorker.currentName)).answers.first?.text == "Zůstane v databázi")
    }
}
