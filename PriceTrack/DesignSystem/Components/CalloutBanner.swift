import SwiftUI

struct CalloutBanner: View {
    let text: String
    var style: Style = .info

    enum Style { case info, warn }

    private var icon: String {
        style == .info ? "info.circle.fill" : "exclamationmark.triangle.fill"
    }

    private var background: Color { style == .info ? .calloutInfoBg : .calloutWarnBg }
    private var border: Color { style == .info ? .calloutInfoBorder : .calloutWarnBorder }
    private var foreground: Color { style == .info ? .calloutInfoText : .calloutWarnText }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
            Text(text)
                .font(AppFont.secondaryDetail())
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
