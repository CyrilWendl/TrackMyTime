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

    @State private var showingEdit = false
    @State private var showingDeleteOptions = false
    @State private var showingReassign = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section(header: Text("Project")) {
                Text(project.name)
                    .font(.title2)
                if let details = project.details {
                    Text(details)
                        .font(.body)
                }
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
                .onDelete(perform: deleteRelatedEntries)
            }
        }
        .navigationTitle(project.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) { showingDeleteOptions = true } label: {
                    Image(systemName: "trash")
                }
            }
        }
        // Use confirmationDialog which displays title and message reliably across platforms
        .confirmationDialog("Delete project?", isPresented: $showingDeleteOptions, titleVisibility: .visible) {
            Button(role: .destructive) {
                deleteProjectAndEntries()
            } label: {
                Text("Delete entries and project")
            }

            Button {
                showingReassign = true
            } label: {
                Text("Reassign entries to another project")
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What should we do with entries that belong to this project?")
        }
        .sheet(isPresented: $showingReassign) {
            ReassignEntriesView(sourceProject: project)
        }
        .sheet(isPresented: $showingEdit) {
            // Present the edit view for the selected project
            EditProjectView(project: project)
        }
    }

    private func deleteRelatedEntries(offsets: IndexSet) {
        withAnimation {
            let filtered = entries.filter { $0.project?.id == project.id }
            for index in offsets {
                let entry = filtered[index]
                modelContext.delete(entry)
            }
        }
    }

    private func deleteProjectAndEntries() {
        withAnimation {
            // delete entries that belong to this project
            for entry in entries.filter({ $0.project?.id == project.id }) {
                modelContext.delete(entry)
            }
            // delete the project
            modelContext.delete(project)
            dismiss()
        }
    }
}

#Preview {
    let (container, previewProject) = PreviewData.containerAndFirstProject()
    ProjectDetailView(project: previewProject)
        .modelContainer(container)
}
