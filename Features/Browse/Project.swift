import ProjectDescription

let project = Project(
  name: "Browse",
  targets: [
    .target(
      name: "BrowseRunner",
      destinations: .iOS,
      product: .app,
      bundleId: "io.tuist.Mooligan.BrowseRunner",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["Browse/Runner/**"],
      resources: ["Browse/Resources/**"],
      dependencies: [.target(name: "Browse")]
    ),
    .target(
      name: "Browse",
      destinations: .iOS,
      product: .framework,
      bundleId: "io.tuist.Mooligan.Browse",
      infoPlist: .default,
      sources: ["Browse/Sources/**"],
      resources: [],
      dependencies: []
    ),
    .target(
      name: "BrowseTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "io.tuist.Mooligan.Browse",
      infoPlist: .default,
      sources: ["Browse/Tests/**"],
      resources: [],
      dependencies: [.target(name: "Browse")]
    ),
  ]
)

