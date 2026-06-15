#!/bin/bash

# iOS Build Script for Zealova
# Usage: ./run_ios.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Zealova iOS Build Script ===${NC}"

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

# Generated .g.dart files are committed to git — no codegen step here.

# flutter_gemma exclusion is handled by the Podfile (strips it from iOS plugins)

# NOTE: we no longer `simctl uninstall` here — installing over the top
# preserves the app's login/session so you don't get logged out every run.

# RevenueCat keys — paywall throws "Purchase service not configured" without these.
# Override per-shell: export REVENUECAT_APPLE_KEY=appl_xxx REVENUECAT_GOOGLE_KEY=goog_xxx
RC_GOOGLE_KEY="${REVENUECAT_GOOGLE_KEY:-goog_oWxJnYQrUSCtIxMqTPcEPfWgBxq}"
RC_APPLE_KEY="${REVENUECAT_APPLE_KEY:-}"
DART_DEFINES=("--dart-define=REVENUECAT_GOOGLE_KEY=$RC_GOOGLE_KEY")
if [[ -n "$RC_APPLE_KEY" ]]; then
  DART_DEFINES+=("--dart-define=REVENUECAT_APPLE_KEY=$RC_APPLE_KEY")
else
  echo -e "${YELLOW}⚠️  REVENUECAT_APPLE_KEY not set — iOS purchases will fail until you export it.${NC}"
fi

# Build for the simulator, then install MANUALLY. flutter run's own install step
# fails on iOS 26 simulators with "Invalid placeholder attributes / Failed to
# create app extension placeholder for FitWizLiveActivityExtension.appex". The
# fix is to strip that Live Activity extension from the SIMULATOR build only
# (device/release builds keep it) before installing.
echo -e "${GREEN}Building app for simulator...${NC}"
$FLUTTER_PATH build ios --simulator --debug "${DART_DEFINES[@]}"

APP_PATH="$PROJECT_DIR/build/ios/iphonesimulator/Runner.app"

if [ -d "$APP_PATH/PlugIns/FitWizLiveActivityExtension.appex" ]; then
  echo -e "${YELLOW}Stripping Live Activity extension (simulator install workaround)...${NC}"
  rm -rf "$APP_PATH/PlugIns/FitWizLiveActivityExtension.appex"
fi

echo -e "${GREEN}Installing on simulator: $DEVICE_ID${NC}"
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo -e "${GREEN}Launching app...${NC}"
xcrun simctl launch "$DEVICE_ID" com.zealova.app || true

echo -e "${GREEN}=== Done! App installed & launched (login preserved). ===${NC}"
echo -e "${YELLOW}Note: this install method has no hot reload — re-run ./run_ios.sh to apply Dart changes.${NC}"
