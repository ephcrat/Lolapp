//
//  Item.swift
//  Lolapp
//
//  Created by Alejandro Hernandez on 03/05/2025.
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
