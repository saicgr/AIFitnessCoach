"""Regression gate — the injury-safety chokepoint must cover EVERY workout path.

Covers E2E register rows 83-88:

  row 83  one normaliser, shared by every path (plural app ids → singular joints)
  row 84  nothing may be appended to a workout AFTER the terminal guard
  row 85  /workouts/quick runs the deterministic gate (prompt-only was the bug)
  row 86  the 11 muscle-area chips are filtered deterministically, not just
          mentioned in the prompt
  row 88  swap surfaces screen the replacement exercise

Every test here is DB-free: the safety-index lookup and the safe-candidate fetch
are patched, so the rules — not the data — are what is under test. The live-DB
proof for these rows is in the fix report (Horizontal Leg Press knee_safe=FALSE,
Barbell Front Squat knee_safe=FALSE).

Run:
    cd backend && .venv312/bin/python -m pytest tests/test_injury_terminal_guard.py -v
"""
from __future__ import annotations

import ast
from pathlib import Path
from typing import Any, Dict, List
from unittest.mock import AsyncMock, patch

import pytest

BACKEND_ROOT = Path(__file__).resolve().parent.parent

from services.workout_safety_validator import (  # noqa: E402
    SUPPORTED_INJURY_JOINTS,
    UserSafetyContext,
    canonicalize_injury_token,
    canonicalize_injury_tokens,
    normalize_injury_tokens,
)
from services.exercise_rag.injury_guard import (  # noqa: E402
    InjuryUnsafeExerciseError,
    enforce_injury_safety,
    filter_injury_unsafe,
    resolve_avoided_muscle_tokens,
    resolve_user_chosen_exercise,
    screen_exercise_for_injury,
)

_GUARD = "services.exercise_rag.injury_guard"


# ---------------------------------------------------------------------------
# row 83 — ONE normaliser
# ---------------------------------------------------------------------------
def test_one_normaliser_maps_every_app_injury_id():
    """The 8 joint chips the app actually stores (PLURAL) must resolve."""
    app_joint_ids = [
        "knees", "shoulders", "elbows", "wrists", "ankles", "hips",
        "neck", "lower_back",
    ]
    resolved = normalize_injury_tokens(app_joint_ids)
    assert len(resolved) == 8, resolved
    assert set(resolved) == set(SUPPORTED_INJURY_JOINTS)


def test_one_normaliser_handles_legacy_and_quick_chip_spellings():
    """Quick Workout ships Title-Case SINGULAR chips ('Knee', 'Lower Back')."""
    assert canonicalize_injury_token("Knee") == "knee"
    assert canonicalize_injury_token("Lower Back") == "lower_back"
    assert canonicalize_injury_token("  KNEES ") == "knee"
    assert canonicalize_injury_token("back") == "lower_back"
    # Sentinels never become injuries.
    assert canonicalize_injury_token("none") == ""
    assert canonicalize_injury_token(None) == ""


def test_context_delegates_to_the_shared_normaliser():
    """UserSafetyContext must not carry a SECOND copy of the alias logic."""
    ctx = UserSafetyContext(
        injuries=["Knees", "lower back", "abs"], difficulty="beginner",
        equipment=[], user_id="t",
    )
    assert ctx.normalized_injuries() == normalize_injury_tokens(ctx.injuries)
    # Muscle chips are NOT joints — dropped by the joint whitelist ...
    assert "abs" not in ctx.normalized_injuries()
    # ... but preserved by the canonicalizer the guard uses for muscle areas.
    assert "abs" in canonicalize_injury_tokens(ctx.injuries)


# ---------------------------------------------------------------------------
# row 86 — muscle-area chips are enforced, not just prompted
# ---------------------------------------------------------------------------
def test_muscle_tokens_exclude_joints():
    """A knee injury must NOT hard-drop every quad/ham/glute exercise — joints
    are governed by the vetted <joint>_safe columns."""
    assert resolve_avoided_muscle_tokens(["knees", "lower_back", "shoulders"]) == []


def test_muscle_tokens_resolve_for_area_chips():
    tokens = resolve_avoided_muscle_tokens(["Abs", "quads", "biceps"])
    assert "abdominals" in tokens and "quadriceps" in tokens and "biceps" in tokens


@pytest.mark.asyncio
async def test_row86_muscle_area_chip_actually_filters():
    workout: List[Dict[str, Any]] = [
        {"name": "Barbell Bench Press", "target_muscle": "chest", "sets": 4, "reps": 8},
        {"name": "Dumbbell Bicep Curl", "target_muscle": "biceps", "sets": 3, "reps": 12},
        {"name": "Lat Pulldown", "target_muscle": "lats", "sets": 3, "reps": 10},
    ]
    with patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())), \
         patch(f"{_GUARD}.fetch_safe_candidates", AsyncMock(return_value=[
             {"name": "Seated Cable Row", "target_muscle": "upper back",
              "equipment": "cable", "movement_pattern": "horizontal_pull"},
         ])):
        safe, dropped, added = await enforce_injury_safety(
            workout, ["biceps"], equipment=["dumbbell"], focus_areas=[],
            difficulty_ceiling="intermediate", user_id="t",
        )
    assert dropped == ["Dumbbell Bicep Curl"]
    assert added == ["Seated Cable Row"]
    names = [e["name"] for e in safe]
    assert "Dumbbell Bicep Curl" not in names
    assert "Barbell Bench Press" in names and "Lat Pulldown" in names


@pytest.mark.asyncio
async def test_row86_guard_no_longer_returns_early_for_muscle_only_limitation():
    """Before the fix the guard returned immediately when no <joint>_safe column
    resolved, so an Abs-only limitation was a total no-op."""
    workout = [{"name": "Hanging Leg Raise", "target_muscle": "abdominals"}]
    with patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())), \
         patch(f"{_GUARD}.fetch_safe_candidates", AsyncMock(return_value=[])):
        safe, dropped, _added = await enforce_injury_safety(
            workout, ["abs"], user_id="t",
        )
    assert dropped == ["Hanging Leg Raise"]
    assert safe == []


