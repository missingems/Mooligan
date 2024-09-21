// swift-tools-version: 5.9
@preconcurrency import PackageDescription

#if TUIST
@preconcurrency import ProjectDescription

let packageSettings = PackageSettings(
  // Customize the product types for specific package product
  // Default is .staticFramework
   productTypes: [
    "ComposableArchitecture": .framework,
    "NukeUI": .framework,
    "Nuke": .framework,
    "Shimmer": .framework,
   ]
)
#endif

let package = Package(
  name: "Mooligan",
  dependencies: [
    .package(url: "https://github.com/JacobHearst/ScryfallKit", from: "5.11.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.15.0"),
    .package(url: "https://github.com/kean/Nuke", from: "12.8.0"),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.5.1"),
  ]
)
