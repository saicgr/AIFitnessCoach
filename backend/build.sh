#!/bin/bash
# Render build script - Full test suite deployment
# Set SKIP_TESTS=true in Render env vars to skip tests
# Set RUN_CRITICAL_ONLY=true to run only critical tests (faster)

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
elif [ "$RUN_CRITICAL_ONLY" = "true" ]; then
    echo ""
    echo "============================================"
    echo "Running critical tests only..."
    echo "============================================"
    pip install pytest pytest-asyncio httpx

    # Run only critical tests for faster deployment
    python -m pytest \
        tests/test_scores_api.py \
        tests/test_onboarding.py \
        tests/test_health_api.py \
        tests/core/test_weight_utils.py \
        tests/services/exercise_rag/test_filters.py \
        tests/test_workout_generation.py \
        tests/test_one_at_a_time_generation.py \
        tests/test_gemini_schemas.py \
        tests/test_injury_extraction.py \
        tests/test_workout_data_guards.py \
        tests/test_workout_insights_fallback.py \
        tests/test_add_exercise_sections.py \
        -v --tb=short -x -m "not slow" \
        --ignore=tests/test_quick_replies_e2e.py
else
    echo ""
    echo "============================================"
    echo "Running ALL tests..."
    echo "============================================"
    pip install pytest pytest-asyncio httpx

    # Run all tests except slow ones and e2e tests that require external services
    python -m pytest tests/ \
        -v --tb=short \
        -m "not slow" \
        --ignore=tests/test_quick_replies_e2e.py \
        --ignore=tests/test_streaming_speed.py \
        --ignore=tests/test_pr_detection_integration.py \
        -x
fi

# Run REAL integration tests if enabled (makes actual API calls to ChromaDB and Gemini)
# Set RUN_INTEGRATION_TESTS=true in Render env vars to enable
if [ "$RUN_INTEGRATION_TESTS" = "true" ]; then
    echo ""
    echo "============================================"
    echo "Running REAL integration tests (API calls)..."
    echo "============================================"
    pip install pytest pytest-asyncio httpx pytest-timeout

    # These tests make real API calls to ChromaDB and Gemini
    # They verify the full workout generation pipeline works end-to-end
    # Longer timeout (120s) for real API calls
    python -m pytest tests/test_rag_gemini_real_integration.py \
        -v --tb=short \
        -m "integration" \
        --timeout=120 \
        -x

    echo ""
    echo "✅ Integration tests passed!"
fi

echo ""
echo "============================================"
echo "✅ Build complete - deploying..."
echo "============================================"
