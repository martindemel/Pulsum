#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

export COPYFILE_DISABLE=1

LOG_DIR="${TMPDIR:-/tmp}"
info() { printf '\033[36m%s\033[0m\n' "$1"; }
pass() { printf '\033[32m%s\033[0m\n' "$1"; }
fail() { printf '\033[31m%s\033[0m\n' "$1"; exit 1; }

# B6-11 | LOW-13: Pure shell simulator selection (no Python dependency).
# Uses plutil to parse JSON from xcrun simctl.
select_simulator() {
  local desired_os="${PULSUM_SIM_OS:-26.0.1}"
  local major="${desired_os%%.*}"

  if ! command -v xcrun >/dev/null; then
    printf "iPhone SE (3rd generation)\n%s\nplatform=iOS Simulator,name=iPhone SE (3rd generation),OS=%s\n" "$desired_os" "$desired_os"
    return
  fi

  local preferred="iPhone 17 Pro|iPhone 17 Pro Max|iPhone Air|iPhone 17|iPhone 16 Pro|iPhone 16|iPhone 15 Pro|iPhone SE (3rd generation)"

  # Extract available devices as "name|os_version|udid" lines.
  local devices_json
  devices_json="$(xcrun simctl list -j devices available 2>/dev/null)" || {
    printf "iPhone SE (3rd generation)\n%s\nplatform=iOS Simulator,name=iPhone SE (3rd generation),OS=%s\n" "$desired_os" "$desired_os"
    return
  }

  # Parse JSON with plutil (available on all macOS) to extract device entries.
  local entries=""
  entries="$(printf '%s' "$devices_json" | plutil -extract devices raw -o - - 2>/dev/null | while IFS= read -r runtime; do
    # plutil raw output for dict just lists keys, but we need structured access.
    # Fall back to grep/sed parsing of the JSON text.
    :
  done 2>/dev/null || true)"

  # Robust JSON parsing using sed/grep (no external dependencies beyond coreutils).
  # Extract lines of form: runtime_key, device_name, udid, isAvailable
  entries="$(printf '%s' "$devices_json" | sed -n '
    /"devices"/,/^[[:space:]]*}[[:space:]]*$/ {
      /com\.apple\.CoreSimulator\.SimRuntime\.iOS/,/]/ {
        s/.*SimRuntime\.iOS-\([0-9]*\)-\([0-9]*\)\(-\([0-9]*\)\)\{0,1\}.*/OS_\1.\2.\4/p
        /"name"/s/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/NAME_\1/p
        /"udid"/s/.*"udid"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/UDID_\1/p
        /"isAvailable"/s/.*"isAvailable"[[:space:]]*:[[:space:]]*\(true\|false\).*/AVAIL_\1/p
      }
    }
  ')"

  # Build device list as "name|os_version|udid" entries.
  local device_list=""
  local current_os="" current_name="" current_udid="" current_avail=""

  while IFS= read -r line; do
    case "$line" in
      OS_*)
        current_os="${line#OS_}"
        # Clean trailing dot if no patch version
        current_os="${current_os%.}"
        ;;
      NAME_*)
        current_name="${line#NAME_}"
        ;;
      UDID_*)
        current_udid="${line#UDID_}"
        ;;
      AVAIL_*)
        current_avail="${line#AVAIL_}"
        if [ "$current_avail" = "true" ] && [ -n "$current_name" ] && [ -n "$current_udid" ] && [ -n "$current_os" ]; then
          device_list="$device_list
$current_name|$current_os|$current_udid"
        fi
        current_name=""
        current_udid=""
        current_avail=""
        ;;
    esac
  done <<EOF
$entries
EOF

  # Selection logic: try preferred devices with desired OS, then major, then any.
  local selected=""
  local IFS_OLD="$IFS"

  # Helper: find first preferred device matching OS prefix
  _find_preferred() {
    local os_prefix="$1"
    local pref
    IFS='|'
    for pref in $preferred; do
      local match
      match="$(printf '%s' "$device_list" | grep "^${pref}|${os_prefix}" | head -1)"
      if [ -n "$match" ]; then
        printf '%s' "$match"
        return 0
      fi
    done
    IFS="$IFS_OLD"
    return 1
  }

  # Helper: find any device matching OS prefix
  _find_any() {
    local os_prefix="$1"
    printf '%s' "$device_list" | grep "|${os_prefix}" | head -1
  }

  selected="$(_find_preferred "$desired_os" 2>/dev/null)" \
    || selected="$(_find_preferred "$major\." 2>/dev/null)" \
    || selected="$(_find_any "$desired_os" 2>/dev/null)" \
    || selected="$(_find_any "${major}\." 2>/dev/null)" \
    || selected="$(_find_any "26\." 2>/dev/null)" \
    || selected="$(_find_any "18\." 2>/dev/null)" \
    || selected="$(_find_preferred "" 2>/dev/null)" \
    || selected="$(printf '%s' "$device_list" | grep -v '^$' | head -1)" \
    || selected=""

  local name os_ver udid destination
  IFS='|' read -r name os_ver udid <<EOF2
$selected
EOF2

  if [ -z "$name" ]; then
    name="iPhone SE (3rd generation)"
  fi
  if [ -z "$os_ver" ]; then
    os_ver="$desired_os"
  fi

  if [ -n "$udid" ]; then
    destination="id=$udid"
  else
    destination="platform=iOS Simulator,name=$name,OS=$os_ver"
  fi

  printf "%s\n%s\n%s\n" "$name" "$os_ver" "$destination"
}

# B6-11 | LOW-13: Pure shell dataset uniqueness check (no Python dependency).
check_podcast_dataset_uniqueness() {
  info "[gate-ci] Checking podcast dataset uniqueness"
  local raw
  raw="$(git ls-files -z 'podcastrecommendations*.json' 'json database/podcastrecommendations*.json' 2>/dev/null)" || raw=""
  if [ -z "$raw" ]; then
    fail "[gate-ci] No podcast dataset JSON found"
  fi

  local hash_list=""
  local count=0
  while IFS= read -r -d '' path; do
    [ -z "$path" ] && continue
    local digest
    digest="$(shasum -a 256 "$path" | cut -d' ' -f1)"
    info "[gate-ci]   $path -> $digest"
    hash_list="$hash_list
$digest"
    count=$((count + 1))
  done <<< "$raw"

  if [ "$count" -eq 0 ]; then
    fail "[gate-ci] No podcast dataset JSON found"
  fi

  local unique_hashes
  unique_hashes="$(printf '%s' "$hash_list" | sort -u | grep -c -v '^$')"
  if [ "$unique_hashes" -ne 1 ]; then
    fail "[gate-ci] Expected single canonical dataset hash, found $unique_hashes"
  fi
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
    # Show failing test details (assertion messages are near "failed" lines)
    rg -i "assert|fail|error.*Gate4|XCTAssert|expected.*got|but got" "$log_file" | tail -n 30 || true
    printf '\n---\n'
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
