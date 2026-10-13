# Testy a výsledky

## Rozsah současné sady

Verze 1.1.0 obsahuje **41 různých testů**: 30 ve Swift Testing a 11 UI testů XCTest. Jeden jednotkový test je prázdná původní šablona. Níže je původní matice verze 1.0.0; nové testy a výsledky jsou v poslední části této stránky.

Počet úspěšných testů není počet jednotlivých assertions ani záruka otestování každé možné situace. UI kontrola přetrvání textu oznámení není test jeho skutečného doručení. Sestavení není test obnovy dat na jiném telefonu.

## Jednotkové testy

### DiaryTests — 9

| Test | Co konkrétně ověřuje |
| --- | --- |
| `bundledQuestionsCoverEveryCalendarDay` | Načtení vestavěného JSONu, 366 jedinečných otázek, průchod všemi dny 2023 a 2024, neprázdné otázky, délku emoji a konkrétní zadání 29. února a 13. září. |
| `datesRejectInvalidLeapDays` | Platný přestupný den, odmítnutí 29. února v běžném roce, 31. dubna, neplatného měsíce, roku 0000 a chybného formátu. |
| `malformedQuestionResourcesFailVisibly` | Odmítnutí katalogu s duplicitou a prázdného katalogu. |
| `savingUpdatesOneAnswerAndIgnoresWhitespace` | Trim textu, aktualizaci stejného dne bez dalšího záznamu a prázdný vstup, který nesmaže uložený text. |
| `historyMatchesMonthAndDayAndExcludesFutureYears` | Shodný den/měsíc, vyloučení aktuálního i budoucího roku a cizích dat, sestupné pořadí. |
| `answerSurvivesReopeningPersistentStore` | Skutečný soubor databáze, opakované uložení, nový kontejner nad stejným souborem a dva různé dny na přelomu roku. |
| `leapDayHistoryNeverIncludesFebruary28OrMarch1` | Historii 29. února pouze z přestupných roků, bez sousedních dnů a aktuálního roku. |
| `closedDaysCannotBeCreatedOrEdited` | Zákaz přepisu včerejška i vytváření budoucí odpovědi, zachování původního záznamu. |
| `editPermissionExpiresAtMidnight` | Právo úpravy sekundu před půlnocí, zákaz přesně o půlnoci a sekundu po ní. |

### DiaryStatisticsTests — 7

| Test | Co konkrétně ověřuje |
| --- | --- |
| `countsUniqueDaysAndIgnoresFutureAnswers` | Deduplikaci dne, letošní/celkový součet a ignorování budoucích záznamů. |
| `todayExtendsYesterdayStreakWithoutBreakingAnUnfinishedDay` | Série z včerejška zůstává během nevyplněného dneška; dnešní odpověď ji prodlouží. |
| `missedFullDayBreaksStreak` | Celý vynechaný den přeruší sérii, dnešní zápis ji začne znovu, prázdný deník má 0. |
| `streakCrossesYearAndDaylightSavingBoundaries` | Návaznost přes nový rok a jarní/podzimní datum změny času. Referenční prostředí je Europe/Prague; test používá aktuální pásmo běhu. |
| `totalAppearsOnlyOneYearAndOneDayAfterFirstAnswer` | Celkový počet skrytý v den výročí, viditelný následující den a skrytý bez odpovědí. |
| `leapDayAnniversaryAppearsOnMarch1` | Odkrytí celkového součtu pro první zápis 29. 2. až 1. 3. následujícího roku. |
| `heatmapCoversLeapYearAndDistinguishesStatuses` | Všech 366/365 dnů bez duplicit, pondělní začátek, prázdná krajní místa a stavy answered/missed/pending/future. |

### ReminderTests — 3, šablona — 1

