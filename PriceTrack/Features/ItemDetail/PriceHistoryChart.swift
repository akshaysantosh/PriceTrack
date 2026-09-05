import SwiftUI
import Charts
import Foundation

struct PriceHistoryChart: View {
    let entries: [PriceEntry]

    private struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let unitPrice: Decimal
        let store: Store
    }

    private var points: [Point] {
        entries.compactMap { entry in
            guard let up = PriceNormalizer.unitPrice(for: entry) else { return nil }
            return Point(date: entry.date, unitPrice: up.value, store: entry.store)
        }
    }

    // chartForegroundStyleScale needs a KeyValuePairs literal, not a Dictionary — Store has a
    // fixed 4 cases, so this is written out directly rather than built from Store.allCases.
    private var colorScale: KeyValuePairs<String, Color> {
        [
            Store.aldi.displayName: Store.aldi.chartColor,
            Store.coles.displayName: Store.coles.chartColor,
            Store.woolworths.displayName: Store.woolworths.chartColor,
            Store.costco.displayName: Store.costco.chartColor,
        ]
    }

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Unit price", NSDecimalNumber(decimal: point.unitPrice).doubleValue)
            )
            .foregroundStyle(by: .value("Store", point.store.displayName))
            .symbol(by: .value("Store", point.store.displayName))
            .interpolationMethod(.catmullRom)
        }
        .chartForegroundStyleScale(colorScale)
        .chartLegend(position: .bottom, spacing: 8)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}
