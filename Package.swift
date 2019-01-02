// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CrudRouter",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CrudRouter",
            targets: ["CrudRouter"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // 💧 A server-side Swift web framework.,
        .package(url: "https://github.com/vapor/vapor.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/vapor/fluent-sqlite.git", .upToNextMajor(from: "3.0.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CrudRouter",
            dependencies: ["FluentSQLite", "Vapor"]),
        .testTarget(
            name: "CrudRouterTests",
            dependencies: ["CrudRouter", "FluentSQLite"]),
    ]
)
