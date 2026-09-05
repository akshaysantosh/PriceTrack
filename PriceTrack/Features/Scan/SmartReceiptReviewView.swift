import SwiftUI
import SwiftData
import UIKit

/// Review screen for Claude-parsed receipt items: unlike ReceiptReviewView (raw OCR lines you
/// tap one at a time and fill in by hand), items here already come paired with name/price/qty/unit
/// — you just uncheck anything wrong and save the rest in one go.
struct SmartReceiptReviewView: View {
    let parsedItems: [ParsedReceiptItem]
    let receiptImageData: Data?

    @State private var store: Store
    @State private var date = Date()
    @State private var selections: Set<Int>

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(image: UIImage, parsedItems: [ParsedReceiptItem], storeGuess: Store?) {
        self.parsedItems = parsedItems
        self.receiptImageData = image.compressedForReceipt()
        _store = State(initialValue: storeGuess ?? .woolworths)
        _selections = State(initialValue: Set(parsedItems.indices))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                PageHeader(title: "Confirm Items")

                CardView {
                    SectionLabel(text: "Receipt details")

                    HStack {
                        Text("Store")
                            .font(AppFont.body())
                            .foregroundStyle(Color.bodyText)
                        Spacer()
                        Picker("Store", selection: $store) {
                            ForEach(Store.allCases) { s in
                                Text(s.displayName).tag(s)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.accent)
                    }
                    .padding(.top, 4)

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .padding(.top, 8)
                }

                if parsedItems.isEmpty {
                    CalloutBanner(text: "Claude couldn't find any grocery items on that photo. Try a clearer photo, or use manual entry instead.", style: .warn)
                } else {
                    SectionLabel(text: "\(selections.count) of \(parsedItems.count) items selected")

                    CardView {
                        VStack(spacing: 0) {
                            ForEach(Array(parsedItems.enumerated()), id: \.offset) { index, item in
                                if index > 0 {
                                    Divider().overlay(Color.borderCard)
                                }
                                Button {
                                    toggle(index)
                                } label: {
                                    itemRow(item, selected: selections.contains(index))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {
                        saveSelected()
                    } label: {
                        Text("Save \(selections.count) Item\(selections.count == 1 ? "" : "s")")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primary(.accentSuccess))
                    .disabled(selections.isEmpty)
                }
            }
            .padding(16)
        }
        .background(Color.bgPage)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ index: Int) {
        if selections.contains(index) {
            selections.remove(index)
        } else {
            selections.insert(index)
        }
    }

    private func itemRow(_ item: ParsedReceiptItem, selected: Bool) -> some View {
        HStack {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? Color.accentSuccess : Color.textFaint)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(AppFont.body())
                    .foregroundStyle(selected ? Color.bodyText : Color.textMuted)
                Text(quantityLabel(item))
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(item.price.currencyString)
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(selected ? Color.ink : Color.textMuted)
        }
        .padding(.vertical, 8)
    }

    private func quantityLabel(_ item: ParsedReceiptItem) -> String {
        let qty = item.quantity
        let qtyString = qty.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(qty)) : String(format: "%.2f", qty)
        return "\(qtyString) \(item.unit.shortLabel)"
    }

    private func saveSelected() {
        let existing = (try? modelContext.fetch(FetchDescriptor<GroceryItem>())) ?? []
        var itemsByName: [String: GroceryItem] = Dictionary(uniqueKeysWithValues: existing.map { ($0.name, $0) })

        let receipt = Receipt(store: store, date: date, receiptImageData: receiptImageData)
        modelContext.insert(receipt)

        for index in selections {
            let parsed = parsedItems[index]
            let groceryItem: GroceryItem
            if let existingItem = itemsByName[parsed.name] {
                groceryItem = existingItem
            } else {
                groceryItem = GroceryItem(name: parsed.name, category: CategoryClassifier.guess(for: parsed.name) ?? "")
                modelContext.insert(groceryItem)
                itemsByName[parsed.name] = groceryItem
            }
            let entry = PriceEntry(
                store: store, price: parsed.price, quantity: parsed.quantity,
                unit: parsed.unit, date: date, item: groceryItem, receipt: receipt
            )
            modelContext.insert(entry)
        }
        dismiss()
    }
}
