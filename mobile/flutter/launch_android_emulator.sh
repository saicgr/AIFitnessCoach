#!/bin/bash

# Launch Android Emulator for Zealova
# Usage: ./launch_android_emulator.sh [avd_name]
# If no AVD name given, defaults to Medium_Phone_API_36.1
# This script ONLY launches the emulator — it does not build or run the app.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Zealova Android Emulator Launcher ===${NC}"

ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
EMULATOR_PATH="$HOME/Library/Android/sdk/emulator/emulator"

TARGET_AVD="${1:-Medium_Phone_API_36.1}"

# Check if this AVD is already running
BEFORE_DEVICES=$($ADB_PATH devices | grep "emulator-" | awk '{print $1}')
for dev in $BEFORE_DEVICES; do
    RUNNING_AVD=$($ADB_PATH -s "$dev" emu avd name 2>/dev/null | head -n 1 | tr -d '\r')
    if [ "$RUNNING_AVD" = "$TARGET_AVD" ]; then
        echo -e "${GREEN}$TARGET_AVD is already running on $dev${NC}"
        exit 0
    fi
done

echo -e "${YELLOW}Launching emulator: $TARGET_AVD${NC}"
$EMULATOR_PATH -avd "$TARGET_AVD" -no-snapshot-save -gpu auto &

echo -e "${YELLOW}Waiting for emulator to appear...${NC}"
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

echo -e "${YELLOW}Waiting for boot to complete on $TARGET_DEVICE...${NC}"
while [ "$($ADB_PATH -s "$TARGET_DEVICE" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
    sleep 2
done

echo -e "${GREEN}Emulator ready: $TARGET_AVD on $TARGET_DEVICE${NC}"
