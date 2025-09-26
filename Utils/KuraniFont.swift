import SwiftUI
import UIKit

enum KuraniFont {
    static let name = "KG Primary Penmanship"

    static func forTextStyle(_ style: Font.TextStyle) -> Font {
        let uiTextStyle = UIFont.TextStyle(style)
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

private extension UIFont.TextStyle {
    init(_ style: Font.TextStyle) {
        switch style {
        case .largeTitle: self = .largeTitle
        case .title: self = .title1
        case .title2: self = .title2
        case .title3: self = .title3
        case .headline: self = .headline
        case .subheadline: self = .subheadline
        case .body: self = .body
        case .callout: self = .callout
        case .footnote: self = .footnote
        case .caption: self = .caption1
        case .caption2: self = .caption2
        @unknown default: self = .body
        }
    }
}
