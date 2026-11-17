// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacPulse",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MacPulse",
            targets: ["MacPulse"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MacPulse",
            dependencies: [],
            path: "Sources/MacPulse"
        )
    ]
)
