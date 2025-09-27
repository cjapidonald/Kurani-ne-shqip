import SwiftUI

struct FontSizeButtonLabel: View {
    enum Action {
        case decrease
        case increase
    }

    let action: Action

    var body: some View {
        Text("A")
            .font(.system(size: fontSize, weight: .semibold))
            .frame(width: 28, height: 28)
            .foregroundStyle(Color.kuraniAccentLight)
            .accessibilityHidden(true)
    }

    private var fontSize: CGFloat {
        switch action {
        case .decrease:
            return 16
        case .increase:
            return 20
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
