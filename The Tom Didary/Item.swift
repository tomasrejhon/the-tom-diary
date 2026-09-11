//
//  Item.swift
//  The Tom Didary
//
//  Created by Tomáš Rejhon on 10.09.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
