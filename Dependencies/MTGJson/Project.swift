import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.core(
  name: "MTGJson",
  sources: ["MTGJson/Sources/**"],
  resources: ["MTGJson/Resources/**"],
  dependencies: [],
  hasTests: false
)
