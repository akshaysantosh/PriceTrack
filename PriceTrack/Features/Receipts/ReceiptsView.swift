import SwiftUI
import SwiftData

struct ReceiptsView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var receipts: [Receipt]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var scanner: IncomingReceiptCoordinator

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                if receipts.isEmpty {
                    EmptyStateView(
                        symbolName: "receipt",
                        message: "No receipts yet. Anything you scan shows up here as a group, so you can see — or undo — a whole shop at once.",
                        actionTitle: "Scan a receipt"
                    ) {
                        if scanner.cameraAvailable {
                            scanner.showingCamera = true
                        } else {
                            scanner.showingPhotoPicker = true
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(receipts) { receipt in
                        ZStack {
                            ReceiptRow(receipt: receipt)
                            NavigationLink(value: receipt) { EmptyView() }
                                .opacity(0)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.borderCard)
                    .listRowSeparator(.hidden, edges: .top)
                        .listRowInsets(EdgeInsets(top: AppSpacing.m, leading: AppSpacing.l, bottom: AppSpacing.m, trailing: AppSpacing.l))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(receipt)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(receipt)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.bottom, 88, for: .scrollContent)

            FloatingScanButton()
                .padding(.trailing, AppSpacing.l + AppSpacing.xs)
                .padding(.bottom, AppSpacing.l)
        }
        .background(PaperBackground())
        .navigationTitle("Receipts")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Receipt.self) { receipt in
            ReceiptDetailView(receipt: receipt)
        }
        .navigationDestination(for: GroceryItem.self) { item in
            ItemDetailView(item: item)
        }
        .settingsSheet()
    }
}

private struct ReceiptRow: View {
    let receipt: Receipt

    private var total: Decimal {
        (receipt.priceEntries ?? []).reduce(Decimal(0)) { $0 + $1.price }
    }

    private var itemCount: Int {
        (receipt.priceEntries ?? []).count
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(receipt.store.displayName)
                    .font(AppFont.rowTitle())
                    .foregroundStyle(Color.ink)
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s") · \(receipt.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(total.currencyString)
                .font(AppFont.price())
                .foregroundStyle(Color.ink)
        }
    }
}
