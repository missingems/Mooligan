import ProjectDescription

let project = Project(
    name: "Main",
    targets: [
        .target(
            name: "Main",
            destinations: [.iPad, .iPhone, .mac, .appleVision, .appleTv, .appleWatch],
            product: .app,
            bundleId: "com.missingems.mooligan",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                ]
            ),
            sources: ["Main/Sources/**"],
            resources: ["Main/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "MainTests",
            destinations: [.iPad, .iPhone, .mac, .appleVision, .appleTv, .appleWatch],
            product: .unitTests,
            bundleId: "com.missingems.mooligan.MainTests",
            infoPlist: .default,
            sources: ["Main/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Main")]
        ),
    ]
)
