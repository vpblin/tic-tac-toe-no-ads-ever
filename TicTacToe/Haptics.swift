import UIKit

/// Small wrapper so game code reads cleanly and taps feel physical.
enum Haptics {
    static func place() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    static func win() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func draw() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
