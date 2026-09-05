import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var valueColor: Color = .accent

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppFont.heroNumber(23))
                .foregroundStyle(valueColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
        .background(Color.bgCard)
        .overlay(
            RoundedRectangle(cornerRadius: AppMetrics.statRadius)
                .stroke(Color.borderCard, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppMetrics.statRadius))
    }
}
