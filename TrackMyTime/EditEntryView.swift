//
//  EditEntryView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: Entry

    @Query private var projects: [Project]
    @Query private var tags: [Tag]

    @State private var selectedProjectID: UUID?
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var notes: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date? = nil
    @State private var showEndDate: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project")) {
                    Picker("Project", selection: Binding(get: {
                        selectedProjectID ?? projects.first?.id
                    }, set: { newValue in
                        selectedProjectID = newValue
                    })) {
                        ForEach(projects) { project in
                            Text(project.name).tag(project.id as UUID?)
                        }
                    }
                }

                Section(header: Text("Tags")) {
                    if tags.isEmpty {
                        Text("No tags available")
                    } else {
                        ForEach(tags) { tag in
                            Toggle(isOn: Binding(get: {
                                selectedTagIDs.contains(tag.id)
                            }, set: { isOn in
                                if isOn { selectedTagIDs.insert(tag.id) } else { selectedTagIDs.remove(tag.id) }
                            })) {
                                Text(tag.name)
                            }
                        }
                    }
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }

                Section(header: Text("Times")) {
                    DatePicker("Start", selection: $startDate)
                    Toggle("Set end time", isOn: $showEndDate)
                    if showEndDate {
                        DatePicker("End", selection: Binding(get: {
                            endDate ?? Date()
                        }, set: { newValue in
                            endDate = newValue
                        }))
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        selectedProjectID = entry.project?.id
        selectedTagIDs = Set(entry.tags.map { $0.id })
        notes = entry.notes
        startDate = entry.startDate
        if let e = entry.endDate {
            endDate = e
            showEndDate = true
        } else {
            endDate = nil
            showEndDate = false
        }
    }

    private func save() {
        // Validation
        guard let projectID = selectedProjectID, let project = projects.first(where: { $0.id == projectID }) else {
            alertMessage = "Please select a project."
            showAlert = true
            return
        }

        if showEndDate, let end = endDate, end < startDate {
            alertMessage = "End date must be after start date."
            showAlert = true
            return
        }

        let selectedTags = tags.filter { selectedTagIDs.contains($0.id) }

        // Apply changes to the model object
        entry.project = project
        entry.tags = selectedTags
        entry.notes = notes
        entry.startDate = startDate
        entry.endDate = showEndDate ? endDate : nil

        // SwiftData persists changes automatically when objects are mutated under a ModelContext
        dismiss()
    }
}

#Preview {
    // Create an in-memory container and sample data for preview
    ContentView()
        .modelContainer(for: [Item.self, Entry.self, Project.self, Tag.self], inMemory: true)
}
