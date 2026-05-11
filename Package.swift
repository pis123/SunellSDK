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
            url: "https://github.com/pis123/SunellSDK/releases/download/1.2.2/SunellSDK.xcframework.zip",
            checksum: "30cf348c6b532f6db5213ecdce9f3e1a7eab95267fe431c437049499cd7ccd9f"
        )
    ]
)
