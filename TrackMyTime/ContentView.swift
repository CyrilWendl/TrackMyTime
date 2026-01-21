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
    @Query private var entries: [Entry]
    @Query private var projects: [Project]
    @Query private var tags: [Tag]

    @State private var selection: SidebarItem? = nil
    @State private var showingNewEntry = false
    @State private var showingAddProject = false
    @State private var showingAddTag = false
    @State private var noProjectAlert = false
    @State private var showExportSheet = false
    @State private var exportURL: URL? = nil

    enum SidebarItem: Hashable {
        case entries
        case projects
        case tags
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Quick Actions") {
                    Button(action: { handleAddEntryTapped() }) {
                        Label("New Entry", systemImage: "plus")
                    }
                    Button(action: { showingAddProject = true }) {
                        Label("New Project", systemImage: "folder.badge.plus")
                    }
                    Button(action: { showingAddTag = true }) {
                        Label("New Tag", systemImage: "tag")
                    }
                    Button(action: { exportAllEntriesAsCSV() }) {
                        Label("Export as CSV", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Manage") {
                    NavigationLink(value: SidebarItem.entries) {
                        Label("Entries", systemImage: "list.bullet")
                    }
                    NavigationLink(value: SidebarItem.projects) {
                        Label("Projects", systemImage: "folder")
                    }
                    NavigationLink(value: SidebarItem.tags) {
                        Label("Tags", systemImage: "tag")
                    }
                }

                Section("Running") {
                    ForEach(entries.filter { $0.isRunning }) { entry in
                        HStack {
                            Image(systemName: "smallcircle.fill.circle")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text(entry.project?.name ?? "No Project")
                                Text(entry.startDate, format: .dateTime)
                                    .font(.caption)
                            }
                        }
                        .onTapGesture {
                            // Jump to entries view and select nothing in particular
                            selection = .entries
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("TrackMyTime")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        } detail: {
            // Detail area shows the selected management view
            Group {
                switch selection {
                case .projects:
                    ProjectsListView()
                case .tags:
                    TagsListView()
                default:
                    EntriesListView()
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            NewEntryView()
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectView()
        }
        .sheet(isPresented: $showingAddTag) {
            AddTagView()
        }
        .sheet(isPresented: $showExportSheet, onDismiss: { exportURL = nil }) {
            if let url = exportURL {
                ShareLink(item: url) { Text("Share CSV") }
            } else {
                Text("Preparing…")
            }
        }
        .alert("No projects", isPresented: $noProjectAlert) {
            Button("Create Project") { showingAddProject = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You need to create a project before adding entries.")
        }
        .onOpenURL { url in
            // Handle deep link from Dynamic Island / Live Activity
            if url.scheme == "trackmytime", url.host == "running" {
                selection = .entries
            }
        }
        .onChange(of: entries) { newEntries in
            // Start/stop Live Activities for running entries
            for entry in newEntries {
                if entry.isRunning {
#if canImport(ActivityKit)
                    if #available(iOS 16.1, *) {
                        ActivityManager.shared.startActivity(for: entry)
                    }
#endif
                } else {
#if canImport(ActivityKit)
                    if #available(iOS 16.1, *) {
                        ActivityManager.shared.endActivity(for: entry)
                    }
#endif
                }
            }
        }
    }

    private func handleAddEntryTapped() {
        if projects.isEmpty {
            noProjectAlert = true
        } else {
            showingNewEntry = true
        }
    }

    private func exportAllEntriesAsCSV() {
        let csvHeader = "id,project,tags,notes,startDate,endDate,durationSeconds\n"
        var csv = csvHeader

        let iso8601 = ISO8601DateFormatter()
        for entry in entries {
            let id = entry.id.uuidString
            let projectName = entry.project?.name.replacingOccurrences(of: ",", with: " ") ?? ""
            let tagNames = entry.tags.map { $0.name.replacingOccurrences(of: ",", with: " ") }.joined(separator: ";")
            let notes = entry.notes.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: ",", with: " ")
            let start = iso8601.string(from: entry.startDate)
            let end = entry.endDate.map { iso8601.string(from: $0) } ?? ""
            let duration = entry.duration.map { String(Int($0)) } ?? ""
            let line = "\(id),\(projectName),\(tagNames),\(notes),\(start),\(end),\(duration)\n"
            csv += line
        }

        // write to temp file and present share sheet
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("trackmytime_entries_\(Int(Date().timeIntervalSince1970)).csv")
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            showExportSheet = true
        } catch {
            print("Failed to write CSV: \(error)")
        }
    }
}

