//
//  ProjectDetailView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let project: Project

    @Query private var entries: [Entry]

    var body: some View {
        List {
            Section(header: Text("Project")) {
                Text(project.name)
                    .font(.title2)
            }

            Section(header: Text("Entries for project")) {
                ForEach(entries.filter { $0.project?.id == project.id }) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.notes)
                            .font(.body)
                        Text(entry.startDate, format: Date.FormatStyle(date: .numeric, time: .shortened))
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(project.name)
    }
}

#Preview {
    ProjectDetailView(project: Project(name: "Preview Project"))
        .modelContainer(for: [Project.self, Entry.self], inMemory: true)
}
