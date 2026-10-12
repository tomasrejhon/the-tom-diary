import XCTest

/// XCTest scénáře ovládají skutečně spuštěnou aplikaci přes přístupnostní prvky.
/// Každý scénář má vlastní databázi a nastavení podle UUID; restart uvnitř scénáře
/// je znovu použije, zatímco další scénář začíná odděleně od osobních dat.
@MainActor
final class DiaryFlowTests: XCTestCase {
    private let storeID = UUID().uuidString
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Prohlížené datum a aktuální den jsou oddělené. „Půlnoc“ se simuluje v aplikaci,
    /// nikoli změnou systémového času telefonu nebo simulátoru.
    private func launch(_ date: String, currentDay: String? = nil, largeText: Bool = false) {
        app.launchArguments = ["--diary-test-store", storeID, "--diary-test-date", date,
                               "--diary-clock-date", currentDay ?? date, "--diary-hide-samples"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.staticTexts["dailyQuestion"].waitForExistence(timeout: 10))
    }

    private func write(_ value: String) {
        let editor = app.textViews["answerEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        // U delšího předvyplněného textu klepneme na konec: střed by mohl vložit
        // kurzor doprostřed. Test následně porovnává skutečnou hodnotu editoru.
        if let existing = editor.value as? String, !existing.isEmpty {
            editor.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap()
        } else {
            editor.tap()
        }
        editor.typeText(value)
        XCTAssertFalse(app.buttons["Hotovo"].exists)
    }

    private func save() {
        let button = app.buttons["saveAnswer"]
        // Zápis musí jít uložit bez tlačítka Hotovo nad klávesnicí.
        if !button.isHittable { app.staticTexts["diaryDate"].tap() }
        for _ in 0..<5 where !button.isHittable {
            // Tah v okraji posune celou stránku, nikoli vnitřní obsah TextEditoru.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.025, dy: 0.7))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.025, dy: 0.28)))
        }
        if !button.isHittable {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Nedostupné uložení"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCTAssertTrue(button.isHittable)
        button.tap()
        XCTAssertTrue(app.staticTexts["savedAnswer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textViews["answerEditor"].exists)
        XCTAssertFalse(app.buttons["saveAnswer"].exists)
    }

    private func edit() {
        let button = app.buttons["editAnswer"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(app.textViews["answerEditor"].waitForExistence(timeout: 5))
    }

    private func openMenu() {
        let button = app.buttons["openDiaryMenu"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        if !app.buttons["closeDiaryMenu"].waitForExistence(timeout: 5) {
            let failure = XCTAttachment(screenshot: app.screenshot())
            failure.name = "Otevření menu selhalo"
            failure.lifetime = .keepAlways
            add(failure)
        }
        XCTAssertTrue(app.buttons["closeDiaryMenu"].exists)
    }

    private func openTestSettings() {
        openMenu()
        if !app.buttons["testDateSettings"].exists {
            let version = app.buttons["appVersion"]
            for _ in 0..<5 { version.tap() }
        }
        let settings = app.buttons["testDateSettings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        if !settings.isHittable { app.swipeUp() }
        settings.tap()
    }

    private func changeDate(_ date: String) {
        openTestSettings()
        let input = app.textFields["testDateInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        let current = input.value as? String ?? ""
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + date)
        app.buttons["applyTestDate"].tap()
        XCTAssertTrue(app.staticTexts["dailyQuestion"].waitForExistence(timeout: 5))
    }

    private func advanceDay() {
        openTestSettings()
        app.buttons["advanceTestClock"].tap()
    }

    /// Čtecí režim po uložení, úprava, přetrvání po restartu a automatické uložení na pozadí.
    func testSaveEditRelaunchAndBackground() {
        launch("2026-10-11")
        write("Prvni odpoved.")
        save()
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, "Prvni odpoved.")
        XCTAssertTrue(app.buttons["editAnswer"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Uložená dnešní odpověď"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.terminate()
        launch("2026-10-11")
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, "Prvni odpoved.")
        XCTAssertFalse(app.textViews["answerEditor"].exists)
        edit()
        XCTAssertEqual(app.textViews["answerEditor"].value as? String, "Prvni odpoved.")
        write(" Doplneni.")
        let edited = (app.textViews["answerEditor"].value as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(edited.contains("Prvni odpoved."), "Po úpravě: \(edited)")
        XCTAssertTrue(edited.contains("Doplneni."), "Po úpravě: \(edited)")
        save()
        app.terminate()
        launch("2026-10-11")
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, edited)
        edit()
        write(" Na pozadi.")
        let backgroundEdit = (app.textViews["answerEditor"].value as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["savedAnswer"].waitForExistence(timeout: 5))
        app.terminate()
        launch("2026-10-11")
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, backgroundEdit)
    }

    /// Minulý den zůstává uzavřený; nový rok otevře nový samostatný záznam.
    func testPreviousDayIsReadOnlyAndNewDayStartsEmpty() {
        launch("2026-12-31")
        write("Posledni den roku.")
        save()
        advanceDay()
        XCTAssertTrue(app.staticTexts["savedAnswer"].exists)
        XCTAssertFalse(app.buttons["editAnswer"].exists)
        XCTAssertFalse(app.textViews["answerEditor"].exists)
        XCTAssertFalse(app.buttons["saveAnswer"].exists)
        changeDate("2027-01-01")
        write("Novy rok.")
        save()
        changeDate("2026-12-31")
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, "Posledni den roku.")
        XCTAssertFalse(app.buttons["editAnswer"].exists)
        app.terminate()
        launch("2026-12-31", currentDay: "2027-01-01")
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, "Posledni den roku.")
        XCTAssertFalse(app.buttons["editAnswer"].exists)
        changeDate("2027-01-01")
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, "Novy rok.")
        XCTAssertTrue(app.buttons["editAnswer"].exists)
    }

    /// Posun 29. 2. -> 1. 3. nesmí přepsat uloženou odpověď neuloženou úpravou.
    func testMidnightClosesOpenEditorWithoutOverwritingSavedAnswer() {
        launch("2024-02-29")
        XCTAssertTrue(app.staticTexts["dailyQuestion"].label.contains("29.2."))
        write("Prestupny den.")
        save()
        edit()
        write(" Neulozena uprava.")
        let draft = app.textViews["answerEditor"].value as? String
        advanceDay()
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, "Prestupny den.")
        XCTAssertFalse(app.buttons["editAnswer"].exists)
        XCTAssertFalse(app.textViews["answerEditor"].exists)
        XCTAssertEqual(app.staticTexts["closedDraft"].label, draft)
        changeDate("2024-03-01")
        XCTAssertTrue(app.textViews["answerEditor"].exists)
        XCTAssertEqual(app.textViews["answerEditor"].value as? String, "")
        app.terminate()
        launch("2024-02-29", currentDay: "2024-03-01")
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, "Prestupny den.")
        XCTAssertFalse(app.buttons["editAnswer"].exists)
    }

    /// Prohlížení jiného dne nejprve uloží rozepsaný dnešek k jeho původnímu datu.
    func testDateChangesPreserveDraftWithinCurrentDay() {
        launch("2026-10-11")
        write("Dnesni rozepsana odpoved.")
        changeDate("2026-10-10")
        XCTAssertTrue(app.staticTexts["noAnswer"].exists)
        XCTAssertFalse(app.textViews["answerEditor"].exists)
        changeDate("2026-10-11")
        XCTAssertEqual(app.staticTexts["savedAnswer"].label, "Dnesni rozepsana odpoved.")
        XCTAssertTrue(app.buttons["editAnswer"].exists)
    }

    /// Součty, aktuální streak, páté klepnutí, ukázky bez ukládání a reset nástrojů po restartu.
    func testMenuStatsAndDeveloperToolsResetOnRelaunch() {
        launch("2026-10-11")
        XCTAssertFalse(app.buttons["testDateSettings"].exists)
        XCTAssertFalse(app.staticTexts["Testovací datum"].exists)
        XCTAssertFalse(app.staticTexts["Ukázkové odpovědi · neukládají se do deníku"].exists)
        write("Odpoved do statistiky.")
        save()
        openMenu()
        XCTAssertEqual(app.staticTexts["thisYearAnswerCount"].label, "1 odpověď")
        XCTAssertFalse(app.staticTexts["totalAnswerCount"].exists)
        XCTAssertEqual(app.staticTexts["currentStreak"].label, "1 den v řadě")
        XCTAssertEqual(app.staticTexts["activityYearCaption"].label, "přehled roku 2026")
        XCTAssertEqual(app.buttons["appVersion"].label, "v1.0.0")
        XCTAssertFalse(app.buttons["testDateSettings"].exists)
        let menu = XCTAttachment(screenshot: app.screenshot())
        menu.name = "Nové postranní menu"
        menu.lifetime = .keepAlways
        add(menu)
        for _ in 0..<4 { app.buttons["appVersion"].tap() }
        XCTAssertFalse(app.buttons["testDateSettings"].exists)
        app.buttons["appVersion"].tap()
        XCTAssertTrue(app.buttons["testDateSettings"].waitForExistence(timeout: 5))
        app.buttons["testDateSettings"].tap()
        let samples = app.switches["sampleHistoryToggle"]
        XCTAssertTrue(samples.waitForExistence(timeout: 5))
        XCTAssertEqual(samples.value as? String, "0")
        samples.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(samples.value as? String, "1")
        app.buttons["applyTestDate"].tap()
        XCTAssertTrue(app.staticTexts["Ukázkové odpovědi · neukládají se do deníku"].waitForExistence(timeout: 5))
        openMenu()
        XCTAssertEqual(app.staticTexts["thisYearAnswerCount"].label, "1 odpověď")
        XCTAssertEqual(app.staticTexts["currentStreak"].label, "1 den v řadě")
        app.buttons["closeDiaryMenu"].tap()
        XCTAssertTrue(app.staticTexts["savedAnswer"].waitForExistence(timeout: 5))
        app.terminate()
        launch("2026-10-11")
        XCTAssertFalse(app.staticTexts["Ukázkové odpovědi · neukládají se do deníku"].exists)
        XCTAssertFalse(app.staticTexts["Testovací datum"].exists)
        openMenu()
        XCTAssertFalse(app.buttons["testDateSettings"].exists)
        XCTAssertEqual(app.staticTexts["thisYearAnswerCount"].label, "1 odpověď")
    }

    /// Vypnutá připomínka s vlastním textem přetrvá restart; neověřuje doručení.
    func testNotificationTextPersistsAfterRelaunch() {
        launch("2026-10-11")
        openMenu()
        app.buttons["notificationSettings"].tap()
        let title = app.textFields["reminderTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(app.switches["reminderEnabled"].value as? String, "0")
        title.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.8)).tap()
        let existing = title.value as? String ?? ""
        title.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count) + "Muj denik")
        let body = app.descendants(matching: .any)["reminderBody"].firstMatch
        XCTAssertTrue(body.exists)
        body.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap()
        let previous = body.value as? String ?? ""
        body.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: previous.count) + "Cas na dnesni odpoved.")
        app.buttons["saveReminderSettings"].tap()
        XCTAssertTrue(app.staticTexts["dailyQuestion"].waitForExistence(timeout: 5))
        app.terminate()
        launch("2026-10-11")
        openMenu()
        app.buttons["notificationSettings"].tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.value as? String, "Muj denik")
        XCTAssertEqual(body.value as? String, "Cas na dnesni odpoved.")
        let settings = XCTAttachment(screenshot: app.screenshot())
        settings.name = "Nastavení oznámení"
        settings.lifetime = .keepAlways
        add(settings)
    }

    /// Čtyři roky skutečných zápisů, řazení a konec dlouhého textu při největším písmu.
    func testFourRealYearsLongTextAndLargeType() {
        let paragraph = "Dnes jsem sel na dlouhou prochazku a premyslel o uplynulem roce. Cestou jsem potkal kamarada a chvili jsme si povidali. Odpoledne jsem dokoncil odkladanou praci a uvaril veceri. Vecer jsem si precetl nekolik kapitol oblibene knihy. Byl to klidny den, na ktery chci vzpominat."
        for year in 2022...2025 {
            launch("\(year)-09-20")
            write("Rok \(year).\n\n" + paragraph)
            save()
            app.terminate()
        }
        launch("2026-09-20", largeText: true)
        XCTAssertFalse(app.staticTexts["Ukázkové odpovědi · neukládají se do deníku"].exists)
        let entries = (2022...2025).reversed().map { app.staticTexts["historyText-\($0)"] }
        for entry in entries {
            XCTAssertTrue(entry.exists)
            XCTAssertTrue(entry.label.contains(paragraph))
        }
        for index in 0..<3 { XCTAssertLessThan(entries[index].frame.minY, entries[index + 1].frame.minY) }
        let oldest = app.staticTexts["historyText-2022"]
        for _ in 0..<35 {
            if oldest.isHittable && oldest.frame.maxY < app.frame.maxY - 40 { break }
            app.swipeUp()
        }
        XCTAssertTrue(oldest.isHittable)
        XCTAssertLessThan(oldest.frame.maxY, app.frame.maxY - 20)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Historie 2022 – velké písmo a konec dlouhého textu"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
