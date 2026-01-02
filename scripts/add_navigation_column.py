#!/usr/bin/env python3
"""
Script to add Navigation column to all feature tables in FEATURES.md
"""

import re
import sys

# Navigation path mappings based on codebase exploration
NAVIGATION_PATHS = {
    # Authentication & Onboarding (Section 1)
    "Google Sign-In": "App Launch → Sign In → Google Sign-In",
    "Apple Sign-In": "App Launch → Sign In → Apple Sign-In",
    "Language Selection": "Settings → Language",
    "6-Step Onboarding": "First Launch → Onboarding Flow",
    "Pre-Auth Quiz": "App Launch → Get Started → Quiz",
    "Mode Selection": "Onboarding → Age Check → Mode Selection",
    "Timezone Auto-Detect": "Automatic on app start",
    "User Profile Creation": "Onboarding → Profile Setup",
    "Animated Stats Carousel": "Welcome Screen → Stats Display",
    "Auto-Scrolling Carousel": "Welcome Screen → Auto-scroll",
    "Step Progress Indicators": "Onboarding → Progress Bar",
    "Exit Confirmation": "Onboarding → Back/Exit → Confirmation",
    "Coach Selection Screen": "Onboarding → Coach Selection",
    "Custom Coach Creator": "Onboarding → Coach Selection → Create Custom",
    "Coach Personas": "Onboarding → Coach Selection → Persona Cards",
    "Coaching Styles": "Onboarding → Coach Selection → Style Selection",
    "Personality Traits": "Onboarding → Coach Selection → Traits Selection",
    "Communication Tones": "Onboarding → Coach Selection → Tone Selection",
    "Paywall Features Screen": "Post-Onboarding → Paywall Features",
    "Paywall Pricing Screen": "Paywall Features → Pricing",
    "Personalized Preview": "Quiz Complete → Plan Preview",
    "Onboarding Flow Tracking": "Backend tracking",
    "Conversational AI Onboarding": "Onboarding → AI Chat Flow",
    "Quick Reply Detection": "Onboarding → Chat → Quick Replies",
    "Language Provider System": "Backend system",
    "Senior Onboarding Mode": "Onboarding → Senior Mode",
    "Equipment Selection with Details": "Onboarding → Equipment Selection",
    "Environment Selection": "Onboarding → Environment Selection",

    # Home Screen (Section 2)
    "Time-Based Greeting": "Home → Greeting Header",
    "Streak Badge": "Home → Streak Counter",
    "Quick Access Buttons": "Home → Quick Actions Row",
    "Next Workout Card": "Home → Next Workout Tile",
    "Weekly Progress": "Home → Weekly Progress Tile",
    "Weekly Goals": "Home → Weekly Goals Tile",
    "Upcoming Workouts": "Home → Upcoming Workouts Tile",
    "Generation Banner": "Home → Generation Status Banner",
    "Pull-to-Refresh": "Home → Pull Down",
    "Program Menu": "Home → Program Button → Menu",
    "Library Quick Access": "Home → Library Chip",
    "Notification Bell": "Home → Top Right → Bell Icon",
    "Daily Activity Status": "Home → Activity Status Tile",
    "Empty State": "Home → No Workouts State",
    "Senior Home Variant": "Home (Senior Mode)",
    "Mood Picker Card": "Home → Mood Picker Tile",
    "Fitness Score Card": "Home → Fitness Score Tile",
    "Context Logging": "Backend system",
    "My Space Button": "Home → Top Right → My Space Icon",
    "Layout Editor Screen": "Home → My Space → Editor",
    "Multiple Layouts": "Home → My Space → Layouts List",
    "Layout Templates": "Home → My Space → Templates",
    "Tile Size Options": "Home → My Space → Tile Settings",
    "Tile Picker Sheet": "Home → My Space → Add Tile",
    "Template Picker Sheet": "Home → My Space → Apply Template",
    "Dynamic Tile Rendering": "Home → Tile Display",
    "Layout Sharing": "Home → My Space → Share Layout",
    "26 Tile Types": "Home → Various Tiles",
    "Layout Activity Logging": "Backend system",
    "Default Layout Migration": "Backend system",
    "My Journey Card": "Home → My Journey Tile",
    "Journey Milestones": "Home → My Journey → Milestones",
    "Journey Half-Size Tile": "Home → My Journey (Compact)",

    # Workout Generation & Management (Section 3)
    "Monthly Program Generation": "Home → Generate Program",
    "Weekly Scheduling": "Home → Program → Schedule",
    "On-Demand Generation": "Home → Quick Workout",
    "Progressive Overload": "Automatic in generation",
    "Holiday Naming": "Automatic in generation",
    "Equipment Filtering": "Settings → Training → My Equipment",
    "Injury-Aware Selection": "Settings → Training → Muscles to Avoid",
    "Fitness-Level Exercise Filter": "Backend system",
    "Fitness-Level Workout Parameters": "Backend system",
    "Fitness-Level Edge Case Handling": "Backend system",
    "Fitness-Level Derived Difficulty": "Backend system",
    "Goal-Based Customization": "Onboarding → Goals / Settings",
    "Focus Area Targeting": "Home → Program Menu → Edit",
    "Difficulty Adjustment": "Home → Program Menu → Edit → Difficulty",
    "Program Duration": "Home → Program Menu → Edit → Duration",
    "Workout Regeneration": "Home → Program Menu → Regenerate",
    "Drag-and-Drop Rescheduling": "Schedule → Drag Workout",
    "Calendar View - Agenda": "Schedule → Agenda View",
    "Calendar View - Week": "Schedule → Week View",
    "Edit Program Sheet": "Home → Program Menu → Edit Program",
    "Program Menu Button": "Home → Program Button",
    "Quick Regenerate": "Home → Program Menu → Quick Regenerate",
    "Program Reset Analytics": "Backend system",
    "Exercise Swap": "Active Workout → Exercise → Swap",
    "Workout Preview": "Home → Workout Card → View Details",
    "Exercise Count": "Workout Preview → Exercise Count",
    "Duration Estimate": "Workout Preview → Duration",
    "Calorie Estimate": "Workout Preview → Calories",
    "Environment-Aware Generation": "Backend system",
    "Detailed Equipment Integration": "Backend system",
    "Training Split Enforcement": "Settings → Training → Training Split",
    "Balanced Muscle Distribution": "Backend system",
    "Superset Support": "Active Workout → Supersets",
    "AMRAP Finishers": "Active Workout → AMRAP Sets",
    "Set Type Tracking": "Active Workout → Set Types",
    "Drop Sets": "Active Workout → Drop Set",
    "Giant Sets": "Active Workout → Giant Sets",
    "Rest-Pause Sets": "Active Workout → Rest-Pause",
    "Compound Sets": "Active Workout → Compound Sets",
    "Dynamic Warmup Generator": "Workout Start → Warmup",
    "Injury-Aware Warmups": "Workout Start → Warmup",
    "Cooldown Stretch Generator": "Workout End → Stretches",
    "RPE-Based Difficulty": "Active Workout → RPE Input",
    "1RM Calculation": "Active Workout → 1RM Calculator",
    "Estimated 1RM Display": "Active Workout → 1RM Display",
    "Percentage-Based Training": "Settings → Training → Intensity",
    "My 1RMs Screen": "Settings → Training → My 1RMs",
    "Training Intensity Selector": "Settings → Training → Intensity Slider",
    "Auto-Populate 1RMs": "Settings → Training → My 1RMs → Auto-Calculate",
    "Per-Exercise Intensity Override": "Settings → Training → My 1RMs → Override",
    "Equipment-Aware Weight Rounding": "Backend system",
    "RPE to Percentage Conversion": "Backend system",
    "Fitness Glossary": "Settings → Glossary",
    "Workout Sharing Templates": "Workout Complete → Share",
    "Exercise Notes": "Active Workout → Exercise → Notes",
    "Failure Set Tracking": "Active Workout → Mark Failure",
    "Hydration During Workout": "Active Workout → Hydration Button",
    "Adaptive Rest Periods": "Active Workout → Rest Timer",
    "Workout Difficulty Rating": "Workout Complete → Rating",
    "Mobility Workout Type": "Home → Quick Workout → Mobility",
    "Recovery Workout Type": "Home → Quick Workout → Recovery",
    "Hold Seconds Display": "Active Workout → Hold Timer",
    "Unilateral Exercise Support": "Active Workout → Each Side Indicator",
    "Yoga Pose Generation": "Mobility Workout → Yoga Poses",
    "Dynamic Mobility Drills": "Mobility Workout → Dynamic Stretches",
    "Body Area Flexibility Tracking": "Progress → Flexibility",
    "Unilateral Progress Analytics": "Progress → Unilateral Stats",
    "Workout Type Selection UI": "Home → Program Menu → Edit → Type",
    "Mood-Based Workout Generation": "Home → Mood Picker → Generate",
    "Mood-to-Workout Mapping": "Home → Mood Picker → Generate",
    "SSE Streaming Generation": "Backend system",
    "Mood Check-in Logging": "Home → Mood Picker → Log",
    "Mood History Screen": "Home → Mood Picker → View History",
    "Mood Analytics Dashboard": "Home → Mood Picker → Analytics",
    "Mood Pattern Analysis": "Home → Mood Picker → Patterns",
    "Mood Streak Tracking": "Home → Mood Picker → Streak",
    "Mood-Based Recommendations": "Home → Mood Picker → Recommendations",
    "Today's Mood Check-in": "Home → Mood Picker",
    "Mood Workout Completion": "Mood History → Complete",
    "Preference Enforcement in Generation": "Backend system",
    "Post-Generation Preference Validation": "Backend system",
    "Extend Workout / Do More": "Workout Complete → Do More",
    "Custom Workout Builder": "Home → Create Workout",
    "Universal 1RM Weight Application": "Backend system",
    "Historical Weight Integration": "Backend system",
    "Target Muscle Warmup Logging": "Backend system",
    "Equipment-Specific Weight Rounding": "Backend system",
    "Fuzzy Exercise Name Matching": "Backend system",
    "Full Gym Equipment Support": "Settings → Training → Equipment",
    "Detailed Equipment Weights": "Settings → Training → Equipment → Weights",
    "Readiness Score Integration": "Backend system",
    "Mood-Aware Workout Recommendations": "Backend system",
    "Injury-to-Muscle Mapping": "Backend system",
    "User Context Logging for AI": "Backend system",
    "Adaptive Difficulty from Feedback": "Workout Complete → Feedback",
    "Feedback Pattern Analysis": "Backend system",
    "Progressive Difficulty Increase": "Backend system",
    "Difficulty Regression": "Backend system",
    "Customizable Warmup Duration": "Settings → Warmup & Cooldown → Duration",
    "Customizable Stretch Duration": "Settings → Warmup & Cooldown → Stretch",

    # Cardio/Endurance (Section 3b)
    "Cardio Workout Generation": "Home → Cardio Workout",
    "Heart Rate Training Zones (Karvonen)": "Cardio → HR Zones",
    "Heart Rate Training Zones (Percentage)": "Cardio → HR Zones",
    "VO2 Max Estimation": "Cardio → VO2 Max",
    "Fitness Age Calculation": "Cardio → Fitness Age",
    "HR Zones Card Widget": "Home → HR Zones Tile",
    "HR Zones Visualization": "Cardio → Zone Display",
    "Cardio Metrics Table": "Cardio → Metrics",
    "HIIT Workout Type": "Home → Quick Workout → HIIT",
    "Steady-State Cardio": "Home → Quick Workout → Cardio",
    "Cardio Rest Suggestions": "Cardio Workout → Rest Suggestions",
    "Cardio Progression Tracking": "Progress → Cardio",
    "HR Variability (HRV) Tracking": "Health → HRV",
    "Cardio Metrics API": "Backend system",
    "Custom Max HR Setting": "Settings → Cardio → Max HR",
    "Cardio Metrics History": "Cardio → History",
    "Real-time Zone Detection": "Active Cardio → Zone Indicator",
    "Zone Benefit Descriptions": "Cardio → Zone Info",
    "Cardio Session Logging": "Home → Log Cardio",
    "Indoor/Outdoor Location Tracking": "Log Cardio → Location",
    "Treadmill Run Annotation": "Log Cardio → Location → Treadmill",
    "Weather Conditions Tracking": "Log Cardio → Weather",
    "Cardio Session Statistics": "Cardio → Stats",
    "Cardio Patterns in User Context": "Backend system",
    "Cardio-Strength Balance Tracking": "Backend system",

    # Flexibility/Mobility (Section 3c)
    "Flexibility Assessment System": "Library → Flexibility → Assessment",
    "Age/Gender-Adjusted Norms": "Flexibility → Norms",
    "Assessment Score Calculation": "Flexibility → Score",
    "Flexibility Progress Tracking": "Progress → Flexibility",
    "Flexibility Gap Analysis": "Flexibility → Gap Analysis",
    "Personalized Stretch Recommendations": "Flexibility → Recommendations",
    "Flexibility Progress Charts": "Progress → Flexibility Charts",
    "Test Detail Screen": "Flexibility → Test Details",
    "Assessment History Screen": "Flexibility → History",
    "Record Assessment Sheet": "Flexibility → Record",
    "Higher/Lower Is Better Logic": "Backend system",
    "Test Categories by Muscle": "Flexibility → Categories",
    "Percentile Calculation": "Backend system",
    "Improvement Messages": "Flexibility → Tips",
    "Flexibility Score Card Widget": "Home → Flexibility Tile",
    "Assessment Reminders": "Notifications → Flexibility",
    "Flexibility-Based Warmup Integration": "Backend system",
    "Stretch Plan Management": "Flexibility → Stretch Plan",

    # Active Workout Experience (Section 4)
    "3-Phase Structure": "Active Workout → Phases",
    "Warmup Exercises": "Active Workout → Warmup Phase",
    "Set Tracking": "Active Workout → Set Counter",
    "Reps/Weight Logging": "Active Workout → Log Input",
    "Rest Timer Overlay": "Active Workout → Rest Timer",
    "Skip Set/Rest": "Active Workout → Skip Button",
    "Previous Performance": "Active Workout → History Button",
    "Exercise Video": "Active Workout → Video Display",
    "Exercise Detail Sheet": "Active Workout → Swipe Up → Details",
    "Mid-Workout Swap": "Active Workout → Exercise → Swap",
    "Pause/Resume": "Active Workout → Pause Button",
    "Exit Confirmation": "Active Workout → Back → Confirm Exit",
    "Elapsed Timer": "Active Workout → Timer Display",
    "Set Progress Visual": "Active Workout → Set Circles",
    "1RM Logging": "Active Workout → Log 1RM",
    "1RM Percentage Display": "Active Workout → Weight → %1RM",
    "On-Target Indicator": "Active Workout → Weight → Indicator",
    "Alternating Hands": "Active Workout → Side Indicator",
    "Challenge Stats": "Active Workout → Challenge Mode",
    "Feedback Modal": "Workout Complete → Feedback",
    "PR Detection": "Workout Complete → PR Badge",
    "Volume Calculation": "Workout Complete → Volume Stats",
    "Completion Screen": "Workout Complete",
    "Performance Comparison": "Workout Complete → Comparison",
    "Social Share": "Workout Complete → Share",
    "RPE Tracking": "Active Workout → RPE Input",
    "RIR Tracking": "Active Workout → RIR Input",
    "RPE/RIR Help System": "Active Workout → RPE/RIR → Help",
    "AI Weight Suggestion": "Active Workout → Rest → Suggestion",
    "Weight Suggestion Loading": "Active Workout → Rest → Loading",
    "Rule-Based Fallback": "Backend system",
    "Equipment-Aware Increments": "Backend system",
    "Accept/Reject Suggestions": "Active Workout → Rest → Accept/Reject",
    "Timed Exercise Pause": "Active Workout → Timed → Pause",
    "Timed Exercise Resume": "Active Workout → Timed → Resume",
    "Exercise Transition Countdown": "Active Workout → Transition Overlay",
    "Transition Haptic Feedback": "Active Workout → Transition → Haptics",
    "Voice Exercise Announcements": "Active Workout → TTS",
    "Voice Workout Completion": "Workout Complete → TTS",
    "Exercise Name Expansion": "Backend system",
    "Exercise Skip During Workout": "Active Workout → Skip Exercise",
    "Per-Exercise Difficulty Rating": "Workout Complete → Rate Exercises",
    "Feedback Importance Explanation": "Workout Complete → Feedback Info",
    "Voice Rest Period Countdown": "Active Workout → Rest → TTS",
    "Dynamic Set Reduction": "Active Workout → Minus Button",
    "Skip Remaining Sets": "Active Workout → End Exercise Early",
    "Edit Completed Sets": "Active Workout → Tap Set → Edit",
    "Delete Completed Sets": "Active Workout → Swipe Set → Delete",
    "Set Adjustment Reasons": "Active Workout → Reduce → Reason",
    "Fatigue Detection": "Backend system",
    "Smart Set Suggestions": "Active Workout → Fatigue Alert",
    "Adjusted Sets Visual": "Active Workout → Set Count Display",
    "Set Adjustment History": "Backend system",
    "Set Adjustment Sheet": "Active Workout → Reduce → Sheet",

    # Exercise Library (Section 5)
    "Exercise Database": "Library → Exercises",
    "Netflix Carousels": "Library → Category Carousels",
    "Search Bar": "Library → Search",
    "Multi-Filter System": "Library → Filters",
    "Active Filter Chips": "Library → Filter Chips",
    "Clear All Filters": "Library → Clear Filters",
    "Exercise Cards": "Library → Exercise Card",
    "Exercise Detail View": "Library → Exercise → Details",
    "Form Cues": "Library → Exercise → Form Tips",
    "Equipment Display": "Library → Exercise → Equipment",
    "Difficulty Indicators": "Library → Exercise → Difficulty",
    "Secondary Muscles": "Library → Exercise → Muscles",
    "Safe Minimum Weight": "Library → Exercise → Min Weight",
    "Exercise History": "Library → Exercise → History",
    "Custom Exercises Screen": "Settings → Custom Content → My Exercises",
    "Create Simple Exercise": "Custom Exercises → Create → Simple",
    "Create Combo Exercise": "Custom Exercises → Create → Combo",
    "Combo Types": "Custom Exercises → Create → Combo → Type",
    "Component Management": "Custom Exercises → Combo → Components",
    "Exercise Search in Creator": "Custom Exercises → Create → Search",
    "Custom Exercise Usage Tracking": "Backend system",
    "Custom Exercise Stats": "Custom Exercises → Stats",
    "Custom Exercise Deletion": "Custom Exercises → Delete",
    "Custom Exercise Context Logging": "Backend system",
    "Exercise Video Download": "Library → Exercise → Download",
    "Video Download Progress": "Library → Exercise → Downloading",
    "Cancel Video Download": "Library → Exercise → Cancel Download",
    "Offline Video Playback": "Library → Exercise → Play Offline",

    # Skill Progressions (Section 5b)
    "Progression Chains System": "Library → Skills",
    "Pushup Mastery Chain": "Library → Skills → Pushup Mastery",
    "Pullup Journey Chain": "Library → Skills → Pullup Journey",
    "Squat Progressions Chain": "Library → Skills → Squat Progressions",
    "Handstand Journey Chain": "Library → Skills → Handstand Journey",
    "Muscle-Up Mastery Chain": "Library → Skills → Muscle-Up Mastery",
    "Front Lever Chain": "Library → Skills → Front Lever",
    "Planche Chain": "Library → Skills → Planche",
    "Skill Progress Tracking": "Library → Skills → Progress",
    "Unlock Criteria System": "Library → Skills → Unlock Criteria",
    "Practice Attempt Logging": "Library → Skills → Log Attempt",
    "Skills Screen": "Library → Skills Tab",
    "Chain Detail Screen": "Library → Skills → Chain Details",
    "Category Filtering": "Library → Skills → Filter",
    "Library Integration": "Library → Skills Tab",

    # Leverage-Based Progressions (Section 5c)
    "Exercise Variant Chains": "Library → Skills → Progressions",
    "User Exercise Mastery Tracking": "Backend system",
    "Automatic Progression Suggestions": "Workout Complete → Level Up Card",
    "Progression Suggestion Cards": "Workout Complete → Suggestions",
    "Accept/Decline Progression": "Workout Complete → Accept/Decline",
    "Progression History Audit": "Backend system",
    "Rep Range Preferences": "Settings → Training → Rep Preferences",
    "Rep Range Slider": "Settings → Training → Rep Range Slider",
    "\"Avoid High-Rep Sets\" Toggle": "Settings → Training → Avoid High Reps",
    "Progression Style Selector": "Settings → Training → Progression Style",
    "Gemini Progression Context": "Backend system",
    "Leverage-First Prompting": "Backend system",
    "Feedback-Mastery Integration": "Backend system",
    "Equipment-Aware Suggestions": "Backend system",
    "Mastery Score Calculation": "Backend system",
    "User Context Logging": "Backend system",

    # Pre-Built Programs (Section 6)
    "Program Library": "Library → Programs",
    "Category Filters": "Library → Programs → Filter",
    "Program Search": "Library → Programs → Search",
    "Program Cards": "Library → Programs → Card",
    "Celebrity Programs": "Library → Programs → Celebrity",
    "Session Duration": "Library → Programs → Duration",
    "Start Program": "Library → Programs → Start",
    "Program Detail": "Library → Programs → Details",

    # AI Coach Chat (Section 7)
    "Floating Chat Bubble": "Any Screen → Chat Bubble",
    "Full-Screen Chat": "Chat Bubble → Expand",
    "Coach Agent": "Chat → @coach",
    "Nutrition Agent": "Chat → @nutrition",
    "Workout Agent": "Chat → @workout",
    "Injury Agent": "Chat → @injury",
    "Hydration Agent": "Chat → @hydration",
    "@Mention Routing": "Chat → @mention",
    "Intent Auto-Routing": "Chat → Auto-routing",
    "Conversation History": "Chat → History",
    "Suggestion Buttons": "Chat → Suggestions",
    "Typing Indicator": "Chat → Typing...",

    # Nutrition (Section 8)
    "Meal Logging": "Nutrition → Log Meal",
    "Barcode Scanner": "Nutrition → Scan Barcode",
    "Food Search": "Nutrition → Search Food",
    "AI Food Recognition": "Nutrition → Photo → Recognize",
    "Macro Tracking": "Nutrition → Macros",
    "Calorie Display": "Nutrition → Calories",
    "Meal History": "Nutrition → History",
    "Recipe Builder": "Nutrition → Recipes → Create",
    "Meal Plans": "Nutrition → Meal Plans",
    "Nutrition Goals": "Nutrition → Goals",

    # Hydration (Section 9)
    "Water Intake Logging": "Hydration → Log Water",
    "Hydration Goals": "Hydration → Daily Goal",
    "Hydration Reminders": "Settings → Notifications → Hydration",
    "Hydration History": "Hydration → History",
    "Hydration Widget": "Home → Hydration Tile",

    # Fasting (Section 10)
    "Fasting Timer": "Fasting → Timer",
    "Fasting Schedules": "Fasting → Schedules",
    "Fasting History": "Fasting → History",
    "Fasting Goals": "Fasting → Goals",

    # Progress Photos (Section 11)
    "Photo Capture": "Progress → Photos → Capture",
    "Photo Comparison": "Progress → Photos → Compare",
    "Photo Gallery": "Progress → Photos → Gallery",
    "Body Measurements": "Progress → Measurements",
    "Weight Tracking": "Progress → Weight",

    # Social (Section 12)
    "Social Feed": "Social → Feed",
    "Follow/Unfollow": "Social → Profile → Follow",
    "Like/Comment": "Social → Post → Like/Comment",
    "Share Workout": "Workout Complete → Share → Social",
    "Challenges": "Social → Challenges",
    "Leaderboards": "Social → Leaderboards",

    # Achievements (Section 13)
    "Achievement Badges": "Profile → Achievements",
    "Streak Tracking": "Home → Streak",
    "Milestones": "Progress → Milestones",
    "XP System": "Profile → XP",
    "Levels": "Profile → Level",

    # Profile & Stats (Section 14)
    "User Profile": "Profile",
    "Stats Overview": "Profile → Stats",
    "Personal Records": "Profile → PRs",
    "Settings Access": "Profile → Settings",

    # Schedule (Section 15)
    "Weekly Calendar": "Schedule → Week View",
    "Workout Scheduling": "Schedule → Drag & Drop",
    "Rest Days": "Schedule → Rest Days",

    # Metrics (Section 16)
    "Volume Over Time": "Progress → Charts → Volume",
    "Strength Progress": "Progress → Charts → Strength",
    "Workout Frequency": "Progress → Charts → Frequency",
    "Exercise Analytics": "Progress → Analytics",

    # Measurements (Section 17)
    "Body Part Measurements": "Progress → Measurements",
    "Weight Log": "Progress → Weight",
    "Body Fat %": "Progress → Body Fat",

    # Notifications (Section 18)
    "Push Notifications": "Settings → Notifications",
    "Workout Reminders": "Settings → Notifications → Workout",
    "Hydration Reminders": "Settings → Notifications → Hydration",
    "Achievement Alerts": "Settings → Notifications → Achievements",
    "Social Notifications": "Settings → Notifications → Social",

    # Settings (Section 19)
    "Account Settings": "Settings → Account",
    "Privacy Settings": "Settings → Privacy",
    "Data Export": "Settings → Data → Export",
    "Units Selection": "Settings → Units",
    "Theme/Dark Mode": "Settings → Appearance → Theme",
    "Logout": "Settings → Logout",
    "Delete Account": "Settings → Danger Zone → Delete",

    # Accessibility (Section 20)
    "Font Size Adjustment": "Settings → Accessibility → Font Size",
    "High Contrast Mode": "Settings → Accessibility → Contrast",
    "Screen Reader Support": "Settings → Accessibility → Screen Reader",
    "Reduced Motion": "Settings → Accessibility → Reduced Motion",

    # Health Device Integration (Section 21)
    "Apple Health": "Settings → Health → Apple Health",
    "Google Fit": "Settings → Health → Google Fit",
    "Fitbit": "Settings → Health → Fitbit",
    "Garmin": "Settings → Health → Garmin",
    "Whoop": "Settings → Health → Whoop",

    # Paywall & Subscriptions (Section 22)
    "Subscription Plans": "Settings → Subscription → Plans",
    "Manage Subscription": "Settings → Subscription → Manage",
    "Cancel Subscription": "Settings → Subscription → Cancel",
    "Restore Purchases": "Settings → Subscription → Restore",
    "Trial Status": "Settings → Subscription → Trial",

    # Customer Support (Section 23)
    "Support Tickets": "Settings → Support → Tickets",
    "Create Ticket": "Settings → Support → Create Ticket",
    "FAQ": "Settings → Help → FAQ",
    "Contact Support": "Settings → Support → Contact",
    "Report Bug": "Settings → Support → Report Bug",

    # Home Widgets (Section 24)
    "iOS Widgets": "iOS Home Screen → Add Widget",
    "Android Widgets": "Android Home Screen → Add Widget",
    "Quick Start Widget": "Home Widget → Today's Workout",
    "Progress Widget": "Home Widget → Progress",
    "Streak Widget": "Home Widget → Streak",
}

