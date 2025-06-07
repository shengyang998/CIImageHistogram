import CoreImage
import Accelerate
#if canImport(MetalPerformanceShaders)
import Metal
import MetalPerformanceShaders
#endif

public struct CIImageHistogram {
    /// Computes the RGB histograms of a CIImage.
    /// - Parameters:
    ///   - image: Source CIImage.
    ///   - bins: Number of histogram bins.
    ///   - maxPixelValue: Maximum possible pixel intensity value. Defaults to 16 for HDR images.
    ///   - context: Optional CIContext. Defaults to a new context.
    /// - Returns: A 2D array where the first dimension represents color
    ///   channels `[R, G, B]` and each sub array contains `bins` histogram
    ///   counts for that channel.
    public static func histogram(
        for image: CIImage,
        bins: Int = 256,
        maxPixelValue: Float = 16,
        context: CIContext = CIContext(options: nil)
    ) -> [[Float]] {
        let extent = image.extent.integral
        guard !extent.isEmpty, bins > 0 else { return [] }

#if canImport(MetalPerformanceShaders) && (os(iOS) || os(macOS))
        if let device = context.device ?? MTLCreateSystemDefaultDevice(),
           let commandQueue = device.makeCommandQueue() {
            var info = MPSImageHistogramInfo(
                numberOfHistogramEntries: bins,
                histogramForAlpha: false,
                minPixelValue: vector_float4(0, 0, 0, 0),
                maxPixelValue: vector_float4(maxPixelValue, maxPixelValue, maxPixelValue, maxPixelValue)
            )
            let histogramKernel = MPSImageHistogram(device: device, histogramInfo: &info)
            let histogramSize = histogramKernel.histogramSize(forSourceFormat: .rgba32Float)
            guard let histogramBuffer = device.makeBuffer(length: histogramSize, options: [.storageModeShared]) else {
                return []
            }
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .rgba32Float,
                width: Int(extent.width),
                height: Int(extent.height),
                mipmapped: false)
            textureDescriptor.usage = [.shaderRead, .shaderWrite]
            guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
                return []
            }

            context.render(image,
                           to: texture,
                           commandBuffer: nil,
                           bounds: extent,
                           colorSpace: CGColorSpaceCreateDeviceRGB())

            guard let commandBuffer = commandQueue.makeCommandBuffer() else { return [] }
            histogramKernel.encode(to: commandBuffer,
                                  sourceTexture: texture,
                                  histogram: histogramBuffer,
                                  histogramOffset: 0)
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()

            let pointer = histogramBuffer.contents().bindMemory(to: UInt32.self, capacity: bins * 4)
            var rHist = [Float](repeating: 0, count: bins)
            var gHist = [Float](repeating: 0, count: bins)
            var bHist = [Float](repeating: 0, count: bins)
            for i in 0..<bins {
                rHist[i] = Float(pointer[i])
                gHist[i] = Float(pointer[i + bins])
                bHist[i] = Float(pointer[i + bins * 2])
            }
            return [rHist, gHist, bHist]
        }
#endif

        // CPU fallback
        let width = Int(extent.width)
        let height = Int(extent.height)
        let pixels = width * height
        var buffer = [Float](repeating: 0, count: pixels * 4)

        context.render(
            image,
            toBitmap: &buffer,
            rowBytes: width * MemoryLayout<Float>.size * 4,
            bounds: extent,
            format: .RGBAf,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        var rHist = [Float](repeating: 0, count: bins)
        var gHist = [Float](repeating: 0, count: bins)
        var bHist = [Float](repeating: 0, count: bins)
        let binFactor = Float(bins - 1) / maxPixelValue
        for i in stride(from: 0, to: buffer.count, by: 4) {
            let r = buffer[i]
            let g = buffer[i + 1]
            let b = buffer[i + 2]
            let clampedR = max(0, min(maxPixelValue, r))
            let clampedG = max(0, min(maxPixelValue, g))
            let clampedB = max(0, min(maxPixelValue, b))
            let rIndex = Int(clampedR * binFactor)
            let gIndex = Int(clampedG * binFactor)
            let bIndex = Int(clampedB * binFactor)
            rHist[rIndex] += 1
            gHist[gIndex] += 1
            bHist[bIndex] += 1
        }
        return [rHist, gHist, bHist]
    }
}
