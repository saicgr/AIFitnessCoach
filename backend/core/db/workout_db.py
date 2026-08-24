"""
Workout database operations.

Handles all workout-related CRUD operations including:
- Workout creation, listing, and filtering
- SCD2 versioning (supersede, revert, soft delete)
- Workout logs and changes tracking
- Workout exits and rest intervals

The implementation lives in `workout_db_helpers` (this module's own line
count is kept under the TestModuleLineCount budget in
tests/core/test_db_facade.py); this file just re-exports the public surface
so `from core.db.workout_db import WorkoutDB` etc. keep working unchanged.
"""
from core.db.workout_db_helpers import (  # noqa: F401
    WorkoutDB,
    USER_INITIATED_WORKOUT_SOURCES,
    _INDEX_EXEMPT_WORKOUT_SOURCES,
    _FINALIZE_MERGE_FIELDS,
    _is_empty_sets,
    _carries_new_session_data,
    logger,
)
