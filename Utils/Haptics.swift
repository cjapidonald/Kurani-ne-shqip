import Foundation
import UIKit
#if canImport(CoreHaptics)
import CoreHaptics
#endif

enum Haptics {
    private static let supportsHaptics: Bool = {
#if targetEnvironment(macCatalyst)
        return false
#else
#if canImport(CoreHaptics)
        if #available(iOS 13.0, *) {
            return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        }
#endif
        return false
#endif
    }()

    static func success() {
        guard supportsHaptics else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func warning() {
        guard supportsHaptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
