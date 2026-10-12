import Foundation
import SwiftData

/// Jedna skutečně uložená odpověď deníku. `@Model` umožní SwiftData sledovat změny
/// vlastností a ukládat tento objekt do databáze aplikace.
///
/// Den, měsíc a rok tvoří logickou identitu záznamu. `AnswerStore` při úpravě vyhledá
/// existující den; v samotném schématu zatím není databázové omezení jedinečnosti.
@Model
final class Answer {
    // Samostatné kalendářní hodnoty zachovávají přiřazení odpovědi k původnímu dni
    // i po změně časového pásma. Podle dne a měsíce se hledají odpovědi z minulých let.
    var day: Int
    var month: Int
    var year: Int

    // Datum přiřazené odpovědi, nikoli čas poslední úpravy. Při úpravě se nepřepisuje.
    var date: Date
    var text: String

    init(day: Int, month: Int, year: Int, date: Date, text: String) {
        self.day = day
        self.month = month
        self.year = year
        self.date = date
        self.text = text
    }
}
