#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

RED="\033[31m"
NC="\033[0m"

die() {
  echo -e "${RED}secret scan failed:${NC} $1" >&2
  exit 1
}

echo "[secret-scan] scanning repository for leaked keys..."
SEARCH_PATHS=(Pulsum Packages Config.xcconfig Pulsum.xcodeproj)
REGEX_PATTERNS=(
  'sk-[A-Za-z0-9_-]{10,}'
  'sk-proj-[A-Za-z0-9_-]{5,}'
  'OPENAI_API_KEY\s*='
  'PULSUM_COACH_API_KEY\s*='
  'INFOPLIST_KEY_OPENAI_API_KEY'
)

for pattern in "${REGEX_PATTERNS[@]}"; do
  if rg --no-heading --line-number --color never --text --pcre2 -e "$pattern" "${SEARCH_PATHS[@]}" >/tmp/pulsum-secret-scan.log; then
    cat /tmp/pulsum-secret-scan.log >&2
    rm -f /tmp/pulsum-secret-scan.log
    die "pattern '${pattern}' detected in source tree"
  fi
  rm -f /tmp/pulsum-secret-scan.log
done

APP_INPUT="${1:-${PULSUM_APP_PATH:-}}"
TMPDIR_PATH=""
if [[ -n "$APP_INPUT" ]]; then
  if [[ -f "$APP_INPUT" && "$APP_INPUT" == *.ipa ]]; then
    TMPDIR_PATH="$(mktemp -d)"
    unzip -qq "$APP_INPUT" -d "$TMPDIR_PATH"
    APP_PATH="$(find "$TMPDIR_PATH" -name "*.app" -type d | head -n 1)"
  else
    APP_PATH="$APP_INPUT"
  fi

  if [[ ! -d "$APP_PATH" ]]; then
    die "provided app bundle '$APP_INPUT' does not exist"
  fi

  echo "[secret-scan] scanning app bundle: $APP_PATH"
  if rg --no-heading --line-number --color never --text --pcre2 \
    -e 'sk-[A-Za-z0-9_-]{10,}' \
    -e 'sk-proj-[A-Za-z0-9_-]{5,}' \
    -e 'OPENAI_API_KEY\s*=' \
    -e 'PULSUM_COACH_API_KEY\s*=' \
    -e 'INFOPLIST_KEY_OPENAI_API_KEY' \
    "$APP_PATH" >/tmp/pulsum-secret-scan.log; then
    cat /tmp/pulsum-secret-scan.log >&2
    rm -f /tmp/pulsum-secret-scan.log
    [[ -n "$TMPDIR_PATH" ]] && rm -rf "$TMPDIR_PATH"
    die "credential pattern detected inside app bundle"
  fi
  rm -f /tmp/pulsum-secret-scan.log
  [[ -n "$TMPDIR_PATH" ]] && rm -rf "$TMPDIR_PATH"
fi

echo "[secret-scan] ✅ no secrets detected"
