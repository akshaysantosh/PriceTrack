import SwiftUI
import SwiftData
import UIKit

struct ReceiptDetailView: View {
    @Bindable var receipt: Receipt
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirm = false

    private var entries: [PriceEntry] {
        (receipt.priceEntries ?? []).sorted { ($0.item?.name ?? "") < ($1.item?.name ?? "") }
    }

    private var total: Decimal {
        entries.reduce(Decimal(0)) { $0 + $1.price }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                    if let data = receipt.receiptImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppMetrics.cardRadius)
                                    .stroke(Color.borderCard, lineWidth: 1)
                            )
                    }

                    StatTile(
                        value: total.currencyString,
                        label: "\(receipt.store.displayName) · \(receipt.date.formatted(date: .abbreviated, time: .omitted))",
                        valueColor: .accent
                    )
                }
            }
            .listRowBackground(Color.bgPage)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())

            if !entries.isEmpty {
                Section {
                    ForEach(entries) { entry in
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete this whole receipt?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Receipt", role: .destructive) {
                modelContext.delete(receipt)
                dismiss()
            }
        } message: {
            Text("This removes all \(entries.count) logged item\(entries.count == 1 ? "" : "s") from this receipt. This can't be undone.")
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: PriceEntry) -> some View {
        if let item = entry.item {
            NavigationLink {
                ItemDetailView(item: item)
            } label: {
                entryRowContent(entry)
            }
        } else {
            entryRowContent(entry)
        }
    }

    private func entryRowContent(_ entry: PriceEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.item?.name ?? "Unknown item")
                    .font(AppFont.body())
                    .foregroundStyle(Color.ink)
                Text(quantityLabel(entry))
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
