# API v1 module
from fastapi import APIRouter
from api.v1 import chat, health
from api.v1 import users, exercises, performance_db
from api.v1 import metrics, videos, onboarding, reminders, nutrition
from api.v1 import exercise_suggestions
from api.v1 import library  # Modular library package
from api.v1 import hydration
from api.v1 import feedback, achievements, summaries, insights
from api.v1 import notifications, ai_settings
from api.v1 import activity
from api.v1 import subscriptions, analytics, stats
from api.v1 import saved_workouts, challenges, leaderboard
from api.v1 import workouts  # Modular workouts package
from api.v1 import social  # Modular social package
from api.v1 import workout_gallery  # Shareable workout recap images
from api.v1 import personal_goals  # Weekly personal challenges
from api.v1 import goal_social  # Goal sharing and friend features
from api.v1 import features  # Feature voting system (Robinhood-style)
from api.v1 import custom_goals  # Custom training goals with AI keywords
from api.v1 import fasting  # Intermittent fasting tracking and timer
from api.v1 import progress_photos  # Progress photos with before/after comparisons
from api.v1 import scores  # Strength scores, readiness scores, personal records
from api.v1 import workout_history  # Manual workout history import for AI learning
from api.v1 import exercise_preferences  # Staple exercises and variation control
from api.v1 import training_intensity  # Percentage-based 1RM training

# Create v1 router
router = APIRouter(prefix="/v1")

# Include all v1 routes
router.include_router(chat.router, prefix="/chat", tags=["Chat"])
router.include_router(health.router, prefix="/health", tags=["Health"])

# Supabase-backed CRUD endpoints
router.include_router(users.router, prefix="/users", tags=["Users"])
router.include_router(exercises.router, prefix="/exercises", tags=["Exercises"])
router.include_router(workouts.router, prefix="/workouts", tags=["Workouts"])
router.include_router(performance_db.router, prefix="/performance", tags=["Performance"])

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

# Exercise suggestion agent endpoint
router.include_router(exercise_suggestions.router, prefix="/exercise-suggestions", tags=["Exercise Suggestions"])

# Hydration tracking endpoints
router.include_router(hydration.router, prefix="/hydration", tags=["Hydration"])

# Workout and exercise feedback endpoints
router.include_router(feedback.router, prefix="/feedback", tags=["Feedback"])

# Achievements and milestones endpoints
router.include_router(achievements.router, prefix="/achievements", tags=["Achievements"])

# Weekly summaries and notification preferences
router.include_router(summaries.router, prefix="/summaries", tags=["Summaries"])

# User insights and weekly progress
router.include_router(insights.router, tags=["Insights"])

# Push notification endpoints
router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])

# AI settings and personality preferences
router.include_router(ai_settings.router, tags=["AI Settings"])

# Daily activity from Health Connect / Apple Health
router.include_router(activity.router, tags=["Activity"])

# Subscription management and RevenueCat webhooks
router.include_router(subscriptions.router, prefix="/subscriptions", tags=["Subscriptions"])

# Analytics and screen time tracking
router.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])

# Comprehensive stats endpoints (aggregates achievements, PRs, measurements, workout stats)
router.include_router(stats.router, tags=["Stats"])

# Social features endpoints (connections, feed, challenges, reactions)
router.include_router(social.router, tags=["Social"])

# Saved and scheduled workouts from social feed
router.include_router(saved_workouts.router, prefix="/saved-workouts", tags=["Saved Workouts"])

# Workout challenges (friend-to-friend)
router.include_router(challenges.router, tags=["Challenges"])

# Leaderboards (global, country, friends)
router.include_router(leaderboard.router, tags=["Leaderboard"])

# Shareable workout recap images for social sharing
router.include_router(workout_gallery.router, prefix="/workout-gallery", tags=["Workout Gallery"])

# Weekly personal goals (Push it to the Limit challenges)
router.include_router(personal_goals.router, prefix="/personal-goals", tags=["Personal Goals"])

# Goal social features (friends on goals, invites, joining)
router.include_router(goal_social.router, prefix="/goal-social", tags=["Goal Social"])

# Feature voting system (user suggestions and voting)
router.include_router(features.router, tags=["Features"])

# Custom training goals with AI-generated keywords
router.include_router(custom_goals.router, prefix="/custom-goals", tags=["Custom Goals"])

# Intermittent fasting tracking endpoints
router.include_router(fasting.router, prefix="/fasting", tags=["Fasting"])

# Progress photos with before/after comparisons
router.include_router(progress_photos.router, prefix="/progress-photos", tags=["Progress Photos"])

# Scores: strength scores, readiness scores, personal records
router.include_router(scores.router, prefix="/scores", tags=["Scores"])

# Workout history import for AI learning (manual entry of past workouts)
router.include_router(workout_history.router, tags=["Workout History"])

# Exercise preferences: staple exercises, variation control, week comparison
router.include_router(exercise_preferences.router, tags=["Exercise Preferences"])

# Percentage-based 1RM training (train at X% of your max)
router.include_router(training_intensity.router, tags=["Training Intensity"])
