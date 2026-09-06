import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.core(
  name: "Networking",
  dependencies: [
    .external(name: "ScryfallKit"),
    .external(name: "ComposableArchitecture"),
    .external(name: "SQLiteData"),
    .project(target: "Featurist", path: "../../Core/Featurist"),
  ],
  testDependencies: [
    .external(name: "ScryfallKit"),
    .external(name: "ComposableArchitecture"),
    .external(name: "SQLiteData"),
  ]
)
