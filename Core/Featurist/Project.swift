import ProjectDescription

let project = Project(
  name: "Featurist",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.2",
      "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
      "ENABLE_MODULE_VERIFIER": "YES",
      "SWIFT_EMIT_LOC_STRINGS": "YES"
    ]
  ),
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
