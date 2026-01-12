#!/bin/bash

# iOS Build Script for FitWiz
# Usage: ./run_ios.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FitWiz iOS Build Script ===${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

# Get preferred simulator (iPhone 17 Pro or first available iPhone)
get_simulator() {
    # Try iPhone 17 Pro first
    DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro (" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')

    if [ -z "$DEVICE_ID" ]; then
        # Fall back to any iPhone
        DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
    fi

    echo "$DEVICE_ID"
}

# Check if simulator is running
echo -e "${YELLOW}Checking if iOS simulator is running...${NC}"
BOOTED_DEVICES=$(xcrun simctl list devices booted | grep -c "Booted" || true)

if [ "$BOOTED_DEVICES" -eq "0" ]; then
    echo -e "${YELLOW}No simulator running. Starting simulator...${NC}"

    DEVICE_ID=$(get_simulator)

    if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}No iPhone simulators found. Please install iOS simulators via Xcode.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Booting simulator: $DEVICE_ID${NC}"
    xcrun simctl boot "$DEVICE_ID"

    # Open Simulator app
    open -a Simulator

    # Wait a moment for it to fully boot
    echo -e "${YELLOW}Waiting for simulator to boot...${NC}"
    sleep 5

    echo -e "${GREEN}Simulator is ready!${NC}"
else
    echo -e "${GREEN}Simulator is already running.${NC}"
    DEVICE_ID=$(xcrun simctl list devices booted | grep "iPhone" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
    # Ensure Simulator app is visible
    open -a Simulator
fi

# Flutter clean
echo -e "${YELLOW}Running flutter clean...${NC}"
$FLUTTER_PATH clean

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

# Uninstall existing app
echo -e "${YELLOW}Uninstalling existing app...${NC}"
xcrun simctl uninstall booted com.example.fitwiz 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

# Build and run
echo -e "${GREEN}Building and running app on simulator: $DEVICE_ID${NC}"
$FLUTTER_PATH run -d "$DEVICE_ID"

echo -e "${GREEN}=== Done! ===${NC}"