| Test | Co konkrétně ověřuje |
| --- | --- |
| `dailyRequestUsesCustomTimeAndTrimmedContent` | Stálé ID, vlastní hodinu/minutu, trim nadpisu a obsahu, zvuk a kalendářní opakování bez konkrétního dne. |
| `reminderRejectsInvalidTimeOrEmptyEnabledContent` | Neplatnou hodinu/minutu, prázdný obsah zapnuté připomínky a povolení prázdného obsahu při vypnutí. |
| `preferencesSurviveReopeningTheirStore` | Zápis a nové otevření oddělené UserDefaults suite se zachovaným časem a textem. |
| `The_Tom_DidaryTests.example` | Prázdný původní test, bez assertions. Je v počtu 30, ale není funkčním pokrytím. |

## UI testy

### DiaryFlowTests — 7

| Test | Co konkrétně ověřuje |
| --- | --- |
| `testSaveEditRelaunchAndBackground` | Psání bez tlačítka Hotovo, skrytí editoru po uložení, zobrazení odkazu na úpravu, předvyplnění, další uložení, restart a automatické uložení při odchodu na plochu. |
| `testPreviousDayIsReadOnlyAndNewDayStartsEmpty` | Uzavření starého dne na přelomu roku, nepřítomnost editoru/uložení/úpravy, samostatnou novoroční odpověď a zachování obou po restartu. |
| `testMidnightClosesOpenEditorWithoutOverwritingSavedAnswer` | Simulovaný přechod 29. 2. → 1. 3., zachování uložené odpovědi, dočasnou kopii neuložené úpravy a nový prázdný editor. |
| `testDateChangesPreserveDraftWithinCurrentDay` | Automatické uložení dnešní rozepsané odpovědi před prohlížením včerejška a její opětovné načtení při návratu. |
| `testMenuStatsAndDeveloperToolsResetOnRelaunch` | Zpočátku skryté nástroje/ukázky, počet 1 a série 1, rok/verzi, odemčení až pátým klepnutím, zapnutí ukázek bez změny součtu a opětovné skrytí po restartu. Ukládá snímek menu. |
| `testNotificationTextPersistsAfterRelaunch` | Výchozí vypnutí, vlastní nadpis/obsah, uložení a přesnou shodu po restartu. Připomínka zůstává vypnutá; neověřuje permission dialog ani doručení. |
| `testFourRealYearsLongTextAndLargeType` | Skutečné zápisy 2022–2025 do izolované databáze, načtení v roce 2026, správný obsah a pořadí, žádné demo a doscrollování nejstarší odpovědi při největším přístupnostním písmu. |

### Ostatní UI testy — 3

| Test | Co konkrétně ověřuje |
| --- | --- |
| `The_Tom_DidaryUITests.testExample` | Spuštění aplikace jako jednoduchý smoke test. Neobsahuje assertions nad deníkem. |
| `The_Tom_DidaryUITests.testLaunchPerformance` | Měření startu pomocí XCTApplicationLaunchMetric; neověřuje datovou logiku. |
| `The_Tom_DidaryUITestsLaunchTests.testLaunchStaysPortraitWhenPhoneRotates` | Spuštění při landscapeLeft a následné otočení na výšku/obě šířky; rozměr skutečného okna zůstává na výšku. |

## Izolace a spouštění

Automatické testy spouštěj v **simulátoru** přes ⌘U. Konkrétní scénář lze spustit z Test Navigatoru kontextovou nabídkou Run. UI scénáře jsou pomalejší: opakovaně spouštějí aplikaci a pracují s klávesnicí.

`DiaryFlowTests` přiděluje každému scénáři nové UUID. SwiftData soubor a UserDefaults jsou oddělené od běžného úložiště a po restartu uvnitř scénáře znovu použijí stejné UUID. Testy nemusí čekat na skutečnou půlnoc; používají simulovaný aktuální den a jeho posun v Debug aplikaci. Nemění systémový čas.

Systémové oprávnění a UNUserNotificationCenter jsou ovšem společné pro aplikaci daného simulátoru, nejsou oddělené UUID databáze. Vypnutí připomínky v testu může odstranit požadavek stejného ID v této simulátorové instalaci. Ostatní původní UI testy používají běžná data simulátoru a jen aplikaci spouštějí. Automatickou sadu proto nepouštěj na telefonu s osobním deníkem; fyzické ověření proveď ručně.

