#!/bin/bash

# Wear OS Build & Run Script for FitWiz
# Usage: ./run_wearos.sh [--list | --create | --device <name> | --clean]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       ⌚ FitWiz Wear OS Build Script              ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANDROID_SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
EMULATOR="$ANDROID_SDK/emulator/emulator"
ADB="$ANDROID_SDK/platform-tools/adb"
AVDMANAGER="$ANDROID_SDK/cmdline-tools/latest/bin/avdmanager"

# Set JAVA_HOME to Android Studio's bundled JBR if not already set
if [ -z "$JAVA_HOME" ]; then
    ANDROID_STUDIO_JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    if [ -d "$ANDROID_STUDIO_JBR" ]; then
        export JAVA_HOME="$ANDROID_STUDIO_JBR"
        export PATH="$JAVA_HOME/bin:$PATH"
        echo -e "${GREEN}Using Android Studio's bundled Java${NC}"
    fi
fi

# Default AVD name for Wear OS
DEFAULT_WEAROS_AVD="Wear_OS_Round_API_33"

# Parse arguments
COMMAND=""
DEVICE_NAME=""
CLEAN_BUILD=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --list)
            COMMAND="list"
            shift
            ;;
        --create)
            COMMAND="create"
            shift
            ;;
        --device)
            DEVICE_NAME="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --help)
            echo "Usage: ./run_wearos.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --list      List available Wear OS emulators"
            echo "  --create    Create a new Wear OS AVD"
            echo "  --device    Specify AVD name to use"
            echo "  --clean     Clean build before running"
            echo "  --help      Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./run_wearos.sh                    # Build and run on default AVD"
            echo "  ./run_wearos.sh --list             # List available AVDs"
            echo "  ./run_wearos.sh --create           # Create new Wear OS AVD"
            echo "  ./run_wearos.sh --device MyWatch   # Run on specific AVD"
            echo "  ./run_wearos.sh --clean            # Clean build before running"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Usage: ./run_wearos.sh [--list | --create | --device <name> | --clean]"
            exit 1
            ;;
    esac
done

# Function: List available Wear OS emulators
list_wearos_avds() {
    echo -e "${CYAN}Available Wear OS AVDs:${NC}"
    "$EMULATOR" -list-avds | grep -i "wear" || echo "  (none found)"
    echo ""
    echo -e "${CYAN}All AVDs:${NC}"
    "$EMULATOR" -list-avds || echo "  (none found)"
    echo ""
    echo -e "${CYAN}Running emulators:${NC}"
    "$ADB" devices | grep -v "List" | grep -v "^$" || echo "  (none running)"
}

# Function: Create a new Wear OS AVD
create_wearos_avd() {
    echo -e "${YELLOW}Creating Wear OS AVD...${NC}"

    # Check if system image is installed
    SYSTEM_IMAGE="system-images;android-33;android-wear;x86_64"

    echo -e "${YELLOW}Checking for Wear OS system image...${NC}"
    if ! "$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager" --list_installed 2>/dev/null | grep -q "android-wear"; then
        echo -e "${YELLOW}Installing Wear OS system image (API 33)...${NC}"
        "$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager" "$SYSTEM_IMAGE"
    else
        echo -e "${GREEN}Wear OS system image already installed${NC}"
    fi

    # Create AVD
    echo -e "${GREEN}Creating AVD: $DEFAULT_WEAROS_AVD${NC}"
    echo "no" | "$AVDMANAGER" create avd \
        --name "$DEFAULT_WEAROS_AVD" \
        --package "$SYSTEM_IMAGE" \
        --device "wearos_large_round" \
        --force

    echo -e "${GREEN}Wear OS AVD created: $DEFAULT_WEAROS_AVD${NC}"
}

# Function: Get Wear OS AVD (prefer round, then any wear)
get_wearos_avd() {
    # If device specified, use it
    if [ -n "$DEVICE_NAME" ]; then
        echo "$DEVICE_NAME"
        return
    fi

    # Try to find a Wear OS AVD
    AVD=$("$EMULATOR" -list-avds | grep -i "wear" | head -1)

    if [ -z "$AVD" ]; then
        echo ""
    else
        echo "$AVD"
    fi
}

# Function: Find running WearOS emulator device ID
# Returns the device ID of a running WearOS emulator, or empty if none found
find_wearos_device() {
    local target_avd="$1"

    # Get all running emulators
    local devices=$("$ADB" devices | grep "emulator-" | awk '{print $1}')

    for device in $devices; do
        # Get the AVD name for this emulator (with timeout to avoid hanging)
        local avd_name=""
        avd_name=$("$ADB" -s "$device" emu avd name 2>/dev/null | head -1 | tr -d '\r\n')

        # Check if it contains "wear" (case insensitive)
        if [ -n "$avd_name" ]; then
            if echo "$avd_name" | grep -qi "wear"; then
                echo "$device"
                return 0
            fi
        fi
    done

    return 1
}

