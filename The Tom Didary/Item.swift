//
//  Item.swift
//  The Tom Didary
//
//  Created by Tomáš Rejhon on 10.09.2026.
//

import Foundation
import SwiftData

/// Nepoužitý model z původní šablony Xcode. Není v aktivním Schema aplikace
/// a deník do něj žádné odpovědi neukládá. Ponechán pro přehled původu projektu.
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
