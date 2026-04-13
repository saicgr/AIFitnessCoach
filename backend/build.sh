#!/bin/bash
# Render build script - Full test suite deployment
# Set SKIP_TESTS=true in Render env vars to skip tests
# Set RUN_CRITICAL_ONLY=true to run only critical tests (faster)

set -e  # Exit on first error

echo "============================================"
echo "Installing dependencies..."
echo "============================================"
pip install -r requirements.txt

# Always validate critical imports (catches NameError before deploy)
echo ""
echo "============================================"
echo "Validating critical Python imports..."
echo "============================================"
python -c "
import sys, importlib, warnings, logging
warnings.filterwarnings('ignore')
logging.disable(logging.CRITICAL)

modules = [
    'api.v1.workouts.generation_endpoints',
    'api.v1.workouts.generation_streaming',
    'api.v1.workouts.generation',
    'api.v1.workouts.mood_generation',
    'api.v1.workouts.quick',
    'api.v1.workouts.workout_operations',
    'api.v1.workouts.set_adjustments_endpoints',
    'api.v1.cardio_endpoints',
    'api.v1.consistency_endpoints',
    'api.v1.habits_endpoints',
    'api.v1.notifications_endpoints',
    'api.v1.scores_endpoints',
    'api.v1.gym_profiles_endpoints',
    'api.v1.personal_goals_endpoints',
    'api.v1.exercise_preferences',
    'api.v1.admin.live_chat_endpoints',
    'api.v1.live_chat_endpoints',
    'api.v1.nutrition.food_logging',
    'api.v1.nutrition.food_logs',
    'api.v1.nutrition.streaks',
    'api.v1.nutrition.summaries',
    'api.v1.nutrition.cooking_conversions',
    'api.v1.nutrition.tdee_adherence',
    'services.food_analysis.cache_service_helpers',
    'services.food_analysis.cache_service_helpers_part2',
    'services.gemini.nutrition',
]

errors = []
for mod in modules:
    try:
        importlib.import_module(mod)
    except NameError as e:
        errors.append(f'{mod}: {e}')
    except Exception:
        pass  # Other errors (missing env vars, DB connections) are OK at build time

if errors:
    print('IMPORT VALIDATION FAILED:')
    for e in errors:
        print(f'  NameError in {e}')
    sys.exit(1)
else:
    print(f'All {len(modules)} critical modules passed import validation')
"

# Verify WeasyPrint PDF generation works (needs Aptfile system deps).
# Non-fatal: if this fails, PDF reports will 500 but HTML/markdown still work.
echo ""
echo "============================================"
echo "Checking WeasyPrint system deps (Aptfile)..."
echo "============================================"
python -c "
try:
    from weasyprint import HTML
    HTML(string='<p>ok</p>').write_pdf()
    print('✅ WeasyPrint PDF generation: OK')
except Exception as e:
    print(f'⚠️  WeasyPrint init failed: {e}')
    print('   → PDF report generation will return 500 at runtime.')
    print('   → HTML and markdown reports will still work.')
    print('   → Check that Aptfile was loaded by the build — see docs/MCP_SETUP.md.')
" || true

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
        tests/test_food_database_lookup.py \
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
