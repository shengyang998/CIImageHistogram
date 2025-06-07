import XCTest
import CoreImage
@testable import CIImageHistogram

final class CIImageHistogramTests: XCTestCase {
    func testHistogramContainsPixelCount() {
        let width = 2
        let height = 2
        let pixels: [Float] = [
            0, 0, 0, 1,
            1, 1, 1, 1,
            2, 2, 2, 1,
            3, 3, 3, 1
        ]
        let data = Data(bytes: pixels, count: pixels.count * MemoryLayout<Float>.size)
        let bitmap = CIImage(bitmapData: data,
                             bytesPerRow: width * 4 * MemoryLayout<Float>.size,
                             size: CGSize(width: width, height: height),
                             format: .RGBAf,
                             colorSpace: CGColorSpaceCreateDeviceRGB())
        let histogram = CIImageHistogram.histogram(for: bitmap, bins: 4, maxPixelValue: 3)
        XCTAssertEqual(histogram.reduce(0, +), 4)
    }
}

