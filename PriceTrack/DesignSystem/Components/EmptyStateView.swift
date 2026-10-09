import SwiftUI

/// One calm empty state: an icon, a short message, and an optional action.
struct EmptyStateView: View {
    let symbolName: String
    let message: String
    var actionTitle: String?
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: AppSpacing.m) {
            Image(systemName: symbolName)
                .font(.largeTitle.weight(.light))
                .foregroundStyle(Color.textMuted)
            Text(message)
                .font(AppFont.secondaryDetail())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.primary)
                    .padding(.horizontal, AppSpacing.xxl + AppSpacing.l)
                    .padding(.top, AppSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xxl + AppSpacing.l)
    }
}
