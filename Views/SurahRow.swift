import SwiftUI
import Foundation

struct SurahRow: View {
    let surah: Surah
    let progress: Double

    private var percentageString: String {
        let clamped = max(0, min(progress, 1))
        return "\(Int(round(clamped * 100)))%"
    }

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
                Text(String(format: NSLocalizedString("library.progress", comment: "progress"), percentageString))
                    .font(KuraniFont.forTextStyle(.caption2))
                    .foregroundColor(.kuraniAccentLight)
            }
            Spacer()
            ProgressBadge(percentage: percentageString)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.kuraniAccentLight)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

