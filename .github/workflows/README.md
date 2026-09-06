# Workflows

## ci.yml — works today

Runs on every pull request and every push to `main`: resolves dependencies,
runs the whole workspace's tests with `tuist test`, then does a **Release**
build.

The Release build is not redundant. The mock clients, `Card.mock()` and every
`previewValue`/`testValue` live behind `#if DEBUG`, so if production code ever
reaches one, the Release build is what catches it — the Debug build and the
tests will not.

### Runner

`runs-on: xcode-27`.

The project pins iOS 27 as its deployment target and calls unguarded iOS 27
APIs, so it needs the iOS 27 SDK. `xcode-27` is currently the only hosted image
that ships it — `macos-26` tops out at Xcode 26.6. That image is a **preview**
image, so treat it as a dependency with a shelf life: if it is withdrawn before
Xcode 27 reaches a GA image, the options are a self-hosted runner or lowering
the deployment target.

### Caching

Only `~/Library/Caches/org.swift.swiftpm` is cached, deliberately not
`Tuist/.build`. Tuist restores dependency pins from its own state, and a
partially restored `.build` can resolve to versions that disagree with the
committed `Tuist/Package.resolved`.

## testflight.yml — needs setup first

Manual dispatch only, and it **will fail until the three things below are
done**. It is committed as a working starting point, not as something that runs
today.

### 1. Configure signing in the Tuist manifests

There is no `DEVELOPMENT_TEAM` anywhere in `Project.swift` or
`Tuist/ProjectDescriptionHelpers/Module.swift` today, so no target is
signable. The workflow passes `DEVELOPMENT_TEAM` on the command line as a
stopgap; setting it in `Module.baseSettings` is the better fix.

### 2. Register the bundle identifier

`com.missingems.Mooligan` has to exist in App Store Connect with an app record
before an upload will be accepted.

### 3. Add four repository secrets

| Secret | Where it comes from |
| --- | --- |
| `APPLE_TEAM_ID` | Apple Developer → Membership → Team ID |
| `APP_STORE_CONNECT_KEY_ID` | App Store Connect → Users and Access → Integrations → Keys |
| `APP_STORE_CONNECT_ISSUER_ID` | same page, shown above the key list |
| `APP_STORE_CONNECT_KEY_P8` | the downloaded `AuthKey_*.p8`, contents pasted whole |

The API key covers both signing (`-allowProvisioningUpdates` fetches the
profile) and the upload, so no certificate or provisioning profile needs to be
committed or stored as a secret.

### Versioning

`CURRENT_PROJECT_VERSION` is passed in as the `build_number` input because the
manifests do not set one — every build is currently `1.0 (1)`. Wire it into
`Project.swift` if you would rather it be derived automatically.
