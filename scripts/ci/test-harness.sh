#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

export COPYFILE_DISABLE=1

LOG_DIR="${TMPDIR:-/tmp}"
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

info "Running Swift package Gate tests"
run_with_log "PulsumServices Gate subsets" "swift test --package-path Packages/PulsumServices --filter 'Gate0_|Gate1_'" "$SERVICES_LOG"
run_with_log "PulsumData Gate subsets" "swift test --package-path Packages/PulsumData --filter 'Gate0_|Gate1_'" "$DATA_LOG"
run_with_log "PulsumML Gate subsets" "swift test --package-path Packages/PulsumML --filter 'Gate0_|Gate1_'" "$ML_LOG"

pass "[harness] ✅ Package Gate tests completed (logs: $SERVICES_LOG, $DATA_LOG, $ML_LOG)"
