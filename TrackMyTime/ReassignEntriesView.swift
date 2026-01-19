//
//  ReassignEntriesView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData

struct ReassignEntriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let sourceProject: Project
    @Query private var projects: [Project]
    @Query private var entries: [Entry]

    @State private var selectedTargetID: UUID?
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reassign entries from \(sourceProject.name) to:")) {
                    Picker("Target project", selection: $selectedTargetID) {
                        ForEach(projects.filter { $0.id != sourceProject.id }) { p in
                            Text(p.name).tag(p.id as UUID?)
                        }
                    }
                }
            }
            .navigationTitle("Reassign Entries")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reassign") { reassign() }
                        .disabled(selectedTargetID == nil)
                }
            }
            .alert("Select target", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please select a target project to reassign entries to.")
            }
        }
    }

    private func reassign() {
        guard let targetID = selectedTargetID, let target = projects.first(where: { $0.id == targetID }) else {
            showAlert = true
            return
        }

        withAnimation {
            for entry in entries.filter({ $0.project?.id == sourceProject.id }) {
                entry.project = target
            }
            modelContext.delete(sourceProject)
        }

        dismiss()
    }
}

#Preview {
    ReassignEntriesView(sourceProject: Project(name: "Source"))
        .modelContainer(for: [Project.self, Entry.self], inMemory: true)
}
