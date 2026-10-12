# Dokončení první verze, další vývoj a Git

## Osobní verze 1.0.0

První verze má denní otázky, trvalé lokální odpovědi, čtecí režim s úpravou pouze dnes, minulé roky na hlavní stránce, celostránkové menu, statistiky, vlastní denní oznámení a skryté testovací nástroje. Ikonka a dokumentace doplňují poslední přípravu.

Uživatel 12. 10. potvrdil funkční aplikaci na svém iPhonu a po restartu také správnou ikonu oznámení. Osobní v1 tím uzavřel a schválil uložení na GitHub. Přesný rozsah automatických a ručních kontrol je v [testování](testing.md); samotné potvrzení běžného používání nedokazuje všechny okrajové situace.

To není stejná etapa jako veřejné vydání v App Store. Projekt zatím nemá doloženou celou distribuční kontrolu ani otestované obnovení dat na novém telefonu.

## Doporučené další etapy

1. **Export a import zálohy.** Definovat čitelný formát s verzí, kalendářním klíčem a textem, kontrolou neplatných dat a pravidlem při importu stejného dne. Výstup může uživatel uložit do svého cloudového úložiště přes systémový výběr souboru. Import se musí testovat mimo osobní databázi, včetně návratu po chybě. Export zálohuje odpovědi, Git nikoli.
2. **Synchronizace více zařízení přes iCloud/CloudKit.** Nastavit capability a kontejner, připravit kompatibilní model a identitu dne, vyřešit stejné datum upravené na více zařízeních a migraci současných lokálních odpovědí. Teprve potom ověřit dva fyzické přístroje, offline zápisy, návrat online, odhlášený účet a obnovu na novém telefonu. Zapnutí jedné capability samo o sobě není dokončená synchronizace. Technická reference: [Apple — synchronizace SwiftData](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices).
3. **Widget.** Navázat na oddělený katalog a datum. Zobrazování samotné otázky nepotřebuje přístup k odpovědím; pokud je bude widget potřebovat, navrhnout sdílené úložiště/App Group a aktualizace. Soukromý text na ploše je samostatné uživatelské rozhodnutí. Widget byl od začátku odložen do této etapy.
4. **Mac/iPad.** Target dnes uvádí také další Apple platformy, ale rozhraní a ověřování se soustředily na iPhone. Před tvrzením o podpoře doladit rozměry, ovládání, ikony a testy každé platformy.
5. **Případné veřejné vydání.** Připravit distribuci, metadata a náhledy, ověřit přístupnost, migraci dat a podporované systémy. Veřejnou dostupnost plánovat jako vlastní úkol.

## Git a výchozí verze

Projekt je uložený v soukromém repozitáři [tomasrejhon/the-tom-diary](https://github.com/tomasrejhon/the-tom-diary), větev `main`. Značka `v1.0.0` označuje tento výchozí funkční stav.

Před uložením v1 existoval pouze původní commit `1dfa5d4` (Initial Commit). Celý dosavadní vývoj se ukládá jako jeden souhrnný commit po této šabloně. [Historie vývoje](development-history.md) vysvětluje starší rozhodnutí; nejsou zpětně rozdělená do umělých Git commitů.

Verzují se projekt, Swift soubory, JSON otázek, assety, testy a dokumentace. `.gitignore` vylučuje databáze deníku, build produkty, velké `.xcresult` balíčky, podepisovací soubory a místní nastavení Xcode. Původně sledovaný `xcuserdata/.../xcschememanagement.plist` se odstranil pouze z Git indexu, na počítači zůstal.

## Další práce s repozitářem

1. Před novou funkcí vytvoř větev, například `feature/icloud-sync`.
2. Po dokončení zkontroluj diff, proveď odpovídající testy a aktualizuj dotčenou dokumentaci.
3. Vytvoř commit se srozumitelným popisem výsledného chování a nahraj větev na GitHub.
4. Po kontrole změn ji sluč do `main`. Další hotové verze označ novými značkami; existující `v1.0.0` neposouvej.

Na novém počítači projekt získáš například takto:

```sh
git clone https://github.com/tomasrejhon/the-tom-diary.git
cd the-tom-diary
open 'The Tom Didary.xcodeproj'
```

Soukromý repozitář vyžaduje přihlášení účtem s přístupem. V Xcode vyber svůj Team pro podepisování. Klonování obnoví zdrojový projekt, osobní odpovědi ze starého telefonu se takto neobnovují.
