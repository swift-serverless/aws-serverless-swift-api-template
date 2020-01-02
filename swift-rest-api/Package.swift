// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-rest-api",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ProductService",
            targets: ["ProductService"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-sprinter/aws-lambda-swift-sprinter-nio-plugin", from: "1.0.0-alpha.3"),
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ProductService",
             dependencies: ["DynamoDB", "Logging"]
        ),
        .target(
            name: "Products",
             dependencies: ["LambdaSwiftSprinterNioPlugin", "ProductService"]
        ),
        .testTarget(
            name: "ProductServiceTests",
            dependencies: ["ProductService"]
        ),
    ]
)
