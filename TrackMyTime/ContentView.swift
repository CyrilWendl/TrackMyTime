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
        case about
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
                    NavigationLink(value: SidebarItem.about) {
                        Label("About", systemImage: "info.circle")
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
        } detail: {
            // Detail area shows the selected management view
            Group {
                switch selection {
                case .projects:
                    ProjectsListView()
                case .tags:
                    TagsListView()
                case .about:
                    AboutView()
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
        .onChange(of: entries) { _, newEntries in
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
    @Query private var projects: [Project]
    @Query private var tags: [Tag]

    @State private var selectedProjectID: UUID? = nil // nil = All
    @State private var selectedTagID: UUID? = nil // nil = All
    @State private var sortNewestFirst: Bool = true

    // Compute filtered and sorted entries
    private var filteredSortedEntries: [Entry] {
        var result = entries
        if let pid = selectedProjectID {
            result = result.filter { $0.project?.id == pid }
        }
        if let tid = selectedTagID {
            result = result.filter { $0.tags.contains(where: { $0.id == tid }) }
        }
        result.sort { a, b in
            if sortNewestFirst {
                return a.startDate > b.startDate
            } else {
                return a.startDate < b.startDate
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                // Filters section
                Section(header: Text("Filters")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Project", selection: Binding(get: { selectedProjectID }, set: { selectedProjectID = $0 })) {
                            Text("All").tag(nil as UUID?)
                            ForEach(projects) { project in
                                Text(project.name).tag(project.id as UUID?)
                            }
                        }

                        Picker("Tag", selection: Binding(get: { selectedTagID }, set: { selectedTagID = $0 })) {
                            Text("All").tag(nil as UUID?)
                            ForEach(tags) { tag in
                                Text(tag.name).tag(tag.id as UUID?)
                            }
                        }

                        Picker("Sort", selection: $sortNewestFirst) {
                            Text("Newest").tag(true)
                            Text("Oldest").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Entries
                ForEach(filteredSortedEntries) { entry in
                    NavigationLink {
                        EditEntryView(entry: entry)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.project?.name ?? "No Project")
                                    .font(.headline)
                                Text(entry.notes)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(entry.startDate, format: .dateTime)
                                    .font(.caption)
                            }
                            Spacer()
                            if let _ = entry.endDate {
                                Text(formattedDuration(entry.duration))
                                    .font(.caption)
                            } else {
                                Button(action: { stopEntry(entry) }) {
                                    Label("Stop", systemImage: "stop.circle")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("Entries")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        selectedProjectID = nil
                        selectedTagID = nil
                        sortNewestFirst = true
                    }
                }
            }
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
                modelContext.delete(filteredSortedEntries[index])
            }
        }
    }
}

// MARK: - About View

private struct AboutView: View {
    private var currentYear: String {
        String(Calendar.current.component(.year, from: Date()))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Developer")
                .font(.title2)
                .bold()

            Text("Cyril Wendl ©\(currentYear)")

            HStack {
                Text("Contact:")
                    .bold()
                if let mailURL = URL(string: "mailto:tmt@wendl.ch") {
                    Link("tmt@wendl.ch", destination: mailURL)
                } else {
                    Text("tmt@wendl.ch")
                }
            }

            HStack {
                Text("Website:")
                    .bold()
                if let url = URL(string: "https://wendl.ch") {
                    Link("wendl.ch", destination: url)
                } else {
                    Text("wendl.ch")
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("About")
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

// New helper to format a duration (in seconds) into a human-friendly string like "1h 05m 03s" always showing hours, minutes and seconds
private func formattedDuration(_ seconds: TimeInterval?) -> String {
    let total = Int(seconds ?? 0)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let secs = total % 60

    // Always show hours, minutes and seconds. Pad minutes and seconds to two digits for consistent width.
    return "\(hours)h \(String(format: "%02d", minutes))m \(String(format: "%02d", secs))s"
}
