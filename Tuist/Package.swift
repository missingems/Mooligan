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
    .package(url: "https://github.com/JacobHearst/ScryfallKit", .branch("main")),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .branch("main")),
    .package(url: "https://github.com/kean/Nuke", .branch("main")),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", .branch("main"))
  ]
)
