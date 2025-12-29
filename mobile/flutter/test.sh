#!/bin/bash
# Flutter test script - Run during builds
# Usage: ./test.sh [fast|all]

set -e

cd "$(dirname "$0")"

# Find flutter executable
if command -v flutter &> /dev/null; then
    FLUTTER="flutter"
elif [ -f "/opt/homebrew/bin/flutter" ]; then
    FLUTTER="/opt/homebrew/bin/flutter"
elif [ -f "$HOME/flutter/bin/flutter" ]; then
    FLUTTER="$HOME/flutter/bin/flutter"
else
    echo "Flutter not found in PATH"
    exit 1
fi

echo "============================================"
echo "Running Flutter tests..."
echo "Using: $FLUTTER"
echo "============================================"

MODE=${1:-fast}

if [ "$MODE" = "fast" ]; then
    echo "Running fast tests (completion flow)..."
    $FLUTTER test test/screens/onboarding/completion_flow_test.dart
else
    echo "Running ALL tests..."
    $FLUTTER test
fi

echo ""
echo "============================================"
echo "Flutter tests complete!"
echo "============================================"
