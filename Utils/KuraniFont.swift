import SwiftUI
import UIKit

enum KuraniFont {
    static let name = "KG Primary Penmanship"

    static func forTextStyle(_ style: Font.TextStyle) -> Font {
        let baseSize = UIFont.preferredFont(forTextStyle: style).pointSize
        return Font.custom(name, size: baseSize, relativeTo: style)
    }

    static func size(_ size: CGFloat) -> Font {
        Font.custom(name, size: size)
    }

    static func size(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Font.custom(name, size: size, relativeTo: style)
    }
}
