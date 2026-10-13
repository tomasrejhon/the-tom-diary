import SwiftUI
import SwiftData
import Combine

/// Lehká hodnota pro zobrazení historie. Nemá vazbu na databázi; používá ji
/// skutečná historie i ukázka, takže ukázkový text nikdy nevytvoří `Answer`.
struct HistoryEntry: Identifiable {
    let year: Int
    let text: String
    var id: Int { year }
}

/// Dočasná kopie neuložené úpravy ze skončeného dne. Slouží jen ke zkopírování;
/// po úplném ukončení aplikace zmizí a nikdy nepřepíše uzavřený den v databázi.
private struct ClosedDraft {
    let date: Date
    let text: String
}

/// Hlavní obrazovka: otázka, dnešní odpověď, stejné dny minulých let a menu.
/// Přepínání editoru řídí UI stav; samotné ukládání a časovou kontrolu dělá AnswerStore.
struct ContentView: View {
    // Environment předává databázový kontext a stav aplikace. Query automaticky
    // aktualizuje seznam při změně modelů v tomto SwiftData kontejneru.
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var answers: [Answer]
    private let questionProvider = QuestionProvider()

    init(date: Date = DiaryDate.initialDate) {
        _today = State(initialValue: date)
    }
    // text = rozepsaná hodnota, savedText = poslední úspěšně uložená hodnota.
    // today = prohlížený den, currentDate = aktuální čas rozhodující o zápisu.
    @State private var text = ""
    @State private var savedText = ""
    @State private var today = DiaryDate.initialDate
    @State private var currentDate = DiaryDate.now
    @State private var isChangingAnswer = false
    @State private var closedDraft: ClosedDraft?
    @State private var message: String?
    @State private var saveStatus = ""
    @FocusState private var isEditing: Bool
    // Testovací datum, ukázky i odemčení žijí jen v paměti této obrazovky.
    // Návrat z pozadí je nezruší; úplné ukončení a nové spuštění ano.
    @State private var isTestDate = DiaryDate.hasOverride
    @State private var showDateSettings = false
    @State private var showSampleHistory = false
    @State private var proposedDate = DiaryDate.initialDate
    @State private var proposedDateText = ""
    @State private var developerToolsUnlocked = false
    @State private var showMenu = false
    @State private var showNotificationSettings = false
    @State private var showBackupSettings = false
    @StateObject private var backup = BackupManager(defaults: DiaryPreferences.defaults)
    @StateObject private var signing = SigningReminder(defaults: DiaryPreferences.defaults)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var question: Question? {
        let c = DiaryDate.components(today)
        return questionProvider.question(day: c.day!, month: c.month!)
    }
    private var storedHistory: [HistoryEntry] {
        AnswerStore.previousYears(on: today, in: answers).map { HistoryEntry(year: $0.year, text: $0.text) }
    }
    // Vlastní starší odpovědi mají přednost. Ukázka vyžaduje odemčení i přepínač.
    private var showingSampleHistory: Bool {
        developerToolsUnlocked && showSampleHistory && storedHistory.isEmpty
    }
    private var previousYears: [HistoryEntry] {
        showingSampleHistory ? HistoryDemo.answers(for: today) : storedHistory
    }
    // Statistiky používají kalendářní klíče skutečných modelů, nikoli demo ani
    // právě prohlížené testovací datum. Prázdné odpovědi se nezapočítají.
    private var statistics: DiaryStatistics {
        let dates = answers.compactMap { answer -> Date? in
            guard !answer.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return DiaryDate.parse(String(format: "%04d-%02d-%02d", answer.year, answer.month, answer.day))
        }
        return DiaryStatistics(answerDates: dates, now: currentDate, calendar: DiaryDate.calendar)
    }
    private var menuAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.15) : .spring(response: 0.36, dampingFraction: 0.88)
    }
    private var year: Int { DiaryDate.components(today).year! }
    private var hasChanges: Bool { text != savedText }
    private var canWrite: Bool { DiaryDate.canWrite(on: today, now: currentDate) }
    // Nový dnešní záznam -> editor; uložený dnešek -> čtení s odkazem na úpravu.
    // Historický nebo budoucí den -> vždy jen čtení, i když se ručně prohlíží.
    private var showEditor: Bool { canWrite && (savedText.isEmpty || isChangingAnswer) }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                diaryNavigation
                    .allowsHitTesting(!showMenu)
                    .accessibilityHidden(showMenu)
                // Overlay má rozměr celé dostupné obrazovky. Jen skleněné pozadí
                // ignoruje safe area; obsah zůstává mimo stavový řádek a spodní gesto.
                if showMenu {
                    DiarySidebar(statistics: statistics, developerToolsUnlocked: developerToolsUnlocked,
                                 close: closeMenu,
                                 notificationSettings: { closeMenu(); showNotificationSettings = true },
                                 backup: backup, signing: signing,
                                 backupSettings: {
                                     if hasChanges && !saveAnswer() { return }
                                     closeMenu(); showBackupSettings = true
                                 },
                                 testSettings: {
                                     proposedDate = today
                                     proposedDateText = DiaryDate.string(today)
                                     closeMenu()
                                     showDateSettings = true
                                 },
                                 unlockDeveloperTools: { developerToolsUnlocked = true })
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .background {
                            Color.clear
                                .glassEffect(.regular, in: Rectangle())
                                .ignoresSafeArea()
                        }
                        .contentShape(Rectangle())
                        .transition(reduceMotion ? .opacity : .move(edge: .leading).combined(with: .opacity))
                        .gesture(DragGesture(minimumDistance: 30).onEnded { value in
                            if value.translation.width < -65 && abs(value.translation.width) > abs(value.translation.height) { closeMenu() }
                        })
                        .zIndex(1)
                }
            }
            .animation(menuAnimation, value: showMenu)
        }
            .alert("Roční zápisník otázek", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) { message = nil }
            } message: { Text(message ?? "") }
            .onAppear { currentDate = DiaryDate.now; preloadAnswer() }
            .task {
                #if DEBUG
                await backup.configureTestFolderIfNeeded(context: modelContext)
                #endif
                backup.update(context: modelContext, force: true)
                await signing.refresh()
            }
            .onChange(of: text) { _, _ in if hasChanges { saveStatus = "Neuložené změny" } }
            // Neaktivní stav nastává i při odchodu na plochu: neprázdné změny
            // zkusíme uložit. Po návratu znovu ověříme den, který se mohl změnit.
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    refreshDate()
                    backup.update(context: modelContext, force: true)
                    Task { await signing.refresh() }
                }
                if phase == .inactive, hasChanges { _ = saveAnswer() }
            }
            // Systémová změna dne přichází na hlavní smyčku. Timer je doplňková
            // kontrola, nikoli práce na pozadí; před uložením se čas ověří ještě jednou.
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in refreshDate() }
            .refreshable { refreshDate() }
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
                refreshDate()
                if backup.problem != nil { backup.update(context: modelContext) }
            }
            .sheet(isPresented: $showDateSettings) { dateSettings }
            .sheet(isPresented: $showNotificationSettings) { ReminderSettingsView() }
            .sheet(isPresented: $showBackupSettings, onDismiss: { preloadAnswer() }) { BackupSettingsView(backup: backup) }
    }

    /// Běžný obsah v jednom svislém ScrollView; délka historie neomezuje výšku karet.
    private var diaryNavigation: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(today.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "cs_CZ"))))
                        .font(.subheadline).foregroundStyle(.secondary)
                        .accessibilityIdentifier("diaryDate")
                        .onTapGesture { isEditing = false }
                    if developerToolsUnlocked && isTestDate {
                        Label("Testovací datum", systemImage: "calendar.badge.clock")
                            .font(.caption).foregroundStyle(.orange)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Otázka dne").font(.headline).foregroundStyle(.secondary)
                        Text(question?.displayPrompt ?? "Otázku se nepodařilo načíst.")
                            .font(.title2).fontWeight(.semibold).textSelection(.enabled)
                            .accessibilityIdentifier("dailyQuestion")
                            .onTapGesture { isEditing = false }
                        if let error = questionProvider.loadError {
                            Text(error).font(.footnote).foregroundStyle(.red)
                        }
                    }
                    answerSection
                    if let draft = closedDraft {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Neuložený text z \(draft.date.formatted(.dateTime.day().month().year().locale(Locale(identifier: "cs_CZ"))))")
                                .font(.headline)
                            Text("Den už skončil. Text si můžeš zkopírovat; uložená odpověď zůstala zachovaná.")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(draft.text).textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("closedDraft")
                        }.padding(14).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Divider()
                    Text("Minulé roky").font(.headline)
                    if showingSampleHistory {
                        Text("Ukázkové odpovědi · neukládají se do deníku")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if previousYears.isEmpty {
                        Text("Zatím tu není odpověď z předchozích let. Ta letošní tu na tebe počká příští rok.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    } else {
                        ForEach(previousYears) { answer in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(String(answer.year)).font(.headline).foregroundStyle(.secondary)
                                Text(answer.text).textSelection(.enabled)
                                    .accessibilityIdentifier("historyText-\(answer.year)")
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }.padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .accessibilityHidden(showMenu)
            .navigationTitle("Roční zápisník otázek")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: openMenu) {
                        Label("Otevřít menu", systemImage: "line.3.horizontal")
                    }.accessibilityIdentifier("openDiaryMenu")
                    .accessibilityHidden(showMenu)
                }
            }
        }
    }

    /// Zavře klávesnici a obnoví čas statistik ještě před zobrazením menu.
    private func openMenu() {
        isEditing = false
        currentDate = DiaryDate.now
        showMenu = true
    }

    private func closeMenu() { showMenu = false }

    /// Tři stavy: psaní, uložená odpověď a prázdný uzavřený den.
    /// Accessibility identifikátory používají UI testy; neovlivňují viditelný text.
    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showEditor {
                Text("Tvoje odpověď (\(String(year)))").font(.headline)
                TextEditor(text: $text)
                    .focused($isEditing)
                    .frame(minHeight: 150)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityLabel("Tvoje odpověď")
                    .accessibilityIdentifier("answerEditor")
                Button {
                    _ = saveAnswer()
                } label: {
                    Label("Uložit odpověď", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(question == nil || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("saveAnswer")
                if !saveStatus.isEmpty {
                    Text(saveStatus).font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("saveStatus")
                }
            } else if !savedText.isEmpty {
                Text(canWrite ? "Dnes už jsi svou odpověď zaznamenal." : "Tvoje zaznamenaná odpověď")
                    .font(.headline).accessibilityIdentifier("answerRecorded")
                Text(savedText).textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("savedAnswer")
                if canWrite {
                    Button("Chceš svoji dnešní odpověď upravit?") { beginEditing() }
                        .font(.subheadline)
                        .accessibilityIdentifier("editAnswer")
                }
                if backup.isConfigured {
                    Label(backup.status, systemImage: backup.symbol)
                        .font(.caption).foregroundStyle(backup.problem == nil ? Color.secondary : Color.orange)
                        .accessibilityIdentifier("backupStatus")
                }
            } else {
                Text("Pro tento den nemáš zaznamenanou odpověď.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .accessibilityIdentifier("noAnswer")
            }
        }
    }

    /// Skryté ruční prohlížení data je dostupné i v Release po pěti klepnutích.
    /// Posun hodin je navíc jen v Debug a pouze při spuštění s izolovaným testovacím časem.
    private var dateSettings: some View {
        NavigationStack {
            Form {
                #if DEBUG
                if DiaryDate.testingNow != nil {
                    Button("Posunout testovací čas o den") {
                        DiaryDate.testingNow = DiaryDate.calendar.date(byAdding: .day, value: 1, to: DiaryDate.now)
                        showDateSettings = false
                        refreshDate()
                    }.accessibilityIdentifier("advanceTestClock")
                }
                #endif
                Toggle("Zobrazit ukázkové minulé roky", isOn: $showSampleHistory)
                    .accessibilityIdentifier("sampleHistoryToggle")
                Text("Ukázka se zobrazí na hlavní stránce, pokud pro vybraný den nemáš vlastní starší odpovědi.")
                    .font(.footnote)
                DatePicker("Datum", selection: $proposedDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "cs_CZ"))
                    .environment(\.calendar, DiaryDate.calendar)
                    .onChange(of: proposedDate) { _, date in proposedDateText = DiaryDate.string(date) }
                TextField("RRRR-MM-DD", text: $proposedDateText)
                    .accessibilityIdentifier("testDateInput")
                    .onChange(of: proposedDateText) { _, value in
                        if let date = DiaryDate.parse(value) { proposedDate = date }
                    }
                Text("Starší a budoucí dny slouží jen ke čtení. Zapisovat a upravovat lze pouze v aktuálním dni.")
                    .font(.footnote)
                Button("Použít datum") {
                    if let date = DiaryDate.parse(proposedDateText), changeDate(to: date) { isTestDate = true; showDateSettings = false }
                }
                .disabled(DiaryDate.parse(proposedDateText) == nil)
                .accessibilityIdentifier("applyTestDate")
                Button("Použít skutečné dnešní datum") {
                    if changeDate(to: DiaryDate.now) { isTestDate = false; showDateSettings = false }
                }
            }
            .navigationTitle("Testovací datum")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Zavřít") { showDateSettings = false } } }
        }.frame(minWidth: 300, minHeight: 320)
    }

    /// Načte vybraný den z databáze a obnoví čtecí režim bez otevřené klávesnice.
    private func preloadAnswer() {
        text = AnswerStore.answer(on: today, in: answers)?.text ?? ""
        savedText = text
        isChangingAnswer = false
        isEditing = false
        saveStatus = text.isEmpty ? "" : "Uloženo v zařízení"
    }

    /// Vrací úspěch, aby přepnutí data nezahodilo text při chybě ukládání.
    /// Čas ověřuje přímo teď: hodnota z posledního timeru může být už zastaralá.
    @discardableResult
    private func saveAnswer() -> Bool {
        guard question != nil else { return false }
        guard DiaryDate.canWrite(on: today, now: DiaryDate.now) else {
            preserveClosedDraft()
            message = "Den už skončil. Odpověď z tohoto dne už nelze měnit."
            return false
        }
        // Vymazání rozepsaného textu nikdy potichu nesmaže dříve uloženou odpověď.
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            if hasChanges { message = "Odpověď je prázdná. Doplň text, aby se změna mohla uložit."; return false }
            return true
        }
        do {
            try AnswerStore.save(text, on: today, in: modelContext)
            backup.update(context: modelContext)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            savedText = text
            saveStatus = "Uloženo v zařízení"
            isChangingAnswer = false
            isEditing = false
            return true
        } catch {
            message = "Odpověď se nepodařilo uložit. Text zůstává rozepsaný. \(error.localizedDescription)"
            return false
        }
    }

    /// Před přechodem z dneška uloží změny k původnímu dni. Po půlnoci je uchová
    /// jen jako dočasný ClosedDraft, protože uzavřený den už měnit nesmíme.
    @discardableResult
    private func changeDate(to date: Date) -> Bool {
        if hasChanges {
            if DiaryDate.canWrite(on: today, now: DiaryDate.now) {
                if !saveAnswer() { return false }
            } else {
                preserveClosedDraft()
            }
        }
        currentDate = DiaryDate.now
        today = date
        preloadAnswer()
        return true
    }

    /// Zachová neuloženou neprázdnou úpravu ke zkopírování a vrátí uložený text.
    private func preserveClosedDraft() {
        if hasChanges, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            closedDraft = ClosedDraft(date: today, text: text)
        }
        text = savedText
        isChangingAnswer = false
        isEditing = false
        currentDate = DiaryDate.now
    }

    /// Odkaz na úpravu předvyplní editor; starší den neotevře ani při zastaralém UI.
    private func beginEditing() {
        currentDate = DiaryDate.now
        guard canWrite else { refreshDate(); return }
        text = savedText
        isChangingAnswer = true
        isEditing = true
    }

    /// Běžný režim automaticky přepne na nový den. Ručně zvolené testovací datum
    /// zůstane otevřené, ale možnost zápisu se vždy řídí aktuálním časem.
    private func refreshDate() {
        currentDate = DiaryDate.now
        if !DiaryDate.canWrite(on: today, now: currentDate), hasChanges { preserveClosedDraft() }
        guard !isTestDate else { return }
        if !DiaryDate.calendar.isDate(today, inSameDayAs: currentDate) { _ = changeDate(to: currentDate) }
    }


}

#Preview {
    ContentView().modelContainer(for: Answer.self, inMemory: true)
}
