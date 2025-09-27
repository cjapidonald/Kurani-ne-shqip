import SwiftUI
import UIKit

enum KuraniFont {
    static let name = "KG Primary Penmanship"

    private static let isFontAvailable: Bool = {
        UIFont(name: name, size: 12) != nil
    }()

    static func forTextStyle(_ style: Font.TextStyle) -> Font {
        let uiTextStyle = style.uiTextStyle
        let baseSize = UIFont.preferredFont(forTextStyle: uiTextStyle).pointSize
        return customFont(size: baseSize, relativeTo: style)
    }

    static func size(_ size: CGFloat) -> Font {
        customFont(size: size)
    }

    static func size(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        customFont(size: size, relativeTo: style)
    }

    private static func customFont(size: CGFloat, relativeTo style: Font.TextStyle? = nil) -> Font {
        guard isFontAvailable else {
            if let style {
                return .system(style)
            } else {
                return .system(size: size)
            }
        }

        if let style {
            return .custom(name, size: size, relativeTo: style)
        } else {
            return .custom(name, size: size)
        }
    }
}

private extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}
