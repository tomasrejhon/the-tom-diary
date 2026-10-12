# Dokumentace The Tom Diary 1.0.0

Tato dokumentace vysvětluje současný kód i postup vývoje. Je psaná pro návrat k projektu po delší době a pro postupné porozumění SwiftUI. Popisuje stav k 12. 10. 2026; historické výsledky mají uvedený vlastní den a prostředí.

## Doporučené pořadí čtení

1. [README projektu](../README.md): účel aplikace a rychlé spuštění.
2. [Architektura](architecture.md): mapa všech souborů a tok dat.
3. [Data](data.md): pravidla, která nesmí při dalších úpravách zmizet.
4. [Vývoj](development.md): jak aplikaci spouštět, měnit a bezpečně testovat.
5. [Testy](testing.md): co skutečně ověřujeme a které výsledky pocházejí ze starší verze.
6. [Historie](development-history.md): vývojová rozhodnutí v souvislostech.
7. [Ikonka](icon.md) a [další vývoj](roadmap.md).

## Jak dokumentaci udržovat

Při nové funkci uprav její pravidla v `data.md`, mapu souborů při přidání či přejmenování a příslušné testy v `testing.md`. Výsledek ověření musí obsahovat datum, zařízení/runtime, skutečný rozsah a výsledek; úspěšné sestavení není totéž jako test funkce nebo doručení notifikace.

Do historie přidávej dokončené rozhodnutí a jeho důvod. Při vydání změň `MARKETING_VERSION` v obou konfiguracích hlavního targetu; číslo v menu se načítá automaticky. `CURRENT_PROJECT_VERSION` je samostatné číslo sestavení.

## Podklady

- `Assets/` obsahuje originální ikonku, její čtvercový podklad a skutečné náhledy ze simulátoru. Odpovědi v náhledech jsou umělé testovací texty.
- `TestResults/` obsahuje malé přehledy zaznamenaných výsledků. Velké `.xcresult` balíčky a build produkty se do repozitáře nepřidávají.
- `///` před typem nebo metodou v kódu je dokumentační komentář, který Xcode zobrazí také v Quick Help. `//` vysvětluje konkrétní krok nebo důvod uvnitř implementace.

Dokumentace není úplný přepis chatů. Zachovává doložená rozhodnutí, aktuální implementaci a výsledky. Pokud se dřívější popis liší od současného chování, platí současný kód a kapitola [Data](data.md).
