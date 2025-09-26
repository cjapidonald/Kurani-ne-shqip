import Foundation
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "Accent" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "Accent", bundle: resourceBundle)

    /// The "AccentLight" asset catalog color resource.
    static let accentLight = DeveloperToolsSupport.ColorResource(name: "AccentLight", bundle: resourceBundle)

    /// The "DarkBackground" asset catalog color resource.
    static let darkBackground = DeveloperToolsSupport.ColorResource(name: "DarkBackground", bundle: resourceBundle)

    /// The "Primary" asset catalog color resource.
    static let primary = DeveloperToolsSupport.ColorResource(name: "Primary", bundle: resourceBundle)

    /// The "PrimarySurface" asset catalog color resource.
    static let primarySurface = DeveloperToolsSupport.ColorResource(name: "PrimarySurface", bundle: resourceBundle)

    /// The "TextPrimary" asset catalog color resource.
    static let textPrimary = DeveloperToolsSupport.ColorResource(name: "TextPrimary", bundle: resourceBundle)

    /// The "TextSecondary" asset catalog color resource.
    static let textSecondary = DeveloperToolsSupport.ColorResource(name: "TextSecondary", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

