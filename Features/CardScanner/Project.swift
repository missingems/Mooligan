import ProjectDescription

let project = Project(
  name: "CardScanner",
  options: .options(
    automaticSchemesOptions: .disabled
  ),
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.2",
      "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
      "ENABLE_MODULE_VERIFIER": "YES",
      "SWIFT_EMIT_LOC_STRINGS": "YES"
    ]
  ),
  targets: [
    .target(
      name: "CardScannerRunner",
      destinations: .iOS,
      product: .app,
      bundleId: "com.missingems.Mooligan.CardScannerRunner",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
          "NSCameraUsageDescription": "Used to scan card titles and set codes.",
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
      dependencies: [.target(name: "CardScanner")],
      settings: .settings(
        base: [
          "CODE_COVERAGE_ENABLED": "YES"
        ]
      )
    ),
  ],
  schemes: [
    .scheme(
      name: "CardScanner",
      buildAction: .buildAction(targets: ["CardScanner"]),
      testAction: .targets(
        [
          .testableTarget(
            target: "CardScannerTests",
            parallelization: .swiftTestingOnly,
            isRandomExecutionOrdering: true
          )
        ],
        options: .options(
          coverage: true,
          codeCoverageTargets: ["CardScanner"]
        )
      )
    ),
    .scheme(
      name: "CardScannerRunner",
      buildAction: .buildAction(targets: ["CardScannerRunner"]),
      runAction: .runAction(executable: "CardScannerRunner")
    ),
    .scheme(
      name: "CardScannerTests",
      buildAction: .buildAction(targets: ["CardScannerTests"]),
      testAction: .targets(
        [
          .testableTarget(
            target: "CardScannerTests",
            parallelization: .swiftTestingOnly,
            isRandomExecutionOrdering: true
          )
        ],
        options: .options(
          coverage: true,
          codeCoverageTargets: ["CardScanner"]
        )
      )
    )
  ]
)
