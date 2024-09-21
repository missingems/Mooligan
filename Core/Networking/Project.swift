import ProjectDescription

let project = Project(
    name: "Networking",
    settings: .settings(
      base: [
        "SWIFT_VERSION": "6.0.0",
        "CLANG_ENABLE_CODE_COVERAGE": "YES"
      ]
    ),
    targets: [
        .target(
            name: "Networking",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.missingems.Mooligan.Networking",
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: [],
            dependencies: [
              .external(name: "ScryfallKit")
            ]
        ),
        .target(
            name: "NetworkingTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.missingems.Mooligan.NetworkingTests",
            infoPlist: .default,
            sources: ["Tests/**"],
            resources: [],
            dependencies: [.target(name: "Networking")]
        ),
    ]
)
