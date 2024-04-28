import ProjectDescription

let project = Project(
  name: "Browse",
  targets: [
    .target(
      name: "Browse",
      destinations: .iOS,
      product: .framework,
      bundleId: "io.tuist.Browse",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["Browse/Sources/**"],
      resources: ["Browse/Resources/**"],
      dependencies: []
    ),
    .target(
      name: "BrowseTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "io.tuist.BrowseTests",
      infoPlist: .default,
      sources: ["Browse/Tests/**"],
      resources: [],
      dependencies: [.target(name: "Browse")]
    ),
  ]
)
