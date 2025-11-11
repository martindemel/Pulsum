#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

export COPYFILE_DISABLE=1

LOG_DIR="${TMPDIR:-/tmp}"
DERIVED_DIR="$(mktemp -d ${TMPDIR:-/tmp}/pulsum-derived.XXXXXX)"
trap 'rm -rf "$DERIVED_DIR"' EXIT
XCODE_LOG="$LOG_DIR/pulsum_xcode_tests.log"
SERVICES_LOG="$LOG_DIR/pulsum_services_gate.log"
DATA_LOG="$LOG_DIR/pulsum_data_gate.log"
ML_LOG="$LOG_DIR/pulsum_ml_gate.log"
SECRET_LOG="$LOG_DIR/pulsum_secret_scan.log"
PRIVACY_LOG="$LOG_DIR/pulsum_privacy_check.log"

info() { printf '\033[36m%s\033[0m\n' "$1"; }
pass() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m%s\033[0m\n' "$1"; exit 1; }

run_with_log() {
  local description="$1"
  local command="$2"
  local log_file="$3"

  info "$description"
  if eval "$command" >"$log_file" 2>&1; then
    pass "$description ✅"
  else
    tail -n 50 "$log_file" || true
    fail "$description failed. See $log_file"
  fi
}

info "Running Gate-0 integrity sweeps"
run_with_log "Secret scan" "scripts/ci/scan-secrets.sh" "$SECRET_LOG"
run_with_log "Privacy manifest check" "scripts/ci/check-privacy-manifests.sh" "$PRIVACY_LOG"

info "Running Pulsum.xcodeproj tests"
DEST_PRIMARY="platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0"
DEST_FALLBACK="platform=iOS Simulator,name=iPhone 15,OS=26.0"

run_xcode_tests() {
  local destination="$1"
  info "Building for $destination"
  if ! xcodebuild build-for-testing -scheme Pulsum -configuration Debug -destination "$destination" -derivedDataPath "$DERIVED_DIR" >"$XCODE_LOG" 2>&1; then
    return 1
  fi
  info "Executing tests for $destination"
  xcodebuild test-without-building -scheme Pulsum -configuration Debug -destination "$destination" -derivedDataPath "$DERIVED_DIR" >>"$XCODE_LOG" 2>&1
}

if run_xcode_tests "$DEST_PRIMARY"; then
  pass "xcodebuild test succeeded on iPhone 16 Pro"
else
  info "Primary destination failed, retrying on iPhone 15"
  if run_xcode_tests "$DEST_FALLBACK"; then
    pass "xcodebuild test succeeded on iPhone 15"
  else
    tail -n 50 "$XCODE_LOG" || true
    fail "xcodebuild test failed on both destinations. See $XCODE_LOG"
  fi
fi

info "Running focused Gate tests via swift test"
run_with_log "PulsumServices Gate subsets" "swift test --package-path Packages/PulsumServices --filter 'Gate0_|Gate1_'" "$SERVICES_LOG"
run_with_log "PulsumData Gate subsets" "swift test --package-path Packages/PulsumData --filter 'Gate0_|Gate1_'" "$DATA_LOG"
run_with_log "PulsumML Gate subsets" "swift test --package-path Packages/PulsumML --filter 'Gate0_|Gate1_'" "$ML_LOG"

pass "[harness] ✅ Gate-1 harness completed (logs: $XCODE_LOG, $SERVICES_LOG, $DATA_LOG, $ML_LOG)"
