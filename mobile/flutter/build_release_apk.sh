#!/bin/bash

# Release TEST APK Build Script for Zealova
#
# Builds a signed, installable release APK — the artifact you sideload to test
# a real release build (R8 + resource shrinking + prod defines) on a device or
# emulator WITHOUT going through Play.
#
# This is NOT the Play Store artifact. For Play uploads use:
#   scripts/build_release.sh   → signed AAB with full keystore pre-flight
#   build_appbundle.sh         → plain AAB build
#
# Usage:
#   ./build_release_apk.sh                 # arm64-v8a only (phones + Apple Silicon emulators)
#   ./build_release_apk.sh --all-abis      # fat APK, all ABIs (older/Intel devices, ~2x size)
#   ./build_release_apk.sh --split         # one APK per ABI
#   ./build_release_apk.sh --install       # adb install onto the connected device after building
#   ./build_release_apk.sh --clean         # flutter clean first (slow; kills other flutter instances)
#
# Signing: resolved by android/app/build.gradle.kts in this order —
#   1. env vars KEYSTORE_PATH / KEYSTORE_PASSWORD / KEY_ALIAS / KEY_PASSWORD
#   2. android/key.properties (gitignored local fallback)
#   3. hard failure — release builds never sign with an empty password.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Zealova Release TEST APK Build ===${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

# --- Parse args ------------------------------------------------------------
ABI_MODE="arm64"     # arm64 | all | split
DO_INSTALL=false
DO_CLEAN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all-abis) ABI_MODE="all" ;;
        --split)    ABI_MODE="split" ;;
        --install)  DO_INSTALL=true ;;
        --clean)    DO_CLEAN=true ;;
        -h|--help)  sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo -e "${RED}Unknown option: $1${NC}" >&2; exit 1 ;;
    esac
    shift
done

# --- Pre-flight: signing credentials resolvable? ---------------------------
# Mirrors the gradle resolution order so we fail here with a readable message
# instead of 4 minutes into a gradle run.
ENV_SIGNING_COMPLETE=false
if [[ -n "${KEYSTORE_PASSWORD:-}" && -n "${KEY_PASSWORD:-}" ]]; then
    ENV_SIGNING_COMPLETE=true
fi

if [[ "$ENV_SIGNING_COMPLETE" = true ]]; then
    echo -e "${GREEN}Signing: env vars (KEYSTORE_PASSWORD / KEY_PASSWORD set)${NC}"
    RESOLVED_KEYSTORE="${KEYSTORE_PATH:-android/keystores/release.keystore}"
elif [[ -f "android/key.properties" ]]; then
    echo -e "${GREEN}Signing: android/key.properties${NC}"
    RESOLVED_KEYSTORE="android/app/$(grep '^storeFile=' android/key.properties | cut -d= -f2-)"
else
    echo -e "${RED}No release signing credentials found.${NC}" >&2
    echo "  Either export KEYSTORE_PATH / KEYSTORE_PASSWORD / KEY_ALIAS / KEY_PASSWORD," >&2
    echo "  or create android/key.properties (see android/key.properties.example)." >&2
    exit 1
fi

# Normalize a relative-to-android/app keystore path for the existence check.
if [[ ! -f "$RESOLVED_KEYSTORE" && -f "android/app/$RESOLVED_KEYSTORE" ]]; then
    RESOLVED_KEYSTORE="android/app/$RESOLVED_KEYSTORE"
fi
if [[ ! -f "$RESOLVED_KEYSTORE" ]]; then
    # key.properties paths are relative to android/app/ and may contain ../
    RESOLVED_KEYSTORE="$(cd "$(dirname "$RESOLVED_KEYSTORE")" 2>/dev/null && pwd)/$(basename "$RESOLVED_KEYSTORE")" || true
fi
if [[ ! -f "$RESOLVED_KEYSTORE" ]]; then
    echo -e "${RED}Keystore not found at: $RESOLVED_KEYSTORE${NC}" >&2
    exit 1
fi
echo -e "${CYAN}  keystore: $RESOLVED_KEYSTORE${NC}"

# --- Validate RevenueCat key ----------------------------------------------
# Without a real key environment_config.dart falls back to
# "test_key_placeholder" and the paywall dies with "Purchase service not
# configured" — which is exactly the bug a release test build exists to catch.
RC_GOOGLE_KEY="${REVENUECAT_GOOGLE_KEY:-goog_oWxJnYQrUSCtIxMqTPcEPfWgBxq}"
RC_GOOGLE_KEY="$(printf '%s' "$RC_GOOGLE_KEY" | tr -d '\r\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
if [[ "$RC_GOOGLE_KEY" == "test_key_placeholder" || -z "$RC_GOOGLE_KEY" ]]; then
    echo -e "${RED}REVENUECAT_GOOGLE_KEY missing or placeholder — refusing to build.${NC}" >&2
    exit 1
fi
if [[ ! "$RC_GOOGLE_KEY" =~ ^goog_ ]]; then
    echo -e "${YELLOW}REVENUECAT_GOOGLE_KEY does not start with 'goog_' — verify you copied the Android key, not iOS.${NC}" >&2
fi

DART_DEFINES=(
    "--dart-define=ENV=prod"
    "--dart-define=REVENUECAT_GOOGLE_KEY=$RC_GOOGLE_KEY"
)
# Sentry DSN defaults to the production DSN baked into environment_config.dart.
# Override via env when testing without polluting production Issues.
if [[ -n "${SENTRY_DSN:-}" ]]; then
    DART_DEFINES+=("--dart-define=SENTRY_DSN=$SENTRY_DSN")
    echo -e "${CYAN}Overriding SENTRY_DSN from env var${NC}"
