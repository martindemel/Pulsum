#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

pass() { printf "\033[32m%s\033[0m\n" "$1"; }
fail() { printf "\033[31m%s\033[0m\n" "$1"; exit 1; }
info() { printf "\033[36m%s\033[0m\n" "$1"; }

usage() {
  cat <<'USAGE'
Usage: scripts/ci/integrity.sh [--strict]

Options:
  --strict   Require HEAD == origin/main (default allows ahead commits).
USAGE
}

STRICT="${PULSUM_INTEGRITY_STRICT:-0}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict)
      STRICT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1"
      ;;
  esac
done

info "Pulsum integrity sweep"

info "Git sync"
git fetch origin >/dev/null 2>&1 || true
if ! git show-ref --verify --quiet refs/remotes/origin/main; then
  fail "origin/main not found. Run: git fetch origin main"
fi
COUNTS="$(git rev-list --left-right --count origin/main...HEAD)"
BEHIND="${COUNTS%% *}"
AHEAD="${COUNTS##* }"
info "Branch divergence (origin/main...HEAD): behind=$BEHIND ahead=$AHEAD"
if [ "$BEHIND" -ne 0 ]; then
  fail "branch is behind origin/main by $BEHIND commit(s). Run: git fetch origin && git rebase origin/main"
fi
if [ "$STRICT" -eq 1 ] && [ "$AHEAD" -ne 0 ]; then
  fail "strict mode requires HEAD == origin/main (ahead by $AHEAD). Use: git checkout origin/main or re-run without --strict"
fi
if [ "$AHEAD" -eq 0 ]; then
  pass "branch is in sync with origin/main"
else
  pass "origin/main is an ancestor of HEAD (ahead by $AHEAD)"
fi
LOCAL_HEAD="$(git rev-parse HEAD)"

info "Tag position (gate0-done-2025-11-09)"
if [ "$STRICT" -eq 1 ] || { [ "$BEHIND" -eq 0 ] && [ "$AHEAD" -eq 0 ]; }; then
  if git rev-parse -q --verify refs/tags/gate0-done-2025-11-09 >/dev/null; then
    TAG_HEAD="$(git rev-parse gate0-done-2025-11-09^{})"
    [ "$TAG_HEAD" = "$LOCAL_HEAD" ] || fail "tag gate0-done-2025-11-09 != HEAD"
    pass "tag gate0-done-2025-11-09 points at HEAD"
  else
    info "tag gate0-done-2025-11-09 not found (ok if not tagged)"
  fi
else
  info "tag check skipped (not on origin/main)"
fi

info "Git integrity"
git fsck --no-reflogs >/dev/null 2>&1 || fail "git fsck failed"
if [ "${CI_ALLOW_DIRTY:-0}" = "1" ]; then
  info "CI_ALLOW_DIRTY=1 → skipping clean working tree enforcement"
else
  DIRTY_COUNT="$(git status --porcelain=v1 | wc -l | tr -d ' ')"
  if [ "$DIRTY_COUNT" -ne 0 ]; then
    git status --porcelain=v1
    fail "working tree has uncommitted changes. Commit, stash, or set CI_ALLOW_DIRTY=1."
  fi
  pass "working tree clean"
fi

info "Ignore hygiene"
TRACKED_BUILD="$(git ls-files Build | wc -l | tr -d ' ')"
[ "$TRACKED_BUILD" -eq 0 ] || fail "tracked files exist under Build/"
pass "no tracked files under Build/"

info "Project backup audit"
BACKUPS="$(git ls-files '*.pbxproj.backup' 2>/dev/null || true)"
if [ -n "$BACKUPS" ]; then
  printf '%s\n' "$BACKUPS"
  fail "found tracked *.pbxproj.backup files"
fi
pass "no *.pbxproj.backup files tracked"

info "PBX manifest uniqueness"
PBX_COUNTS="$(python3 - <<'PY'
import re
from pathlib import Path
text = Path("Pulsum.xcodeproj/project.pbxproj").read_text()
fr = len(re.findall(r'PBXFileReference[^\n]*PrivacyInfo\.xcprivacy', text))
br = len(re.findall(r'PBXBuildFile[^\n]*PrivacyInfo\.xcprivacy', text))
print(fr, br)
PY
)"
FR="${PBX_COUNTS% *}"
BR="${PBX_COUNTS#* }"
[ "$FR" -eq 1 ] && [ "$BR" -eq 1 ] || fail "expected FR=1 BR=1 for PrivacyInfo.xcprivacy, got FR=$FR BR=$BR"
pass "PrivacyInfo.xcprivacy counts FR=1 BR=1"

info "Dataset canonicality"
python3 - <<'PY' || fail "dataset hash check failed"
import hashlib, json, subprocess, sys
try:
    raw = subprocess.check_output([
        "git", "ls-files", "-z",
        "podcastrecommendations*.json", "json database/podcastrecommendations*.json"
    ], text=True)
except subprocess.CalledProcessError:
    raw = ""
