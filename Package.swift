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
            checksum: "ba37e4f51733eb662a640731f500521e0e9b14253475558b63ac4dfa78084dfa"
        )
    ]
)
