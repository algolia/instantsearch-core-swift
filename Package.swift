// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "instantsearch-core-swift",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "instantsearch-core-swift",
            targets: ["instantsearch-core-swift"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url:"https://github.com/algolia/algoliasearch-client-swift", from: "7.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "instantsearch-core-swift",
            dependencies: ["AlgoliaSearch"],
	    path: "./Sources"),
        .testTarget(
            name: "instantsearch-core-swiftTests",
            dependencies: ["instantsearch-core-swift"],
            path: "./Tests/Sources"),
    ]
)
