// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

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
    .package(url: "https://github.com/JacobHearst/ScryfallKit", from: "5.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.11.1"),
    .package(url: "https://github.com/kean/Nuke", from: "12.7.2"),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.4.2")
  ]
)
