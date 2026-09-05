import SwiftUI

/// Screen heading matching the design system's page-title spec (25px / weight 800).
/// Used instead of iOS's native large title, which can't be reliably restyled to a custom
/// font via UINavigationBarAppearance (it collapses the title on this iOS version).
struct PageHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppFont.pageTitle())
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
