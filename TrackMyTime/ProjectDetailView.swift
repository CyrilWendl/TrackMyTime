//
//  ProjectDetailView.swift
//  TrackMyTime
//
//  Created by GitHub Copilot on 19.01.2026.
//

import SwiftUI
import SwiftData
import Charts

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let project: Project

    @Query private var entries: [Entry]

    @State private var showingEdit = false
    @State private var showingDeleteOptions = false
    @State private var showingReassign = false

    @Environment(\.dismiss) private var dismiss

    // New state: selected time window for charts
    private enum TimeWindow: String, CaseIterable, Identifiable {
        case week = "1W"
        case month = "1M"
        case threeMonths = "3M"
        case all = "All"

        var id: String { rawValue }
    }

    @State private var selectedWindow: TimeWindow = .week

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

            // Charts section
            Section(header: Text("Charts")) {
                VStack(alignment: .leading) {
                    Picker("Window", selection: $selectedWindow) {
                        ForEach(TimeWindow.allCases) { window in
                            Text(window.rawValue).tag(window)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Show total time and chart
                    let data = aggregatedData(for: selectedWindow)
                    let totalSeconds = data.reduce(0) { $0 + $1.duration }

                    HStack {
                        Text("Total: \(formatDuration(totalSeconds))")
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    if #available(iOS 16.0, macOS 13.0, *) {
                        Chart(data) { point in
                            BarMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Seconds", point.duration)
                            )
                            .foregroundStyle(.blue)
                        }
                        .chartXAxis { AxisMarks(values: .stride(by: .day, count: xAxisStride(for: selectedWindow))) }
                        .frame(height: 160)
                    } else {
                        Text("Charts require iOS 16 / macOS 13+")
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            // Entries section (kept as before)
            Section(header: Text("Entries for project")) {
                ForEach(filteredEntries()) { entry in
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
        .actionSheet(isPresented: $showingDeleteOptions) {
            ActionSheet(title: Text("Delete project?"), message: Text("What should we do with entries that belong to this project?"), buttons: [
                .destructive(Text("Delete entries and project")) {
                    deleteProjectAndEntries()
                },
                .default(Text("Reassign entries to another project")) {
                    showingReassign = true
                },
                .cancel()
            ])
        }
        .sheet(isPresented: $showingReassign) {
            ReassignEntriesView(sourceProject: project)
        }
        .sheet(isPresented: $showingEdit) {
            // Present the edit view for the selected project
            EditProjectView(project: project)
        }
    }

    // MARK: - Helpers for entries and charts

    private func filteredEntries() -> [Entry] {
        entries.filter { $0.project?.id == project.id }
    }

    private struct ChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let duration: Double // seconds
    }

    private func aggregatedData(for window: TimeWindow) -> [ChartPoint] {
        let calendar = Calendar.current
        let now = Date()
        let end = now
        let start: Date
        switch window {
        case .week:
            start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? calendar.startOfDay(for: now)
        case .month:
            start = calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: now)) ?? calendar.startOfDay(for: now)
        case .threeMonths:
            start = calendar.date(byAdding: .month, value: -3, to: calendar.startOfDay(for: now)) ?? calendar.startOfDay(for: now)
        case .all:
            // start from earliest entry
            let dates = filteredEntries().compactMap { $0.startDate }
            start = dates.min() ?? calendar.startOfDay(for: now)
        }

        // Build day buckets from start..end inclusive
        var dayBuckets: [Date: Double] = [:]
        var cursor = calendar.startOfDay(for: start)
        while cursor <= calendar.startOfDay(for: end) {
            dayBuckets[cursor] = 0
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? Date.distantFuture
        }

        let windowStart = start
        let windowEnd = end

        for entry in filteredEntries() {
            let entryStart = entry.startDate
            let entryEnd = entry.endDate ?? now
            // Skip if entirely outside window
            if entryEnd < windowStart || entryStart > windowEnd { continue }

            // Clip to window
            let clippedStart = max(entryStart, windowStart)
            let clippedEnd = min(entryEnd, windowEnd)

            // accumulate into day buckets by splitting over days
            var dayCursor = calendar.startOfDay(for: clippedStart)
            while dayCursor <= calendar.startOfDay(for: clippedEnd) {
                let dayStart = dayCursor
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(86400)
                let overlapStart = max(clippedStart, dayStart)
                let overlapEnd = min(clippedEnd, dayEnd)
                let seconds = max(0, overlapEnd.timeIntervalSince(overlapStart))
                dayBuckets[dayStart, default: 0] += seconds
                dayCursor = calendar.date(byAdding: .day, value: 1, to: dayCursor) ?? Date.distantFuture
            }
        }

        // Map to sorted ChartPoints
        let points = dayBuckets.sorted(by: { $0.key < $1.key }).map { ChartPoint(date: $0.key, duration: $0.value) }
        return points
    }

    private func xAxisStride(for window: TimeWindow) -> Int {
        switch window {
        case .week: return 1
        case .month: return 5
        case .threeMonths: return 14
        case .all: return 30
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
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
