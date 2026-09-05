import Foundation
import UIKit

struct ParsedReceiptItem {
    let name: String
    let price: Decimal
    let quantity: Double
    let unit: UnitType
}

enum ClaudeReceiptParser {
    struct ParseResult {
        let items: [ParsedReceiptItem]
        let storeGuess: Store?
    }

    enum ParseError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "No Claude API key set."
            case .invalidResponse: return "Couldn't understand Claude's response."
            case .apiError(let message): return message
            }
        }
    }

    static func parse(image: UIImage) async throws -> ParseResult {
        guard let apiKey = KeychainStore.load(), !apiKey.isEmpty else {
            throw ParseError.noAPIKey
        }
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            throw ParseError.invalidResponse
        }
        let base64Image = jpegData.base64EncodedString()
        let storeNames = Store.allCases.map { $0.displayName }.joined(separator: ", ")

        let prompt = """
        You are reading a photo of a grocery receipt. Extract every purchased grocery line item — \
        skip subtotals, totals, tax/GST lines, surcharges, loyalty numbers, payment/card details, and \
        non-grocery lines like bag fees or coupons.

        For each item return:
        - "name": a short, human-readable item name (e.g. "A2 Milk 2L"), not the raw receipt abbreviation.
        - "price": the price actually paid for that line, as a plain decimal number, net of any per-line discount.
        - "quantity": a number.
        - "unit": one of exactly these strings: "litre", "millilitre", "gram", "kilogram", "each", "dozen".
        If a pack size is shown (e.g. "700g", "2L"), use that as quantity + unit. If priced by weight \
        (e.g. "$4.99/kg"), use the actual weight purchased and its unit. Otherwise use quantity 1 and unit "each".

        Also guess which store this receipt is from, if you can tell, choosing the closest match from this \
        list: \(storeNames). Omit "store" entirely if you can't tell.

        Respond with ONLY valid JSON, no other text, no markdown code fences, in exactly this shape:
        {"store": "Aldi", "items": [{"name": "A2 Milk 2L", "price": 7.29, "quantity": 2, "unit": "litre"}]}
        """

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-5",
            "max_tokens": 2048,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ParseError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { $0["error"] as? [String: Any] }
                .flatMap { $0["message"] as? String } ?? "Request failed (HTTP \(httpResponse.statusCode))"
            throw ParseError.apiError(message)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String else {
            throw ParseError.invalidResponse
        }

        return try parseModelOutput(text)
    }

    private static func parseModelOutput(_ text: String) throws -> ParseResult {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsJSON = json["items"] as? [[String: Any]] else {
            throw ParseError.invalidResponse
        }

        let storeGuess = (json["store"] as? String).flatMap { name in
            Store.allCases.first { $0.displayName.caseInsensitiveCompare(name) == .orderedSame }
        }

        let items: [ParsedReceiptItem] = itemsJSON.compactMap { itemJSON in
            guard let name = itemJSON["name"] as? String,
                  let priceNumber = itemJSON["price"] as? NSNumber,
                  let quantityNumber = itemJSON["quantity"] as? NSNumber,
                  let unitString = itemJSON["unit"] as? String,
                  let unit = UnitType(rawValue: unitString) else {
                return nil
            }
            return ParsedReceiptItem(
                name: name,
                price: priceNumber.decimalValue,
                quantity: quantityNumber.doubleValue,
                unit: unit
            )
        }

        return ParseResult(items: items, storeGuess: storeGuess)
    }
}
