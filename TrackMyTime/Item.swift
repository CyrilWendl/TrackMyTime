//
//  Item.swift
//  TrackMyTime
//
//  Created by Cyril Wendl on 19.01.2026.
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
