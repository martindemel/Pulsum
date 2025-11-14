#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

RED="\033[31m"
NC="\033[0m"

die() {
  echo -e "${RED}placeholder scan failed:${NC} $1" >&2
  exit 1
}

PATTERN='(?i)\b(TODO|TBD|FIXME|lorem ipsum|placeholder|dummy)\b'

if rg --no-heading --line-number --color never --pcre2 "$PATTERN" \
  Pulsum Packages \
  --glob '!**/Tests/**' \
  --glob '!Docs/**' \
  --glob '!**/*.md' \
  --glob '!**/*.txt'; then
  die "remove the placeholder terms listed above (tests/docs are excluded automatically)"
fi

echo "[placeholder-scan] ✅ no forbidden placeholders detected"
