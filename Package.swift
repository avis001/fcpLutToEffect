// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "lutfx",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "LutFxKit", targets: ["LutFxKit"]),
        .executable(name: "lutfx", targets: ["lutfx"]),
        .executable(name: "LutFxApp", targets: ["LutFxApp"]),
    ],
    targets: [
        .target(name: "LutFxKit", path: "Sources/LutFxKit"),
        .executableTarget(name: "lutfx", dependencies: ["LutFxKit"], path: "Sources/lutfx"),
        .executableTarget(name: "LutFxApp", dependencies: ["LutFxKit"], path: "Sources/LutFxApp"),
    ]
)