# Function: Wait for WearOS emulator to boot
wait_for_wearos_boot() {
    local avd_name="$1"
    echo -e "${YELLOW}Waiting for WearOS emulator to boot...${NC}"

    local max_wait=120
    local waited=0

    while [ $waited -lt $max_wait ]; do
        # First check if WearOS device is visible
        local device=$(find_wearos_device "$avd_name")

        if [ -n "$device" ]; then
            # Check if boot animation has completed
            BOOT_COMPLETE=$("$ADB" -s "$device" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')

            if [ "$BOOT_COMPLETE" = "1" ]; then
                echo -e "${GREEN}Emulator booted successfully!${NC}"
                return 0
            fi
        fi

        sleep 3
        waited=$((waited + 3))
        echo -e "${YELLOW}  Still booting... ($waited/$max_wait seconds)${NC}"
    done

    echo -e "${RED}Emulator boot timeout after ${max_wait}s${NC}"
    return 1
}

# Handle commands
case $COMMAND in
    list)
        list_wearos_avds
        exit 0
        ;;
    create)
        create_wearos_avd
        exit 0
        ;;
esac

# Main flow: Start emulator and run app

# 1. Find a Wear OS AVD
AVD=$(get_wearos_avd)

if [ -z "$AVD" ]; then
    echo -e "${RED}No Wear OS AVD found.${NC}"
    echo -e "${YELLOW}Create one with: ./run_wearos.sh --create${NC}"
    echo ""
    echo -e "${CYAN}Or create manually:${NC}"
    echo "  1. Open Android Studio"
    echo "  2. Tools > Device Manager"
    echo "  3. Create Device > Wear OS > Wear OS Large Round"
    echo "  4. Select API 33+ system image"
    exit 1
fi

echo -e "${GREEN}Using Wear OS AVD: $AVD${NC}"

# 2. Check if WearOS emulator is already running
echo -e "${YELLOW}Checking for running WearOS emulator...${NC}"
DEVICE_ID=$(find_wearos_device "$AVD")
echo -e "${YELLOW}Found device: '$DEVICE_ID'${NC}"

if [ -n "$DEVICE_ID" ]; then
    echo -e "${GREEN}Wear OS emulator is already running: $DEVICE_ID${NC}"
else
    echo -e "${YELLOW}Starting Wear OS emulator...${NC}"

    # Start emulator in background
    "$EMULATOR" -avd "$AVD" \
        -no-snapshot-save \
        -no-audio \
        -gpu auto \
        &

    # Wait for it to boot
    wait_for_wearos_boot "$AVD"

    # Now find the device ID of the newly started WearOS emulator
    DEVICE_ID=$(find_wearos_device "$AVD")

    if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}Failed to find WearOS emulator device ID${NC}"
        echo -e "${YELLOW}Tip: Try running with --device flag to specify the AVD name${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Device ID: $DEVICE_ID${NC}"

# 4. Build the Wear OS app
cd "$PROJECT_DIR"

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}🧹 Running gradle clean...${NC}"
    ./gradlew clean
fi

echo -e "${YELLOW}🔨 Building Wear OS app...${NC}"
./gradlew assembleDebug

# 5. Install the app
echo -e "${YELLOW}📲 Installing app on emulator...${NC}"
"$ADB" -s "$DEVICE_ID" install -r app/build/outputs/apk/debug/app-debug.apk

# 6. Launch the app
echo -e "${GREEN}🚀 Launching FitWiz Wear OS...${NC}"
"$ADB" -s "$DEVICE_ID" shell am start -n "com.fitwiz.wearos.debug/com.fitwiz.wearos.MainActivity"

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              ✅ FitWiz is running!                ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📝 Useful commands:${NC}"
echo -e "   View logs:    ${BLUE}adb -s $DEVICE_ID logcat | grep -iE 'FitWiz|fitwiz'${NC}"
echo -e "   Reinstall:    ${BLUE}adb -s $DEVICE_ID install -r app/build/outputs/apk/debug/app-debug.apk${NC}"
echo -e "   Kill app:     ${BLUE}adb -s $DEVICE_ID shell am force-stop com.fitwiz.wearos.debug${NC}"
echo -e "   Uninstall:    ${BLUE}adb -s $DEVICE_ID uninstall com.fitwiz.wearos.debug${NC}"
echo ""
