import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
  name: "Query",
  dependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
    .project(target: "DesignComponents", path: "../../Core/DesignComponents"),
    .project(target: "Featurist", path: "../../Core/Featurist"),
    .external(name: "ComposableArchitecture"),
    .external(name: "ScryfallKit"),
    .external(name: "NukeUI"),
  ],
  runnerDependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
  ],
  testDependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
    .external(name: "ComposableArchitecture"),
    .external(name: "ScryfallKit"),
  ]
)
