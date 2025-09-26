import SwiftUI

enum KuraniTheme {
    static let background = Color.kuraniDarkBackground
    static let surface = Color.kuraniPrimarySurface
    static let primary = Color.kuraniPrimaryBrand
    static let accent = Color.kuraniAccentBrand
    static let accentLight = Color.kuraniAccentLight

    static let headerGradient = LinearGradient(
        colors: [Color.kuraniPrimaryBrand, Color.kuraniAccentBrand],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color.kuraniAccentBrand, Color.kuraniPrimaryBrand],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    static let kuraniDarkBackground = Color("DarkBackground")
    static let kuraniPrimarySurface = Color("PrimarySurface")
    static let kuraniPrimaryBrand = Color("Primary")
    static let kuraniAccentBrand = Color("Accent")
    static let kuraniAccentLight = Color("AccentLight")
    static let kuraniTextPrimary = Color("TextPrimary")
    static let kuraniTextSecondary = Color("TextSecondary")
}

struct BrandHeader: View {
    let titleKey: LocalizedStringKey
    var subtitle: LocalizedStringKey?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titleKey)
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.kuraniTextPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.kuraniTextSecondary)
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
            .background(Color.kuraniPrimarySurface.opacity(0.8))
            .clipShape(Capsule())
            .foregroundColor(.kuraniAccentLight)
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
                    colors: [Color.kuraniPrimaryBrand, Color.kuraniAccentBrand],
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
            .background(Color.kuraniPrimarySurface.opacity(0.95))
            .foregroundColor(.kuraniTextPrimary)
            .clipShape(Capsule())
            .shadow(radius: 12)
    }
}
