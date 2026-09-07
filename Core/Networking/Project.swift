import ProjectDescription
import ProjectDescriptionHelpers

/// Whether Apollo codegen has produced `Sources/PriceHistory/Generated`.
///
/// Flipped to `true` by `GraphQL/bootstrap.sh`. This is a literal rather than a
/// `FileManager` check because Tuist caches manifest evaluation by content hash:
/// a manifest that only *reads* the filesystem is never re-evaluated after
/// codegen runs, so the flag would silently never turn on. Editing this line
/// changes the manifest, which is what forces the re-evaluation.
///
/// Commit the flipped value together with `GraphQL/schema.graphqls` and the
/// generated sources.
let graphQLGenerated = true

/// Compiles in `ApolloPriceHistoryClient`. Without it the live price history
/// path is left out and `PriceHistoryClientKey` falls back to the unavailable
/// client, so the chart section simply doesn't render.
let networkingSettings: SettingsDictionary = graphQLGenerated
  ? ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) MTGGRAPHQL_GENERATED"]
  : [:]

let project = Project.core(
  name: "Networking",
  dependencies: [
    .external(name: "ScryfallKit"),
    .external(name: "ComposableArchitecture"),
    .external(name: "SQLiteData"),
    .external(name: "Apollo"),
    .external(name: "ApolloAPI"),
    .project(target: "Featurist", path: "../../Core/Featurist"),
  ],
  testDependencies: [
    .external(name: "ScryfallKit"),
    .external(name: "ComposableArchitecture"),
    .external(name: "SQLiteData"),
  ],
  moduleSettings: .settings(
    base: Module.baseSettings.merging(networkingSettings) { _, new in new }
  )
)
