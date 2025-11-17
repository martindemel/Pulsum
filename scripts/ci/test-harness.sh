#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

export COPYFILE_DISABLE=1

LOG_DIR="${TMPDIR:-/tmp}"
info() { printf '\033[36m%s\033[0m\n' "$1"; }
pass() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m%s\033[0m\n' "$1"; exit 1; }

build_app_target() {
  if ! command -v xcodebuild >/dev/null; then
    info "[gate-ci] xcodebuild not available; skipping Pulsum app build"
    return
  fi

  info "[gate-ci] Building Pulsum app target (Debug/iOS Simulator)"
  local build_cmd=(xcodebuild -scheme Pulsum -configuration Debug -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=26.0" build)
  local log_file="$LOG_DIR/pulsum_app_build.log"
  if command -v xcpretty >/dev/null; then
    if ! "${build_cmd[@]}" | tee "$log_file" | xcpretty; then
      tail -n 50 "$log_file" || true
      fail "[gate-ci] Pulsum app build failed (see $log_file)"
    fi
  else
    if ! "${build_cmd[@]}" >"$log_file" 2>&1; then
      tail -n 50 "$log_file" || true
      fail "[gate-ci] Pulsum app build failed (see $log_file)"
    fi
  fi
  pass "[gate-ci] Pulsum app target built successfully"
}

discover_and_run_spm_gate_tests() {
  local package_dir="$1"
  local package_name
  package_name="$(basename "$package_dir")"
  local list_output

  if [ ! -d "$package_dir" ]; then
    info "[gate-ci] $package_dir not found; skipping"
    return
  fi

  info "[gate-ci] Enumerating Gate suites in $package_name"
  if ! list_output="$(cd "$package_dir" && swift test --list-tests 2>/dev/null)"; then
    fail "[gate-ci] swift test --list-tests failed for $package_name"
  fi

  local patterns
  patterns="$(printf "%s\n" "$list_output" | sed -En 's/.*(Gate[0-9]+_).*/\1/p' | sort -u)"
  if [ -z "$patterns" ]; then
    info "[gate-ci] No Gate suites found in $package_name — skipping"
    return
  fi

  local joined
  joined="$(printf "%s" "$patterns" | paste -sd'|' -)"
  local log_suffix
  log_suffix="$(printf "%s" "$package_name" | tr '[:upper:]' '[:lower:]')"
  local log_file="$LOG_DIR/pulsum_${log_suffix}_gate.log"

  info "[gate-ci] Running $package_name tests matching (${joined})"
  if (cd "$package_dir" && swift test --parallel --filter "(${joined})") >"$log_file" 2>&1; then
    pass "[gate-ci] $package_name Gate suites passed"
  else
    tail -n 50 "$log_file" || true
    fail "[gate-ci] $package_name Gate suites failed (see $log_file)"
  fi
}

run_xcode_ui_gate_tests() {
  local log_file="$LOG_DIR/pulsum_ui_gate.log"

  if [ "${SKIP_UI_GATES:-0}" = "1" ]; then
    info "[gate-ci] SKIP_UI_GATES=1 → skipping UI Gate tests"
    return
  fi

  if ! command -v xcodebuild >/dev/null; then
    info "[gate-ci] xcodebuild not available; skipping UI Gate tests"
    return
  fi

  if ! command -v xcrun >/dev/null; then
    info "[gate-ci] xcrun not available; skipping UI Gate tests"
    return
  fi

  local devices
  devices="$(xcrun simctl list devices available 2>/dev/null || true)"

  local preferred=(
    "iPhone 16 Pro"
    "iPhone 16"
    "iPhone 17"
    "iPhone 16 Plus"
    "iPhone 15"
  )

  local preferred_json="["
  for candidate in "${preferred[@]}"; do
    preferred_json+="\"${candidate//\"/\\\"}\","
  done
  preferred_json="${preferred_json%,}]"

  local selection
  selection="$(printf "%s\n" "$devices" | python3 -c 'import json, sys
preferences = json.loads(sys.argv[1])
text = sys.stdin.read().splitlines()
entries = []
current = None

for raw in text:
    line = raw.strip()
    if line.startswith("--") and line.endswith("--"):
        current = line.strip("- ").strip()
        continue
    if "(" in line and ")" in line:
        name = line.split(" (", 1)[0].strip()
        udid = None
        parts = line.split("(")
        if len(parts) > 1:
            udid = parts[1].split(")")[0].strip()
        if current and current.startswith("iOS"):
            os = current.split(None, 1)[1]
            entries.append((name, os, udid))

def pick(preferred_names, os_prefix=None):
    for pref in preferred_names:
        for name, os, udid in entries:
            if name == pref and (os_prefix is None or os.startswith(os_prefix)):
                return name, os, udid
    return None

selection = pick(preferences, "26")
if selection is None:
    for name, os, udid in entries:
        if os.startswith("26"):
            selection = (name, os, udid)
            break
if selection is None:
    selection = pick(preferences)
if selection is None and entries:
    selection = entries[0]

if selection:
    print(selection[0])
    print(selection[1])
    print(selection[2] or "")' "$preferred_json")"

  local dest_name dest_os dest_udid
  dest_name="$(printf "%s\n" "$selection" | sed -n '1p')"
  dest_os="$(printf "%s\n" "$selection" | sed -n '2p')"
  dest_udid="$(printf "%s\n" "$selection" | sed -n '3p')"

  if [ -z "$dest_name" ]; then
    dest_name="iPhone 16 Pro"
    dest_os="26.0"
  fi

  local destination="platform=iOS Simulator,name=${dest_name}"
  if [ -n "$dest_udid" ]; then
    destination="id=${dest_udid}"
  elif [ -n "$dest_os" ]; then
    destination+=",OS=${dest_os}"
  fi

  info "[gate-ci] Running UI Gate tests on ${dest_name} (${dest_os})"
  if UITEST_FAKE_SPEECH=1 UITEST_AUTOGRANT=1 \
     xcodebuild -scheme Pulsum -destination "$destination" \
     -only-testing:PulsumUITests clean test >"$log_file" 2>&1; then
    pass "[gate-ci] UI Gate tests passed"
  else
    tail -n 100 "$log_file" || true
    fail "[gate-ci] UI Gate tests failed (see $log_file)"
  fi
}

PACKAGES=(
  "Packages/PulsumServices"
  "Packages/PulsumAgents"
  "Packages/PulsumML"
  "Packages/PulsumData"
)

build_app_target

for package in "${PACKAGES[@]}"; do
  discover_and_run_spm_gate_tests "$package"
done

run_xcode_ui_gate_tests

pass "[harness] ✅ Gate suites completed"
