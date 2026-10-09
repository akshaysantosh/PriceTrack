import SwiftUI

struct CardView<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            content
        }
        .padding(AppMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card)
                .stroke(Color.borderCard, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
}
