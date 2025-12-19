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
echo "Running pre-deploy tests (including AI integration tests)..."
echo "============================================"

# Install test dependencies
pip install pytest pytest-asyncio

# Run ALL tests including slow AI/integration tests
# This ensures end-to-end testing with real Gemini API
python -m pytest tests/test_onboarding.py tests/test_workout_generation.py tests/test_rag_service.py \
    -v \
    --tb=short \
    -x

echo ""
echo "============================================"
echo "ALL TESTS PASSED - Deployment proceeding"
echo "============================================"
