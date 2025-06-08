import QuartzCore
import CoreImage
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A CALayer subclass that draws an RGB histogram for a given `CIImage` using
/// `CIImageHistogram`.
public class HistogramLayer: CALayer {
    /// Image for which to draw the histogram. Setting this triggers a redraw.
    public var image: CIImage? {
        didSet { setNeedsDisplay() }
    }

    /// Number of histogram bins. Defaults to 256.
    public var bins: Int = 256 {
        didSet { setNeedsDisplay() }
    }

    /// Maximum pixel value used when computing the histogram. Defaults to 16.
    public var maxPixelValue: Float = 16 {
        didSet { setNeedsDisplay() }
    }

    /// Colors used for the RGB channels.
    public var channelColors: [CGColor] = [
        CGColor(red: 1, green: 0, blue: 0, alpha: 1),
        CGColor(red: 0, green: 1, blue: 0, alpha: 1),
        CGColor(red: 0, green: 0, blue: 1, alpha: 1)
    ] {
        didSet { setNeedsDisplay() }
    }

    /// Returns the screen's potential EDR headroom.
    private var potentialHeadroom: CGFloat {
#if os(iOS) || os(tvOS)
        if #available(iOS 17.0, tvOS 17.0, *) {
            return UIScreen.main.potentialEDRHeadroom
        } else if #available(iOS 16.0, tvOS 16.0, *) {
            return UIScreen.main.maximumExtendedDynamicRangeColorComponentValue
        } else {
            return 1
        }
#elseif os(macOS)
        if #available(macOS 14.0, *) {
            return NSScreen.main?.potentialEDRHeadroom ?? 1
        } else if #available(macOS 12.0, *) {
            return NSScreen.main?.maximumPotentialExtendedDynamicRangeColorComponentValue ?? 1
        } else {
            return 1
        }
#else
        return 1
#endif
    }

    /// Returns the screen's current EDR headroom.
    private var currentHeadroom: CGFloat {
#if os(iOS) || os(tvOS)
        if #available(iOS 17.0, tvOS 17.0, *) {
            return UIScreen.main.currentEDRHeadroom
        } else if #available(iOS 16.0, tvOS 16.0, *) {
            return UIScreen.main.currentExtendedDynamicRangeColorComponentValue
        } else {
            return 1
        }
#elseif os(macOS)
        if #available(macOS 14.0, *) {
            return NSScreen.main?.currentEDRHeadroom ?? 1
        } else if #available(macOS 12.0, *) {
            return NSScreen.main?.currentExtendedDynamicRangeColorComponentValue ?? 1
        } else {
            return 1
        }
#else
        return 1
#endif
    }

    public override init() {
        super.init()
        needsDisplayOnBoundsChange = true
#if os(iOS) || os(tvOS)
        contentsScale = UIScreen.main.scale
#elseif os(macOS)
        contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
#endif
    }

    public override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        needsDisplayOnBoundsChange = true
#if os(iOS) || os(tvOS)
        contentsScale = UIScreen.main.scale
#elseif os(macOS)
        contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
#endif
    }

    public override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        guard
            let image = image,
            bins > 0,
            bounds.width > 0,
            bounds.height > 0
        else { return }

        let histogram = CIImageHistogram.histogram(
            for: image,
            bins: bins,
            maxPixelValue: maxPixelValue
        )

        ctx.saveGState()
        ctx.setLineWidth(max(1, bounds.width / CGFloat(bins)))

        for (channelIndex, binsData) in histogram.enumerated() where channelIndex < channelColors.count {
            let maxCount = binsData.max() ?? 1
            let xStep = bounds.width / CGFloat(binsData.count)
            ctx.setStrokeColor(channelColors[channelIndex])
            ctx.beginPath()
            for (i, count) in binsData.enumerated() {
                let x = CGFloat(i) * xStep + xStep / 2
                let normalized = CGFloat(count) / CGFloat(maxCount)
                let y = normalized * bounds.height
                if i == 0 {
                    ctx.move(to: CGPoint(x: x, y: 0))
                }
                ctx.addLine(to: CGPoint(x: x, y: y))
            }
            ctx.strokePath()
        }
        ctx.restoreGState()

        // Draw headroom indicator on the right half of the histogram.
        ctx.saveGState()
        let halfWidth = bounds.width / 2
        let indicatorRect: CGRect
        if potentialHeadroom <= 1 {
            ctx.setFillColor(red: 1, green: 0, blue: 0, alpha: 0.5)
            indicatorRect = CGRect(x: bounds.midX, y: 0, width: halfWidth, height: bounds.height)
        } else {
            let normalized = max(1, min(8, currentHeadroom))
            let width = halfWidth / normalized
            ctx.setFillColor(gray: 1, alpha: 0.5)
            indicatorRect = CGRect(x: bounds.maxX - width, y: 0, width: width, height: bounds.height)
        }
        ctx.fill(indicatorRect)
        ctx.restoreGState()
    }
}
