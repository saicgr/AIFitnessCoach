#!/bin/bash

# ============================================
# AI Fitness Coach - Unified Run Script
# ============================================
# This script handles:
# 1. Uninstalling Flutter app (optional)
# 2. Installing backend dependencies
# 3. Running backend tests
# 4. Starting the backend server
# 5. Running the Flutter app
#
# Usage:
#   ./run_all.sh              # Run everything (tests + backend + Flutter)
#   ./run_all.sh --tests-only # Run backend tests only
#   ./run_all.sh --backend    # Run backend only
#   ./run_all.sh --flutter    # Run Flutter only
#   ./run_all.sh --clean      # Clean uninstall Flutter first
# ============================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"
FLUTTER_DIR="$SCRIPT_DIR/ai_fitness_coach"

# Default device (change as needed) - defaults to Chrome for web
FLUTTER_DEVICE="${FLUTTER_DEVICE:-chrome}"
WEB_PORT=8080

# Parse arguments
RUN_TESTS=true
RUN_BACKEND=true
RUN_FLUTTER=true
CLEAN_INSTALL=false
TESTS_ONLY=false
USE_WEB=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --tests-only)
            TESTS_ONLY=true
            RUN_BACKEND=false
            RUN_FLUTTER=false
            shift
            ;;
        --backend)
            RUN_TESTS=false
            RUN_FLUTTER=false
            shift
            ;;
        --flutter)
            RUN_TESTS=false
            RUN_BACKEND=false
            shift
            ;;
        --clean)
            CLEAN_INSTALL=true
            shift
            ;;
        --device)
            FLUTTER_DEVICE="$2"
            shift 2
            ;;
        --no-tests)
            RUN_TESTS=false
            shift
            ;;
        --mobile)
            USE_WEB=false
            FLUTTER_DEVICE=""
            shift
            ;;
        --web)
            USE_WEB=true
            FLUTTER_DEVICE="chrome"
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --tests-only  Run backend tests only"
            echo "  --backend     Run backend server only"
            echo "  --flutter     Run Flutter app only"
            echo "  --web         Run as web app in Chrome (default)"
            echo "  --mobile      Run on mobile device/emulator"
            echo "  --clean       Uninstall Flutter app before running"
            echo "  --device ID   Specify Flutter device ID"
            echo "  --no-tests    Skip running tests"
            echo "  --help        Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# ============================================
# Helper Functions
# ============================================

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed"
        exit 1
    fi
}

# ============================================
# Pre-flight Checks
# ============================================

print_header "Pre-flight Checks"

check_command python3
check_command pip3
if $RUN_FLUTTER; then
    check_command flutter
fi

print_success "All required commands found"

# ============================================
# Clean Install (if requested)
# ============================================

if $CLEAN_INSTALL && $RUN_FLUTTER; then
    print_header "Cleaning Flutter Installation"

    cd "$FLUTTER_DIR"

    # Get device if not specified
    if [ -z "$FLUTTER_DEVICE" ]; then
        FLUTTER_DEVICE=$(flutter devices | grep -E "^\S" | head -1 | awk '{print $1}')
        if [ -z "$FLUTTER_DEVICE" ]; then
            print_warning "No Flutter device found. Skipping uninstall."
        fi
    fi

    if [ -n "$FLUTTER_DEVICE" ]; then
        echo "Uninstalling from device: $FLUTTER_DEVICE"
        flutter clean
        print_success "Flutter cleaned"
    fi

    cd "$SCRIPT_DIR"
fi

# ============================================
# Backend Dependencies
# ============================================

if $RUN_TESTS || $RUN_BACKEND; then
    print_header "Installing Backend Dependencies"

    cd "$BACKEND_DIR"

    # Install dependencies directly with pip3
    pip3 install -r requirements.txt --quiet

    print_success "Backend dependencies installed"

    cd "$SCRIPT_DIR"
fi

# ============================================
# Run Backend Tests
# ============================================

if $RUN_TESTS; then
    print_header "Running Backend Tests"

    cd "$BACKEND_DIR"

    # Run pytest with coverage
    if python3 -m pytest tests/ -v --tb=short; then
        print_success "All tests passed!"
    else
        print_error "Some tests failed"
        if $TESTS_ONLY; then
            exit 1
        fi
        print_warning "Continuing despite test failures..."
    fi

    cd "$SCRIPT_DIR"
fi

if $TESTS_ONLY; then
    print_header "Tests Complete"
    exit 0
fi

# ============================================
# Start Backend Server
# ============================================

BACKEND_PID=""

if $RUN_BACKEND; then
    print_header "Starting Backend Server"

    cd "$BACKEND_DIR"

    # Check if port 8000 is already in use
    if lsof -i :8000 &> /dev/null; then
        print_warning "Port 8000 is already in use"
        echo "Kill existing process? (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            lsof -ti :8000 | xargs kill -9 2>/dev/null || true
            sleep 1
        fi
    fi

    # Start backend in background
    echo "Starting uvicorn server..."
    python3 -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
    BACKEND_PID=$!

    # Wait for server to start
    echo "Waiting for backend to start..."
    for i in {1..30}; do
        if curl -s http://localhost:8000/api/v1/health/ > /dev/null 2>&1; then
            print_success "Backend server started on http://localhost:8000"
            break
        fi
        sleep 1
    done

    cd "$SCRIPT_DIR"
fi

# ============================================
# Run Flutter App
# ============================================

if $RUN_FLUTTER; then
    print_header "Starting Flutter App"

    cd "$FLUTTER_DIR"

    # Get dependencies
    flutter pub get

    if $USE_WEB; then
        # Run as web app
        echo "Starting Flutter Web App on port $WEB_PORT..."
        echo "Access at: http://localhost:$WEB_PORT"

        # Use Edge if Chrome not available
        if ! flutter devices | grep -q "Chrome"; then
            export CHROME_EXECUTABLE="/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"
        fi

        flutter run -d chrome --web-port=$WEB_PORT
    else
        # Run on mobile device/emulator
        if [ -z "$FLUTTER_DEVICE" ]; then
            echo "Available devices:"
            flutter devices
            echo ""
            echo "Enter device ID (or press Enter for first available):"
            read -r FLUTTER_DEVICE

            if [ -z "$FLUTTER_DEVICE" ]; then
                FLUTTER_DEVICE=$(flutter devices | grep -E "^\S" | head -1 | awk '{print $1}')
            fi
        fi

        if [ -z "$FLUTTER_DEVICE" ]; then
            print_error "No Flutter device available"
            exit 1
        fi

        echo "Running on device: $FLUTTER_DEVICE"

        if $CLEAN_INSTALL; then
            flutter run -d "$FLUTTER_DEVICE" --uninstall-first
        else
            flutter run -d "$FLUTTER_DEVICE"
        fi
    fi

    cd "$SCRIPT_DIR"
fi

# ============================================
# Cleanup
# ============================================

cleanup() {
    print_header "Shutting Down"

    if [ -n "$BACKEND_PID" ]; then
        echo "Stopping backend server (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
    fi

    print_success "Cleanup complete"
}

trap cleanup EXIT

# Keep script running if backend is running alone
if $RUN_BACKEND && ! $RUN_FLUTTER; then
    print_header "Backend Running"
    echo "Press Ctrl+C to stop the server"
    wait $BACKEND_PID
fi
