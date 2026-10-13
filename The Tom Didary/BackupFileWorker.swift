import Foundation

/// Souborové operace probíhají sériově mimo hlavní aktor. Koordinace je nutná
/// pro iCloud Drive i ostatní poskytovatele Soubory; úspěch znamená zápis souboru,
/// nikoli potvrzení vzdáleného cloudového serveru.
actor BackupFileWorker {
    static let directoryName = "The Tom Diary Backups"
    static let currentName = "diary-backup.json"
    static let previousName = "diary-backup-previous.json"

    nonisolated static func bookmark(for url: URL) throws -> Data {
        #if os(macOS)
        return try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
        #else
        return try url.bookmarkData(options: [.minimalBookmark], includingResourceValuesForKeys: nil, relativeTo: nil)
        #endif
    }

    func write(_ backup: DiaryBackup, bookmark: Data) throws -> Date {
        let data = try backup.encoded()
        var stale = false
        #if os(macOS)
        let options: URL.BookmarkResolutionOptions = [.withSecurityScope, .withoutUI]
        #else
        let options: URL.BookmarkResolutionOptions = [.withoutUI]
        #endif
        let directory = try URL(resolvingBookmarkData: bookmark, options: options, relativeTo: nil, bookmarkDataIsStale: &stale)
        guard !stale else { throw BackupError.accessLost }
        let access = directory.startAccessingSecurityScopedResource()
        // Soukromé testovací adresáře nepotřebují rozšíření sandboxu; chybu zápisu
        // i při neuděleném přístupu stále zachytí koordinátor / FileManager.
        defer { if access { directory.stopAccessingSecurityScopedResource() } }
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var result: Result<Date, Error> = .failure(BackupError.accessLost)
        coordinator.coordinate(writingItemAt: directory, options: .forMerging, error: &coordinationError) { root in
            result = Result {
                let manager = FileManager.default
                let folder = root.appendingPathComponent(Self.directoryName, isDirectory: true)
                try manager.createDirectory(at: folder, withIntermediateDirectories: true)
                let current = folder.appendingPathComponent(Self.currentName)
                let previous = folder.appendingPathComponent(Self.previousName)
                if manager.fileExists(atPath: current.path) {
                    let oldData: Data
                    let old: DiaryBackup
                    do { oldData = try Self.readLimited(current); old = try DiaryBackup.decode(oldData) }
                    catch { throw BackupError.unreadableExisting }
                    guard old.diaryID == backup.diaryID else { throw BackupError.anotherDiary }
                    if old.contentHash == backup.contentHash { return old.savedAt }
                    // Nejdřív uchováme ověřenou původní kopii. Selhání tohoto zápisu
                    // nechá aktuální soubor nedotčený. Nový soubor se nahrazuje atomicky.
                    try oldData.write(to: previous, options: [.atomic])
                }
                try data.write(to: current, options: [.atomic])
                return backup.savedAt
            }
        }
        if let coordinationError { throw coordinationError }
        return try result.get()
    }

    func read(_ url: URL) throws -> DiaryBackup {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        var coordinationError: NSError?
        var result: Result<DiaryBackup, Error> = .failure(BackupError.accessLost)
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { actual in
            result = Result { try DiaryBackup.decode(Self.readLimited(actual)) }
        }
        if let coordinationError { throw coordinationError }
        return try result.get()
    }

    private static func readLimited(_ url: URL) throws -> Data {
        if let bytes = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, bytes > DiaryBackup.maximumBytes {
            throw BackupError.tooLarge
        }
        // Limit platí i pro poskytovatele, který velikost neoznámí, nebo pro soubor,
        // jehož obsah se mezitím změnil. Nenačítáme libovolně velký vstup do paměti.
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var data = Data()
        while let part = try handle.read(upToCount: 64 * 1024), !part.isEmpty {
            guard data.count + part.count <= DiaryBackup.maximumBytes else { throw BackupError.tooLarge }
            data.append(part)
        }
        return data
    }
}
