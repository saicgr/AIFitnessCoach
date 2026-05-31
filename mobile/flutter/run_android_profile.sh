#!/bin/bash

# Android PROFILE Build Script for Zealova
# Usage: ./run_android_profile.sh [avd_name]
# If no AVD name given, defaults to Medium_Phone_API_36.1
#
# WHY THIS EXISTS:
# Debug builds (run_android_debug.sh) run the Dart VM in JIT mode with asserts
# enabled and zero compile optimization — they are routinely 3-10x slower than
# what ships. Judging app speed from a debug build on an emulator is misleading.
#
# PROFILE mode is AOT-compiled (same compiler path as release) so the perceived
# speed here is REAL — it's what users feel, minus a tiny observatory overhead.
# Use this to answer "is the app actually slow?" honestly.
#
# Notes:
#  - No hot reload in profile mode (AOT). Edit -> re-run.
#  - `debugPrint` logs (e.g. 🥗 [NutritionProvider] timing) STILL print here, so
#    you get the network-timing lines. Only `if (kDebugMode)` blocks are dropped.
#  - For the absolute truth, a release build is ~5% faster again, but profile is
#    the right tool because it keeps the logs + DevTools timeline.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Zealova Android PROFILE Build Script ===${NC}"
echo -e "${YELLOW}AOT-compiled — this reflects REAL shipped performance, not debug-mode slowness.${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
EMULATOR_PATH="$HOME/Library/Android/sdk/emulator/emulator"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

# Determine which AVD to use
TARGET_AVD="${1:-Medium_Phone_API_36.1}"

# Record devices BEFORE launching so we can detect the new one
BEFORE_DEVICES=$($ADB_PATH devices | grep "emulator-" | awk '{print $1}')

# Check if this specific AVD is already running
AVD_ALREADY_RUNNING=false
for dev in $BEFORE_DEVICES; do
    RUNNING_AVD=$($ADB_PATH -s "$dev" emu avd name 2>/dev/null | head -n 1 | tr -d '\r')
    if [ "$RUNNING_AVD" = "$TARGET_AVD" ]; then
        AVD_ALREADY_RUNNING=true
        TARGET_DEVICE="$dev"
        echo -e "${GREEN}$TARGET_AVD is already running on $TARGET_DEVICE${NC}"
        break
    fi
done

if [ "$AVD_ALREADY_RUNNING" = false ]; then
    echo -e "${YELLOW}Launching emulator: $TARGET_AVD${NC}"
    $EMULATOR_PATH -avd "$TARGET_AVD" -no-snapshot-save -gpu auto &

    # Wait for the new emulator to appear
    echo -e "${YELLOW}Waiting for emulator to boot...${NC}"
    TARGET_DEVICE=""
    for i in $(seq 1 60); do
        CURRENT_DEVICES=$($ADB_PATH devices | grep "emulator-" | awk '{print $1}')
        for dev in $CURRENT_DEVICES; do
            if ! echo "$BEFORE_DEVICES" | grep -q "$dev"; then
                TARGET_DEVICE="$dev"
                break 2
            fi
        done
        sleep 2
    done

    if [ -z "$TARGET_DEVICE" ]; then
        echo -e "${RED}Timed out waiting for emulator to appear.${NC}"
        exit 1
    fi

    # Wait for boot to complete on the new device
    while [ "$($ADB_PATH -s "$TARGET_DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 2
        echo -e "${YELLOW}Still waiting for $TARGET_DEVICE to boot...${NC}"
    done

    echo -e "${GREEN}Emulator ready: $TARGET_AVD on $TARGET_DEVICE${NC}"
fi

# Clean build cache to ensure latest code is compiled
echo -e "${YELLOW}Cleaning build cache...${NC}"
$FLUTTER_PATH clean

echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

# Generated .g.dart files are committed to git — no codegen step here.
# See run_ios_debug.sh for the full reasoning.

# Uninstall existing app from target device
echo -e "${YELLOW}Uninstalling existing app from $TARGET_DEVICE...${NC}"
$ADB_PATH -s "$TARGET_DEVICE" uninstall com.aifitnesscoach.app 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

# RevenueCat keys — paywall throws "Purchase service not configured" without these.
RC_GOOGLE_KEY="${REVENUECAT_GOOGLE_KEY:-goog_oWxJnYQrUSCtIxMqTPcEPfWgBxq}"
DART_DEFINES=("--dart-define=REVENUECAT_GOOGLE_KEY=$RC_GOOGLE_KEY")
[[ -n "${REVENUECAT_APPLE_KEY:-}" ]] && DART_DEFINES+=("--dart-define=REVENUECAT_APPLE_KEY=$REVENUECAT_APPLE_KEY")

# Build, install, then attach — we can't use `flutter run --profile` directly
# because it rejects --no-tree-shake-icons (that flag exists only on `flutter
# build`), yet the profile run still tree-shakes icons and would abort on
# habit_detail_screen's runtime-built IconData (a user's saved habit icon, not
# const). So: build the APK WITH the flag, install it, launch it, then
# `flutter attach` for the same logs/DevTools workflow `run` gives.
echo -e "${GREEN}Building PROFILE APK (--no-tree-shake-icons) ...${NC}"
$FLUTTER_PATH build apk --profile --no-tree-shake-icons "${DART_DEFINES[@]}"

APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-profile.apk"
echo -e "${YELLOW}Installing $APK_PATH on $TARGET_DEVICE...${NC}"
$ADB_PATH -s "$TARGET_DEVICE" install -r "$APK_PATH"

echo -e "${YELLOW}Launching app...${NC}"
$ADB_PATH -s "$TARGET_DEVICE" shell monkey -p com.aifitnesscoach.app -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

echo -e "${GREEN}Attaching Flutter (profile logs + DevTools)...${NC}"
$FLUTTER_PATH attach -d "$TARGET_DEVICE"

echo -e "${GREEN}=== Done! ===${NC}"
