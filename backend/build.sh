#!/bin/bash
# Render build script - runs tests before deployment
# If tests fail, deployment will be blocked

set -e  # Exit on first error

echo "============================================"
echo "Installing dependencies..."
echo "============================================"
pip install -r requirements.txt

echo ""
echo "============================================"
echo "Running pre-deploy tests..."
echo "============================================"

# Install test dependencies
pip install pytest pytest-asyncio

# Run critical tests - deployment fails if any test fails
python -m pytest tests/test_onboarding.py tests/test_workout_generation.py \
    -v \
    --tb=short \
    -x  # Stop on first failure

echo ""
echo "============================================"
echo "ALL TESTS PASSED - Deployment proceeding"
echo "============================================"
