#!/usr/bin/env bash
set -euo pipefail

SCHEME="${SCHEME:-Pulsum}"
CONFIG="${CONFIG:-Debug}"
DERIVED="${DERIVED:-Build}"

rm -rf "$DERIVED"
mkdir -p "$DERIVED"

# pick the first available iPhone simulator UDID on this host
UDID="$(xcrun simctl list devices available | awk -F'[()]' '/iPhone/ && $0 !~ /unavailable/ {print $2; exit}')"
if [ -z "${UDID:-}" ]; then
  echo "No available iPhone simulator found on this runner." >&2
  exit 1
fi

# boot it (best-effort)
xcrun simctl bootstatus "$UDID" -b || xcrun simctl boot "$UDID" || true

run() {
  if command -v xcbeautify >/dev/null 2>&1; then
    xcodebuild "$@" | xcbeautify
  else
    xcodebuild "$@"
  fi
}

# build-for-testing (Debug, codesign off for test bundles)
run -project Pulsum.xcodeproj \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" \
    CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
    build-for-testing

# test-without-building: only UI tests, deterministic seams, single destination
UITEST_USE_STUB_LLM=1 UITEST_FAKE_SPEECH=1 UITEST_AUTOGRANT=1 \
run -project Pulsum.xcodeproj \
    -scheme "$SCHEME" \
    -configuration "$CONFIG" \
    -destination "id=$UDID" \
    -derivedDataPath "$DERIVED" \
    -parallel-testing-enabled NO \
    -maximum-concurrent-test-simulator-destinations 1 \
    -only-testing:PulsumUITests \
    test-without-building
