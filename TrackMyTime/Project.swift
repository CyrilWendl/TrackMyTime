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
    var details: String?

    init(id: UUID = UUID(), name: String, details: String? = nil) {
        self.id = id
        self.name = name
        self.details = details
    }
}
