// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Rudder",
    platforms: [
        .iOS(.v9), .tvOS(.v10)
    ],
    products: [
        .library(
            name: "Rudder",
            targets: ["Rudder"]
        )
    ],
    dependencies: [
        .package(name: "MetricsReporter", url: "https://github.com/rudderlabs/metrics-reporter-ios", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Rudder",
            dependencies: [
                .product(name: "MetricsReporter", package: "MetricsReporter"),
            ],
            path: "Sources",
            sources: ["Classes/"],
            publicHeadersPath: "Classes/Headers/Public/",
            cSettings: [
                .headerSearchPath("Classes/Headers/")
            ]
        ),
        .testTarget(
            name: "RudderTests",
            dependencies: ["Rudder", "MetricsReporter"],
            path: "Tests"
        ),
    ]
)
