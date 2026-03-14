import ProjectDescription

let project = Project(
  name: "CardDetail",
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
      name: "CardDetailRunner",
      destinations: .iOS,
      product: .app,
      bundleId: "com.missingems.Mooligan.CardDetailRunner",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["Runner/**"],
      resources: ["Resources/**"],
      dependencies: [.target(name: "CardDetail")]
    ),
    .target(
      name: "CardDetail",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.missingems.Mooligan.CardDetail",
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
      name: "CardDetailTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.missingems.CardDetailTests",
      infoPlist: .default,
      sources: ["Tests/**"],
      resources: [],
      dependencies: [.target(name: "CardDetail")],
      settings: .settings(
        base: [
          "CODE_COVERAGE_ENABLED": "YES"
        ]
      )
    ),
  ],
  schemes: [
    .scheme(
      name: "CardDetail",
      buildAction: .buildAction(targets: ["CardDetail"]),
      testAction: .targets(
        [
          .testableTarget(
            target: "CardDetailTests",
            parallelization: .swiftTestingOnly,
            isRandomExecutionOrdering: true
          )
        ],
        options: .options(
          coverage: true,
          codeCoverageTargets: ["CardDetail"]
        )
      )
    ),
    .scheme(
      name: "CardDetailRunner",
      buildAction: .buildAction(targets: ["CardDetailRunner"]),
      runAction: .runAction(executable: "CardDetailRunner")
    ),
    .scheme(
      name: "CardDetailTests",
      buildAction: .buildAction(targets: ["CardDetailTests"]),
      testAction: .targets(
        [
          .testableTarget(
            target: "CardDetailTests",
            parallelization: .swiftTestingOnly,
            isRandomExecutionOrdering: true
          )
        ],
        options: .options(
          coverage: true,
          codeCoverageTargets: ["CardDetail"]
        )
      )
    )
  ]
)
