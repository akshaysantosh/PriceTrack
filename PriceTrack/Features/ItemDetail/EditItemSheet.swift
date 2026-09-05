import SwiftUI

struct EditItemSheet: View {
    @Bindable var item: GroceryItem
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var category: String

    init(item: GroceryItem) {
        self.item = item
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Item name", text: $name)
                    TextField("Category (optional)", text: $category)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        item.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        item.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
