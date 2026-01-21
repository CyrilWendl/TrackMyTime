import Foundation
import SwiftUI
import SwiftData

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
final class ActivityManager {
    static let shared = ActivityManager()

    private var activities: [UUID: Activity<TrackAttributes>] = [:]

    private init() {}

    func startActivity(for entry: Entry) {
        guard entry.isRunning else { return }
        guard activities[entry.id] == nil else { return }

        let initialState = TrackAttributes.ContentState(startDate: entry.startDate, entryID: entry.id, deeplink: "trackmytime://running")
        let attributes = TrackAttributes()
        let content = ActivityContent(state: initialState, staleDate: nil)

        do {
            print("[ActivityManager] Requesting activity for entry \(entry.id)")
            let activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
            activities[entry.id] = activity
            print("[ActivityManager] Started activity: \(activity.id) for entry \(entry.id)")
        } catch {
            print("[ActivityManager] Failed to start activity: \(error)")
        }
    }

    func updateActivity(entryID: UUID, startDate: Date) {
        guard let activity = activities[entryID] else {
            print("[ActivityManager] No active activity found for entryID \(entryID) when trying to update")
            return
        }
        let newState = TrackAttributes.ContentState(startDate: startDate, entryID: entryID, deeplink: "trackmytime://running")
        Task {
            if #available(iOS 16.2, *) {
                await activity.update(using: newState)
            } else {
                await activity.update(using: newState)
            }
            print("[ActivityManager] Updated activity \(activity.id) for entry \(entryID)")
        }
    }

    func endActivity(for entry: Entry) {
        guard let activity = activities[entry.id] else {
            print("[ActivityManager] No active activity found for entry \(entry.id) when trying to end")
            return
        }
        Task {
            if #available(iOS 16.2, *) {
                // Provide a final content when ending; use the entry's startDate so the lock screen shows final elapsed time.
                let finalState = TrackAttributes.ContentState(startDate: entry.startDate, entryID: entry.id, deeplink: "trackmytime://running")
                let finalContent = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(finalContent, dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .immediate)
            }
            print("[ActivityManager] Ended activity \(activity.id) for entry \(entry.id)")
        }
        activities.removeValue(forKey: entry.id)
    }
}
#endif
