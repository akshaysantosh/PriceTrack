import SwiftUI
import SwiftData
import Foundation

/// Confirms/edits one OCR'd receipt line into a saved PriceEntry: pick or create the item,
/// then set price/quantity/unit (price is pre-filled with a best-effort guess from the line).
struct AssignLineSheet: View {
    let rawLine: String
    let store: Store
    let date: Date
    var receipt: Receipt? = nil
    var onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: GroceryItem?
    @State private var priceText: String = ""
    @State private var quantityText: String = "1"
    @State private var unitFamily: UnitFamily = .count
    @State private var unit: UnitType = .each

    private var priceValue: Decimal? { Decimal(string: priceText) }
    private var quantityValue: Double? { Double(quantityText) }
    private var canSave: Bool {
        selectedItem != nil && (priceValue.map { $0 > 0 } ?? false) && (quantityValue.map { $0 > 0 } ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Receipt line") {
                    Text(rawLine)
                        .font(AppFont.secondaryDetail())
                        .foregroundStyle(Color.textSecondary)
                }

                Section("Item") {
                    ItemPicker(selectedItem: $selectedItem)
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
            .navigationTitle("Assign Line")
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
            .onAppear(perform: prefill)
        }
    }

    private func prefill() {
        guard priceText.isEmpty, let guess = TextRecognizer.guessedPrice(in: rawLine) else { return }
        priceText = NSDecimalNumber(decimal: guess).stringValue
    }

    private func save() {
        guard let selectedItem, let priceValue, let quantityValue else { return }
        let entry = PriceEntry(
            store: store,
            price: priceValue,
            quantity: quantityValue,
            unit: unit,
            date: date,
            item: selectedItem,
            receipt: receipt
        )
        modelContext.insert(entry)
        onSaved()
        dismiss()
    }
}
