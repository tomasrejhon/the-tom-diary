# Průvodce vývojem

## První otevření projektu

Otevři soubor `The Tom Didary.xcodeproj`, ne samostatný Swift soubor. Samostatně otevřený soubor může mít vlastní okno bez targetu, testovacího plánu a správného zařízení. Ověř název projektu v horní liště Xcode.

Vyber schéma **The Tom Didary** a iPhone simulátor, v ověřeném prostředí **iPhone 17 / iOS 27.0**. Použité Xcode je 27; projekt vznikl v Xcode 26.3. Minimální podporované iOS v projektu je **26.2**, ale kompatibilita aktuálního kódu nebyla zvlášť ověřena na každém podporovaném runtime. Jazyková konfigurace je Swift 5.0 a hlavní target používá výchozí izolaci MainActor.

Projekt má tři targety: aplikaci, `The Tom DidaryTests` a `The Tom DidaryUITests`. Nemá externí balíčky ani server, který by bylo nutné spouštět. Xcode přebírá Swift soubory a zdroje ze synchronizovaných projektových složek.

| Akce | Zkratka / nabídka |
| --- | --- |
| Sestavit | ⌘B |
| Spustit | ⌘R |
| Zastavit | ⌘. |
| Spustit testy schématu | ⌘U |
| Vybrat konkrétní test | Test Navigator, kontextová nabídka Run |
| Sestavit Release bez spuštění Instruments | Product → Build For → Profiling při standardním nastavení Profile akce |

Sestavení v konfiguraci Release vždy ověř podle build logu či konfigurace schématu. Pouhý název nabídky není důkaz, že se použil Release. Aktuální referenční sestavení tuto konfiguraci v logu ověřovalo.

## Instalace na skutečný iPhone

1. Připoj iPhone a potvrď důvěru počítači, pokud ji systém vyžádá.
2. V projektu vyber hlavní target → **Signing & Capabilities** → **Automatically manage signing**, poté svůj účet/Team.
3. Jako Run Destination vyber svůj iPhone a spusť ⌘R. Případné systémové kroky pro Developer Mode či důvěru vývojáři dokonči podle pokynů Xcode a iPhonu.
4. Po spuštění lze kabel odpojit a používat nainstalovanou aplikaci samostatně.

Pro další aktualizace používej stejnou identitu aplikace a aktualizuj existující instalaci. Původní bundle ID je `My.The-Tom-Didary`; název na ploše je zvlášť `The Tom Diary`. Přejmenování viditelného názvu nepřejmenovává databázi ani bundle ID. Změna bundle ID by vytvořila jinou aplikaci s vlastním datovým prostorem. Aplikaci s osobními odpověďmi před aktualizací neodinstalovávej.

Když `codesign` chce přístup ke klíči v přihlašovací klíčence Macu, jde o heslo této klíčenky, obvykle přihlašovací heslo Macu. Je to jiný dialog než přihlášení Apple účtu.

## Skryté testovací nastavení

Otevři menu a klepni **pětkrát za sebou na verzi v1.0.0**. Pauza mezi dvěma klepnutími nesmí být větší než dvě sekundy. Objeví se položka Testovací nastavení. Obsahuje ruční datum, textové zadání RRRR-MM-DD, návrat na skutečný dnešek a přepínač ukázek minulých let.

Odemčení, ručně prohlížený den a ukázky vydrží po dobu aktuálního běhu aplikace. Přechod na plochu je neresetuje; úplné ukončení a nové spuštění ano. Funkce je dostupná také v Release, ale bez odemčení není vidět.

**Ruční výběr dne neumožní zapisovat do minulosti ani budoucnosti.** Jen změní zobrazení. Aktuální rok statistik se také neposune. V běžném fyzickém testu se tedy nemění systémový čas a nenaplňuje se několik minulých let přes skryté prohlížení.

## Automatické testy a simulované hodiny

Debug UI scénáře předávají aplikaci:

