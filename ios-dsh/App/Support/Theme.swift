import SwiftUI
import UIKit

enum Theme {
    static let accent = Color(red: 0.33, green: 0.57, blue: 1.00)
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.13)
    static let paper = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let muted = Color(uiColor: .secondaryLabel)

    static let markGradient = LinearGradient(
        colors: [Color(red: 0.36, green: 0.62, blue: 1.0), Color(red: 0.55, green: 0.38, blue: 0.98)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func failure() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
