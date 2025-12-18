#!/bin/bash
# Run tests before deployment
# This script should be run during CI/CD or before deploying to Render
# Exit code 0 = all tests passed, non-zero = tests failed

set -e  # Exit on first error

echo "============================================"
echo "Running AI Fitness Coach Backend Tests"
echo "============================================"

# Change to backend directory
cd "$(dirname "$0")"

# Install test dependencies if needed
pip install -q pytest pytest-asyncio pytest-cov

echo ""
echo "Running critical tests..."
echo "============================================"

# Run tests with verbose output
# These tests use the REAL Gemini API - no mocks
# If any test fails, deployment should be blocked

python -m pytest tests/test_onboarding.py tests/test_workout_generation.py \
    -v \
    --tb=short \
    --no-header \
    -x  # Stop on first failure

TEST_EXIT_CODE=$?

echo ""
echo "============================================"
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo "ALL TESTS PASSED - Safe to deploy"
else
    echo "TESTS FAILED - DO NOT DEPLOY"
    echo "Fix the failing tests before deploying"
fi
echo "============================================"

exit $TEST_EXIT_CODE
