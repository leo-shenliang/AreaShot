// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AreaShot",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AreaShot",
            path: "Sources/AreaShot"
        )
    ]
)
