// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "AdminAPIClient",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "AdminAPIClient",
            targets: ["AdminAPIClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "AdminAPIClient",
            dependencies: [
                .product(name: "Tracing", package: "swift-distributed-tracing"),
            ]
        ),
        .testTarget(
            name: "AdminAPIClientTests",
            dependencies: ["AdminAPIClient"]
        ),
    ]
)
