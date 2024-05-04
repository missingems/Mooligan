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
      dependencies: [
        .project(target: "Query", path: .relativeToManifest("Features/Query")),
        .project(target: "Browse", path: .relativeToManifest("Features/Browse")),
      ]
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
    )
  ]
)
