#!/bin/bash
# Render build script - FAST deployment
# Set SKIP_TESTS=true in Render env vars to skip tests

set -e  # Exit on first error

echo "============================================"
echo "Installing dependencies..."
echo "============================================"
pip install -r requirements.txt

# Skip tests if SKIP_TESTS=true (for faster iteration)
if [ "$SKIP_TESTS" = "true" ]; then
    echo ""
    echo "============================================"
    echo "⚡ SKIPPING TESTS (SKIP_TESTS=true)"
    echo "============================================"
else
    echo ""
    echo "============================================"
    echo "Running tests..."
    echo "============================================"
    pip install pytest pytest-asyncio
    # Run fast tests only (exclude slow API tests)
    python -m pytest tests/test_onboarding.py tests/test_quick_replies_e2e.py -v --tb=short -x -m "not slow"
fi

echo ""
echo "============================================"
echo "✅ Build complete - deploying..."
echo "============================================"
