#!/usr/bin/env bash
set -euo pipefail

SCHEME="${SCHEME:-Pulsum}"
CONFIG="${CONFIG:-Debug}"
DERIVED="${DERIVED:-Build}"

# Prefer newer models, then fallback. Names must match `simctl list devices`.
DEVICE_CANDIDATES=(
  "iPhone 17 Pro"
  "iPhone 17"
  "iPhone 16 Pro"
  "iPhone 16"
  "iPhone SE (3rd generation)"
)

# Do NOT pin a patch version; let xcodebuild pick the newest available runtime.
OS_SPEC="${OS_SPEC:-latest}"

# Helper: xcodebuild with optional xcbeautify
xc() {
  if command -v xcbeautify >/dev/null 2>&1; then
    xcodebuild "$@" | xcbeautify
  else
    xcodebuild "$@"
  fi
}

# Pick first available device by name
DEVICE_NAME=""
for name in "${DEVICE_CANDIDATES[@]}"; do
  if xcrun simctl list devices | grep -q "^[[:space:]]*${name} ("; then
    DEVICE_NAME="$name"
    break
  fi
done
: "${DEVICE_NAME:=iPhone 17 Pro}"

DEST="platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_SPEC}"

echo "Using simulator: ${DEVICE_NAME} (OS=${OS_SPEC})"
echo "Destination: ${DEST}"

# Clean derived data
rm -rf "$DERIVED"
mkdir -p "$DERIVED"

# Best-effort: boot and wait for the device by name
xcrun simctl boot "$DEVICE_NAME" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$DEVICE_NAME" -b || true

# Build for testing (Debug, codesign off)
xc \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "$DEST" \
  -destination-timeout 180 \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
  build-for-testing

# Run only UI tests, deterministic seams, single sim (no parallel clones)
UITEST_USE_STUB_LLM=1 UITEST_FAKE_SPEECH=1 UITEST_AUTOGRANT=1 \
xc \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -destination "$DEST" \
  -destination-timeout 180 \
  -derivedDataPath "$DERIVED" \
  -parallel-testing-enabled NO \
  -maximum-concurrent-test-simulator-destinations 1 \
  -only-testing:PulsumUITests \
  test-without-building
