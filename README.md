# CIImageHistogram

A Swift Package that provides utilities for calculating the luminance histogram of a `CIImage`. The library supports images with high dynamic range values up to 16 and builds as a dynamic library for both iOS (16.2+) and macOS (12.0+).

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
let histogram = CIImageHistogram.histogram(for: image, bins: 256)
```

The resulting array contains the count of pixels in each luminance bin from 0 to the provided `maxPixelValue` (default is 16).

