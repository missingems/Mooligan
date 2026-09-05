import ProjectDescription

let workspace = Workspace(
  name: "Mooligan",
  projects: ["."],
  generationOptions: .options(
    // Stamps LastUpgradeCheck into every generated .xcodeproj so Xcode stops
    // raising "Update to recommended settings". Bump this when you move to a
    // new major Xcode and have reviewed its recommendations.
    lastXcodeUpgradeCheck: Version(27, 0, 0)
  )
)
