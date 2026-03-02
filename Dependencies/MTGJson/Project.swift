import ProjectDescription

let project = Project(
  name: "MTGJson",
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
      name: "MTGJson",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.missingems.MTGJson",
      sources: ["MTGJson/Sources/**"],
      resources: ["MTGJson/Resources/**"],
      dependencies: [
        .external(name: "Apollo")
      ]
    )
  ]
)

