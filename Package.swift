// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AdminAPIClient",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "AdminAPIClient",
            targets: ["AdminAPIClient"]),
    ],
    targets: [
        .target(
            name: "AdminAPIClient"),
        .testTarget(
            name: "AdminAPIClientTests",
            dependencies: ["AdminAPIClient"]
        ),
    ]
)
