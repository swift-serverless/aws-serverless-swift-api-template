// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-rest-api",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(name: "Products", targets: ["Products"]),
        .library(
            name: "ProductService",
            targets: ["ProductService"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "0.1.0"),
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", from: "5.0.0-alpha.3"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ProductService",
             dependencies: [
                 .product(name: "AWSDynamoDB", package: "aws-sdk-swift"),
                 .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "Products",
             dependencies: [
                 .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                 .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-runtime"),
                "ProductService"
            ]
        ),
        .testTarget(
            name: "ProductServiceTests",
            dependencies: ["Products"]
        ),
    ]
)