@pytest.mark.asyncio
async def test_backfill_never_reintroduces_an_avoided_muscle():
    workout = [
        {"name": "Dumbbell Bicep Curl", "target_muscle": "biceps", "sets": 3, "reps": 12},
        {"name": "Plank", "target_muscle": "abdominals", "sets": 3, "reps": 1},
    ]
    with patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())), \
         patch(f"{_GUARD}.fetch_safe_candidates", AsyncMock(return_value=[
             {"name": "Hammer Curl", "target_muscle": "biceps"},        # avoided
             {"name": "Goblet Squat", "target_muscle": "quadriceps"},   # fine
         ])):
        safe, dropped, added = await enforce_injury_safety(
            workout, ["biceps"], user_id="t",
        )
    assert dropped == ["Dumbbell Bicep Curl"]
    assert added == ["Goblet Squat"]
    assert "Hammer Curl" not in [e["name"] for e in safe]


# ---------------------------------------------------------------------------
# row 84 — nothing may be appended after the terminal guard
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_row84_contraindicated_finisher_is_stripped():
    """The equipment finisher /generate-stream appends AFTER the guard.

    'Horizontal Leg Press' is row 1 of the alphabetically-sorted 'Leg Press
    Machine' compound pool and is knee_safe=FALSE in the live safety index.
    """
    guarded_workout = [
        {"name": "Glute Bridge", "target_muscle": "glutes", "sets": 3, "reps": 12},
        {"name": "Seated Cable Row", "target_muscle": "upper back", "sets": 3, "reps": 10},
    ]
    finisher = {
        "name": "Horizontal Leg Press", "equipment": "Leg Press Machine",
        "target_muscle": "Quadriceps (Quadriceps Femoris), Glutes",
        "is_finisher": True, "is_timed": True, "duration_seconds": 300, "sets": 1,
    }
    appended = guarded_workout + [finisher]

    with patch(f"{_GUARD}._unsafe_name_set",
               AsyncMock(return_value={"horizontal leg press"})):
        kept, dropped = await filter_injury_unsafe(appended, ["knees"])

    assert dropped == ["Horizontal Leg Press"]
    assert [e["name"] for e in kept] == ["Glute Bridge", "Seated Cable Row"]


@pytest.mark.asyncio
async def test_row84_finisher_survives_an_unrelated_injury():
    """The screen must not over-drop: a shoulder injury leaves a leg press alone."""
    finisher = {"name": "Horizontal Leg Press", "equipment": "Leg Press Machine",
                "target_muscle": "Quadriceps"}
    with patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())):
        kept, dropped = await filter_injury_unsafe([finisher], ["shoulders"])
    assert dropped == []
    assert len(kept) == 1


def test_row84_every_exercise_appender_is_screened():
    """Class-wide gate: any function that appends exercises must screen them.

    Ordering discipline alone is not enough — `workout_builder.build_adapted_workout`
    appends a finisher in a file with no guard at all, which an "is the guard
    above me?" check would happily pass.

    RED at HEAD is expected until the three appender call sites
    (generation_streaming.py, generation_endpoints.py, workout_builder.py) route
    their finisher through `filter_injury_unsafe` — those files are owned by
    another workstream; see `cross_domain_requests` in the fix report.
    """
    import importlib.util

    spec = importlib.util.spec_from_file_location(
        "_audit_injury_guard_terminal",
        BACKEND_ROOT / "scripts" / "audit_injury_guard_terminal.py",
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    violations = mod.audit(BACKEND_ROOT)
    assert violations == [], (
        "Exercises are appended to a workout with no injury screen afterwards:\n  "
        + "\n  ".join(violations)
    )


# ---------------------------------------------------------------------------
# row 88 — swap surfaces screen the replacement
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_row88_swap_screen_blocks_contraindicated_replacement():
    with patch(f"{_GUARD}._unsafe_name_set",
               AsyncMock(return_value={"barbell front squat"})):
        reason = await screen_exercise_for_injury(
            {"name": "Barbell Front Squat", "target_muscle": "Quadriceps"}, ["knees"],
        )
    assert reason == "safety_index"


@pytest.mark.asyncio
async def test_row88_swap_screen_allows_a_safe_replacement():
    with patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())):
        reason = await screen_exercise_for_injury(
            {"name": "Glute Bridge", "target_muscle": "glutes"}, ["knees"],
        )
    assert reason is None


@pytest.mark.asyncio
async def test_row88_swap_screen_is_a_noop_without_injuries():
    reason = await screen_exercise_for_injury({"name": "Barbell Front Squat"}, [])
    assert reason is None


# ---------------------------------------------------------------------------
# rows 85 + 88 — every generating/mutating path reaches the chokepoint
# ---------------------------------------------------------------------------
def _calls_in_file(rel_path: str) -> set:
    tree = ast.parse((BACKEND_ROOT / rel_path).read_text(encoding="utf-8"))
    names = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            fn = node.func
            if isinstance(fn, ast.Name):
                names.add(fn.id)
            elif isinstance(fn, ast.Attribute):
                names.add(fn.attr)
    return names


@pytest.mark.parametrize(
    "rel_path",
    [
        "api/v1/workouts/quick.py",                    # row 85 (generate + save)
        "api/v1/workouts/swap_variant.py",             # row 88 (variant swap)
        "api/v1/workouts/generation_streaming.py",     # /generate-stream
        "api/v1/workouts/generation_endpoints.py",     # /generate + /regenerate
    ],
)
def test_every_workout_producing_path_calls_the_chokepoint(rel_path):
    assert "enforce_injury_safety" in _calls_in_file(rel_path), (
        f"{rel_path} produces or mutates a persisted workout but never calls "
        f"enforce_injury_safety — the deterministic injury gate."
    )


