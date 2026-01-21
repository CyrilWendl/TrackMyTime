// PreviewData.swift
// Shared preview data provider for TrackMyTime previews

import Foundation
import SwiftData

/// PreviewData provides a reusable in-memory ModelContainer seeded with sample data
/// Use this from any `#Preview` closure so previews share the same seeding code.
enum PreviewData {
    /// Create an in-memory ModelContainer and seed it with sample Projects, Tags and Entries.
    /// Returns the container and the seeded projects (managed objects inserted into the container).
    static func makeContainerWithProjects() -> (ModelContainer, [Project]) {
        let schema = Schema([Item.self, Entry.self, Project.self, Tag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }

        let context = container.mainContext

        // Seed projects
        let p1 = Project(name: "Personal", details: "Home tasks and hobbies")
        let p2 = Project(name: "Work", details: "Client projects and meetings")
        let p3 = Project(name: "Open Source", details: "Library maintenance")
        context.insert(p1)
        context.insert(p2)
        context.insert(p3)

        // Seed tags
        let t1 = Tag(name: "Urgent")
        let t2 = Tag(name: "Low Priority")
        let t3 = Tag(name: "Work")
        context.insert(t1)
        context.insert(t2)
        context.insert(t3)

        // Seed entries and attach to projects/tags
        let e1 = Entry(notes: "Groceries", startDate: Date())
        e1.project = p1
        e1.tags = [t1, t2]
        context.insert(e1)

        let e2 = Entry(notes: "Team meeting", startDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        e2.project = p2
        context.insert(e2)

        let e3 = Entry(notes: "Code review", startDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date())
        e3.project = p2
        e3.tags = [t3]
        context.insert(e3)

        try? context.save()
        return (container, [p1, p2, p3])
    }

    /// Convenience: return the container and the first project (useful for single-project previews)
    static func containerAndFirstProject() -> (ModelContainer, Project) {
        let (container, projects) = makeContainerWithProjects()
        return (container, projects[0])
    }

    /// Convenience: return the container and a project with a specific name if present
    static func containerAndProject(named name: String) -> (ModelContainer, Project?) {
        let (container, projects) = makeContainerWithProjects()
        return (container, projects.first(where: { $0.name == name }))
    }
}
