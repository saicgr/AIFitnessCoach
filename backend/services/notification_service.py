"""
Push Notification Service using Firebase Admin SDK
Sends push notifications to users via Firebase Cloud Messaging (FCM)
"""

import os
import json
import logging
import random
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime

logger = logging.getLogger(__name__)

# Global Firebase app instance
_firebase_app = None


def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    import firebase_admin
    from firebase_admin import credentials

    global _firebase_app

    if _firebase_app is not None:
        return _firebase_app

    try:
        # Check for credentials file path
        cred_path = os.environ.get('FIREBASE_CREDENTIALS_PATH')

        if cred_path and os.path.exists(cred_path):
            # Use credentials file
            cred = credentials.Certificate(cred_path)
            _firebase_app = firebase_admin.initialize_app(cred)
            logger.info("✅ Firebase initialized with credentials file")
        else:
            # Try to use credentials from environment variable (JSON string)
            cred_json = os.environ.get('FIREBASE_CREDENTIALS_JSON')
            if cred_json:
                cred_dict = json.loads(cred_json)
                cred = credentials.Certificate(cred_dict)
                _firebase_app = firebase_admin.initialize_app(cred)
                logger.info("✅ Firebase initialized with credentials from environment")
            else:
                # Use default credentials (for GCP environments)
                _firebase_app = firebase_admin.initialize_app()
                logger.info("✅ Firebase initialized with default credentials")

        return _firebase_app
    except Exception as e:
        logger.error(f"❌ Failed to initialize Firebase: {e}")
        raise


