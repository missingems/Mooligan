import ProjectDescription

let project = Project(
  name: "Browse",
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
      bundleId: "com.missingems.Mooligan.Browse",
      infoPlist: .default,
      sources: ["Tests/**"],
      resources: [],
      dependencies: [.target(name: "Browse")]
    ),
  ]
)

