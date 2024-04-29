import ProjectDescription

let project = Project(
  name: "Mooligan",
  targets: [
    .target(
      name: "Mooligan",
      destinations: .iOS,
      product: .app,
      bundleId: "io.tuist.Mooligan",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["Mooligan/Sources/**"],
      resources: ["Mooligan/Resources/**"],
      dependencies: []
    ),
    .target(
      name: "MooliganTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "io.tuist.MooliganTests",
      infoPlist: .default,
      sources: ["Mooligan/Tests/**"],
      resources: [],
      dependencies: [.target(name: "Mooligan")]
    ),
    .target(
      name: "Browse",
      destinations: .iOS,
      product: .app,
      bundleId: "io.tuist.Mooligan.Browse",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
        ]
      ),
      sources: ["Features/Browse/Runner/**"],
      resources: ["Features/Browse/Resources/**"],
      dependencies: []
    ),
  ]
)
