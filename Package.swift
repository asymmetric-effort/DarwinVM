// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DarwinVM",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "darwinvm", targets: ["darwinvm"]),
        .library(name: "DarwinVMCore", targets: ["DarwinVMCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/apple/swift-testing.git", from: "6.3.1"),
    ],
    targets: [
        .executableTarget(
            name: "darwinvm",
            dependencies: [
                "DarwinVMCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "DarwinVMCore",
            dependencies: []
        ),
        .testTarget(
            name: "DarwinVMCoreTests",
            dependencies: [
                "DarwinVMCore",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
        .testTarget(
            name: "darwinvmTests",
            dependencies: [
                "darwinvm",
                "DarwinVMCore",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
