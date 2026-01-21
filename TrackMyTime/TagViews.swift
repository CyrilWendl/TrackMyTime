import SwiftUI

// Small reusable tag dot used throughout the app
struct TagDot: View {
    let color: Color
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
    }
}
