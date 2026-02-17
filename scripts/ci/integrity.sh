#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

pass() { printf "\033[32m%s\033[0m\n" "$1"; }
fail() { printf "\033[31m%s\033[0m\n" "$1"; exit 1; }
info() { printf "\033[36m%s\033[0m\n" "$1"; }

usage() {
  cat <<'USAGE'
Usage: scripts/ci/integrity.sh [--strict] [--lenient]

Options:
  --strict    Require HEAD == origin/main (default allows ahead commits).
  --lenient   Warn instead of failing on tag position mismatch (for local dev).
USAGE
}

STRICT="${PULSUM_INTEGRITY_STRICT:-0}"
LENIENT="${PULSUM_INTEGRITY_LENIENT:-0}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --strict)
      STRICT=1
      shift
      ;;
    --lenient)
      LENIENT=1
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
# B6-08 | LOW-09: Tag check is enforced by default. Use --lenient to warn only.
if git rev-parse -q --verify refs/tags/gate0-done-2025-11-09 >/dev/null; then
  TAG_HEAD="$(git rev-parse gate0-done-2025-11-09^{})"
  if [ "$TAG_HEAD" = "$LOCAL_HEAD" ]; then
    pass "tag gate0-done-2025-11-09 points at HEAD"
  elif git merge-base --is-ancestor "$TAG_HEAD" "$LOCAL_HEAD" 2>/dev/null; then
    # Tag is an ancestor of HEAD — acceptable when ahead of origin/main
    pass "tag gate0-done-2025-11-09 is an ancestor of HEAD (commits added since tag)"
  else
    if [ "$LENIENT" -eq 1 ]; then
      info "WARNING: tag gate0-done-2025-11-09 != HEAD and is not an ancestor (--lenient: continuing)"
    else
      fail "tag gate0-done-2025-11-09 != HEAD and is not an ancestor. Use --lenient for local dev."
    fi
  fi
else
  if [ "$LENIENT" -eq 1 ]; then
    info "WARNING: tag gate0-done-2025-11-09 not found (--lenient: continuing)"
  else
    fail "tag gate0-done-2025-11-09 not found. Create with: git tag gate0-done-2025-11-09 <commit>. Use --lenient for local dev."
  fi
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

# B6-11 | LOW-13: Pure shell PBX manifest check (no Python dependency).
info "PBX manifest uniqueness"
PBX_FILE="Pulsum.xcodeproj/project.pbxproj"
FR="$(grep -c 'PBXFileReference.*PrivacyInfo\.xcprivacy' "$PBX_FILE" || echo 0)"
BR="$(grep -c 'PBXBuildFile.*PrivacyInfo\.xcprivacy' "$PBX_FILE" || echo 0)"
[ "$FR" -eq 1 ] && [ "$BR" -eq 1 ] || fail "expected FR=1 BR=1 for PrivacyInfo.xcprivacy, got FR=$FR BR=$BR"
pass "PrivacyInfo.xcprivacy counts FR=1 BR=1"

# B6-11 | LOW-13: Pure shell dataset canonicality check (no Python dependency).
info "Dataset canonicality"
DATASET_RAW="$(git ls-files -z 'podcastrecommendations*.json' 'json database/podcastrecommendations*.json' 2>/dev/null)" || DATASET_RAW=""
if [ -z "$DATASET_RAW" ]; then
  fail "no podcast dataset JSON found"
fi
DATASET_HASHES=""
DATASET_COUNT=0
while IFS= read -r -d '' dpath; do
  [ -z "$dpath" ] && continue
  dhash="$(shasum -a 256 "$dpath" | cut -d' ' -f1)"
  info "  $dpath -> $dhash"
  DATASET_HASHES="$DATASET_HASHES
$dhash"
  DATASET_COUNT=$((DATASET_COUNT + 1))
done <<< "$DATASET_RAW"
if [ "$DATASET_COUNT" -eq 0 ]; then
  fail "no podcast dataset JSON found"
fi
UNIQUE_HASHES="$(printf '%s' "$DATASET_HASHES" | sort -u | grep -c -v '^$')"
[ "$UNIQUE_HASHES" -eq 1 ] || fail "expected single canonical dataset hash, found $UNIQUE_HASHES"
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
