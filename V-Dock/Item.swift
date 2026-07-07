//
//  Item.swift
//  V-Dock
//
//  Created by Sajudin on 07/07/26.
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