Unit testy používají vlastní kontejnery v paměti, vlastní dočasný soubor nebo UserDefaults suite. Trvalý unit test po sobě dočasnou složku odstraní. UUID databáze UI testů mohou po běhu v simulátoru zůstat; jejich existence není synchronizace či uživatelská záloha.

## Provedené běhy

| Datum / etapa | Prostředí | Doložený výsledek a meze |
| --- | --- | --- |
| Úvodní připojení otázek | Mac a iPhone simulátor | 6 nových datových testů a původní startovací testy; ještě před pozdějšími změnami ukládání/UI. |
| 20. 9. 2026 | iPhone 17 / iOS 26.3 | Jeden konečný úplný běh: 17 spuštěných testů, 0 selhání. Zahrnoval i různé konfigurace tehdejších startovacích testů. [Výsledky](TestResults/vysledky-testu.json). |
| 23. 9. 2026, orientace | iPhone 17 / iOS 26.3 | Úplný běh po změně orientace: 14 testů, 14 úspěšných. [Výsledky](TestResults/vysledky-orientace.json). |
| 11. 10. 2026, čtení/úprava dneška | iPhone 17 / iOS 27.0 | 18 různých testů mělo konečný úspěšný výsledek. První úplný běh 17/18; po opravě cílení gest opakovány dotčené scénáře a datové testy. Nešlo o druhý úplný běh všech 18 současně. [Výsledky](TestResults/vysledky-uprav-odpovedi-2026-10-11.json). |
| 11. 10. 2026, menu/oznámení | iPhone 17 / iOS 27.0 | 30 různých testů mělo konečný úspěšný výsledek napříč třemi běhy. První úplný běh měl 24 úspěchů a 6 UI selhání; dotčené scénáře po opravách prošly opakováním. Debug i Release byly sestavené. [Přesný přehled s původem výsledků](TestResults/vysledky-menu-2026-10-11.json). |
| 11. 10. 2026, celostránkové menu | iPhone 17 / iOS 27.0 | Znovu prošel jediný dotčený UI scénář menu; snímek skutečného výsledku. [Výsledky](TestResults/fullscreen-menu-results.json). |

Po změně čtecího režimu proběhla také samostatná kontrola skutečného `DiaryDate.swift` v 12 případech kolem půlnoci v Europe/Prague; 12/12 uspělo. Není to dalších 12 metod v současné Xcode sadě ani end-to-end čekání na skutečnou půlnoc.

Při ukončování aplikace v testech se v některých logách objevilo `killed` / kód 9. Rozhodující je stav konkrétního testu a případná failure summary; tento záznam sám neznamená selhání assertions.

### Ověření ikonky a komentářů

Sestavení **Debug i Release uspělo** na iPhone 17 / iOS 27.0. Release konfigurace je potvrzená build logem. V obou výsledných balíčcích je nová ikonka AppIcon, zobrazovaný název The Tom Diary, původní bundle ID a verze 1.0.0 / build 1; iPhone orientace zůstává portrait.

Znovu prošel `testMenuStatsAndDeveloperToolsResetOnRelaunch` (1 test, 0 selhání, 51,468 s). Zdroj je `Test-The Tom Didary-2026.10.11_17-51-23-+0200.xcresult`. Neopakovali jsme celou sadu 30 testů: runtime změna je ikonka a zobrazovaný název, ostatní změny jsou komentáře a dokumentace.

Porovnání Swift tokenů všech 20 souborů proti záloze potvrdilo nezměněnou logiku. Ikonka má 1024 × 1024 a žádný alpha kanál; místní Markdown odkazy, JSONy a syntaxe projektu prošly kontrolou. Matice výše odpovídá všem 30 metodám nalezeným ve zdrojích.

