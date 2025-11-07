// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "MacroDI",
    platforms: [
        .macOS(.v10_15), // Macros need a host platform to run on
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MacroDI",
            targets: ["MacroDI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0-latest"),
        .package(url: "https://github.com/Swinject/Swinject.git", exact: "2.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        // Macro implementation that performs the source transformation of a macro.
        .macro(
            name: "MacroDIPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "Swinject"
            ]
        ),

        // Library that exposes a macro as part of its API, which is used in client programs.
        .target(
            name: "MacroDI",
            dependencies: [
                "MacroDIPlugin",
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "Swinject"
            ]
        ),
        // A test target used to develop the macro implementation.
        .testTarget(
            name: "MacroDITests",
            dependencies: [
                "MacroDI",
                "MacroDIPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                "Swinject"
            ]
        )
    ]
)
