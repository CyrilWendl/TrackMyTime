//
//  TagDetailView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData

struct TagDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let tag: Tag
    @Query private var entries: [Entry]

    @State private var name: String = ""
    @State private var color: Color = .accentColor
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag") {
                    HStack(spacing: 8) {
                        TagDot(color: tag.color)
                        Text(tag.name)
                            .font(.title2)
                    }
                    TextField("Tag Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    ColorPicker("Color", selection: $color)
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

                Section {
                    Button("Delete Tag", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
            .navigationTitle(tag.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = tag.name
                color = tag.color
            }
            .alert("Delete Tag?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) { deleteTag() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the tag from all entries and cannot be undone.")
            }
        }
    }

    private func saveChanges() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tag.name = trimmed
        if let hex = color.toHexString() {
            tag.colorHex = hex
        }
        modelContext.insert(tag)
        try? modelContext.save()
        dismiss()
    }

    private func deleteTag() {
        // Remove tag from entries if necessary (entries keep tag objects directly in arrays)
        for entry in entries where entry.tags.contains(where: { $0.id == tag.id }) {
            if let idx = entry.tags.firstIndex(where: { $0.id == tag.id }) {
                entry.tags.remove(at: idx)
            }
        }
        modelContext.delete(tag)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    TagDetailView(tag: Tag(name: "Preview", colorHex: "#FF3B30"))
        .modelContainer(for: [Tag.self, Entry.self], inMemory: true)
}
