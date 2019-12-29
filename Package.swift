// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CrudRouter",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "CrudRouter", targets: ["CrudRouter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .branch("ArrayRouting")),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-alpha.2.1"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0-alpha.3"),
    ],
    targets: [
        .target(name: "CrudRouter", dependencies: ["Fluent", "FluentSQLiteDriver", "Vapor"]),
        .testTarget(name: "CrudRouterTests", dependencies: ["CrudRouter", "FluentSQLiteDriver", "XCTVapor"]),
    ]
)