def test_quick_path_uses_the_shared_canonicalizer_not_a_second_one():
    src = (BACKEND_ROOT / "api/v1/workouts/quick.py").read_text(encoding="utf-8")
    assert "canonicalize_injury_tokens" in src
    # It must read the PROFILE's injuries too — a broken client chip list can no
    # longer disable the gate (row 85's second half).
    assert "get_active_injuries_with_muscles" in src


def test_quick_guard_is_the_last_mutation_before_persist():
    """In /quick the guard must run after every filter, not before them."""
    src = (BACKEND_ROOT / "api/v1/workouts/quick.py").read_text(encoding="utf-8")
    guard_at = src.index("enforce_injury_safety(\n")
    for earlier in (
        "filter_main_exercises(",
        "filter_by_workout_type_muscles(",
        "reorder_exercises_canonically(",
        "validate_and_cap_exercise_parameters(",
    ):
        assert src.index(earlier) < guard_at, (
            f"{earlier} runs AFTER the terminal injury guard in quick.py"
        )


# ---------------------------------------------------------------------------
# row 85 — functional proof through the real /workouts/quick endpoint
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_row85_quick_endpoint_strips_a_contraindicated_exercise():
    """Full-path proof: Gemini returns a Barbell Front Squat for a user whose
    PROFILE says `knees`, and the persisted workout must not contain it.

    The request body carries NO injuries at all — reproducing the broken client
    chips (Title-Case singular vs stored plural ids). The server reads the
    profile itself, so the gate fires anyway.
    """
    import json as _json
    from unittest.mock import MagicMock

    from httpx import ASGITransport, AsyncClient

    from main import app
    from core.auth import get_current_user
    import api.v1.workouts.quick as quick_mod

    user_id = "11111111-1111-1111-1111-111111111111"
    captured: Dict[str, Any] = {}

    fake_db = MagicMock()
    fake_db.get_user.return_value = {
        "id": user_id, "fitness_level": "intermediate", "equipment": ["barbell"],
    }

    def _create_workout(payload):
        captured["exercises"] = payload["exercises_json"]
        return {
            "id": "22222222-2222-2222-2222-222222222222",
            "user_id": user_id, "name": payload["name"], "type": payload["type"],
            "difficulty": payload["difficulty"],
            "scheduled_date": payload["scheduled_date"],
            "exercises_json": payload["exercises_json"],
            "duration_minutes": payload["duration_minutes"],
        }

    fake_db.create_workout.side_effect = _create_workout

    gemini_payload = {
        "name": "Quick 15min Workout", "type": "strength", "difficulty": "intermediate",
        "exercises": [
            {"name": "Barbell Front Squat", "muscle_group": "quadriceps",
             "target_muscle": "quadriceps", "sets": 3, "reps": 8, "rest_seconds": 90},
            {"name": "Glute Bridge", "muscle_group": "glutes",
             "target_muscle": "glutes", "sets": 3, "reps": 12, "rest_seconds": 60},
        ],
    }
    gemini_response = MagicMock()
    gemini_response.text = _json.dumps(gemini_payload)

    app.dependency_overrides[get_current_user] = lambda: {"id": user_id}
    try:
        with patch.object(quick_mod, "get_supabase_db", return_value=fake_db), \
             patch.object(quick_mod, "get_user_avoided_exercises",
                          AsyncMock(return_value=[])), \
             patch.object(quick_mod, "get_user_avoided_muscles",
                          AsyncMock(return_value={"avoid": [], "reduce": []})), \
             patch.object(quick_mod, "get_user_progression_pace",
                          AsyncMock(return_value="medium")), \
             patch.object(quick_mod, "get_user_rep_preferences",
                          AsyncMock(return_value={"training_focus": "balanced",
                                                  "min_reps": 8, "max_reps": 12})), \
             patch.object(quick_mod, "get_user_progression_context",
                          AsyncMock(return_value={"mastery_context": ""})), \
             patch.object(quick_mod, "get_active_injuries_with_muscles",
                          AsyncMock(return_value={"injuries": ["knees"],
                                                  "avoided_muscles": []})), \
             patch.object(quick_mod, "log_workout_change", MagicMock()), \
             patch.object(quick_mod, "index_workout_to_rag", MagicMock()), \
             patch.object(quick_mod, "track_quick_workout_usage",
                          AsyncMock(return_value=None)), \
             patch("services.gemini.constants.gemini_generate_with_retry",
                   AsyncMock(return_value=gemini_response)), \
             patch(f"{_GUARD}._unsafe_name_set",
                   AsyncMock(return_value={"barbell front squat"})), \
             patch(f"{_GUARD}.fetch_safe_candidates", AsyncMock(return_value=[
                 {"name": "Seated Leg Curl", "target_muscle": "hamstrings",
                  "equipment": "machine", "movement_pattern": "isolation"},
             ])):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as ac:
                resp = await ac.post(
                    "/api/v1/workouts/quick",
                    json={"user_id": user_id, "duration": 15, "focus": "strength",
                          "source": "button"},
                )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert resp.status_code == 200, resp.text
    persisted = captured.get("exercises")
    assert persisted is not None, "workout was never persisted"
    names = [e.get("name") for e in persisted]
    assert "Barbell Front Squat" not in names, (
        f"contraindicated exercise reached the DB for a knees user: {names}"
    )
    assert "Glute Bridge" in names
    assert "Seated Leg Curl" in names, f"guard did not backfill: {names}"