// MARK: - Subviews

private struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]

    @State private var showingAddProject = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(projects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        Text(project.name)
                    }
                }
                .onDelete(perform: deleteProjects)
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProject = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
            }
        }
    }

    private func deleteProjects(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(projects[index])
            }
        }
    }
}

private struct TagsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tags: [Tag]

    @State private var showingAddTag = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(tags) { tag in
                    NavigationLink {
                        TagDetailView(tag: tag)
                    } label: {
                        Text(tag.name)
                    }
                }
                .onDelete(perform: deleteTags)
            }
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTag = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTag) {
                AddTagView()
            }
        }
    }

    private func deleteTags(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(tags[index])
            }
        }
    }
}

private struct EntriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [Entry]

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.secondary)
                                if entry.isRunning {
                                    Image(systemName: "smallcircle.fill.circle")
                                        .foregroundColor(.red)
                                }
                                Text(entry.project?.name ?? "No Project")
                                    .font(.headline)
                            }
                            Text(entry.notes)
                                .font(.subheadline)
                            if let _ = entry.endDate {
                                Text("Duration: \(Int(entry.duration ?? 0)) seconds")
                                    .font(.caption)
                            } else {
                                Text("Running")
                                    .font(.caption)
                            }
                        }
                        .padding()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.project?.name ?? "No Project")
                                Text(entry.startDate, format: .dateTime)
                                    .font(.caption)
                            }
                            Spacer()
                            if let _ = entry.endDate {
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
            .navigationTitle("Entries")
        }
    }

    private func stopEntry(_ entry: Entry) {
        withAnimation {
            entry.endDate = Date()
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
        .modelContainer(previewModelContainer())
}

// Helper for previews: create an in-memory ModelContainer seeded with sample projects
private func previewModelContainer() -> ModelContainer {
    let schema = Schema([Item.self, Entry.self, Project.self, Tag.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container: ModelContainer
    do {
        container = try ModelContainer(for: schema, configurations: [config])
    } catch {
        fatalError("Failed to create preview ModelContainer: \(error)")
    }

    let context = container.mainContext

    // Insert a few example projects for the canvas
    let p1 = Project(name: "Personal", details: "Home tasks and hobbies")
    let p2 = Project(name: "Work", details: "Client projects and meetings")
    let p3 = Project(name: "Open Source", details: "Library maintenance")

    context.insert(p1)
    context.insert(p2)
    context.insert(p3)

    // Insert some example tags
    let t1 = Tag(name: "Research", colorHex: "#FF9500")
    let t2 = Tag(name: "Meeting", colorHex: "#007AFF")
    context.insert(t1)
    context.insert(t2)

    // Insert example entries: one finished and one currently running
    let finishedEntry = Entry(project: p2, tags: [t2], notes: "Client sync and planning", startDate: Date().addingTimeInterval(-3600 * 3), endDate: Date().addingTimeInterval(-3600 * 2))
    let runningEntry = Entry(project: p1, tags: [t1], notes: "Sketching ideas", startDate: Date().addingTimeInterval(-300), endDate: nil)

    context.insert(finishedEntry)
    context.insert(runningEntry)

    // Save context (ignore errors in preview)
    try? context.save()

    return container
}
