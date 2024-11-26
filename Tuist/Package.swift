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
    "SDWebImage": .framework,
    "VariableBlur": .framework
   ]
)
#endif

let package = Package(
  name: "Mooligan",
  dependencies: [
    .package(url: "https://github.com/JacobHearst/ScryfallKit", from: "5.12.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.16.1"),
    .package(url: "https://github.com/kean/Nuke", from: "12.8.0"),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.5.1"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSVGNativeCoder", from: "0.2.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "3.1.3"),
    .package(url: "https://github.com/bpisano/sticker", from: "1.2.0"),
    .package(url: "https://github.com/nikstar/VariableBlur", from: "1.2.0"),
  ]
)
