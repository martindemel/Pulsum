#!/usr/bin/env bash
set -euo pipefail

# Config (override via env)
SCHEME="${SCHEME:-Pulsum}"
CONFIG="${CONFIG:-Debug}"
DERIVED="${DERIVED:-Build}"
DEVICE_NAME="${DEVICE_NAME:-iPhone 17 Pro}"
OS_VERSION="${OS_VERSION:-26.1}"
DEST="platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}"

xc() {
  if command -v xcbeautify >/dev/null 2>&1; then
    xcodebuild "$@" | xcbeautify
  else
    xcodebuild "$@"
  fi
}

# Fresh derived data
rm -rf "$DERIVED"
mkdir -p "$DERIVED"

# Make sure destination simulator exists & is booted (best-effort)
SIM_UDID="$(xcrun simctl list devices | awk -v name="$DEVICE_NAME" -v os="$OS_VERSION" '$0 ~ name && $0 ~ os {print $2}' | tr -d '()' | head -n1 || true)"
if [[ -n "${SIM_UDID:-}" ]]; then
  xcrun simctl bootstatus "$SIM_UDID" -b || xcrun simctl boot "$SIM_UDID" || true
fi

# 1) Build for testing (Debug, simulator) – disable codesign for test bundles
xc -project Pulsum.xcodeproj \
   -scheme "$SCHEME" \
   -configuration "$CONFIG" \
   -destination "$DEST" \
   -derivedDataPath "$DERIVED" \
   CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO \
   build-for-testing

# 2) Test without building – run ONLY UI tests, inject seams, disable parallel clones
UITEST_USE_STUB_LLM=1 UITEST_FAKE_SPEECH=1 UITEST_AUTOGRANT=1 \
xc -project Pulsum.xcodeproj \
   -scheme "$SCHEME" \
   -configuration "$CONFIG" \
   -destination "$DEST" \
   -derivedDataPath "$DERIVED" \
   -parallel-testing-enabled NO \
   -maximum-concurrent-test-simulator-destinations 1 \
   -only-testing:PulsumUITests \
   test-without-building
