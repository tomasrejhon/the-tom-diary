# Automatická záloha a platnost instalace — verze 1.1.0

## Nastavení

V celostránkovém menu otevři **Záloha a obnova → Vybrat složku zálohy**. Systém Soubory udělí aplikaci přístup pouze k vybrané složce. Pro ochranu před ztrátou telefonu zvol soukromou složku v **iCloud Drive**; místní složka na telefonu takovou ochranu neposkytuje. CloudKit a placené Apple Developer členství se pro tento způsob souborového zálohování nepoužívají.

Po výběru proběhne první záloha všech současných odpovědí. Pokud zápis selže, fungující předchozí nastavení se nemění. Aplikace si ukládá oprávnění jako bookmark, nikoli obyčejnou cestu. Pokud složku odstraníš nebo odebereš přístup, je třeba ji znovu vybrat.

## Soubor a potvrzení

V podadresáři `The Tom Diary Backups` vzniká `diary-backup.json`. Po změně deníku uchováme původní platnou verzi v `diary-backup-previous.json`. Soubor obsahuje značku formátu `TheTomDiary`, verzi 1, identitu deníku, čas snapshotu a všechny odpovědi jako kalendářní klíč `RRRR-MM-DD` a text. Obsah je čitelný JSON bez šifrování aplikací; nesdílej složku s jinými lidmi, pokud jim nechceš zpřístupnit deník.

Nová / upravená odpověď nejprve projde stávajícím lokálním uložením SwiftData. Potom `BackupManager` vytvoří snapshot skutečných modelů a `BackupFileWorker` na samostatném aktoru provede koordinovaný atomický zápis. Ukázky, rozepsaný editor a testovací datum se neexportují jako odpovědi.

Malý text pod uloženou odpovědí ukazuje průběh nebo **Záložní soubor aktualizován**. Menu obsahuje stav a čas posledního úspěšného zápisu. Tento stav potvrzuje zápis do vybrané složky, nikoli přijetí dat vzdáleným cloudovým serverem. Poskytovatel iCloud Drive / Soubory spravuje následný přenos a jeho případné odložení bez internetu. Soubor musí před ztrátou telefonu skutečně dojít do cloudu, aby byl na novém zařízení dostupný.

Rychlé změny se zpracují sériově; čekající snapshot nahradí nejnovější. Chyba zálohy nikdy nevrací úspěšně uloženou odpověď zpět. Po návratu do aplikace se soubor znovu ověří; po chybě se zápis opakuje i při periodické kontrole během běhu nebo tlačítkem **Aktualizovat zálohu teď**. Ukončená aplikace negarantuje práci na pozadí: po přerušení se stav znovu sestaví z databáze při spuštění.

Nezměněný obsah nerotuje předchozí kopii ani neposouvá čas úspěšné zálohy. Cizí identita deníku nebo nečitelný existující soubor zápis zastaví; původní soubor se zachová. Vypnutí automatické zálohy odpojí oprávnění v nastavení, ale nemaže soubory ani odpovědi.

## Obnova na novém iPhonu

1. Nainstaluj stejnou aplikaci a přihlas telefon ke svému iCloud účtu.
2. V menu otevři **Záloha a obnova → Obnovit ze záložního souboru**.
3. Vyber aktuální JSON, případně předchozí kopii. Aplikace nejprve ověří formát, velikost a data.
4. Potvrď **Doplnit chybějící odpovědi**. Současné odpovědi se nepřepisují; obnova je opakovatelná bez duplicit.
5. Na prázdném telefonu aplikace převezme identitu obnoveného deníku. Následně vyber původní cloudovou složku pro další automatické zápisy.

Obnova je samostatná datová operace a nepovoluje editaci minulých dnů v běžném editoru. Nepodporovaná verze, neplatné datum, prázdný text a opakované dny se odmítnou před změnou databáze. Limit je 10 MB a 20 000 odpovědí. Chyba uložení odstraní pouze nově vkládané modely.

## Připomínka podpisu

`SigningProfile` čte `ExpirationDate` a UUID z XML payloadu souboru `embedded.mobileprovision` uvnitř podepsané aplikace. Zpracovává vývojové profily (`get-task-allow`); informace se nepoužívá k ověření kryptografické platnosti podpisu. Neodvozuje datum od instalace, prvního spuštění ani verze aplikace. Chybějící / nečitelný profil neznamená odhad dalších sedmi dní. Na simulátoru menu uvádí, že podpis nevyprší.

Menu zobrazuje datum i čas konce instalace a přepínač připomínky. Je přednastavená jako zapnutá, ale bez systémového povolení aplikace oznámení nenaplánuje ani při startu nevyvolá překvapivý dialog. Tlačítkem **Povolit oznámení** nebo přepnutím připomínky ze stavu vypnuto na zapnuto lze o oprávnění požádat. Existující povolení denní připomínky se použije také zde.

Lokální požadavek s vlastním ID `diary-signing-expiration` se plánuje 24 hodin před expirací. Při prvním otevření v posledních 24 hodinách přijde za minutu, pokud stále zbývá více než minuta platnosti. Po expiraci ani v posledních 60 sekundách se neplánuje. Změna skutečného profilu nahradí starý termín; stejné spuštění jej neposouvá a doručené oznámení se při každém otevření neopakuje. Vypnutí odstraní pouze tuto připomínku, nikoli denní oznámení.

Vypršení profilu neodinstaluje aplikaci a nemaže databázi. Přestane jít otevřít, dokud ji znovu nenahraješ s platným podpisem. Zachovej stejný bundle ID, Team a původní instalaci; aplikaci kvůli obnově neodinstalovávej.

## Ověřování

Nové testy ověřují JSON roundtrip, validaci poškozených a nepodporovaných záloh, obnova bez přepsání existujícího dne, rotaci předchozí kopie, odmítnutí cizího / poškozeného cíle, přetrvání nastavení, skutečný soubor po úpravě odpovědi, chybu zápisu a opakování. Testy podpisu ověřují čtení metadat, čas 24 hodin před skutečnou expirací, pozdní spuštění a zákaz minulého termínu. UI scénář používá izolovaný adresář a testovací profil; nesahá do osobní cloudové složky a neplánuje oznámení podpisu.

Doručení na skutečném telefonu a cesta přes skutečný iCloud Drive vyžadují ruční ověření uživatele. Úspěšný simulátorový zápis je nenahrazuje. Výsledky běhů a jejich rozsah jsou v [Testování](testing.md).

## Soubory

- `DiaryBackup.swift`: verze formátu, validace, snapshot a bezpečné sloučení do SwiftData.
- `BackupFileWorker.swift`: bookmarky, koordinované čtení/zápis, předchozí kopie.
- `BackupManager.swift`: nastavení, pozorovatelný stav, fronta snapshotů, opakování.
- `BackupSettingsView.swift`: systémový výběr složky / souboru a potvrzení obnovy.
- `SigningReminder.swift`: metadata profilu a lokální připomínka expirace.
- `DiaryPreferences.swift`: společné oddělení UserDefaults pro izolované UI testy.

Technické zdroje: [Apple — výběr složky a bookmarky](https://developer.apple.com/documentation/uikit/providing-access-to-directories), [Apple — profil podpisu](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles), [Apple — lokální oznámení](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app).
