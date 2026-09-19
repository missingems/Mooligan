// swift-tools-version: 6.2
import PackageDescription

// Measures the card scanner on the Mac, where Vision's feature prints match the
// ones on a phone; the iOS simulator's do not. Sources/ScannerAccuracy/App links
// the scanner's own detect, crop, sync and search code, so the tool runs exactly
// what the app runs.
let package = Package(
  name: "scanner-accuracy",
  platforms: [.macOS(.v15)],
  targets: [
    .executableTarget(
      name: "ScannerAccuracy",
      swiftSettings: [
        // The same flag Core/Networking builds with, for Accelerate's current LAPACK.
        .unsafeFlags(["-Xcc", "-DACCELERATE_NEW_LAPACK"]),
      ]
    ),
  ]
)
