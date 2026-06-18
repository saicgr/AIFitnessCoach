"""
State schema for the Coach Agent.
"""
from typing import TypedDict, List, Dict, Any, Optional, Union
from models.chat import CoachIntent


class CoachAgentState(TypedDict):
    """
    State for the general coach agent.
    Handles general fitness coaching, greetings, and app control.
    """
    # Input (from ChatRequest)
    user_message: str
    user_id: Union[str, int]
    user_profile: Optional[Dict[str, Any]]
    current_workout: Optional[Dict[str, Any]]
    workout_schedule: Optional[Dict[str, Any]]
    conversation_history: List[Dict[str, str]]

    # Media (for progress photos, documents, gym equipment)
    image_base64: Optional[str]
    media_ref: Optional[Dict[str, Any]]
    media_refs: Optional[List[Dict[str, Any]]]
    media_content_type: Optional[str]

    # AI personality settings
    ai_settings: Optional[Dict[str, Any]]

    # Intent extraction results
    intent: Optional[CoachIntent]
    setting_name: Optional[str]
    setting_value: Optional[bool]
    setting_value_text: Optional[str]
    destination: Optional[str]
    water_goal_glasses: Optional[int]
    weight_value: Optional[float]

    # Reminder scheduling (SCHEDULE_REMINDER). Time is captured as EITHER a
    # relative delay OR an absolute clock time; coach_action_node resolves it to
    # an absolute timestamp against `user_tz`.
    reminder_text: Optional[str]
    reminder_title: Optional[str]
    reminder_delay_minutes: Optional[int]
    reminder_time_hour: Optional[int]
    reminder_time_minute: Optional[int]
    reminder_recurrence: Optional[str]
    reminder_weekday: Optional[int]
    # Live IANA timezone of the user's phone, threaded from the HTTP layer so
    # reminder times resolve to the user's local clock.
    user_tz: Optional[str]

    # RAG context
    rag_documents: List[Dict[str, Any]]
    rag_context_formatted: str

    # Wearable health & activity context (Phase B2) — a compact prompt string
    # of the user's sleep / recovery / steps / heart-rate picture, pre-fetched
    # in `_build_agent_state`. Empty string when the user has no wearable data
    # or has not consented (a NORMAL state — the coach must then never invent
    # numbers).
    health_context: Optional[str]

    # Self-tracked habits / mood / body-measurements summary (user-logged via
    # chat or the dedicated screens). "" when the user has no such data — the
    # coach must then never invent streaks/measurements. Built by
    # services.coach.self_tracking_context.build_self_tracking_context.
    self_tracking_context: Optional[str]

    # Closed-loop form verdicts: the user's recent video-analyzed form scores +
    # standout issues + per-exercise trend, so the coach can reference real form
    # findings ("your squat depth regressed — here's a cue"). "" when the user
    # has no completed form analyses — the coach must then never invent a verdict.
    # Built by services.coach.form_verdict_context.build_form_verdict_context.
    form_verdict_context: Optional[str]

    # Cardio activity context (SLICE_COACH) — compact prompt string of the
    # user's recent cardio picture (sessions, VO2max, training-load ACWR,
    # PRs, and optionally a THIS-session focus line). Pre-fetched by the
    # endpoint that invokes the agent (e.g. /coach/cardio-insight). None
    # when the user has no cardio history — the coach must then answer
    # generally and never invent pace/distance numbers.
    cardio_context: Optional[str]

    # Dietary constraints (Gap 7/17) — `resolve_dietary_constraints` output:
    # the HARD vegan/allergy/restriction rule unioned across
    # nutrition_preferences.diet_type + dietary_restrictions[] + allergies +
    # coach_memory, so the coach never suggests a violating food even in
    # general chat (the user may be "vegan" only in settings, never in chat).
    dietary_constraints: Optional[Dict[str, Any]]

    # Today's nutrition (Gap 17) — `fetch_daily_nutrition_context` output so the
    # coach can answer "what should I eat?" with the real calorie/macro
    # remainder in GENERAL chat, not only the @nutrition agent. None when the
    # user has no targets / logged nothing — the coach must then never invent
    # macros.
    daily_nutrition_context: Optional[Dict[str, Any]]

    # Cycle phase (Gap 17) — phase string + compact prompt block, mirrored from
    # the nutrition/workout agents so the coach is cycle-aware in general chat.
    # None when the user has no cycle data. Never raw hormone_logs.
    cycle_phase: Optional[str]
    cycle_context: Optional[Dict[str, Any]]

    # Structured injury directives (Gap 17) — `resolve_injury_directives` output
    # (phase/severity/allowed_intensity per body part) so the coach respects the
    # SAME deterministic safety the workout generator uses, not just free-text
    # memory. None/empty when healthy.
    injury_directives: Optional[Dict[str, Any]]

    # Race/event periodization block (Gap 11) — `format_race_context_for_ai`
    # output: phase + this-week focus + today's auto-adjusted recommendation.
    # "" when the user has no dated race goal.
    race_context: Optional[str]

    # Surface bias — identifies WHICH UI surface invoked the coach so the
    # prompt can add a one-sentence emphasis (e.g. cardio_auto_insight asks
    # for a single 1-2 sentence insight). Optional; absence = no bias.
    source: Optional[str]

    # Response generation
    ai_response: str
    final_response: str

    # Output
    action_data: Optional[Dict[str, Any]]
    rag_context_used: bool
    similar_questions: List[str]

    # Error handling
    error: Optional[str]

    # i18n — ISO 639-1 locale code. Injected into system prompt.
    locale: Optional[str]
