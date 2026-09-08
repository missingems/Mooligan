#!/bin/bash
#
# Runs the price history tests, including the live MTGGraphQL integration test.
#
#     MTGGRAPHQL_TOKEN=xxxxx ./verify-live.sh
#
# Without the token the integration test is skipped and only the mapper tests
# run, which is still a useful check.
#
# These run under SwiftPM on macOS rather than `xcodebuild test` because the app
# targets iOS 27.0 and there is no iOS 27 simulator runtime installed. The whole
# price history slice is pure Foundation, so it compiles for macOS unchanged.
# Set MTGGRAPHQL_URL to point at the deployed proxy instead of MTGJSON directly.

set -euo pipefail
GRAPHQL_DIR="$(cd "$(dirname "$0")" && pwd)"
NETWORKING_DIR="$(dirname "$GRAPHQL_DIR")"

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

mkdir -p "$SCRATCH/Sources/Networking" "$SCRATCH/Tests/NetworkingTests"
cat > "$SCRATCH/Package.swift" <<'SPM'
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
  name: "Networking",
  platforms: [.macOS(.v14)],
  targets: [
    .target(name: "Networking"),
    .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
  ]
)
SPM

# Only the pure-Foundation slice: models + mapper, and the tests over them.
ln -s "$NETWORKING_DIR/Sources/PriceHistory/PriceHistory.swift" "$SCRATCH/Sources/Networking/"
ln -s "$NETWORKING_DIR/Sources/PriceHistory/PriceHistoryMapper.swift" "$SCRATCH/Sources/Networking/"
ln -s "$NETWORKING_DIR/Tests/PriceHistoryMapperTests.swift" "$SCRATCH/Tests/NetworkingTests/"
ln -s "$NETWORKING_DIR/Tests/PriceHistoryIntegrationTests.swift" "$SCRATCH/Tests/NetworkingTests/"

if [[ -z "${MTGGRAPHQL_TOKEN:-}" ]]; then
  echo "note: MTGGRAPHQL_TOKEN not set — the live integration test will be skipped." >&2
fi

cd "$SCRATCH"
swift test
