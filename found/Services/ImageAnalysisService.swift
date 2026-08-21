import Vision
import UIKit

// MARK: - ImageAnalysisService
// Uses Apple's Vision framework to extract characteristics from photos.
// Results are ALWAYS editable by the user — never presented as guaranteed facts.

protocol ImageAnalysisServiceProtocol {
    func analyze(imageData: Data) async -> ImageAnalysisResult
}

struct ImageAnalysisResult {
    var suggestedCategory: ItemCategory?
    var dominantColors: [String]
    var objectLabels: [String]         // broad human-readable descriptions
    var confidence: Double             // overall analysis confidence
    var isAvailable: Bool              // false if Vision failed or no data

    static let unavailable = ImageAnalysisResult(
        suggestedCategory: nil,
        dominantColors: [],
        objectLabels: [],
        confidence: 0,
        isAvailable: false
    )
}

final class ImageAnalysisService: ImageAnalysisServiceProtocol {

    func analyze(imageData: Data) async -> ImageAnalysisResult {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return .unavailable
        }

        async let classificationResult = classifyImage(cgImage)
        async let colorResult = analyzeDominantColors(image)

        let (labels, confidence) = await classificationResult
        let colors = await colorResult
        let category = inferCategory(from: labels)

        return ImageAnalysisResult(
            suggestedCategory: category,
            dominantColors: colors,
            objectLabels: labels,
            confidence: confidence,
            isAvailable: true
        )
    }

    // MARK: - Classification

    private func classifyImage(_ cgImage: CGImage) async -> ([String], Double) {
        await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard error == nil,
                      let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: ([], 0))
                    return
                }

                let top = results
                    .filter { $0.confidence > 0.1 }
                    .prefix(5)
                    .map { self.humanReadable($0.identifier) }

                let avgConfidence = results.prefix(3).reduce(0.0) { $0 + Double($1.confidence) } / 3

                continuation.resume(returning: (Array(top), avgConfidence))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Color Analysis

    private func analyzeDominantColors(_ image: UIImage) async -> [String] {
        // Simple color analysis: sample key pixels and bucket into color names
        guard let cgImage = image.cgImage else { return [] }

        let size = CGSize(width: 20, height: 20)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: Int(size.width * size.height) * 4)

        guard let context = CGContext(
            data: &pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        var colorCounts: [String: Int] = [:]
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = Int(pixelData[i])
            let g = Int(pixelData[i + 1])
            let b = Int(pixelData[i + 2])
            let name = colorName(r: r, g: g, b: b)
            colorCounts[name, default: 0] += 1
        }

        return colorCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }

    // MARK: - Helpers

    private func colorName(r: Int, g: Int, b: Int) -> String {
        let brightness = (r + g + b) / 3
        if brightness < 50 { return "black" }
        if brightness > 200 {
            if r > 200 && g > 200 && b > 200 { return "white" }
        }
        if r > g && r > b { return r - b > 50 ? "red" : "orange" }
        if g > r && g > b { return "green" }
        if b > r && b > g { return b - r > 50 ? "blue" : "purple" }
        if r > 150 && g > 150 && b < 100 { return "yellow" }
        return brightness > 150 ? "white" : "gray"
    }

    private func humanReadable(_ identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespaces)
            .capitalized ?? identifier
    }

    private func inferCategory(from labels: [String]) -> ItemCategory? {
        let lower = labels.joined(separator: " ").lowercased()

        if lower.contains("phone") || lower.contains("laptop") || lower.contains("computer")
            || lower.contains("earphone") || lower.contains("headphone")
            || lower.contains("charger") || lower.contains("electronic")
            || lower.contains("keyboard") || lower.contains("tablet") { return .electronics }

        if lower.contains("bag") || lower.contains("backpack")
            || lower.contains("purse") || lower.contains("wallet") { return .bags }

        if lower.contains("shirt") || lower.contains("jacket") || lower.contains("hoodie")
            || lower.contains("coat") || lower.contains("cloth") { return .clothing }

        if lower.contains("key") || lower.contains("keychain") { return .keys }

        if lower.contains("card") || lower.contains("id") || lower.contains("passport") { return .idCards }

        if lower.contains("book") || lower.contains("notebook") || lower.contains("textbook") { return .books }

        if lower.contains("watch") || lower.contains("glasses") || lower.contains("jewelry")
            || lower.contains("bottle") { return .accessories }

        return nil
    }
}