# Default navigation for features not in mapping
DEFAULT_NAVIGATION = "—"

def get_navigation_path(feature_name):
    """Get navigation path for a feature name."""
    # Try exact match first
    if feature_name in NAVIGATION_PATHS:
        return NAVIGATION_PATHS[feature_name]

    # Try partial match
    for key, path in NAVIGATION_PATHS.items():
        if key.lower() in feature_name.lower() or feature_name.lower() in key.lower():
            return path

    # Check for common patterns
    feature_lower = feature_name.lower()

    if "backend" in feature_lower or "api" in feature_lower or "logging" in feature_lower or "tracking" in feature_lower:
        return "Backend system"
    if "notification" in feature_lower or "reminder" in feature_lower:
        return "Settings → Notifications"
    if "settings" in feature_lower:
        return "Settings"
    if "onboarding" in feature_lower:
        return "Onboarding Flow"
    if "workout" in feature_lower:
        return "Active Workout"
    if "exercise" in feature_lower:
        return "Library → Exercises"
    if "progress" in feature_lower or "chart" in feature_lower:
        return "Progress"
    if "nutrition" in feature_lower or "meal" in feature_lower or "food" in feature_lower:
        return "Nutrition"
    if "hydration" in feature_lower or "water" in feature_lower:
        return "Hydration"
    if "fasting" in feature_lower:
        return "Fasting"
    if "social" in feature_lower or "share" in feature_lower:
        return "Social"
    if "profile" in feature_lower:
        return "Profile"
    if "subscription" in feature_lower or "paywall" in feature_lower:
        return "Settings → Subscription"
    if "support" in feature_lower or "ticket" in feature_lower:
        return "Settings → Support"
    if "widget" in feature_lower:
        return "Home Screen Widget"
    if "chat" in feature_lower or "coach" in feature_lower or "ai" in feature_lower:
        return "Chat"
    if "cardio" in feature_lower or "heart rate" in feature_lower or "hr zone" in feature_lower:
        return "Cardio"
    if "flexibility" in feature_lower or "stretch" in feature_lower:
        return "Flexibility"
    if "skill" in feature_lower or "progression" in feature_lower:
        return "Library → Skills"
    if "home" in feature_lower:
        return "Home"

    return DEFAULT_NAVIGATION


