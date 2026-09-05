import SwiftUI
import SwiftData

struct ReceiptsView: View {
    @Query(sort: \Receipt.date, order: .reverse) private var receipts: [Receipt]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageHeader(title: "Receipts")
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

            if receipts.isEmpty {
                CalloutBanner(text: "No receipts yet. Anything you log through Scan will show up here as a group, so you can see — or undo — a whole shop at once.")
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                List {
                    ForEach(receipts) { receipt in
                        NavigationLink(value: receipt) {
                            ReceiptRow(receipt: receipt)
                        }
                        .listRowBackground(Color.bgCard)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(receipt)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Receipt.self) { receipt in
            ReceiptDetailView(receipt: receipt)
        }
        .navigationDestination(for: GroceryItem.self) { item in
            ItemDetailView(item: item)
        }
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
            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.store.displayName)
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.ink)
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s") · \(receipt.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(total.currencyString)
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(Color.ink)
        }
        .padding(.vertical, 4)
    }
}
