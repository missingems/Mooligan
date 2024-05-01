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
      sources: ["Runner/**"],
      resources: ["Resources/**"],
      dependencies: [.target(name: "Browse")]
    ),
    .target(
      name: "Browse",
      destinations: .iOS,
      product: .framework,
      bundleId: "io.tuist.Mooligan.Browse",
      infoPlist: .default,
      sources: ["Sources/**"],
      resources: [],
      dependencies: [
        .project(target: "Networking", path: "../../Core/Networking"),
        .external(name: "ComposableArchitecture")
      ]
    ),
    .target(
      name: "BrowseTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "io.tuist.Mooligan.Browse",
      infoPlist: .default,
      sources: ["Tests/**"],
      resources: [],
      dependencies: [.target(name: "Browse")]
    ),
  ]
)

