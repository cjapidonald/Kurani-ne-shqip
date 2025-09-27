import SwiftUI

struct FontSizeButtonLabel: View {
    enum Action {
        case decrease
        case increase
    }

    let action: Action

    var body: some View {
        Text(symbol)
            .font(.system(size: fontSize, weight: fontWeight))
            .frame(width: 28, height: 28)
            .foregroundStyle(Color.kuraniAccentLight)
            .accessibilityHidden(true)
    }

    private var fontSize: CGFloat {
        switch action {
        case .decrease:
            return 18
        case .increase:
            return 20
        }
    }

    private var fontWeight: Font.Weight {
        switch action {
        case .decrease:
            return .regular
        case .increase:
            return .semibold
        }
    }

    private var symbol: String {
        switch action {
        case .decrease:
            return "a"
        case .increase:
            return "A"
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        FontSizeButtonLabel(action: .decrease)
        FontSizeButtonLabel(action: .increase)
    }
    .padding()
    .background(Color.black)
    .previewLayout(.sizeThatFits)
}
