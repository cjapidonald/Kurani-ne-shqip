import SwiftUI

enum KuraniTheme {
    static let background = Color.darkBackground
    static let surface = Color.primarySurface
    static let primary = Color.primaryBrand
    static let accent = Color.accentBrand
    static let accentLight = Color.accentLight

    static let headerGradient = LinearGradient(
        colors: [Color.primaryBrand, Color.accentBrand],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color.accentBrand, Color.primaryBrand],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    static let darkBackground = Color("DarkBackground")
    static let primarySurface = Color("PrimarySurface")
    static let primaryBrand = Color("Primary")
    static let accentBrand = Color("Accent")
    static let accentLight = Color("AccentLight")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
}

struct BrandHeader: View {
    let titleKey: LocalizedStringKey
    var subtitle: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KuraniTheme.headerGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 6)
    }
}

struct Pill: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.system(.caption, design: .rounded))
            .fontWeight(.semibold)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.primarySurface.opacity(0.8))
            .clipShape(Capsule())
            .foregroundColor(.accentLight)
    }
}

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.primaryBrand, Color.accentBrand],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct ToastView: View {
    let message: LocalizedStringKey

    var body: some View {
        Text(message)
            .font(.system(.callout, design: .rounded))
            .fontWeight(.medium)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.primarySurface.opacity(0.95))
            .foregroundColor(.textPrimary)
            .clipShape(Capsule())
            .shadow(radius: 12)
    }
}
