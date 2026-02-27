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
from api.v1 import stats_gallery  # Shareable stats images
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
from api.v1 import layouts  # Home screen layout customization
from api.v1 import recipe_suggestions  # AI recipe suggestions based on culture, body type, diet
from api.v1 import support  # Support ticket system
from api.v1 import skill_progressions  # Bodyweight skill progressions
from api.v1 import cardio  # Heart rate zones and cardio metrics
from api.v1 import flexibility  # Flexibility assessments and progress tracking
from api.v1 import email_preferences  # Email subscription preferences
from api.v1 import exercise_progressions  # Leverage-based exercise progressions
from api.v1 import audio_preferences  # Audio settings for workouts (TTS, ducking, background music)
from api.v1 import sound_preferences  # Sound effect customization (countdown, completion sounds)
from api.v1 import demo  # Demo/trial preview endpoints for pre-signup experience
from api.v1 import progress  # Visual progress charts (strength, volume, summary)
from api.v1 import subjective_feedback  # Subjective results tracking (mood, energy, feel results)
from api.v1 import scheduling  # Smart rescheduling for missed workouts
from api.v1 import consistency  # Consistency insights, streaks, and workout patterns
from api.v1 import milestones  # Progress milestones and ROI communication
from api.v1 import subscription_transparency  # Subscription transparency tracking
from api.v1 import subscription_context  # Subscription context for AI personalization
from api.v1 import programs  # Branded workout programs and user program assignments
from api.v1 import window_mode  # Window mode logging (split screen, PiP, freeform)
from api.v1 import neat  # NEAT (Non-Exercise Activity Thermogenesis) improvement system
from api.v1 import supersets  # Superset preferences and manual pairing
from api.v1 import strain_prevention  # Strain prevention and volume tracking
from api.v1 import injuries  # Injury tracking and workout modifications
from api.v1 import senior_fitness  # Senior fitness settings and modifications
from api.v1 import progression_settings  # Progression pace preferences
from api.v1 import fasting_impact  # Fasting impact analysis on weight, workouts, and goals
from api.v1 import nutrition_preferences  # Nutrition preferences, quick logging, meal templates
from api.v1 import diabetes  # Diabetes tracking (glucose, insulin, A1C, medications, alerts)
from api.v1 import exercise_history  # Per-exercise workout history and PRs
from api.v1 import muscle_analytics  # Muscle-level analytics, heatmap, balance analysis
from api.v1 import hormonal_health  # Hormonal health tracking (testosterone, estrogen, cycle tracking)
from api.v1 import kegel  # Kegel/pelvic floor exercises and preferences
from api.v1 import weekly_plans  # Holistic weekly plans (workouts + nutrition + fasting)
from api.v1 import chat_reports  # Chat message reporting for AI coach feedback quality
from api.v1 import live_chat  # Live chat support with human agents
from api.v1 import inflammation  # Food inflammation analysis from barcode scans
from api.v1 import admin  # Admin backend for live chat management and support
from api.v1 import habits  # Simple habit tracking (not eating outside, no doordash, etc.)
from api.v1 import watch_sync  # WearOS watch sync (batch sync, activity goals)
from api.v1 import weight_increments  # Equipment-specific weight increment preferences
from api.v1 import trophies  # Trophy room and achievement system
from api.v1 import gym_profiles  # Multi-gym profile system (Robinhood-style switcher)
from api.v1 import xp  # XP events, daily login, streaks, double XP
from api.v1 import warmup_preferences  # Custom warmup/stretch preferences and pre/post workout routines
from api.v1 import custom_exercises  # User-defined custom exercises with media upload
from api.v1 import daily_schedule  # Daily schedule planner
from api.v1 import sync  # Offline sync bulk upload and import
from api.v1 import exercise_popularity  # Collaborative filtering exercise scores
from api.v1 import beast_mode  # Beast mode custom training preferences
from api.v1 import wrapped  # Fitness Wrapped monthly recap cards
from api.v1 import plateau  # Plateau detection (exercise + weight stalling)

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

# Shareable stats images for social sharing
router.include_router(stats_gallery.router, prefix="/stats-gallery", tags=["Stats Gallery"])

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

# Home screen layout customization
router.include_router(layouts.router, tags=["Layouts"])

# AI recipe suggestions based on body type, culture, diet
router.include_router(recipe_suggestions.router, tags=["Recipe Suggestions"])

# Support ticket system for user issues
router.include_router(support.router, prefix="/support", tags=["Support"])

# Bodyweight skill progressions (push-up, pull-up, squat progressions, etc.)
router.include_router(skill_progressions.router, prefix="/skill-progressions", tags=["Skill Progressions"])

# Heart rate zones and cardio metrics
router.include_router(cardio.router, prefix="/cardio", tags=["Cardio"])

# Flexibility assessments and progress tracking
router.include_router(flexibility.router, prefix="/flexibility", tags=["Flexibility"])

# Email subscription preferences
router.include_router(email_preferences.router, prefix="/email-preferences", tags=["Email Preferences"])

# Leverage-based exercise progressions (mastery tracking, progression suggestions)
router.include_router(exercise_progressions.router, prefix="/exercise-progressions", tags=["Exercise Progressions"])

# Audio preferences for workouts (TTS volume, audio ducking, background music)
router.include_router(audio_preferences.router, prefix="/audio-preferences", tags=["Audio Preferences"])

# Sound effect preferences (countdown beeps, completion sounds - NO applause)
router.include_router(sound_preferences.router, tags=["Sound Preferences"])

# Demo/trial endpoints for pre-signup preview experience (no auth required)
router.include_router(demo.router, tags=["Demo"])

# Visual progress charts (strength over time, volume over time, summary)
router.include_router(progress.router, tags=["Progress"])

