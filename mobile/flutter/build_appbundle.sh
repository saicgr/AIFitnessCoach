#!/bin/bash

# Android App Bundle Build Script for FitWiz
# Usage: ./build_appbundle.sh [--debug]
# Builds a release AAB by default, pass --debug for debug AAB

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FitWiz App Bundle Build Script ===${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$PROJECT_DIR"

# Determine build mode
BUILD_MODE="release"
if [ "$1" = "--debug" ]; then
    BUILD_MODE="debug"
fi

echo -e "${CYAN}Build mode: ${BUILD_MODE}${NC}"

# Clean previous build
echo -e "${YELLOW}Cleaning previous build...${NC}"
$FLUTTER_PATH clean

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

# Build the app bundle
echo -e "${YELLOW}Building app bundle (${BUILD_MODE})...${NC}"
# REVENUECAT_GOOGLE_KEY must be set as env var before running this script
# export REVENUECAT_GOOGLE_KEY=goog_YourKeyHere
if [ -z "$REVENUECAT_GOOGLE_KEY" ]; then
    echo -e "${RED}ERROR: REVENUECAT_GOOGLE_KEY env var not set${NC}"
    echo -e "${YELLOW}Run: export REVENUECAT_GOOGLE_KEY=goog_oWxJnYQrUSCtIxMqTPcEPfWgBxq${NC}"
    exit 1
fi

$FLUTTER_PATH build appbundle --${BUILD_MODE} --dart-define=ENV=prod --dart-define=REVENUECAT_GOOGLE_KEY=$REVENUECAT_GOOGLE_KEY

# Locate the output
if [ "$BUILD_MODE" = "release" ]; then
    AAB_PATH="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"
else
    AAB_PATH="$PROJECT_DIR/build/app/outputs/bundle/debug/app-debug.aab"
fi

if [ -f "$AAB_PATH" ]; then
    FILE_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo ""
    echo -e "${GREEN}=== Build Successful ===${NC}"
    echo -e "${GREEN}AAB: ${AAB_PATH}${NC}"
    echo -e "${GREEN}Size: ${FILE_SIZE}${NC}"
    echo ""
    echo -e "${CYAN}Upload this file to Google Play Console.${NC}"
else
    echo -e "${RED}Build failed - AAB not found at expected path.${NC}"
    exit 1
fi
