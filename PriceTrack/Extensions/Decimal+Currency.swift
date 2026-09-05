import Foundation

extension Decimal {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: self as NSDecimalNumber) ?? "$\(self)"
    }
}
