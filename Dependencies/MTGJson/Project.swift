import ProjectDescription

let project = Project(
  name: "MTGJson",
  targets: [
    .target(
      name: "MTGJson",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.missingems.MTGJson",
      deploymentTargets: .iOS("16.0"),
      sources: ["MTGJson/Sources/**"],
      resources: ["MTGJson/Resources/**"],
      dependencies: [
        .external(name: "Apollo")
      ]
    )
  ]
)

