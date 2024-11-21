import ProjectDescription

let project = Project(
  name: "DesignComponents",
  options: .options(
    automaticSchemesOptions: .enabled(
      targetSchemesGrouping: .notGrouped,
      codeCoverageEnabled: true,
      testingOptions: .parallelizable
    )
  ),
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0.0",
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
        .external(name: "SDWebImage"),
        .external(name: "SDWebImageSwiftUI"),
        .external(name: "SDWebImageSVGNativeCoder"),
        .external(name: "Sticker")
      ]
    )
  ]
)

