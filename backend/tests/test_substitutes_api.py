"""Unit tests for /suggest-substitutes endpoint helpers.

Covers the new reason-aware classification, name-keyword safety filter,
intent filter, scoring, seeded jitter, and per-substitute explanation
helpers. Integration-level tests use a fake Supabase client.

Run: cd backend && .venv/bin/python -m pytest tests/test_substitutes_api.py -v
"""
from __future__ import annotations

import os
import sys
from typing import Any, Dict, List, Optional
from unittest.mock import MagicMock

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from api.v1.exercise_preferences_endpoints import (  # noqa: E402
    _classify_reason,
    _detect_intent,
    _detect_family_keyword,
    _is_unsafe_by_name_keyword,
    _passes_intent_filter,
    _row_passes_all_filters,
    _score_candidate,
    _seeded_jitter,
    _explain_substitute,
    _to_substitute_exercise,
    _build_injury_warning,
    _build_safety_warning,
    _build_message,
    INTENT_KEYWORDS,
    PREGNANCY_UNSAFE_KEYWORDS,
)
from api.v1.exercise_preferences_models import SubstituteRequest


# ---------------------------------------------------------------------------
# _detect_intent / _classify_reason
# ---------------------------------------------------------------------------

def _req(name: str, reason: Optional[str] = None) -> SubstituteRequest:
    return SubstituteRequest(exercise_name=name, user_id="u-test", reason=reason)


@pytest.mark.parametrize(
    "reason,expected_intent",
    [
        (None, "none"),
        ("", "none"),
        ("knee injury", "none"),  # injury detected separately; no intent
        ("no equipment available", "no_equipment"),
        ("bodyweight only", "no_equipment"),
        ("at home today", "no_equipment"),
        ("boring", "boring"),
        ("bored and want variety", "boring"),
        ("tired of this", "boring"),
        ("pregnant — second trimester", "pregnant"),
        ("expecting third trimester", "pregnant"),
        ("post-surgery rehab", "post_surgery"),
        ("recovery from acl", "post_surgery"),
        ("menstrual phase", "menstrual"),
        ("pms today", "menstrual"),
    ],
)
def test_detect_intent(reason, expected_intent):
    assert _detect_intent(reason) == expected_intent


def test_classify_reason_pregnancy():
    ctx = _classify_reason(_req("Squat", "pregnant — second trimester"))
    assert ctx.intent == "pregnant"
    assert ctx.injury_type is None
    assert ctx.desired_equipment is None  # only no_equipment sets this


def test_classify_reason_no_equipment():
    ctx = _classify_reason(_req("Squat", "no equipment available"))
    assert ctx.intent == "no_equipment"
    assert ctx.desired_equipment == ["bodyweight", "none", ""]


def test_classify_reason_knee_injury_overrides_intent():
    """Injury detection runs alongside intent. Both are surfaced; safety wins."""
    ctx = _classify_reason(_req("Squat", "knee injury"))
    assert ctx.injury_type == "knee"
    assert ctx.intent == "none"


def test_classify_reason_boring_extracts_family_keyword():
    ctx = _classify_reason(_req("Barbell Bench Press", "boring"))
    assert ctx.intent == "boring"
    assert ctx.family_keyword == "press"


def test_classify_reason_seed_changes_with_reason():
    """Same exercise + different reasons → different seeds → different rankings."""
    ctx_a = _classify_reason(_req("Squat", "knee injury"))
    ctx_b = _classify_reason(_req("Squat", "boring"))
    assert ctx_a.seed != ctx_b.seed


def test_classify_reason_seed_stable_for_same_input():
    ctx_a = _classify_reason(_req("Squat", "knee injury"))
    ctx_b = _classify_reason(_req("Squat", "knee injury"))
    assert ctx_a.seed == ctx_b.seed


# ---------------------------------------------------------------------------
# _detect_family_keyword
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("name,expected", [
    ("Barbell Back Squat", "squat"),
    ("Bench Press", "press"),
    ("Bicep Curl", "curl"),
    ("Bent Over Row", "row"),
    ("Conventional Deadlift", "deadlift"),
    ("Walking Lunge", "lunge"),
    ("Push-Up", "push-up"),
    ("Glute Bridge", None),  # no movement keyword in list
])
def test_detect_family_keyword(name, expected):
    assert _detect_family_keyword(name) == expected


