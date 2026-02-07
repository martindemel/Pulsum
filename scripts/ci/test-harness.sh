#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

export COPYFILE_DISABLE=1

LOG_DIR="${TMPDIR:-/tmp}"
info() { printf '\033[36m%s\033[0m\n' "$1"; }
pass() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m%s\033[0m\n' "$1"; exit 1; }

select_simulator() {
  local desired_os="${PULSUM_SIM_OS:-26.0.1}"
  if ! command -v xcrun >/dev/null || ! command -v python3 >/dev/null; then
    printf "iPhone SE (3rd generation)\n%s\nplatform=iOS Simulator,name=iPhone SE (3rd generation),OS=%s\n" "$desired_os" "$desired_os"
    return
  fi

  local selection
  selection="$(python3 - <<'PY'
import json, os, re, subprocess, sys
preferred = [
    "iPhone SE (3rd generation)",
    "iPhone 16 Pro",
    "iPhone 16",
    "iPhone 16 Plus",
    "iPhone 15 Pro",
    "iPhone 15"
]
desired = os.environ.get("PULSUM_SIM_OS", "26.0.1")
major = desired.split(".")[0]
try:
    raw = subprocess.check_output(
        ["xcrun", "simctl", "list", "-j", "devices", "available"],
        text=True
    )
    data = json.loads(raw)
except (subprocess.CalledProcessError, json.JSONDecodeError):
    data = {}

entries = []
for runtime, devices in (data.get("devices") or {}).items():
    match = re.search(r"iOS[-\.](\d+)-(\d+)(?:-(\d+))?", runtime)
    if not match:
        continue
    parts = [match.group(1), match.group(2)]
    if match.group(3):
        parts.append(match.group(3))
    os_version = ".".join(parts)
    for device in devices or []:
        if device.get("isAvailable") and device.get("udid"):
            entries.append((device["name"], os_version, device["udid"]))

def pick(names, prefix=None):
    for name in names:
        for entry in entries:
            if entry[0] == name and (prefix is None or entry[1].startswith(prefix)):
                return entry
    return None

def pick_any(prefix):
    for entry in entries:
        if entry[1].startswith(prefix):
            return entry
    return None

selection = pick(preferred, prefix=desired)
if selection is None:
    selection = pick(preferred, prefix=major)
if selection is None:
    selection = pick_any(desired)
if selection is None:
    selection = pick_any(major)
if selection is None:
    selection = pick_any("26")
if selection is None:
    selection = pick_any("18")
if selection is None:
    selection = pick(preferred)
if selection is None and entries:
    selection = entries[0]

if selection:
    print(selection[0] or "")
    print(selection[1] or "")
    print(selection[2] or "")
PY)"

  local name os udid destination
  name="$(printf '%s' "$selection" | sed -n '1p')"
  os="$(printf '%s' "$selection" | sed -n '2p')"
  udid="$(printf '%s' "$selection" | sed -n '3p')"

  if [ -z "$name" ]; then
    name="iPhone SE (3rd generation)"
  fi
  if [ -z "$os" ]; then
    os="$desired_os"
  fi

  if [ -n "$udid" ]; then
    destination="id=$udid"
  else
    destination="platform=iOS Simulator,name=$name,OS=$os"
  fi

  printf "%s\n%s\n%s\n" "$name" "$os" "$destination"
}

check_podcast_dataset_uniqueness() {
  info "[gate-ci] Checking podcast dataset uniqueness"
  python3 - <<'PY' || fail "[gate-ci] Dataset hash check failed"
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
    print("[gate-ci] No podcast dataset JSON found")
    sys.exit(1)
hashes = {}
for path in paths:
    with open(path, "rb") as fh:
        digest = hashlib.sha256(fh.read()).hexdigest()
    hashes.setdefault(digest, []).append(path)
print("[gate-ci] dataset hashes:", json.dumps(hashes, indent=2))
if len(hashes) != 1:
    print(f"[gate-ci] Expected single canonical dataset hash, found {len(hashes)}")
    sys.exit(1)
PY
  pass "[gate-ci] dataset hash unique"
}

