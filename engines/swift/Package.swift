// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DivorceCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "DivorceCore", targets: ["DivorceCore"]),
    ],
    targets: [
        .target(name: "DivorceCore"),
        .testTarget(
            name: "DivorceCoreTests",
            dependencies: ["DivorceCore"]
        ),
    ]
)
