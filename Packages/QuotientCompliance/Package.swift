// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuotientCompliance",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "QuotientCompliance", targets: ["QuotientCompliance"])
    ],
    targets: [
        .target(
            name: "QuotientCompliance",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "QuotientComplianceTests",
            dependencies: ["QuotientCompliance"]
        )
    ]
)