# ---------------------------------------------------------------------------
# _is_unsafe_by_name_keyword (belt-and-suspenders)
# ---------------------------------------------------------------------------

def test_unsafe_by_name_keyword_knee_hindu_squat():
    """Was leaking — Hindu Squat / Baithak passed avoid_if check on empty data."""
    ctx = _classify_reason(_req("Goblet Squat", "knee injury"))
    assert _is_unsafe_by_name_keyword("Baithak (Hindu Squat)", ctx) is True
    assert _is_unsafe_by_name_keyword("Walking Lunges", ctx) is True
    assert _is_unsafe_by_name_keyword("Reverse Hack Squat", ctx) is True


def test_unsafe_by_name_keyword_knee_safe_exercise():
    ctx = _classify_reason(_req("Goblet Squat", "knee injury"))
    assert _is_unsafe_by_name_keyword("Glute Bridge", ctx) is False
    assert _is_unsafe_by_name_keyword("Lat Pulldown", ctx) is False


def test_unsafe_by_name_keyword_pregnancy_jump():
    """Was leaking — '180 Jump Turns' returned 10/50 pregnancy queries."""
    ctx = _classify_reason(_req("Squat", "pregnant — second trimester"))
    assert _is_unsafe_by_name_keyword("180 Jump Turns", ctx) is True
    assert _is_unsafe_by_name_keyword("Box Jump", ctx) is True
    assert _is_unsafe_by_name_keyword("Plyometric Push-up", ctx) is True
    assert _is_unsafe_by_name_keyword("Crunch", ctx) is True


def test_unsafe_by_name_keyword_pregnancy_safe():
    ctx = _classify_reason(_req("Squat", "pregnant"))
    assert _is_unsafe_by_name_keyword("Glute Bridge", ctx) is False
    assert _is_unsafe_by_name_keyword("Cable Row", ctx) is False


def test_unsafe_by_name_keyword_no_injury_no_intent():
    """Without an injury type or pregnancy intent, nothing should be flagged."""
    ctx = _classify_reason(_req("Squat", None))
    assert _is_unsafe_by_name_keyword("Baithak (Hindu Squat)", ctx) is False
    assert _is_unsafe_by_name_keyword("Box Jump", ctx) is False


# ---------------------------------------------------------------------------
# _passes_intent_filter (hard filters before scoring)
# ---------------------------------------------------------------------------

def _row(name: str, **kw: Any) -> Dict[str, Any]:
    return {"id": kw.get("id", "row-1"), "name": name, **kw}


def test_passes_intent_filter_no_equipment_drops_dumbbells():
    ctx = _classify_reason(_req("Bench Press", "no equipment available"))
    assert _passes_intent_filter(_row("Push-Up", equipment="bodyweight"), ctx) is True
    assert _passes_intent_filter(_row("DB Press", equipment="dumbbells"), ctx) is False
    assert _passes_intent_filter(_row("Cable Row", equipment="cable"), ctx) is False


def test_passes_intent_filter_pregnant_drops_plyometric():
    ctx = _classify_reason(_req("Squat", "pregnant"))
    assert _passes_intent_filter(_row("Box Jump", category="plyometric"), ctx) is False
    assert _passes_intent_filter(_row("180 Jump Turns", category="cardio"), ctx) is False
    assert _passes_intent_filter(_row("Glute Bridge", category="strength"), ctx) is True


def test_passes_intent_filter_post_surgery_caps_difficulty():
    ctx = _classify_reason(_req("Squat", "post-surgery rehab"))
    assert _passes_intent_filter(_row("Wall Sit", difficulty_level=2), ctx) is True
    assert _passes_intent_filter(_row("Pistol Squat", difficulty_level=8), ctx) is False
    # difficulty_level absent → don't drop (default-allow)
    assert _passes_intent_filter(_row("Glute Bridge"), ctx) is True


def test_passes_intent_filter_none_intent_passes_everything():
    ctx = _classify_reason(_req("Squat", None))
    assert _passes_intent_filter(_row("Box Jump", category="plyometric"), ctx) is True


# ---------------------------------------------------------------------------
# _seeded_jitter
# ---------------------------------------------------------------------------

