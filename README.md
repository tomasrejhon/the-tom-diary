# The Tom Diary

Osobní deník pro iPhone: každý den jedna otázka, vlastní odpověď a vzpomínky na stejný den minulých let. Aplikace je česky, funguje offline a ukládá odpovědi lokálně pomocí SwiftData.

Hlavní stránka má nadpis **Roční zápisník otázek**. Zdrojový projekt a jeho další vývoj jsou v soukromém repozitáři [tomasrejhon/the-tom-diary](https://github.com/tomasrejhon/the-tom-diary). Výchozí funkční verze je označená značkou `v1.0.0`.

**Verze 1.0.0, build 1.** Aktuální technická dokumentace zachycuje stav z 12. října 2026. První verze je určená především pro osobní používání na iPhonu. iCloud synchronizace, export/import, widget a samostatně doladěná verze pro Mac jsou další etapy.

## Spuštění

1. Otevři `The Tom Didary.xcodeproj` v Xcode. Původní překlep v názvu projektu zůstal kvůli stabilitě cest a identity; na ploše iPhonu se aplikace jmenuje **The Tom Diary**.
2. Vyber schéma **The Tom Didary** a iPhone simulátor. Ověřená konfigurace je Xcode 27 a iPhone 17 / iOS 27.0; minimální iOS projektu je 26.2.
3. Spusť **⌘R**. Testy spustíš **⌘U**. Pro fyzický telefon nastav svůj Team v **Signing & Capabilities**.

Podrobný postup, včetně aktualizace existující instalace na telefonu, je v [průvodci vývojem](Documentation/development.md).

## Co aplikace dělá

- Obsahuje 366 vestavěných otázek včetně 29. února; za každou je samostatně uložené emoji.
- Odpověď lze během jejího dne uložit i upravit. Po uložení se místo editoru zobrazí čtecí karta s odkazem na úpravu. Starší dny jsou pouze ke čtení.
- Odpovědi ze stejného dne a měsíce v minulých letech se zobrazují přímo pod dnešní otázkou, od nejnovějšího roku.
- Celostránkové menu se skleněným pozadím obsahuje letošní počet, později i celkový počet, roční přehled a aktuální počet dnů v řadě.
- Lze nastavit každodenní lokální oznámení s vlastním časem, nadpisem a textem.
- iPhone zůstává na výšku. Dlouhé odpovědi se ve stránce posouvají.
- Pět navazujících klepnutí na verzi v menu odkryje dočasné testovací nastavení. Po úplném ukončení se opět skryje.

## Dokumentace

Začni [rozcestníkem dokumentace](Documentation/README.md). Obsahuje:

| Dokument | K čemu slouží |
| --- | --- |
| [Architektura a mapa souborů](Documentation/architecture.md) | Co dělá každý soubor, jak spolupracují jednotlivé části a co znamenají Swift anotace. |
| [Data a pravidla deníku](Documentation/data.md) | Otázky, odpovědi, lokální ukládání, půlnoc, historie, statistiky a oznámení. |
| [Průvodce vývojem](Documentation/development.md) | Spuštění, instalace na iPhone, testovací režim a běžné úpravy. |
| [Testy a výsledky](Documentation/testing.md) | Úplný seznam automatických testů, provedené běhy a zbývající fyzické ověření. |
| [Historie vývoje](Documentation/development-history.md) | Jak vznikaly funkce a proč jsme upravovali jednotlivá rozhodnutí. |
| [Ikonka](Documentation/icon.md) | Originál, připravený asset, způsob úpravy a výměna v Xcode. |
| [Další vývoj a Git](Documentation/roadmap.md) | Dokončená osobní v1, další etapy a verzování projektu. |

Komentáře přímo ve Swift souborech jsou česky. Vysvětlují hlavně odpovědnost typů, rozdíl mezi rozepsaným a uloženým textem, datumové hranice a ochranu dat při chybě.

## Stav dat a ověření

**Odpovědi zatím nejsou synchronizované do cloudu.** Git ukládá zdrojový kód, nikoli osobní zápisy z telefonu. Při aktualizaci používej existující instalaci; odinstalování smaže její lokální data. Přenos na nový telefon přes vlastní synchronizaci aplikace ještě není implementovaný.

Před přidáním ikonky a dokumentace mělo všech **30 různých testů** konečný úspěšný výsledek napříč doloženými běhy; zahrnuje to jeden prázdný test šablony. Po úpravě menu na celou obrazovku znovu prošel odpovídající UI scénář. Po přidání ikonky a komentářů uspělo sestavení Debug/Release a znovu prošel UI scénář menu. Přesné meze a aktuální ověření této změny jsou v [testovací dokumentaci](Documentation/testing.md).

Základní ukládání bylo vyzkoušené i na skutečném iPhonu. Uživatel 12. října potvrdil funkční aplikaci, doručení notifikace a po restartu telefonu také správné logo oznámení. Doručení se správným logem prošlo i ručně v simulátoru. Podrobnosti a meze ověření jsou v [testovací dokumentaci](Documentation/testing.md).
