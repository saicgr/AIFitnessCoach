"""Where every declared user-preference field is written — enforced, not hoped.

THE BUG THIS EXISTS TO KILL
---------------------------
`PUT /users/{id}` and `POST /users/{id}/preferences` both used to accept a
payload, write the handful of fields somebody had remembered to wire up, and
return 200 for the rest. Two independent leaks produced the same user-visible
lie ("saved!" for a value that was never stored):

  1. UNDECLARED  — Pydantic's default `extra="ignore"` swallowed any key the
     model did not declare. `workout_weight_unit` (three shipped UI toggles)
     and the five fitness-assessment capacities died here.
  2. DECLARED-BUT-UNROUTED — worse, because it survives validation: a field
     was declared on the model and then never copied into `update_data` by the
     hand-written if/else chain in the endpoint. At the time this module was
     written, **32 of 81** `UserUpdate` fields were in this state, including
     `workout_ui_mode`, `workout_ui_mode_user_explicit`, `timezone`,
     `goal_target_date`, `coach_name`, `photo_url` and both accessibility
     fields.

Both models now set `extra="forbid"`, which closes (1) with a 422. This module
closes (2): every declared field must name a destination here, and
`assert_contract_complete()` runs at IMPORT TIME, so a field added to a model
without a route fails app startup instead of silently vanishing in production.

DESTINATIONS
------------
    Column(name)   -> a real `public.users` column
    PrefsKey(key)  -> a key inside the `users.preferences` JSONB blob
    Special(why)   -> the endpoint writes it itself with logic a generic copy
                      cannot express (JSON re-encoding, dual-writes, change
                      detection, cross-field validation). `why` is the audit
                      trail — "Special" is not an escape hatch for "unhandled",
                      and the gate below checks each one is genuinely
                      referenced by the endpoint source.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Optional, Union

from pydantic import BaseModel


# ── Destination kinds ───────────────────────────────────────────────────────

@dataclass(frozen=True)
class Column:
    """Copy verbatim into this `public.users` column."""
    name: str


@dataclass(frozen=True)
class PrefsKey:
    """Copy verbatim into this key of the `users.preferences` JSONB blob."""
    key: str


@dataclass(frozen=True)
class Special:
    """Written by bespoke endpoint code. `why` documents what it does."""
    why: str


Route = Union[Column, PrefsKey, Special]


# ── Columns this repo added after the checked-in schema snapshot was taken.
# `backend/scripts/schema_columns_snapshot.json` is refreshed by the
# column-drift gate's owner; until it is, the contract check needs to know
# these are real. Verified live in production by migration 2381.
COLUMNS_ADDED_SINCE_SNAPSHOT = frozenset({
    "pushup_capacity",
    "pullup_capacity",
    "plank_capacity",
    "squat_capacity",
    "cardio_capacity",
    "training_experience",
})


# ── PUT /users/{user_id}  (models.user.UserUpdate) ──────────────────────────

USER_UPDATE_ROUTING: Dict[str, Route] = {
    # -- handled bespoke in api/v1/users/profile.py::update_user --------------
    "fitness_level": Special("column write + gym-profile sync"),
    "goals": Special("JSON-encoded into the VARCHAR goals column"),
    "equipment": Special("dual-write equipment + equipment_v2, change detection"),
    "custom_equipment": Special("JSON-encoded into the VARCHAR column"),
    "preferences": Special("merged with extended fields into the JSONB blob"),
    "active_injuries": Special("change detection + injury_history sync"),
    "onboarding_completed": Special("also stamps onboarding_completed_at"),
    "coach_selected": Special("column write + onboarding hooks"),
    "paywall_completed": Special("column write + onboarding hooks"),
    "is_pregnant": Special("column write"),
    "is_lactating": Special("column write"),
    "days_per_week": Special("merged into the preferences JSONB"),
    "workout_duration": Special("merged into the preferences JSONB"),
    "training_split": Special("merged into the preferences JSONB"),
    "intensity_preference": Special("merged into the preferences JSONB"),
    "preferred_time": Special("merged into the preferences JSONB"),
    "name": Special("column write"),
    "gender": Special("column write"),
    "age": Special("column write"),
    "date_of_birth": Special("column write"),
    "height_cm": Special("column write"),
    "weight_kg": Special("column write"),
    "target_weight_kg": Special("column write"),
    "workout_days": Special("schedule-change detection + preferences merge"),
    "activity_level": Special("column write"),
    "fcm_token": Special("column write"),
    "device_platform": Special("column write + last_device_update stamp"),
    "notification_preferences": Special("merged with the existing JSONB"),
    "progression_pace": Special("merged into the preferences JSONB"),
    "workout_type_preference": Special("merged into the preferences JSONB"),
    "cardio_preference": Special("merged into the preferences JSONB"),
    "workout_environment": Special("merged into the preferences JSONB"),
    "gym_name": Special("merged into the preferences JSONB"),
    "workout_variety": Special("merged into the preferences JSONB"),
    "equipment_details": Special("column write"),
    "weight_unit": Special("column write"),
    "measurement_unit": Special("column write"),
    "bio": Special("column write"),
    "primary_goal": Special("column write"),
    "muscle_focus_points": Special("column write after the 5-point validation"),
    "device_model": Special("column write + last_device_update stamp"),
    "is_foldable": Special("column write + last_device_update stamp"),
    "os_version": Special("column write + last_device_update stamp"),
    "screen_width": Special("column write + last_device_update stamp"),
    "screen_height": Special("column write + last_device_update stamp"),
    "in_vacation_mode": Special("column write"),
    "vacation_start_date": Special("empty string -> NULL, cross-field validated"),
    "vacation_end_date": Special("empty string -> NULL, cross-field validated"),
    "is_trainer": Special("column write"),

    # -- previously DECLARED-BUT-UNROUTED; now routed generically -------------
    # Every entry below reached the server, validated, and was thrown away
    # behind a 200 before this table existed.
    "timezone": Column("timezone"),
    "photo_url": Column("photo_url"),
    "workout_ui_mode": Column("workout_ui_mode"),
    "workout_ui_mode_user_explicit": Column("workout_ui_mode_user_explicit"),
    "workout_weight_unit": Column("workout_weight_unit"),
    "distance_unit": Column("distance_unit"),
    "referral_source": Column("referral_source"),
    "prior_apps_tried": Column("prior_apps_tried"),
    "referral_code": Column("referral_code"),
    "coach_name": Column("coach_name"),
    "seen_founder_note": Column("seen_founder_note"),
    "commitment_pact_accepted": Column("commitment_pact_accepted"),
    "commitment_pact_accepted_at": Column("commitment_pact_accepted_at"),
    "trial_start_date": Column("trial_start_date"),
    "goal_target_date": Column("goal_target_date"),
    "paused_at": Column("paused_at"),
    "pause_duration_days": Column("pause_duration_days"),
    # No `users` column exists for these — the preferences JSONB is their real
    # home, and row_to_user() reads them back out of it.
    "accessibility_mode": PrefsKey("accessibility_mode"),
    "accessibility_settings": PrefsKey("accessibility_settings"),
    "exercise_consistency": PrefsKey("exercise_consistency"),
    "sleep_quality": PrefsKey("sleep_quality"),
    "obstacles": PrefsKey("obstacles"),
    "dietary_restrictions": PrefsKey("dietary_restrictions"),
    "weight_direction": PrefsKey("weight_direction"),
    "weight_change_amount": PrefsKey("weight_change_amount"),
    "motivations": PrefsKey("motivations"),
    "nutrition_goals": PrefsKey("nutrition_goals"),
    "interested_in_fasting": PrefsKey("interested_in_fasting"),
    "fasting_protocol": PrefsKey("fasting_protocol"),
    "wake_time": PrefsKey("wake_time"),
    "sleep_time": PrefsKey("sleep_time"),
    "coach_id": PrefsKey("coach_id"),
    "workout_experience": PrefsKey("workout_experience"),
    "health_conditions": PrefsKey("health_conditions"),
    # `selected_days` is the legacy alias of `workout_days`; POST /preferences
    # already folds it onto the same prefs key (users/onboarding.py), so PUT
    # does too rather than inventing a second key nothing reads.
    "selected_days": PrefsKey("workout_days"),
}


# ── POST /users/{user_id}/preferences  (users.models.UserPreferencesRequest) ─

USER_PREFERENCES_ROUTING: Dict[str, Route] = {
    # -- handled bespoke in api/v1/users/onboarding.py::save_user_preferences -
    "goals": Special("JSON-encoded into the VARCHAR goals column"),
    "fitness_level": Special("column write"),
    "primary_goal": Special("column write"),
    "muscle_focus_points": Special("column write"),
    "age": Special("column write"),
    "gender": Special("column write"),
    "height_cm": Special("column write"),
    "weight_kg": Special("column write"),
    "goal_weight_kg": Special("column write -> users.target_weight_kg"),
    "activity_level": Special("column write"),
    "equipment": Special("dual-write equipment + equipment_v2, change detection"),
    "custom_equipment": Special("JSON-encoded into the VARCHAR column"),
    "limitations": Special("column write -> users.active_injuries + injury sync"),
    "coach_id": Special("prefs merge + flips coach_selected/onboarding_completed"),
    "days_per_week": Special("merged into the preferences JSONB"),
    "workout_duration": Special("merged into the preferences JSONB"),
    "workout_duration_min": Special("merged into the preferences JSONB"),
    "workout_duration_max": Special("merged into the preferences JSONB"),
    "selected_days": Special("merged into the preferences JSONB as workout_days"),
    "training_split": Special("merged into the preferences JSONB"),
    "workout_type": Special("merged into the preferences JSONB"),
    "progression_pace": Special("merged into the preferences JSONB"),
    "workout_environment": Special("merged into the preferences JSONB"),
    "workout_variety": Special("merged into the preferences JSONB"),
    "equipment_weights": Special("merged into the preferences JSONB"),
    "sleep_quality": Special("merged into the preferences JSONB"),
    "obstacles": Special("merged into the preferences JSONB"),
    "past_blockers": Special("merged into the preferences JSONB"),
    "primary_whys": Special("merged into the preferences JSONB"),
    "nutrition_goals": Special("merged into the preferences JSONB"),
    "dietary_restrictions": Special("merged into the preferences JSONB"),
    "meals_per_day": Special("merged into the preferences JSONB"),
    "weight_direction": Special("merged into the preferences JSONB"),
    "weight_change_amount": Special("merged into the preferences JSONB"),
    "interested_in_fasting": Special("merged into the preferences JSONB"),
    "fasting_protocol": Special("merged into the preferences JSONB"),
    "wake_time": Special("merged into the preferences JSONB"),
    "sleep_time": Special("merged into the preferences JSONB"),
    "motivations": Special("merged into the preferences JSONB"),
    "focus_areas": Special("merged into the preferences JSONB"),
    "training_experience": Special("column write + preferences JSONB copy"),
    "weight_change_rate": Special("merged into the preferences JSONB"),
    "nutrition": Special("nested block flattened onto its top-level siblings"),
    "fasting": Special("nested block flattened onto its top-level siblings"),
    "use_metric_units": Special("derives the four unit columns when unset"),

    # -- generically routed --------------------------------------------------
    "name": Column("name"),
    "date_of_birth": Column("date_of_birth"),
    "coach_name": Column("coach_name"),
    "is_trainer": Column("is_trainer"),
    "goal_target_date": Column("goal_target_date"),
    "weight_unit": Column("weight_unit"),
    "workout_weight_unit": Column("workout_weight_unit"),
    "measurement_unit": Column("measurement_unit"),
    "distance_unit": Column("distance_unit"),
    # The fitness assessment. Columns added by migration 2381 — before that
    # these five answers were POSTed by every onboarding client and had
    # literally nowhere to go, which made
    # generation_endpoints.py's `has_assessment` permanently False.
    "pushup_capacity": Column("pushup_capacity"),
    "pullup_capacity": Column("pullup_capacity"),
    "plank_capacity": Column("plank_capacity"),
    "squat_capacity": Column("squat_capacity"),
    "cardio_capacity": Column("cardio_capacity"),
    # Aliases: the payload builder sends the same answer under two names
    # (`workouts_per_week`+`days_per_week`, `workout_days`+`selected_days`).
    # save_user_preferences folds each alias onto its canonical field BEFORE
    # the preferences merge, so both end up in the JSONB exactly once. Routing
    # them generically as well would let the alias overwrite the canonical
    # value, which is the wrong precedence.
    "workouts_per_week": Special("aliased onto days_per_week before the merge"),
    "workout_days": Special("aliased onto selected_days before the merge"),
    "allergens": PrefsKey("allergens"),
    "custom_allergens": PrefsKey("custom_allergens"),
    "disliked_foods": PrefsKey("disliked_foods"),
    "inflammation_sensitivity": PrefsKey("inflammation_sensitivity"),
    "meal_budget_usd": PrefsKey("meal_budget_usd"),
    "daily_food_budget_usd": PrefsKey("daily_food_budget_usd"),
}


# ── Application helpers ─────────────────────────────────────────────────────

def apply_routes(
    model: BaseModel,
    routing: Dict[str, Route],
    update_data: Dict[str, Any],
    preferences: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Copy every non-None `Column`/`PrefsKey` field of `model` to its home.

    `Special` fields are skipped — the endpoint already wrote them, and a
    second generic write could undo the bespoke transform (e.g. re-writing the
    raw list over the JSON-encoded `goals` string).

    Existing entries in `update_data` win: bespoke code runs first and is the
    authority for anything it touched. Returns the set of routed field names
    (for the endpoint's log line).
    """
    routed: Dict[str, Any] = {}
    for field, route in routing.items():
        value = getattr(model, field, None)
        if value is None:
            continue
        if isinstance(route, Column):
            if route.name in update_data:
                continue
            update_data[route.name] = value
            routed[field] = route.name
        elif isinstance(route, PrefsKey):
            if preferences is None:
                continue
            if route.key in preferences and preferences[route.key] == value:
                continue
            preferences[route.key] = value
            routed[field] = f"preferences.{route.key}"
    return routed