| Argument | Účel |
| --- | --- |
| `--diary-test-store UUID` | Vlastní trvalý soubor databáze v dočasné složce a vlastní UserDefaults suite. Platné UUID je podmínkou simulovaných hodin. |
| `--diary-test-date RRRR-MM-DD` | Úvodní den k prohlížení. |
| `--diary-clock-date RRRR-MM-DD` | Simulované aktuální datum; funguje pouze s izolovaným úložištěm. |
| `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` | Největší přístupnostní písmo ve scénáři dlouhé historie. |

Starý argument `--diary-hide-samples` zůstal v pomocné metodě UI testů, ale aplikace ho už nečte: ukázky jsou nyní vypnuté automaticky. Není to podmínka izolace ani současné veřejné nastavení.

Pokud má izolovaný test aktivní simulovaný čas, v testovacím formuláři se objeví tlačítko **Posunout testovací čas o den**. V běžné aplikaci ani Release není. Tyto testy simuluje aplikace; nepřestavují hodiny systému.

V `DiaryDate.swift` existuje i Debug konstanta `testDate`. Standardně je `nil`; změna například na `"2024-02-29"` mění jen úvodní prohlížené datum. Před běžným používáním ji vrať na `nil`. Pro deterministický zápis k historickému dni používej izolovaný automatický scénář, nikoli ruční posun data na osobním telefonu.

## Kam sáhnout při změně

| Chci změnit… | Začnu zde |
| --- | --- |
| Otázku nebo její emoji | JSON v Resources; poté `bundledQuestionsCoverEveryCalendarDay`. |
| Vzhled dnešní stránky / karet | `ContentView.swift`; ověřit dlouhý text, klávesnici a velké písmo. |
| Obsah menu | `DiarySidebar.swift`; jeho rozměry a glass overlay jsou v ContentView. |
| Barvy ročního přehledu | `YearActivityView.swift`; stavy dnů neměnit ve view. |
| Počty / sérii / výročí | `DiaryStatistics.swift` a jeho testy. |
| Pravidla ukládání | `AnswerStore.swift` a `DiaryDate.swift`; zachovat kontrolu i před zápisem do databáze. |
| Oznámení | `NotificationManager.swift`, `ReminderSettingsView.swift` a `ReminderTests`. |
| Intro při spuštění | `DiaryRootView.swift`: délka je v `Task.sleep`, prolnutí ve `withAnimation`. Podklad je `DiaryLaunchArtwork.imageset`; po návratu z pozadí se intro neopakuje. |
| Ikonku | `Assets.xcassets/AppIcon.appiconset`; viz [návod](icon.md). |
| Verzi | MARKETING_VERSION hlavního targetu v Debug i Release. Číslo buildu je CURRENT_PROJECT_VERSION. |

## Postup při další úpravě

Nejdříve ujasni pravidlo a postižené soubory, potom uprav kód. Pro změnu logiky spusť související jednotkové testy; pro změnu ovládání odpovídající UI scénář. Před vydáním zkontroluj sestavení Debug/Release a potřebný fyzický scénář. U malé úpravy komentářů není nutné přidávat test, který jen kopíruje implementaci.

Chybu popiš tak, aby šla zopakovat: zařízení a iOS, verze aplikace, datum v aplikaci, kroky, očekávaný a skutečný výsledek, případně snímek. Více chyb může být v jedné zprávě, ale každá má vlastní číslo a postup. Je užitečné uvést, zda šlo o běžný režim nebo odemčené testovací nastavení.

## Sdílená schémata od verze 1.1.0

`The Tom Diary` obsahuje aplikaci a obě testovací sady. `The Tom Diary Unit Tests` spouští pouze jednotkové / datové testy. Obě schémata jsou v repozitáři a vypínají paralelní klony simulátorů. Host testů má samostatné UUID úložiště; UI scénáře navíc nastavují vlastní UUID při každém spuštění testovacího případu. Původní automaticky vytvořené schéma `The Tom Didary` může na stávajícím počítači zůstat viditelné. Pro běžnou instalaci vyber nové plné schéma, fyzický telefon a Run; argument izolovaného úložiště je pouze v TestAction, ne v LaunchAction.
