import ProjectDescription

let project = Project(
  name: "Featurist",
  targets: [
    .target(
      name: "Featurist",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.missingems.Featurist",
      sources: ["Featurist/Sources/**"],
      resources: ["Featurist/Resources/**"],
      dependencies: [
        .external(name: "ComposableArchitecture")
      ]
    ),
  ]
)