def test_variant_swap_guard_runs_before_persist():
    """row 88 (variant-swap surface): the guard must gate the variant BEFORE
    `persist_variant_cache_row` writes it — nothing after."""
    src = (BACKEND_ROOT / "api/v1/workouts/swap_variant.py").read_text(encoding="utf-8")
    assert src.index("enforce_injury_safety(") < src.index("persist_variant_cache_row(sb,")


def test_quick_save_guard_runs_before_upsert():
    """Client-generated quick workouts get their ONLY safety pass at /quick/save."""
    src = (BACKEND_ROOT / "api/v1/workouts/quick.py").read_text(encoding="utf-8")
    guard_positions = [
        i for i in range(len(src))
        if src.startswith("enforce_injury_safety(", i)
    ]
    upsert_at = src.index('.upsert(workout_db_data')
    assert any(p < upsert_at for p in guard_positions), (
        "/quick/save upserts client-supplied exercises with no injury guard"
    )


# ---------------------------------------------------------------------------
# ADVERSARIAL REVIEW additions
# ---------------------------------------------------------------------------
def test_muscle_token_does_not_match_a_different_muscles_anatomy():
    """`biceps femoris` is a HAMSTRING head, not the biceps brachii.

    The library spells the hamstring group
    ``"Hamstrings (Biceps Femoris, Semitendinosus, Semimembranosus)"`` — 214 of
    the 413 `exercise_library` rows containing the substring "biceps" are
    hamstring rows. A flat `token in blob` scan made the Biceps chip hard-drop
    every hamstring movement (and blocked hamstring backfills too).
    """
    from services.exercise_rag.injury_guard import _targets_avoided_muscle

    tokens = resolve_avoided_muscle_tokens(["biceps"])
    assert "biceps" in tokens

    leg_curl = {
        "name": "Lying Leg Curl",
        "target_muscle": "Hamstrings (Biceps Femoris, Semitendinosus, Semimembranosus)",
        "body_part": "upper legs",
    }
    rdl = {
        "name": "Romanian Deadlift",
        "target_muscle": "Hamstrings (Biceps Femoris, Semitendinosus), Glutes (Gluteus Maximus)",
        "body_part": "upper legs",
    }
    curl = {
        "name": "Dumbbell Bicep Curl",
        "target_muscle": "Biceps (Biceps Brachii)",
        "body_part": "upper arms",
    }
    assert _targets_avoided_muscle(leg_curl, tokens) is False
    assert _targets_avoided_muscle(rdl, tokens) is False
    assert _targets_avoided_muscle(curl, tokens) is True


def test_muscle_token_still_matches_a_named_anatomy_in_full():
    """Precision must not cost recall: an Upper Back limitation still drops lat
    work spelled `Middle Back (Latissimus Dorsi, Teres Major)`."""
    from services.exercise_rag.injury_guard import _targets_avoided_muscle

    tokens = resolve_avoided_muscle_tokens(["upper_back"])
    pulldown = {
        "name": "Lat Pulldown",
        "target_muscle": "Middle Back (Latissimus Dorsi, Teres Major)",
        "body_part": "back",
    }
    shrug = {"name": "Barbell Shrug", "target_muscle": "Upper Back (Trapezius)",
             "body_part": "back"}
    assert _targets_avoided_muscle(pulldown, tokens) is True
    assert _targets_avoided_muscle(shrug, tokens) is True
    # ... but a shoulder raise whose SECONDARY head is the lower trapezius is a
    # shoulder exercise, not upper-back work.
    y_raise = {
        "name": "Dumbbell Chest Supported Y Raise",
        "target_muscle": "Shoulders (Posterior Deltoids, Lower Trapezius)",
        "body_part": "shoulders",
    }
    assert _targets_avoided_muscle(y_raise, tokens) is False


@pytest.mark.asyncio
async def test_muscle_chip_does_not_strip_hamstring_work_end_to_end():
    """Whole-guard proof of the same class, through `enforce_injury_safety`."""
    workout = [
        {"name": "Lying Leg Curl",
         "target_muscle": "Hamstrings (Biceps Femoris, Semitendinosus)",
         "body_part": "upper legs", "sets": 3, "reps": 12},
        {"name": "Dumbbell Bicep Curl", "target_muscle": "Biceps (Biceps Brachii)",
         "body_part": "upper arms", "sets": 3, "reps": 12},
    ]
    with patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())), \
         patch(f"{_GUARD}.fetch_safe_candidates", AsyncMock(return_value=[
             {"name": "Seated Cable Row", "target_muscle": "Middle Back (Rhomboids)"},
         ])):
        safe, dropped, _added = await enforce_injury_safety(
            workout, ["biceps"], user_id="t",
        )
    assert dropped == ["Dumbbell Bicep Curl"], dropped
    assert "Lying Leg Curl" in [e["name"] for e in safe]


def test_variant_swap_guards_the_CACHED_branch_too():
    """A variant cached BEFORE the user logged the injury is just as unsafe.

    `get_cached_variant` returns a previously persisted `workouts` row and the
    client opens that row by id — so the cache-hit branch must screen it, not
    only the freshly generated one.
    """
    src = (BACKEND_ROOT / "api/v1/workouts/swap_variant.py").read_text(encoding="utf-8")
    tree = ast.parse(src)
    endpoint = next(
        n for n in ast.walk(tree)
        if isinstance(n, ast.AsyncFunctionDef) and n.name == "swap_workout_variant"
    )
    guard_calls = [
        n for n in ast.walk(endpoint)
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
        and n.func.id == "_injury_guard_exercises"
    ]
    assert len(guard_calls) >= 2, (
        "swap-variant must screen BOTH the cache-hit branch and the freshly "
        f"generated variant; found {len(guard_calls)} guard call(s)."
    )
    # And the cached branch must be screened before it is returned.
    assert src.index("_injury_guard_exercises(user_id, cached_exercises") < src.index(
        "cached=True,"
    )