paths = [p for p in raw.split("\x00") if p]
if not paths:
    print("no podcast dataset JSON found")
    sys.exit(1)
hashes = {}
for path in paths:
    with open(path, "rb") as fh:
        digest = hashlib.sha256(fh.read()).hexdigest()
    hashes.setdefault(digest, []).append(path)
print("dataset_hashes:", json.dumps(hashes, indent=2))
if len(hashes) != 1:
    print(f"expected single canonical dataset hash, found {len(hashes)}")
    sys.exit(1)
PY
pass "podcast dataset hash unique"

info "Secret scan (repo)"
if [ -x scripts/ci/scan-secrets.sh ]; then
  scripts/ci/scan-secrets.sh >/tmp/pulsum_secret_repo.log 2>&1 || { cat /tmp/pulsum_secret_repo.log; fail "secret scan (repo) failed"; }
  pass "secret scan (repo) passed"
else
  info "scripts/ci/scan-secrets.sh not found; skipped"
fi

info "Placeholder audit"
if [ -x scripts/ci/scan-placeholders.sh ]; then
  scripts/ci/scan-placeholders.sh >/tmp/pulsum_placeholder_scan.log 2>&1 || { cat /tmp/pulsum_placeholder_scan.log; fail "placeholder scan failed"; }
  pass "no forbidden placeholders"
else
  info "scripts/ci/scan-placeholders.sh not found; skipped"
fi

info "Privacy manifests"
if [ -x scripts/ci/check-privacy-manifests.sh ]; then
  scripts/ci/check-privacy-manifests.sh >/tmp/pulsum_privacy.log 2>&1 || { cat /tmp/pulsum_privacy.log; fail "privacy manifest check failed"; }
  pass "privacy manifests ok"
else
  info "scripts/ci/check-privacy-manifests.sh not found; skipped"
fi

info "Gate test harness"
if [ -x scripts/ci/test-harness.sh ]; then
  scripts/ci/test-harness.sh >/tmp/pulsum_gate_harness.log 2>&1 || { tail -n +1 /tmp/pulsum_gate_harness.log; fail "gate test harness failed"; }
  pass "dynamic gate suites executed"
else
  info "scripts/ci/test-harness.sh not found; skipped"
fi

info "Release build (signing disabled)"
BUILD_RELEASE_ARGS=()
if [ -n "${PULSUM_INTEGRITY_DESTINATION:-}" ]; then
  BUILD_RELEASE_ARGS+=(--destination "$PULSUM_INTEGRITY_DESTINATION")
fi
scripts/ci/build-release.sh "${BUILD_RELEASE_ARGS[@]}" >/tmp/pulsum_xcbuild.log 2>&1 || \
fail "xcodebuild Release failed; see /tmp/pulsum_xcbuild.log"
pass "Release build ok"

info "Gate-0 tests"
SVC_OK=0; DATA_OK=0; ML_OK=0
swift test --package-path Packages/PulsumServices -Xswiftc -strict-concurrency=complete --filter Gate0_  >/tmp/pulsum_services_tests.log 2>&1 && SVC_OK=1 || true
swift test --package-path Packages/PulsumData     -Xswiftc -strict-concurrency=complete --filter Gate0_  >/tmp/pulsum_data_tests.log     2>&1 && DATA_OK=1 || true
swift test --package-path Packages/PulsumML       -Xswiftc -strict-concurrency=complete --filter Gate0_  >/tmp/pulsum_ml_tests.log       2>&1 && ML_OK=1 || true
[ "$SVC_OK"  -eq 1 ] || { tail -n +1 /tmp/pulsum_services_tests.log; fail "PulsumServices Gate0_ tests failed"; }
[ "$DATA_OK" -eq 1 ] || { tail -n +1 /tmp/pulsum_data_tests.log;     fail "PulsumData Gate0_ tests failed"; }
[ "$ML_OK"   -eq 1 ] || { tail -n +1 /tmp/pulsum_ml_tests.log;       fail "PulsumML Gate0_ tests failed"; }
pass "Gate-0 tests ok"

info "Bundle secret rescan"
if [ -x scripts/ci/scan-secrets.sh ]; then
  APP_PATH=""
  for candidate in \
    "Build/DerivedData/Build/Products/Release-iphoneos/Pulsum.app" \
    "Build/DerivedData/Build/Products/Release-iphonesimulator/Pulsum.app" \
    "Build/Build/Products/Release-iphoneos/Pulsum.app" \
    "Build/Build/Products/Release-iphonesimulator/Pulsum.app"
  do
    if [ -d "$candidate" ]; then
      APP_PATH="$candidate"
      break
    fi
  done
  if [ -n "$APP_PATH" ]; then
    scripts/ci/scan-secrets.sh "$APP_PATH" >/tmp/pulsum_secret_bundle.log 2>&1 || { cat /tmp/pulsum_secret_bundle.log; fail "secret scan (bundle) failed"; }
    pass "secret scan (bundle) passed"
  else
    info "no built app bundle found; skipped bundle scan"
  fi
fi

pass "Integrity sweep completed"
