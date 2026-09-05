import SwiftUI
import SwiftData

struct ReceiptReviewView: View {
    let lines: [String]
    let receiptImageData: Data?

    @State private var store: Store = .woolworths
    @State private var date: Date = Date()
    @State private var assignedLines: Set<Int> = []
    @State private var activeLine: LineSelection?
    @State private var receipt: Receipt?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private struct LineSelection: Identifiable {
        let id: Int
    }

    init(image: UIImage, lines: [String]) {
        self.lines = lines
        self.receiptImageData = image.compressedForReceipt()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppMetrics.cardSpacing) {
                CardView {
                    SectionLabel(text: "Receipt details")

                    HStack {
                        Text("Store")
                            .font(AppFont.body())
                            .foregroundStyle(Color.bodyText)
                        Spacer()
                        Picker("Store", selection: $store) {
                            ForEach(Store.allCases) { store in
                                Text(store.displayName).tag(store)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Color.accent)
                    }
                    .padding(.top, 4)
                    .onChange(of: store) { _, newValue in receipt?.store = newValue }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .padding(.top, 8)
                        .onChange(of: date) { _, newValue in receipt?.date = newValue }
                }

                SectionLabel(text: "Tap a line to log it")

                CardView {
                    VStack(spacing: 0) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            if index > 0 {
                                Divider().overlay(Color.borderCard)
                            }
                            Button {
                                activeLine = LineSelection(id: index)
                            } label: {
                                lineRow(line, index: index)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primary(.accentSuccess))
                .padding(.top, 4)
            }
            .padding(16)
        }
        .background(Color.bgPage)
        .navigationTitle("Review Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeLine) { selection in
            AssignLineSheet(
                rawLine: lines[selection.id],
                store: store,
                date: date,
                receipt: ensureReceipt(),
                onSaved: { assignedLines.insert(selection.id) }
            )
        }
    }

    /// Creates (once) and returns the shared Receipt for this scan session, so every line
    /// assigned from this review links to the same receipt instead of standing alone.
    private func ensureReceipt() -> Receipt {
        if let receipt { return receipt }
        let newReceipt = Receipt(store: store, date: date, receiptImageData: receiptImageData)
        modelContext.insert(newReceipt)
        receipt = newReceipt
        return newReceipt
    }

    private func lineRow(_ line: String, index: Int) -> some View {
        HStack {
            Image(systemName: assignedLines.contains(index) ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(assignedLines.contains(index) ? Color.accentSuccess : Color.textFaint)
            Text(line)
                .font(AppFont.body())
                .foregroundStyle(assignedLines.contains(index) ? Color.textMuted : Color.bodyText)
                .strikethrough(assignedLines.contains(index))
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
