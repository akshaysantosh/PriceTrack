import SwiftUI
import UIKit

/// The page background: warm off-white paper (`Color.bgPage`, #F8F6F1) with a very faint, fine
/// grain. The grain is a small noise tile generated once and repeated, drawn as warm-dark specks
/// at a few percent opacity so it reads as texture, not pattern.
struct PaperBackground: View {
    /// The tone under the grain. Defaults to the shared page tone; a screen with its own tint
    /// (e.g. a per-character menu colour) can pass `PaperGrain.lifted(_:)` of that tint.
    var base: Color = PaperGrain.base

    var body: some View {
        ZStack {
            base
            Image(uiImage: PaperGrain.tile)
                .interpolation(.none)
                .resizable(resizingMode: .tile)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

enum PaperGrain {
    /// Tweak these to taste: `maxAlpha` is how dark the strongest speck gets (0–255).
    private static let maxAlpha: UInt8 = 64
    /// Fraction of pixels that get a speck at all — sparse flecks read as grain, where a speck on
    /// every pixel just reads as a flat grey.
    private static let coverage = 0.28
    /// The specks darken the page slightly on average, so the base is lifted a touch to land the
    /// overall tone on `Color.bgPage` (#F8F6F1).
    static let base = Color(hex: "#fdfbf7")
    /// A 128px tile drawn at 1.5x, so each speck is two physical pixels wide on a 3x screen —
    /// coarse enough to be seen at arm's length, still fine enough to read as grain.
    private static let side = 128
    private static let scale: CGFloat = 1.5

    /// Lifts a tone by the same amount `base` is lifted over `Color.bgPage`, so a custom tint
    /// keeps its overall look once the grain darkens it slightly.
    static func lifted(red: Double, green: Double, blue: Double) -> Color {
        Color(red: min(1, red + 5.0 / 255), green: min(1, green + 5.5 / 255), blue: min(1, blue + 6.5 / 255))
    }

    static let tile: UIImage = {
        var generator = SeededGenerator(seed: 0x9E3779B97F4A7C15)
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        for i in 0..<(side * side) {
            // Premultiplied RGBA: a warm brown speck with random strength; most are very light.
            let hasSpeck = Double.random(in: 0..<1, using: &generator) < coverage
            let strength: UInt8 = hasSpeck ? UInt8.random(in: 1...maxAlpha, using: &generator) : 0
            let alpha = Int(strength)
            pixels[i * 4 + 0] = UInt8(alpha * 90 / 255)
            pixels[i * 4 + 1] = UInt8(alpha * 70 / 255)
            pixels[i * 4 + 2] = UInt8(alpha * 45 / 255)
            pixels[i * 4 + 3] = strength
        }
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        let cgImage = CGImage(
            width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent
        )!
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }()
}

/// Deterministic noise, so the grain is identical on every launch.
private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