def test_seeded_jitter_deterministic():
    j1 = _seeded_jitter("row-x", "seed-a")
    j2 = _seeded_jitter("row-x", "seed-a")
    assert j1 == j2


def test_seeded_jitter_different_seed_different_value():
    j1 = _seeded_jitter("row-x", "seed-a")
    j2 = _seeded_jitter("row-x", "seed-b")
    assert j1 != j2


def test_seeded_jitter_in_range():
    for row_id in ("a", "b", "c", "12345", None):
        for seed in ("seed-1", "seed-2"):
            j = _seeded_jitter(row_id, seed)
            assert 0.0 <= j < 0.10


# ---------------------------------------------------------------------------
# _score_candidate
# ---------------------------------------------------------------------------

def test_score_candidate_boring_penalizes_same_family():
    ctx = _classify_reason(_req("Barbell Back Squat", "boring"))
    same_family = _row("Front Squat", id="r1", display_body_part="Quadriceps")
    different = _row("Romanian Deadlift", id="r2", display_body_part="Hamstrings")
    s_same = _score_candidate(same_family, "quadriceps", ctx)
    s_diff = _score_candidate(different, "quadriceps", ctx)
    assert s_diff > s_same, f"different family should score higher: {s_diff} vs {s_same}"


def test_score_candidate_prefers_media_rich():
    ctx = _classify_reason(_req("Squat", None))
    with_media = _row("Glute Bridge", id="r1", display_body_part="Glutes",
                      gif_url="https://example.com/x.gif")
    without_media = _row("Hip Thrust", id="r2", display_body_part="Glutes")
    s_with = _score_candidate(with_media, "glutes", ctx)
    s_without = _score_candidate(without_media, "glutes", ctx)
    assert s_with > s_without


def test_score_candidate_prefers_matching_equipment_for_no_equipment():
    ctx = _classify_reason(_req("Bench Press", "no equipment available"))
    bw = _row("Push-Up", id="r1", display_body_part="Chest", equipment="bodyweight")
    db = _row("DB Press", id="r2", display_body_part="Chest", equipment="dumbbells")
    s_bw = _score_candidate(bw, "chest", ctx)
    s_db = _score_candidate(db, "chest", ctx)
    assert s_bw > s_db


def test_score_candidate_post_surgery_prefers_mobility():
    ctx = _classify_reason(_req("Squat", "post-surgery rehab"))
    mobility = _row("Hip Mobility Drill", id="r1",
                    display_body_part="Hips", category="mobility",
                    difficulty_level=2)
    strength = _row("Goblet Squat", id="r2",
                    display_body_part="Quadriceps", category="strength",
                    difficulty_level=2)
    s_mob = _score_candidate(mobility, "hips", ctx)
    s_str = _score_candidate(strength, "hips", ctx)
    assert s_mob > s_str


# ---------------------------------------------------------------------------
# _row_passes_all_filters (composite gate)
# ---------------------------------------------------------------------------

def test_row_passes_all_filters_self_exclusion():
    ctx = _classify_reason(_req("Squat", None))
    # Same name as original → always excluded
    assert _row_passes_all_filters(_row("Squat"), ctx) is False
    assert _row_passes_all_filters(_row("squat"), ctx) is False  # case-insensitive
    assert _row_passes_all_filters(_row("Goblet Squat"), ctx) is True


def test_row_passes_all_filters_combines_avoid_if_and_name_keyword():
    ctx = _classify_reason(_req("Goblet Squat", "knee injury"))
    # Hindu Squat with empty avoid_if would have leaked before — name keyword catches it
    assert _row_passes_all_filters(
        _row("Baithak (Hindu Squat)", avoid_if=[], display_body_part="Quadriceps"),
        ctx,
    ) is False
    # Glute Bridge OK
    assert _row_passes_all_filters(
        _row("Glute Bridge", avoid_if=[], display_body_part="Glutes"),
        ctx,
    ) is True


# ---------------------------------------------------------------------------
# _explain_substitute / _build_*_warning / _build_message
# ---------------------------------------------------------------------------

def test_explain_substitute_knee():
    ctx = _classify_reason(_req("Squat", "knee injury"))
    assert _explain_substitute(_row("Glute Bridge"), ctx) == "Knee-friendly alternative"


