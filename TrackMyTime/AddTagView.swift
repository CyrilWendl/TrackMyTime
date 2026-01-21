//
//  AddTagView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData

struct AddTagView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var showAlert: Bool = false
    // allow selecting a color for the tag
    @State private var color: Color = .accentColor

    var body: some View {
        NavigationView {
            Form {
                Section("Tag") {
                    TextField("Name", text: $name)
                    ColorPicker("Color", selection: $color)
                }
            }
            .navigationTitle("New Tag")
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
                Text("Please provide a tag name.")
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showAlert = true
            return
        }

        // convert selected Color to a hex string (fallback to accent color hex)
        let hex = color.toHexString() ?? "#007AFF"
        let tag = Tag(name: trimmed, colorHex: hex)
        modelContext.insert(tag)
        dismiss()
    }
}

#Preview {
    AddTagView()
        .modelContainer(for: [Tag.self], inMemory: true)
}
