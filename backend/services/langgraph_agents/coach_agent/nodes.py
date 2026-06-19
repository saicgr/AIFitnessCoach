"""
Node implementations for the Coach Agent.

The coach agent is autonomous - it handles:
1. General fitness questions
2. Motivation and greetings
3. App settings and navigation (via action_data)
"""
from typing import Dict, Any, List, Literal, Optional, Tuple
from datetime import datetime, timedelta
import base64
import re
import uuid
import pytz

from google.genai import types
from services.gemini.constants import gemini_generate_with_retry

from .state import CoachAgentState
from ..personality import build_personality_prompt, sanitize_coach_name
from models.chat import AISettings, CoachIntent
from services.gemini_service import GeminiService
from core.logger import get_logger

logger = get_logger(__name__)

# Coach expertise base prompt template (coach name is inserted dynamically)
COACH_BASE_PROMPT_TEMPLATE = """You are {coach_name}, an AI fitness coach. You are the main point of contact for users and handle:
- General fitness questions and advice
- Motivation and encouragement
- App navigation guidance
- Overall wellness tips

NOTE ON PERSONALITY:
Your voice, tone, energy level, and how you celebrate (or don't celebrate)
are defined entirely in the PERSONALITY CUSTOMIZATION section further down.
That section OVERRIDES any default warmth or enthusiasm. If the user picked
a reserved or stoic persona, stay reserved — do NOT default to hype or
celebratory phrasing.

CAPABILITIES:
1. **General Fitness**: Answer questions about training, rest, recovery
2. **Motivation**: Provide encouragement and support
3. **App Control**: Help users navigate the app and change settings
4. **Wellness**: Tips on sleep, stress, and overall health
5. **Nutrition**: Provide dietary advice and meal suggestions
6. **Injury/Recovery**: Help with pain and recovery questions
7. **Hydration**: Guide water intake and hydration
8. **Vision**: Analyze progress photos, identify gym equipment, read fitness documents and workout plans

You are a comprehensive fitness coach who can handle ALL aspects of fitness and wellness.
Do NOT tell users to ask other agents or use @mentions - YOU handle everything!

APP FEATURES & NAVIGATION GUIDE:
You can guide users to any feature and trigger navigation via action_data.

MAIN SCREENS (Bottom Nav):
- Home: Today's workout, quick actions, weekly calendar, progress stats
- Nutrition: Meal logging (photo/barcode/text), hydration (tab 3), macro targets
- Social: Activity feed, friends, challenges, leaderboards
- Profile: User stats, workout history, measurements, progress photos

WORKOUT FEATURES:
- Today's Workout: AI-generated daily workout on home screen
- Exercise Library (/library): 500+ exercises with form videos
- Custom Workouts (/workout/build): Build from any exercise
- Schedule (/schedule): Weekly view with drag & drop
- Workout History (/workouts): Past workouts with stats
- Modifications: the Workout specialist handles these (add/remove/replace, intensity, reschedule). If the user asks for a change or a recommended change, acknowledge briefly and tell them you'll pass it along — the router forwards these to the Workout agent automatically.

NUTRITION:
- Meal Logging: Photo analysis, barcode scan, or text search
- Menu/Buffet Analysis: Photo of restaurant menu for analysis
- Hydration: Water intake tracking (Nutrition tab 3)
- Recipes (/recipe-suggestions): AI-powered based on goals
- Food History (/food-history): Past logged meals

PROGRESS & ANALYTICS:
- Stats (/stats): Comprehensive dashboard
- Exercise History (/stats/exercise-history): Weight/rep progression
- Muscle Analytics (/stats/muscle-analytics): Training distribution
- Consistency (/consistency): Streaks and patterns
- Measurements (/measurements): Body measurements
- Milestones (/stats/milestones): Achievement celebrations

HEALTH & WELLNESS:
- Injuries (/injuries): Log injuries, get modified workouts
- Habits (/habits): Daily habit tracking
- NEAT (/neat): Daily activity and steps
- Metrics (/metrics): Apple Health / Google Fit data
- Strain Prevention (/strain-prevention): Overtraining monitoring
- Plateau Detection (/plateau): Stagnation alerts
- Hormonal Health (/hormonal-health): Cycle-aware adjustments
- Diabetes (/diabetes): Blood glucose tracking

GAMIFICATION:
- XP System: Earn XP for workouts, meals, streaks
- Trophy Room (/trophy-room): Earned badges
- Leaderboard (/xp-leaderboard): Compare with friends
- Achievements (/achievements): Full achievement list
- Fitness Wrapped (/wrapped): Monthly recap stories

SETTINGS (navigate users here):
- Workout Settings (/settings/workout-settings): Days/week, duration, split
- AI Coach (/settings/ai-coach): Personality, voice, style
- Appearance (/settings/appearance): Dark/light mode, colors, font size
- Sound & Notifications (/settings/sound-notifications): Audio, haptics, push
- Equipment (/settings/equipment): Available gym equipment
- Offline Mode (/settings/offline-mode): Download workouts offline
- Privacy (/settings/privacy-data): Data export, account management
- Subscription (/settings/subscription): Plan management

THINGS YOU CAN DO DIRECTLY (via action_data):
1. Navigate to any screen ("take me to...", "open...", "show me...")
2. Toggle dark/light mode on/off
3. Toggle ALL workout sounds on/off ("mute sounds", "turn off sounds")
4. Toggle countdown sounds specifically
5. Toggle rest timer sounds specifically
6. Toggle voice announcements / TTS on/off
7. Toggle background music on/off
8. Toggle haptic feedback on/off
9. Handle workout questions. IMPORTANT: you yourself have NO workout mutation tools. If the user wants to change a workout (add/remove/replace/reschedule/intensity) or asks for a recommended change, tell them briefly that you'll pass it to the workout specialist — the router will forward the next message to the Workout agent automatically when it sees a modification or recommendation intent.
10. Analyze food photos for calories & macros
11. Check exercise form from video
12. Compare form across multiple videos
13. Log hydration ("I drank 3 glasses of water")
14. Set daily water goal ("set my water goal to 10 glasses")
15. Report injuries and get modified workouts
16. Generate quick custom workouts
17. Start today's workout
18. Mark workout as complete
19. Set a custom reminder ("remind me to take creatine at 8am", "remind me in 2 hours to stretch", "remind me every morning at 7 to weigh in"). The phone fires it on time even if the app is closed. Use this for a SPECIFIC time/cadence + the user's own message. For the built-in recurring nudges (move every hour, drink water regularly) toggle movement_reminders / hydration_reminders instead.
20. Answer any fitness, nutrition, or wellness question

VALID DESTINATIONS (for action_data with action: "navigate"):
home, nutrition, social, profile, workouts, library, schedule, workout_builder,
hydration, fasting, food_history, food_library, recipe_suggestions, nutrition_settings,
stats, progress, milestones, exercise_history, muscle_analytics, progress_charts,
consistency, measurements, chat, live_chat, help, glossary,
injuries, habits, neat, metrics, diabetes, plateau, strain_prevention,
hormonal_health, mood_history, achievements, trophy_room, leaderboard,
rewards, summaries, settings, workout_settings, ai_coach, appearance,
sound_notifications, equipment, offline_mode, privacy, subscription

DIRECTLY TOGGLEABLE SETTINGS — boolean (action: "change_setting", setting_value: true/false).
These are flipped instantly in-app WITHOUT leaving the chat. Prefer these over telling
the user to open a settings page.

  Display / appearance:
  - dark_mode: Toggle dark mode (true=dark, false=light)
  - reduce_animations: Reduce motion / animations (accessibility)
  - high_contrast: High-contrast mode (accessibility)
  - serious_mode: Turn OFF celebrations/confetti/level-up popups (true=serious/quiet, false=normal)

  Workout sounds & audio:
  - sounds / sound_effects / mute: Toggle ALL workout sounds at once
  - countdown_sounds: Countdown beeps (3, 2, 1)
  - rest_timer_sounds: Rest timer end chime
  - exercise_completion_sounds: Chime when an exercise is completed
  - workout_completion_sounds: Chime when the whole workout is completed
  - voice_announcements / tts / text_to_speech: Voice coach during workouts
  - background_music: Allow/block other music apps during workouts
  - audio_ducking: Lower background music while the voice coach speaks
  - mute_during_video: Mute the voice coach while an exercise demo video plays
  - haptics: Vibration feedback (on=medium, off=none)

  Notifications & reminders (each is an independent in-app toggle):
  - workout_reminders, hydration_reminders, nutrition_reminders, movement_reminders,
    habit_reminders, post_workout_meal_reminder, daily_briefing
  - streak_alerts, achievement_alerts, weekly_summary, ai_coach_messages
  - guilt_notifications: "you missed your workout" guilt-tone nudges (usually set false)

  Nutrition UI:
  - nutrition_ai_tips: AI tips on the nutrition screen
  - nutrition_compact_view: Compact food-log layout
  - nutrition_quick_log: Quick-log mode
  - show_macros_on_log: Show macros when logging food

  Workout behavior:
  - week_starts_sunday: Week starts Sunday (false=Monday)
  - fatigue_alerts: Mid-workout fatigue alerts
  - pre_set_insight: Pre-set coaching insight
  - voice_set_logging: Log sets by voice
  - show_synced_workouts: Show wearable-synced workouts in the home carousel
  - ble_heart_rate: Bluetooth heart-rate monitor support
  - ble_auto_connect: Auto-connect to the last HR monitor
  - vacation_mode: Pause streaks/reminders while away
  - barbell_per_side: Enter barbell weight as per-side plates

ENUM / CHOICE SETTINGS (action: "change_setting", put the choice in setting_value_text):
  - theme_mode: "light" | "dark" | "system"  (use this when the user says "match my phone"/"auto")
  - haptic_level: "off" | "light" | "medium" | "strong"
  - sound_volume: "low" | "medium" | "high"
  - accent_color: "monochrome" | "cyan" | "purple" | "orange" | "green" | "blue" | "red" | "pink" | "teal" | "indigo" | "amber" | "lime"
  - font_size: "small" | "normal" | "large" | "extra_large"
  - workout_weight_unit: "lbs" | "kg"   (weights you lift)
  - body_weight_unit: "lbs" | "kg"      (your body weight — SEPARATE from lifting units; never change both unless asked)
  - increment_unit: "lbs" | "kg"        (plate/dumbbell increment unit — also separate)

SETTINGS THAT OPEN A SETTINGS PAGE (action: "change_setting", no direct toggle):
- equipment: Opens Equipment settings
- workout_days / training_split: Opens Workout Settings
- ai_coach_style / coaching_style: Opens AI Coach settings

ADDITIONAL ACTIONS:
- action: "log_hydration", amount: N - Log N glasses of water
- action: "set_water_goal", glasses: N - Set daily water goal to N glasses
- action: "log_weight", weight: N - Navigate to log weight
- action: "start_workout", workout_id: ID - Start a specific workout
- action: "complete_workout", workout_id: ID - Mark workout as done
- action: "schedule_reminder" - Schedule a local device reminder. You do NOT
  build this payload yourself; the system resolves the time from the user's
  request against their timezone and emits {{title, body, trigger_time_iso8601,
  recurrence ('once'|'daily'|'weekly'), reminder_id}}. Just confirm naturally
  what was set ("Done — I'll remind you to take creatine every day at 8 AM").
  If no time was given the action comes back unsuccessful — then ASK the user
  when they'd like the reminder.

AI IMPORT TOOLS (delegated to the tool-binding agent path):
- import_gym_equipment(source='file'|'images'|'text'|'url', s3_keys?, mime_types?, raw_text?, url?)
  * When a user uploads a gym equipment list (PDF/Word/photo/URL) or says
    something like "import my gym equipment from this PDF", call this tool.
  * Returns {{action: "import_gym_equipment", job_id}} — the frontend polls
    /media-jobs/{{job_id}} and shows a confirmation sheet when the job
    completes. DO NOT attempt to list equipment yourself — the tool handles
    extraction, taxonomy matching, and environment inference.
- import_exercise(source='photo'|'video'|'text', s3_key?, raw_text?, user_hint?)
  * Use when the user wants to save a new custom exercise to their library
    — e.g. "add barbell hip thrust to my exercises", a photo of a new
    machine, or a video demo. Photo/text return the saved row synchronously;
    video returns a job_id for the preview sheet.

SAFETY GUARDRAILS (NON-NEGOTIABLE — applies to every reply):

1. **Sustainability over extreme goals.** If the user asks for an aggressive
   weight-loss / weight-gain / strength target (e.g. "lose 30 lbs in 30 days",
   "gain 20 lbs muscle in a month", "200 lbs in a year"), DO NOT generate a
   compliant plan. Briefly explain the realistic ceiling (≤1% body weight per
   week, ≤0.5-1 lb lean muscle per week, etc.) and offer a sustainable
   alternative. One line of reasoning is enough — don't lecture.

2. **Never auto-switch units.** If the user says "100 lb" treat as pounds. If
   they say "100 kg" treat as kg. NEVER convert between kg and lb silently —
   if it's genuinely ambiguous, ask one-word clarification ("lb or kg?").
   When logging or echoing a set, ALWAYS state the unit explicitly:
   "I logged 3 sets of squats at 100 lb" — never just "100".

3. **No diagnostic or treatment language.** You are NOT a clinician. Never
   say "you have X condition", "this is a sign of Y disorder", "stop taking
   medication", "take this supplement instead of your prescription", or
   anything that diagnoses or treats. If the user describes symptoms
   (chest pain, sudden numbness, persistent injury, anything alarming),
   recommend they speak with a doctor / PT / dietitian. Stay in the lane
   of fitness coaching + technique + sustainable habits.

4. **No claims of disease prevention or cure.** No "this workout prevents
   diabetes / cancer / heart disease". You can describe well-established
   benefits ("regular cardio improves cardiovascular fitness") but never
   make medical-grade outcome claims.

5. **Drop one-off jokes after a short window.** If the user said something
   sarcastically or as a one-off ("yeah I had beer for recovery, lol"), do
   NOT keep referencing it across days. Acknowledge the moment, then move
   on. The summarizer drops sarcasm-flagged turns after 48h — do not
   manually re-surface them earlier.

6. **Never narrate a single-point health-metric outlier as fact.** Zealova
   reads HR / HRV / SpO2 / sleep stages from HealthKit / Health Connect —
   meaning the values come from the user's Apple Watch / Fitbit / Whoop /
   ring, NOT from any Zealova sensor. Wearable optical sensors produce
   real outliers from grip, tattoos, cold skin, motion, loose strap. If
   a single value looks anomalous (e.g. resting HR > 140, sleep < 1h
   when the user mentioned sleeping normally, SpO2 < 85% with no other
   symptoms, HR spike > 30 BPM above the user's usual training peak on a
   casual walk), DO NOT report it as fact and DO NOT use it to drive a
   recommendation. Frame it as "your watch recorded a brief spike to
   184 BPM during your walk — likely a sensor artefact, not a real
   reading. If it happens repeatedly with symptoms, talk to a doctor."
   When in doubt, pull a second data point or ask the user how they
   actually felt. Single outliers are sensor problems until proven
   otherwise.

7. **Self-tracked data is opt-in.** If a SELF-TRACKED block is present you may
   reference the user's habit streaks, mood, and measurement trends naturally
   and proactively; if it's absent, never invent them.
"""


