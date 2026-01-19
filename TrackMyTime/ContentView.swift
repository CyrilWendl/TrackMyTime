//
//  ContentView.swift
//  TrackMyTime
//
//  Created by Cyril Wendl on 19.01.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @Query private var entries: [Entry]

    @State private var showingNewEntry = false

    var body: some View {
        NavigationSplitView {
            List {
                Section("Items") {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }

                Section("Entries") {
                    ForEach(entries) { entry in
                        NavigationLink {
                            VStack(alignment: .leading) {
                                HStack {
                                    // A small camera icon with a running indicator next to it
                                    HStack(spacing: 6) {
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.secondary)
                                        if entry.isRunning {
                                            Image(systemName: "smallcircle.fill.circle")
                                                .foregroundColor(.red)
                                        }
                                    }

                                    Text(entry.project?.name ?? "No Project")
                                        .font(.headline)
                                }

                                Text(entry.notes)
                                    .font(.subheadline)

                                if let end = entry.endDate {
                                    Text("Duration: \(Int(entry.duration ?? 0)) seconds")
                                        .font(.caption)
                                } else {
                                    Text("Running")
                                        .font(.caption)
                                }

                                // Provide a prominent stop button when entry is running
                                if entry.isRunning {
                                    HStack {
                                        Spacer()
                                        Button(action: { stopEntry(entry) }) {
                                            Label("Stop", systemImage: "stop.circle")
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                }
                            }
                            .padding()
                        } label: {
                            HStack {
                                HStack {
                                    if entry.isRunning {
                                        Image(systemName: "smallcircle.fill.circle")
                                            .foregroundColor(.red)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(entry.project?.name ?? "No Project")
                                        Text(entry.startDate, format: Date.FormatStyle(date: .numeric, time: .standard))
                                            .font(.caption)
                                    }
                                }
                                Spacer()
                                if let end = entry.endDate {
                                    Text((entry.duration ?? 0).formatted(.number.precision(.fractionLength(0))))
                                        .font(.caption)
                                } else {
                                    Button(action: { stopEntry(entry) }) {
                                        Label("Stop", systemImage: "stop.circle")
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteEntries)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { showingNewEntry = true }) {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .sheet(isPresented: $showingNewEntry) {
            // Use the shared model container from the app (do not create an in-memory container here)
            NewEntryView()
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func stopEntry(_ entry: Entry) {
        withAnimation {
            entry.endDate = Date()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, Entry.self, Project.self, Tag.self], inMemory: true)
}
