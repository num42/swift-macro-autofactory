// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let name = "AutoFactory"

let package = Package(
  name: name,
  platforms: [.macOS(.v12), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: name,
      targets: [name]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/num42/swift-macrotester.git", from: "1.0.3"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    // Macro implementation that performs the source transformation of a macro.
    .macro(
      name: "\(name)Macros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
      ]
    ),
    // Library that exposes a macro as part of its API, which is used in client programs.
    .target(
      name: name,
      dependencies: [.target(name: "\(name)Macros")]
    ),
    // A test target used to develop the macro implementation.
    .testTarget(
      name: "\(name)Tests",
      dependencies: [
        .product(name: "MacroTester", package: "swift-macrotester"),
        .target(name: "\(name)Macros"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
      ],
      resources: [.copy("Resources")]
    )
  ]
)
