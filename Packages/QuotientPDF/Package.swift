// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuotientPDF",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "QuotientPDF", targets: ["QuotientPDF"])
    ],
    targets: [
        .target(
            name: "QuotientPDF",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "QuotientPDFTests",
            dependencies: ["QuotientPDF"]
        )
    ]
)
