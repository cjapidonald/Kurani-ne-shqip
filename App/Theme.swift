import SwiftUI

enum KuraniTheme {
    static let background = Color.kuraniDarkBackground
    static let surface = Color.kuraniPrimarySurface
    static let primary = Color.kuraniPrimaryBrand
    static let accent = Color.kuraniAccentBrand
    static let accentLight = Color.kuraniAccentLight
}

extension Color {
    static let kuraniDarkBackground = Color("DarkBackground")
    static let kuraniPrimarySurface = Color("PrimarySurface")
    static let kuraniPrimaryBrand = Color("Primary")
    static let kuraniAccentBrand = Color("Accent")
    static let kuraniAccentLight = Color("AccentLight")
    static let kuraniTextPrimary = Color("TextPrimary")
    static let kuraniTextSecondary = Color("TextSecondary")

    // Backwards compatibility alias for older usages in the codebase
    static let accentBrand = Color.kuraniAccentBrand
}

struct BrandHeader: View {
    let titleKey: LocalizedStringKey
    var subtitle: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(titleKey)
                .font(KuraniFont.forTextStyle(.largeTitle))
                .fontWeight(.semibold)
                .foregroundColor(.kuraniTextPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(KuraniFont.forTextStyle(.subheadline))
                    .foregroundColor(.kuraniTextSecondary)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.kuraniAccentLight.opacity(0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1.2)
                )
                .shadow(color: Color.kuraniPrimaryBrand.opacity(0.14), radius: 18, y: 12)
        )
        .padding(.horizontal, 4)
    }
}

struct Pill: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(KuraniFont.forTextStyle(.subheadline))
            .fontWeight(.semibold)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .foregroundColor(.black)
            .background(
                Capsule()
                    .fill(Color.kuraniAccentLight.opacity(0.9))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black, lineWidth: 0.8)
            )
            .shadow(color: Color.kuraniAccentBrand.opacity(0.18), radius: 8, y: 4)
    }
}

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(KuraniTheme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: Color.kuraniAccentBrand.opacity(configuration.isPressed ? 0.12 : 0.22), radius: 12, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.36, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct ToastView: View {
    let message: LocalizedStringKey

    var body: some View {
        Text(message)
            .font(KuraniFont.forTextStyle(.callout))
            .fontWeight(.medium)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.kuraniPrimarySurface.opacity(0.95))
            .foregroundColor(.kuraniTextPrimary)
            .clipShape(Capsule())
            .shadow(radius: 12)
    }
}

private struct AppleCardBackground: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.kuraniPrimarySurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.kuraniPrimaryBrand.opacity(0.08), radius: 10, y: 6)
            )
    }
}

extension View {
    func appleCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(AppleCardBackground(cornerRadius: cornerRadius))
    }
}
