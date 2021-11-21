// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CrudRouter",
    platforms: [
       .macOS(.v12)
    ],
    products: [
        .library(name: "CrudRouter", targets: ["CrudRouter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.53.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.4.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.1.0"),
    ],
    targets: [
      .target(name: "CrudRouter", dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver")
      ]),
        .testTarget(name: "CrudRouterTests", dependencies: [
          .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
          .product(name: "XCTVapor", package: "vapor")
        ]),
    ]
)
