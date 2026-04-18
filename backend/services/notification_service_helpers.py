"""Helper functions extracted from notification_service.
Push Notification Service using Firebase Admin SDK
Sends push notifications to users via Firebase Cloud Messaging (FCM)


"""
from typing import Any, Dict, Optional, Tuple
from datetime import datetime
import logging
from services.notification_service_helpers_part2 import NotificationServicePart2
logger = logging.getLogger(__name__)
class NotificationService(NotificationServicePart2):
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
    TYPE_DAILY_BUNDLE = "daily_bundle"
    TYPE_DAILY_CRATE = "daily_crate"

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
        TYPE_DAILY_BUNDLE: "daily_bundle",
        TYPE_DAILY_CRATE: "daily_crate",
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

    # Tier 4: 5 days missed - stronger emotional appeal
    INACTIVITY_NUDGE_5DAY = [
        {"title": "Your dumbbells are ready for you!", "body": "5 days, {name}. Your equipment is right where you left it. One session flips the momentum."},
        {"title": "5 days off...", "body": "Your workout plan is still here, waiting like a loyal friend. Just one session?"},
        {"title": "Remember your goals?", "body": "5 days off. That fire is still in you. Light it up with one session, {name}."},
        {"title": "We're still here!", "body": "5 days is just a pause, not a stop. Come crush one workout!"},
    ]

    # Tier 5: 7 days missed - warm welcome-back
    INACTIVITY_NUDGE_7DAY = [
        {"title": "A whole week!", "body": "We kept your plan warm for you, {name}. Remember why you started. One rep is all it takes."},
        {"title": "7 days...", "body": "Your workout hasn't given up on you. Don't give up on it."},
        {"title": "Miss the grind?", "body": "It's been a week. Even champions take breaks. But now? It's time, {name}."},
        {"title": "Your comeback starts now!", "body": "7 days off means you're fully rested. Let's use that energy!"},
    ]

    # Tier 6: 14+ days missed - no judgment, gentle pull
    INACTIVITY_NUDGE_14PLUS_DAY = [
        {"title": "We haven't given up on you!", "body": "It's been {days} days, but your plan is still here. One small step back, {name}."},
        {"title": "Still in your corner!", "body": "{days} days away? That's OK. One rep. One walk. Just start."},
        {"title": "Remember day 1?", "body": "You started for a reason {days} days ago. That reason hasn't changed, {name}."},
        {"title": "It's time.", "body": "It's been {days} days. No judgment — just open the app and let's talk."},
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
            {"title": "{coach_name}", "body": "Still time today, {name}. Even 20 minutes of {workout_name} flips the day."},
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

        # ─── Smart App-Open Hook Templates ──────────────────────────────

        # --- Streak Countdown Urgency ---
        ("streak_countdown", "gentle"): [
            {"title": "{coach_name}", "body": "Hey {name}, your {streak}-day streak expires tonight. Even a quick session saves it!"},
            {"title": "{coach_name}", "body": "{name}, just a heads up — your {streak}-day streak is at risk tonight. A short workout keeps it alive."},
            {"title": "{coach_name}", "body": "Your {streak}-day streak is counting on you tonight. No pressure — just 10 minutes!"},
            {"title": "{coach_name}", "body": "Friendly reminder: your {streak}-day streak ends tonight without a workout. You've got this!"},
        ],
        ("streak_countdown", "balanced"): [
            {"title": "{coach_name}", "body": "2 hours left! Your {streak}-day streak expires tonight, {name}. Even 10 min saves it!"},
            {"title": "{coach_name}", "body": "{name}, your {streak}-day streak is on life support! Quick workout to save it?"},
            {"title": "{coach_name}", "body": "Clock's ticking! {streak} days on the line tonight. One session keeps it alive, {name}!"},
            {"title": "{coach_name}", "body": "Don't let {streak} days go to waste! A quick workout tonight saves your streak."},
        ],
        ("streak_countdown", "tough_love"): [
            {"title": "{coach_name}", "body": "{streak} days on the line tonight, {name}. You've built too much to let it slip."},
            {"title": "{coach_name}", "body": "Streak's on the line tonight, {name}. 10 minutes keeps {streak} days alive."},
            {"title": "{coach_name}", "body": "{name}! {streak} days of work — let's protect it. One set counts."},
            {"title": "{coach_name}", "body": "Streak Shield or a quick session — either way, your {streak}-day streak survives tonight."},
        ],

        # --- Progress Milestone Teaser ---
        ("progress_milestone", "gentle"): [
            {"title": "{coach_name}", "body": "You're so close! One more workout hits {milestone} total, {name}. That's amazing."},
            {"title": "{coach_name}", "body": "{name}, you're 1 workout away from {milestone} total. What a milestone!"},
            {"title": "{coach_name}", "body": "Just 1 more session to reach {milestone} workouts, {name}. You're almost there!"},
            {"title": "{coach_name}", "body": "Milestone incoming! {current_count} workouts done, {milestone} is next. Go for it!"},
        ],
        ("progress_milestone", "balanced"): [
            {"title": "{coach_name}", "body": "One more workout and you hit {milestone} total, {name}! History in the making!"},
            {"title": "{coach_name}", "body": "{name}, you're 1 session from {milestone} lifetime workouts! Let's make it happen!"},
            {"title": "{coach_name}", "body": "{milestone} workouts is RIGHT THERE! One session today and you've done it, {name}!"},
            {"title": "{coach_name}", "body": "SO CLOSE! {current_count} done, {milestone} is next. Today's the day, {name}!"},
        ],
        ("progress_milestone", "tough_love"): [
            {"title": "{coach_name}", "body": "ONE workout from {milestone}! Don't you DARE stop now, {name}!"},
            {"title": "{coach_name}", "body": "{milestone} is RIGHT THERE. One session. No excuses. EARN IT!"},
            {"title": "{coach_name}", "body": "{name}! {current_count} down, 1 to go for {milestone}. FINISH what you started!"},
            {"title": "{coach_name}", "body": "You're 1 rep away from {milestone} workouts. GET IN THERE!"},
        ],

        # --- Post-Workout Nutrition ---
        ("post_workout_nutrition", "gentle"): [
            {"title": "{coach_name}", "body": "Great workout, {name}! Your body needs fuel. Log your post-workout meal when you can."},
            {"title": "{coach_name}", "body": "Nice session! A meal within 30-60 min helps recovery. Log it when ready!"},
            {"title": "{coach_name}", "body": "{name}, your muscles are hungry after {workout_name}! Log your post-workout meal."},
            {"title": "{coach_name}", "body": "Awesome work on {workout_name}! Don't forget to refuel and log your meal."},
        ],
        ("post_workout_nutrition", "balanced"): [
            {"title": "{coach_name}", "body": "Refuel window open! Log your post-workout meal within 30 min for best recovery, {name}!"},
            {"title": "{coach_name}", "body": "{name}, {workout_name} crushed! Now feed those muscles — log your meal!"},
            {"title": "{coach_name}", "body": "Your muscles are hungry after {workout_name}! Post-workout nutrition is key. Log it!"},
            {"title": "{coach_name}", "body": "Great {workout_name}! Protein within 60 min = faster recovery. Log your meal now!"},
        ],
        ("post_workout_nutrition", "tough_love"): [
            {"title": "{coach_name}", "body": "You just CRUSHED {workout_name}! Don't waste it — EAT and LOG it NOW, {name}!"},
            {"title": "{coach_name}", "body": "Your workout means NOTHING without nutrition! Log that post-workout meal!"},
            {"title": "{coach_name}", "body": "{name}! Muscles don't grow on air. Eat. Log. Recover. NOW!"},
            {"title": "{coach_name}", "body": "30-min anabolic window is TICKING! Log your post-workout meal, {name}!"},
        ],

        # --- Coach Insight (curiosity trigger) ---
        ("coach_insight", "gentle"): [
            {"title": "{coach_name}", "body": "I noticed something in your recent workouts, {name}. Tap when you have a moment!"},
            {"title": "{coach_name}", "body": "{name}, I have an observation about your progress. Check it out when you can."},
            {"title": "{coach_name}", "body": "Something caught my eye in your training data. Want to hear about it?"},
            {"title": "{coach_name}", "body": "I've been looking at your patterns, {name}. I have a tip for you!"},
        ],
        ("coach_insight", "balanced"): [
            {"title": "{coach_name}", "body": "I analyzed your recent workouts and found something interesting, {name}! Tap to see."},
            {"title": "{coach_name}", "body": "{name}, I've got a personalized insight from your training data. Check it out!"},
            {"title": "{coach_name}", "body": "Your data tells a story! I noticed a trend in your workouts. Tap to learn more."},
            {"title": "{coach_name}", "body": "Coach's eye: I spotted something in your progress, {name}. Worth a look!"},
        ],
        ("coach_insight", "tough_love"): [
            {"title": "{coach_name}", "body": "I found something in your data, {name}. You NEED to see this. Tap now!"},
            {"title": "{coach_name}", "body": "{name}! Your training data revealed something critical. Open the app!"},
            {"title": "{coach_name}", "body": "I've been watching your numbers. There's something you should know. TAP."},
            {"title": "{coach_name}", "body": "Important insight about your training, {name}. Don't ignore this one!"},
        ],

        # --- Habit Streak Reward ---
        ("habit_streak_reward", "gentle"): [
            {"title": "{coach_name}", "body": "Amazing, {name}! {consecutive_days} days of meal logging in a row. Tap to see your insights!"},
            {"title": "{coach_name}", "body": "You've logged meals {consecutive_days} days straight! That's real consistency."},
            {"title": "{coach_name}", "body": "{consecutive_days}-day logging streak, {name}! Your nutrition data is getting valuable."},
            {"title": "{coach_name}", "body": "Wow — {consecutive_days} consecutive days of tracking! You're building a great habit."},
        ],
        ("habit_streak_reward", "balanced"): [
            {"title": "{coach_name}", "body": "{consecutive_days}-day meal logging streak! You're on fire, {name}! Tap for insights!"},
            {"title": "{coach_name}", "body": "{name}, {consecutive_days} days of food tracking! Achievement unlocked! See your stats!"},
            {"title": "{coach_name}", "body": "STREAK ALERT: {consecutive_days} days of logging! Your nutrition game is STRONG!"},
            {"title": "{coach_name}", "body": "{consecutive_days} days straight! Your consistency is paying off, {name}. Check your progress!"},
        ],
        ("habit_streak_reward", "tough_love"): [
            {"title": "{coach_name}", "body": "{consecutive_days} DAYS of tracking! That's DISCIPLINE, {name}! See your reward!"},
            {"title": "{coach_name}", "body": "{name}! {consecutive_days}-day logging streak! THIS is what commitment looks like!"},
            {"title": "{coach_name}", "body": "{consecutive_days} consecutive days! You're in ELITE company now. Keep it going!"},
            {"title": "{coach_name}", "body": "RESPECT! {consecutive_days} days of meal tracking. You're not messing around!"},
        ],

        # --- Rest Day Tip ---
        ("rest_day_tip", "gentle"): [
            {"title": "{coach_name}", "body": "Rest day! I have a recovery tip that'll help tomorrow's workout, {name}."},
            {"title": "{coach_name}", "body": "No workout today, but I've got something helpful for you. Tap when you can!"},
            {"title": "{coach_name}", "body": "{name}, even rest days matter. I've got a tip to boost your recovery."},
            {"title": "{coach_name}", "body": "Taking it easy today? Great! Here's a rest day pro tip for you."},
        ],
        ("rest_day_tip", "balanced"): [
            {"title": "{coach_name}", "body": "Rest day, {name}! Got a recovery tip that'll boost tomorrow's performance. Tap!"},
            {"title": "{coach_name}", "body": "No workout today, but don't disappear! I've got a tip for you, {name}."},
            {"title": "{coach_name}", "body": "{name}, rest days are growth days! I have an insight to share. Check it out!"},
            {"title": "{coach_name}", "body": "Rest day tip incoming! Your recovery matters as much as your training."},
        ],
        ("rest_day_tip", "tough_love"): [
            {"title": "{coach_name}", "body": "Rest day doesn't mean LAZY day! I've got a recovery mission for you, {name}!"},
            {"title": "{coach_name}", "body": "{name}! Rest days are for ACTIVE recovery. Open the app for your tip!"},
            {"title": "{coach_name}", "body": "The work doesn't stop on rest days! Check in for a recovery briefing."},
            {"title": "{coach_name}", "body": "Champions recover STRATEGICALLY. I have a rest day tip for you. TAP!"},
        ],

        # --- Progress Comparison (monthly) ---
        ("progress_comparison", "balanced"): [
            {"title": "{coach_name}", "body": "Month in review! Last month: {last_month} workouts. This month: {this_month}. Tap to see the full picture, {name}!"},
            {"title": "{coach_name}", "body": "{name}, your monthly stats are in! {this_month} vs {last_month} workouts. How do you compare?"},
            {"title": "{coach_name}", "body": "New month, new data! You did {this_month} workouts vs {last_month} last month. Check your progress!"},
            {"title": "{coach_name}", "body": "Monthly progress report ready! {this_month} workouts this month vs {last_month} last month. Tap to review!"},
        ],

        # --- Time Capsule ---
        ("time_capsule", "balanced"): [
            {"title": "{coach_name}", "body": "It's been {days_active} days since you started, {name}! Tap to see how far you've come."},
            {"title": "{coach_name}", "body": "{days_active} days ago you began your journey. Look at you now! Tap for your before & after."},
            {"title": "{coach_name}", "body": "Day {days_active} milestone! {name}, your transformation story is being written. See your progress!"},
            {"title": "{coach_name}", "body": "{days_active} days of dedication! Remember where you started? Tap to compare!"},
        ],

        # --- Chain Visual ---
        ("chain_visual", "balanced"): [
            {"title": "{coach_name}", "body": "{streak} green days in a row, {name}! Don't let today turn red. A quick workout keeps the chain alive."},
            {"title": "{coach_name}", "body": "Your activity grid is looking clean — {streak} days! Keep it green today, {name}!"},
            {"title": "{coach_name}", "body": "{streak}-day chain is beautiful! One workout keeps it unbroken. Don't stop now, {name}!"},
            {"title": "{coach_name}", "body": "Look at that streak: {streak} days! Today decides if it stays green or turns red."},
        ],

        # --- Recovery Complete ---
        ("recovery_complete", "balanced"): [
            {"title": "{coach_name}", "body": "Your {muscle_group} is fully recovered and primed for growth, {name}! Perfect day to train."},
            {"title": "{coach_name}", "body": "{muscle_group} recovery complete! {hours_recovered}h of rest means you're ready to push harder."},
            {"title": "{coach_name}", "body": "{name}, your {muscle_group} has had {hours_recovered}h to recover. It's ready for today's workout!"},
            {"title": "{coach_name}", "body": "Science says your {muscle_group} is primed! {hours_recovered}h recovery = peak performance window."},
        ],

        # --- Day-3 Activation (push parity for the email) ---
        ("day3_activation", "gentle"): [
            {"title": "{coach_name}", "body": "Hey {name}, your plan is ready when you are. About 20 minutes for the first one."},
            {"title": "{coach_name}", "body": "{name}, no rush — your first workout is sitting on the home screen whenever you want it."},
        ],
        ("day3_activation", "balanced"): [
            {"title": "{coach_name}", "body": "{name}, your plan's been waiting. 20 minutes to start your first workout."},
            {"title": "{coach_name}", "body": "Your first workout is built and waiting, {name}. Today's the day."},
        ],
        ("day3_activation", "tough_love"): [
            {"title": "{coach_name}", "body": "{name}! Your plan has been sitting untouched. 20 minutes. Now."},
            {"title": "{coach_name}", "body": "Day 3 and zero workouts, {name}. Your plan didn't build itself for nothing."},
        ],

        # --- Onboarding Incomplete ---
        ("onboarding_incomplete", "gentle"): [
            {"title": "{coach_name}", "body": "{name}, just 2 more answers and your plan is ready. Two minutes."},
            {"title": "{coach_name}", "body": "Hey {name} — your plan can't be built until you finish setup. Quick wrap-up?"},
        ],
        ("onboarding_incomplete", "balanced"): [
            {"title": "{coach_name}", "body": "{name}, 2 answers left. Two minutes. Then your plan generates instantly."},
            {"title": "{coach_name}", "body": "Almost there, {name}. Finish setup and your full plan builds in seconds."},
        ],
        ("onboarding_incomplete", "tough_love"): [
            {"title": "{coach_name}", "body": "{name}, your plan is 2 minutes away from ready. Let's finish setting it up."},
        ],

        # --- Weekly Recap ---
        ("weekly_recap", "gentle"): [
            {"title": "{coach_name}", "body": "{name}, your week in numbers — tap to see how you did."},
            {"title": "{coach_name}", "body": "Sunday review time, {name}. Quick look at your week?"},
        ],
        ("weekly_recap", "balanced"): [
            {"title": "{coach_name}", "body": "{name}, your week is in. Numbers don't lie — let's see them."},
            {"title": "{coach_name}", "body": "Weekly recap dropped, {name}. Open to see what you pulled off."},
        ],
        ("weekly_recap", "tough_love"): [
            {"title": "{coach_name}", "body": "{name}, your week is graded. Open it. Be honest."},
        ],

        # --- Achievement Unlocked (real-time) ---
        ("achievement_unlocked", "gentle"): [
            {"title": "🏆 {achievement_name}", "body": "Earned, {name}. {coach_name} saw that."},
        ],
        ("achievement_unlocked", "balanced"): [
            {"title": "🏆 {achievement_name}", "body": "{name}, you earned that. {coach_name} is taking notes."},
        ],
        ("achievement_unlocked", "tough_love"): [
            {"title": "🏆 {achievement_name}", "body": "{name}, you earned that. Don't get comfortable — there's more."},
        ],

        # --- Comeback (returned after ≥7d gap) ---
        ("comeback", "gentle"): [
            {"title": "{coach_name}", "body": "{name}, welcome back. {coach_name} kept your plan."},
            {"title": "{coach_name}", "body": "Glad to see you, {name}. Plan's queued and adjusted for the time off."},
        ],
        ("comeback", "balanced"): [
            {"title": "{coach_name}", "body": "Welcome back, {name}. {coach_name} missed you."},
            {"title": "{coach_name}", "body": "{name}, you came back. That's the hardest part. {coach_name} is ready."},
        ],
        ("comeback", "tough_love"): [
            {"title": "{coach_name}", "body": "{name}. Don't disappear again. {coach_name} is watching."},
        ],

        # ─── Merch Milestone Nudges (migration 1931) ──────────────────
        # Placeholders: {coach_name}, {name}, {merch_name}, {levels_away}, {next_level}
        #
        # merch_proximity: user is 1-3 levels away from a merch tier
        ("merch_proximity", "gentle"): [
            {"title": "{coach_name}", "body": "{name}, you're {levels_away} levels from a FREE {merch_name}. You've got this!"},
            {"title": "{coach_name}", "body": "So close to Level {next_level} — {merch_name} is almost yours, {name}."},
            {"title": "{coach_name}", "body": "Hey {name}, only {levels_away} levels until your FREE {merch_name} ships to you."},
        ],
        ("merch_proximity", "balanced"): [
            {"title": "🎁 {coach_name}", "body": "{levels_away} levels away from a FREE {merch_name}! Keep earning XP, {name}."},
            {"title": "🎁 {coach_name}", "body": "{name}! Level {next_level} = FREE {merch_name} shipped to you. Go get it!"},
            {"title": "🎁 {coach_name}", "body": "You're THIS close — {levels_away} levels and your {merch_name} is in the mail!"},
        ],
        ("merch_proximity", "tough_love"): [
            {"title": "🎁 {coach_name}", "body": "{levels_away} levels between you and a FREE {merch_name}. DON'T quit now, {name}."},
            {"title": "🎁 {coach_name}", "body": "Level {next_level} = real swag. You gonna earn it or not, {name}?"},
            {"title": "🎁 {coach_name}", "body": "FREE {merch_name} is {levels_away} levels away. Stop scrolling, start earning."},
        ],

        # merch_unlocked: user just leveled up to a merch tier (L50/100/150/200/250)
        ("merch_unlocked", "gentle"): [
            {"title": "🎁 {coach_name}", "body": "Congrats {name}! You unlocked a FREE {merch_name}. Tap to accept and we'll reach out."},
            {"title": "🎁 {coach_name}", "body": "{name}, you earned real merch! Your {merch_name} is waiting in the Rewards tab."},
        ],
        ("merch_unlocked", "balanced"): [
            {"title": "🎁 FREE {merch_name}!", "body": "{name}, Level {next_level} means REAL swag. Tap to accept your {merch_name}!"},
            {"title": "🎁 {coach_name}", "body": "You did it! {merch_name} UNLOCKED. Accept it in the Rewards tab."},
        ],
        ("merch_unlocked", "tough_love"): [
            {"title": "🎁 {coach_name}", "body": "{name}. You earned it. {merch_name} UNLOCKED. Go claim it."},
        ],

        # merch_claim_reminder: claim pending_address for D+1/D+3/D+7
        ("merch_claim_reminder", "gentle"): [
            {"title": "🎁 {coach_name}", "body": "Friendly reminder, {name} — your FREE {merch_name} is waiting to be accepted."},
            {"title": "🎁 {coach_name}", "body": "Don't forget: your {merch_name} is unclaimed. One tap to accept!"},
        ],
        ("merch_claim_reminder", "balanced"): [
            {"title": "🎁 {merch_name}", "body": "Your FREE {merch_name} is still waiting! Tap Accept and we'll email you."},
            {"title": "🎁 {coach_name}", "body": "{name}! Your {merch_name} is sitting unclaimed. Tap to accept it now."},
        ],
        ("merch_claim_reminder", "tough_love"): [
            {"title": "🎁 {coach_name}", "body": "{name}. FREE {merch_name}. Unclaimed. WHY? Tap Accept."},
        ],

        # ─── Week-1 Retention Nudge Ladder (W4) ──────────────────────
        # Fires on Day 1, 3 (completed/stalled variants), 5, 7 for new users.
        # Placeholders: {coach_name}, {name}, {days_in}, {count} (workouts so far)
        # Tone: compassionate — never tough_love regardless of user pref
        # (enforced by account-age cap in push_nudge_cron.py).
        ("week1_day1", "gentle"): [
            {"title": "{coach_name}", "body": "{name}, {coach_name} here. Day 1 of your plan is ready — about 20 minutes when you've got a window."},
            {"title": "{coach_name}", "body": "Welcome aboard, {name}! Your first workout is loaded. Take your time."},
        ],
        ("week1_day1", "balanced"): [
            {"title": "{coach_name}", "body": "{name}, {coach_name} here. Day 1 of your plan is ready — 20 minutes. When you show up today, the pattern starts."},
            {"title": "{coach_name}", "body": "Day 1, {name}. Your plan is warm. Even 10 minutes breaks the ice."},
            {"title": "{coach_name}", "body": "{name}, today's the easy day to start. 20 min to first win."},
        ],
        ("week1_day1", "tough_love"): [
            {"title": "{coach_name}", "body": "Day 1, {name}. {coach_name}'s ready. The plan's ready. Your turn."},
        ],

        ("week1_day3_completed", "gentle"): [
            {"title": "{coach_name}", "body": "Three days in, {name}. You're doing this. {coach_name} is proud."},
            {"title": "{coach_name}", "body": "Day 3 and you're still here, {name} — that's the hardest part."},
        ],
        ("week1_day3_completed", "balanced"): [
            {"title": "🔥 {coach_name}", "body": "Three days in, {name}. Most people who make it past Day 3 are still here in month 3. You're building something."},
            {"title": "{coach_name}", "body": "Day 3 check-in, {name}. {count} workout{s} logged — keep the thread going."},
        ],
        ("week1_day3_completed", "tough_love"): [
            {"title": "{coach_name}", "body": "Day 3 done, {name}. Don't stop now — compound time starts at week 2."},
        ],

        ("week1_day3_stalled", "gentle"): [
            {"title": "{coach_name}", "body": "Day 3, {name}. No judgment — life happens. Want to try 10 minutes? That's all it takes to break the ice."},
            {"title": "{coach_name}", "body": "Checking in, {name}. Your plan is still waiting — a tiny workout beats none."},
        ],
        ("week1_day3_stalled", "balanced"): [
            {"title": "{coach_name}", "body": "Day 3, {name}. No judgment — life happens. 10 minutes is all you need today."},
            {"title": "{coach_name}", "body": "{name}, day 3 and you haven't started yet. {coach_name} has a 15-minute starter version if that helps."},
        ],
        ("week1_day3_stalled", "tough_love"): [
            {"title": "{coach_name}", "body": "Day 3, {name}. No workout yet. Gentle push: open the app, pick the shortest session, hit start."},
        ],

        ("week1_day5", "gentle"): [
            {"title": "{coach_name}", "body": "Halfway through week one, {name}. How are you feeling? {coach_name} is here."},
            {"title": "{coach_name}", "body": "Day 5, {name}. Small wins stack up. You've got this."},
        ],
        ("week1_day5", "balanced"): [
            {"title": "{coach_name}", "body": "Halfway through week one, {name}. {count} workout{s} in — here's your 30-day forecast when you open the app."},
            {"title": "{coach_name}", "body": "Day 5, {name}. Your body's starting to learn the pattern. Keep going."},
        ],
        ("week1_day5", "tough_love"): [
            {"title": "{coach_name}", "body": "Halfway, {name}. The pattern you build this week you'll still have in month 6."},
        ],

        ("week1_day7", "gentle"): [
            {"title": "🎉 {coach_name}", "body": "One full week, {name}. That's a milestone. Open the app to see your recap."},
            {"title": "{coach_name}", "body": "{name}, week 1 done. {coach_name} is proud. Here's what you built."},
        ],
        ("week1_day7", "balanced"): [
            {"title": "🎉 {coach_name}", "body": "One full week, {name}. You've earned it. Here's your week in review."},
            {"title": "🏅 {coach_name}", "body": "{name}! 7 days in. 80% of users who make it to day 7 stick with it long term — you're in."},
        ],
        ("week1_day7", "tough_love"): [
            {"title": "🎉 {coach_name}", "body": "{name}, week 1 complete. Don't celebrate too long — week 2 builds on week 1."},
        ],

        # ─── Streak Saved (migration 1938 / W3) ───────────────────────
        # Fires when auto-consumed streak_shield saved the user's streak.
        # Placeholders: {coach_name}, {name}, {streak} (saved length), {shields} (remaining count)
        ("streak_saved", "gentle"): [
            {"title": "🛡️ Streak saved!", "body": "{name}, we used a Streak Shield — your {streak}-day streak is safe. {shields} shields left."},
            {"title": "🛡️ {coach_name}", "body": "No worries, {name}. A Streak Shield kept your {streak}-day streak alive."},
        ],
        ("streak_saved", "balanced"): [
            {"title": "🛡️ Streak saved!", "body": "{name}, a Streak Shield just saved your {streak}-day streak. Let's keep it going!"},
            {"title": "🛡️ {coach_name}", "body": "Shield used. {streak}-day streak: still alive. Come back strong today, {name}."},
        ],
        ("streak_saved", "tough_love"): [
            {"title": "🛡️ {coach_name}", "body": "{name}, shield used. {streak}-day streak stays. Don't rely on them — show up tomorrow."},
        ],

        # ─── Streak at Risk (Safe Variant) ─── for users who HAVE shields.
        # Gentler tone because loss aversion is already handled by shield reserve.
        ("streak_at_risk_safe", "gentle"): [
            {"title": "🛡️ {coach_name}", "body": "Didn't train today, {name}? You've got shields — streak's safe tonight either way."},
        ],
        ("streak_at_risk_safe", "balanced"): [
            {"title": "🛡️ {coach_name}", "body": "{name}, your {streak}-day streak is covered by shields tonight. Still — 20 minutes today keeps the flame lit."},
        ],
        ("streak_at_risk_safe", "tough_love"): [
            {"title": "🛡️ {coach_name}", "body": "{streak} days, {name}. Shields in the tank — but use 'em as a backup, not a plan. Train today."},
        ],

        # ─── Level Milestone Celebration (migration 1936) ─────────────
        # Placeholders: {coach_name}, {name}, {level}, {rewards_summary}
        # Fires when user hits any major XP milestone (L5/10/25/50/75/100/...).
        ("level_milestone_celebration", "gentle"): [
            {"title": "🏅 Level {level}", "body": "Congrats, {name}! You hit Level {level}. Your rewards are in your inventory."},
            {"title": "🏅 {coach_name}", "body": "Level {level} unlocked. {rewards_summary}"},
            {"title": "🏅 {coach_name}", "body": "{name}, proud of you — Level {level} reached. Check your inventory."},
        ],
        ("level_milestone_celebration", "balanced"): [
            {"title": "🏅 LEVEL {level}!", "body": "{name}, you did it. {rewards_summary} Tap to open your rewards."},
            {"title": "🏅 {coach_name}", "body": "LEVEL {level} UNLOCKED! {rewards_summary}"},
            {"title": "🏅 Level {level} · {coach_name}", "body": "{name}, real work = real rewards. {rewards_summary}"},
        ],
        ("level_milestone_celebration", "tough_love"): [
            {"title": "🏅 {coach_name}", "body": "{name}. Level {level}. Don't celebrate too long. Back to work."},
            {"title": "🏅 LEVEL {level}", "body": "{name}, you earned it. Now earn the next one."},
        ],
    }

    # ─────────────────────────────────────────────────────────────────
    # 3. Comeback Nudge Templates (formerly GUILT_ESCALATION — renamed for tone)
    # ─────────────────────────────────────────────────────────────────
    # Keyed by (days_tier, intensity). Tiers: 1, 2, 3, 5, 7, 14 days inactive.
    # Placeholders: {coach_name}, {name}, {days}
    # Research (Fitness behavior change meta-analysis): shame/guilt undermines
    # motivation. Tough_love tier preserved for users who opt into it, but the
    # harshest strings rewritten to be "hype" not "shame" — calling you forward,
    # not calling you out. New-user intensity is auto-capped to balanced for
    # accounts < 14 days old (see _send_nudge in push_nudge_cron).

    COMEBACK_NUDGE_TEMPLATES = {
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
            {"title": "{coach_name}", "body": "3 days, {name}. Enough recovery — your body's ready. Gear up."},
            {"title": "{coach_name}", "body": "3 days off. {coach_name}'s got a plan that matches your energy today. Let's go."},
            {"title": "{coach_name}", "body": "Day 3. {name}, you've got a comeback in you. Today's the day."},
            {"title": "{coach_name}", "body": "3 days of rest banked. Time to cash it in — 20 minutes, that's it."},
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
            {"title": "{coach_name}", "body": "5 days off — your body's rested, {name}. Let's use that energy."},
            {"title": "{coach_name}", "body": "5 days. {coach_name} knows you've got a comeback in you."},
            {"title": "{coach_name}", "body": "Day 5. The best time to train was 5 days ago. The next-best time is right now, {name}."},
            {"title": "{coach_name}", "body": "5 days in the tank. {name}, one session and you're back."},
        ],

        # --- 7 Days Inactive ---
        (7, "gentle"): [
            {"title": "{coach_name}", "body": "{coach_name} misses you, {name}. Your weights are ready whenever you are."},
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
            {"title": "{coach_name}", "body": "A week off, {name}. {coach_name} has been waiting — ready when you are."},
            {"title": "{coach_name}", "body": "7 days. That's long enough to reset. Now let's rebuild, {name}."},
            {"title": "{coach_name}", "body": "A full week. {coach_name}'s got a fresh plan designed for day 1 back. No ramp-up needed."},
            {"title": "{coach_name}", "body": "7 days clean. {name}, come make today the comeback day."},
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
            {"title": "{coach_name}", "body": "{days} days. {coach_name} hasn't given up on you. Today is a clean slate, {name}."},
            {"title": "{coach_name}", "body": "{days} days in, {name}. This is your moment — {coach_name}'s ready to rebuild with you."},
            {"title": "{coach_name}", "body": "{days} days. Your comeback story starts the second you open this app again."},
            {"title": "{coach_name}", "body": "{days} days, {name}. One small win today — that's all it takes to restart."},
        ],
    }

    # Default channel
    DEFAULT_CHANNEL_ID = "fitwiz_notifications"

    def __init__(self):
        """Initialize the notification service"""
        from services.notification_service import initialize_firebase
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
            from core.config import get_settings
            from services.gemini.constants import gemini_generate_with_retry_sync

            settings = get_settings()

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

            response = gemini_generate_with_retry_sync(
                model=settings.gemini_model,
                contents=prompt,
                config=genai.types.GenerateContentConfig(
                    max_output_tokens=60,
                    temperature=0.9,
                ),
                method_name="push_notification",
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
            logger.warning(f"🤖 [Notification] Gemini personalization failed: {e}", exc_info=True)
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
                template_pool = self.COMEBACK_NUDGE_TEMPLATES.get(
                    (tier, accountability_intensity),
                    self.COMEBACK_NUDGE_TEMPLATES.get((14, "balanced"), [])
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
                    # merch + level-milestone placeholders
                    "merch_name": context_dict.get("merch_name", "reward"),
                    "next_level": context_dict.get("next_level", 0),
                    "levels_away": context_dict.get("levels_away", 0),
                    "level": context_dict.get("level", 0),
                    "rewards_summary": context_dict.get("rewards_summary", ""),
                    # streak_saved / streak_at_risk_safe placeholders (W3)
                    "shields": context_dict.get("shields", 0),
                    # Week-1 nudge placeholders (W4)
                    "count": context_dict.get("count", 0),
                    "days_in": context_dict.get("days_in", 0),
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



# Singleton instance
_notificationservice_instance: Optional[NotificationService] = None


def get_notification_service() -> NotificationService:
    """Get or create the singleton NotificationService instance."""
    global _notificationservice_instance
    if _notificationservice_instance is None:
        _notificationservice_instance = NotificationService()
    return _notificationservice_instance