def _locale_system_prefix(locale: str) -> str:
    """Return the locale-awareness prefix to prepend to agent system prompts.

    Returns an empty string for 'en' (no instruction needed — default language).
    """
    if not locale or locale == "en":
        return ""
    from core.locale import LOCALE_NATIVE_NAMES
    native = LOCALE_NATIVE_NAMES.get(locale, locale)
    return (
        f"The user's preferred language is {native} ({locale}).\n"
        f"ALWAYS respond in {native}, regardless of which language the user\n"
        f"writes in. Match their tone but use {native}. Exceptions: keep\n"
        "technical fitness acronyms (RPE, 1RM, AMRAP, EMOM, PR, BMR, TDEE, HRV) and\n"
        "brand names (Zealova, Strava, Fitbod, MyFitnessPal) in Latin script even\n"
        "when responding in non-Latin-script languages.\n\n"
    )


from core.locale import locale_system_suffix as _locale_system_suffix  # noqa: E402


def get_coach_system_prompt(ai_settings: Dict[str, Any] = None, locale: str = "en") -> str:
    """Build the full system prompt with personality customization.

    Args:
        ai_settings: User's AI personality settings dict.
        locale: ISO 639-1 locale code for the user's preferred language.
                Defaults to 'en' for backwards compatibility.
    """
    settings_obj = AISettings(**ai_settings) if ai_settings else None

    # Get the coach name from settings or use default (sanitized)
    coach_name = sanitize_coach_name(settings_obj.coach_name, default="Coach") if settings_obj and settings_obj.coach_name else "Coach"

    # Build the base prompt with the coach name
    base_prompt = COACH_BASE_PROMPT_TEMPLATE.format(coach_name=coach_name)

    personality = build_personality_prompt(
        ai_settings=settings_obj,
        agent_name="Coach",  # Fallback agent name if coach_name not set
        agent_specialty="fitness coaching and wellness guidance"
    )
    return f"{_locale_system_prefix(locale)}{base_prompt}\n\n{personality}"


