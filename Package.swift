// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ACConnectClient",
    platforms: [
        .iOS(.v13) // Or a higher version depending on your needs
    ],
    products: [
        .library(
            name: "ACConnectClient",
            targets: ["ACConnectClient"]
        ),
    ],
    targets: [
        .target(
            name: "ACConnectClient",
            dependencies: [],
            path: "Sources/ACConnectClient"
        )
    ]
)
