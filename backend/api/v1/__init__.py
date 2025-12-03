# API v1 module
from fastapi import APIRouter
from api.v1 import chat, health, workouts, performance
from api.v1 import users, exercises, workouts_db, performance_db
from api.v1 import metrics, videos, onboarding, reminders, nutrition, library

# Create v1 router
router = APIRouter(prefix="/v1")

# Include all v1 routes
router.include_router(chat.router, prefix="/chat", tags=["Chat"])
router.include_router(health.router, prefix="/health", tags=["Health"])
router.include_router(workouts.router, prefix="/workouts", tags=["Workouts"])
router.include_router(performance.router, prefix="/performance", tags=["Performance"])

# Supabase-backed CRUD endpoints
router.include_router(users.router, prefix="/users", tags=["Users"])
router.include_router(exercises.router, prefix="/exercises", tags=["Exercises"])
router.include_router(workouts_db.router, prefix="/workouts-db", tags=["Workouts DB"])
router.include_router(performance_db.router, prefix="/performance-db", tags=["Performance DB"])

# Health metrics endpoints
router.include_router(metrics.router, tags=["Health Metrics"])

# S3 video streaming endpoints
router.include_router(videos.router, tags=["Videos"])

# Conversational AI onboarding endpoints
router.include_router(onboarding.router, prefix="/onboarding", tags=["Onboarding"])

# Email reminder endpoints
router.include_router(reminders.router, prefix="/reminders", tags=["Reminders"])

# Nutrition tracking endpoints
router.include_router(nutrition.router, prefix="/nutrition", tags=["Nutrition"])

# Library browsing endpoints (exercises & programs)
router.include_router(library.router, prefix="/library", tags=["Library"])
