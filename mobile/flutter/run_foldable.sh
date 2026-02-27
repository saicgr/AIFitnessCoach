#!/bin/bash

# Foldable Build Script for FitWiz
# Usage: ./run_foldable.sh
# Targets a foldable AVD (e.g. Pixel 9 Pro Fold)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FitWiz Foldable Build Script ===${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
EMULATOR_PATH="$HOME/Library/Android/sdk/emulator/emulator"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

# Find a foldable AVD
echo -e "${YELLOW}Searching for foldable AVD...${NC}"
AVDS=$($EMULATOR_PATH -list-avds)
FOLD_AVD=$(echo "$AVDS" | grep -i "fold" | head -n 1)

if [ -z "$FOLD_AVD" ]; then
    echo -e "${RED}No foldable AVD found.${NC}"
    echo -e "${YELLOW}Available AVDs:${NC}"
    echo "$AVDS"
    echo ""
    echo -e "${YELLOW}Please create a foldable AVD in Android Studio:${NC}"
    echo -e "  1. Open Android Studio > Device Manager"
    echo -e "  2. Create Virtual Device > Phone > Pixel 9 Pro Fold"
    echo -e "  3. Select a system image (API 35 recommended)"
    echo -e "  4. Finish and re-run this script"
    exit 1
fi

echo -e "${GREEN}Found foldable AVD: $FOLD_AVD${NC}"

# Check if the foldable AVD is already running
FOLD_SERIAL=""
for SERIAL in $($ADB_PATH devices | grep "emulator-" | awk '{print $1}'); do
    AVD_NAME=$($ADB_PATH -s "$SERIAL" emu avd name 2>/dev/null | head -n 1 | tr -d '\r')
    if [ "$AVD_NAME" = "$FOLD_AVD" ]; then
        FOLD_SERIAL="$SERIAL"
        break
    fi
done

if [ -n "$FOLD_SERIAL" ]; then
    echo -e "${GREEN}Foldable emulator already running on $FOLD_SERIAL${NC}"
else
    echo -e "${YELLOW}Starting foldable emulator: $FOLD_AVD${NC}"
    $EMULATOR_PATH -avd "$FOLD_AVD" -gpu auto &

    # Wait for any emulator device to appear
    echo -e "${YELLOW}Waiting for emulator to connect...${NC}"
    $ADB_PATH wait-for-device

    # Find the serial for the foldable AVD we just launched
    echo -e "${YELLOW}Detecting foldable emulator serial...${NC}"
    for i in $(seq 1 30); do
        for SERIAL in $($ADB_PATH devices | grep "emulator-" | awk '{print $1}'); do
            AVD_NAME=$($ADB_PATH -s "$SERIAL" emu avd name 2>/dev/null | head -n 1 | tr -d '\r')
            if [ "$AVD_NAME" = "$FOLD_AVD" ]; then
                FOLD_SERIAL="$SERIAL"
                break 2
            fi
        done
        sleep 1
    done

    if [ -z "$FOLD_SERIAL" ]; then
        echo -e "${RED}Could not detect foldable emulator serial. Falling back to first emulator.${NC}"
        FOLD_SERIAL=$($ADB_PATH devices | grep "emulator-" | head -n 1 | awk '{print $1}')
    fi

    if [ -z "$FOLD_SERIAL" ]; then
        echo -e "${RED}No emulator detected. Something went wrong.${NC}"
        exit 1
    fi

    # Wait for boot to complete
    echo -e "${YELLOW}Waiting for boot on $FOLD_SERIAL...${NC}"
    while [ "$($ADB_PATH -s "$FOLD_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 2
        echo -e "${YELLOW}Still waiting for boot...${NC}"
    done

    echo -e "${GREEN}Foldable emulator is ready on $FOLD_SERIAL!${NC}"
fi

# Skip flutter clean to avoid killing other running Flutter instances
# Use --no-build-cache flag or run 'flutter clean' manually if needed
echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

# Uninstall existing app
echo -e "${YELLOW}Uninstalling existing app...${NC}"
$ADB_PATH -s "$FOLD_SERIAL" uninstall com.aifitnesscoach.app 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

# Build and run on foldable
echo -e "${GREEN}Building and running app on foldable ($FOLD_SERIAL)...${NC}"
$FLUTTER_PATH run -d "$FOLD_SERIAL"

echo -e "${GREEN}=== Done! ===${NC}"
