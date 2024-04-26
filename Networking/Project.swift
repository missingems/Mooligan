import ProjectDescription

let project = Project(
    name: "Networking",
    targets: [
        .target(
            name: "Networking",
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "com.mooligan.Networking",
            infoPlist: .default,
            sources: ["Networking/Sources/**"],
            resources: ["Networking/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "NetworkingTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.NetworkingTests",
            infoPlist: .default,
            sources: ["Networking/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Networking")]
        ),
    ]
)
