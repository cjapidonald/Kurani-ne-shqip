import SwiftUI

struct ArabicDictionaryDetailView: View {
    let entry: ArabicDictionaryEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.word)
                        .font(.system(size: 28, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(entry.transliteration)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.kuraniTextSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey("dictionary.meanings"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.kuraniAccentLight)

                    ForEach(entry.meanings, id: \.self) { meaning in
                        Text("• \(meaning)")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                if let notes = entry.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey("dictionary.notes"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.kuraniAccentLight)

                        Text(notes)
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.kuraniTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.kuraniPrimarySurface)
    }
}
