import SwiftUI
import SwiftData
import Foundation

/// Logs a price without a receipt scan. Pass `item` when launched from an item's detail screen
/// (item is fixed); pass `nil` when launched from "add new item" so the user can search-or-create.
struct AddPriceSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let presetItem: GroceryItem?

    @State private var selectedItem: GroceryItem?
    @State private var store: Store = .woolworths
    @State private var priceText: String = ""
    @State private var quantityText: String = "1"
    @State private var unitFamily: UnitFamily = .count
    @State private var unit: UnitType = .each
    @State private var date: Date = Date()

    init(item: GroceryItem?) {
        self.presetItem = item
        _selectedItem = State(initialValue: item)
    }

    private var priceValue: Decimal? {
        Decimal(string: priceText)
    }

    private var quantityValue: Double? {
        Double(quantityText)
    }

    private var canSave: Bool {
        selectedItem != nil && (priceValue.map { $0 > 0 } ?? false) && (quantityValue.map { $0 > 0 } ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    if let presetItem {
                        Text(presetItem.name)
                            .foregroundStyle(Color.ink)
                    } else {
                        ItemPicker(selectedItem: $selectedItem)
                    }
                }

                Section("Store & date") {
                    Picker("Store", selection: $store) {
                        ForEach(Store.allCases) { store in
                            Text(store.displayName).tag(store)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Price & quantity") {
                    TextField("Price paid (e.g. 5.50)", text: $priceText)
                        .keyboardType(.decimalPad)

                    Picker("Unit type", selection: $unitFamily) {
                        Text("Volume").tag(UnitFamily.volume)
                        Text("Weight").tag(UnitFamily.weight)
                        Text("Count").tag(UnitFamily.count)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: unitFamily) { _, newValue in
                        unit = UnitType.options(for: newValue).first ?? .each
                    }

                    HStack {
                        TextField("Quantity", text: $quantityText)
                            .keyboardType(.decimalPad)
                        Picker("Unit", selection: $unit) {
                            ForEach(UnitType.options(for: unitFamily)) { unit in
                                Text(unit.shortLabel).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("Log a Price")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard let selectedItem, let priceValue, let quantityValue else { return }
        let entry = PriceEntry(store: store, price: priceValue, quantity: quantityValue, unit: unit, date: date, item: selectedItem)
        modelContext.insert(entry)
        dismiss()
    }
}
