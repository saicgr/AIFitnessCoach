"""
Activity database operations.

Handles daily activity and health metrics from:
- Health Connect (Android)
- Apple Health (iOS)

The implementation lives in `activity_db_helpers` (this module's own line
count is kept under the TestModuleLineCount budget in
tests/core/test_db_facade.py); this file just re-exports the public surface
so `from core.db.activity_db import ActivityDB` keeps working unchanged.
"""
from core.db.activity_db_helpers import ActivityDB  # noqa: F401
