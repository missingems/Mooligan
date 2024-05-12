import ProjectDescription

let project = Project(
  name: "DesignComponents",
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
        .external(name: "SDWebImageSwiftUI"),
        .external(name: "SDWebImageSVGNativeCoder"),
        .external(name: "Shimmer")
      ]
    )
  ]
)

