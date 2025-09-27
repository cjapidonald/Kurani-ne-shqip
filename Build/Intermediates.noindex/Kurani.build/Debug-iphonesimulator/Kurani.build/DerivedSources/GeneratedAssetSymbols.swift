import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
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

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "AccentLight" asset catalog color resource.
    static let accentLight = DeveloperToolsSupport.ColorResource(name: "AccentLight", bundle: resourceBundle)

    /// The "BrandAccent" asset catalog color resource.
    static let brandAccent = DeveloperToolsSupport.ColorResource(name: "BrandAccent", bundle: resourceBundle)

    /// The "BrandPrimary" asset catalog color resource.
    static let brandPrimary = DeveloperToolsSupport.ColorResource(name: "BrandPrimary", bundle: resourceBundle)

    /// The "DarkBackground" asset catalog color resource.
    static let darkBackground = DeveloperToolsSupport.ColorResource(name: "DarkBackground", bundle: resourceBundle)

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

    /// The "AppIcon" asset catalog image resource.
    static let appIcon = DeveloperToolsSupport.ImageResource(name: "AppIcon", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "AccentLight" asset catalog color.
    static var accentLight: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accentLight)
#else
        .init()
#endif
    }

    /// The "BrandAccent" asset catalog color.
    static var brandAccent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .brandAccent)
#else
        .init()
#endif
    }

    /// The "BrandPrimary" asset catalog color.
    static var brandPrimary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .brandPrimary)
#else
        .init()
#endif
    }

    /// The "DarkBackground" asset catalog color.
    static var darkBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .darkBackground)
#else
        .init()
#endif
    }

    /// The "PrimarySurface" asset catalog color.
    static var primarySurface: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .primarySurface)
#else
        .init()
#endif
    }

    /// The "TextPrimary" asset catalog color.
    static var textPrimary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textPrimary)
#else
        .init()
#endif
    }

    /// The "TextSecondary" asset catalog color.
    static var textSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .textSecondary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "AccentLight" asset catalog color.
    static var accentLight: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accentLight)
#else
        .init()
#endif
    }

    /// The "BrandAccent" asset catalog color.
    static var brandAccent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .brandAccent)
#else
        .init()
#endif
    }

    /// The "BrandPrimary" asset catalog color.
    static var brandPrimary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .brandPrimary)
#else
        .init()
#endif
    }

    /// The "DarkBackground" asset catalog color.
    static var darkBackground: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .darkBackground)
#else
        .init()
#endif
    }

    /// The "PrimarySurface" asset catalog color.
    static var primarySurface: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .primarySurface)
#else
        .init()
#endif
    }

    /// The "TextPrimary" asset catalog color.
    static var textPrimary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textPrimary)
#else
        .init()
#endif
    }

    /// The "TextSecondary" asset catalog color.
    static var textSecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .textSecondary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "AccentLight" asset catalog color.
    static var accentLight: SwiftUI.Color { .init(.accentLight) }

    /// The "BrandAccent" asset catalog color.
    static var brandAccent: SwiftUI.Color { .init(.brandAccent) }

    /// The "BrandPrimary" asset catalog color.
    static var brandPrimary: SwiftUI.Color { .init(.brandPrimary) }

    /// The "DarkBackground" asset catalog color.
    static var darkBackground: SwiftUI.Color { .init(.darkBackground) }

    /// The "PrimarySurface" asset catalog color.
    static var primarySurface: SwiftUI.Color { .init(.primarySurface) }

    /// The "TextPrimary" asset catalog color.
    static var textPrimary: SwiftUI.Color { .init(.textPrimary) }

    /// The "TextSecondary" asset catalog color.
    static var textSecondary: SwiftUI.Color { .init(.textSecondary) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "AccentLight" asset catalog color.
    static var accentLight: SwiftUI.Color { .init(.accentLight) }

    /// The "BrandAccent" asset catalog color.
    static var brandAccent: SwiftUI.Color { .init(.brandAccent) }

    /// The "BrandPrimary" asset catalog color.
    static var brandPrimary: SwiftUI.Color { .init(.brandPrimary) }

    /// The "DarkBackground" asset catalog color.
    static var darkBackground: SwiftUI.Color { .init(.darkBackground) }

    /// The "PrimarySurface" asset catalog color.
    static var primarySurface: SwiftUI.Color { .init(.primarySurface) }

    /// The "TextPrimary" asset catalog color.
    static var textPrimary: SwiftUI.Color { .init(.textPrimary) }

    /// The "TextSecondary" asset catalog color.
    static var textSecondary: SwiftUI.Color { .init(.textSecondary) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "AppIcon" asset catalog image.
    static var appIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .appIcon)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "AppIcon" asset catalog image.
    static var appIcon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .appIcon)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