def test_explain_substitute_no_equipment():
    ctx = _classify_reason(_req("Bench Press", "no equipment available"))
    assert _explain_substitute(_row("Push-Up"), ctx) == "Bodyweight, no equipment needed"


def test_explain_substitute_pregnant():
    ctx = _classify_reason(_req("Squat", "pregnant"))
    assert _explain_substitute(_row("Glute Bridge"), ctx) == "Pregnancy-safe alternative"


def test_explain_substitute_default():
    ctx = _classify_reason(_req("Squat", None))
    assert _explain_substitute(_row("Glute Bridge"), ctx) == "Same muscle group"


def test_build_injury_warning_only_for_injury():
    assert _build_injury_warning(_classify_reason(_req("Squat", "knee injury"))) is not None
    assert _build_injury_warning(_classify_reason(_req("Squat", "boring"))) is None
    assert _build_injury_warning(_classify_reason(_req("Squat", None))) is None


def test_build_safety_warning_pregnant():
    msg = _build_safety_warning(_classify_reason(_req("Squat", "pregnant")))
    assert msg is not None and "pregnan" in msg.lower()


def test_build_safety_warning_post_surgery():
    msg = _build_safety_warning(_classify_reason(_req("Squat", "post-surgery rehab")))
    assert msg is not None and "post-surgery" in msg.lower()


def test_build_safety_warning_none_for_plain_injury():
    """Injury queries get an injury_warning instead of a safety_warning."""
    assert _build_safety_warning(_classify_reason(_req("Squat", "knee injury"))) is None


def test_build_message_uses_intent_branch():
    ctx = _classify_reason(_req("Squat", "no equipment available"))
    assert "bodyweight" in _build_message(ctx, 5).lower()


# ---------------------------------------------------------------------------
# _to_substitute_exercise
# ---------------------------------------------------------------------------

def test_to_substitute_exercise_media_coalesce_gif():
    ctx = _classify_reason(_req("Squat", None))
    sub = _to_substitute_exercise(_row(
        "Glute Bridge", id="r1", display_body_part="Glutes",
        gif_url="https://x.com/g.gif",
        video_url="https://x.com/v.mp4",
        image_url="https://x.com/i.png",
    ), ctx)
    # gif wins
    assert sub.media_url == "https://x.com/g.gif"
    assert sub.gif_url == "https://x.com/g.gif"
    assert sub.video_url == "https://x.com/v.mp4"


def test_to_substitute_exercise_media_falls_through_to_video():
    ctx = _classify_reason(_req("Squat", None))
    sub = _to_substitute_exercise(_row(
        "Glute Bridge", id="r1", display_body_part="Glutes",
        gif_url=None,
        video_url="https://x.com/v.mp4",
        image_url="https://x.com/i.png",
    ), ctx)
    assert sub.media_url == "https://x.com/v.mp4"
    # gif_url back-compat populated with the same coalesced value
    assert sub.gif_url == "https://x.com/v.mp4"


def test_to_substitute_exercise_media_falls_through_to_image():
    ctx = _classify_reason(_req("Squat", None))
    sub = _to_substitute_exercise(_row(
        "Glute Bridge", id="r1", display_body_part="Glutes",
        gif_url=None, video_url=None,
        image_url="https://x.com/i.png",
    ), ctx)
    assert sub.media_url == "https://x.com/i.png"
    assert sub.gif_url == "https://x.com/i.png"


def test_to_substitute_exercise_no_media():
    ctx = _classify_reason(_req("Squat", None))
    sub = _to_substitute_exercise(_row(
        "Glute Bridge", id="r1", display_body_part="Glutes",
    ), ctx)
    assert sub.media_url is None
    assert sub.gif_url is None


def test_to_substitute_exercise_populates_all_fields():
    ctx = _classify_reason(_req("Squat", "knee injury"))
    sub = _to_substitute_exercise(_row(
        "Glute Bridge",
        id="r1",
        display_body_part="Glutes",
        body_part="Lower Body",
        equipment="bodyweight",
        target_muscle="Glutes (Gluteus Maximus)",
        difficulty_level=3,
        gif_url="https://x.com/g.gif",
    ), ctx)
    assert sub.name == "Glute Bridge"
    assert sub.library_id == "r1"
    assert sub.muscle_group == "Glutes"
    assert sub.body_part == "Lower Body"
    assert sub.equipment == "bodyweight"
    assert sub.target_muscle == "Glutes (Gluteus Maximus)"
    assert sub.difficulty == "3"
    assert sub.is_safe_for_reason is True
    assert sub.reason == "Knee-friendly alternative"