build_app_target() {
  if ! command -v xcodebuild >/dev/null; then
    info "[gate-ci] xcodebuild not available; skipping Pulsum app build"
    return
  fi

  local sim
  sim="$(select_simulator)"
  local sim_name sim_os destination
  sim_name="$(printf '%s' "$sim" | sed -n '1p')"
  sim_os="$(printf '%s' "$sim" | sed -n '2p')"
  destination="$(printf '%s' "$sim" | sed -n '3p')"

  info "[gate-ci] Building Pulsum app target (Debug) on ${sim_name} (${sim_os})"
  local build_cmd=(xcodebuild -scheme Pulsum -configuration Debug -destination "$destination" build)
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
  local list_output=""
  local patterns=""

  if [ ! -d "$package_dir" ]; then
    info "[gate-ci] $package_dir not found; skipping"
    return
  fi

  info "[gate-ci] Enumerating Gate suites in $package_name"
  if list_output="$(cd "$package_dir" && swift test list -Xswiftc -strict-concurrency=complete 2>/dev/null)"; then
    patterns="$(printf "%s\n" "$list_output" | sed -En 's/.*(Gate[0-9]+_).*/\1/p' | sort -u)"
  elif list_output="$(cd "$package_dir" && swift test --list-tests -Xswiftc -strict-concurrency=complete 2>/dev/null)"; then
    patterns="$(printf "%s\n" "$list_output" | sed -En 's/.*(Gate[0-9]+_).*/\1/p' | sort -u)"
  fi

  if [ -z "$patterns" ] && [ -d "$package_dir/Tests" ]; then
    patterns="$(rg --no-filename --only-matching 'Gate[0-9]+_' "$package_dir/Tests" 2>/dev/null | sort -u || true)"
    if [ -n "$patterns" ]; then
      info "[gate-ci] Using source-based Gate discovery fallback for $package_name"
    fi
  fi

  if [ -z "$patterns" ]; then
    info "[gate-ci] No Gate suites found in $package_name — skipping"
    return
  fi

  local joined
  joined="$(printf "%s" "$patterns" | paste -sd'|' -)"
  local log_suffix
  log_suffix="$(printf "%s" "$package_name" | tr '[:upper:]' '[:lower:]')"
  local log_file="$LOG_DIR/pulsum_${log_suffix}_gate.log"

  info "[gate-ci] Building $package_name with strict concurrency"
  if ! (cd "$package_dir" && swift build -Xswiftc -strict-concurrency=complete) >"$log_file" 2>&1; then
    tail -n 50 "$log_file" || true
    fail "[gate-ci] swift build failed for $package_name (see $log_file)"
  fi

  info "[gate-ci] Running $package_name tests matching (${joined})"
  if (cd "$package_dir" && swift test -Xswiftc -strict-concurrency=complete --parallel --filter "(${joined})") >"$log_file" 2>&1; then
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

  local sim
  sim="$(select_simulator)"
  local dest_name dest_os destination
  dest_name="$(printf '%s' "$sim" | sed -n '1p')"
  dest_os="$(printf '%s' "$sim" | sed -n '2p')"
  destination="$(printf '%s' "$sim" | sed -n '3p')"

  info "[gate-ci] Running UI Gate tests on ${dest_name} (${dest_os})"
  if UITEST_FAKE_SPEECH=1 UITEST_AUTOGRANT=1 \
     xcodebuild -scheme Pulsum -destination "$destination" \
     -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
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

check_podcast_dataset_uniqueness
build_app_target

for package in "${PACKAGES[@]}"; do
  discover_and_run_spm_gate_tests "$package"
done

run_xcode_ui_gate_tests

pass "[harness] ✅ Gate suites completed"
