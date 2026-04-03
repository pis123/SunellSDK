// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SunellSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SunellSDK",
            targets: ["SunellSDK"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "SunellSDK",
            url: "https://github.com/pis123/SunellSDK/releases/download/1.1.0/SunellSDK.xcframework.zip",
            checksum: "b448d4754eea0ddde85bf2065692a545f3c0f64bc2b489d91d7e15a50b69273d"
        )
    ]
)