class NotificationService:
    """Service for sending push notifications via FCM"""

    # Notification types
    TYPE_WORKOUT_REMINDER = "workout_reminder"
    TYPE_NUTRITION_REMINDER = "nutrition_reminder"
    TYPE_HYDRATION_REMINDER = "hydration_reminder"
    TYPE_AI_COACH = "ai_coach"
    TYPE_STREAK_ALERT = "streak_alert"
    TYPE_WEEKLY_SUMMARY = "weekly_summary"
    TYPE_BILLING_REMINDER = "billing_reminder"
    TYPE_MOVEMENT_REMINDER = "movement_reminder"
    TYPE_LIVE_CHAT_MESSAGE = "live_chat_message"
    TYPE_LIVE_CHAT_CONNECTED = "live_chat_connected"
    TYPE_LIVE_CHAT_ENDED = "live_chat_ended"
    TYPE_TEST = "test"

    # Android notification channel IDs (must match Flutter side)
    CHANNEL_IDS = {
        TYPE_WORKOUT_REMINDER: "workout_coach",
        TYPE_NUTRITION_REMINDER: "nutrition_coach",
        TYPE_HYDRATION_REMINDER: "hydration_coach",
        TYPE_STREAK_ALERT: "streak_coach",
        TYPE_WEEKLY_SUMMARY: "progress_coach",
        TYPE_AI_COACH: "ai_coach",
        TYPE_BILLING_REMINDER: "billing_coach",
        TYPE_MOVEMENT_REMINDER: "movement_coach",
        TYPE_LIVE_CHAT_MESSAGE: "live_chat",
        TYPE_LIVE_CHAT_CONNECTED: "live_chat",
        TYPE_LIVE_CHAT_ENDED: "live_chat",
        TYPE_TEST: "test_notifications",
    }

    # Movement reminder message templates (variety to avoid notification fatigue)
    MOVEMENT_REMINDER_TEMPLATES = [
        {
            "title": "Time to move!",
            "body": "You've only taken {steps} steps this hour. A short walk can boost your energy!",
        },
        {
            "title": "Stand up and stretch!",
            "body": "Your body will thank you. Take 2 minutes to move around!",
        },
        {
            "title": "Quick walk?",
            "body": "Just {steps} steps this hour. A quick walk improves circulation and focus.",
        },
        {
            "title": "Get moving!",
            "body": "Reduce sedentary time - every step counts! You're at {steps}/{threshold} steps.",
        },
        {
            "title": "Movement check!",
            "body": "Time to shake off the stiffness. Stand up and take a quick walk!",
        },
        {
            "title": "Desk break time!",
            "body": "Walking improves your mood and productivity. You've taken {steps} steps this hour.",
        },
        {
            "title": "Walk break!",
            "body": "Get up and get those steps in! Small movements add up over time.",
        },
        {
            "title": "Stretch it out!",
            "body": "Only {steps} steps so far. Stand up and move around for a few minutes!",
        },
    ]

    # ─────────────────────────────────────────────────────────────────
    # Phase 1: Template Pools
    # ─────────────────────────────────────────────────────────────────

    # 1a. Workout reminder templates with {name} and {workout_name} placeholders
    WORKOUT_REMINDER_TEMPLATES = [
        {"title": "Hey {name}, your {workout_name} is ready!", "body": "Your body is primed and waiting. Let's make today count."},
        {"title": "Today's plan: {workout_name}", "body": "Everything's set, {name}. Just press play."},
        {"title": "{name}, ready to train?", "body": "One session closer to your goals."},
        {"title": "Time to move, {name}!", "body": "Your {workout_name} won't do itself. Let's go!"},
        {"title": "{workout_name} awaits!", "body": "Show up today and your future self will thank you."},
        {"title": "Let's get after it, {name}!", "body": "Your {workout_name} is loaded and ready to roll."},
        {"title": "Training time!", "body": "{name}, your {workout_name} is calling. Answer with action."},
        {"title": "Your workout is set!", "body": "{workout_name} is ready. Lace up and let's do this, {name}."},
        {"title": "Ready when you are, {name}!", "body": "Today's {workout_name} is waiting. Let's build something great."},
        {"title": "Rise and grind!", "body": "{name}, your {workout_name} is prepped. Time to earn it."},
    ]

    # 1b. Inactivity nudge templates - 3 tiers, positive/progress-affirming (NO guilt/shame)
    INACTIVITY_NUDGE_1DAY = [
        {"title": "Pick up where you left off!", "body": "Your next workout is ready whenever you are."},
        {"title": "Quick check-in!", "body": "Yesterday was rest -- today's a fresh start."},
        {"title": "One day off, no worries!", "body": "Consistency is about the long game. Ready to jump back in?"},
        {"title": "Your workout is waiting!", "body": "A single session can set the tone for the whole week."},
    ]
    INACTIVITY_NUDGE_2DAY = [
        {"title": "Two days off -- feeling rested?", "body": "Sometimes rest is progress. Ready to move again?"},
        {"title": "Recharged and ready?", "body": "Two rest days in the bank. Time to spend that energy!"},
        {"title": "Your body's had a break!", "body": "A quick session today can feel amazing after some rest."},
        {"title": "Fresh start today?", "body": "Two days off means your muscles are recovered. Let's use that."},
    ]
    INACTIVITY_NUDGE_3PLUS_DAY = [
        {"title": "Welcome back anytime!", "body": "It's been {days} days. No pressure -- just pick one exercise to start."},
        {"title": "We saved your spot!", "body": "{days} days away, but your plan is still here. Start small."},
        {"title": "Every comeback starts with one rep!", "body": "It's been {days} days. A 10-minute session is all it takes."},
        {"title": "No judgment, just progress!", "body": "{days} days off? That's okay. Today is a great day to start fresh."},
    ]

    # 1c. Streak celebration templates with {streak} placeholder
    STREAK_CELEBRATION_TEMPLATES = [
        {"title": "{streak}-day streak!", "body": "You've shown up {streak} days in a row. That's real dedication."},
        {"title": "Streak: {streak} days!", "body": "Consistency is your superpower. Keep it rolling!"},
        {"title": "{streak} days strong!", "body": "Every day you show up, you're building a better you."},
        {"title": "On fire: {streak} days!", "body": "This streak is proof that discipline beats motivation."},
        {"title": "{streak} and counting!", "body": "You're not stopping anytime soon. Incredible work!"},
        {"title": "Day {streak} -- unstoppable!", "body": "Most people quit by now. You didn't. Respect."},
        {"title": "Still going: {streak} days!", "body": "Your future self is cheering right now."},
        {"title": "{streak}-day champion!", "body": "This is what commitment looks like. Keep going!"},
    ]
    # Special milestone messages
    STREAK_MILESTONE_TEMPLATES = {
        7: {"title": "1 Week Streak!", "body": "7 days strong! You've built a real habit. This is just the beginning."},
        14: {"title": "2 Week Streak!", "body": "14 days of consistency. You're officially in a groove!"},
        30: {"title": "30-Day Streak!", "body": "A full month! You've proven this isn't a phase -- it's a lifestyle."},
        50: {"title": "50 Days!", "body": "Half a hundred days of dedication. You're in elite company now."},
        100: {"title": "100-Day Streak!", "body": "Triple digits! This is extraordinary discipline. Be proud."},
        365: {"title": "365-Day Streak!", "body": "ONE FULL YEAR. You are a legend. Absolutely incredible."},
    }

    # 1d. Nutrition reminder templates per meal type
    NUTRITION_BREAKFAST_TEMPLATES = [
        {"title": "Good morning! Log your breakfast", "body": "Start your day right -- track what fuels your morning."},
        {"title": "Breakfast time!", "body": "Snap a pic or log your meal to stay on track."},
        {"title": "Fuel up!", "body": "A logged breakfast sets the tone for the whole day."},
        {"title": "Morning fuel check!", "body": "What's on the plate? Log your breakfast to keep your streak."},
        {"title": "Rise and eat!", "body": "Track your breakfast and start the day with intention."},
        {"title": "Breakfast check-in!", "body": "Log your morning meal -- it takes 10 seconds."},
        {"title": "Don't skip tracking!", "body": "Your breakfast matters. Log it to see your full picture."},
        {"title": "Morning nutrition!", "body": "Quick -- log what you're eating before the day gets busy."},
    ]
    NUTRITION_LUNCH_TEMPLATES = [
        {"title": "Lunchtime! Log your meal", "body": "Midday fuel matters. Keep your nutrition on point."},
        {"title": "Lunch check-in!", "body": "What are you having? Log it in under 10 seconds."},
        {"title": "Midday fuel!", "body": "Track your lunch to keep your nutrition goals on track."},
        {"title": "Time to log lunch!", "body": "A quick snap or log keeps your day on track."},
        {"title": "Lunch break = log break!", "body": "Take a sec to track what you're eating."},
        {"title": "Halfway through the day!", "body": "Log your lunch to see how your macros are looking."},
        {"title": "Fuel check!", "body": "Lunchtime logging keeps you aware and in control."},
        {"title": "What's for lunch?", "body": "Log it now so you don't forget later!"},
    ]
    NUTRITION_DINNER_TEMPLATES = [
        {"title": "Dinner time! Log your meal", "body": "End your day strong -- track your evening nutrition."},
        {"title": "Evening fuel!", "body": "Log your dinner to complete today's nutrition picture."},
        {"title": "Last meal of the day!", "body": "Track your dinner and see how you did today."},
        {"title": "Dinner check-in!", "body": "What's on the plate tonight? Log it to stay on track."},
        {"title": "Wrap up your nutrition!", "body": "Log dinner and you'll have a full day of tracking."},
        {"title": "Time to log dinner!", "body": "A quick entry completes your daily nutrition log."},
        {"title": "Evening nutrition check!", "body": "Track your dinner -- your tomorrow self will appreciate it."},
        {"title": "Finish strong!", "body": "Log your dinner to close out today's nutrition."},
    ]
    NUTRITION_GENERIC_TEMPLATES = [
        {"title": "Time to log your meal!", "body": "Tracking your food takes 10 seconds and pays off big."},
        {"title": "Meal check-in!", "body": "Snap a photo or log what you're eating to stay on target."},
        {"title": "Fuel your progress!", "body": "Log your meal to keep your nutrition goals on track."},
        {"title": "Track your nutrition!", "body": "Quick -- log what you're eating before you forget."},
        {"title": "Nutrition reminder!", "body": "Every meal logged is a step closer to your goals."},
        {"title": "Don't forget to log!", "body": "A few taps now means better insights later."},
        {"title": "Food tracking time!", "body": "Stay consistent with your logging. You're doing great!"},
        {"title": "Log your meal!", "body": "Keeping track of nutrition is half the battle. You've got this."},
    ]

    # 1e. Hydration reminder templates - 3 tiers based on progress
    # Low tier: <40% of goal
    HYDRATION_LOW_TEMPLATES = [
        {"title": "Time to hydrate!", "body": "You're at {percent}% of your water goal. Your body needs fuel!"},
        {"title": "Water check!", "body": "Only {percent}% of your hydration goal so far. Grab a glass!"},
        {"title": "Stay hydrated!", "body": "You're at {percent}%. A few glasses can make a big difference."},
        {"title": "Drink up!", "body": "{percent}% of your water goal. Even a small sip counts!"},
        {"title": "Hydration alert!", "body": "You're behind at {percent}%. Time to catch up on water."},
        {"title": "Your body needs water!", "body": "At {percent}% of your goal. Pour yourself a tall glass!"},
    ]
    # Medium tier: 40-75% of goal
    HYDRATION_MEDIUM_TEMPLATES = [
        {"title": "Solid progress!", "body": "You're at {percent}% of your water goal. Keep sipping!"},
        {"title": "Halfway there!", "body": "{percent}% of your hydration goal reached. Keep it up!"},
        {"title": "Good hydration!", "body": "You're at {percent}%. A few more glasses to hit your target."},
        {"title": "Keep drinking!", "body": "{percent}% done. You're on pace -- don't slow down now!"},
    ]
    # High tier: >75% of goal
    HYDRATION_HIGH_TEMPLATES = [
        {"title": "Almost there!", "body": "You're at {percent}% of your water goal. The finish line is close!"},
        {"title": "So close!", "body": "{percent}% hydrated. Just a little more to hit your goal!"},
        {"title": "Final stretch!", "body": "You're at {percent}%. One or two more glasses and you're done!"},
        {"title": "Crushing it!", "body": "{percent}% of your water goal. You're almost at 100%!"},
    ]

    # 1f. Weekly summary templates with {count} placeholder
    WEEKLY_SUMMARY_TEMPLATES = [
        {"title": "Your weekly report is ready!", "body": "You completed {count} workout{s} this week. Check your progress!"},
        {"title": "Week in review!", "body": "{count} workout{s} done this week. See how you stacked up!"},
        {"title": "Weekly recap is here!", "body": "{count} session{s} this week. Tap to see your full breakdown."},
        {"title": "Your progress this week!", "body": "{count} workout{s} completed. Let's see the numbers!"},
        {"title": "Weekly summary ready!", "body": "This week: {count} workout{s}. Your report has all the details."},
        {"title": "How'd your week go?", "body": "{count} training session{s} logged. Check your trends and stats!"},
        {"title": "Time for your weekly review!", "body": "{count} workout{s} in the books. See your progress report."},
        {"title": "Week complete!", "body": "You trained {count} time{s} this week. Your summary awaits!"},
    ]

    # ─────────────────────────────────────────────────────────────────
    # 2. Accountability Coach Templates
    # ─────────────────────────────────────────────────────────────────
    # Keyed by (nudge_type, intensity). Placeholders: {coach_name}, {name},
    # {workout_name}, {streak}, {days}, {meal_type}, {incomplete_count}

    ACCOUNTABILITY_TEMPLATES = {
        # --- Morning Workout Reminder ---
        ("morning_workout", "gentle"): [
            {"title": "{coach_name}", "body": "Good morning, {name}! {workout_name} is on your schedule today. No rush."},
            {"title": "{coach_name}", "body": "Hey {name}, just a heads up — {workout_name} is ready when you are."},
            {"title": "{coach_name}", "body": "Morning! {workout_name} is on today's plan. You've got this."},
            {"title": "{coach_name}", "body": "{name}, {workout_name} is waiting for you whenever you're ready today."},
            {"title": "{coach_name}", "body": "Rise and shine! {workout_name} is today's focus. Take it at your pace."},
            {"title": "{coach_name}", "body": "Good morning! Your {workout_name} is all set for today."},
        ],
        ("morning_workout", "balanced"): [
            {"title": "{coach_name}", "body": "Hey {name}! Today's {workout_name} is loaded and ready. Let's crush it!"},
            {"title": "{coach_name}", "body": "Time to work, {name}! {workout_name} won't do itself. Let's go!"},
            {"title": "{coach_name}", "body": "{name}, your {workout_name} is calling. Answer with action!"},
            {"title": "{coach_name}", "body": "Today's plan: {workout_name}. Show up and the results will follow."},
            {"title": "{coach_name}", "body": "Rise and grind! {workout_name} is ready. One session closer to your goals."},
            {"title": "{coach_name}", "body": "{name}! {workout_name} is locked in. Make it count today."},
        ],
        ("morning_workout", "tough_love"): [
            {"title": "{coach_name}", "body": "GET UP! {workout_name} is TODAY. No excuses, {name}!"},
            {"title": "{coach_name}", "body": "{name}! {workout_name} isn't going to lift itself. MOVE IT!"},
            {"title": "{coach_name}", "body": "Your alarm went off for a reason. {workout_name}. NOW."},
            {"title": "{coach_name}", "body": "Champions don't snooze. {workout_name} is waiting. Get after it!"},
            {"title": "{coach_name}", "body": "{name}, you signed up for this. {workout_name} is on deck. Let's GO!"},
            {"title": "{coach_name}", "body": "No negotiation. {workout_name} today. The iron doesn't care about your excuses."},
        ],

        # --- Missed Workout Nudge ---
        ("missed_workout", "gentle"): [
            {"title": "{coach_name}", "body": "Still time for {workout_name} today! Even a quick session counts."},
            {"title": "{coach_name}", "body": "Hey {name}, your {workout_name} is still on the schedule. No pressure!"},
            {"title": "{coach_name}", "body": "Busy day? {workout_name} is still there whenever you have 20 minutes."},
            {"title": "{coach_name}", "body": "{name}, just checking in — {workout_name} hasn't been marked done yet."},
            {"title": "{coach_name}", "body": "Your {workout_name} is patiently waiting. Even 15 minutes makes a difference."},
            {"title": "{coach_name}", "body": "Friendly nudge: {workout_name} is still on today's list!"},
        ],
        ("missed_workout", "balanced"): [
            {"title": "{coach_name}", "body": "Hey {name}! Your {workout_name} is still waiting. Even 20 minutes counts!"},
            {"title": "{coach_name}", "body": "{workout_name} is on the clock! Don't let the day slip by, {name}."},
            {"title": "{coach_name}", "body": "Evening check-in: {workout_name} is undone. Quick session before bed?"},
            {"title": "{coach_name}", "body": "{name}, you've got time for a quick {workout_name}. Future you will be grateful!"},
            {"title": "{coach_name}", "body": "Don't skip today! {workout_name} is ready. Show up for 20 minutes."},
            {"title": "{coach_name}", "body": "Your {workout_name} misses you. Just one session — you'll feel great after!"},
        ],
        ("missed_workout", "tough_love"): [
            {"title": "{coach_name}", "body": "Still no workout logged?! {workout_name} is RIGHT THERE. Get moving, {name}!"},
            {"title": "{coach_name}", "body": "{name}, what happened to {workout_name}?! The gym doesn't close yet!"},
            {"title": "{coach_name}", "body": "Excuses or results. Pick one. {workout_name} is still available."},
            {"title": "{coach_name}", "body": "The day isn't over until {workout_name} is done. Get off the couch!"},
            {"title": "{coach_name}", "body": "{name}! I didn't program {workout_name} for it to sit there untouched!"},
            {"title": "{coach_name}", "body": "Your {workout_name} is gathering dust. Is that who you want to be?"},
        ],

        # --- Meal Logging Reminder ---
        ("meal_reminder", "gentle"): [
            {"title": "{coach_name}", "body": "Time for {meal_type}! Don't forget to log what you eat."},
            {"title": "{coach_name}", "body": "Quick reminder to track your {meal_type}, {name}."},
            {"title": "{coach_name}", "body": "{meal_type} time! A quick log keeps your nutrition on track."},
            {"title": "{coach_name}", "body": "Hey {name}, remember to log your {meal_type} when you get a chance."},
            {"title": "{coach_name}", "body": "Tracking your {meal_type} takes 10 seconds. Worth it!"},
            {"title": "{coach_name}", "body": "{name}, have you logged {meal_type} yet? Every meal counts!"},
        ],
        ("meal_reminder", "balanced"): [
            {"title": "{coach_name}", "body": "{meal_type} check-in! Log your meal to keep your macros on point, {name}."},
            {"title": "{coach_name}", "body": "Don't let {meal_type} go untracked! Snap a pic or log it quick."},
            {"title": "{coach_name}", "body": "Nutrition is half the battle! Log your {meal_type} now, {name}."},
            {"title": "{coach_name}", "body": "{name}, your {meal_type} is missing from today's log. Fix that!"},
            {"title": "{coach_name}", "body": "Tracking builds awareness. Log your {meal_type} before you forget!"},
            {"title": "{coach_name}", "body": "Quick — log your {meal_type}! Consistency with tracking = results."},
        ],
        ("meal_reminder", "tough_love"): [
            {"title": "{coach_name}", "body": "LOG YOUR {meal_type}! You can't improve what you don't track, {name}!"},
            {"title": "{coach_name}", "body": "{name}! No {meal_type} logged = no accountability. Track it NOW!"},
            {"title": "{coach_name}", "body": "Your {meal_type} isn't going to log itself. 10 seconds. Do it."},
            {"title": "{coach_name}", "body": "Skipping tracking is skipping progress. Log that {meal_type}!"},
            {"title": "{coach_name}", "body": "{meal_type} untracked? That's amateur hour, {name}. Log it!"},
            {"title": "{coach_name}", "body": "TRACK. YOUR. {meal_type}. No excuses. Champions track everything."},
        ],

        # --- Post-Workout Nutrition ---
        ("post_workout_meal", "gentle"): [
            {"title": "{coach_name}", "body": "Great workout! Remember to refuel with a good meal, {name}."},
            {"title": "{coach_name}", "body": "Nice session! Your muscles need fuel now. Log your post-workout meal."},
            {"title": "{coach_name}", "body": "Workout done! Time to eat and recover. Don't forget to log it."},
            {"title": "{coach_name}", "body": "{name}, your body needs nutrients after that workout. What are you eating?"},
            {"title": "{coach_name}", "body": "Post-workout window is open! Grab some protein and log your meal."},
            {"title": "{coach_name}", "body": "Recovery starts with nutrition. Log your post-workout meal when ready!"},
        ],
        ("post_workout_meal", "balanced"): [
            {"title": "{coach_name}", "body": "Crushed that workout! Now fuel the gains — log your post-workout meal!"},
            {"title": "{coach_name}", "body": "The workout was just half the work. Refuel and log it, {name}!"},
            {"title": "{coach_name}", "body": "Muscles are screaming for protein! Log your post-workout meal now."},
            {"title": "{coach_name}", "body": "Don't waste that workout! Eat well and track it. Your gains depend on it."},
            {"title": "{coach_name}", "body": "{name}, 30 minutes post-workout = prime fuel window. Log your meal!"},
            {"title": "{coach_name}", "body": "Great session! The anabolic window is open. Eat, track, grow!"},
        ],
        ("post_workout_meal", "tough_love"): [
            {"title": "{coach_name}", "body": "You worked out but didn't eat?! LOG YOUR MEAL. Recovery matters!"},
            {"title": "{coach_name}", "body": "All that work for nothing if you don't fuel up! Track your meal NOW!"},
            {"title": "{coach_name}", "body": "{name}! Workout without nutrition = wasted effort. Eat and log it!"},
            {"title": "{coach_name}", "body": "Your muscles are STARVING. Feed them. Log the meal. Do it now."},
            {"title": "{coach_name}", "body": "Don't you dare skip post-workout nutrition! Log what you eat!"},
            {"title": "{coach_name}", "body": "The gains fairy doesn't visit if you don't eat! Log. Your. Meal."},
        ],

        # --- Streak At Risk ---
        ("streak_at_risk", "gentle"): [
            {"title": "{coach_name}", "body": "Your {streak}-day streak is still safe! A quick workout keeps it going."},
            {"title": "{coach_name}", "body": "Hey {name}, your streak is at {streak} days. Would hate to see it end!"},
            {"title": "{coach_name}", "body": "{streak} days of consistency! Even a 15-minute session protects your streak."},
            {"title": "{coach_name}", "body": "Just checking in — your {streak}-day streak ends at midnight. No pressure!"},
            {"title": "{coach_name}", "body": "{name}, you've been so consistent! Quick session to keep the {streak}-day streak alive?"},
            {"title": "{coach_name}", "body": "Your {streak}-day streak is on the line. A light workout is all it takes!"},
        ],
        ("streak_at_risk", "balanced"): [
            {"title": "{coach_name}", "body": "Your {streak}-day streak ends TONIGHT! Quick 15-min workout to save it?"},
            {"title": "{coach_name}", "body": "{streak} days of hard work on the line! Don't let it end today, {name}!"},
            {"title": "{coach_name}", "body": "Tick tock! Your {streak}-day streak needs a workout before midnight."},
            {"title": "{coach_name}", "body": "{name}, {streak} days is impressive. A quick session keeps it alive!"},
            {"title": "{coach_name}", "body": "Don't break the chain! {streak} days and counting. Get a quick one in!"},
            {"title": "{coach_name}", "body": "Your {streak}-day streak is too good to lose. 20 minutes is all you need!"},
        ],
        ("streak_at_risk", "tough_love"): [
            {"title": "{coach_name}", "body": "{streak} DAYS! You're going to throw that away?! GET TO THE GYM!"},
            {"title": "{coach_name}", "body": "{name}! {streak}-day streak dies at midnight. Is that what you want?!"},
            {"title": "{coach_name}", "body": "Your {streak}-day streak is DYING. Save it or regret it tomorrow!"},
            {"title": "{coach_name}", "body": "{streak} consecutive days of discipline. Don't quit now. MOVE!"},
            {"title": "{coach_name}", "body": "LAST CHANCE! {streak}-day streak ends in hours. No excuses!"},
            {"title": "{coach_name}", "body": "You built {streak} days of momentum. DON'T. BREAK. THE. CHAIN."},
        ],

        # --- Weekly Check-In ---
        ("weekly_checkin", "gentle"): [
            {"title": "{coach_name}", "body": "Time for your weekly nutrition check-in! See how you did this week."},
            {"title": "{coach_name}", "body": "Hey {name}, your weekly review is ready. Take a quick look!"},
            {"title": "{coach_name}", "body": "Weekly nutrition check-in time! It only takes a minute."},
            {"title": "{coach_name}", "body": "Your weekly summary is waiting. Let's see your progress, {name}!"},
        ],
        ("weekly_checkin", "balanced"): [
            {"title": "{coach_name}", "body": "Weekly check-in time! Review your nutrition and adjust your targets."},
            {"title": "{coach_name}", "body": "{name}, your weekly nutrition summary is ready. Don't skip it!"},
            {"title": "{coach_name}", "body": "It's review day! Check your weekly nutrition and set next week up for success."},
            {"title": "{coach_name}", "body": "Weekly accountability check! How did your nutrition stack up?"},
        ],
        ("weekly_checkin", "tough_love"): [
            {"title": "{coach_name}", "body": "WEEKLY CHECK-IN! No skipping. Review your nutrition NOW, {name}!"},
            {"title": "{coach_name}", "body": "You can't improve without reviewing. Do your weekly check-in!"},
            {"title": "{coach_name}", "body": "Weekly review time. Face the numbers. That's how champions improve."},
            {"title": "{coach_name}", "body": "{name}! Skip the check-in and you're flying blind. Do it now."},
        ],

        # --- Habit Reminder ---
        ("habit_reminder", "gentle"): [
            {"title": "{coach_name}", "body": "Don't forget your daily habits! {incomplete_count} left to complete."},
            {"title": "{coach_name}", "body": "{name}, you have {incomplete_count} habits left for today. No rush!"},
            {"title": "{coach_name}", "body": "Evening check: {incomplete_count} habits still open. You've got this!"},
            {"title": "{coach_name}", "body": "Quick reminder to check off your remaining {incomplete_count} habits today."},
            {"title": "{coach_name}", "body": "{incomplete_count} habits to go! Small daily wins add up, {name}."},
            {"title": "{coach_name}", "body": "Before bed: {incomplete_count} habits left. Even completing one counts!"},
        ],
        ("habit_reminder", "balanced"): [
            {"title": "{coach_name}", "body": "{incomplete_count} habits incomplete! Log them before the day ends, {name}!"},
            {"title": "{coach_name}", "body": "Don't break your habit streaks! {incomplete_count} left to check off today."},
            {"title": "{coach_name}", "body": "Evening habit check: {incomplete_count} to go. Finish strong, {name}!"},
            {"title": "{coach_name}", "body": "{name}, {incomplete_count} habits are waiting. Small wins = big results!"},
            {"title": "{coach_name}", "body": "Almost bedtime! {incomplete_count} habits still need your attention."},
            {"title": "{coach_name}", "body": "Habit check! {incomplete_count} left. Don't let today's streak die!"},
        ],
        ("habit_reminder", "tough_love"): [
            {"title": "{coach_name}", "body": "{incomplete_count} HABITS UNDONE! Finish them NOW, {name}!"},
            {"title": "{coach_name}", "body": "You set these habits for a reason! {incomplete_count} left. NO EXCUSES!"},
            {"title": "{coach_name}", "body": "The day isn't done until your habits are! {incomplete_count} remaining!"},
            {"title": "{coach_name}", "body": "{name}! {incomplete_count} habits hanging? That's not discipline!"},
            {"title": "{coach_name}", "body": "CHECK. OFF. YOUR. HABITS. {incomplete_count} left. Handle it!"},
            {"title": "{coach_name}", "body": "Champions complete their habits EVERY day. {incomplete_count} to go. FINISH!"},
        ],
    }

    # ─────────────────────────────────────────────────────────────────
    # 3. Guilt Escalation Templates (Duolingo-style)
    # ─────────────────────────────────────────────────────────────────
    # Keyed by (days_tier, intensity). Tiers: 1, 2, 3, 5, 7, 14 days inactive.
    # Placeholders: {coach_name}, {name}, {days}

    GUILT_ESCALATION_TEMPLATES = {
        # --- 1 Day Inactive ---
        (1, "gentle"): [
            {"title": "{coach_name}", "body": "Rest day? {coach_name} will be here when you're ready, {name}."},
            {"title": "{coach_name}", "body": "One day off is totally fine! See you tomorrow, {name}."},
            {"title": "{coach_name}", "body": "Taking a breather? Your next workout is ready when you are."},
            {"title": "{coach_name}", "body": "Everyone needs rest! {coach_name} is saving your spot."},
        ],
        (1, "balanced"): [
            {"title": "{coach_name}", "body": "{coach_name} noticed you took yesterday off. Fresh start today, {name}?"},
            {"title": "{coach_name}", "body": "One day off — no big deal! But let's get back at it today, {name}."},
            {"title": "{coach_name}", "body": "Yesterday was rest. Today is action! Ready to train, {name}?"},
            {"title": "{coach_name}", "body": "{name}, {coach_name} missed you yesterday. Back at it today?"},
        ],
        (1, "tough_love"): [
            {"title": "{coach_name}", "body": "{coach_name} is watching. One day off is fine. Two is a pattern."},
            {"title": "{coach_name}", "body": "Yesterday: no workout. Today: no excuses. Get moving, {name}!"},
            {"title": "{coach_name}", "body": "One day off? Acceptable. But don't make it a habit, {name}."},
            {"title": "{coach_name}", "body": "The weights don't lift themselves, {name}. Yesterday's rest is over."},
        ],

        # --- 2 Days Inactive ---
        (2, "gentle"): [
            {"title": "{coach_name}", "body": "{coach_name} is thinking of you! No rush, {name}."},
            {"title": "{coach_name}", "body": "Two days off — hope you're resting well! Come back when ready."},
            {"title": "{coach_name}", "body": "Missing you at the gym, {name}! Take your time though."},
            {"title": "{coach_name}", "body": "Two rest days can be great for recovery! Ready to resume?"},
        ],
        (2, "balanced"): [
            {"title": "{coach_name}", "body": "{coach_name} is starting to worry... Your workout misses you, {name}!"},
            {"title": "{coach_name}", "body": "Two days off — feeling rested? Time to put that energy to work!"},
            {"title": "{coach_name}", "body": "{name}, it's been 2 days. A quick session will get you back in the groove!"},
            {"title": "{coach_name}", "body": "Recharged and ready? Two rest days means extra energy for today!"},
        ],
        (2, "tough_love"): [
            {"title": "{coach_name}", "body": "Two days off? That's not the {name} I know. Let's go!"},
            {"title": "{coach_name}", "body": "{name}! Two days. I'm not asking — I'm telling. Get to the gym!"},
            {"title": "{coach_name}", "body": "Two days without training. The excuses stop NOW, {name}."},
            {"title": "{coach_name}", "body": "Day 2 of nothing. Your goals don't take days off. Neither should you."},
        ],

        # --- 3 Days Inactive ---
        (3, "gentle"): [
            {"title": "{coach_name}", "body": "{coach_name} just wants to check in. Everything okay, {name}?"},
            {"title": "{coach_name}", "body": "It's been 3 days. No judgment — just want to make sure you're alright!"},
            {"title": "{coach_name}", "body": "Hey {name}, {coach_name} is here whenever you're ready to come back."},
            {"title": "{coach_name}", "body": "Three days off. Life gets busy! Your workout will be here when you return."},
        ],
        (3, "balanced"): [
            {"title": "{coach_name}", "body": "{coach_name} hasn't heard from you in 3 days. Everything okay, {name}?"},
            {"title": "{coach_name}", "body": "3 days... {name}, your momentum is slipping! One session turns it around."},
            {"title": "{coach_name}", "body": "Three days away! {coach_name} kept your workout warm. Come back!"},
            {"title": "{coach_name}", "body": "{name}, day 3 without training. Don't let a habit die. Show up today!"},
        ],
        (3, "tough_love"): [
            {"title": "{coach_name}", "body": "THREE days?! {name}, we need to talk. Get your gear on. NOW!"},
            {"title": "{coach_name}", "body": "3 days of excuses. {name}, is this who you want to be?!"},
            {"title": "{coach_name}", "body": "Day 3. No workout. {coach_name} is NOT impressed, {name}!"},
            {"title": "{coach_name}", "body": "THREE DAYS! The gym is starting to forget your name, {name}!"},
        ],

        # --- 5 Days Inactive ---
        (5, "gentle"): [
            {"title": "{coach_name}", "body": "{coach_name} saved your spot. Come back anytime, {name}."},
            {"title": "{coach_name}", "body": "It's been a few days. {coach_name} believes in you, {name}!"},
            {"title": "{coach_name}", "body": "No pressure, but {coach_name} is here ready to help when you're back."},
            {"title": "{coach_name}", "body": "5 days — life happens! A 10-minute walk counts. Start small, {name}."},
        ],
        (5, "balanced"): [
            {"title": "{coach_name}", "body": "{coach_name} is considering sending a search party for you, {name}..."},
            {"title": "{coach_name}", "body": "5 days without a workout? {name}, that's not like you! Come back!"},
            {"title": "{coach_name}", "body": "{name}, {coach_name} has been staring at your empty schedule for 5 days..."},
            {"title": "{coach_name}", "body": "Day 5. Your gains are filing a missing person's report, {name}."},
        ],
        (5, "tough_love"): [
            {"title": "{coach_name}", "body": "{coach_name} is about to call your emergency contact, {name}!"},
            {"title": "{coach_name}", "body": "FIVE DAYS?! {name}, your muscles are atrophying as we speak!"},
            {"title": "{coach_name}", "body": "5 days off. {name}, this is a full-blown crisis. GET MOVING!"},
            {"title": "{coach_name}", "body": "Day 5 of nothing. {coach_name} didn't sign up for this, {name}!"},
        ],

        # --- 7 Days Inactive ---
        (7, "gentle"): [
            {"title": "{coach_name}", "body": "{coach_name} misses you, {name}. Your weights are gathering dust."},
            {"title": "{coach_name}", "body": "A whole week! {coach_name} is still here for you, {name}."},
            {"title": "{coach_name}", "body": "It's been 7 days. No judgment. Just one workout to restart, {name}."},
            {"title": "{coach_name}", "body": "One week away. {coach_name} kept everything ready for your comeback!"},
        ],
        (7, "balanced"): [
            {"title": "{coach_name}", "body": "{coach_name} has been staring at your empty gym slot all week, {name}..."},
            {"title": "{coach_name}", "body": "7 days! {name}, your fitness is going in reverse. One session fixes it!"},
            {"title": "{coach_name}", "body": "A full week without training, {name}! {coach_name} is NOT giving up on you."},
            {"title": "{coach_name}", "body": "{name}, 7 days is a slump. {coach_name} has a comeback plan ready!"},
        ],
        (7, "tough_love"): [
            {"title": "{coach_name}", "body": "{coach_name} has started training your replacement. Just kidding. Or am I?"},
            {"title": "{coach_name}", "body": "ONE FULL WEEK, {name}! That's not a rest day — that's a surrender!"},
            {"title": "{coach_name}", "body": "7 days of nothing. {name}, {coach_name} is DEEPLY disappointed."},
            {"title": "{coach_name}", "body": "A WEEK?! {name}, do you even remember where the gym is?!"},
        ],

        # --- 14+ Days Inactive (Win-back) ---
        (14, "gentle"): [
            {"title": "{coach_name}", "body": "It's been {days} days. {coach_name} still believes in you, {name}."},
            {"title": "{coach_name}", "body": "{days} days away, but your plan is still here. Start small, {name}."},
            {"title": "{coach_name}", "body": "Every comeback starts with one rep. {coach_name} is ready when you are."},
            {"title": "{coach_name}", "body": "Hey {name}, it's been a while. {coach_name} saved your workouts for you."},
        ],
        (14, "balanced"): [
            {"title": "{coach_name}", "body": "{days} days, {name}. No judgment. Just one workout. That's all {coach_name} asks."},
            {"title": "{coach_name}", "body": "It's been {days} days. {name}, your comeback story starts today!"},
            {"title": "{coach_name}", "body": "{coach_name} checked — your last workout was {days} days ago. Time to fix that!"},
            {"title": "{coach_name}", "body": "{days} days without training. {name}, {coach_name} has a recovery plan ready!"},
        ],
        (14, "tough_love"): [
            {"title": "{coach_name}", "body": "{days} days. {coach_name} hasn't given up on you. Don't give up on yourself, {name}."},
            {"title": "{coach_name}", "body": "{days} DAYS, {name}! This is your wake-up call. TODAY you change this."},
            {"title": "{coach_name}", "body": "It's been {days} days. {name}, {coach_name} is still here. ARE YOU?!"},
            {"title": "{coach_name}", "body": "{days} days of silence. {name}, get off the sidelines. NOW!"},
        ],
    }

    # Default channel
    DEFAULT_CHANNEL_ID = "fitwiz_notifications"

    def __init__(self):
        """Initialize the notification service"""
        initialize_firebase()

    def _get_channel_id(self, notification_type: str) -> str:
        """Get the Android notification channel ID for a notification type"""
        return self.CHANNEL_IDS.get(notification_type, self.DEFAULT_CHANNEL_ID)

    @staticmethod
    def _get_time_of_day(user_timezone: Optional[str] = None) -> str:
        """Get the time of day based on user's timezone.

        Returns: 'morning' (5-12), 'afternoon' (12-17), 'evening' (17-21), 'night' (21-5)
        """
        try:
            if user_timezone:
                import pytz
                tz = pytz.timezone(user_timezone)
                hour = datetime.now(tz).hour
            else:
                hour = datetime.utcnow().hour
        except Exception:
            hour = datetime.utcnow().hour

        if 5 <= hour < 12:
            return "morning"
        elif 12 <= hour < 17:
            return "afternoon"
        elif 17 <= hour < 21:
            return "evening"
        else:
            return "night"

    # ─────────────────────────────────────────────────────────────────
    # Phase 3: Gemini-Powered Personalization
    # ─────────────────────────────────────────────────────────────────

    async def _generate_personalized_message(
        self,
        notification_type: str,
        user_name: Optional[str] = None,
        streak: Optional[int] = None,
        workout_name: Optional[str] = None,
        time_of_day: Optional[str] = None,
        days_missed: Optional[int] = None,
        workouts_completed: Optional[int] = None,
        # Coach persona params (for accountability nudges)
        coach_name: Optional[str] = None,
        coaching_style: Optional[str] = None,
        communication_tone: Optional[str] = None,
        use_emojis: bool = True,
        accountability_intensity: Optional[str] = None,
    ) -> Optional[Tuple[str, str]]:
        """Generate a personalized notification message using Gemini.

        When coach persona params are provided (coach_name, coaching_style, etc.),
        the prompt instructs Gemini to write in-character as the user's selected
        AI coach. This enables Duolingo-style personality-driven notifications.

        Args:
            notification_type: The type of nudge (e.g., 'missed_workout', 'guilt_day3')
            user_name: The user's display name
            streak: Current workout streak in days
            workout_name: Name of the relevant workout
            time_of_day: 'morning', 'afternoon', 'evening', 'night'
            days_missed: Days since last workout (for guilt escalation)
            workouts_completed: Workouts completed this week
            coach_name: User's selected coach name (e.g., "Coach Mike", "Sensei")
            coaching_style: Coach personality (e.g., "drill-sergeant", "zen-master")
            communication_tone: Language style (e.g., "gen-z", "pirate", "british")
            use_emojis: Whether to include emojis in the message
            accountability_intensity: "gentle", "balanced", or "tough_love"

        Returns:
            (title, body) tuple, or None on any failure (falls back to template).
        """
        try:
            from google import genai
            from core.gemini_client import get_genai_client
            from core.config import get_settings

            settings = get_settings()
            client = get_genai_client()

            # Build context string
            context_parts = []
            if user_name:
                context_parts.append(f"User name: {user_name}")
            if streak is not None:
                context_parts.append(f"Current streak: {streak} days")
            if workout_name:
                context_parts.append(f"Workout: {workout_name}")
            if time_of_day:
                context_parts.append(f"Time of day: {time_of_day}")
            if days_missed is not None:
                context_parts.append(f"Days since last workout: {days_missed}")
            if workouts_completed is not None:
                context_parts.append(f"Workouts completed this week: {workouts_completed}")

            context_str = ". ".join(context_parts)

            # EDGE CASE: If coach persona is provided, use persona-aware prompt.
            # Otherwise fall back to the generic notification writer prompt.
            if coach_name or coaching_style:
                coach_display = coach_name or "Coach"
                style = coaching_style or "motivational"
                tone = communication_tone or "encouraging"
                intensity = accountability_intensity or "balanced"
                emoji_instruction = "Use emojis for emphasis." if use_emojis else "No emojis."

                prompt = (
                    f"You are {coach_display}, a personal fitness coach. "
                    f"Your coaching style is {style}. "
                    f"Your communication tone is {tone}. "
                    f"Accountability intensity: {intensity}. "
                    f"{emoji_instruction} "
                    f"Write a push notification for: {notification_type}. "
                    f"Context: {context_str}. "
                    "Be concise (1-2 sentences max for the body). Stay completely in character. "
                    "Reply ONLY in this exact format on two lines:\n"
                    "TITLE: <title — use your coach name>\n"
                    "BODY: <body text>"
                )
            else:
                prompt = (
                    "You are a fitness app notification writer. Write a single push notification "
                    f"for type: {notification_type}. Context: {context_str}. "
                    "Be motivating, concise, and positive. No guilt or shame. No emojis. "
                    "Reply ONLY in this exact format on two lines:\n"
                    "TITLE: <title text>\n"
                    "BODY: <body text>"
                )

            response = client.models.generate_content(
                model=settings.gemini_model,
                contents=prompt,
                config=genai.types.GenerateContentConfig(
                    max_output_tokens=60,
                    temperature=0.9,
                ),
            )

            text = response.text.strip()
            lines = text.split("\n")

            title = None
            body = None
            for line in lines:
                line = line.strip()
                if line.upper().startswith("TITLE:"):
                    title = line[6:].strip()
                elif line.upper().startswith("BODY:"):
                    body = line[5:].strip()

            if title and body:
                logger.info(f"🤖 [Notification] Gemini personalized: {title}")
                return (title, body)

            logger.warning(f"🤖 [Notification] Gemini response unparseable: {text[:100]}")
            return None

        except Exception as e:
            logger.warning(f"🤖 [Notification] Gemini personalization failed: {e}")
            return None

    # ─────────────────────────────────────────────────────────────────
    # Accountability Coach: Unified Send Method
    # ─────────────────────────────────────────────────────────────────

    async def send_accountability_nudge(
        self,
        fcm_token: str,
        nudge_type: str,
        context_dict: Dict[str, Any],
        user_name: Optional[str] = None,
        coach_name: Optional[str] = None,
        coaching_style: Optional[str] = None,
        communication_tone: Optional[str] = None,
        use_emojis: bool = True,
        accountability_intensity: str = "balanced",
        use_ai: bool = True,
    ) -> Tuple[bool, str]:
        """Send an accountability nudge with coach persona awareness.

        Attempts Gemini personalization first (if use_ai=True), then falls back
        to the appropriate template pool based on (nudge_type, intensity).

        Args:
            fcm_token: Device FCM token
            nudge_type: Type of nudge ('morning_workout', 'missed_workout', 'meal_reminder',
                        'post_workout_meal', 'streak_at_risk', 'weekly_checkin',
                        'habit_reminder', or 'guilt_dayN')
            context_dict: Context placeholders (workout_name, streak, days, meal_type, etc.)
            user_name: User's display name
            coach_name: Coach's display name (notification title)
            coaching_style: Coach personality style
            communication_tone: Coach communication tone
            use_emojis: Whether to include emojis
            accountability_intensity: 'gentle', 'balanced', or 'tough_love'
            use_ai: Whether to use Gemini personalization

        Returns:
            Tuple of (success: bool, message: str) — the message text for chat storage.

        Notes:
            - EDGE CASE: If coach_name is None/empty, falls back to "Your Coach"
            - EDGE CASE: If Gemini fails, falls back to template pool
            - EDGE CASE: If template pool not found for nudge_type, uses generic message
            - EDGE CASE: Template placeholders that are missing get safe defaults
        """
        title = coach_name or "Your Coach"
        message_body = ""

        # Step 1: Try Gemini personalization
        if use_ai:
            result = await self._generate_personalized_message(
                notification_type=nudge_type,
                user_name=user_name,
                streak=context_dict.get("streak"),
                workout_name=context_dict.get("workout_name"),
                days_missed=context_dict.get("days"),
                coach_name=coach_name,
                coaching_style=coaching_style,
                communication_tone=communication_tone,
                use_emojis=use_emojis,
                accountability_intensity=accountability_intensity,
            )
            if result:
                title, message_body = result

        # Step 2: Fall back to template pool if Gemini didn't produce a message
        if not message_body:
            # Determine which template pool to use
            template_key = (nudge_type, accountability_intensity)

            # EDGE CASE: Guilt escalation uses tier-based keys (e.g., "guilt_day3" → tier 3)
            if nudge_type.startswith("guilt_day"):
                try:
                    tier = int(nudge_type.replace("guilt_day", ""))
                except ValueError:
                    tier = 14
                template_pool = self.GUILT_ESCALATION_TEMPLATES.get(
                    (tier, accountability_intensity),
                    self.GUILT_ESCALATION_TEMPLATES.get((14, "balanced"), [])
                )
            else:
                template_pool = self.ACCOUNTABILITY_TEMPLATES.get(template_key, [])

            if template_pool:
                import random
                template = random.choice(template_pool)
                # EDGE CASE: Safe formatting with defaults for missing placeholders
                safe_context = {
                    "coach_name": coach_name or "Your Coach",
                    "name": user_name or "there",
                    "workout_name": context_dict.get("workout_name", "your workout"),
                    "streak": context_dict.get("streak", 0),
                    "days": context_dict.get("days", 0),
                    "meal_type": context_dict.get("meal_type", "meal"),
                    "incomplete_count": context_dict.get("incomplete_count", 0),
                    "s": "s" if context_dict.get("incomplete_count", 0) != 1 else "",
                }
                title = template["title"].format(**safe_context)
                message_body = template["body"].format(**safe_context)
            else:
                # EDGE CASE: No template pool found — use generic message
                message_body = f"Hey {user_name or 'there'}, {coach_name or 'your coach'} has a reminder for you!"
                logger.warning(f"⚠️ [Accountability] No template pool for ({nudge_type}, {accountability_intensity})")

        # Step 3: Send the push notification
        data = {
            "nudge_type": nudge_type,
            "accountability": "true",
        }
        # Add chat_message_id if provided in context (set by cron after chat save)
        if context_dict.get("chat_message_id"):
            data["chat_message_id"] = str(context_dict["chat_message_id"])

        success = await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=message_body,
            notification_type=self.TYPE_AI_COACH,
            data=data,
        )

        return (success, message_body)

    async def generate_accountability_message(
        self,
        nudge_type: str,
        context_dict: Dict[str, Any],
        user_name: Optional[str] = None,
        coach_name: Optional[str] = None,
        coaching_style: Optional[str] = None,
        communication_tone: Optional[str] = None,
        use_emojis: bool = True,
        accountability_intensity: str = "balanced",
        use_ai: bool = True,
    ) -> str:
        """Generate an accountability message without sending it.

        Used by push_nudge_cron.py to get the message text for saving to
        chat_messages before sending the push notification.

        Args:
            Same as send_accountability_nudge() minus fcm_token.

        Returns:
            The generated message body string.

        Notes:
            - EDGE CASE: Always returns a non-empty string (falls back to generic)
        """
        message_body = ""

        # Try Gemini personalization
        if use_ai:
            result = await self._generate_personalized_message(
                notification_type=nudge_type,
                user_name=user_name,
                streak=context_dict.get("streak"),
                workout_name=context_dict.get("workout_name"),
                days_missed=context_dict.get("days"),
                coach_name=coach_name,
                coaching_style=coaching_style,
                communication_tone=communication_tone,
                use_emojis=use_emojis,
                accountability_intensity=accountability_intensity,
            )
            if result:
                _, message_body = result

        # Fall back to template pool
        if not message_body:
            template_key = (nudge_type, accountability_intensity)

            if nudge_type.startswith("guilt_day"):
                try:
                    tier = int(nudge_type.replace("guilt_day", ""))
                except ValueError:
                    tier = 14
                template_pool = self.GUILT_ESCALATION_TEMPLATES.get(
                    (tier, accountability_intensity),
                    self.GUILT_ESCALATION_TEMPLATES.get((14, "balanced"), [])
                )
            else:
                template_pool = self.ACCOUNTABILITY_TEMPLATES.get(template_key, [])

            if template_pool:
                import random
                template = random.choice(template_pool)
                safe_context = {
                    "coach_name": coach_name or "Your Coach",
                    "name": user_name or "there",
                    "workout_name": context_dict.get("workout_name", "your workout"),
                    "streak": context_dict.get("streak", 0),
                    "days": context_dict.get("days", 0),
                    "meal_type": context_dict.get("meal_type", "meal"),
                    "incomplete_count": context_dict.get("incomplete_count", 0),
                }
                message_body = template["body"].format(**safe_context)
            else:
                message_body = f"Hey {user_name or 'there'}, {coach_name or 'your coach'} has a reminder for you!"

        return message_body

    async def send_notification(
        self,
        fcm_token: str,
        title: str,
        body: str,
        notification_type: str = TYPE_AI_COACH,
        data: Optional[Dict[str, str]] = None,
        image_url: Optional[str] = None,
    ) -> bool:
        """
        Send a push notification to a single device

        Args:
            fcm_token: The device's FCM token
            title: Notification title
            body: Notification body text
            notification_type: Type of notification for tracking/filtering
            data: Optional additional data payload
            image_url: Optional image URL for rich notifications

        Returns:
            True if sent successfully, False otherwise
        """
        try:
            from firebase_admin import messaging

            # Build the notification
            notification = messaging.Notification(
                title=title,
                body=body,
                image=image_url,
            )

            # Build data payload
            payload = {
                "type": notification_type,
                "timestamp": datetime.utcnow().isoformat(),
            }
            if data:
                payload.update(data)

            # Build Android-specific config with type-specific channel
            channel_id = self._get_channel_id(notification_type)
            android_config = messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#00D9FF",  # Cyan color
                    sound="default",
                    channel_id=channel_id,
                ),
            )

            # Build the message
            message = messaging.Message(
                notification=notification,
                data=payload,
                token=fcm_token,
                android=android_config,
            )

            # Send the message
            response = messaging.send(message)
            logger.info(f"✅ Notification sent: {response}")
            return True

        except messaging.UnregisteredError:
            logger.warning(f"⚠️ FCM token is no longer valid: {fcm_token[:20]}...")
            return False
        except messaging.SenderIdMismatchError:
            logger.error(f"❌ Sender ID mismatch - FCM token belongs to different Firebase project")
            return False
        except messaging.InvalidArgumentError as e:
            logger.error(f"❌ Invalid argument error: {e}")
            return False
        except Exception as e:
            logger.error(f"❌ Failed to send notification: {type(e).__name__}: {e}")
            import traceback
            logger.error(f"Traceback: {traceback.format_exc()}")
            return False

    async def send_multicast(
        self,
        fcm_tokens: List[str],
        title: str,
        body: str,
        notification_type: str = TYPE_AI_COACH,
        data: Optional[Dict[str, str]] = None,
    ) -> Dict[str, Any]:
        """
        Send notifications to multiple devices

        Args:
            fcm_tokens: List of FCM tokens
            title: Notification title
            body: Notification body text
            notification_type: Type of notification
            data: Optional additional data payload

        Returns:
            Dictionary with success_count and failure_count
        """
        try:
            from firebase_admin import messaging

            notification = messaging.Notification(
                title=title,
                body=body,
            )

            payload = {
                "type": notification_type,
                "timestamp": datetime.utcnow().isoformat(),
            }
            if data:
                payload.update(data)

            channel_id = self._get_channel_id(notification_type)
            android_config = messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#00D9FF",
                    sound="default",
                    channel_id=channel_id,
                ),
            )

            message = messaging.MulticastMessage(
                notification=notification,
                data=payload,
                tokens=fcm_tokens,
                android=android_config,
            )

            response = messaging.send_each_for_multicast(message)

            logger.info(
                f"✅ Multicast sent: {response.success_count} success, "
                f"{response.failure_count} failed"
            )

            return {
                "success_count": response.success_count,
                "failure_count": response.failure_count,
            }

        except Exception as e:
            logger.error(f"❌ Failed to send multicast notification: {e}")
            return {"success_count": 0, "failure_count": len(fcm_tokens)}

    # ─────────────────────────────────────────────────────────────────
    # Pre-built notification messages with template pools
    # ─────────────────────────────────────────────────────────────────

    async def send_workout_reminder(
        self,
        fcm_token: str,
        workout_name: str = "today's workout",
        user_name: Optional[str] = None,
        user_timezone: Optional[str] = None,
        use_ai: bool = True,
    ) -> bool:
        """Send a workout reminder notification"""
        # Try Gemini personalization first
        if use_ai and user_name:
            time_of_day = self._get_time_of_day(user_timezone)
            ai_result = await self._generate_personalized_message(
                notification_type="workout_reminder",
                user_name=user_name,
                workout_name=workout_name,
                time_of_day=time_of_day,
            )
            if ai_result:
                title, body = ai_result
                return await self.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type=self.TYPE_WORKOUT_REMINDER,
                    data={"action": "open_workout"},
                )

        # Template pool fallback
        template = random.choice(self.WORKOUT_REMINDER_TEMPLATES)
        name = user_name or "there"
        title = template["title"].format(name=name, workout_name=workout_name)
        body = template["body"].format(name=name, workout_name=workout_name)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_WORKOUT_REMINDER,
            data={"action": "open_workout"},
        )

    async def send_missed_workout_guilt(
        self,
        fcm_token: str,
        days_missed: int = 1,
        user_name: Optional[str] = None,
        user_timezone: Optional[str] = None,
        use_ai: bool = True,
    ) -> bool:
        """Send an inactivity nudge notification (positive, no guilt/shame)"""
        # Try Gemini personalization first
        if use_ai and user_name:
            time_of_day = self._get_time_of_day(user_timezone)
            ai_result = await self._generate_personalized_message(
                notification_type="inactivity_nudge",
                user_name=user_name,
                days_missed=days_missed,
                time_of_day=time_of_day,
            )
            if ai_result:
                title, body = ai_result
                return await self.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type=self.TYPE_AI_COACH,
                    data={"action": "open_home"},
                )

        # Template pool fallback - select tier based on days_missed
        if days_missed == 1:
            template = random.choice(self.INACTIVITY_NUDGE_1DAY)
            title = template["title"]
            body = template["body"]
        elif days_missed == 2:
            template = random.choice(self.INACTIVITY_NUDGE_2DAY)
            title = template["title"]
            body = template["body"]
        else:
            template = random.choice(self.INACTIVITY_NUDGE_3PLUS_DAY)
            title = template["title"].format(days=days_missed)
            body = template["body"].format(days=days_missed)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_AI_COACH,
            data={"action": "open_home"},
        )

    async def send_streak_celebration(
        self,
        fcm_token: str,
        streak_days: int,
        user_name: Optional[str] = None,
        user_timezone: Optional[str] = None,
        use_ai: bool = True,
    ) -> bool:
        """Send a streak celebration notification"""
        # Try Gemini personalization first
        if use_ai and user_name:
            time_of_day = self._get_time_of_day(user_timezone)
            ai_result = await self._generate_personalized_message(
                notification_type="streak_celebration",
                user_name=user_name,
                streak=streak_days,
                time_of_day=time_of_day,
            )
            if ai_result:
                title, body = ai_result
                return await self.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type=self.TYPE_STREAK_ALERT,
                    data={"streak": str(streak_days)},
                )

        # Check for milestone first
        if streak_days in self.STREAK_MILESTONE_TEMPLATES:
            template = self.STREAK_MILESTONE_TEMPLATES[streak_days]
        else:
            template = random.choice(self.STREAK_CELEBRATION_TEMPLATES)

        title = template["title"].format(streak=streak_days)
        body = template["body"].format(streak=streak_days)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_STREAK_ALERT,
            data={"streak": str(streak_days)},
        )

    async def send_nutrition_reminder(
        self,
        fcm_token: str,
        meal_type: str = "meal",
    ) -> bool:
        """Send a nutrition logging reminder"""
        # Select pool based on meal type
        meal_lower = meal_type.lower()
        if meal_lower == "breakfast":
            pool = self.NUTRITION_BREAKFAST_TEMPLATES
        elif meal_lower == "lunch":
            pool = self.NUTRITION_LUNCH_TEMPLATES
        elif meal_lower == "dinner":
            pool = self.NUTRITION_DINNER_TEMPLATES
        else:
            pool = self.NUTRITION_GENERIC_TEMPLATES

        template = random.choice(pool)
        title = template["title"]
        body = template["body"]

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_NUTRITION_REMINDER,
            data={"action": "open_nutrition"},
        )

    async def send_hydration_reminder(
        self,
        fcm_token: str,
        current_ml: int = 0,
        goal_ml: int = 2000,
    ) -> bool:
        """Send a hydration reminder"""
        percent = int((current_ml / goal_ml) * 100) if goal_ml > 0 else 0

        # Select tier based on progress percentage
        if percent < 40:
            pool = self.HYDRATION_LOW_TEMPLATES
        elif percent <= 75:
            pool = self.HYDRATION_MEDIUM_TEMPLATES
        else:
            pool = self.HYDRATION_HIGH_TEMPLATES

        template = random.choice(pool)
        title = template["title"].format(percent=percent)
        body = template["body"].format(percent=percent)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_HYDRATION_REMINDER,
            data={"action": "open_hydration"},
        )

    async def send_weekly_summary_ready(
        self,
        fcm_token: str,
        workouts_completed: int = 0,
        user_name: Optional[str] = None,
        user_timezone: Optional[str] = None,
        use_ai: bool = True,
    ) -> bool:
        """Send notification that weekly summary is ready"""
        # Try Gemini personalization first
        if use_ai and user_name:
            time_of_day = self._get_time_of_day(user_timezone)
            ai_result = await self._generate_personalized_message(
                notification_type="weekly_summary",
                user_name=user_name,
                workouts_completed=workouts_completed,
                time_of_day=time_of_day,
            )
            if ai_result:
                title, body = ai_result
                return await self.send_notification(
                    fcm_token=fcm_token,
                    title=title,
                    body=body,
                    notification_type=self.TYPE_WEEKLY_SUMMARY,
                    data={"action": "open_summaries"},
                )

        # Template pool fallback
        template = random.choice(self.WEEKLY_SUMMARY_TEMPLATES)
        s = "s" if workouts_completed != 1 else ""
        title = template["title"].format(count=workouts_completed, s=s)
        body = template["body"].format(count=workouts_completed, s=s)

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_WEEKLY_SUMMARY,
            data={"action": "open_summaries"},
        )

    async def send_test_notification(
        self,
        fcm_token: str,
    ) -> bool:
        """Send a test notification"""
        title = "Test Notification 🧪"
        body = "Your AI Coach is ready to help you crush your goals! 💪"

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_TEST,
        )

    # ─────────────────────────────────────────────────────────────────
    # Movement Reminder (NEAT) Methods
    # ─────────────────────────────────────────────────────────────────

    async def send_movement_reminder(
        self,
        fcm_token: str,
        current_steps: int = 0,
        threshold: int = 250,
        template_index: Optional[int] = None,
    ) -> bool:
        """
        Send a movement reminder notification to encourage the user to move.

        Args:
            fcm_token: The device's FCM token
            current_steps: Number of steps taken this hour
            threshold: Step threshold for the hour (default 250)
            template_index: Optional index to use specific template, otherwise random

        Returns:
            True if sent successfully, False otherwise
        """
        # Select a template (random or specified)
        if template_index is not None:
            template_idx = template_index % len(self.MOVEMENT_REMINDER_TEMPLATES)
        else:
            template_idx = random.randint(0, len(self.MOVEMENT_REMINDER_TEMPLATES) - 1)

        template = self.MOVEMENT_REMINDER_TEMPLATES[template_idx]

        # Format the message with step data
        title = template["title"]
        body = template["body"].format(steps=current_steps, threshold=threshold)

        logger.info(f"🚶 [Movement] Sending reminder: {title} - {body}")

        return await self.send_notification(
            fcm_token=fcm_token,
            title=title,
            body=body,
            notification_type=self.TYPE_MOVEMENT_REMINDER,
            data={
                "action": "open_home",
                "current_steps": str(current_steps),
                "threshold": str(threshold),
            },
        )

    async def send_movement_reminder_to_user(
        self,
        user_id: str,
        current_steps: int = 0,
        threshold: int = 250,
    ) -> bool:
        """
        Send a movement reminder to a user by their user_id.

        Looks up the FCM token and sends the reminder.

        Args:
            user_id: The user's ID
            current_steps: Steps taken this hour
            threshold: Step threshold

        Returns:
            True if sent successfully, False otherwise
        """
        from core.supabase_db import get_supabase_db

        try:
            db = get_supabase_db()
            user = db.get_user(user_id)

            if not user:
                logger.warning(f"🚶 [Movement] User not found: {user_id}")
                return False

            fcm_token = user.get("fcm_token")
            if not fcm_token:
                logger.warning(f"🚶 [Movement] No FCM token for user: {user_id}")
                return False

            return await self.send_movement_reminder(
                fcm_token=fcm_token,
                current_steps=current_steps,
                threshold=threshold,
            )

        except Exception as e:
            logger.error(f"❌ [Movement] Error sending reminder to user {user_id}: {e}")
            return False

    # ─────────────────────────────────────────────────────────────────
    # Live Chat Support Notification Methods
    # ─────────────────────────────────────────────────────────────────

    async def send_live_chat_message_notification(
        self,
        user_id: str,
        agent_name: str,
        message_preview: str,
        ticket_id: str,
    ) -> bool:
        """
        Send a notification when a support agent sends a new message in live chat.

        Args:
            user_id: The user's ID
            agent_name: Name of the support agent
            message_preview: Preview of the message (truncated)
            ticket_id: The support ticket/chat ID

        Returns:
            True if sent successfully, False otherwise
        """
        from core.supabase_db import get_supabase_db

        try:
            db = get_supabase_db()
            user = db.get_user(user_id)

            if not user:
                logger.warning(f"💬 [LiveChat] User not found: {user_id}")
                return False

            fcm_token = user.get("fcm_token")
            if not fcm_token:
                logger.warning(f"💬 [LiveChat] No FCM token for user: {user_id}")
                return False

            # Truncate message preview if too long
            preview = message_preview[:100] + "..." if len(message_preview) > 100 else message_preview

            title = f"New message from {agent_name}"
            body = preview

            return await self.send_notification(
                fcm_token=fcm_token,
                title=title,
                body=body,
                notification_type=self.TYPE_LIVE_CHAT_MESSAGE,
                data={
                    "action": "open_live_chat",
                    "ticket_id": ticket_id,
                    "agent_name": agent_name,
                },
            )

        except Exception as e:
            logger.error(f"❌ [LiveChat] Error sending message notification to user {user_id}: {e}")
            return False

    async def send_live_chat_connected_notification(
        self,
        user_id: str,
        agent_name: str,
        ticket_id: str,
    ) -> bool:
        """
        Send a notification when a support agent is assigned to the user's chat.

        Args:
            user_id: The user's ID
            agent_name: Name of the support agent
            ticket_id: The support ticket/chat ID

        Returns:
            True if sent successfully, False otherwise
        """
        from core.supabase_db import get_supabase_db

        try:
            db = get_supabase_db()
            user = db.get_user(user_id)

            if not user:
                logger.warning(f"💬 [LiveChat] User not found: {user_id}")
                return False

            fcm_token = user.get("fcm_token")
            if not fcm_token:
                logger.warning(f"💬 [LiveChat] No FCM token for user: {user_id}")
                return False

            title = "Support agent connected!"
            body = f"{agent_name} has joined your chat and is ready to help."

            return await self.send_notification(
                fcm_token=fcm_token,
                title=title,
                body=body,
                notification_type=self.TYPE_LIVE_CHAT_CONNECTED,
                data={
                    "action": "open_live_chat",
                    "ticket_id": ticket_id,
                    "agent_name": agent_name,
                },
            )

        except Exception as e:
            logger.error(f"❌ [LiveChat] Error sending connected notification to user {user_id}: {e}")
            return False

    async def send_live_chat_ended_notification(
        self,
        user_id: str,
        resolution_note: str,
        ticket_id: str,
    ) -> bool:
        """
        Send a notification when a support agent ends the chat session.

        Args:
            user_id: The user's ID
            resolution_note: Note about how the issue was resolved
            ticket_id: The support ticket/chat ID

        Returns:
            True if sent successfully, False otherwise
        """
        from core.supabase_db import get_supabase_db

        try:
            db = get_supabase_db()
            user = db.get_user(user_id)

            if not user:
                logger.warning(f"💬 [LiveChat] User not found: {user_id}")
                return False

            fcm_token = user.get("fcm_token")
            if not fcm_token:
                logger.warning(f"💬 [LiveChat] No FCM token for user: {user_id}")
                return False

            title = "Chat session ended"
            # Truncate resolution note if too long
            note_preview = resolution_note[:100] + "..." if len(resolution_note) > 100 else resolution_note
            body = f"Your support chat has been resolved. {note_preview}"

            return await self.send_notification(
                fcm_token=fcm_token,
                title=title,
                body=body,
                notification_type=self.TYPE_LIVE_CHAT_ENDED,
                data={
                    "action": "open_live_chat",
                    "ticket_id": ticket_id,
                    "chat_ended": "true",
                },
            )

        except Exception as e:
            logger.error(f"❌ [LiveChat] Error sending ended notification to user {user_id}: {e}")
            return False


# Singleton instance
_notification_service: Optional[NotificationService] = None


def get_notification_service() -> NotificationService:
    """Get or create the notification service singleton"""
    global _notification_service
    if _notification_service is None:
        _notification_service = NotificationService()
    return _notification_service
