// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "lutfx",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "lutfx", path: "Sources/lutfx")
    ]
)