@pytest.mark.asyncio
async def test_quick_save_identity_comes_from_the_token_not_the_payload():
    """/quick/save's injury guard must screen against the CALLER's limitations.

    The endpoint used to resolve `user_id` from `request.state.user_id` with a
    fallback to `body.workout["user_id"]`. `request.state.user_id` is never
    assigned anywhere in the codebase, so the fallback was the only branch that
    ever ran — the guard read the limitations of a client-supplied id, and a
    blank/foreign id turned this endpoint's ONLY safety pass into a no-op.
    """
    from httpx import ASGITransport, AsyncClient

    from main import app
    from core.auth import get_current_user

    caller = "11111111-1111-1111-1111-111111111111"
    victim = "33333333-3333-3333-3333-333333333333"

    app.dependency_overrides[get_current_user] = lambda: {"id": caller}
    try:
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as ac:
            resp = await ac.post(
                "/api/v1/workouts/quick/save",
                json={
                    "workout": {
                        "id": "44444444-4444-4444-4444-444444444444",
                        "user_id": victim,
                        "exercises_json": [{"name": "Barbell Front Squat"}],
                    },
                    "source": "quick_button",
                    "generation_method": "quick_rule_based",
                    "generation_source": "quick_workout",
                },
            )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert resp.status_code == 403, resp.text


def test_quick_save_does_not_trust_request_state_user_id():
    """Static half of the same rule — no resurrection of the payload fallback."""
    src = (BACKEND_ROOT / "api/v1/workouts/quick.py").read_text(encoding="utf-8")
    assert 'getattr(request.state, "user_id"' not in src, (
        "request.state.user_id is never assigned in this codebase; reading it "
        "makes the payload the effective identity."
    )


# ---------------------------------------------------------------------------
# row 88 (residual) — the USER-CHOSEN-exercise surfaces
# ---------------------------------------------------------------------------
# `/workouts/swap-exercise`, `/workouts/add-exercise` and their preview twins let
# the user name the exercise, so `enforce_injury_safety` (which filters a list we
# generated) never sees it. They now resolve through
# `resolve_user_chosen_exercise`, which screens and CANNOT be called without the
# user's injuries.
_SWAP_SURFACES = ("api/v1/workouts/workout_operations.py", "api/v1/workouts/exercises.py")


def test_row88_resolver_cannot_be_called_without_injuries():
    """`injuries` is keyword-only and REQUIRED — forgetting it is a TypeError,
    not an unscreened exercise (same shape as row 84's finisher fix)."""
    import inspect

    sig = inspect.signature(resolve_user_chosen_exercise)
    param = sig.parameters["injuries"]
    assert param.kind is inspect.Parameter.KEYWORD_ONLY
    assert param.default is inspect.Parameter.empty


@pytest.mark.asyncio
async def test_row88_resolver_raises_on_a_contraindicated_pick():
    with patch(f"{_GUARD}._lookup_library_exercise",
               lambda name, eid=None: {"name": "Barbell Front Squat",
                                       "target_muscle": "Quadriceps",
                                       "id": "lib-1"}), \
         patch(f"{_GUARD}._unsafe_name_set",
               AsyncMock(return_value={"barbell front squat"})):
        with pytest.raises(InjuryUnsafeExerciseError) as err:
            await resolve_user_chosen_exercise("Barbell Front Squat", injuries=["knees"])
    assert err.value.reason == "safety_index"
    assert err.value.exercise_name == "Barbell Front Squat"


@pytest.mark.asyncio
async def test_row88_resolver_screens_a_name_the_library_does_not_carry():
    """A typed-in name with no library row is still screened (keyword backstop)."""
    with patch(f"{_GUARD}._lookup_library_exercise", lambda name, eid=None: None), \
         patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())):
        with pytest.raises(InjuryUnsafeExerciseError):
            await resolve_user_chosen_exercise("Jefferson Curl", injuries=["lower_back"])


@pytest.mark.asyncio
async def test_row88_resolver_returns_a_safe_pick_untouched():
    row = {"name": "Glute Bridge", "target_muscle": "glutes", "id": "lib-2"}
    with patch(f"{_GUARD}._lookup_library_exercise", lambda name, eid=None: row), \
         patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())):
        got = await resolve_user_chosen_exercise("Glute Bridge", injuries=["knees"])
    assert got == row


def test_row88_swap_surfaces_have_no_unscreened_library_lookup():
    """Structural gate: neither swap file may resolve an exercise on its own.

    Call-site discipline is what failed here the first time — the screen existed
    (`screen_exercise_for_injury`) with ZERO callers. So the raw lookups are
    deleted, not merely accompanied by a screen: if these files can't reach the
    library except through the screened resolver, a future endpoint in them
    cannot reintroduce the bug.
    """
    offenders = []
    for rel in _SWAP_SURFACES:
        src = (BACKEND_ROOT / rel).read_text(encoding="utf-8")
        for needle in ("get_exercise_library_service", "exercise_library_cleaned"):
            if needle in src:
                offenders.append(f"{rel}: {needle}")
    assert offenders == [], (
        "unscreened library lookup in a user-chosen-exercise surface:\n  "
        + "\n  ".join(offenders)
    )


