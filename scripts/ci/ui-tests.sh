#!/usr/bin/env bash
set -euo pipefail

SCHEME=${SCHEME:-Pulsum}
CONFIG=${CONFIG:-Debug}
DERIVED=${DERIVED:-Build}
DEVICE_NAME=${DEVICE_NAME:-"iPhone 17 Pro"}
OS_SPEC=${OS_SPEC:-26.1}

xc(){ if command -v xcbeautify >/dev/null 2>&1; then xcodebuild "$@" | xcbeautify; else xcodebuild "$@"; fi; }

SIM_UDID="$(xcrun simctl list devices | awk -v n="$DEVICE_NAME" -v os="$OS_SPEC" '$0 ~ n && $0 ~ os {print $2}' | tr -d "()" | head -n1 || true)"
if [[ -n "${SIM_UDID:-}" ]]; then
  DEST="id=$SIM_UDID"
  xcrun simctl bootstatus "$SIM_UDID" -b || xcrun simctl boot "$SIM_UDID" || true
else
  DEST="platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_SPEC}"
  xcrun simctl boot "$DEVICE_NAME" >/dev/null 2>&1 || true
  xcrun simctl bootstatus "$DEVICE_NAME" -b || true
fi

rm -rf "$DERIVED" && mkdir -p "$DERIVED"

xc -scheme "$SCHEME" -configuration "$CONFIG" -destination "$DEST" -destination-timeout 180 -derivedDataPath "$DERIVED" \
   CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build-for-testing

UITEST_USE_STUB_LLM=1 UITEST_FAKE_SPEECH=1 UITEST_AUTOGRANT=1 \
xc -scheme "$SCHEME" -configuration "$CONFIG" -destination "$DEST" -destination-timeout 180 -derivedDataPath "$DERIVED" \
   -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 -only-testing:PulsumUITests test-without-building
