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

    @State private var selection: SidebarItem? = .entries
    @State private var showingNewEntry = false
    @State private var showingAddProject = false
    @State private var showingAddTag = false
    @State private var noProjectAlert = false

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
        .alert("No projects", isPresented: $noProjectAlert) {
            Button("Create Project") { showingAddProject = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You need to create a project before adding entries.")
        }
    }

    private func handleAddEntryTapped() {
        if projects.isEmpty {
            noProjectAlert = true
        } else {
            showingNewEntry = true
        }
    }
}

// MARK: - Subviews

private struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var projects: [Project]

    @State private var showingAddProject = false
    @State private var editingProject: Project? = nil
    @State private var showingEdit = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(projects) { project in
                    NavigationLink {
                        ProjectDetailView(project: project)
                    } label: {
                        Text(project.name)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Edit") {
                            editingProject = project
                            showingEdit = true
                        }
                        .tint(.blue)
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
            .sheet(isPresented: $showingEdit) {
                if let editingProject = editingProject {
                    EditProjectView(project: editingProject)
                }
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

    @State private var showingNewEntry = false
    @State private var showingAddProject = false
    @State private var showNoProjectAlert = false

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if projects.isEmpty {
                            // Show explanation alert and offer to create a project
                            showNoProjectAlert = true
                        } else {
                            showingNewEntry = true
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                NewEntryView()
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView()
            }
            .alert("No projects", isPresented: $showNoProjectAlert) {
                Button("Create Project") { showingAddProject = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You don't have any projects yet. Please create a project first before adding entries.")
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
                modelContext.delete(entries[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, Entry.self, Project.self, Tag.self], inMemory: true)
}
