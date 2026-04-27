#!/bin/bash

# Launch iOS Simulator for Zealova
# Usage: ./launch_ios_simulator.sh [device_name]
# If no device name given, defaults to iPhone 16 Pro
# This script ONLY launches the simulator — it does not build or run the app.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Zealova iOS Simulator Launcher ===${NC}"

TARGET_DEVICE="${1:-iPhone 16 Pro}"

# Find the UDID for the requested device
UDID=$(xcrun simctl list devices available --json 2>/dev/null \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
target = sys.argv[1] if len(sys.argv) > 1 else 'iPhone 16 Pro'
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('name') == target and d.get('isAvailable', True):
            print(d['udid'])
            sys.exit(0)
" "$TARGET_DEVICE" 2>/dev/null)

if [ -z "$UDID" ]; then
    echo -e "${YELLOW}Device '$TARGET_DEVICE' not found. Available simulators:${NC}"
    xcrun simctl list devices available | grep -E "iPhone|iPad" | head -20
    exit 1
fi

# Check if already booted
STATE=$(xcrun simctl list devices --json 2>/dev/null \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('udid') == sys.argv[1]:
            print(d.get('state', 'unknown'))
            sys.exit(0)
" "$UDID" 2>/dev/null)

if [ "$STATE" = "Booted" ]; then
    echo -e "${GREEN}$TARGET_DEVICE ($UDID) is already booted${NC}"
    open -a Simulator
    exit 0
fi

echo -e "${YELLOW}Booting simulator: $TARGET_DEVICE ($UDID)${NC}"
xcrun simctl boot "$UDID"

echo -e "${YELLOW}Opening Simulator app...${NC}"
open -a Simulator

# Wait for the simulator to finish booting
echo -e "${YELLOW}Waiting for boot to complete...${NC}"
for i in $(seq 1 30); do
    STATE=$(xcrun simctl list devices --json 2>/dev/null \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('udid') == sys.argv[1]:
            print(d.get('state', 'unknown'))
            sys.exit(0)
" "$UDID" 2>/dev/null)
    if [ "$STATE" = "Booted" ]; then
        break
    fi
    sleep 2
done

echo -e "${GREEN}Simulator ready: $TARGET_DEVICE ($UDID)${NC}"
