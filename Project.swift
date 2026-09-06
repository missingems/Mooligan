import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Mooligan",
  options: .options(automaticSchemesOptions: .disabled),
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
          "BGTaskSchedulerPermittedIdentifiers": .array(["com.missingems.Mooligan.bulkSync"]),
          "UIBackgroundModes": .array(["processing"]),
          // Version and build both come from build settings so CI can stamp
          // them on the `xcodebuild` command line without touching the plist.
          "CFBundleShortVersionString": "$(MARKETING_VERSION)",
          "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
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
      ],
      settings: .settings(base: Module.appVersioning)
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
      dependencies: [
        .target(name: "Mooligan"),
        .project(target: "Networking", path: .relativeToManifest("Core/Networking")),
        .project(target: "Browse", path: .relativeToManifest("Features/Browse")),
        .external(name: "ComposableArchitecture"),
      ],
      settings: Module.testSettings
    ),
    // Renders SwiftUI views on the simulator and diffs them against committed
    // reference images. A `.unitTests` bundle, so `tuist test` runs it in the
    // same pass as the logic tests.
    .target(
      name: "MooliganSnapshotTests",
      destinations: Module.destinations,
      product: .unitTests,
      bundleId: "com.missingems.MooliganSnapshotTests",
      deploymentTargets: Module.deploymentTargets,
      infoPlist: .default,
      sources: ["Mooligan/SnapshotTests/**"],
      resources: [],
      dependencies: [
        .target(name: "Mooligan"),
        .project(target: "DesignComponents", path: .relativeToManifest("Core/DesignComponents")),
        .external(name: "SnapshotTesting"),
      ],
      settings: Module.testSettings
    ),
    // Drives the built app through XCUITest. A `.uiTests` bundle: needs the app
    // installed on a booted simulator, so it is the slow part of `tuist test`.
    .target(
      name: "MooliganUITests",
      destinations: Module.destinations,
      product: .uiTests,
      bundleId: "com.missingems.MooliganUITests",
      deploymentTargets: Module.deploymentTargets,
      infoPlist: .default,
      sources: ["Mooligan/UITests/**"],
      resources: [],
      dependencies: [
        .target(name: "Mooligan"),
      ]
    ),
  ]
)
