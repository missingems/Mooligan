// swift-tools-version: 5.9
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
  // Customize the product types for specific package product
  // Default is .staticFramework
  // productTypes: ["Alamofire": .framework,]
)
#endif

let package = Package(
  name: "Mooligan",
  dependencies: [
    .package(url: "https://github.com/JacobHearst/ScryfallKit", from: "5.9.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.1.0"),
  ]
)

