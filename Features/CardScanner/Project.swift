import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
  name: "CardScanner",
  dependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
    .project(target: "DesignComponents", path: "../../Core/DesignComponents"),
    .project(target: "Featurist", path: "../../Core/Featurist"),
    .external(name: "ComposableArchitecture"),
    .external(name: "ScryfallKit"),
    .external(name: "Nuke"),
    .external(name: "VariableBlur"),
  ],
  runnerDependencies: [
    .project(target: "DesignComponents", path: "../../Core/DesignComponents"),
    .external(name: "ComposableArchitecture"),
  ],
  runnerInfoPlist: [
    "NSCameraUsageDescription": "Used to scan card titles and set codes.",
  ],
  testDependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
    .project(target: "DesignComponents", path: "../../Core/DesignComponents"),
    .external(name: "ComposableArchitecture"),
    .external(name: "ScryfallKit"),
  ]
)
