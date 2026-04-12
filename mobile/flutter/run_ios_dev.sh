#!/bin/bash

# iOS Dev Build Script for FitWiz
# Usage: ./run_ios_dev.sh [simulator_name]
# If no simulator name given, defaults to "iPhone 17 Pro"
#
# This script starts the LOCAL backend and runs the app pointing to it.
# Use this for development. Use run_ios_debug.sh to test against Render.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FitWiz iOS DEV Build Script (Local Backend) ===${NC}"

# Set paths
FLUTTER_PATH="/opt/homebrew/bin/flutter"
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

# --- Build and run with ENV=dev --------------------------------------------

echo -e "${YELLOW}Cleaning build cache...${NC}"
$FLUTTER_PATH clean

echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

# flutter_gemma exclusion is handled by the Podfile (strips it from iOS plugins)

echo -e "${YELLOW}Uninstalling existing app...${NC}"
xcrun simctl uninstall "$DEVICE_ID" com.aifitnesscoach.app 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

echo -e "${GREEN}Building and running app in DEBUG mode (ENV=dev -> local backend) on $TARGET_SIM...${NC}"
$FLUTTER_PATH run --debug -d "$DEVICE_ID" --dart-define=ENV=dev

echo -e "${GREEN}=== Done! ===${NC}"