Podklady: [souhrn nové verze](TestResults/v1-verification.json), [UI výsledek](TestResults/v1-icon-ui-results.json), [statické kontroly](TestResults/v1-static-checks.json) a [nový snímek menu](Assets/menu-v1-2026-10-11.png). Fyzické doručení notifikace a vzhled ikonky byly později potvrzeny uživatelem 12. 10.; viz poslední část níže.

## Fyzické testování

Uživatel již na svém iPhonu potvrdil funkční ukládání. Z jeho testů vzniklo odstranění tlačítka Hotovo a nové čtení/úprava dnešní odpovědi. Později upřesnil podobu menu. Fotografie ukázaly čitelný text a emoji konkrétní otázky; nenahrazuje to kontrolu každého emoji.

Uživatel 12. 10. uvedl, že aplikace na telefonu vypadá dobře a funguje, a po restartu potvrdil správnou ikonu oznámení. První osobní verzi tím schválil pro GitHub. Následující postup slouží k opakování ručních kontrol při dalších úpravách; jednotlivé body nemají samostatný protokol uživatelova měření:

1. Aktualizovat existující instalaci a zkontrolovat, že dřívější odpověď zůstala, zobrazí se ikonka a verze v1.0.0.
2. Otevřít/zavřít celostránkové menu, posunout jeho obsah a zkontrolovat vzhled skla v osobním nastavení světlého/tmavého režimu.
3. Zapnout notifikaci pár minut dopředu, uložit, odejít na plochu/uzamknout telefon a ověřit doručení, nadpis, text a zvuk. Poté vyzkoušet jiný čas a vypnutí; zaznamenat i stav oprávnění či Focus režimu, pokud se oznámení neukáže.
4. Pokud se skutečně přejde přes půlnoc, ověřit návrat následující den a nemožnost přepsání včerejší odpovědi. Automatické scénáře čas simuluje aplikace, ne celý telefon.

## Co sada zatím nedokazuje

Není ověřené obnovení na novém fyzickém iPhonu ani skutečný přenos přes iCloud. Export/import JSON nyní ověřují datové testy a místní souborový picker. Další mezery jsou multi-device synchronizace, zátěž mnoha let zápisů, všechny kombinace časových pásem a ruční změny hodin, chování při nedostatku místa nebo poškozené databázi, kompletní ovládání VoiceOverem a odeslání do App Store. Samostatné UI pro Mac, iPad, visionOS a widget nejsou součástí ověřené první verze.

Tyto oblasti jsou další možné kroky, nikoli tvrzení o hotových funkcích.

## Ověření posledních úprav — 12. 10. 2026

Uživatel potvrdil doručení připomínky na svém iPhonu; oprava se týká loga oznámení a nadpisu hlavní stránky. Změna nezasahuje do SwiftData modelu, ukládání ani bundle ID. Debug i Release pro fyzický iPhone prošly bez chyb; konfigurace potvrzené v build logu. V obou zkompilovaných Assets.car je ikona oznámení 60 × 60 (@3x) a další malé velikosti. Debug pro simulátor také uspěl.

Znovu prošel `testSaveEditRelaunchAndBackground` (1 test, 0 selhání, 56,725 s), tedy zápis, úprava, restart a uložení na pozadí. Celá sada 30 testů se pro tuto malou změnu neopakovala. Nový nadpis je na snímku skutečného simulátoru celý, bez zkrácení.

Podklady: [souhrn](TestResults/v1-final-fixes-2026-10-12.json), [UI výsledek](TestResults/v1-final-fixes-ui-2026-10-12.json) a [náhled](Assets/rocni-zapisnik-2026-10-12.png). Uživatel následně potvrdil správné logo na skutečném telefonu po jeho restartu.

Ruční kontrola běžné instalace simulátoru navíc ověřila skutečné doručení lokální připomínky ve 16:46 při aplikaci na pozadí. V centru oznámení bylo správné logo deníku, nadpis i obsah. Test byl ve světlém vzhledu iPhone 17 / iOS 27.0; nenahrazuje ověření na uživatelově fyzickém telefonu. [Snímek doručené notifikace](Assets/notifikace-logo-2026-10-12.png). Nastavení simulátoru se po kontrole vrátilo na vypnutou připomínku ve 20:00.

