import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
struct TrackMyTimeLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TrackAttributes.self) { context in
            // Lock screen / expanded UI
            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Recording")
                        .font(.headline)
                    Spacer()
                    Text(context.state.startDate, style: .timer)
                        .font(.headline)
                }
                if let deeplink = context.state.deeplink, let url = URL(string: deeplink) {
                    Link(destination: url) {
                        Text("Open")
                    }
                }
            }
            .padding()
            .activitySystemActionForegroundColor(.accentColor)
            .widgetURL(URL(string: context.state.deeplink ?? ""))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.startDate, style: .timer)
                        .font(.headline)
                }
            } compactLeading: {
                // Compact leading view: small red dot
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            } compactTrailing: {
                // Compact trailing: elapsed time
                Text(context.state.startDate, style: .timer)
                    .font(.caption)
            } minimal: {
                // Minimal island: very small red dot
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
            }
        }
    }
}
#endif
