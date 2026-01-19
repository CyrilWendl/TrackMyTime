//
//  EditProjectView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData

struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let project: Project

    @State private var name: String = ""
    @State private var details: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Project") {
                    TextField("Name", text: $name)
                }
                Section("Description (optional)") {
                    TextEditor(text: $details)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = project.name
                details = project.details ?? ""
            }
        }
    }

    private func save() {
        withAnimation {
            project.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
            project.details = trimmedDetails.isEmpty ? nil : trimmedDetails
        }
        dismiss()
    }
}

#Preview {
    EditProjectView(project: Project(name: "Preview"))
        .modelContainer(for: [Project.self], inMemory: true)
}
