//
//  TagDetailView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData

struct TagDetailView: View {
    let tag: Tag
    @Query private var entries: [Entry]

    var body: some View {
        List {
            Section(header: Text("Tag")) {
                Text(tag.name)
                    .font(.title2)
            }

            Section(header: Text("Entries with tag")) {
                ForEach(entries.filter { $0.tags.contains(where: { $0.id == tag.id }) }) { entry in
                    VStack(alignment: .leading) {
                        Text(entry.project?.name ?? "No Project")
                            .font(.headline)
                        Text(entry.notes)
                            .font(.body)
                        Text(entry.startDate, format: Date.FormatStyle(date: .numeric, time: .shortened))
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(tag.name)
    }
}

#Preview {
    TagDetailView(tag: Tag(name: "Preview"))
        .modelContainer(for: [Tag.self, Entry.self], inMemory: true)
}