def test_row88_every_resolver_call_passes_real_injuries():
    """No call site may hand the resolver an empty literal (a guard that guards
    nothing) — the same failure mode row 84's `avoid_names=set()` had."""
    bad = []
    for rel in _SWAP_SURFACES:
        tree = ast.parse((BACKEND_ROOT / rel).read_text(encoding="utf-8"))
        for node in ast.walk(tree):
            if not isinstance(node, ast.Call):
                continue
            fn = node.func
            name = fn.id if isinstance(fn, ast.Name) else getattr(fn, "attr", "")
            if name != "resolve_user_chosen_exercise":
                continue
            kw = {k.arg: k.value for k in node.keywords}
            if "injuries" not in kw:
                bad.append(f"{rel}:{node.lineno} missing injuries=")
                continue
            value = kw["injuries"]
            if isinstance(value, (ast.List, ast.Tuple, ast.Set)) and not value.elts:
                bad.append(f"{rel}:{node.lineno} injuries= empty literal")
            elif isinstance(value, ast.Constant) and not value.value:
                bad.append(f"{rel}:{node.lineno} injuries= falsy constant")
    assert bad == [], "\n  ".join(bad)


def test_row88_swap_endpoints_resolve_only_through_the_screened_helper():
    """Every user-chosen-exercise endpoint reaches the resolver."""
    ops = _calls_in_file("api/v1/workouts/workout_operations.py")
    assert "resolve_user_chosen_exercise" in ops
    prev = _calls_in_file("api/v1/workouts/exercises.py")
    assert "_lookup_exercise_screened" in prev
    src = (BACKEND_ROOT / "api/v1/workouts/exercises.py").read_text(encoding="utf-8")
    assert "resolve_user_chosen_exercise(" in src


@pytest.mark.asyncio
async def test_row88_swap_exercise_endpoint_refuses_a_contraindicated_pick():
    """Full-path proof through POST /api/v1/workouts/swap-exercise.

    A knee-injured user asks to swap into "Barbell Front Squat"
    (`knee_safe = FALSE` in the live index). The endpoint must refuse (409) and
    must NOT write the workout.
    """
    from unittest.mock import MagicMock

    from httpx import ASGITransport, AsyncClient

    from main import app
    from core.auth import get_current_user
    import api.v1.workouts.workout_operations as ops_mod

    user_id = "11111111-1111-1111-1111-111111111111"
    workout_id = "22222222-2222-2222-2222-222222222222"

    fake_db = MagicMock()
    fake_db.get_workout.return_value = {
        "id": workout_id, "user_id": user_id,
        "exercises_json": [{"name": "Goblet Squat", "sets": 3, "reps": 10}],
    }

    app.dependency_overrides[get_current_user] = lambda: {"id": user_id}
    try:
        with patch.object(ops_mod, "get_supabase_db", return_value=fake_db), \
             patch.object(ops_mod, "get_active_injuries_with_muscles",
                          AsyncMock(return_value={"injuries": ["knees"],
                                                  "avoided_muscles": []})), \
             patch.object(ops_mod, "get_all_muscles_for_exercise",
                          AsyncMock(return_value=None)), \
             patch(f"{_GUARD}._lookup_library_exercise",
                   lambda name, eid=None: {"name": "Barbell Front Squat",
                                           "target_muscle": "Quadriceps",
                                           "id": "lib-1"}), \
             patch(f"{_GUARD}._unsafe_name_set",
                   AsyncMock(return_value={"barbell front squat"})):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as ac:
                resp = await ac.post(
                    "/api/v1/workouts/swap-exercise",
                    json={"workout_id": workout_id,
                          "old_exercise_name": "Goblet Squat",
                          "new_exercise_name": "Barbell Front Squat"},
                )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert resp.status_code == 409, resp.text
    assert resp.json()["detail"]["error"] == "EXERCISE_UNSAFE_FOR_INJURY"
    fake_db.update_workout.assert_not_called()


@pytest.mark.asyncio
async def test_row88_swap_exercise_endpoint_allows_a_safe_pick():
    """The screen must not become a wall: a safe replacement still swaps."""
    from unittest.mock import MagicMock

    from httpx import ASGITransport, AsyncClient

    from main import app
    from core.auth import get_current_user
    import api.v1.workouts.workout_operations as ops_mod

    user_id = "11111111-1111-1111-1111-111111111111"
    workout_id = "22222222-2222-2222-2222-222222222222"

    fake_db = MagicMock()
    fake_db.get_workout.return_value = {
        "id": workout_id, "user_id": user_id,
        "exercises_json": [{"name": "Goblet Squat", "sets": 3, "reps": 10}],
    }
    written: Dict[str, Any] = {}

    def _update(_wid, data):
        written.update(data)
        return {"id": workout_id, "user_id": user_id, "name": "W", "type": "strength",
                "difficulty": "beginner", "scheduled_date": "2026-07-30T12:00:00+00:00",
                "exercises_json": data["exercises_json"], "duration_minutes": 30}

    fake_db.update_workout.side_effect = _update

    app.dependency_overrides[get_current_user] = lambda: {"id": user_id}
    try:
        with patch.object(ops_mod, "get_supabase_db", return_value=fake_db), \
             patch.object(ops_mod, "get_active_injuries_with_muscles",
                          AsyncMock(return_value={"injuries": ["knees"],
                                                  "avoided_muscles": []})), \
             patch.object(ops_mod, "get_all_muscles_for_exercise",
                          AsyncMock(return_value=None)), \
             patch.object(ops_mod, "log_workout_change", MagicMock()), \
             patch.object(ops_mod, "upsert_substitution", MagicMock()), \
             patch.object(ops_mod, "index_workout_to_rag", AsyncMock()), \
             patch(f"{_GUARD}._lookup_library_exercise",
                   lambda name, eid=None: {"name": "Glute Bridge",
                                           "target_muscle": "glutes", "id": "lib-2"}), \
             patch(f"{_GUARD}._unsafe_name_set", AsyncMock(return_value=set())):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as ac:
                resp = await ac.post(
                    "/api/v1/workouts/swap-exercise",
                    json={"workout_id": workout_id,
                          "old_exercise_name": "Goblet Squat",
                          "new_exercise_name": "Glute Bridge"},
                )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert resp.status_code == 200, resp.text
    assert "Glute Bridge" in written.get("exercises_json", "")


