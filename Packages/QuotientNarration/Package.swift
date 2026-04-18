// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuotientNarration",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "QuotientNarration", targets: ["QuotientNarration"])
    ],
    targets: [
        .target(
            name: "QuotientNarration",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "QuotientNarrationTests",
            dependencies: ["QuotientNarration"]
        )
    ]
)
