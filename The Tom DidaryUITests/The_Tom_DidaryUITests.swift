//
//  The_Tom_DidaryUITests.swift
//  The Tom DidaryUITests
//
//  Created by Tomáš Rejhon on 10.09.2026.
//

import XCTest

/// Původní scénáře Xcode: základní spuštění a měření délky startu.
/// Start používá běžná data simulátoru; nic do nich nezapisuje.
final class The_Tom_DidaryUITests: XCTestCase {

    override func setUpWithError() throws {
        // Zastavíme scénář na první chybě, aby nevytvářel zavádějící další výsledky.
        continueAfterFailure = false

        // Datové a kalendářní scénáře s izolací jsou v DiaryFlowTests.
    }

    override func tearDownWithError() throws {
        // Tento startovací scénář nevytváří vlastní testovací soubory.
    }

    @MainActor
    func testExample() throws {
        // Smoke test: ověří, že lze aplikaci spustit; nekontroluje obsah odpovědí.
        let app = XCUIApplication()
        app.launch()

        // Podrobné funkční kontroly obsahuje DiaryFlowTests.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // Výkonnostní metrika startu; není to kontrola správnosti deníku.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
