# Historie vývoje a rozhodnutí

Tento přehled zachycuje doložené milníky z požadavků, kódu a výsledků. Nejde o doslovný přepis chatů ani zpětně vytvořenou historii Git commitů. Současná pravidla popisuje [Data](data.md); některé starší varianty už neplatí.

## Začátek projektu — září 2026

Projekt vyšel ze šablony SwiftUI/SwiftData vytvořené 10. 9. 2026. Původní název obsahuje překlep **The Tom Didary**. Ve zdrojových cestách a bundle ID zůstává, aby se při dokončování první verze zbytečně neměnila identita existující instalace. Uživatel od začátku chtěl především **iPhone**; Mac měl přijít později.

Základní myšlenka: jedna otázka pro každý kalendářní den, zapsaná odpověď a možnost za několik let číst, jak se odpověď na stejné zadání proměnila. Widget byl vědomě odložen, dokud nebude fungovat hlavní aplikace. Otázky a ukládání jsme oddělili od obrazovky, aby pozdější rozšíření nebylo závislé na kopírování celé hlavní stránky.

## Otázky, emoji a lokální ukládání

Do balíčku aplikace se připojil JSON otázek. Původní texty se zachovaly, přibyla otázka pro 29. února a emoji podle tématu. Emoji je samostatné pole, takže uživatel může výběr revidovat bez úpravy znění otázky. Katalog má 366 položek a kontrolu úplnosti.

Zvolilo se lokální SwiftData úložiště: jednoduché osobní používání bez serveru a bez internetu. Druhé uložení stejného dne upraví odpověď místo přidání další. Prázdný vstup nesmí smazat dříve uloženou hodnotu. Otázky se vybírají podle dne/měsíce, historie podle dne/měsíce a menšího roku.

Uživatel otevřel téma nového telefonu a více zařízení. iCloud/CloudKit byl označen jako další etapa; v1 jej neaktivuje. Otázky mohou zůstat offline v aplikaci, synchronizovat se mají vlastní odpovědi. Záloha/export se má řešit samostatně od živé synchronizace.

Pro rychlé procházení kalendáře vznikl Debug přepis data a později formulář s výběrem i textovým zadáním. V nynější verzi prohlížení jiného dne samo nepovolí historický zápis; skutečný čas je oddělený.

## Historie přímo na hlavní stránce — kolem 15. 9.

Na přání uživatele vznikla ukázka čtyř předchozích let s delšími texty o několika větách. První řešení ji otevíralo ikonou hodin, ale uživatel chtěl minulost vidět hned pod dnešní odpovědí. Historie se přesunula na hlavní stránku do svislého ScrollView; karty nemají pevný počet řádků.

Dočasný SwiftData kontejner původní ukázky se odstranil po zachyceném problému s neplatným slabým odkazem databázového pozorovatele. Pracovní diagnóza ukazovala na životnost tohoto kontejneru, nikoli na potvrzenou obecnou chybu SwiftData. Demo se přepsalo na obyčejné hodnoty `HistoryEntry`, takže neukládá modely ani neovlivňuje skutečný deník.

V tehdejším simulátoru iOS 26.3 se místo některých emoji zobrazovaly čtverečky. Samotné JSON znaky byly správné. Proto se rozlišovala chyba vykreslování prostředí od obsahu aplikace; pozdější fotografie z telefonu ukazují emoji konkrétní otázky.

## Ověření ukládání a historie — 20. 9.

Přibyly UI scénáře pro skutečné ukládání, úpravu, ukončení/nové spuštění, návrat z plochy a čtyři roky dlouhých odpovědí při velkém písmu. UI testy dostaly vlastní trvalé databáze podle UUID, aby nepracovaly s běžnými osobními zápisy.

Při ověřování se opravilo předávání změny dne na hlavní smyčku a zpřísnil se formát testovacího data. Jedno očekávání úpravy textu záviselo na poloze kurzoru; zpřesnilo se ovládání a porovnávání skutečné hodnoty editoru. Konečný úplný běh měl 17 úspěšných spuštěných testů na iPhone 17 / iOS 26.3.

## Pouze na výšku — 23. 9.

Uživatel zvolil iPhone rozhraní pouze na výšku. V Debug i Release se nastavila podporovaná orientace a dosavadní startovací kontrola různých orientací se nahradila testem skutečného zámku okna při otočení telefonu. Nový úplný běh měl 14 úspěšných testů; změnil se rozsah startovacích konfigurací, ne počet vyjádřený jako historická suma všech kontrol.

## První fyzické testy

Uživatel nastavil v Xcode automatické podepisování, dokončil přístup ke klíči v přihlašovací klíčence a nainstaloval aplikaci na svůj iPhone. Potvrdil, že ukládání funguje. Testování se tak rozšířilo ze simulátoru na skutečnou klávesnici a běžné používání bez kabelu.

