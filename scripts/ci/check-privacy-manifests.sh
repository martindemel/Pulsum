#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

RED="\033[31m"
NC="\033[0m"

die() {
  echo -e "${RED}privacy manifest check failed:${NC} $1" >&2
  exit 1
}

MANIFESTS=(
  Pulsum/PrivacyInfo.xcprivacy
  Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy
  Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy
  Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy
  Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy
  Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy
)

for manifest in "${MANIFESTS[@]}"; do
  [[ -f "$manifest" ]] || die "missing privacy manifest: $manifest"
done

python3 - <<'PY'
import os
import sys
import plistlib

REQUIRED = {
    "Pulsum/PrivacyInfo.xcprivacy": {
        "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
    },
    "Packages/PulsumAgents/Sources/PulsumAgents/PrivacyInfo.xcprivacy": {
        "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
    },
    "Packages/PulsumData/Sources/PulsumData/PrivacyInfo.xcprivacy": {
        "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
    },
    "Packages/PulsumServices/Sources/PulsumServices/PrivacyInfo.xcprivacy": {
        "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
    },
    "Packages/PulsumML/Sources/PulsumML/PrivacyInfo.xcprivacy": {
        "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
    },
    "Packages/PulsumUI/Sources/PulsumUI/PrivacyInfo.xcprivacy": {
        "NSPrivacyAccessedAPICategoryUserDefaults": {"CA92.1"},
    },
}

errors = []

for path, expectations in REQUIRED.items():
    if not os.path.exists(path):
        errors.append(f"missing manifest: {path}")
        continue
    with open(path, "rb") as handle:
        data = plistlib.load(handle)
    types = data.get("NSPrivacyAccessedAPITypes", [])
    entries = {
        entry.get("NSPrivacyAccessedAPIType"): set(entry.get("NSPrivacyAccessedAPITypeReasons", []))
        for entry in types
    }
    for api_type, expected in expectations.items():
        have = entries.get(api_type, set())
        if not expected.issubset(have):
            missing = ", ".join(sorted(expected - have))
            errors.append(f"{path}: {api_type} missing reasons: {missing}")

if errors:
    print("\n".join(errors))
    sys.exit(1)

print("privacy manifests: ✅ basic checks passed")
PY

if command -v rg >/dev/null 2>&1; then
  RESOURCE_COUNT=$(rg --no-heading -n "PrivacyInfo\\.xcprivacy in Resources" Pulsum.xcodeproj/project.pbxproj | grep -v "PBXBuildFile" | wc -l | tr -d '[:space:]')
else
  RESOURCE_COUNT=$(grep -n "PrivacyInfo\\.xcprivacy in Resources" Pulsum.xcodeproj/project.pbxproj | grep -v "PBXBuildFile" | wc -l | tr -d '[:space:]')
fi
if [[ "${RESOURCE_COUNT:-0}" -ne 1 ]]; then
  die "expected exactly one 'PrivacyInfo.xcprivacy in Resources' entry in Pulsum target (found ${RESOURCE_COUNT:-0})"
fi

if [[ "${RUN_PRIVACY_REPORT:-0}" != "0" ]]; then
  if ! xcrun -f privacyreport >/dev/null 2>&1; then
    die "RUN_PRIVACY_REPORT is set but 'privacyreport' tool is unavailable"
  fi
  REPORT_DIR="${TMPDIR:-/tmp}/pulsum-privacy-report"
  rm -rf "$REPORT_DIR"
  mkdir -p "$REPORT_DIR"
  echo "[privacy-check] running xcrun privacyreport..."
  xcrun privacyreport generate --project Pulsum.xcodeproj --scheme Pulsum --output "$REPORT_DIR" >/dev/null
  echo "[privacy-check] report saved to $REPORT_DIR"
fi

echo "[privacy-check] ✅ manifests validated"