def format_workout_context(schedule: Dict[str, Any]) -> str:
    """Format workout schedule for context."""
    if not schedule:
        return ""

    parts = ["\nWORKOUT OVERVIEW:"]

    def format_date(date_str: str) -> str:
        if not date_str:
            return ""
        if "T" in date_str:
            date_str = date_str.split("T")[0]
        try:
            date_obj = datetime.strptime(date_str, "%Y-%m-%d")
            return date_obj.strftime("%A, %B %d")
        except ValueError:
            return date_str

    today = schedule.get("today")
    if today:
        status = "COMPLETED" if today.get("is_completed") else "scheduled"
        parts.append(f"- Today: {today.get('name', 'Unknown')} ({status})")

    tomorrow = schedule.get("tomorrow")
    if tomorrow:
        parts.append(f"- Tomorrow: {tomorrow.get('name', 'Unknown')}")

    this_week = schedule.get("thisWeek", [])
    completed_count = sum(1 for w in this_week if w.get("is_completed"))
    total_count = len(this_week)
    if total_count > 0:
        parts.append(f"- This week: {completed_count}/{total_count} workouts completed")

    return "\n".join(parts)


def format_dietary_and_nutrition_context(state: Dict[str, Any]) -> List[str]:
    """Gap 7/17 — dietary HARD rule + today's nutrition for the coach prompt.

    Returns a list of context_parts (possibly empty). Called from BOTH coach
    prompt builders (`_build_coach_response_prompt` + `coach_response_node`) so
    the streamed and buffered replies stay byte-identical — edit here, not in
    either caller.

    The dietary rule unions diet_type + dietary_restrictions[] + allergies +
    coach_memory (resolved in langgraph_service via `resolve_dietary_constraints`)
    so a "Vegan"-in-settings user who never said it in chat still never gets a
    meat suggestion — the video's "remembers you're vegan" moment, but grounded
    in structured prefs, not just chat memory.
    """
    out: List[str] = []

    dietary = state.get("dietary_constraints") or {}
    if dietary.get("hard_rule"):
        out.append(
            "\nDIETARY CONSTRAINTS (apply to EVERY food mention):\n"
            f"⛔ {dietary['hard_rule']}\n"
            "Never recommend, suggest, or assume a food that violates these — "
            "not even as an example. This holds whether or not the user "
            "mentioned it in this chat."
        )

    # Today's nutrition so the coach can answer "what should I eat?" in general
    # chat (not only @nutrition). Compact, grounded — never a macro dump.
    dnc = state.get("daily_nutrition_context") or {}
    if dnc:
        cal_t = dnc.get("target_calories")
        cal_c = dnc.get("total_calories")
        # Prefer the burn-adjusted net remainder when exercise earned calories
        # back; else the plain remainder.
        cal_r = dnc.get("net_calorie_remainder")
        if cal_r is None:
            cal_r = dnc.get("calorie_remainder")
        bits: List[str] = []
        if cal_t is not None:
            if cal_r is not None:
                bits.append(
                    f"calories {int(round(cal_c or 0))}/{int(round(cal_t))} "
                    f"({int(round(cal_r))} left)"
                )
            else:
                bits.append(f"calorie target {int(round(cal_t))}")
        prot_r = (dnc.get("macros_remaining") or {}).get("protein_g")
        if prot_r is not None:
            bits.append(f"{int(round(prot_r))}g protein left")
        burned = dnc.get("calories_burned_today")
        if burned:
            bits.append(f"{int(round(burned))} kcal burned today")
        if bits:
            out.append(
                "\nTODAY'S NUTRITION (use ONLY these numbers for food/calorie "
                "questions; never invent macros):\n- " + "; ".join(bits)
            )

    # Race/event periodization (Gap 11) — phase + today's auto-adjusted plan so
    # "should I train today?" respects the taper/peak/deload schedule.
    race_block = state.get("race_context")
    if race_block:
        out.append(
            "\n" + str(race_block).strip()
            + "\nUse this as the source of truth for training-load advice; the "
            "schedule already auto-adjusts for recovery — do not override it."
        )

    # Cycle phase (Gap 17) — compact prompt block so general-chat coaching is
    # cycle-aware. Reuses the same block the nutrition/workout agents get.
    cyc = state.get("cycle_context") or {}
    if cyc.get("available") and cyc.get("prompt_block"):
        out.append("\n" + str(cyc["prompt_block"]).strip())

    # Structured injury directives (Gap 17) — deterministic phase-aware safety,
    # not LLM-classified. One compact line; the coach must respect it.
    inj = state.get("injury_directives") or {}
    active = inj.get("active") or []
    ease_in = inj.get("ease_in") or []
    if active or ease_in:
        parts: List[str] = []
        for a in active[:4]:
            bp = a.get("body_part")
            ph = a.get("phase")
            ai = a.get("allowed_intensity")
            if bp:
                seg = bp
                if ph:
                    seg += f" ({ph}"
                    seg += f", {ai} intensity)" if ai else ")"
                parts.append(seg)
        for e in ease_in[:3]:
            bp = e.get("body_part")
            if bp:
                parts.append(f"{bp} (easing back in)")
        if parts:
            out.append(
                "\nACTIVE INJURIES (deterministic — respect for any training/"
                "exercise suggestion; never program around a hard-avoid):\n- "
                + "; ".join(parts)
            )

    return out


def format_profile_extras(profile: Dict[str, Any]) -> List[str]:
    """Gap 17 — extra USER PROFILE lines (age/sex/size + weight goal).

    Returns context_parts to append under the existing "USER PROFILE" header.
    Called from BOTH coach prompt builders — edit here, not in either caller.
    Renders weight in the user's own unit (lb default — they train in lb).
    Only emits a line when the value is present (no fabricated demographics).
    """
    out: List[str] = []
    if not profile:
        return out

    unit = (profile.get("weight_unit") or "lb").lower()

    def _w(kg):
        if kg in (None, 0):
            return None
        if unit == "kg":
            return f"{round(float(kg))} kg"
        return f"{round(float(kg) * 2.2046226)} lb"

    bits: List[str] = []
    age = profile.get("age")
    sex = profile.get("sex")
    if age:
        bits.append(f"age {int(age)}")
    if sex:
        bits.append(str(sex).lower())
    h = profile.get("height_cm")
    if h:
        if unit == "kg":
            bits.append(f"{round(float(h))} cm")
        else:
            total_in = round(float(h) / 2.54)
            bits.append(f"{total_in // 12}'{total_in % 12}\"")
    w = _w(profile.get("weight_kg"))
    if w:
        bits.append(w)
    bf = profile.get("body_fat_pct")
    if bf:
        bits.append(f"{round(float(bf))}% body fat")
    if bits:
        out.append("- Body: " + ", ".join(bits))

    tw = _w(profile.get("target_weight_kg"))
    if tw:
        cur = _w(profile.get("weight_kg"))
        if cur and cur != tw:
            out.append(
                f"- Weight goal: {tw} (from {cur}) — frame guidance toward this "
                "goal; never push an unsafe deficit."
            )
        else:
            out.append(f"- Weight goal: {tw}")

    return out


def should_handle_action(state: CoachAgentState) -> Literal["action", "log", "respond"]:
    """
    Determine if this is an action request, a wellness log, or a question.

    Routes to `log` for universal natural-language logging (Phase 6) —
    "I did 30 min yoga", "drank 500ml water", "weighed 70kg", "slept 7h",
    "meditated 10 min", "20 min sauna", and multi-action messages.

    Routes to `action` for settings / navigation / workout control.

    Routes to `respond` for general questions, greetings, motivation.
    """
    intent = state.get("intent")

    # Phase 6 — the universal logger. LOG_WEIGHT routes here too so chat
    # weight logging actually PERSISTS (it used to only emit UI action_data).
    if intent in (CoachIntent.LOG_ACTIVITY, CoachIntent.LOG_WEIGHT):
        logger.info(f"[Coach Router] Logging intent: {intent} -> log")
        return "log"

    action_intents = [
        CoachIntent.CHANGE_SETTING,
        CoachIntent.NAVIGATE,
        CoachIntent.START_WORKOUT,
        CoachIntent.COMPLETE_WORKOUT,
        CoachIntent.SET_WATER_GOAL,
        CoachIntent.SCHEDULE_REMINDER,
    ]

    if intent in action_intents:
        logger.info(f"[Coach Router] Action intent: {intent} -> action")
        return "action"

    # Default: respond with coaching
    logger.info("[Coach Router] General query -> respond")
    return "respond"


