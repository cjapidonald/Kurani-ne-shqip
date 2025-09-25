import SwiftUI

struct SurahRow: View {
    let surah: Surah

    var body: some View {
        HStack(spacing: 16) {
            Pill(number: surah.number)
            VStack(alignment: .leading, spacing: 4) {
                Text(surah.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.textPrimary)
                Text("\(surah.ayahCount) \(LocalizedStringKey("library.ayahs"))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.accentBrand)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
