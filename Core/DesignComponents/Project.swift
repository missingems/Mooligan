import ProjectDescription

let project = Project(
  name: "DesignComponents",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.2",
    ]
  ),
  targets: [
    .target(
      name: "DesignComponents",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.missingems.DesignComponents",
      infoPlist: .default,
      sources: ["Sources/**"],
      resources: ["Resources/**"],
      dependencies: [
        .external(name: "NukeUI"),
        .external(name: "Shimmer"),
        .external(name: "SVGView"),
        .project(target: "Networking", path: "../../Core/Networking"),
        .project(target: "Featurist", path: "../../Core/Featurist"),
      ]
    )
  ]
)
