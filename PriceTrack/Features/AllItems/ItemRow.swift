import SwiftUI

struct ItemRow: View {
    let item: GroceryItem

    private var cheapest: StoreComparison? {
        PriceNormalizer.cheapestStore(for: item)
    }

    private var avatarLetter: String {
        let trimmed = item.category.trimmingCharacters(in: .whitespaces)
        return trimmed.first.map { String($0).uppercased() } ?? "•"
    }

    private var avatarSymbol: String? {
        CategoryClassifier.symbolName(forCategory: item.category)
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(item.categoryColor)
                .frame(width: 3)
                .padding(.vertical, 6)

            avatar

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if item.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.accent)
                    }
                    Text(item.name)
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.ink)
                }
                if !item.category.isEmpty {
                    Text(item.category)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textMuted)
                }
            }
            Spacer()
            if let cheapest {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(cheapest.unitPrice.value.currencyString)/\(cheapest.unitPrice.unitLabel)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentSuccess)
                    Text(cheapest.store.displayName)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                }
            } else {
                Text("No prices")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textMuted)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var avatar: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(item.categoryColor.opacity(0.15))
            .frame(width: 44, height: 44)
            .overlay(
                Group {
                    if let avatarSymbol {
                        Image(systemName: avatarSymbol)
                            .font(.system(size: 17, weight: .semibold))
                    } else {
                        Text(avatarLetter)
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .foregroundStyle(item.categoryColor)
            )
    }
}