# ---------------------------------------------------------------------------
# Sanity — INTENT_KEYWORDS / PREGNANCY_UNSAFE_KEYWORDS shapes
# ---------------------------------------------------------------------------

def test_intent_keywords_shape():
    expected = {"no_equipment", "boring", "pregnant", "post_surgery", "menstrual"}
    assert set(INTENT_KEYWORDS.keys()) == expected
    for k, v in INTENT_KEYWORDS.items():
        assert isinstance(v, list) and len(v) >= 2


def test_pregnancy_keywords_include_jump_and_supine():
    assert "jump" in PREGNANCY_UNSAFE_KEYWORDS
    assert "supine" in PREGNANCY_UNSAFE_KEYWORDS
    assert "crunch" in PREGNANCY_UNSAFE_KEYWORDS


# ---------------------------------------------------------------------------
# Findings #12, #15, #17, #18, #19, #21
# ---------------------------------------------------------------------------

from api.v1.exercise_preferences_endpoints import (  # noqa: E402
    _normalize_exercise_name,
    _normalize_for_matching,
    INJURY_EXERCISE_CONTRAINDICATIONS,
)


def test_normalize_collapses_whitespace_and_punct():
    """Finding #15 — Bench-Press / Bench  Press / Bench (Press) all unify."""
    assert _normalize_for_matching("Bench-Press") == "bench press"
    assert _normalize_for_matching("Bench  Press") == "bench press"
    assert _normalize_for_matching("Bench (Press)") == "bench press"
    assert _normalize_for_matching("Bench/Press") == "bench press"
    assert _normalize_for_matching("  Bench Press  ") == "bench press"
    assert _normalize_exercise_name(None) == ""
    assert _normalize_exercise_name("Push-Up") == "Push Up"


def test_plyo_keywords_extended_to_all_joints():
    """Finding #12 — every joint blocks the plyo keyword family."""
    for joint in ("ankle", "hip", "wrist", "elbow", "shoulder", "neck", "knee", "lower_back"):
        joint_kws = INJURY_EXERCISE_CONTRAINDICATIONS.get(joint, [])
        assert "jump" in joint_kws, f"{joint} missing 'jump'"
        assert "plyo" in joint_kws, f"{joint} missing 'plyo'"
        assert "box jump" in joint_kws, f"{joint} missing 'box jump'"


def test_box_jump_blocked_under_ankle_injury():
    """Finding #12 — Box Jump + ankle sprain returns 0 plyo subs."""
    ctx = _classify_reason(_req("Box Jump", "ankle sprain"))
    assert _is_unsafe_by_name_keyword("180 Jump Turns", ctx) is True
    assert _is_unsafe_by_name_keyword("Box Jump To Step", ctx) is True
    assert _is_unsafe_by_name_keyword("Plyometric Push-Up", ctx) is True


def test_walking_lunge_blocked_under_knee_injury():
    """Finding #19 — sandbag/treadmill walking-lunge variants blocked even
    if avoid_if[] data hasn't been backfilled."""
    ctx = _classify_reason(_req("Walking Lunges", "knee injury"))
    assert _is_unsafe_by_name_keyword("Sandbag Walking Lunge", ctx) is True
    assert _is_unsafe_by_name_keyword("Treadmill Walking Lunge", ctx) is True
    assert _is_unsafe_by_name_keyword("Weighted Walking Lunge", ctx) is True


def test_normalize_punct_used_in_unsafe_check():
    """Finding #15 — punctuated names still match keyword guards."""
    ctx = _classify_reason(_req("Box Jump", "knee injury"))
    assert _is_unsafe_by_name_keyword("Box-Jump", ctx) is True
    assert _is_unsafe_by_name_keyword("Box (Jump)", ctx) is True


def test_seeded_jitter_widened_to_010():
    """Finding #18 — jitter range is now [0, 0.10), not [0, 0.05)."""
    samples = [_seeded_jitter(f"row-{i}", f"seed-{i}") for i in range(200)]
    assert min(samples) >= 0.0
    assert max(samples) < 0.10
    # At 200 samples, at least some should exceed 0.05 — proves wider range.
    assert any(s > 0.05 for s in samples), "jitter range did not widen"


