#!/bin/bash

# iOS Debug Build Script for FitWiz
# Usage: ./run_ios_debug.sh [simulator_name]
# If no simulator name given, defaults to "iPhone 17 Pro"
#
# This script runs the app against the REMOTE Render backend.
# Use this to test against production. Use run_ios_dev.sh for local backend.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FitWiz iOS DEBUG Build Script ===${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

# --- Launch iOS Simulator --------------------------------------------------

TARGET_SIM="${1:-iPhone 17 Pro}"

# Get simulator device ID by name
get_simulator_id() {
    local name="$1"
    xcrun simctl list devices available | grep "$name (" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'
}

echo -e "${YELLOW}Looking for simulator: $TARGET_SIM${NC}"
DEVICE_ID=$(get_simulator_id "$TARGET_SIM")

if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}$TARGET_SIM not found, trying any available iPhone...${NC}"
    DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
fi

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}No iPhone simulators found. Please install iOS simulators via Xcode.${NC}"
    exit 1
fi

# Check if this simulator is already booted
DEVICE_STATE=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -c "Booted" || true)

if [ "$DEVICE_STATE" -eq "0" ]; then
    echo -e "${YELLOW}Booting simulator: $TARGET_SIM ($DEVICE_ID)${NC}"
    xcrun simctl boot "$DEVICE_ID"
    open -a Simulator

    echo -e "${YELLOW}Waiting for simulator to boot...${NC}"
    for i in $(seq 1 30); do
        BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -c "Booted" || true)
        if [ "$BOOT_STATUS" -gt "0" ]; then
            break
        fi
        if [ "$i" -eq 30 ]; then
            echo -e "${RED}Simulator failed to boot after 60s${NC}"
            exit 1
        fi
        sleep 2
    done
    echo -e "${GREEN}Simulator ready: $TARGET_SIM${NC}"
else
    echo -e "${GREEN}$TARGET_SIM is already running${NC}"
    open -a Simulator
fi

# --- Build and run (remote backend) ----------------------------------------

echo -e "${YELLOW}Cleaning build cache...${NC}"
$FLUTTER_PATH clean

echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

# flutter_gemma exclusion is handled by the Podfile (strips it from iOS plugins)

# Regenerate launcher icons if the source is newer than the generated 1024px icon.
# Pass REGEN_ICONS=1 to force regeneration.
ICON_SRC="assets/icon/app_icon.png"
ICON_OUT="ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
if [ "${REGEN_ICONS:-0}" = "1" ] || [ "$ICON_SRC" -nt "$ICON_OUT" ]; then
    echo -e "${YELLOW}Regenerating launcher icons from $ICON_SRC...${NC}"
    dart run flutter_launcher_icons
else
    echo -e "${GREEN}Launcher icons are up to date (set REGEN_ICONS=1 to force).${NC}"
fi

echo -e "${YELLOW}Fully removing existing app from simulator...${NC}"
# 1) Terminate the app if running
xcrun simctl terminate "$DEVICE_ID" com.aifitnesscoach.app 2>/dev/null || true
# 2) Uninstall bundle + data container
xcrun simctl uninstall "$DEVICE_ID" com.aifitnesscoach.app 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"
# 3) Kill SpringBoard so iOS flushes the cached launcher icon
echo -e "${YELLOW}Flushing SpringBoard icon cache...${NC}"
xcrun simctl spawn "$DEVICE_ID" launchctl stop com.apple.SpringBoard 2>/dev/null || true

echo -e "${GREEN}Building and running app in DEBUG mode on $TARGET_SIM...${NC}"
$FLUTTER_PATH run --debug -d "$DEVICE_ID"

echo -e "${GREEN}=== Done! ===${NC}"
