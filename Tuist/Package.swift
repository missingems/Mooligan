// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
@preconcurrency import ProjectDescription

let packageSettings = PackageSettings(
  // Everything defaults to .staticFramework, which is what we want: the whole
  // dependency graph links into a single app binary. Only override a product
  // here if it must exist as its own dynamic image at runtime.
  productTypes: [:]
)
#endif

let package = Package(
  name: "Mooligan",
  dependencies: [
    .package(url: "https://github.com/JacobHearst/ScryfallKit", from: "6.2.0"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.26.2"),
    .package(url: "https://github.com/kean/Nuke", from: "13.0.6"),
    .package(url: "https://github.com/exyte/SVGView.git", from: "1.0.6"),
    .package(url: "https://github.com/markiv/SwiftUI-Shimmer", from: "1.5.1"),
    .package(url: "https://github.com/nikstar/VariableBlur.git", .upToNextMajor(from: "1.3.0")),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.12.0"),
    // Test-only: SwiftUI view rendering for MooliganSnapshotTests. Only the
    // `SnapshotTesting` product is used (no macros), so it adds no swift-syntax.
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
  ]
)
