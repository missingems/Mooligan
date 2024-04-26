import ProjectDescription

let project = Project(
    name: "Mooligan",
    targets: [
        .target(
            name: "Mooligan",
            destinations: .iOS,
            product: .app,
            bundleId: "com.mooligan.app",
            infoPlist: .default,
            sources: ["Mooligan/Sources/**"],
            resources: ["Mooligan/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "MooliganTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.mooligan.app.tests",
            infoPlist: .default,
            sources: ["Mooligan/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Mooligan")]
        ),
    ]
)