Z telefonních fotografií vzešly dva konkrétní požadavky: tlačítko **Hotovo** nad klávesnicí rušilo hlavní uložení a po uložení zůstával zbytečně velký editor s tlačítkem.

## Čtecí režim a uzavření dne — 11. 10.

Tlačítko Hotovo se odstranilo. Klávesnici zavře uložení, posun stránky nebo klepnutí na datum. Po úspěšném uložení se editor nahradí odpovědí a sdělením, že dnešek je zaznamenaný. Odkaz nabídne úpravu pouze během stejného dne a předvyplní uložený text.

Pravidlo uzavřeného dne jsme vložili i do ukládací vrstvy. Otevřený editor přes půlnoc nesmí přepsat včerejšek. Neuložená úprava se dočasně nabízí ke zkopírování, zatímco uložený text zůstává. Toto dočasné zachování není trvalá záloha.

Testy byly rozšířeny o zákaz historického/budoucího zápisu a hranici přesné půlnoci. Ve finálním přehledu prošlo 18 různých testů napříč doloženými běhy; po potíži s dostupností ukládání při dlouhém textu se zpřesnilo gesto v okraji stránky a opakoval dotčený scénář.

## Menu, statistiky a oznámení — 11. 10.

Uživatel navrhl hamburger menu místo ikon kalendáře a oznámení. Upřesnil dvě pravidla: zobrazovat **aktuální**, nikoli nejdelší sérii a první rok skrývat jen **celkový**, nikoli letošní počet. Roční přehled má zelené vyplněné, žluté vynechané a šedé budoucí dny.

Vznikly samostatné výpočty a vykreslení roku, formulář vlastního času/nadpisu/textu oznámení a verzová patička. Testovací datum a ukázky se přesunuly za pět klepnutí na verzi; jejich odemčení a volby se po novém spuštění nepamatují.

První úplný běh měl 24 úspěchů a 6 UI selhání. Při opravách se odstranily identifikátory z rodičovských kontejnerů, které se v SwiftUI přenášely na potomky, a zpřesnilo cílení přepínače i kurzoru. Opakované dotčené scénáře doplnily konečný úspěšný výsledek všech 30 různých testů. Datové testy součtů a nastavení prošly; samotné doručení oznámení se tím neověřilo.

První menu mělo podobu zaobleného panelu nad aplikací. Na další přání se změnilo na **celou obrazovku**, se skleněným pozadím až k hranám, vysunutím zleva a zavřením křížkem či tahem. Odpovídající UI scénář znovu prošel a uložil skutečný náhled.

## Ikonka a dokumentace první verze

Uživatel dodal hotový motiv krémového deníku s modrým páskem. Při přípravě pro iOS se doplnilo pozadí do čtvercových rohů a odstranil se vnější bílý okraj; zaoblení necháváme systému. Vznikl neprůhledný asset 1024 × 1024 a originál zůstává uložený vedle podkladu.

Do Swift souborů se doplnily české komentáře k odpovědnosti typů a důležitým rozhodnutím. Vznikla mapa souborů, pravidla dat, průvodce vývojem, úplná matice současných testů, doložená historie výsledků a plán dalších etap. Git už v projektu existuje s původním Initial Commit, ale vzdálený repozitář dosud nebyl připojený.

## Poslední telefonní připomínky — 12. 10.

Uživatel potvrdil funkční aplikaci a doručení notifikace. Požádal o změnu nadpisu hlavní stránky z „Denní deník“ na „Roční zápisník otázek“ a nahlásil náhradní ikonu v oznámení. Nadpis i titulek chybového dialogu se sjednotily; název aplikace The Tom Diary a bundle ID se nemění.

Univerzální podklad ikonky se doplnil o explicitní iPhone/iPad velikosti pro oznámení, nastavení, Spotlight a plochu. Výsledné sestavení pro skutečný iPhone obsahuje konkrétní malou ikonu. Po aktualizaci telefonu zůstala v oznámení stará ikona, ale uživatel následně potvrdil, že restart telefonu problém vyřešil. To podporuje vysvětlení zastaralou systémovou cache; konkrétní interní příčinu jsme neměřili.

Debug i Release pro fyzický iPhone uspěly; cílený UI scénář zápisu, úpravy, restartu a návratu z pozadí znovu prošel. Ruční test v běžném simulátoru ve 16:46 potvrdil skutečné oznámení se správným logem. Náhledy a výsledky jsou uložené v dokumentaci.

## Uzavření osobní v1 a GitHub — 12. 10.

Po potvrzení správné ikonky oznámení na telefonu uživatel schválil uložení projektu na GitHub. Zvolil soukromý repozitář `tomasrejhon/the-tom-diary`. Celý dosavadní funkční vývoj, testy, otázky, ikonka a dokumentace tvoří první souhrnný vývojový commit po původní šabloně; stav má značku `v1.0.0`. Místní nastavení Xcode se přestalo sledovat, soubor na počítači zůstal. Historie starších chatů se nepřepisovala na umělé commity.
