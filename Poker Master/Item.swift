//
//  Item.swift
//  Poker Master
//
//  Created by Ned Whittleton on 4/11/24.
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
