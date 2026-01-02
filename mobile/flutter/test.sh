#!/bin/bash
# Flutter test script - Run during builds
# Usage: ./test.sh [fast|all|critical]

set -e

cd "$(dirname "$0")"

# Find flutter executable
if command -v flutter &> /dev/null; then
    FLUTTER="flutter"
elif [ -f "/opt/homebrew/bin/flutter" ]; then
    FLUTTER="/opt/homebrew/bin/flutter"
elif [ -f "$HOME/flutter/bin/flutter" ]; then
    FLUTTER="$HOME/flutter/bin/flutter"
elif [ -f "$HOME/fvm/versions/3.32.2/bin/flutter" ]; then
    FLUTTER="$HOME/fvm/versions/3.32.2/bin/flutter"
else
    echo "Flutter not found in PATH"
    exit 1
fi

echo "============================================"
echo "Running Flutter tests..."
echo "Using: $FLUTTER"
echo "============================================"

MODE=${1:-fast}

case "$MODE" in
    fast)
        echo "Running fast tests (completion flow)..."
        $FLUTTER test test/screens/onboarding/completion_flow_test.dart
        ;;
    critical)
        echo "Running critical tests (models + services)..."
        $FLUTTER test \
            test/models/user_test.dart \
            test/models/workout_test.dart \
            test/models/nutrition_test.dart \
            test/services/api_client_test.dart \
            test/screens/onboarding/completion_flow_test.dart
        ;;
    all)
        echo "Running ALL tests..."
        $FLUTTER test
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Usage: ./test.sh [fast|all|critical]"
        exit 1
        ;;
esac

echo ""
echo "============================================"
echo "Flutter tests complete!"
echo "============================================"
