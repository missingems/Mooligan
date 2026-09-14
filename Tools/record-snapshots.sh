#!/bin/bash
# Re-records snapshot references (Mooligan/SnapshotTests/__Snapshots__) after a UI change.
#
#   Tools/record-snapshots.sh                                   every snapshot suite
#   Tools/record-snapshots.sh PriceHistorySnapshotTests         one suite
#   Tools/record-snapshots.sh 'PriceHistorySnapshotTests/loadedSection()'   one test
#
# It runs the tests twice: once in record mode, which writes new references (and reports the
# rewritten snapshots as failures, which is expected), then once normally to confirm they pass.
#
# RECORD=failed (the default) rewrites only snapshots that no longer match. The comparisons allow a
# 2% difference, so a very small tweak can still "match"; use RECORD=all to rewrite every reference.
#
# References depend on the device, so record on the simulator CI compares against (see
# SIMULATOR_NAME in .github/workflows/ci.yml). Override with SIMULATOR_NAME=... if that changes.
set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE="${SIMULATOR_NAME:-iPhone 17 Pro}"
MODE="${RECORD:-failed}"

# Matching by name alone is ambiguous with several iOS runtimes installed, so pick the simulator's id:
# a booted one if there is one, otherwise the newest runtime that has it.
UDID="$(xcrun simctl list devices available --json | DEVICE="$DEVICE" python3 -c '
import json, os, sys
devices = json.load(sys.stdin)["devices"]
matches = [(runtime, device) for runtime, entries in devices.items() if ".iOS-" in runtime
           for device in entries if device["name"] == os.environ["DEVICE"]]
matches.sort(key=lambda match: (match[1]["state"] == "Booted", match[0]))
print(matches[-1][1]["udid"] if matches else "")
')"
if [ -z "$UDID" ]; then
  echo "No available simulator named \"$DEVICE\"." >&2
  exit 1
fi
DESTINATION="id=${UDID}"

if [ ! -d Mooligan.xcworkspace ]; then
  tuist generate --no-open
fi

ONLY=()
if [ "$#" -eq 0 ]; then
  ONLY=(-only-testing:MooliganSnapshotTests)
else
  for target in "$@"; do
    ONLY+=("-only-testing:MooliganSnapshotTests/${target}")
  done
fi

LOG_DIR="$(mktemp -d)"

run_tests() {
  xcodebuild test \
    -workspace Mooligan.xcworkspace \
    -scheme Mooligan \
    -destination "$DESTINATION" \
    -collect-test-diagnostics never \
    "${ONLY[@]}"
}

echo "Recording snapshots (RECORD=${MODE}) on ${DEVICE} (${UDID})…"
# TEST_RUNNER_ passes the variable through to the test process.
TEST_RUNNER_SNAPSHOT_TESTING_RECORD="$MODE" run_tests > "$LOG_DIR/record.log" 2>&1 || true
if grep -q "xcodebuild: error:" "$LOG_DIR/record.log"; then
  echo "Recording could not run. Log: $LOG_DIR/record.log" >&2
  grep "xcodebuild: error:" "$LOG_DIR/record.log" >&2
  exit 1
fi

echo "Checking the new references…"
if run_tests > "$LOG_DIR/verify.log" 2>&1; then
  echo "Snapshots pass."
else
  echo "Snapshots still fail after recording. Log: $LOG_DIR/verify.log" >&2
  grep -E "error:|✘" "$LOG_DIR/verify.log" | head -20 >&2 || true
  exit 1
fi

echo "Changed references (review them before committing):"
git status --short -- Mooligan/SnapshotTests/__Snapshots__
