import SwiftUI

struct SurahRow: View {
    let surah: Surah

    var body: some View {
        HStack(spacing: 16) {
            Pill(number: surah.number)
            VStack(alignment: .leading, spacing: 4) {
                Text(surah.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.kuraniTextPrimary)
                Text("\(surah.ayahCount) \(LocalizedStringKey("library.ayahs"))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.kuraniTextSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color.accentBrand)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

