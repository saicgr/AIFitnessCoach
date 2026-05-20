#!/usr/bin/env bash
# Run every timezone test in one shot. Exits non-zero on any failure.
set -e
cd "$(dirname "$0")/../.."
echo "==================================================================="
echo " 1/4  Pure helper invariants"
echo "==================================================================="
backend/.venv/bin/python backend/scripts/_test_tz_helpers.py
echo
echo "==================================================================="
echo " 2/4  resolve_timezone priority + write-through"
echo "==================================================================="
backend/.venv/bin/python backend/scripts/_test_tz_resolver.py
echo
echo "==================================================================="
echo " 3/4  LangGraph state propagation"
echo "==================================================================="
backend/.venv/bin/python backend/scripts/_test_tz_state_propagation.py
echo
echo "==================================================================="
echo " 4/4  End-to-end DB invariants (Phase 1 regression check)"
echo "==================================================================="
backend/.venv/bin/python backend/scripts/_verify_scheduled_date_fix.py
echo
echo "==================================================================="
echo " ALL TIMEZONE TESTS PASSED"
echo "==================================================================="
