#!/bin/bash

# Android Dev Build Script for FitWiz
# Usage: ./run_android_dev.sh [avd_name]
# If no AVD name given, defaults to Medium_Phone_API_36.1
#
# This script starts the LOCAL backend and runs the app pointing to it.
# Use this for development. Use run_android_debug.sh to test against Render.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FitWiz Android DEV Build Script (Local Backend) ===${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
EMULATOR_PATH="$HOME/Library/Android/sdk/emulator/emulator"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$(cd "$PROJECT_DIR/../../backend" && pwd)"

cd "$PROJECT_DIR"

# --- Start local backend ---------------------------------------------------

BACKEND_PID=""

cleanup() {
    if [ -n "$BACKEND_PID" ] && kill -0 "$BACKEND_PID" 2>/dev/null; then
        echo -e "\n${YELLOW}Stopping local backend (PID $BACKEND_PID)...${NC}"
        kill "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
        echo -e "${GREEN}Backend stopped.${NC}"
    fi
}
trap cleanup EXIT INT TERM

# Check if backend is already running on port 8000
if lsof -i :8000 -sTCP:LISTEN >/dev/null 2>&1; then
    echo -e "${CYAN}Backend already running on port 8000, reusing it.${NC}"
else
    echo -e "${YELLOW}Starting local backend...${NC}"
    if [ ! -f "$BACKEND_DIR/main.py" ]; then
        echo -e "${RED}Backend not found at $BACKEND_DIR/main.py${NC}"
        exit 1
    fi
    cd "$BACKEND_DIR"
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
    BACKEND_PID=$!
    cd "$PROJECT_DIR"

    # Wait for backend to be ready
    echo -e "${YELLOW}Waiting for backend to start...${NC}"
    for i in $(seq 1 30); do
        if curl -s http://localhost:8000/ >/dev/null 2>&1; then
            echo -e "${GREEN}Backend ready on http://localhost:8000${NC}"
            break
        fi
        if [ "$i" -eq 30 ]; then
            echo -e "${RED}Backend failed to start after 30s${NC}"
            exit 1
        fi
        sleep 1
    done
fi

# --- Launch emulator -------------------------------------------------------

TARGET_AVD="${1:-Medium_Phone_API_36.1}"

BEFORE_DEVICES=$($ADB_PATH devices | grep "emulator-" | awk '{print $1}')

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

    while [ "$($ADB_PATH -s "$TARGET_DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 2
        echo -e "${YELLOW}Still waiting for $TARGET_DEVICE to boot...${NC}"
    done

    echo -e "${GREEN}Emulator ready: $TARGET_AVD on $TARGET_DEVICE${NC}"
fi

# --- Check emulator storage ------------------------------------------------

echo -e "${YELLOW}Checking emulator storage...${NC}"
AVAIL_KB=$($ADB_PATH -s "$TARGET_DEVICE" shell df /data 2>/dev/null | tail -1 | awk '{print $4}')
AVAIL_KB=$(echo "$AVAIL_KB" | tr -dc '0-9')

if [ -n "$AVAIL_KB" ] && [ "$AVAIL_KB" -lt 1048576 ]; then
    AVAIL_MB=$((AVAIL_KB / 1024))
    echo -e "${YELLOW}Low storage: ${AVAIL_MB}MB free. Reverting bloated Google app updates...${NC}"
    BLOAT_PACKAGES=(
        com.google.android.youtube
        com.google.android.apps.maps
        com.google.android.apps.photos
        com.google.android.gm
        com.android.chrome
        com.google.android.apps.docs
        com.google.android.apps.tachyon
        com.google.android.apps.messaging
        com.google.android.apps.nbu.files
        com.google.android.apps.wellbeing
        com.google.android.apps.youtube.music
        com.google.android.googlequicksearchbox
        com.google.android.videos
        com.google.android.apps.magazines
    )
    for pkg in "${BLOAT_PACKAGES[@]}"; do
        $ADB_PATH -s "$TARGET_DEVICE" shell pm uninstall-system-updates "$pkg" 2>/dev/null && \
            echo -e "  ${GREEN}Reverted $pkg${NC}" || true
    done

    AVAIL_KB=$($ADB_PATH -s "$TARGET_DEVICE" shell df /data 2>/dev/null | tail -1 | awk '{print $4}')
    AVAIL_KB=$(echo "$AVAIL_KB" | tr -dc '0-9')
    AVAIL_MB=$((AVAIL_KB / 1024))
    echo -e "${GREEN}Storage after cleanup: ${AVAIL_MB}MB free${NC}"
else
    if [ -n "$AVAIL_KB" ]; then
        AVAIL_MB=$((AVAIL_KB / 1024))
        echo -e "${GREEN}Storage OK: ${AVAIL_MB}MB free${NC}"
    else
        echo -e "${YELLOW}Could not determine storage, continuing anyway...${NC}"
    fi
fi

# --- Build and run with ENV=dev --------------------------------------------

echo -e "${YELLOW}Cleaning build cache...${NC}"
$FLUTTER_PATH clean

echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

echo -e "${YELLOW}Uninstalling existing app from $TARGET_DEVICE...${NC}"
$ADB_PATH -s "$TARGET_DEVICE" uninstall com.aifitnesscoach.app 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

echo -e "${GREEN}Building and running app in DEBUG mode (ENV=dev → local backend) on $TARGET_DEVICE...${NC}"
$FLUTTER_PATH run --debug -d "$TARGET_DEVICE" --dart-define=ENV=dev

echo -e "${GREEN}=== Done! ===${NC}"
