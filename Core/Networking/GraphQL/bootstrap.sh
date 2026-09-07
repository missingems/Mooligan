#!/bin/bash
#
# Fetches the MTGGraphQL schema and generates the Apollo Swift types.
#
# Run from this directory with your MTGGraphQL access token in the environment:
#
#     MTGGRAPHQL_TOKEN=xxxxx ./bootstrap.sh
#
# The token is only ever written to apollo-codegen-config.local.json, which is
# gitignored and deleted on exit. The schema it downloads is not a secret and
# should be committed so codegen works on CI and on a fresh clone.

set -euo pipefail
cd "$(dirname "$0")"

if [[ -z "${MTGGRAPHQL_TOKEN:-}" ]]; then
  echo "error: MTGGRAPHQL_TOKEN is not set." >&2
  echo "Tokens come from the MTGJSON Discord for Patreon subscribers." >&2
  exit 1
fi

LOCAL_CONFIG="apollo-codegen-config.local.json"
trap 'rm -f "$LOCAL_CONFIG"' EXIT

if [[ ! -x ./apollo-ios-cli ]]; then
  echo "==> Installing apollo-ios-cli"
  # The plugin lives in the Tuist-managed checkout, so build it from a scratch
  # package rather than adding a plugin dependency to the app itself.
  SCRATCH="$(mktemp -d)"
  mkdir -p "$SCRATCH/Sources/Probe"
  cat > "$SCRATCH/Package.swift" <<'SPM'
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
  name: "Probe",
  dependencies: [.package(url: "https://github.com/apollographql/apollo-ios", from: "1.25.7")],
  targets: [.target(name: "Probe")]
)
SPM
  echo 'public struct Probe {}' > "$SCRATCH/Sources/Probe/Probe.swift"
  ( cd "$SCRATCH" && swift package --allow-writing-to-package-directory \
      --allow-network-connections all apollo-cli-install >/dev/null )
  cp "$SCRATCH/apollo-ios-cli" ./apollo-ios-cli
  rm -rf "$SCRATCH"
fi

echo "==> Writing $LOCAL_CONFIG (token header, gitignored)"
python3 - "$LOCAL_CONFIG" <<'PY'
import json, os, sys
config = json.load(open("apollo-codegen-config.json"))
config["schemaDownloadConfiguration"]["headers"] = [
    {"key": "authorization", "value": "Bearer " + os.environ["MTGGRAPHQL_TOKEN"]}
]
json.dump(config, open(sys.argv[1], "w"), indent=2)
PY

echo "==> Fetching schema from graphql.mtgjson.com"
./apollo-ios-cli fetch-schema --path "$LOCAL_CONFIG"

echo "==> Generating Swift types"
./apollo-ios-cli generate --path "$LOCAL_CONFIG"

if [[ ! -d ../Sources/PriceHistory/Generated ]]; then
  echo "error: codegen reported success but produced no Generated directory." >&2
  exit 1
fi

echo "==> Enabling MTGGRAPHQL_GENERATED in Core/Networking/Project.swift"
# Must edit the manifest itself: Tuist caches manifest evaluation by content
# hash, so a filesystem check inside the manifest would never be re-run.
sed -i '' 's/^let graphQLGenerated = false$/let graphQLGenerated = true/' ../Project.swift
grep -q '^let graphQLGenerated = true$' ../Project.swift \
  || { echo "error: could not flip graphQLGenerated in ../Project.swift" >&2; exit 1; }

echo "==> tuist generate"
( cd ../../.. && tuist generate --no-open )

cat <<'DONE'

Done. The live Apollo client is now compiled in.

Commit together:
  git add Core/Networking/GraphQL/schema.graphqls \
          Core/Networking/Sources/PriceHistory/Generated \
          Core/Networking/Project.swift

Verify the live response (see GraphQL/README.md for why this runs under SwiftPM
rather than xcodebuild — there is no iOS 27 simulator runtime installed):

  ./verify-live.sh

DONE