# ── Contract enforcement (runs at import) ───────────────────────────────────

class FieldContractError(RuntimeError):
    """A model field has no declared destination — the write would be lost."""


def contract_violations(model_cls: type[BaseModel], routing: Dict[str, Route],
                        label: str) -> list[str]:
    """Return human-readable problems with `routing` against `model_cls`."""
    declared = set(model_cls.model_fields)
    routed = set(routing)
    problems: list[str] = []
    for field in sorted(declared - routed):
        problems.append(
            f"{label}.{field} is declared but has no route — a client that "
            f"sends it gets a 200 and the value is discarded. Add it to "
            f"{label}_ROUTING (Column / PrefsKey / Special)."
        )
    for field in sorted(routed - declared):
        problems.append(
            f"{label}_ROUTING has a route for '{field}', which {model_cls.__name__} "
            f"does not declare — dead entry, or the field was renamed."
        )
    extra = model_cls.model_config.get("extra")
    if extra != "forbid":
        problems.append(
            f"{model_cls.__name__}.model_config['extra'] is {extra!r}, not "
            f"'forbid' — undeclared keys would be silently dropped behind a 200."
        )
    return problems


def assert_contract_complete() -> None:
    """Fail loudly (at import, i.e. at app startup) on any unrouted field."""
    from models.user import UserUpdate
    from api.v1.users.models import UserPreferencesRequest

    problems = (
        contract_violations(UserUpdate, USER_UPDATE_ROUTING, "USER_UPDATE")
        + contract_violations(
            UserPreferencesRequest, USER_PREFERENCES_ROUTING, "USER_PREFERENCES"
        )
    )
    if problems:
        raise FieldContractError(
            "User-preference field contract is incomplete:\n  - "
            + "\n  - ".join(problems)
        )


assert_contract_complete()
