import ProjectDescription

let project = Project(
  name: "Query",
  targets: [
    .target(
      name: "QueryRunner",
      destinations: .iOS,
      product: .app,
      bundleId: "io.tuist.Mooligan.QueryRunner",
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
      bundleId: "io.tuist.Mooligan.Query",
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
      bundleId: "io.tuist.Mooligan.QueryTests",
      infoPlist: .default,
      sources: ["Tests/**"],
      resources: [],
      dependencies: [.target(name: "Query")]
    ),
  ]
)

