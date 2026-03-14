import ProjectDescription

let project = Project(
  name: "CardScanner",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.2",
      "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
      "ENABLE_MODULE_VERIFIER": "YES",
      "SWIFT_EMIT_LOC_STRINGS": "YES"
    ]
  ),  targets: [
    .target(
      name: "CardScannerRunner",
      destinations: .iOS,
      product: .app,
      bundleId: "com.missingems.Mooligan.CardScannerRunner",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["Runner/**"],
      resources: ["Resources/**"],
      dependencies: [.target(name: "CardScanner")]
    ),
    .target(
      name: "CardScanner",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.missingems.Mooligan.CardScanner",
      infoPlist: .default,
      sources: ["Sources/**"],
      resources: [],
      dependencies: [
        .project(target: "Networking", path: "../../Core/Networking"),
        .project(target: "DesignComponents", path: "../../Core/DesignComponents"),
        .project(target: "Featurist", path: "../../Core/Featurist"),
      ]
    ),
    .target(
      name: "CardScannerTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.missingems.CardScannerTests",
      infoPlist: .default,
      sources: ["Tests/**"],
      resources: [],
      dependencies: [.target(name: "CardScanner")]
    ),
  ]
)
