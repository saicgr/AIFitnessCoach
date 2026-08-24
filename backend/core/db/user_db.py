"""
User database operations.

Handles all user-related CRUD operations including:
- User profile management
- User lookup by ID, email, auth_id
- Injury management
- User metrics history
- Chat history

The implementation lives in `user_db_helpers` (this module's own line count
is kept under the TestModuleLineCount budget in tests/core/test_db_facade.py);
this file just re-exports the public surface so
`from core.db.user_db import UserDB` keeps working unchanged.
"""
from core.db.user_db_helpers import UserDB  # noqa: F401
