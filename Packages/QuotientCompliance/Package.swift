// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuotientCompliance",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "QuotientCompliance", targets: ["QuotientCompliance"])
    ],
    dependencies: [
        .package(path: "../QuotientFinance")
    ],
    targets: [
        .target(
            name: "QuotientCompliance",
            dependencies: ["QuotientFinance"],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "QuotientComplianceTests",
            dependencies: ["QuotientCompliance", "QuotientFinance"]
        )
    ]
)
