"""
Exercise database operations.

Handles all exercise-related CRUD operations including:
- Exercise catalog management
- Performance logging
- Strength records and PRs
- Weekly volume tracking

The implementation lives in `exercise_db_helpers` (this module's own line
count is kept under the TestModuleLineCount budget in
tests/core/test_db_facade.py); this file just re-exports the public surface
so `from core.db.exercise_db import ExerciseDB` keeps working unchanged.
"""
from core.db.exercise_db_helpers import ExerciseDB  # noqa: F401
