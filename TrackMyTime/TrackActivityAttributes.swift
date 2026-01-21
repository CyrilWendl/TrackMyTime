// New shared Activity attributes moved out so both the app and the Live Activity extension
// can reference the same type. Add this file to the Live Activity widget target as well
// (set target membership in Xcode).

import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.1, *)
public struct TrackAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var startDate: Date
        public var entryID: UUID
        public var deeplink: String?

        public init(startDate: Date, entryID: UUID, deeplink: String? = nil) {
            self.startDate = startDate
            self.entryID = entryID
            self.deeplink = deeplink
        }
    }

    public init() {}
}
#endif
