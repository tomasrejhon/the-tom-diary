//
//  The_Tom_DidaryApp.swift
//  The Tom Didary
//
//  Created by Tomáš Rejhon on 10.09.2026.
//

import SwiftUI
import SwiftData

/// Vstupní bod aplikace. Vytvoří jednu databázi SwiftData a předá ji všem obrazovkám.
/// Seznam ve `Schema` určuje, které modely se skutečně ukládají; nyní pouze `Answer`.
@main
struct The_Tom_DidaryApp: App {
    // Kontejner žije po celou dobu běhu aplikace. Trvalé úložiště přežije její ukončení.
    // CloudKit capabilities nejsou nastavené: běžná instalace nyní ukládá data jen lokálně.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Answer.self,
        ])
        var modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        #if DEBUG
        // UI test dostane vlastní databázi podle UUID. Při opakovaném spuštění stejného
        // scénáře se použije stejný soubor, takže lze ověřit skutečné přetrvání dat.
        // Běžná instalace ani Release tento argument nepoužívají.
        if let token = DiaryDate.argument("--diary-test-store"), let id = UUID(uuidString: token) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("diary-test-\(id.uuidString).store")
            modelConfiguration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        }
        #endif

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Nespouštíme náhradní prázdnou databázi: zakryla by problém s načtením dat.
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DiaryRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