@pytest.mark.asyncio
async def test_row88_preview_swap_endpoint_refuses_a_contraindicated_pick():
    """Same rule on the preview twin — the preview is what /save persists."""
    from unittest.mock import MagicMock

    from httpx import ASGITransport, AsyncClient

    from main import app
    from core.auth import get_current_user
    import api.v1.workouts.exercises as ex_mod

    user_id = "11111111-1111-1111-1111-111111111111"

    entry = MagicMock()
    entry.payload = {"id": "p1", "preview_id": "p1", "user_id": user_id,
                     "exercises_json": [{"name": "Goblet Squat"}]}
    fake_cache = MagicMock()
    fake_cache.get_owned = AsyncMock(return_value=(entry, None))
    fake_cache.update = AsyncMock(return_value=entry)

    app.dependency_overrides[get_current_user] = lambda: {"id": user_id}
    try:
        with patch.object(ex_mod, "get_preview_cache", return_value=fake_cache), \
             patch.object(ex_mod, "resolve_active_injuries",
                          AsyncMock(return_value=["knees"])), \
             patch(f"{_GUARD}._lookup_library_exercise",
                   lambda name, eid=None: {"name": "Barbell Front Squat",
                                           "target_muscle": "Quadriceps",
                                           "id": "lib-1"}), \
             patch(f"{_GUARD}._unsafe_name_set",
                   AsyncMock(return_value={"barbell front squat"})):
            transport = ASGITransport(app=app)
            async with AsyncClient(transport=transport, base_url="http://test") as ac:
                resp = await ac.post(
                    "/api/v1/workouts/preview/swap-exercise",
                    json={"preview_id": "p1",
                          "old_exercise_name": "Goblet Squat",
                          "new_exercise_name": "Barbell Front Squat"},
                )
    finally:
        app.dependency_overrides.pop(get_current_user, None)

    assert resp.status_code == 409, resp.text
    assert resp.json()["detail"]["error"] == "EXERCISE_UNSAFE_FOR_INJURY"
    fake_cache.update.assert_not_called()


# ---------------------------------------------------------------------------
# row 83 residual (a) — the two injury stores must agree at one chokepoint
# ---------------------------------------------------------------------------
class _FakeTable:
    def __init__(self, store, name):
        self._store, self._name = store, name
        self._filters = {}

    def select(self, *_a, **_k):
        return self

    def update(self, data):
        self._store["writes"].append((self._name, data))
        self._pending = data
        return self

    def eq(self, col, val):
        self._filters[col] = val
        return self

    def maybe_single(self):
        self._single = True
        return self

    def execute(self):
        rows = self._store.get(self._name, [])
        out = MagicMockData(rows[0] if getattr(self, "_single", False) and rows else rows)
        return out


class MagicMockData:
    def __init__(self, data):
        self.data = data


class _FakeSupabase:
    def __init__(self, store):
        self.client = self
        self._store = store

    def table(self, name):
        return _FakeTable(self._store, name)


def _run_sync(user_injuries, profile):
    from api.v1.injuries import sync_profile_active_injuries

    store = {"user_injuries": user_injuries,
             "users": [{"active_injuries": profile}],
             "writes": []}
    result = sync_profile_active_injuries(_FakeSupabase(store), "u1")
    return result, store["writes"]


def test_row83_report_projects_onto_the_profile_store():
    """A reported injury must land in `users.active_injuries` — the column the
    regenerate path reads. This is the whole reason the row-83 chokepoint was
    being handed an empty list."""
    written, writes = _run_sync(
        [{"body_part": "knee", "status": "active"}], [],
    )
    assert written == ["knee"]
    assert writes and writes[0][0] == "users"
    assert writes[0][1] == {"active_injuries": ["knee"]}


def test_row83_healed_injury_leaves_the_profile_store():
    written, _ = _run_sync(
        [{"body_part": "knee", "status": "healed"}], ["knee"],
    )
    assert written == []


def test_row83_untracked_profile_entries_are_preserved():
    """Onboarding chips / body-map taps live only in the profile column — the
    projection must never delete what `user_injuries` never recorded."""
    written, _ = _run_sync(
        [{"body_part": "knee", "status": "active"}], ["shoulders", "abs"],
    )
    assert written == ["shoulders", "abs", "knee"]


def test_row83_projection_is_idempotent_and_writes_nothing_when_unchanged():
    written, writes = _run_sync(
        [{"body_part": "knee", "status": "active"}], ["knee"],
    )
    assert written is None
    assert writes == []


def test_row83_projection_reconciles_spelling_across_the_two_stores():
    """`user_injuries` says "knee", the profile says the app's plural "knees" —
    one canonicalizer decides they are the same injury, so healing removes it."""
    written, _ = _run_sync(
        [{"body_part": "knee", "status": "healed"}], ["knees", "abs"],
    )
    assert written == ["abs"]


def test_row83_every_user_injuries_writer_syncs_the_profile():
    """Class gate: no endpoint may write `user_injuries` without reconciling."""
    src = (BACKEND_ROOT / "api/v1/injuries.py").read_text(encoding="utf-8")
    tree = ast.parse(src)
    for fn in ast.walk(tree):
        if not isinstance(fn, (ast.AsyncFunctionDef, ast.FunctionDef)):
            continue
        writes = False
        for node in ast.walk(fn):
            if isinstance(node, ast.Call) and isinstance(node.func, ast.Attribute) \
                    and node.func.attr in ("insert", "update"):
                inner = node.func.value
                # ...table("user_injuries").insert(...) / .update(...)
                while isinstance(inner, ast.Call) and isinstance(inner.func, ast.Attribute):
                    if inner.func.attr == "table" and inner.args \
                            and isinstance(inner.args[0], ast.Constant) \
                            and inner.args[0].value == "user_injuries":
                        writes = True
                    inner = inner.func.value
        if not writes:
            continue
        called = {
            n.func.id for n in ast.walk(fn)
            if isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
        }
        assert "sync_profile_active_injuries" in called, (
            f"{fn.name} writes user_injuries without syncing users.active_injuries"
        )


