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
            hero
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: AppSpacing.s, leading: AppSpacing.l, bottom: AppSpacing.s, trailing: AppSpacing.l))

            if !entries.isEmpty {
                SectionLabel(text: "Items")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: AppSpacing.l, leading: AppSpacing.l, bottom: AppSpacing.xs, trailing: AppSpacing.l))

                ForEach(entries) { entry in
                    entryRow(entry)
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.borderCard)
                        .listRowInsets(EdgeInsets(top: AppSpacing.m, leading: AppSpacing.l, bottom: AppSpacing.m, trailing: AppSpacing.l))
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
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete receipt", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.ink)
                }
                .accessibilityLabel("More actions")
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

    private var hero: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            if let data = receipt.receiptImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(receipt.store.displayName)
                    .font(AppFont.detailTitle())
                    .foregroundStyle(Color.ink)
                Text("\(receipt.date.formatted(date: .abbreviated, time: .omitted)) · \(entries.count) item\(entries.count == 1 ? "" : "s")")
                    .font(AppFont.secondaryDetail())
                    .foregroundStyle(Color.textSecondary)
            }

            Text(total.currencyString)
                .font(AppFont.heroPrice())
                .foregroundStyle(Color.ink)
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: PriceEntry) -> some View {
        if let item = entry.item {
            ZStack {
                entryRowContent(entry)
                NavigationLink {
                    ItemDetailView(item: item)
                } label: { EmptyView() }
                .opacity(0)
            }
        } else {
            entryRowContent(entry)
        }
    }

    private func entryRowContent(_ entry: PriceEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(entry.item?.name ?? "Unknown item")
                    .font(AppFont.rowTitle())
                    .foregroundStyle(Color.ink)
                Text(quantityLabel(entry))
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
