//
//  AddProjectView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData

struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section("Project") {
                    TextField("Name", text: $name)
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Name required", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please provide a project name.")
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showAlert = true
            return
        }

        let project = Project(name: trimmed)
        modelContext.insert(project)
        dismiss()
    }
}

#Preview {
    AddProjectView()
        .modelContainer(for: [Project.self], inMemory: true)
}
