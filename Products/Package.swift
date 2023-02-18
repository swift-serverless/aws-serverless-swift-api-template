// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-rest-api",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "Products", targets: ["Products"]),
        .library(
            name: "DynamoDBService",
            targets: ["DynamoDBService"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "1.0.0-alpha.1"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", branch: "main"),
        .package(url: "https://github.com/soto-project/soto.git", from: "6.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "DynamoDBService",
             dependencies: [
                 .product(name: "SotoDynamoDB", package: "soto"),
                 .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "DynamoDBLambda",
             dependencies: [
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
               "DynamoDBService"
            ]
        ),
        .executableTarget(
            name: "Products",
             dependencies: [
                "DynamoDBLambda"
            ]
        ),
        .testTarget(
            name: "ProductServiceTests",
            dependencies: ["Products"]
        ),
    ]
)
