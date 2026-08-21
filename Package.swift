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
            url: "https://github.com/pis123/SunellSDK/releases/download/1.3.0/SunellSDK.xcframework.zip",
            checksum: "c6a9a44bc6ba50eb646d047a933b64678fe449f815ab20d36c8286cf405b033b"
        )
    ]
)
