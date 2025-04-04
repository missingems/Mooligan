// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
  productTypes: ["ComposableArchitecture": .framework]
)
#endif

let package = Package(
  name: "Featurist",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.16.1")
    // Add your own dependencies here:
    // .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
    // You can read more about dependencies here: https://docs.tuist.io/documentation/tuist/dependencies
  ]
)
