# Workflows

One workflow, `ci.yml`, with three jobs: `test` → `ui-test` → `deploy`.

## `test` — runs on every PR and every push to `main`

Resolves dependencies, boots an iOS 27 simulator, then
`tuist test Mooligan --skip-ui-tests`. The `Mooligan` scheme is a workspace
scheme (`Scheme.mooliganApp()` in `Tuist/ProjectDescriptionHelpers/Module.swift`)
that aggregates **every** test target — so one `tuist generate` + Cmd-U on the
`Mooligan` scheme in Xcode runs the same set locally.

| Target | Kind | What it checks |
| --- | --- | --- |
| `*Tests` (per module) | logic | the Browse / Query / CardDetail / CardScanner / Networking / DesignComponents suites |
| `MooliganTests` | logic | `AppFeature` reducer behaviour |
| `MooliganSnapshotTests` | snapshot | renders views, diffs against `Mooligan/SnapshotTests/__Snapshots__/` |

Then a **Release** build. That build is not redundant: the mock clients,
`Card.mock()` and every `previewValue`/`testValue` live behind `#if DEBUG`, so
if production code ever reaches one, the Release build is what catches it — the
Debug build and the tests will not.

## `ui-test` — runs after `test`

`needs: test`. Runs `MooliganUITests` (XCUITest) on its own so the slower,
flakier UI pass has its own retries — `-retry-tests-on-failure -test-iterations 3`
— without gating the fast feedback from `test`.

The app launches with `-uiTestMode`
([`Mooligan/Sources/UITestSupport.swift`](../../Mooligan/Sources/UITestSupport.swift)),
which swaps every network client for its in-memory mock and makes bulk sync
inert, so the tests run fully offline against fixed data (mock sets `FIN`/`TDM`/…,
cards "Test Card 01"…"Test Card 60", 12 per page). Coverage: Browse list load +
search; set-detail grid scroll, pagination, colour filter, in-set search;
card-detail vertical scroll + horizontal paging. Add hooks with
`.accessibilityIdentifier("<area>.<element>")` at the view call site.

### Updating snapshot references

Snapshot failures mean the rendered view no longer matches the committed PNG.
If the change was intentional, re-record locally against an **iOS 27**
simulator and commit the new images:

```
SNAPSHOT_TESTING_RECORD=all xcodebuild test \
  -workspace Mooligan.xcworkspace -scheme Mooligan \
  -destination 'name=iPhone 17 Pro' \
  -only-testing:MooliganSnapshotTests
```

Review the diff, then commit `Mooligan/SnapshotTests/__Snapshots__/`.

## `deploy` — runs after `test` + `ui-test`, only on a push to `main`

`needs: [test, ui-test]`, so it never ships a red build. Archives, exports, and uploads to
TestFlight with an App Store Connect API key (which covers both signing via
`-allowProvisioningUpdates` and the upload, so no certificate or profile is
stored in the repo).

### Versioning

Derived from git, no stored state:

| | |
| --- | --- |
| **Marketing version** | the latest `vX.Y.Z` tag (the `v` is optional), e.g. `1.0.0` |
| **Build number** | `git rev-list <tag>..HEAD --count` + 1 |

So tagging `v1.0.0` on a commit makes that commit build `1.0.0 (1)`, the next
merge `1.0.0 (2)`, and so on. Push `v2.0.0` and the following builds become
`2.0.0 (1)`, `2.0.0 (2)`… The build number resetting per tag is fine —
TestFlight only requires it to increase *within* one marketing version, and
every merge adds at least one commit.

With no tag yet, it falls back to `0.1.0 (<total commit count>)`.

The manifests carry `MARKETING_VERSION = 1.0.0` / `CURRENT_PROJECT_VERSION = 1`
as defaults for local builds (`Module.appVersioning` in
`Tuist/ProjectDescriptionHelpers/Module.swift`); the `deploy` job overrides both
on the `xcodebuild` command line.

**To cut a release:** `git tag v2.0.0 && git push origin v2.0.0`. The next merge
to `main` ships under the new version.

### Prerequisites (the `deploy` job fails until these are done)

1. **Signing team.** There is no `DEVELOPMENT_TEAM` in the Tuist manifests; the
   workflow passes it on the command line from `APPLE_TEAM_ID`. Setting it in
   `Module.baseSettings` is the tidier fix.
2. **App record.** `com.missingems.Mooligan` must exist in App Store Connect
   with an app record before an upload is accepted.
3. **Four repository secrets:**

   | Secret | Where it comes from |
   | --- | --- |
   | `APPLE_TEAM_ID` | Apple Developer → Membership → Team ID |
   | `APP_STORE_CONNECT_KEY_ID` | App Store Connect → Users and Access → Integrations → Keys |
   | `APP_STORE_CONNECT_ISSUER_ID` | same page, above the key list |
   | `APP_STORE_CONNECT_KEY_P8` | the downloaded `AuthKey_*.p8`, contents pasted whole |

## Runner

`runs-on: xcode-27`. The project pins iOS 27 as its deployment target and calls
unguarded iOS 27 APIs, so it needs the iOS 27 SDK. `xcode-27` is currently the
only hosted image that ships it. That image is a **preview** image: if it is
withdrawn before Xcode 27 reaches a GA image, the options are a self-hosted
runner or lowering the deployment target.

Every job runs `xcodebuild -downloadComponent MetalToolchain` first — Xcode 26+
ships the Metal toolchain separately and `DesignComponents/Sources/crtDistortion.metal`
needs it to compile.

## Caching

Only `~/Library/Caches/org.swift.swiftpm` is cached, deliberately not
`Tuist/.build`. Tuist restores dependency pins from its own state, and a
partially restored `.build` can resolve to versions that disagree with the
committed `Tuist/Package.resolved`.
