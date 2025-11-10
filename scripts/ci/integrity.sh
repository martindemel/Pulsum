#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

pass() { printf "\033[32m%s\033[0m\n" "$1"; }
fail() { printf "\033[31m%s\033[0m\n" "$1"; exit 1; }
info() { printf "\033[36m%s\033[0m\n" "$1"; }

info "Pulsum integrity sweep"

info "Git sync"
git fetch origin >/dev/null 2>&1 || true
LOCAL_HEAD="$(git rev-parse HEAD)"
REMOTE_HEAD="$(git rev-parse origin/main)"
[ "$LOCAL_HEAD" = "$REMOTE_HEAD" ] || fail "local HEAD != origin/main"
pass "local HEAD matches origin/main"

info "Tag position (gate0-done-2025-11-09)"
if git rev-parse -q --verify refs/tags/gate0-done-2025-11-09 >/dev/null; then
  TAG_HEAD="$(git rev-parse gate0-done-2025-11-09^{})"
  [ "$TAG_HEAD" = "$LOCAL_HEAD" ] || fail "tag gate0-done-2025-11-09 != HEAD"
  pass "tag gate0-done-2025-11-09 points at HEAD"
else
  info "tag gate0-done-2025-11-09 not found (ok if not tagged)"
fi

info "Git integrity"
git fsck --no-reflogs >/dev/null 2>&1 || fail "git fsck failed"
DIRTY_COUNT="$(git status --porcelain=v1 | wc -l | tr -d ' ')"
[ "$DIRTY_COUNT" -eq 0 ] || fail "working tree has uncommitted changes"
pass "working tree clean"

info "Ignore hygiene"
TRACKED_BUILD="$(git ls-files Build | wc -l | tr -d ' ')"
[ "$TRACKED_BUILD" -eq 0 ] || fail "tracked files exist under Build/"
pass "no tracked files under Build/"

info "PBX manifest uniqueness"
FR=$(grep -n 'PBXFileReference .*PrivacyInfo\.xcprivacy' Pulsum.xcodeproj/project.pbxproj | wc -l | tr -d ' ')
BR=$(grep -n 'PBXBuildFile .*PrivacyInfo\.xcprivacy in Resources' Pulsum.xcodeproj/project.pbxproj | wc -l | tr -d ' ')
[ "$FR" -eq 1 ] && [ "$BR" -eq 1 ] || fail "expected FR=1 BR=1 for PrivacyInfo.xcprivacy, got FR=$FR BR=$BR"
pass "PrivacyInfo.xcprivacy counts FR=1 BR=1"

info "Secret scan (repo)"
if [ -x scripts/ci/scan-secrets.sh ]; then
  scripts/ci/scan-secrets.sh >/tmp/pulsum_secret_repo.log 2>&1 || { cat /tmp/pulsum_secret_repo.log; fail "secret scan (repo) failed"; }
  pass "secret scan (repo) passed"
else
  info "scripts/ci/scan-secrets.sh not found; skipped"
fi

info "Privacy manifests"
if [ -x scripts/ci/check-privacy-manifests.sh ]; then
  scripts/ci/check-privacy-manifests.sh >/tmp/pulsum_privacy.log 2>&1 || { cat /tmp/pulsum_privacy.log; fail "privacy manifest check failed"; }
  pass "privacy manifests ok"
else
  info "scripts/ci/check-privacy-manifests.sh not found; skipped"
fi

info "Release build (signing disabled)"
DEST1="platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0"
DEST2="platform=iOS Simulator,name=iPhone 15,OS=26.0"
scripts/ci/build-release.sh -destination "$DEST1" -derivedDataPath Build >/tmp/pulsum_xcbuild.log 2>&1 || \
scripts/ci/build-release.sh -destination "$DEST2" -derivedDataPath Build >/tmp/pulsum_xcbuild.log 2>&1 || \
fail "xcodebuild Release failed; see /tmp/pulsum_xcbuild.log"
pass "Release build ok"

info "Gate-0 tests"
SVC_OK=0; DATA_OK=0; ML_OK=0
swift test --package-path Packages/PulsumServices --filter Gate0_  >/tmp/pulsum_services_tests.log 2>&1 && SVC_OK=1 || true
swift test --package-path Packages/PulsumData     --filter Gate0_  >/tmp/pulsum_data_tests.log     2>&1 && DATA_OK=1 || true
swift test --package-path Packages/PulsumML       --filter Gate0_  >/tmp/pulsum_ml_tests.log       2>&1 && ML_OK=1 || true
[ "$SVC_OK"  -eq 1 ] || { tail -n +1 /tmp/pulsum_services_tests.log; fail "PulsumServices Gate0_ tests failed"; }
[ "$DATA_OK" -eq 1 ] || { tail -n +1 /tmp/pulsum_data_tests.log;     fail "PulsumData Gate0_ tests failed"; }
[ "$ML_OK"   -eq 1 ] || { tail -n +1 /tmp/pulsum_ml_tests.log;       fail "PulsumML Gate0_ tests failed"; }
pass "Gate-0 tests ok"

info "Bundle secret rescan"
if [ -x scripts/ci/scan-secrets.sh ]; then
  APP_PATH="Build/Build/Products/Release-iphonesimulator/Pulsum.app"
  if [ -d "$APP_PATH" ]; then
    scripts/ci/scan-secrets.sh "$APP_PATH" >/tmp/pulsum_secret_bundle.log 2>&1 || { cat /tmp/pulsum_secret_bundle.log; fail "secret scan (bundle) failed"; }
    pass "secret scan (bundle) passed"
  else
    info "no built app bundle found; skipped bundle scan"
  fi
fi

pass "Integrity sweep completed"
