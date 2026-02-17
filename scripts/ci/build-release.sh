#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

info() { printf "\033[36m%s\033[0m\n" "$1"; }
fail() { printf "\033[31m%s\033[0m\n" "$1"; exit 1; }

usage() {
  cat <<'USAGE'
Usage: scripts/ci/build-release.sh [options] [xcodebuild args...]

Options:
  --offline                 Skip package resolution (requires local checkouts).
  --destination <dest>      Override xcodebuild destination.
  --derived-data-path <dir> Override DerivedData path (must be repo-local).
  --clean-caches            Remove repo-local DerivedData and SourcePackages caches.
  -h, --help                Show this help.

Notes:
  - Default destination is build-only friendly: generic/platform=iOS.
  - Repo-local caches default to Build/DerivedData and Build/SourcePackages.
USAGE
}

OFFLINE="${PULSUM_OFFLINE:-0}"
CLEAN_CACHES=0
BUILD_ARGS=()
DESTINATION=""
SDK=""
DERIVED_DATA_PATH=""
CLONED_SOURCE_PACKAGES_DIR=""

require_arg() {
  local flag="$1"
  local value="${2:-}"
  [ -n "$value" ] || fail "$flag requires a value."
  printf '%s' "$value"
}

abs_path() {
  local path="$1"
  if [[ "$path" = /* ]]; then
    printf '%s' "$path"
  else
    printf '%s/%s' "$ROOT_DIR" "$path"
  fi
}

ensure_repo_local() {
  local path="$1"
  local label="$2"
  if [[ "$path" = /* ]] && [[ "$path" != "$ROOT_DIR/"* ]]; then
    fail "$label must be within the repo (try Build/DerivedData or Build/SourcePackages)."
  fi
}

ensure_writable_dir() {
  local path="$1"
  local label="$2"
  if [ -e "$path" ] && [ ! -d "$path" ]; then
    fail "$label path exists but is not a directory: $path"
  fi
  if [ ! -d "$path" ]; then
    mkdir -p "$path" || fail "Failed to create $label directory at $path"
    chmod 755 "$path" 2>/dev/null || true
  fi
  if [ ! -w "$path" ]; then
    fail "$label directory is not writable: $path. Try: sudo chown -R $(whoami) \"$path\"; chmod -R u+rwX \"$path\"; rm -rf \"$path\""
  fi
}

# B6-11 | LOW-13: Pure shell simulator destination resolution (no Python dependency).
resolve_simulator_destination() {
  if ! command -v xcrun >/dev/null 2>&1; then
    printf "platform=iOS Simulator,OS=latest"
    return
  fi

  local preferred="iPhone 17 Pro|iPhone 17 Pro Max|iPhone Air|iPhone 17|iPhone 16 Pro|iPhone 16|iPhone 15 Pro|iPhone SE (3rd generation)"

  local devices_json
  devices_json="$(xcrun simctl list -j devices available 2>/dev/null)" || {
    printf "platform=iOS Simulator,OS=latest"
    return
  }

  # Parse JSON with sed to extract device entries as "os_major.minor|name|udid" lines.
  local entries=""
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

  # Build "os_sortkey|name|udid" list from parsed entries.
  local device_list=""
  local current_os="" current_name="" current_udid="" current_avail=""

  while IFS= read -r line; do
    case "$line" in
      OS_*)
        current_os="${line#OS_}"
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
$current_os|$current_name|$current_udid"
        fi
        current_name=""
        current_udid=""
        current_avail=""
        ;;
    esac
  done <<EOF
$entries
EOF

  if [ -z "$(printf '%s' "$device_list" | grep -v '^$')" ]; then
    printf "platform=iOS Simulator,OS=latest"
    return
  fi

  # Sort by OS version descending (lexicographic works for major.minor format).
  local sorted
  sorted="$(printf '%s' "$device_list" | grep -v '^$' | sort -t'|' -k1 -rV)"

  # Get the latest OS version.
  local latest_os
  latest_os="$(printf '%s\n' "$sorted" | head -1 | cut -d'|' -f1)"

  # Filter to only latest OS devices.
  local latest_devices
  latest_devices="$(printf '%s\n' "$sorted" | grep "^${latest_os}|")"

  # Try preferred devices in order.
  local selected_udid=""
  IFS='|'
  for pref in $preferred; do
    local match
    match="$(printf '%s\n' "$latest_devices" | grep "|${pref}|" | head -1)"
    if [ -n "$match" ]; then
      selected_udid="$(printf '%s' "$match" | cut -d'|' -f3)"
      break
    fi
  done
  unset IFS

  # Fallback to first available device on latest OS.
  if [ -z "$selected_udid" ]; then
    selected_udid="$(printf '%s\n' "$latest_devices" | head -1 | cut -d'|' -f3)"
  fi

  if [ -n "$selected_udid" ]; then
    printf "id=%s" "$selected_udid"
  else
    printf "platform=iOS Simulator,OS=latest"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --offline)
      OFFLINE=1
      shift
      ;;
    --clean-caches)
      CLEAN_CACHES=1
      shift
      ;;
    -destination|--destination)
      DESTINATION="$(require_arg "$1" "${2:-}")"
      shift 2
      ;;
    -sdk)
      SDK="$(require_arg "$1" "${2:-}")"
      shift 2
      ;;
    -derivedDataPath|--derived-data-path)
      DERIVED_DATA_PATH="$(require_arg "$1" "${2:-}")"
      shift 2
      ;;
    -clonedSourcePackagesDirPath)
      CLONED_SOURCE_PACKAGES_DIR="$(require_arg "$1" "${2:-}")"
      shift 2
      ;;
    *)
      BUILD_ARGS+=("$1")
      shift
      ;;
  esac
done

if [ -z "$DERIVED_DATA_PATH" ]; then
  DERIVED_DATA_PATH="${PULSUM_DERIVED_DATA_PATH:-Build/DerivedData}"
fi
if [ -z "$CLONED_SOURCE_PACKAGES_DIR" ]; then
  CLONED_SOURCE_PACKAGES_DIR="${PULSUM_SPM_CHECKOUTS_DIR:-Build/SourcePackages}"
fi

ensure_repo_local "$DERIVED_DATA_PATH" "DerivedData path"
ensure_repo_local "$CLONED_SOURCE_PACKAGES_DIR" "SourcePackages path"

DERIVED_DATA_PATH_ABS="$(abs_path "$DERIVED_DATA_PATH")"
CLONED_SOURCE_PACKAGES_DIR_ABS="$(abs_path "$CLONED_SOURCE_PACKAGES_DIR")"
BUILD_DIR_ABS="$(abs_path "Build")"

if [ "$CLEAN_CACHES" -eq 1 ]; then
  info "Cleaning repo-local caches"
  rm -rf "$DERIVED_DATA_PATH_ABS" "$CLONED_SOURCE_PACKAGES_DIR_ABS"
fi

ensure_writable_dir "$BUILD_DIR_ABS" "Build"
ensure_writable_dir "$DERIVED_DATA_PATH_ABS" "DerivedData"
ensure_writable_dir "$CLONED_SOURCE_PACKAGES_DIR_ABS" "SourcePackages"

if [ -z "$DESTINATION" ]; then
  DESTINATION="${PULSUM_BUILD_DESTINATION:-generic/platform=iOS}"
fi

if [[ "$DESTINATION" == *"Simulator"* ]] && [[ "$DESTINATION" != *"OS="* ]] && [[ "$DESTINATION" != id=* ]]; then
  DESTINATION="$(resolve_simulator_destination)"
fi

if [ -z "$SDK" ]; then
  if [[ "$DESTINATION" == *"Simulator"* ]] || [[ "$DESTINATION" == id=* ]]; then
    SDK="iphonesimulator"
  else
    SDK="iphoneos"
  fi
fi

BUILD_ARGS+=("-destination" "$DESTINATION")
BUILD_ARGS+=("-sdk" "$SDK")
BUILD_ARGS+=("-derivedDataPath" "$DERIVED_DATA_PATH")
BUILD_ARGS+=("-clonedSourcePackagesDirPath" "$CLONED_SOURCE_PACKAGES_DIR")

NEEDS_SIM=0
if [[ "$DESTINATION" == *"Simulator"* ]] || [[ "$SDK" == "iphonesimulator" ]] || [[ "$DESTINATION" == id=* ]]; then
  NEEDS_SIM=1
fi

if [ "$NEEDS_SIM" -eq 1 ]; then
  if ! command -v xcrun >/dev/null 2>&1; then
    fail "xcrun not available; install Xcode CLT or use a device destination (generic/platform=iOS)."
  fi
  if ! xcrun simctl list >/dev/null 2>&1; then
    fail "CoreSimulator appears unhealthy. Try: sudo killall -9 com.apple.CoreSimulator.CoreSimulatorService; open -a Simulator; xcrun simctl list."
  fi
fi

info "Using destination: $DESTINATION"
info "DerivedData: $DERIVED_DATA_PATH"
info "SourcePackages: $CLONED_SOURCE_PACKAGES_DIR"

PACKAGE_RESOLVED="Pulsum.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

if [ "$OFFLINE" -eq 1 ]; then
  info "Offline mode enabled; skipping Swift package resolution."
  if [ ! -f "$PACKAGE_RESOLVED" ]; then
    fail "Offline mode requires Package.resolved at $PACKAGE_RESOLVED. Run once online or execute: xcodebuild -resolvePackageDependencies -project Pulsum.xcodeproj -scheme Pulsum -derivedDataPath Build/DerivedData -clonedSourcePackagesDirPath Build/SourcePackages"
  fi
  CHECKOUTS_PATH="$CLONED_SOURCE_PACKAGES_DIR_ABS/checkouts"
  if [ ! -d "$CHECKOUTS_PATH" ] || [ -z "$(ls -A "$CHECKOUTS_PATH" 2>/dev/null)" ]; then
    fail "Offline mode requires cached packages in $CHECKOUTS_PATH. Prime with: scripts/ci/build-release.sh (online) or xcodebuild -resolvePackageDependencies -project Pulsum.xcodeproj -scheme Pulsum -derivedDataPath Build/DerivedData -clonedSourcePackagesDirPath Build/SourcePackages"
  fi
  BUILD_ARGS+=("-disableAutomaticPackageResolution")
else
  info "Resolving Swift package dependencies."
  RESOLVE_ARGS=(-project Pulsum.xcodeproj -scheme Pulsum -resolvePackageDependencies -derivedDataPath "$DERIVED_DATA_PATH" -clonedSourcePackagesDirPath "$CLONED_SOURCE_PACKAGES_DIR")
  if ! xcodebuild "${RESOLVE_ARGS[@]}" >/tmp/pulsum_spm_resolve.log 2>&1; then
    cat /tmp/pulsum_spm_resolve.log
    fail "Swift package resolution failed. If you're offline, re-run with --offline or PULSUM_OFFLINE=1."
  fi
fi

xcodebuild -scheme Pulsum -configuration Release build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  "${BUILD_ARGS[@]}"