Poslední fyzické potvrzení pochází přímo od uživatele: po aktualizaci zůstávala stará ikona, restart iPhonu ji opravil. Jde o ruční výsledek, nikoli další automatický test. Pro přípravu GitHubu se měnila pouze dokumentace a sledování souborů Gitem; funkční kód se znovu neměnil.

## Rozšíření 1.1.0 — 13. 10. 2026

Přibylo 7 metod `BackupTests`, 3 metody `SigningReminderTests` a UI scénář `testAutomaticBackupStatusAndSigningMenuSurviveRelaunch`. Zdrojová sada má nyní 41 metod: 30 datových / jednotkových včetně prázdné šablony a 11 UI. Nové případy popisuje [Zálohování a podpis](backup-and-signing.md#ověřování).

Na Macu skutečně prošlo všech 30 jednotkových testů, 0 selhání, v 6 sadách. Zdroj výsledku je `Test-The Tom Diary Unit Tests-2026.10.13_20-57-13-+0200.xcresult`. XML payload existujícího fyzicky podepsaného Debug i Release balíčku obsahoval čitelné ExpirationDate a vývojové oprávnění. To není test doručení připomínky.

První simulátorové běhy se zastavily při připojování testovacího procesu; nový iPhone 17e také hlásil timeout obrazovky. Xcode při ukončování oznámil chybu LLDB RPC serveru. Pozdější sestavení narazilo na `Resource temporarily unavailable` při spouštění swift-frontend. Tyto pokusy nejsou úspěšné testy. Sdílená schémata vypínají paralelní klony; pro dokončení ověřování se také vypnul debugger testů. Běžný Run má debugger nadále zapnutý.

Ruční ověření na telefonu: aktualizace původní instalace bez smazání odpovědí; výběr soukromé složky iCloud Drive; obsah JSON po zápisu i úpravě; předchozí kopie; přenos do cloudu a stažení na jiném zařízení; obnova v prázdném testovacím deníku; odebrání přístupu ke složce a opakování; datum expirace v menu a skutečné doručení oznámení. Osobní data při testování nemaž.

Na iPhone 17 / iOS 27.0 měl úplný běh ve 21:06 výsledek 40/41. Nový UI scénář narazil na odkaz obnovy mimo viditelnou část Form. Sekce obnovy se přesunula před delší vysvětlení a test nyní v případě potřeby posouvá obsah. Opakování dotčeného scénáře ve 21:18 prošlo: 1 test, 0 selhání, 45,436 s. Všech 41 metod má konečný úspěšný výsledek napříč těmito dvěma běhy; nejde o druhý úplný běh. [Strojový souhrn](TestResults/backup-signing-2026-10-13.json).

Ruční kontrola běžné simulátorové instalace ve 21:30–21:32 prošla systémovým výběrem místní složky, vytvořením souboru, jeho následným výběrem k obnově, potvrzením a výsledkem dokončené obnovy. Deník byl prázdný; doplnění skutečných odpovědí a zachování existujících záznamů pokrývají datové testy. Tento krok nepoužíval iCloud účet ani osobní data.

Po ručním odemčení Macu a potvrzení Klíčenky uživatelem dokončil fyzický Debug build podpis ve 21:43. Release build následně uspěl ve 21:45. Oba výsledné balíčky mají verzi 1.1.0, původní bundle ID a čitelný vývojový profil; build protokoly potvrzují 0 chyb a 7 upozornění. Upozornění se týkají existující definice App Store ikony, orientace iPadu a chybějícího AppIntents.framework; nejsou to selhání zálohování. Xcode se vrátil na schéma The Tom Diary / Debug / fyzický iPhone. Proběhlo pouze sestavení; aktualizaci telefonu a skutečný iCloud přenos uživatel provede ručně. Nezávislá kontrola nových souborů nenašla závažnou chybu způsobující ztrátu dat.
