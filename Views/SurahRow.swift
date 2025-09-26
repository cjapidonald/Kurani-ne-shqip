import SwiftUI
import Foundation

struct SurahRow: View {
    let surah: Surah

    var body: some View {
        HStack(spacing: 16) {
            Pill(number: surah.number)
            VStack(alignment: .leading, spacing: 4) {
                Text(surah.name)
                    .font(KuraniFont.forTextStyle(.headline))
                    .foregroundColor(.kuraniTextPrimary)
                Text("\(surah.ayahCount) \(NSLocalizedString("library.ayahs", comment: ""))")
                    .font(KuraniFont.forTextStyle(.caption))
                    .foregroundColor(.kuraniTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.kuraniAccentLight)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

