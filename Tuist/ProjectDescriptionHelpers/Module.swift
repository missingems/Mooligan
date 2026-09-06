import ProjectDescription

/// Single source of truth for every project in the workspace.
///
/// Settings live here rather than being copy-pasted into each `Project.swift`,
/// so a change is made once and every project picks it up on the next
/// `tuist generate`.
public enum Module {
  public static let organization = "com.missingems.Mooligan"

  public static let destinations: Destinations = .iOS

  /// The app uses unguarded iOS 26 APIs (`glassEffect`, `tabBarMinimizeBehavior`,
  /// `scrollEdgeEffect`). Pin it explicitly — leaving this unset makes the
  /// minimum OS follow whichever SDK happens to be installed.
  public static let deploymentTargets: DeploymentTargets = .iOS("27.0")

  /// Product type for every first-party module.
  ///
  /// Static, so the whole graph links into one app binary: no dyld image to
  /// load, embed and code-sign per module at launch, and the linker can
  /// dead-strip across module boundaries.
  public static let product: Product = .staticFramework

  public static let baseSettings: SettingsDictionary = [
    // Swift *language mode*. Only 4, 4.2, 5 and 6 are valid — "6.2" is a
    // toolchain version and is silently truncated to 6 by the build system.
    "SWIFT_VERSION": "6",
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "ENABLE_MODULE_VERIFIER": "YES",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "DEAD_CODE_STRIPPING": "YES",
  ]

  public static let settings: Settings = .settings(base: baseSettings)

  /// Defaults for the app's version and build number.
  ///
  /// Local builds get `1.0.0 (1)`. CI overrides both on the `xcodebuild`
  /// command line: `MARKETING_VERSION` from the latest `vX.Y.Z` tag,
  /// `CURRENT_PROJECT_VERSION` from the commit count since that tag.
  public static let appVersioning: SettingsDictionary = [
    "MARKETING_VERSION": "1.0.0",
    "CURRENT_PROJECT_VERSION": "1",
  ]

  public static let testSettings: Settings = .settings(
    base: baseSettings.merging(["CODE_COVERAGE_ENABLED": "YES"]) { _, new in new }
  )
}

// MARK: - Target factories

public extension Target {
  /// A first-party module: static framework, shared settings.
  static func module(
    name: String,
    sources: SourceFilesList,
    resources: ResourceFileElements? = nil,
    dependencies: [TargetDependency]
  ) -> Target {
    .target(
      name: name,
      destinations: Module.destinations,
      product: Module.product,
      bundleId: "\(Module.organization).\(name)",
      deploymentTargets: Module.deploymentTargets,
      infoPlist: .default,
      sources: sources,
      resources: resources,
      dependencies: dependencies
    )
  }

  /// A hostless logic-test bundle for `module`.
  static func tests(
    for module: String,
    sources: SourceFilesList = ["Tests/**"],
    dependencies: [TargetDependency] = []
  ) -> Target {
    .target(
      name: "\(module)Tests",
      destinations: Module.destinations,
      product: .unitTests,
      bundleId: "\(Module.organization).\(module)Tests",
      deploymentTargets: Module.deploymentTargets,
      infoPlist: .default,
      sources: sources,
      resources: [],
      dependencies: [.target(name: module)] + dependencies,
      settings: Module.testSettings
    )
  }

  /// A standalone host app used to run/preview a single feature in isolation.
  static func runner(
    for module: String,
    infoPlist: [String: Plist.Value] = [:],
    dependencies: [TargetDependency] = []
  ) -> Target {
    .target(
      name: "\(module)Runner",
      destinations: Module.destinations,
      product: .app,
      bundleId: "\(Module.organization).\(module)Runner",
      deploymentTargets: Module.deploymentTargets,
      infoPlist: .extendingDefault(
        with: ["UILaunchStoryboardName": "LaunchScreen.storyboard"].merging(infoPlist) { _, new in new }
      ),
      sources: ["Runner/**"],
      resources: ["Resources/**"],
      dependencies: [.target(name: module)] + dependencies
    )
  }
}

// MARK: - Project factories

public extension Project {
  /// A core module: framework + optional test bundle. Schemes are automatic.
  static func core(
    name: String,
    sources: SourceFilesList = ["Sources/**"],
    resources: ResourceFileElements? = ["Resources/**"],
    dependencies: [TargetDependency],
    hasTests: Bool = true,
    testDependencies: [TargetDependency] = []
  ) -> Project {
    Project(
      name: name,
      settings: Module.settings,
      targets: [
        .module(name: name, sources: sources, resources: resources, dependencies: dependencies),
      ] + (hasTests ? [.tests(for: name, dependencies: testDependencies)] : [])
    )
  }

