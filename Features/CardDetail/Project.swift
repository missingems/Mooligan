import ProjectDescription

let project = Project(
  name: "CardDetail",
  options: .options(
    automaticSchemesOptions: .enabled(
      targetSchemesGrouping: .notGrouped,
      codeCoverageEnabled: true,
      testingOptions: .parallelizable
    )
  ),
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0.0",
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
        .external(name: "ComposableArchitecture"),
        .external(name: "NukeUI"),
        .external(name: "Shimmer")
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
      dependencies: [.target(name: "CardDetail")]
    ),
  ]
)
