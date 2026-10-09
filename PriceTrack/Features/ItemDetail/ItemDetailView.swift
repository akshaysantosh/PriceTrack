import SwiftUI
import SwiftData
import Foundation

struct ItemDetailView: View {
    @Bindable var item: GroceryItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddPrice = false
    @State private var showingEditItem = false
    @State private var showingDeleteConfirm = false

    private var comparisons: [StoreComparison] {
        PriceNormalizer.latestUnitPricesByStore(for: item)
    }

    private var sortedEntries: [PriceEntry] {
        (item.priceEntries ?? []).sorted { $0.date > $1.date }
    }

    /// A line chart is only meaningful with a few points.
    private var showsChart: Bool { sortedEntries.count >= 3 }

    var body: some View {
        List {
            hero
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l))

            if !comparisons.isEmpty {
                label("Compare by store")
                ForEach(comparisons) { comparison in
                    comparisonRow(comparison, isCheapest: comparison.id == comparisons.first?.id)
                        .rowStyle()
                }
            }

            if !sortedEntries.isEmpty {
                label("Price history")
                if showsChart {
                    PriceHistoryChart(entries: sortedEntries)
                        .frame(height: 200)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l))
                } else {
                    Text("Log a couple more prices to see a trend.")
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textMuted)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l))
                }

                label("Logged prices")
                ForEach(sortedEntries) { entry in
                    entryRow(entry)
                        .rowStyle()
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        item.isFavorite.toggle()
                    } label: {
                        Label(item.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                              systemImage: item.isFavorite ? "star.slash" : "star")
                    }
                    Button {
                        showingEditItem = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete item", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.ink)
                }
                .accessibilityLabel("More actions")
            }
        }
        .sheet(isPresented: $showingAddPrice) {
            AddPriceSheet(item: item)
        }
        .sheet(isPresented: $showingEditItem) {
            EditItemSheet(item: item)
        }
        .confirmationDialog("Delete this item? This also removes its price history.", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
        }
    }

    // MARK: Pieces

    private var hero: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if !item.category.isEmpty {
                    Text(item.category)
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textSecondary)
                }
                Text(item.name)
                    .font(AppFont.detailTitle())
                    .foregroundStyle(Color.ink)
            }

            if let cheapest = comparisons.first {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("\(cheapest.unitPrice.value.currencyString)/\(cheapest.unitPrice.unitLabel)")
                        .font(AppFont.heroPrice())
                        .foregroundStyle(Color.accentSuccess)
                    Text("Cheapest now at \(cheapest.store.displayName)")
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textSecondary)
                }
            } else {
                Text("No prices logged yet. Scan a receipt or log one by hand.")
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textMuted)
            }

            Button {
                showingAddPrice = true
            } label: {
                Label("Log a price", systemImage: "plus")
            }
            .buttonStyle(.solidAccent)
        }
    }

    private func label(_ text: String) -> some View {
        SectionLabel(text: text)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: AppSpacing.l, leading: AppSpacing.l, bottom: AppSpacing.xs, trailing: AppSpacing.l))
    }

    private func comparisonRow(_ comparison: StoreComparison, isCheapest: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(comparison.store.displayName)
                    .font(AppFont.rowTitle())
                    .foregroundStyle(isCheapest ? Color.accentSuccess : Color.ink)
                Text(comparison.entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textMuted)
            }
            Spacer()
            Text("\(comparison.unitPrice.value.currencyString)/\(comparison.unitPrice.unitLabel)")
                .font(AppFont.price())
                .foregroundStyle(isCheapest ? Color.accentSuccess : Color.ink)
        }
    }

    private func entryRow(_ entry: PriceEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(entry.store.displayName)
                    .font(AppFont.rowTitle())
                    .foregroundStyle(Color.ink)
                Text("\(quantityLabel(entry)) · \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(entry.price.currencyString)
                .font(AppFont.rowTitle())
                .foregroundStyle(Color.ink)
        }
    }

    private func quantityLabel(_ entry: PriceEntry) -> String {
        let qty = entry.quantity
        let qtyString = qty.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(qty)) : String(format: "%.2f", qty)
        return "\(qtyString) \(entry.unit.shortLabel)"
    }
}

private extension View {
    /// Flat, borderless list row on the cream page with a hairline divider.
    func rowStyle() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparatorTint(Color.borderCard)
            .listRowInsets(EdgeInsets(top: AppSpacing.m, leading: AppSpacing.l, bottom: AppSpacing.m, trailing: AppSpacing.l))
    }
}
