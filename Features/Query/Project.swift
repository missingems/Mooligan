import ProjectDescription

let project = Project(
  name: "Query",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0.0",
      "CLANG_ENABLE_CODE_COVERAGE": "YES"
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
        .external(name: "ComposableArchitecture"),
        .external(name: "NukeUI"),
        .external(name: "Shimmer")
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