# Monday=0 .. Sunday=6, matching Python's datetime.weekday() and the
# `reminder_weekday` extraction field.
_WEEKDAY_NAMES = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
]


def _fmt_12h(dt: datetime) -> str:
    """Format a clock time as '6:05 PM' without platform-specific strftime
    flags (Render is Linux but %-I is non-portable — keep it explicit)."""
    hour = dt.hour % 12 or 12
    ampm = "AM" if dt.hour < 12 else "PM"
    return f"{hour}:{dt.minute:02d} {ampm}"


def _build_schedule_reminder_action(
    state: CoachAgentState,
) -> Tuple[Optional[Dict[str, Any]], str]:
    """Resolve a SCHEDULE_REMINDER intent into a frontend-ready action.

    The intent extractor captures time as EITHER a relative delay
    (`reminder_delay_minutes`) OR an absolute clock time (`reminder_time_hour` /
    `reminder_time_minute`) — never a real timestamp, because it has no notion
    of "now". Here we resolve it against the user's LIVE phone timezone
    (`user_tz`) into an absolute ISO-8601 instant the Flutter side hands
    straight to `flutter_local_notifications.zonedSchedule`.

    Returns (action_data, action_context). When no usable time was given we
    return a soft-failure action (success=False) so the acknowledgment asks the
    user when — we never silently drop the request.
    """
    tz_name = state.get("user_tz") or "UTC"
    try:
        tz = pytz.timezone(tz_name)
    except Exception:
        tz = pytz.UTC
        tz_name = "UTC"
    now = datetime.now(tz)

    text = (state.get("reminder_text") or "").strip()
    title = (state.get("reminder_title") or "").strip()
    if not title and text:
        title = text[:1].upper() + text[1:]
        if len(title) > 60:
            title = title[:57].rstrip() + "…"
    if not title:
        title = "Reminder"
    body = text or title

    recurrence = (state.get("reminder_recurrence") or "once").lower().strip()
    if recurrence not in ("once", "daily", "weekly"):
        recurrence = "once"

    delay = state.get("reminder_delay_minutes")
    hour = state.get("reminder_time_hour")
    minute = state.get("reminder_time_minute") or 0
    weekday = state.get("reminder_weekday")

    fire_at: Optional[datetime] = None

    if isinstance(delay, int) and delay > 0:
        # A relative delay is inherently one-off.
        recurrence = "once"
        fire_at = now + timedelta(minutes=delay)
    elif isinstance(hour, int) and 0 <= hour <= 23:
        try:
            candidate = now.replace(
                hour=hour, minute=int(minute or 0), second=0, microsecond=0
            )
        except Exception:
            candidate = now.replace(hour=hour, minute=0, second=0, microsecond=0)
        if recurrence == "weekly" and isinstance(weekday, int) and 0 <= weekday <= 6:
            days_ahead = (weekday - candidate.weekday()) % 7
            if days_ahead == 0 and candidate <= now:
                days_ahead = 7
            candidate = candidate + timedelta(days=days_ahead)
        elif candidate <= now:
            # once / daily: if the time already passed today, fire tomorrow.
            candidate = candidate + timedelta(days=1)
        fire_at = candidate

    if fire_at is None:
        return (
            {
                "action": "schedule_reminder",
                "success": False,
                "error": "no_time",
                "reminder_text": text or None,
            },
            f"Tried to set a reminder for '{text or 'something'}' but the user "
            f"gave no time — ask them WHEN they want it (a clock time or "
            f"'in N minutes/hours').",
        )

    reminder_id = "coach_" + uuid.uuid4().hex[:12]
    action_data = {
        "action": "schedule_reminder",
        "reminder_id": reminder_id,
        "title": title,
        "body": body,
        "trigger_time_iso8601": fire_at.isoformat(),
        "recurrence": recurrence,
        "weekday": weekday if recurrence == "weekly" else None,
        "success": True,
    }

    when_local = _fmt_12h(fire_at)
    if recurrence == "daily":
        when_desc = f"every day at {when_local}"
    elif recurrence == "weekly":
        wd = (
            _WEEKDAY_NAMES[weekday]
            if isinstance(weekday, int) and 0 <= weekday <= 6
            else "weekly"
        )
        when_desc = f"every {wd} at {when_local}"
    else:
        day_desc = (
            "today"
            if fire_at.date() == now.date()
            else (
                "tomorrow"
                if fire_at.date() == (now + timedelta(days=1)).date()
                else fire_at.strftime("%A, %b %d")
            )
        )
        when_desc = f"{day_desc} at {when_local}"
    action_context = (
        f"Scheduled a {'recurring ' if recurrence != 'once' else ''}reminder to "
        f"'{text or title}' {when_desc} ({tz_name})"
    )
    return action_data, action_context


async def coach_action_node(state: CoachAgentState) -> Dict[str, Any]:
    """
    Handle app actions (settings, navigation, workout control).
    """
    logger.info("[Coach Action] Processing app action...")

    intent = state.get("intent")
    gemini_service = GeminiService()

    action_data = None
    action_context = None

    if intent == CoachIntent.CHANGE_SETTING:
        setting_name = state.get("setting_name")
        setting_value = state.get("setting_value")
        setting_value_text = state.get("setting_value_text")
        if setting_name is not None:
            action_data = {
                "action": "change_setting",
                "setting_name": setting_name,
                "setting_value": setting_value,
                # Enum/string-valued settings (theme_mode='system',
                # haptic_level='light', accent_color='blue', font_size='large',
                # unit toggles) ride this field; boolean toggles leave it null.
                "setting_value_text": setting_value_text,
                "success": True,
            }
            applied = setting_value_text if setting_value_text is not None else setting_value
            action_context = f"Changed setting '{setting_name}' to {applied}"

    elif intent == CoachIntent.NAVIGATE:
        destination = state.get("destination")
        if destination:
            # ── "Need help" → contact chips (no /support route exists) ──
            # When the classifier maps the user's request to `support` (or any
            # legacy synonym), surface our three contact channels as tappable
            # options instead of trying to navigate to a missing route.
            # See feedback_no_silent_fallbacks.md — we don't fall back to a
            # broken navigate; we replace the intent with a structured action.
            if destination in ("support", "help", "contact", "live_chat"):
                from core.config import get_settings as _get_settings
                _s = _get_settings()
                action_data = {
                    "action": "show_options",
                    "prompt": "I can connect you with our team — pick one:",
                    "options": [
                        {
                            "label": "Discord",
                            "icon": "discord",
                            "url": _s.discord_url,
                        },
                        {
                            "label": "Email",
                            "icon": "email",
                            "url": f"mailto:{_s.support_email}",
                        },
                        {
                            "label": "Instagram",
                            "icon": "instagram",
                            "url": _s.instagram_url,
                        },
                    ],
                    "success": True,
                }
                action_context = "Offered contact options (Discord, Email, Instagram)"
            else:
                # ── Per-destination params (B3) ─────────────────────────
                # Hydration deep-links into the Fuel tab with the water
                # section preselected. Other destinations carry no params
                # by default — the frontend route map is the source of
                # truth for query strings.
                _nav_params: Dict[str, Any] = {}
                if destination == "hydration":
                    _nav_params = {"fuelSection": "water"}
                    # Normalize to `nutrition` so the frontend route map
                    # uses /nutrition?fuelSection=water (the canonical
                    # water section), not the legacy /nutrition?tab=2.
                    destination = "nutrition"
                action_data = {
                    "action": "navigate",
                    "destination": destination,
                    "params": _nav_params,
                    "success": True,
                }
                action_context = f"Navigating to {destination}"

    elif intent == CoachIntent.START_WORKOUT:
        workout = state.get("current_workout")
        workout_id = workout.get("id") if workout else None
        action_data = {
            "action": "start_workout",
            "workout_id": workout_id,
            "success": True,
        }
        action_context = f"Starting workout: {workout.get('name') if workout else 'your workout'}"

    elif intent == CoachIntent.COMPLETE_WORKOUT:
        workout = state.get("current_workout")
        workout_id = workout.get("id") if workout else None
        action_data = {
            "action": "complete_workout",
            "workout_id": workout_id,
            "success": True,
        }
        action_context = f"Completing workout: {workout.get('name') if workout else 'your workout'}"

    elif intent == CoachIntent.SET_WATER_GOAL:
        glasses = state.get("water_goal_glasses", 8)
        action_data = {
            "action": "set_water_goal",
            "glasses": glasses,
            "success": True,
        }
        action_context = f"Setting daily water goal to {glasses} glasses"

    elif intent == CoachIntent.LOG_WEIGHT:
        weight = state.get("weight_value")
        action_data = {
            "action": "log_weight",
            "weight": weight,
            "success": True,
        }
        action_context = f"Logging weight: {weight}"

    elif intent == CoachIntent.GENERATE_SHARE_ARTIFACT:
        # Mint a public share token for whatever the user asked to share.
        # `scope` and `period` are provided by the intent extractor in
        # state — defaults handle generic "share my week" type prompts.
        from services.langgraph_agents.tools.share_tools import (
            generate_share_artifact,
        )

        share_scope = state.get("share_scope") or "plan"
        share_period = state.get("share_period") or "week"
        user_id = state.get("user_id")
        if not user_id:
            action_data = {
                "action": "share_artifact_generated",
                "success": False,
                "error": "Sign in to create share links.",
            }
            action_context = "Cannot share — user not signed in"
        else:
            payload = await generate_share_artifact(
                user_id=user_id,
                scope=share_scope,
                period=share_period,
            )
            action_data = {"action": "share_artifact_generated", **payload}
            if payload.get("success"):
                action_context = (
                    f"Created public share link {payload.get('url')}"
                )
            else:
                action_context = (
                    f"Share failed: {payload.get('error', 'unknown error')}"
                )

    elif intent == CoachIntent.SCHEDULE_REMINDER:
        action_data, action_context = _build_schedule_reminder_action(state)

    # Generate a natural response for the action
    context_parts = []

    if state.get("user_profile"):
        profile = state["user_profile"]
    if action_context:
        context_parts.append(f"\nACTION: {action_context}")

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_coach_system_prompt(ai_settings, locale=state.get("locale") or "en")

    # NB: previous suffix said "Be friendly and helpful!" which silently
    # overrode non-friendly personas (drill-sergeant, scientist, zen-master,
    # professional). The persona prompt above already specifies tone — let it
    # do its job. Suffix is intentionally persona-neutral.
    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

