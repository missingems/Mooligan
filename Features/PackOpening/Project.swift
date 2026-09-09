import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
  name: "PackOpening",
  dependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
    .project(target: "DesignComponents", path: "../../Core/DesignComponents"),
    .project(target: "Featurist", path: "../../Core/Featurist"),
    // The session pushes a tapped card onto its own stack rather than handing
    // it back to the host, so the pack stays put behind it.
    .project(target: "CardDetail", path: "../../Features/CardDetail"),
    .external(name: "ComposableArchitecture"),
    .external(name: "ScryfallKit"),
    .external(name: "Nuke"),
    .external(name: "NukeUI"),
  ],
  runnerDependencies: [
    .project(target: "Networking", path: "../../Core/Networking"),
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