# ---------------------------------------------------------------------------
# row 83 residual (b) — muscle-area ids reach the validator, not /dev/null
# ---------------------------------------------------------------------------
def test_row83_muscle_ids_survive_into_the_validator_context():
    ctx = UserSafetyContext(
        injuries=["hamstrings", "quads", "knees"], difficulty="beginner",
        equipment=[], user_id="t",
    )
    # Joints keep going to the <joint>_safe columns ...
    assert ctx.normalized_injuries() == ["knee"]
    # ... and the muscle chips are no longer dropped on the floor.
    tokens = ctx.avoided_muscle_tokens()
    assert "hamstrings" in tokens and "quadriceps" in tokens


def test_row83_muscle_only_limitation_now_produces_a_violation():
    """Before: a Hamstrings-only user got violations=0 / swaps=0 out of the
    whole validator, because the joint whitelist emptied their injury list."""
    from services.workout_safety_validator import _check_row_safety

    ctx = UserSafetyContext(
        injuries=["hamstrings"], difficulty="advanced", equipment=[], user_id="t",
    )
    leg_curl = {
        "is_tagged": True, "name": "Lying Leg Curl",
        "target_muscle": "Hamstrings (Biceps Femoris, Semitendinosus)",
        "body_part": "upper legs", "safety_difficulty": "beginner",
    }
    bench = {
        "is_tagged": True, "name": "Barbell Bench Press",
        "target_muscle": "Chest (Pectoralis Major)", "body_part": "chest",
        "safety_difficulty": "beginner",
    }
    assert _check_row_safety(leg_curl, ctx) == ["primary_target_is_avoided_muscle"]
    assert _check_row_safety(bench, ctx) == []


def test_row83_joint_injuries_do_not_gain_muscle_wide_drops():
    """A knee injury must stay governed by knee_safe, not hard-drop every leg
    exercise — the regression that would make this fix worse than the bug."""
    ctx = UserSafetyContext(
        injuries=["knees"], difficulty="advanced", equipment=[], user_id="t",
    )
    assert ctx.avoided_muscle_tokens() == []


# ---------------------------------------------------------------------------
# keyword needle matching + replacement shape (safety-path hygiene)
# ---------------------------------------------------------------------------
def test_injury_keyword_needle_matches_words_not_substrings():
    from services.exercise_rag.injury_guard import _name_keyword_banned

    # free text still resolves
    assert _name_keyword_banned("barbell deadlift", ["left lower back"]) is True
    assert _name_keyword_banned("box jump", ["knee pain"]) is True
    # ... but a word that merely CONTAINS the region no longer fires
    assert _name_keyword_banned("barbell deadlift", ["backache"]) is False


def test_replacement_inherits_shape_instead_of_inventing_one():
    from services.exercise_rag.injury_guard import _build_replacement

    cand = {"name": "Seated Cable Row", "target_muscle": "upper back",
            "equipment": "cable", "movement_pattern": "horizontal_pull"}
    # Inherits the session's real prescription from a donor that has it.
    repl = _build_replacement(
        [{"name": "Plank"}, {"name": "Row", "sets": 5, "reps": 6, "rest_seconds": 120}],
        cand,
    )
    assert (repl["sets"], repl["reps"], repl["rest_seconds"]) == (5, 6, 120)
    # A duration-only session gets NO fabricated set scheme.
    timed = _build_replacement(
        [{"name": "Bike Intervals", "duration_seconds": 600, "is_timed": True}], cand,
    )
    assert "sets" not in timed and "reps" not in timed
    assert timed["duration_seconds"] == 600


@pytest.mark.asyncio
async def test_row88_whole_list_edit_screens_only_the_newly_introduced_exercise():
    """The edit endpoints replace `exercises_json` wholesale — the last way a
    user-picked exercise could reach the DB unscreened.

    Screening the WHOLE list would refuse a plain reorder of what the generator
    already produced, so only names the edit INTRODUCES are screened.
    """
    from api.v1.workouts.workout_operations import (
        assert_edit_introduces_no_unsafe_exercise,
    )
    import api.v1.workouts.workout_operations as ops_mod
    from fastapi import HTTPException

    existing = [{"name": "Barbell Front Squat", "sets": 3},
                {"name": "Glute Bridge", "sets": 3}]

    with patch.object(ops_mod, "resolve_active_injuries",
                      AsyncMock(return_value=["knees"])), \
         patch(f"{_GUARD}._unsafe_name_set",
               AsyncMock(return_value={"barbell front squat"})):
        # Reorder / removal of what is already there: allowed, no exception.
        await assert_edit_introduces_no_unsafe_exercise(
            "u1", existing, list(reversed(existing)),
        )
        # Introducing the same contraindicated move: refused.
        with pytest.raises(HTTPException) as err:
            await assert_edit_introduces_no_unsafe_exercise(
                "u1",
                [{"name": "Glute Bridge", "sets": 3}],
                [{"name": "Glute Bridge"}, {"name": "Barbell Front Squat"}],
            )
    assert err.value.status_code == 409
    assert err.value.detail["error"] == "EXERCISE_UNSAFE_FOR_INJURY"


def test_row88_edit_surfaces_call_the_screen():
    """Static half — both whole-list editors must reach the screen."""
    for rel in ("api/v1/workouts/workout_operations.py",
                "api/v1/workouts/exercises.py"):
        assert "assert_edit_introduces_no_unsafe_exercise" in _calls_in_file(rel), rel