You just performed an app action for the user. Acknowledge it naturally and briefly. Stay in character — your persona is defined above.""" + _locale_system_suffix(state.get("locale") or "en")

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    response = await gemini_service.chat(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
    )

    logger.info(f"[Coach Action] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
        "action_data": action_data,
    }


async def coach_log_node(state: CoachAgentState) -> Dict[str, Any]:
    """Universal natural-language logger (Phase 6).

    Parses the user's message into one-or-more structured wellness events,
    persists each via the `/events/log` endpoint, and confirms with concrete
    results ("Logged 30 min yoga — ~95 kcal 🔥"). Every log is undoable via
    the signed `undo_token` carried in action_data.

    Handles:
      - multi-action messages (one message → several logs)
      - the vague-input case (X3 — asks exactly one clarifying question)
      - done-vs-future is enforced by the extractor (X10/X13)
      - workout calories flow to the home flame icon via the workouts table
        (X9 — see api/v1/activity.py get_ai_burned_today)
    """
    from datetime import datetime, timedelta, timezone

    from services.logging.log_extractor import extract_log_actions

    logger.info("[Coach Log] Universal logging path...")

    user_message = state.get("user_message", "")
    user_id = state.get("user_id")
    gemini_service = GeminiService()

    # ── Extract structured loggable actions ──────────────────────────────
    extraction = await extract_log_actions(user_message, user_id=str(user_id) if user_id else None)

    # X3 — clear log but missing key detail → one concise question, no write.
    if extraction.get("needs_clarification"):
        question = extraction.get("clarification_question") \
            or "Got it — what did you do, and for how long?"
        return {
            "ai_response": question,
            "final_response": question,
            "action_data": None,
        }

    actions = extraction.get("actions") or []

    # X10/X13 — not actually a log (question / future / negation). Fall back
    # to a normal coaching reply rather than logging anything.
    if not extraction.get("is_log") or not actions:
        logger.info("[Coach Log] No loggable action — deferring to coach reply")
        return await coach_response_node(state)

    if not user_id:
        msg = "Sign in so I can save that to your log."
        return {"ai_response": msg, "final_response": msg, "action_data": None}

    # ── A5 / X14 — scheduled-workout reconciliation ──────────────────────
    # When the user reports doing their PLANNED session in generic terms
    # ("did legs today", "finished my workout", "trained chest"), complete
    # the workout that's already SCHEDULED for today instead of inserting a
    # duplicate freeform activity log. The extractor flags these actions
    # with refers_to_scheduled_workout=True.
    completed_scheduled = None   # dict describing the completed plan, if any
    if any(
        a.get("domain") == "workout" and a.get("refers_to_scheduled_workout")
        for a in actions
    ):
        completed_scheduled = await _complete_scheduled_workout(
            state, str(user_id),
        )
        if completed_scheduled is not None:
            # The scheduled workout was completed — drop the workout actions
            # that referred to it so we don't ALSO create a freeform log.
            actions = [
                a for a in actions
                if not (a.get("domain") == "workout"
                        and a.get("refers_to_scheduled_workout"))
            ]
        else:
            # No scheduled workout (or already done) — fall through and log
            # the workout actions as freeform activity. Strip the flag so
            # _post_process already produced a usable payload; if it lacks a
            # duration we ask one clarifying question instead.
            unusable = [
                a for a in actions
                if a.get("domain") == "workout"
                and a.get("refers_to_scheduled_workout")
                and not (a.get("payload") or {}).get("duration_minutes")
            ]
            if unusable and len(unusable) == len(
                [a for a in actions if a.get("domain") == "workout"]
            ):
                # Every workout action is a flag-only reference with no
                # detail and there's nothing scheduled to complete → ask.
                q = ("Nice — I don't see a workout scheduled for today. "
                     "What did you do, and for how long?")
                # Keep any non-workout actions (multi-action) flowing.
                actions = [a for a in actions if a.get("domain") != "workout"]
                if not actions:
                    return {"ai_response": q, "final_response": q,
                            "action_data": None}

    # ── Persist each action via the events endpoint (in-process) ─────────
    from api.v1.wellness.events import EventLogRequest, log_event as endpoint_log_event
    from fastapi import Request as _Req

    scope = {"type": "http", "headers": [], "method": "POST", "path": "/events/log"}

    logged = []   # successful EventLogResponse dicts + display labels
    failed = []   # human-readable failure notes
    for act in actions:
        # X1 — resolve the natural-language time hint to a concrete UTC ISO.
        occurred_at_iso = _resolve_log_timestamp(act.get("occurred_at_hint"))
        try:
            body = EventLogRequest(
                user_id=str(user_id),
                domain=act["domain"],
                source="chat",
                occurred_at=occurred_at_iso,
                payload=act["payload"],
            )
            req = _Req(scope=scope, receive=None)
            resp = await endpoint_log_event(
                request=req, body=body, current_user={"id": str(user_id)},
            )
            rd = resp.model_dump() if hasattr(resp, "model_dump") else dict(resp)
            rd["display"] = act.get("display")
            rd["extractor_warning"] = act.get("warning")
            logged.append(rd)
        except Exception as e:
            detail = getattr(e, "detail", None) or str(e)
            logger.warning(f"[Coach Log] write failed for {act['domain']}: {detail}")
            failed.append(act.get("display") or act["domain"])

    if not logged and completed_scheduled is None:
        msg = "I couldn't save that — mind rephrasing what you did?"
        if failed:
            msg = f"I couldn't log {', '.join(failed)} — could you rephrase?"
        return {"ai_response": msg, "final_response": msg, "action_data": None}

    # ── Build action_data ────────────────────────────────────────────────
    # Single log → flat event_logged payload (back-compat with the existing
    # frontend handler). Multiple logs → an `events` list the handler
    # iterates. Either way the frontend refreshes timeline + flame + undo.
    def _event_payload(rd: Dict[str, Any]) -> Dict[str, Any]:
        return {
            "domain": rd.get("domain"),
            "event_id": rd.get("event_id"),
            "name": rd.get("name"),
            "calories": rd.get("calories"),
            "undo_token": rd.get("undo_token"),
            "warning": rd.get("warning") or rd.get("extractor_warning"),
            "created": rd.get("created", True),
        }

    sched_already_done = bool(
        completed_scheduled and completed_scheduled.get("already_done")
    )

    if completed_scheduled is not None and not logged:
        if sched_already_done:
            # Nothing changed — the workout was already complete. No
            # action_data; just an acknowledging reply below.
            action_data = None
        else:
            # A5 — only a scheduled-workout completion happened. Emit the
            # existing `complete_workout` action so the frontend flips the
            # hero-carousel checkmark + week strip exactly like the UI path.
            action_data = {
                "action": "complete_workout",
                "workout_id": completed_scheduled.get("workout_id"),
                "success": True,
            }
    elif len(logged) == 1 and completed_scheduled is None:
        action_data = {"action": "event_logged", **_event_payload(logged[0])}
    else:
        # Multi-action, or a scheduled completion alongside other logs.
        action_data = {
            "action": "event_logged",
            "events": [_event_payload(rd) for rd in logged],
        }
        if completed_scheduled is not None and not sched_already_done:
            action_data["completed_workout_id"] = \
                completed_scheduled.get("workout_id")

    # ── Concrete confirmation copy (X18) ─────────────────────────────────
    confirm_lines = []
    if completed_scheduled is not None:
        _sched_name = completed_scheduled.get("name", "your scheduled workout")
        if sched_already_done:
            confirm_lines.append(f"{_sched_name} was already marked complete")
        else:
            confirm_lines.append(f"{_sched_name} marked complete ✅")
    for rd in logged:
        label = rd.get("display") or rd.get("name") or "your activity"
        cals = rd.get("calories")
        if cals and rd.get("domain") in ("workout", "sauna"):
            confirm_lines.append(f"{label} — ~{cals} kcal 🔥")
        else:
            confirm_lines.append(label)
    summary = "; ".join(confirm_lines)

    warnings = [rd.get("warning") or rd.get("extractor_warning")
                for rd in logged if rd.get("warning") or rd.get("extractor_warning")]
    warn_note = (" Note: " + " ".join(w for w in warnings if w)) if warnings else ""

    ai_settings = state.get("ai_settings")
    base_system_prompt = get_coach_system_prompt(ai_settings, locale=state.get("locale") or "en")
    system_prompt = f"""{base_system_prompt}

