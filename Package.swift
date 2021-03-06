// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitCommit",
    products: [
        .executable(
            name: "git-commit",
            targets: ["git-commit"]
        ),
        .library(
            name: "GitCommitFramework",
            targets: ["GitCommitFramework"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "git-commit",
            dependencies: ["GitCommitFramework"]),
        .target(
            name: "GitCommitFramework",
            dependencies: ["Yams"]),
        .testTarget(
            name: "GitCommitTests",
            dependencies: ["GitCommitFramework"]),
    ]
)
