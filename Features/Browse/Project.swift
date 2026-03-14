import ProjectDescription

let project = Project(
  name: "Browse",
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
      name: "BrowseRunner",
      destinations: .iOS,
      product: .app,
      bundleId: "com.missingems.Mooligan.BrowseRunner",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["Runner/**"],
      resources: ["Resources/**"],
      dependencies: [.target(name: "Browse")]
    ),
    .target(
      name: "Browse",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.missingems.Mooligan.Browse",
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
      name: "BrowseTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.missingems.Mooligan.BrowseTests",
      infoPlist: .default,
      sources: ["Tests/**"],
      resources: [],
      dependencies: [.target(name: "Browse")],
      settings: .settings(
        base: [
          "CODE_COVERAGE_ENABLED": "YES"
        ]
      )
    ),
  ],
  schemes: [
    .scheme(
      name: "Browse",
      buildAction: .buildAction(targets: ["Browse"]),
      testAction: .targets(
        [
          .testableTarget(
            target: "BrowseTests",
            parallelization: .swiftTestingOnly,
            isRandomExecutionOrdering: true
          ),
        ],
        options: .options(
          coverage: true,
          codeCoverageTargets: ["Browse"]
        )
      )
    ),
    .scheme(
      name: "BrowseRunner",
      buildAction: .buildAction(targets: ["BrowseRunner"]),
      runAction: .runAction(executable: "BrowseRunner")
    ),
    .scheme(
      name: "BrowseTests",
      buildAction: .buildAction(targets: ["BrowseTests"]),
      testAction: .targets(
        [
          .testableTarget(
            target: "BrowseTests",
            parallelization: .swiftTestingOnly,
            isRandomExecutionOrdering: true
          )
        ],
        options: .options(
          coverage: true,
          codeCoverageTargets: ["Browse"]
        )
      )
    )
  ]
)
