import SwiftUI

struct ProgressBadge: View {
    let percentage: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.kuraniAccentLight.opacity(0.16))
            Circle()
                .stroke(Color.kuraniAccentLight, lineWidth: 1.4)

            Text(percentage)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.kuraniAccentLight)
        }
        .frame(width: 34, height: 34)
    }
}
