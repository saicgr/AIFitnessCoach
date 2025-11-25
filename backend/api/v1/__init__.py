# API v1 module
from fastapi import APIRouter
from api.v1 import chat, health, workouts, performance
from api.v1 import users, exercises, workouts_db, performance_db

# Create v1 router
router = APIRouter(prefix="/v1")

# Include all v1 routes
router.include_router(chat.router, prefix="/chat", tags=["Chat"])
router.include_router(health.router, prefix="/health", tags=["Health"])
router.include_router(workouts.router, prefix="/workouts", tags=["Workouts"])
router.include_router(performance.router, prefix="/performance", tags=["Performance"])

# DuckDB-backed CRUD endpoints
router.include_router(users.router, prefix="/users", tags=["Users"])
router.include_router(exercises.router, prefix="/exercises", tags=["Exercises"])
router.include_router(workouts_db.router, prefix="/workouts-db", tags=["Workouts DB"])
router.include_router(performance_db.router, prefix="/performance-db", tags=["Performance DB"])
