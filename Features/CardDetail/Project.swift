import ProjectDescription

let project = Project(
    name: "CardDetail",
    targets: [
        .target(
            name: "CardDetail",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.CardDetail",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                ]
            ),
            sources: ["CardDetail/Sources/**"],
            resources: ["CardDetail/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "CardDetailTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.CardDetailTests",
            infoPlist: .default,
            sources: ["CardDetail/Tests/**"],
            resources: [],
            dependencies: [.target(name: "CardDetail")]
        ),
    ]
)
