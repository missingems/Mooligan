// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
  productTypes: [:]
)
#endif

let package = Package(
  name: "MTGJson",
  dependencies: [
    .package(url: "https://github.com/apollographql/apollo-ios.git", .upToNextMajor(from: "2.0.0"))
  ]
)
