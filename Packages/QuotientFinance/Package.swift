// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuotientFinance",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "QuotientFinance", targets: ["QuotientFinance"])
    ],
    targets: [
        .target(
            name: "QuotientFinance",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "QuotientFinanceTests",
            dependencies: ["QuotientFinance"]
        )
    ]
)
