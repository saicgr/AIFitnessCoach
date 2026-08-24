"""
Analytics database operations.

Handles workout regeneration analytics including:
- Regeneration history tracking
- Custom workout inputs (focus areas, injuries)
- Equipment usage patterns

The implementation lives in `analytics_db_helpers` (this module's own line
count is kept under the TestModuleLineCount budget in
tests/core/test_db_facade.py); this file just re-exports the public surface
so `from core.db.analytics_db import AnalyticsDB` keeps working unchanged.
"""
from core.db.analytics_db_helpers import AnalyticsDB, logger  # noqa: F401