The user just logged the following and it has been SAVED to their tracker:
  {summary}{warn_note}

Confirm warmly in ONE or TWO short sentences that it's logged, repeating the
concrete result (duration / calories / amount). Add at most one brief
coaching nudge. Do NOT ask a question. Stay in character — persona above.""" + _locale_system_suffix(state.get("locale") or "en")

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]
    try:
        response = await gemini_service.chat(
            user_message=user_message,
            system_prompt=system_prompt,
            conversation_history=conversation_history,
        )
    except Exception as e:
        logger.warning(f"[Coach Log] confirmation copy failed: {e}")
        # Deterministic fallback — never leave the log silent (X18).
        response = f"Logged: {summary}.{warn_note}"

    logger.info(f"[Coach Log] Logged {len(logged)} event(s); failed {len(failed)}")
    return {
        "ai_response": response,
        "final_response": response,
        "action_data": action_data,
    }


async def _complete_scheduled_workout(state, user_id: str):
    """A5 / X14 — complete today's SCHEDULED workout, if there is one.

    Returns {workout_id, name} when a scheduled, not-yet-completed workout
    was marked done; returns None when there's nothing scheduled (or it's
    already complete) — the caller then logs a freeform activity instead.

    Uses the same `complete_workout` endpoint the UI uses, so PRs, streaks,
    XP and strength-score recalcs all run identically.
    """
    # Prefer the workout already threaded into agent state; fall back to a
    # fresh fetch for today.
    workout = state.get("current_workout")
    if not workout or not workout.get("id"):
        try:
            from services.langgraph_agents.tools.nutrition_context_helpers import (
                fetch_todays_workout,
            )
            workout = await fetch_todays_workout(user_id)
        except Exception as e:
            logger.warning(f"[Coach Log] fetch_todays_workout failed: {e}")
            workout = None

    if not workout or not workout.get("id"):
        return None  # rest day / nothing scheduled → caller logs freeform

    if workout.get("is_completed") or workout.get("status") == "completed":
        # Already done — don't double-complete; treat as "nothing to do" so
        # the caller falls through. The confirmation copy still acknowledges.
        logger.info("[Coach Log] scheduled workout already completed")
        return {
            "workout_id": workout.get("id"),
            "name": workout.get("name") or "your workout",
            "already_done": True,
        }

    try:
        from api.v1.workouts.crud_completion import complete_workout
        from fastapi import Request as _Req
        from starlette.background import BackgroundTasks as _BgTasks

        scope = {"type": "http", "headers": [], "method": "POST",
                 "path": "/workouts/complete"}
        await complete_workout(
            request=_Req(scope=scope, receive=None),
            workout_id=str(workout["id"]),
            background_tasks=_BgTasks(),
            completion_method="marked_done",
            current_user={"id": user_id},
        )
        logger.info(f"[Coach Log] completed scheduled workout {workout['id']}")
        return {
            "workout_id": workout.get("id"),
            "name": workout.get("name") or "your workout",
        }
    except Exception as e:
        detail = getattr(e, "detail", None) or str(e)
        logger.warning(f"[Coach Log] complete scheduled workout failed: {detail}")
        return None  # fall through to freeform log


def _resolve_log_timestamp(hint) -> str:
    """Convert a natural-language time hint to a concrete UTC ISO string.

    X1 — "yesterday" / "this morning" / "last night" must log to the right
    date, not "now". Reuses the catalog's deterministic hint tables.
    """
    from datetime import datetime, timedelta, timezone
    from services.logging.catalog import resolve_day_offset, resolve_time_of_day

    now = datetime.now(timezone.utc)
    if not hint:
        return now.isoformat()
    target = now + timedelta(days=resolve_day_offset(hint))
    tod = resolve_time_of_day(hint)
    if tod:
        midpoint = (tod[0] + tod[1]) // 2
        target = target.replace(hour=midpoint, minute=0, second=0, microsecond=0)
        # Never produce a future timestamp (e.g. "this evening" said at noon).
        if target > now:
            target = now
    return target.isoformat()


def _build_coach_response_prompt(state: CoachAgentState):
    """Build the (system_prompt, conversation_history) pair for a general
    coaching reply.

    Extracted from `coach_response_node` so the SSE token-streaming path
    (`coach_response_stream`) builds an IDENTICAL prompt — the streamed reply
    must be byte-for-byte equivalent to what the buffered node would produce.
    """
    context_parts = []

    # Add current date/time
    pacific = pytz.timezone('America/Los_Angeles')
    now = datetime.now(pacific)
    context_parts.append(f"CURRENT DATE/TIME: {now.strftime('%A, %B %d, %Y at %I:%M %p')} (Pacific Time)")

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"\nUSER PROFILE:")
        context_parts.append(f"- Fitness Level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"- Goals: {', '.join(profile.get('goals', []))}")
        context_parts.extend(format_profile_extras(profile))  # Gap 17: age/sex/size/weight goal

    # === Long-term coach memory (migration 2217) ===
    # Durable facts the user told the coach (injuries/pain, dietary prefs,
    # goals, constraints) + open loops to follow up on — pre-fetched and ranked
    # in langgraph_service so recall is cross-session and cross-day. Empty
    # string when the user has no memory or disabled it. Kept identical in both
    # the streaming (_build_coach_response_prompt) and buffered
    # (coach_response_node) paths — edit both together.
    memory_context = state.get("memory_context")
    if memory_context:
        context_parts.append(f"\n{memory_context}")

    if state.get("workout_schedule"):
        context_parts.append(format_workout_context(state["workout_schedule"]))

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    # === Wearable health & activity context (Phase B2) ===
    # IMPORTANT: this snippet is byte-for-byte identical to the one in
    # `coach_response_node` — the streamed and buffered coach replies MUST
    # build the same prompt. Edit both together.
    health_context = state.get("health_context")
    if health_context:
        context_parts.append(
            f"\nWEARABLE HEALTH & ACTIVITY:\n{health_context}\n"
            "You can see this user's wearable health data — answer sleep, "
            "recovery, step, heart-rate, water, and activity questions using "
            "ONLY the numbers above. If a metric is absent here, the user has "
            "no wearable for it — say so plainly and never invent numbers."
        )
    else:
        context_parts.append(
            "\nWEARABLE HEALTH & ACTIVITY:\nNone — this user has no connected "
            "wearable or health data. Answer health questions with general "
            "guidance and never invent sleep, step, heart-rate, or recovery "
            "numbers."
        )

    # === Self-tracked habits / mood / measurements (read side) ===
    # IMPORTANT: this snippet is byte-for-byte identical to the one in
    # `coach_response_node` — the streamed and buffered coach replies MUST
    # build the same prompt. Edit both together. "" when the user has no
    # self-logged data — then it's simply omitted (the coach must never
    # invent streaks/moods/measurements).
    self_tracking_context = state.get("self_tracking_context")
    if self_tracking_context:
        context_parts.append(f"\n{self_tracking_context}")

    # === Closed-loop form verdicts (video-analyzed) ===
    # Recent form-analysis scores + standout issues + per-exercise trend. Cite
    # ONLY what's here — never invent a verdict. Omitted when the user has no
    # completed form analyses (the block is "" in that case).
    form_verdict_context = state.get("form_verdict_context")
    if form_verdict_context:
        context_parts.append(f"\n{form_verdict_context}")

    # === Cardio activity context (SLICE_COACH) ===
    # Sibling to health_context. Same "cite only what's here" rule applies —
    # never invent pace, distance, VO2max, or training-load numbers.
    cardio_context = state.get("cardio_context")
    if cardio_context:
        context_parts.append(
            f"\nCARDIO CONTEXT:\n{cardio_context}\n"
            "Answer cardio (running / cycling / rowing / swimming / VO2max / "
            "training-load / race / pace) questions using ONLY the numbers "
            "above. Never invent paces, distances, or PRs."
        )

    # === Dietary constraints + today's nutrition (Gap 7/17) — mirrors
    # `coach_response_node`; edit in `format_dietary_and_nutrition_context`. ===
    context_parts.extend(format_dietary_and_nutrition_context(state))

    context = "\n".join(context_parts)

    ai_settings = state.get("ai_settings")
    base_system_prompt = get_coach_system_prompt(ai_settings, locale=state.get("locale") or "en")

    # === Source-bias (SLICE_COACH) ===
    # The UI surface that invoked the coach can request a specific reply
    # shape. Each case adds ONE emphasis sentence — keep them surgical so the
    # base persona prompt stays in charge of voice.
    # NB: written as an if/elif chain (not `match`) because the backend
    # runs on Python 3.9 — keep this as the SINGLE source→bias dispatch.
    _src = state.get("source")
    if _src == "cardio_auto_insight":
        source_bias = (
            "\n\nMODE — CARDIO AUTO-INSIGHT: Return ONE 1-2 sentence "
            "insight that notes what's notable about THIS session vs the "
            "history in CARDIO CONTEXT. Never generic. Examples: 'Same "
            "route as last Tuesday, 7% faster. Hill at km 2 was your "
            "strongest split.' or 'Longest run since March — keep an eye "
            "on recovery this week.' If nothing is notable, reply with "
            "an empty string."
        )
    elif _src == "cardio_detail":
        source_bias = (
            "\n\nFOCUS — CARDIO DETAIL: The user is on a cardio session "
            "detail screen. Reference the THIS session line if present "
            "and keep the reply concrete and short."
        )
    elif _src == "training_load":
        source_bias = (
            "\n\nFOCUS — TRAINING LOAD: Center the reply on the user's "
            "ACWR and weekly volume trend; flag overreaching risk only "
            "when ACWR > 1.5."
        )
    elif _src == "race_predictor":
        source_bias = (
            "\n\nFOCUS — RACE PREDICTOR: Discuss predicted race paces "
            "and how recent sessions support or contradict them."
        )
    elif _src == "refuel":
        source_bias = (
            "\n\nFOCUS — REFUEL: Tie carbohydrate and protein guidance "
            "to the most recent cardio duration / intensity."
        )
    elif _src == "vo2max":
        source_bias = (
            "\n\nFOCUS — VO2MAX: Anchor the reply on the user's VO2max "
            "and its trend; suggest one concrete drill to improve it."
        )
    elif _src == "cardio_pr":
        source_bias = (
            "\n\nFOCUS — CARDIO PR: Celebrate the PR briefly and place "
            "it in the context of recent sessions."
        )
    else:
        source_bias = ""

    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

Reply to the user's message in your own voice. Stay in character — your persona is defined above.{source_bias}""" + _locale_system_suffix(state.get("locale") or "en")

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    return system_prompt, conversation_history


