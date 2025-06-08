# CIImageHistogram

A Swift Package that provides utilities for calculating RGB histograms of a `CIImage`. Histogram generation uses **Metal Performance Shaders** when available for fast processing of high dynamic range images up to a linear value of 16. The package builds as a dynamic library for both iOS (16.2+) and macOS (12.0+).

## Usage

Add the package as a dependency in your `Package.swift`:

```swift
.package(url: "https://example.com/CIImageHistogram.git", from: "1.0.0")
```

Import the library and compute a histogram:

```swift
import CIImageHistogram
import CoreImage

let image = CIImage(contentsOf: url)!
let rgbHist = CIImageHistogram.histogram(for: image, bins: 256)
let redBins = rgbHist[0]
```

The resulting value is a 2D array where the first dimension corresponds to the red, green and blue channels. Each sub array contains the count of pixels in each bin from 0 to the provided `maxPixelValue` (default is 16).

## Displaying a Histogram

`HistogramLayer` is a `CALayer` subclass included in the package that draws the RGB histogram for a `CIImage`. The example below downloads an image from the internet and shows how to display its histogram:

```swift
import CIImageHistogram
import CoreImage

let url = URL(string: "https://upload.wikimedia.org/wikipedia/commons/3/3c/Shaki_waterfall.jpg")!
let data = try Data(contentsOf: url)
let ciImage = CIImage(data: data)!

let layer = HistogramLayer()
layer.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
layer.image = ciImage
```

Add the layer to your view's layer hierarchy to visualize the histogram.

On displays that support Extended Dynamic Range (EDR), `HistogramLayer` draws an
additional indicator on the right half of the view. A red overlay means no extra
headroom is available. When EDR headroom is present, a white overlay appears and
its width shrinks as the current headroom increases.

On iOS, the layer uses `UIScreen`'s `potentialEDRHeadroom` and
`currentEDRHeadroom` APIs (falling back to the older extended-dynamic-range
properties on earlier releases) to determine available headroom. macOS exposes
similar information via `NSScreen` using the matching EDR headroom properties or
the legacy `maximumPotentialExtendedDynamicRangeColorComponentValue`.

