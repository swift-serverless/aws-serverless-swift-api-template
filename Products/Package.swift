// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-rest-api",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "Products", targets: ["Products"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-serverless/BreezeLambdaDynamoDBAPI.git", from: "0.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .executableTarget(
            name: "Products",
             dependencies: [
                .product(name: "BreezeLambdaAPI", package: "BreezeLambdaDynamoDBAPI"),
                .product(name: "BreezeDynamoDBService", package: "BreezeLambdaDynamoDBAPI"),
            ]
        ),
        .testTarget(
            name: "ProductServiceTests",
            dependencies: ["Products"]
        ),
    ]
)