def test_seed_includes_reason_so_jitter_differs_for_boring_vs_none():
    """Finding #18 — boring reason vs none must produce different seeds."""
    ctx_none = _classify_reason(_req("Goblet Squat", None))
    ctx_boring = _classify_reason(_req("Goblet Squat", "boring"))
    assert ctx_none.seed != ctx_boring.seed
    j_none = _seeded_jitter("row-1", ctx_none.seed)
    j_boring = _seeded_jitter("row-1", ctx_boring.seed)
    assert j_none != j_boring


def test_score_target_muscle_outweighs_body_part():
    """Finding #21 — same target_muscle (+0.30) > same body_part (+0.20)."""
    ctx = _classify_reason(_req("Bicep Curl", "elbow tendinitis"))
    ctx.original_target_muscle = "biceps"
    # Row A: same target_muscle (bicep)
    row_a = {"id": "a", "name": "Hammer Curl", "target_muscle": "biceps",
             "display_body_part": "Upper Arms", "category": "strength"}
    # Row B: same body_part but different target (e.g., triceps)
    row_b = {"id": "b", "name": "Tricep Pushdown", "target_muscle": "triceps",
             "display_body_part": "Upper Arms", "category": "strength"}
    score_a = _score_candidate(row_a, "biceps", ctx)
    score_b = _score_candidate(row_b, "biceps", ctx)
    assert score_a > score_b


def test_score_category_match_bonus_strength():
    """Finding #17 — same-category match adds +0.25; mismatch subtracts 0.25."""
    ctx = _classify_reason(_req("Wall Push-Up", None))
    ctx.original_category = "strength"
    row_strength = {"id": "s", "name": "Knee Push-Up", "category": "strength"}
    row_stretch = {"id": "t", "name": "Above Head Chest Stretch", "category": "stretching"}
    score_s = _score_candidate(row_strength, None, ctx)
    score_t = _score_candidate(row_stretch, None, ctx)
    # Strength→strength gets +0.25; strength→stretching gets −0.25 → 0.50 gap
    # before jitter (which is < 0.10).
    assert score_s - score_t > 0.30


def test_score_category_mismatch_no_penalty_for_post_surgery():
    """Finding #17 — post_surgery is allowed to lean toward stretching."""
    ctx = _classify_reason(_req("Squat", "post-surgery rehab"))
    ctx.original_category = "strength"
    row_stretch = {"id": "t", "name": "Hip Stretch", "category": "stretching"}
    score_t = _score_candidate(row_stretch, None, ctx)
    # No category mismatch penalty for post_surgery (intent gates the −0.25).
    # Stretching gets +0.15 from the post_surgery branch instead.
    assert score_t > 0.0


def test_to_substitute_exercise_safe_flag_reflects_truth():
    """Finding #13 — is_safe_for_reason must NOT lie when name-keyword fires."""
    ctx = _classify_reason(_req("Squat", "knee injury"))
    unsafe_row = {"id": "x", "name": "Hindu Squat", "category": "strength",
                  "target_muscle": "quadriceps", "display_body_part": "Upper Legs",
                  "avoid_if": []}
    sub = _to_substitute_exercise(unsafe_row, ctx)
    assert sub.is_safe_for_reason is False


def test_to_substitute_exercise_safe_flag_true_for_clean_row():
    ctx = _classify_reason(_req("Squat", "knee injury"))
    safe_row = {"id": "y", "name": "Glute Bridge", "category": "strength",
                "target_muscle": "glutes", "display_body_part": "Hips",
                "avoid_if": []}
    sub = _to_substitute_exercise(safe_row, ctx)
    assert sub.is_safe_for_reason is True


def test_classify_reason_populates_normalized_form():
    ctx = _classify_reason(_req("  Bench-Press  "))
    assert ctx.original_norm == "bench press"
    assert ctx.original_lower == "bench press"


def test_burpee_blocked_under_ankle():
    """Finding #12 — burpee (a plyo movement) blocked under ankle/knee."""
    ctx = _classify_reason(_req("Box Jump", "ankle sprain"))
    assert _is_unsafe_by_name_keyword("Burpee Box Jump", ctx) is True
