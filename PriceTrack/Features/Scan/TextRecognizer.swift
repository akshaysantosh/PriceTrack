import Foundation
import Vision
import UIKit

enum TextRecognizer {
    /// Recognizes text in the image and returns lines ordered top-to-bottom, matching receipt reading order.
    static func recognizeLines(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                    continuation.resume(returning: [])
                    return
                }
                // Vision's coordinate origin is bottom-left; sort descending on y to read top-to-bottom.
                let sorted = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
                let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            // A UIImage's pixel buffer is often stored sideways/rotated relative to how it's
            // displayed (that's what .imageOrientation encodes) — cgImage strips that tag off,
            // so it must be passed to Vision explicitly or it reads the raw, wrongly-oriented
            // pixels. Without this, recognition on real camera/photo-library images is unreliable:
            // it silently drops or garbles many lines instead of failing loudly.
            let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) ?? .up
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    /// Best-effort guess at a trailing dollar amount on a receipt line, e.g. "MILK A2 2L   $5.50" -> 5.50.
    /// This only pre-fills a suggestion in the assign sheet — the user always confirms/edits it.
    static func guessedPrice(in line: String) -> Decimal? {
        let pattern = #"\$?\s?(\d+\.\d{2})\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              let valueRange = Range(match.range(at: 1), in: line) else { return nil }
        return Decimal(string: String(line[valueRange]))
    }
}
