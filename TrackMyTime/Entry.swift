//
//  Entry.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import Foundation
import SwiftData

@Model
final class Entry {
    var id: UUID
    var project: Project?
    var tags: [Tag]
    var notes: String
    var startDate: Date
    var endDate: Date?

    init(id: UUID = UUID(), project: Project? = nil, tags: [Tag] = [], notes: String = "", startDate: Date = Date(), endDate: Date? = nil) {
        self.id = id
        self.project = project
        self.tags = tags
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
    }

    var duration: TimeInterval? {
        guard let end = endDate else { return nil }
        return end.timeIntervalSince(startDate)
    }

    // Computed property to indicate whether this entry is currently running
    var isRunning: Bool {
        return endDate == nil
    }
}
