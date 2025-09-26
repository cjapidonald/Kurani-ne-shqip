import SwiftUI
import UIKit

enum KuraniFont {
    static let name = "KG Primary Penmanship"

    static func forTextStyle(_ style: Font.TextStyle) -> Font {
        let uiTextStyle = style.uiTextStyle
        let baseSize = UIFont.preferredFont(forTextStyle: uiTextStyle).pointSize
        return Font.custom(name, size: baseSize, relativeTo: style)
    }

    static func size(_ size: CGFloat) -> Font {
        Font.custom(name, size: size)
    }

    static func size(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Font.custom(name, size: size, relativeTo: style)
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
