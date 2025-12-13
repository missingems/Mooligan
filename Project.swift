import ProjectDescription

let project = Project(
  name: "Mooligan",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.2",
    ]
  ),
  targets: [
    .target(
      name: "Mooligan",
      destinations: .iOS,
      product: .app,
      bundleId: "com.missingems.Mooligan",
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
        .project(target: "CardDetail", path: .relativeToManifest("Features/CardDetail")),
        .project(target: "Featurist", path: .relativeToManifest("Core/Featurist")),
      ]
    ),
    .target(
      name: "MooliganTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.missingems.MooliganTests",
      infoPlist: .default,
      sources: ["Mooligan/Tests/**"],
      resources: [],
      dependencies: [.target(name: "Mooligan")]
    )
  ]
)
