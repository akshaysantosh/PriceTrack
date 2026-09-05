import SwiftUI

struct SectionLabel: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text.uppercased())
                .font(AppFont.sectionLabel())
                .tracking(0.6)
                .foregroundStyle(Color.accent)
            Rectangle()
                .fill(Color(hex: "#f0ede5"))
                .frame(maxWidth: .infinity)
                .frame(height: 2)
        }
        .padding(.top, 24)
    }
}