def process_table_row(line, is_header=False, is_separator=False):
    """Process a table row to add navigation column."""
    if not line.strip().startswith('|'):
        return line

    # Split by pipe, preserving structure
    parts = line.rstrip().split('|')

    if is_header:
        # Add Navigation header
        # Find the last non-empty part
        if parts[-1].strip() == '':
            parts.insert(-1, ' Navigation ')
        else:
            parts.append(' Navigation ')
            parts.append('')
        return '|'.join(parts)

    if is_separator:
        # Add separator for navigation column
        if parts[-1].strip() == '':
            parts.insert(-1, '-------|')
        else:
            parts.append('-------|')
            parts.append('')
        # Clean up the separator
        return '|'.join(parts).replace('||', '|')

    # Regular row - add navigation
    # Find the feature name (typically in column 2)
    if len(parts) >= 3:
        feature_name = parts[2].strip()
        nav_path = get_navigation_path(feature_name)

        if parts[-1].strip() == '':
            parts.insert(-1, f' {nav_path} ')
        else:
            parts.append(f' {nav_path} ')
            parts.append('')
        return '|'.join(parts)

    return line


def add_navigation_to_tables(content):
    """Add navigation column to all feature tables in content."""
    lines = content.split('\n')
    result = []
    in_table = False
    table_line_count = 0

    for i, line in enumerate(lines):
        # Check if this is a table header line
        if line.strip().startswith('| # | Feature | Description |'):
            in_table = True
            table_line_count = 0
            # Process header
            result.append(process_table_row(line, is_header=True))
            continue

        if in_table:
            table_line_count += 1

            # Second line is separator
            if table_line_count == 1 and line.strip().startswith('|---'):
                result.append(process_table_row(line, is_separator=True))
                continue

            # Check if still in table
            if line.strip().startswith('|') and '|' in line[1:]:
                result.append(process_table_row(line))
                continue
            else:
                # End of table
                in_table = False
                result.append(line)
                continue

        result.append(line)

    return '\n'.join(result)


def main():
    input_file = '/Users/saichetangrandhe/AIFitnessCoach/FEATURES.md'

    print(f"Reading {input_file}...")
    with open(input_file, 'r', encoding='utf-8') as f:
        content = f.read()

    print("Adding navigation column to tables...")
    new_content = add_navigation_to_tables(content)

    # Write back
    print(f"Writing updated content to {input_file}...")
    with open(input_file, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print("Done!")


if __name__ == '__main__':
    main()