# Subjective results tracking (mood, energy, "feel results")
router.include_router(subjective_feedback.router, prefix="/subjective-feedback", tags=["Subjective Feedback"])

# Smart rescheduling for missed workouts (reschedule, skip, AI suggestions)
router.include_router(scheduling.router, prefix="/scheduling", tags=["Scheduling"])

# Consistency insights, streaks, and workout patterns dashboard
router.include_router(consistency.router, prefix="/consistency", tags=["Consistency"])

# Progress milestones and ROI communication
router.include_router(milestones.router, prefix="/progress", tags=["Progress Milestones"])

# Subscription transparency tracking (pre-signup pricing views, trial status)
router.include_router(subscription_transparency.router, tags=["Subscription Transparency"])

# Subscription context logging for AI personalization
router.include_router(subscription_context.router, tags=["Subscription Context"])

# Branded workout programs and user program assignments
router.include_router(programs.router, prefix="/programs", tags=["Programs"])

# Window mode logging (split screen, PiP, freeform) for analytics
router.include_router(window_mode.router, prefix="/window-mode", tags=["Window Mode"])


# NEAT improvement system (step goals, hourly activity, NEAT scores, streaks, achievements)
router.include_router(neat.router, prefix="/neat", tags=["NEAT"])

# Superset preferences and manual pairing
router.include_router(supersets.router, tags=["Supersets"])

# Strain prevention and volume tracking (10% rule, risk assessment)
router.include_router(strain_prevention.router, prefix="/strain-prevention", tags=["Strain Prevention"])

# Injury tracking, recovery check-ins, workout modifications
router.include_router(injuries.router, prefix="/injuries", tags=["Injuries"])

# Senior fitness settings and age-appropriate modifications
router.include_router(senior_fitness.router, prefix="/senior-fitness", tags=["Senior Fitness"])

# Progression pace preferences and AI recommendations
router.include_router(progression_settings.router, prefix="/progression-settings", tags=["Progression Settings"])

# Fasting impact analysis on weight, workouts, and goals
router.include_router(fasting_impact.router, prefix="/fasting-impact", tags=["Fasting Impact"])

# Nutrition preferences, quick logging, meal templates, and food search
router.include_router(nutrition_preferences.router, prefix="/nutrition", tags=["Nutrition Preferences"])

# Diabetes tracking (glucose readings, insulin doses, A1C, medications, alerts)
router.include_router(diabetes.router, tags=["Diabetes Tracking"])

# Per-exercise workout history, progression charts, and personal records
router.include_router(exercise_history.router, tags=["Exercise History"])

# Muscle-level analytics: heatmap, training frequency, balance analysis
router.include_router(muscle_analytics.router, tags=["Muscle Analytics"])

# Hormonal health tracking (testosterone, estrogen, menstrual cycle, recommendations)
router.include_router(hormonal_health.router, tags=["Hormonal Health"])

# Kegel/pelvic floor exercises, preferences, and session tracking
router.include_router(kegel.router, tags=["Kegel/Pelvic Floor"])

# Holistic weekly plans (integrated workouts, nutrition, fasting)
router.include_router(weekly_plans.router, prefix="/weekly-plans", tags=["Weekly Plans"])

# Chat message reporting for AI coach feedback quality improvement
router.include_router(chat_reports.router, prefix="/chat", tags=["Chat Reports"])

# Live chat support with human agents
router.include_router(live_chat.router, prefix="/support/live-chat", tags=["Live Chat"])

# Food inflammation analysis from barcode scans
router.include_router(inflammation.router, prefix="/inflammation", tags=["Inflammation Analysis"])

# Admin backend for live chat management, support tickets, and reports
router.include_router(admin.router, prefix="/admin", tags=["Admin"])

# Simple habit tracking (not eating outside, no doordash, walking 10k steps, etc.)
router.include_router(habits.router, prefix="/habits", tags=["Habits"])

# WearOS watch sync (batch sync, activity goals)
router.include_router(watch_sync.router, tags=["Watch Sync"])

# Equipment-specific weight increment preferences (kg/lbs, per equipment type)
router.include_router(weight_increments.router, prefix="/weight-increments", tags=["Weight Increments"])

# Trophy room and achievement system (trophies, progress, summary)
router.include_router(trophies.router, prefix="/progress", tags=["Trophies"])

# Multi-gym profile system (Robinhood-style switcher for different gyms/locations)
router.include_router(gym_profiles.router, prefix="/gym-profiles", tags=["Gym Profiles"])

# XP events, daily login, streaks, double XP multipliers
router.include_router(xp.router, tags=["XP & Progression"])

# Custom warmup/stretch preferences (pre-workout, post-exercise routines, preferred/avoided)
router.include_router(warmup_preferences.router, tags=["Warmup Preferences"])

# User-defined custom exercises for equipment not in library (with media upload)
router.include_router(custom_exercises.router, tags=["Custom Exercises"])

# Daily schedule planner (workouts, activities, meals, habits in one timeline)
router.include_router(daily_schedule.router, prefix="/daily-schedule", tags=["Daily Schedule"])

# Offline sync bulk upload and import (dead letter recovery, data export/import)
router.include_router(sync.router, tags=["Sync"])

# Exercise popularity scores for collaborative filtering
router.include_router(exercise_popularity.router, tags=["Exercise Popularity"])

# Beast mode custom training preferences (sets, reps, rest, intensity)
router.include_router(beast_mode.router, prefix="/beast-mode", tags=["Beast Mode"])

# Fitness Wrapped monthly recap cards (Spotify-Wrapped-style)
router.include_router(wrapped.router, prefix="/wrapped", tags=["Wrapped"])

# Plateau detection (exercise + weight stalling, recommendations)
router.include_router(plateau.router, prefix="/plateau", tags=["Plateau Detection"])