  /// A feature module: framework + standalone runner app + test bundle, with
  /// the three schemes (`<Name>`, `<Name>Runner`, `<Name>Tests`) the app uses.
  static func feature(
    name: String,
    dependencies: [TargetDependency],
    runnerDependencies: [TargetDependency] = [],
    runnerInfoPlist: [String: Plist.Value] = [:],
    testDependencies: [TargetDependency] = []
  ) -> Project {
    Project(
      name: name,
      options: .options(automaticSchemesOptions: .disabled),
      settings: Module.settings,
      targets: [
        .runner(for: name, infoPlist: runnerInfoPlist, dependencies: runnerDependencies),
        .module(name: name, sources: ["Sources/**"], resources: [], dependencies: dependencies),
        .tests(for: name, dependencies: testDependencies),
      ],
      schemes: [
        .moduleScheme(name),
        .scheme(
          name: "\(name)Runner",
          buildAction: .buildAction(targets: ["\(name)Runner"]),
          runAction: .runAction(executable: "\(name)Runner")
        ),
        .testScheme(name),
      ]
    )
  }
}

// MARK: - Every tested first-party module

public extension Module {
  /// Feature / core modules that ship a test bundle, as (manifest-relative
  /// path, module name). The test bundle is always `<name>Tests`.
  ///
  /// Drives the app scheme's aggregate test action — add a module here and one
  /// Cmd-U on the `Mooligan` scheme picks it up.
  static let testedModules: [(path: String, name: String)] = [
    ("Features/Browse", "Browse"),
    ("Features/Query", "Query"),
    ("Features/CardDetail", "CardDetail"),
    ("Features/CardScanner", "CardScanner"),
    ("Core/Networking", "Networking"),
    ("Core/DesignComponents", "DesignComponents"),
  ]
}

// MARK: - Scheme factories

extension Scheme {
  /// The one scheme to run in Xcode — a **workspace** scheme (it references
  /// targets across projects, which a project scheme can't). Its test action
  /// builds and runs *every* test target: `MooliganTests` (logic),
  /// `MooliganSnapshotTests`, `MooliganUITests`, and every module's
  /// `<name>Tests` bundle. One Cmd-U gives whole-project coverage.
  ///
  /// Belongs in `Workspace.swift`, not a `Project.swift`.
  public static func mooliganApp() -> Scheme {
    func app(_ target: String) -> TargetReference {
      .project(path: .relativeToManifest("."), target: target)
    }
    func module(_ path: String, _ target: String) -> TargetReference {
      .project(path: .relativeToManifest(path), target: target)
    }

    let moduleTestables = Module.testedModules.map { mod in
      TestableTarget.testableTarget(
        target: module(mod.path, "\(mod.name)Tests"),
        parallelization: .swiftTestingOnly,
        isRandomExecutionOrdering: true
      )
    }

    let coverageTargets: [TargetReference] =
      [app("Mooligan")] + Module.testedModules.map { module($0.path, $0.name) }

    return .scheme(
      name: "Mooligan",
      buildAction: .buildAction(targets: [app("Mooligan")]),
      testAction: .targets(
        [
          .testableTarget(target: app("MooliganTests"), parallelization: .swiftTestingOnly),
          .testableTarget(target: app("MooliganSnapshotTests"), parallelization: .swiftTestingOnly),
          .testableTarget(target: app("MooliganUITests")),
        ] + moduleTestables,
        options: .options(coverage: true, codeCoverageTargets: coverageTargets)
      ),
      runAction: .runAction(executable: app("Mooligan"))
    )
  }

  static func moduleScheme(_ name: String) -> Scheme {
    .scheme(
      name: name,
      buildAction: .buildAction(targets: ["\(name)"]),
      testAction: .moduleTests(name)
    )
  }

  static func testScheme(_ name: String) -> Scheme {
    .scheme(
      name: "\(name)Tests",
      buildAction: .buildAction(targets: ["\(name)Tests"]),
      testAction: .moduleTests(name)
    )
  }
}

extension TestAction {
  static func moduleTests(_ name: String) -> TestAction {
    .targets(
      [
        .testableTarget(
          target: "\(name)Tests",
          parallelization: .swiftTestingOnly,
          isRandomExecutionOrdering: true
        ),
      ],
      options: .options(coverage: true, codeCoverageTargets: ["\(name)"])
    )
  }
}
