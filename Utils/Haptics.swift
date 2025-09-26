import Foundation
import UIKit
#if canImport(CoreHaptics)
import CoreHaptics
#endif

enum Haptics {
    private static let supportsHaptics: Bool = {
#if canImport(CoreHaptics)
        if ProcessInfo.processInfo.isMacCatalystApp {
            return false
        }

        if #available(iOS 14.0, *) {
            if ProcessInfo.processInfo.isiOSAppOnMac {
                return false
            }
        }

        if #available(iOS 13.0, *) {
            return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        }
#endif
        return false
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
