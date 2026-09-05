import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
  name: "Browse",
  dependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
    .project(target: "DesignComponents", path: "../../Core/DesignComponents"),
    .project(target: "Featurist", path: "../../Core/Featurist"),
    .external(name: "ComposableArchitecture"),
    .external(name: "ScryfallKit"),
  ],
  runnerDependencies: [
    .project(target: "DesignComponents", path: "../../Core/DesignComponents"),
    .external(name: "ComposableArchitecture"),
    .external(name: "ScryfallKit"),
  ],
  testDependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
    .external(name: "ComposableArchitecture"),
    .external(name: "ScryfallKit"),
  ]
)
