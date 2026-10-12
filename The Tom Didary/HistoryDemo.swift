import SwiftUI

/// Čtyři dlouhé ukázky historie pro vizuální kontrolu. Vracejí pouze HistoryEntry,
/// nikdy model Answer. Zobrazí se jen po odemčení nástrojů, zapnutí ukázek a bez
/// vlastní historie. V nepřestupném roce nevytvoří neexistující 29. únor.
enum HistoryDemo {
    static func answers(for date: Date) -> [HistoryEntry] {
        let c = DiaryDate.components(date)
        let examples = [
            "Dnes by mi nejvíc pomohla dlouhá procházka bez telefonu a bez plánu. Poslední týden jsem měl hlavu plnou práce a skoro jsem si nevšiml, že už začíná podzim. Rád bych se zastavil v malé kavárně, dal si něco dobrého a jen chvíli pozoroval lidi kolem sebe. Večer bych chtěl zavolat někomu blízkému a probrat i něco jiného než povinnosti. Myslím, že právě takový obyčejný den by mi teď udělal největší radost.",
            "Náladu by mi zlepšilo, kdybych konečně dokončil věc, kterou už několik dní odkládám. Nejde ani tak o její náročnost, spíš ji pořád nosím v hlavě a bere mi energii. Potom bych si rád pustil oblíbené album a uvařil večeři, na kterou si obvykle neudělám čas. Chtěl bych mít na konci dne pocit, že jsem něco posunul a zároveň si dovolil odpočinout. Dnes nepotřebuji velký úspěch, stačí mi malý krok a trochu klidu.",
            "Nejraději bych dnes strávil odpoledne s přáteli, které jsem dlouho neviděl. Chybí mi naše rozhovory, společný smích i to, že před nimi nemusím nic předstírat. Mohli bychom vyrazit na krátký výlet a cestou se zastavit na dobré jídlo. Uvědomuji si, že když mám horší náladu, často se uzavřu do sebe, přestože mi společnost nakonec pomůže. Zkusím tentokrát udělat první krok a někomu napsat.",
            "Dnes by mi udělalo dobře trochu zpomalit a přestat se porovnávat s ostatními. Mám za sebou náročné období a občas zapomínám ocenit, co už se mi povedlo. Pomohlo by mi uklidit si pracovní stůl, otevřít okno a dát si hodinu jen pro sebe. Večer bych si rád přečetl pár kapitol knihy, která na mě čeká už celé léto. Chci si připomenout, že odpočinek nemusím nejdřív zasloužit."
        ]
        return examples.enumerated().compactMap { index, text in
            let year = c.year! - index - 1
            guard DiaryDate.parse(String(format: "%04d-%02d-%02d", year, c.month!, c.day!)) != nil else { return nil }
            return HistoryEntry(year: year, text: text)
        }
    }
}
