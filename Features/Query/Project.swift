import ProjectDescription

let project = Project(
  name: "Query",
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
      product: .staticFramework,
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
      dependencies: [.target(name: "Query")]
    ),
  ]
)