fi
[[ -n "${BACKEND_URL:-}" ]] && DART_DEFINES+=("--dart-define=BACKEND_URL=$BACKEND_URL")
[[ -n "${SUPABASE_URL:-}" ]] && DART_DEFINES+=("--dart-define=SUPABASE_URL=$SUPABASE_URL")
[[ -n "${SUPABASE_ANON_KEY:-}" ]] && DART_DEFINES+=("--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY")

# --- Build -----------------------------------------------------------------
# Skipped by default: `flutter clean` kills concurrently running flutter
# instances in this shared tree. Pass --clean when you actually need it.
if [[ "$DO_CLEAN" = true ]]; then
    echo -e "${YELLOW}Cleaning build cache...${NC}"
    $FLUTTER_PATH clean
fi

echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

# Generated .g.dart files are committed to git — no codegen step here.

ABI_ARGS=()
case "$ABI_MODE" in
    arm64) ABI_ARGS=("--target-platform" "android-arm64") ;;
    split) ABI_ARGS=("--split-per-abi") ;;
    all)   ABI_ARGS=() ;;   # flutter's default: armeabi-v7a + arm64-v8a + x86_64
esac

echo -e "${GREEN}Building release APK (abi: $ABI_MODE)...${NC}"
# --no-tree-shake-icons: habit_detail_screen builds IconData from a persisted
# runtime code point (a user's saved habit icon), which can't be const — the
# icon tree-shaker would otherwise abort the release build.
$FLUTTER_PATH build apk --release --no-tree-shake-icons "${ABI_ARGS[@]}" "${DART_DEFINES[@]}"

# --- Locate + verify output ------------------------------------------------
APK_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"
# bash 3.2 on macOS has no `mapfile` — read the list the portable way.
APKS=()
while IFS= read -r line; do
    [[ -n "$line" ]] && APKS+=("$line")
done < <(find "$APK_DIR" -maxdepth 1 -name "*release*.apk" ! -name "*.sha1" 2>/dev/null | sort)

if [[ ${#APKS[@]} -eq 0 ]]; then
    echo -e "${RED}Build reported success but no release APK found in $APK_DIR${NC}" >&2
    exit 1
fi

echo ""
echo -e "${GREEN}=== Build Successful ===${NC}"
for apk in "${APKS[@]}"; do
    echo -e "${GREEN}APK:  $apk  ($(du -h "$apk" | cut -f1))${NC}"
done

# Verify it's signed with the RELEASE cert, not the debug one. A release APK
# that silently carried the debug signature installs fine and fails Play
# upload later — catch it here.
APKSIGNER="$(ls "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1 || true)"

# apksigner is a java wrapper and there is no system JDK on this machine —
# gradle uses Android Studio's bundled JBR, so point apksigner at it too.
# Without this it dies with "Unable to locate a Java Runtime".
if [[ -z "${JAVA_HOME:-}" ]]; then
    for candidate in \
        "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
        "$(/usr/libexec/java_home 2>/dev/null || true)"
    do
        if [[ -n "$candidate" && -x "$candidate/bin/java" ]]; then
            export JAVA_HOME="$candidate"
            break
        fi
    done
fi

if [[ -n "$APKSIGNER" && -n "${JAVA_HOME:-}" ]]; then
    echo ""
    echo -e "${YELLOW}Verifying signature...${NC}"
    if CERTS=$("$APKSIGNER" verify --print-certs "${APKS[0]}" 2>/dev/null); then
        SIGNER_DN=$(echo "$CERTS" | grep -m1 "Signer #1 certificate DN" || true)
        echo -e "${GREEN}  Signed OK — ${SIGNER_DN#*: }${NC}"
        if echo "$SIGNER_DN" | grep -qi "CN=Android Debug"; then
            echo -e "${RED}  WARNING: signed with the DEBUG certificate, not the release keystore.${NC}" >&2
        fi
    else
        echo -e "${RED}  apksigner could not verify the APK.${NC}" >&2
    fi
else
    echo -e "${YELLOW}apksigner or a JDK not found — skipping signature verification.${NC}"
fi

# --- Optional install ------------------------------------------------------
if [[ "$DO_INSTALL" = true ]]; then
    echo ""
    if [[ ${#APKS[@]} -gt 1 ]]; then
        INSTALL_APK=$(printf '%s\n' "${APKS[@]}" | grep "arm64-v8a" | head -1)
        INSTALL_APK="${INSTALL_APK:-${APKS[0]}}"
    else
        INSTALL_APK="${APKS[0]}"
    fi
    echo -e "${YELLOW}Installing $(basename "$INSTALL_APK")...${NC}"
    # Release and debug builds carry different signatures — uninstall first,
    # otherwise adb install fails with INSTALL_FAILED_UPDATE_INCOMPATIBLE.
    $ADB_PATH uninstall com.aifitnesscoach.app >/dev/null 2>&1 || true
    $ADB_PATH install -r "$INSTALL_APK"
    echo -e "${GREEN}Installed. Launching...${NC}"
    $ADB_PATH shell monkey -p com.aifitnesscoach.app -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
fi

echo ""
echo -e "${CYAN}This is a TEST artifact — for Play Store uploads use scripts/build_release.sh.${NC}"
echo -e "${GREEN}=== Done! ===${NC}"
