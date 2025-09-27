import SwiftUI

struct FontSizeButtonLabel: View {
    enum Action {
        case decrease
        case increase
    }

    let action: Action

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .semibold))
            .frame(width: 28, height: 28)
            .foregroundStyle(Color.kuraniAccentLight)
            .accessibilityHidden(true)
    }

    private var symbol: String {
        switch action {
        case .decrease:
            return "minus"
        case .increase:
            return "plus"
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
