import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.core(
  name: "DesignComponents",
  dependencies: [
    .external(name: "NukeUI"),
    .external(name: "Shimmer"),
    .external(name: "SVGView"),
    .external(name: "VariableBlur"),
    .external(name: "ScryfallKit"),
    .project(target: "Networking", path: "../../Core/Networking"),
    .project(target: "Featurist", path: "../../Core/Featurist"),
  ]
)
