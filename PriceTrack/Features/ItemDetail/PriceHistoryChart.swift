import SwiftUI
import Charts
import Foundation

struct PriceHistoryChart: View {
    let entries: [PriceEntry]

    private struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let unitPrice: Double
        let store: Store
    }

    private var points: [Point] {
        entries.compactMap { entry in
            guard let up = PriceNormalizer.unitPrice(for: entry) else { return nil }
            return Point(date: entry.date, unitPrice: NSDecimalNumber(decimal: up.value).doubleValue, store: entry.store)
        }
    }

    /// Only the stores that actually appear in this item's history, in a stable order, so the
    /// legend and colours match the data (the app knows seven stores, not four).
    private var storesPresent: [Store] {
        let present = Set(points.map(\.store))
        return Store.allCases.filter { present.contains($0) }
    }

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Unit price", point.unitPrice)
            )
            .foregroundStyle(by: .value("Store", point.store.displayName))
            .interpolationMethod(.monotone)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Unit price", point.unitPrice)
            )
            .foregroundStyle(by: .value("Store", point.store.displayName))
        }
        .chartForegroundStyleScale(
            domain: storesPresent.map(\.displayName),
            range: storesPresent.map(\.chartColor)
        )
        .chartLegend(position: .bottom, spacing: AppSpacing.s)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}
