#!/bin/bash

# Android Build Script for FitWiz
# Usage: ./run_android.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FitWiz Android Build Script ===${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
EMULATOR_PATH="$HOME/Library/Android/sdk/emulator/emulator"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

# Check if emulator is running
echo -e "${YELLOW}Checking if Android emulator is running...${NC}"
RUNNING_DEVICES=$($ADB_PATH devices | grep -v "List" | grep -v "^$" | wc -l | tr -d ' ')

if [ "$RUNNING_DEVICES" -eq "0" ]; then
    echo -e "${YELLOW}No emulator running. Starting emulator...${NC}"

    # Get list of available AVDs
    AVDS=$($EMULATOR_PATH -list-avds)
    FIRST_AVD=$(echo "$AVDS" | head -n 1)

    if [ -z "$FIRST_AVD" ]; then
        echo -e "${RED}No Android Virtual Devices found. Please create one in Android Studio.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Starting emulator: $FIRST_AVD${NC}"
    $EMULATOR_PATH -avd "$FIRST_AVD" &

    # Wait for emulator to boot
    echo -e "${YELLOW}Waiting for emulator to boot...${NC}"
    $ADB_PATH wait-for-device

    # Wait for boot animation to complete
    while [ "$($ADB_PATH shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 2
        echo -e "${YELLOW}Still waiting for boot...${NC}"
    done

    echo -e "${GREEN}Emulator is ready!${NC}"
else
    echo -e "${GREEN}Emulator is already running.${NC}"
fi

# Flutter clean
echo -e "${YELLOW}Running flutter clean...${NC}"
$FLUTTER_PATH clean

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

# Uninstall existing app
echo -e "${YELLOW}Uninstalling existing app...${NC}"
$ADB_PATH uninstall com.aifitnesscoach.app 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

# Build and run
echo -e "${GREEN}Building and running app...${NC}"
$FLUTTER_PATH run -d emulator-5554

echo -e "${GREEN}=== Done! ===${NC}"
