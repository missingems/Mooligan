import ProjectDescription

let project = Project(
  name: "Query",
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
      name: "QueryRunner",
      destinations: .iOS,
      product: .app,
      bundleId: "com.missingems.Mooligan.QueryRunner",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["Runner/**"],
      resources: ["Resources/**"],
      dependencies: [.target(name: "Query")]
    ),
    .target(
      name: "Query",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.missingems.Mooligan.Query",
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
      name: "QueryTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.missingems.QueryTests",
      infoPlist: .default,
      sources: ["Tests/**"],
      resources: [],
      dependencies: [.target(name: "Query")],
      settings: .settings(
        base: [
          "CODE_COVERAGE_ENABLED": "YES"
        ]
      )
    ),
  ],
  schemes: [
    .scheme(
      name: "Query",
      buildAction: .buildAction(targets: ["Query"]),
      testAction: .targets(
        [
          .testableTarget(
            target: "QueryTests",
            parallelization: .swiftTestingOnly,
            isRandomExecutionOrdering: true
          )
        ],
        options: .options(
          coverage: true,
          codeCoverageTargets: ["Query"]
        )
      )
    ),
    .scheme(
      name: "QueryRunner",
      buildAction: .buildAction(targets: ["QueryRunner"]),
      runAction: .runAction(executable: "QueryRunner")
    ),
    .scheme(
      name: "QueryTests",
      buildAction: .buildAction(targets: ["QueryTests"]),
      testAction: .targets(
        [
          .testableTarget(
            target: "QueryTests",
            parallelization: .swiftTestingOnly,
            isRandomExecutionOrdering: true
          )
        ],
        options: .options(
          coverage: true,
          codeCoverageTargets: ["Query"]
        )
      )
    )
  ]
)
