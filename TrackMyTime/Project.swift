//
//  Project.swift
//  TrackMyTime
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
