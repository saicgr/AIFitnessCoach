"""
User API endpoints package.

ENDPOINTS:
- POST /api/v1/users/auth/google - Authenticate with Google OAuth via Supabase
- POST /api/v1/users/auth/email - Authenticate with email/password
- POST /api/v1/users/auth/email/signup - Create account with email/password
- POST /api/v1/users/auth/forgot-password - Send password reset email
- POST /api/v1/users/auth/reset-password - Reset password with token
- POST /api/v1/users/auth/change-password - Change password (logged in)
- POST /api/v1/users/ - Create a new user
- GET  /api/v1/users/ - Get all users
- GET  /api/v1/users/by-auth/{auth_id} - Get user by auth ID
- GET  /api/v1/users/{id} - Get user by ID
- GET  /api/v1/users/{id}/program-preferences - Get user's program preferences
- PUT  /api/v1/users/{id} - Update user
- DELETE /api/v1/users/{id} - Delete user
- POST /api/v1/users/{id}/reset-onboarding - Reset onboarding
- DELETE /api/v1/users/{id}/reset - Full reset (delete all user data)
- GET  /api/v1/users/{id}/export - Export all user data as ZIP
- GET  /api/v1/users/{id}/export-text - Export workout logs as plain text
- POST /api/v1/users/{id}/import - Import user data from ZIP
- GET  /api/v1/users/{id}/favorite-exercises - Get favorites
- POST /api/v1/users/{id}/favorite-exercises - Add favorite
- DELETE /api/v1/users/{id}/favorite-exercises/{name} - Remove favorite
- GET  /api/v1/users/{id}/exercise-queue - Get exercise queue
- POST /api/v1/users/{id}/exercise-queue - Add to queue
- PUT  /api/v1/users/{id}/exercise-queue/{name} - Update queue item
- DELETE /api/v1/users/{id}/exercise-queue/{name} - Remove from queue
- POST /api/v1/users/{id}/preferences - Save quiz preferences
- POST /api/v1/users/{id}/calculate-nutrition-targets - Calculate nutrition
- GET  /api/v1/users/{id}/nutrition-targets - Get nutrition targets
- POST /api/v1/users/{id}/sync-fasting-preferences - Sync fasting prefs
- POST /api/v1/users/{id}/photo - Upload profile photo
- DELETE /api/v1/users/{id}/photo - Delete profile photo
"""
from fastapi import APIRouter

from api.v1.users.auth import router as auth_router
from api.v1.users.profile import router as profile_router
from api.v1.users.onboarding import router as onboarding_router
from api.v1.users.exercises import router as exercises_router
from api.v1.users.data_export import router as data_export_router
from api.v1.users.photo import router as photo_router

# Re-export key symbols that tests and other code import from api.v1.users
from api.v1.users.auth import google_auth
from api.v1.users.models import (
    GoogleAuthRequest,
    row_to_user,
    merge_extended_fields_into_preferences,
    get_default_equipment_for_environment,
)

# Re-export dependencies that tests patch via 'api.v1.users.xxx'
from core.supabase_db import get_supabase_db
from core.supabase_client import get_supabase
from core.activity_logger import log_user_activity, log_user_error

# Combined router
router = APIRouter()
router.include_router(auth_router)
router.include_router(profile_router)
router.include_router(onboarding_router)
router.include_router(exercises_router)
router.include_router(data_export_router)
router.include_router(photo_router)
