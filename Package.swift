// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CIImageHistogram",
    platforms: [
        .iOS("16.2"),
        .macOS("12.0")
    ],
    products: [
        .library(
            name: "CIImageHistogram",
            type: .dynamic,
            targets: ["CIImageHistogram"])
    ],
    targets: [
        .target(
            name: "CIImageHistogram",
            path: "Sources"
        ),
        .testTarget(
            name: "CIImageHistogramTests",
            dependencies: ["CIImageHistogram"],
            path: "Tests"
        )
    ]
)