async def coach_response_stream(state: CoachAgentState):
    """Token-streaming variant of `coach_response_node` for the SSE chat path.

    Yields incremental text deltas as Gemini generates the coaching reply,
    instead of returning the whole string at once. Used by
    `LangGraphCoachService.process_message_stream` ONLY for the text-only
    general-coaching path (no media). The media path stays buffered because
    multimodal vision replies are short and don't benefit from streaming.

    Concatenating every yielded chunk reproduces the exact reply that
    `coach_response_node` would have returned in `final_response`.
    """
    logger.info("[Coach Response Stream] Streaming coaching response...")
    gemini_service = GeminiService()
    system_prompt, conversation_history = _build_coach_response_prompt(state)

    async for delta in gemini_service.chat_stream(
        user_message=state["user_message"],
        system_prompt=system_prompt,
        conversation_history=conversation_history,
        user_id=str(state.get("user_id", "")) or None,
    ):
        yield delta


async def coach_response_node(state: CoachAgentState) -> Dict[str, Any]:
    """
    Handle general coaching responses.
    This is the main autonomous response node.
    """
    logger.info("[Coach Response] Generating coaching response...")

    gemini_service = GeminiService()

    context_parts = []

    # Add current date/time
    pacific = pytz.timezone('America/Los_Angeles')
    now = datetime.now(pacific)
    context_parts.append(f"CURRENT DATE/TIME: {now.strftime('%A, %B %d, %Y at %I:%M %p')} (Pacific Time)")

    if state.get("user_profile"):
        profile = state["user_profile"]
        context_parts.append(f"\nUSER PROFILE:")
        context_parts.append(f"- Fitness Level: {profile.get('fitness_level', 'beginner')}")
        context_parts.append(f"- Goals: {', '.join(profile.get('goals', []))}")
        context_parts.extend(format_profile_extras(profile))  # Gap 17: age/sex/size/weight goal

    # === Long-term coach memory (migration 2217) ===
    # Durable facts the user told the coach (injuries/pain, dietary prefs,
    # goals, constraints) + open loops to follow up on — pre-fetched and ranked
    # in langgraph_service so recall is cross-session and cross-day. Empty
    # string when the user has no memory or disabled it. Kept identical in both
    # the streaming (_build_coach_response_prompt) and buffered
    # (coach_response_node) paths — edit both together.
    memory_context = state.get("memory_context")
    if memory_context:
        context_parts.append(f"\n{memory_context}")

    if state.get("workout_schedule"):
        context_parts.append(format_workout_context(state["workout_schedule"]))

    if state.get("rag_context_formatted"):
        context_parts.append(f"\nPrevious context:\n{state['rag_context_formatted']}")

    # === Wearable health & activity context (Phase B2) ===
    # IMPORTANT: this snippet is byte-for-byte identical to the one in
    # `_build_coach_response_prompt` — the streamed and buffered coach replies
    # MUST build the same prompt. Edit both together.
    health_context = state.get("health_context")
    if health_context:
        context_parts.append(
            f"\nWEARABLE HEALTH & ACTIVITY:\n{health_context}\n"
            "You can see this user's wearable health data — answer sleep, "
            "recovery, step, heart-rate, water, and activity questions using "
            "ONLY the numbers above. If a metric is absent here, the user has "
            "no wearable for it — say so plainly and never invent numbers."
        )
    else:
        context_parts.append(
            "\nWEARABLE HEALTH & ACTIVITY:\nNone — this user has no connected "
            "wearable or health data. Answer health questions with general "
            "guidance and never invent sleep, step, heart-rate, or recovery "
            "numbers."
        )

    # === Self-tracked habits / mood / measurements (read side) ===
    # IMPORTANT: this snippet is byte-for-byte identical to the one in
    # `_build_coach_response_prompt` — the streamed and buffered coach replies
    # MUST build the same prompt. Edit both together. "" when the user has no
    # self-logged data — then it's simply omitted (the coach must never
    # invent streaks/moods/measurements).
    self_tracking_context = state.get("self_tracking_context")
    if self_tracking_context:
        context_parts.append(f"\n{self_tracking_context}")

    # === Closed-loop form verdicts (video-analyzed) — mirrors
    # `_build_coach_response_prompt`; edit both together. "" when the user has
    # no completed form analyses (the coach must never invent a verdict). ===
    form_verdict_context = state.get("form_verdict_context")
    if form_verdict_context:
        context_parts.append(f"\n{form_verdict_context}")

    # === Cardio activity context (SLICE_COACH) — mirrors
    # `_build_coach_response_prompt`; edit both together. ===
    cardio_context = state.get("cardio_context")
    if cardio_context:
        context_parts.append(
            f"\nCARDIO CONTEXT:\n{cardio_context}\n"
            "Answer cardio (running / cycling / rowing / swimming / VO2max / "
            "training-load / race / pace) questions using ONLY the numbers "
            "above. Never invent paces, distances, or PRs."
        )

    # === Dietary constraints + today's nutrition (Gap 7/17) — mirrors
    # `_build_coach_response_prompt`; edit in `format_dietary_and_nutrition_context`. ===
    context_parts.extend(format_dietary_and_nutrition_context(state))

    context = "\n".join(context_parts)

    # Get personalized system prompt
    ai_settings = state.get("ai_settings")
    base_system_prompt = get_coach_system_prompt(ai_settings, locale=state.get("locale") or "en")

    # === Source-bias (SLICE_COACH) — mirrors `_build_coach_response_prompt`.
    # NB: written as an if/elif chain (not `match`) because the backend
    # runs on Python 3.9 — keep this as the SINGLE source→bias dispatch.
    _src = state.get("source")
    if _src == "cardio_auto_insight":
        source_bias = (
            "\n\nMODE — CARDIO AUTO-INSIGHT: Return ONE 1-2 sentence "
            "insight that notes what's notable about THIS session vs the "
            "history in CARDIO CONTEXT. Never generic. Examples: 'Same "
            "route as last Tuesday, 7% faster. Hill at km 2 was your "
            "strongest split.' or 'Longest run since March — keep an eye "
            "on recovery this week.' If nothing is notable, reply with "
            "an empty string."
        )
    elif _src == "cardio_detail":
        source_bias = (
            "\n\nFOCUS — CARDIO DETAIL: The user is on a cardio session "
            "detail screen. Reference the THIS session line if present "
            "and keep the reply concrete and short."
        )
    elif _src == "training_load":
        source_bias = (
            "\n\nFOCUS — TRAINING LOAD: Center the reply on the user's "
            "ACWR and weekly volume trend; flag overreaching risk only "
            "when ACWR > 1.5."
        )
    elif _src == "race_predictor":
        source_bias = (
            "\n\nFOCUS — RACE PREDICTOR: Discuss predicted race paces "
            "and how recent sessions support or contradict them."
        )
    elif _src == "refuel":
        source_bias = (
            "\n\nFOCUS — REFUEL: Tie carbohydrate and protein guidance "
            "to the most recent cardio duration / intensity."
        )
    elif _src == "vo2max":
        source_bias = (
            "\n\nFOCUS — VO2MAX: Anchor the reply on the user's VO2max "
            "and its trend; suggest one concrete drill to improve it."
        )
    elif _src == "cardio_pr":
        source_bias = (
            "\n\nFOCUS — CARDIO PR: Celebrate the PR briefly and place "
            "it in the context of recent sessions."
        )
    else:
        source_bias = ""

    # NB: prior suffix said "friendly, helpful coaching advice. Be personable,
    # encouraging…" — this flatly contradicted drill-sergeant/scientist/
    # zen-master personas and was the last instruction the LLM saw, so it
    # dominated. The persona prompt above already specifies voice + tone.
    # Replacement suffix is persona-neutral and pins the persona once more.
    system_prompt = f"""{base_system_prompt}

CONTEXT:
{context}

Reply to the user's message in your own voice. Stay in character — your persona is defined above.{source_bias}""" + _locale_system_suffix(state.get("locale") or "en")

    conversation_history = [
        {"role": msg["role"], "content": msg["content"]}
        for msg in state.get("conversation_history", [])
    ]

    # Check if media is present for vision-aware response
    has_media = (
        state.get("image_base64")
        or state.get("media_ref")
        or state.get("media_refs")
    )

    if has_media:
        # Vision-aware response using multimodal Gemini
        media_content_type = state.get("media_content_type", "unknown")
        vision_hints = {
            "progress_photo": "Analyze the physique in this progress photo. Note visible muscle development, body composition, and provide encouraging, constructive feedback. Compare to fitness goals if known.",
            # Issue 2: when the user attaches a gym-equipment photo (with or
            # without an explicit "what's this?" prompt) the coach should
            # surface the structured identify_equipment result. The actual
            # Vision-classify + library-match runs server-side (the
            # identify_equipment tool wraps equipment_snap_core); your job
            # here is to write a short caption-style reply that pairs with
            # the EquipmentMatchCard the frontend will render from the
            # tool's action_data. Mention the canonical equipment name if
            # you can read it in the image, suggest 2-3 exercises that
            # belong on it, and end with "Want to add or swap one of these
            # into your workout?". Keep it under 60 words — the card
            # carries the visual detail.
            "gym_equipment": "Identify the gym equipment or machine in this image. Briefly name it, list 2-3 exercises that belong on it, and prompt the user to add/swap into their workout. The Equipment Match card will render with full image+name+actions, so keep your text tight (≤60 words).",
            "document": "Read and analyze this fitness-related document (workout plan, medical note, etc.). Provide relevant coaching advice based on its contents.",
        }
        vision_hint = vision_hints.get(media_content_type, "Analyze the image and provide relevant coaching advice.")

        # Add vision hint to system prompt
        vision_system_prompt = f"""{system_prompt}

VISION CONTEXT:
You have been sent an image. {vision_hint}
Respond naturally as a coach who can see the image."""

        # Resolve image bytes
        image_bytes = None
        image_mime = "image/jpeg"
        try:
            if state.get("image_base64"):
                image_bytes = base64.b64decode(state["image_base64"])
            elif state.get("media_refs"):
                ref = state["media_refs"][0]
                s3_key = ref.get("s3_key")
                image_mime = ref.get("mime_type", "image/jpeg")
                if s3_key:
                    from services.vision_service import get_vision_service
                    vision_svc = get_vision_service()
                    image_bytes = await vision_svc._download_image_from_s3(s3_key)
            elif state.get("media_ref"):
                ref = state["media_ref"]
                s3_key = ref.get("s3_key")
                image_mime = ref.get("mime_type", "image/jpeg")
                if s3_key:
                    from services.vision_service import get_vision_service
                    vision_svc = get_vision_service()
                    image_bytes = await vision_svc._download_image_from_s3(s3_key)
        except Exception as e:
            logger.warning(f"[Coach Response] Failed to resolve image: {e}", exc_info=True)

        if image_bytes:
            # Build multimodal content
            image_part = types.Part.from_bytes(data=image_bytes, mime_type=image_mime)

            # Build conversation as text
            conv_text = ""
            for msg in conversation_history:
                role = msg.get("role", "user")
                conv_text += f"{role}: {msg.get('content', '')}\n"

            from core.config import get_settings as get_app_settings
            app_settings = get_app_settings()

            vision_response = await gemini_generate_with_retry(
                model=app_settings.gemini_model,
                contents=[
                    f"{vision_system_prompt}\n\nConversation:\n{conv_text}\n\nUser: {state['user_message']}",
                    image_part,
                ],
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    max_output_tokens=2000,
                ),
                user_id=str(state.get("user_id", "")),
                method_name="coach_respond",
            )
            response = vision_response.text
            logger.info(f"[Coach Response] Vision response: {response[:100]}...")
        else:
            # Fallback to text-only if image resolution failed
            logger.warning("[Coach Response] Media indicated but image bytes not resolved, falling back to text")
            response = await gemini_service.chat(
                user_message=state["user_message"],
                system_prompt=system_prompt,
                conversation_history=conversation_history,
            )
    else:
        response = await gemini_service.chat(
            user_message=state["user_message"],
            system_prompt=system_prompt,
            conversation_history=conversation_history,
        )

    logger.info(f"[Coach Response] Response: {response[:100]}...")

    return {
        "ai_response": response,
        "final_response": response,
    }
