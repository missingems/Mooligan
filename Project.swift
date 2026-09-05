import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Mooligan",
  settings: Module.settings,
  targets: [
    .target(
      name: "Mooligan",
      destinations: Module.destinations,
      product: .app,
      bundleId: "com.missingems.Mooligan",
      deploymentTargets: Module.deploymentTargets,
      infoPlist: .extendingDefault(
        with: [
          "UILaunchStoryboardName": "LaunchScreen.storyboard",
          "NSCameraUsageDescription": .string("We need camera access to scan your cards."),
        ]
      ),
      sources: ["Mooligan/Sources/**"],
      resources: ["Mooligan/Resources/**"],
      dependencies: [
        .project(target: "Query", path: .relativeToManifest("Features/Query")),
        .project(target: "Browse", path: .relativeToManifest("Features/Browse")),
        .project(target: "CardDetail", path: .relativeToManifest("Features/CardDetail")),
        .project(target: "CardScanner", path: .relativeToManifest("Features/CardScanner")),
        .project(target: "DesignComponents", path: .relativeToManifest("Core/DesignComponents")),
        .project(target: "Networking", path: .relativeToManifest("Core/Networking")),
        .external(name: "ComposableArchitecture"),
        .external(name: "ScryfallKit"),
      ]
    ),
    .target(
      name: "MooliganTests",
      destinations: Module.destinations,
      product: .unitTests,
      bundleId: "com.missingems.MooliganTests",
      deploymentTargets: Module.deploymentTargets,
      infoPlist: .default,
      sources: ["Mooligan/Tests/**"],
      resources: [],
      dependencies: [.target(name: "Mooligan")]
    ),
  ]
)
