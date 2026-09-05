import SwiftUI
import SwiftData
import Foundation

struct ItemDetailView: View {
    @Bindable var item: GroceryItem
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddPrice = false
    @State private var showingEditItem = false

    private var comparisons: [StoreComparison] {
        PriceNormalizer.latestUnitPricesByStore(for: item)
    }

    private var sortedEntries: [PriceEntry] {
        (item.priceEntries ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                    if !item.category.isEmpty {
                        Text(item.category.uppercased())
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textMuted)
                    }

                    if let cheapest = comparisons.first {
                        StatTile(
                            value: "\(cheapest.unitPrice.value.currencyString)/\(cheapest.unitPrice.unitLabel)",
                            label: "Cheapest now · \(cheapest.store.displayName)",
                            valueColor: .accentSuccess
                        )
                    }

                    if !comparisons.isEmpty {
                        SectionLabel(text: "Compare by store")
                        CardView {
                            VStack(spacing: 10) {
                                ForEach(comparisons) { comparison in
                                    comparisonRow(comparison, isCheapest: comparison.id == comparisons.first?.id)
                                }
                            }
                        }
                    }

                    if sortedEntries.count > 1 {
                        SectionLabel(text: "Price history")
                        CardView {
                            PriceHistoryChart(entries: sortedEntries)
                                .frame(height: 180)
                        }
                    }

                    if sortedEntries.isEmpty {
                        CalloutBanner(text: "No prices logged yet. Scan a receipt or add one manually.")
                    } else {
                        SectionLabel(text: "Logged prices")
                    }
                }
            }
            .listRowBackground(Color.bgPage)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())

            if !sortedEntries.isEmpty {
                Section {
                    ForEach(sortedEntries) { entry in
                        entryRow(entry)
                            .listRowBackground(Color.bgCard)
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
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.bgPage)
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    item.isFavorite.toggle()
                } label: {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(Color.accent)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddPrice = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditItem = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingAddPrice) {
            AddPriceSheet(item: item)
        }
        .sheet(isPresented: $showingEditItem) {
            EditItemSheet(item: item)
        }
    }

    private func comparisonRow(_ comparison: StoreComparison, isCheapest: Bool) -> some View {
        HStack {
            Text(comparison.store.displayName)
                .font(AppFont.body())
                .fontWeight(isCheapest ? .bold : .regular)
                .foregroundStyle(isCheapest ? Color.accentSuccess : Color.bodyText)
            Spacer()
            Text("\(comparison.unitPrice.value.currencyString)/\(comparison.unitPrice.unitLabel)")
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(isCheapest ? Color.accentSuccess : Color.bodyText)
            Text(comparison.entry.date, style: .date)
                .font(AppFont.caption())
                .foregroundStyle(Color.textFaint)
        }
    }

    private func entryRow(_ entry: PriceEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.store.displayName)
                    .font(AppFont.body())
                    .foregroundStyle(Color.ink)
                Text("\(quantityLabel(entry)) · \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(entry.price.currencyString)
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(Color.ink)
        }
        .padding(.vertical, 4)
    }

    private func quantityLabel(_ entry: PriceEntry) -> String {
        let qty = entry.quantity
        let qtyString = qty.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(qty)) : String(format: "%.2f", qty)
        return "\(qtyString) \(entry.unit.shortLabel)"
    }
}
