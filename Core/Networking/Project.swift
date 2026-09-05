import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.core(
  name: "Networking",
  dependencies: [
    .external(name: "ScryfallKit"),
    .external(name: "ComposableArchitecture"),
    .project(target: "Featurist", path: "../../Core/Featurist"),
  ]
)
