"""Regression gate: the Coach Recap card AND the "AI Summary" detailed-summary
card must never claim completed work that was never logged.

REPRODUCED BUG (device, screenshot-confirmed): a workout marked complete with
18 prescribed sets, exactly ONE `is_completed: true`, every single set at
`reps: 0` (0kg volume, 0 PRs) produced a recap whose banner correctly said
"Marked complete — log your sets next time..." but whose "What stood out"
section said "Successfully completed all prescribed sets" and "Maintained
consistent movement execution across all five exercises" — both fabricated
from the workout PLAN (`current_session['exercises']`/`['planned_exercises']`),
not the LOGGED `sets_json`. The "AI Summary" card (`generate_detailed_workout_summary`)
sits on the SAME screen directly below the recap and shares the exact same
PLAN-vs-LOGGED blind spot (its own `COMPLETION: N/M exercises completed` line
and `_deterministic_detailed_summary`'s `total_sets`/`completion_rate` inputs
are all client-supplied PLAN data too).

The fix (see `services/workout_feedback_rag_service.py`):
  - `derive_actual_session_completion(sets_json)` computes ground truth from
    the durable per-set store — used by BOTH surfaces below.
  - `generate_workout_recap` takes it as `actual_completion` and, AFTER the
    LLM call (or its deterministic fallback), deterministically overwrites
    `what_stood_out`/`headline`/`coaching_cue`/`prs` when there's no real
    logged work — this is the load-bearing guard, not just a prompt rule.
  - `generate_detailed_workout_summary` takes the same `actual_completion` and
    applies the markdown-prose equivalent: a WHOLE-BODY deterministic override
    (short + honest, not padded) when there's no real logged work, or a
    BULLET-LEVEL strip of "all sets/exercises completed" overclaims when
    completion is partial — again AFTER the LLM/fallback text is produced, so
    a prompt violation can never reach the client.

These tests stub the Gemini call to return EXACTLY the fabricated bug text
(mirroring the real `response.parsed` / `response.text` shapes) and assert on
the REAL generators, proving the deterministic guard — not just a prompt
change — is what stops the fabricated claims.

Run:
  backend/.venv312/bin/pytest backend/tests/test_recap_completion_truth.py -v -s
"""
from __future__ import annotations

import sys
from types import SimpleNamespace

import pytest

sys.path.insert(0, "backend")

from services.workout_feedback_rag_service import (  # noqa: E402
    WorkoutAiRecapPayload,
    derive_actual_session_completion,
    generate_detailed_workout_summary,
    generate_workout_recap,
)


# ---------------------------------------------------------------------------
# Fixture data — mirrors the real bug: workout_logs id 4afeaab7, 18 set
# entries, exactly ONE is_completed:true, every one at reps:0.
# ---------------------------------------------------------------------------

def _bug_sets_json() -> list[dict]:
    exercise_names = [
        "Kettlebell Swing", "Goblet Squat", "Renegade Row",
        "Box Step-Up", "Mountain Climber",
    ]
    sets = []
    for i in range(18):
        sets.append({
            "exercise_name": exercise_names[i % len(exercise_names)],
            "set_number": (i // len(exercise_names)) + 1,
            "set_type": "working",
            "reps": 0,
            "reps_completed": 0,
            "weight_kg": 0,
            "is_completed": (i == 0),  # exactly one true, matching the bug
        })
    return sets


def _bug_current_session() -> dict:
    exercise_names = [
        "Kettlebell Swing", "Goblet Squat", "Renegade Row",
        "Box Step-Up", "Mountain Climber",
    ]
    # The client-supplied PLAN — this is what made the naive completion
    # analysis in format_feedback_context look like 100% completion, since
    # `exercises` mirrors `planned_exercises` regardless of what was logged.
    plan = [
        {"name": n, "sets": 3, "reps": 12, "weight_kg": 0, "time_seconds": 0}
        for n in exercise_names
    ]
    return {
        "workout_log_id": "4afeaab7",
        "workout_id": "wk-balanced-kinetic-flow",
        "workout_name": "Balanced Kinetic Flow",
        "workout_type": "strength",
        "exercises": plan,
        "planned_exercises": plan,
        "total_time_seconds": 0,
        "total_rest_seconds": 0,
        "avg_rest_seconds": 0,
        "calories_burned": 0,
        "total_sets": 18,
        "total_reps": 0,
        "total_volume_kg": 0.0,
    }


class _FakeRagService:
    """Duck-typed stand-in — avoids the real service's ChromaDB Cloud client."""

    async def get_user_workout_history(self, user_id, n_results=10):
        return []

    async def get_exercise_weight_history(self, user_id, exercise_name, n_results=5):
        return []

    def format_feedback_context(self, current_session, past_sessions, weight_progressions):
        from services.workout_feedback_rag_service import WorkoutFeedbackRAGService
        # format_feedback_context doesn't touch `self` — safe to call unbound.
        return WorkoutFeedbackRAGService.format_feedback_context(
            self, current_session, past_sessions, weight_progressions
        )


def _fabricated_bug_response():
    """Exactly the fabricated text from the real device screenshot."""
    payload = WorkoutAiRecapPayload(
        headline="Balanced Kinetic Flow crushed — five exercises, zero excuses.",
        what_stood_out=[
            "Successfully completed all prescribed sets for the Balanced "
            "Kinetic Flow routine.",
            "Maintained consistent movement execution across all five "
            "exercises.",
        ],
        volume_comparison={
            "current_volume_kg": 0.0,
            "previous_volume_kg": None,
            "delta_pct": None,
            "comparable_workout_name": None,
            "summary": "First session of its kind.",
        },
        prs=[],
        coaching_cue="Log your working weight next time to track progression.",
        notes_reference=None,
    )
    return SimpleNamespace(parsed=payload)


async def _run_generate_recap(monkeypatch, actual_completion):
    async def _fake_llm_call(**kwargs):
        return _fabricated_bug_response()

    monkeypatch.setattr(
        "services.gemini.constants.gemini_generate_with_retry",
        _fake_llm_call,
        raising=True,
    )

    return await generate_workout_recap(
        gemini_service=SimpleNamespace(model="fake-model"),
        rag_service=_FakeRagService(),
        user_id="test-user-1aa02a24",
        current_session=_bug_current_session(),
        earned_prs=None,
        logged_notes=None,
        total_workouts_completed=12,
        exercise_contexts=None,
        injury_context=None,
        rest_analysis=None,
        session_signals=None,
        use_kg=False,
        actual_completion=actual_completion,
    )


# ---------------------------------------------------------------------------
# derive_actual_session_completion — ground truth extraction
# ---------------------------------------------------------------------------

def test_derive_actual_completion_detects_zero_real_work():
    stats = derive_actual_session_completion(_bug_sets_json())
    assert stats["total_sets"] == 18
    assert stats["completed_sets"] == 1  # one is_completed:true
    assert stats["completed_with_real_work"] == 0  # but reps:0 on all of them
    assert stats["has_real_logged_work"] is False
    assert stats["all_completed"] is False


def test_derive_actual_completion_none_when_no_sets_json():
    # No evidence to guard on — must fail OPEN (None), not assume zero work.
    assert derive_actual_session_completion(None) is None


def test_derive_actual_completion_all_completed():
    sets = [
        {"exercise_name": "Squat", "set_type": "working", "reps": 8,
         "weight_kg": 60, "is_completed": True}
        for _ in range(4)
    ]
    stats = derive_actual_session_completion(sets)
    assert stats["all_completed"] is True
    assert stats["has_real_logged_work"] is True


# ---------------------------------------------------------------------------
# generate_workout_recap — the real bug repro
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_recap_never_claims_completion_with_no_real_logged_work(monkeypatch):
    """THE regression test: 1-of-18 sets completed, all reps zero.

    The stubbed Gemini call returns the EXACT fabricated bug text. If the
    deterministic guard is doing its job, none of it should survive.
    """
    actual_completion = derive_actual_session_completion(_bug_sets_json())
    recap = await _run_generate_recap(monkeypatch, actual_completion)

    stood_out_text = " ".join(recap["what_stood_out"]).lower()
    headline_text = (recap.get("headline") or "").lower()

    # The exact fabricated claims must be gone.
    assert "all prescribed sets" not in stood_out_text
    assert "consistent movement execution" not in stood_out_text
    assert "successfully completed" not in stood_out_text

    # No sentence anywhere in the recap may assert full completion.
    for field in ("headline", "coaching_cue"):
        text = (recap.get(field) or "").lower()
        assert "completed all" not in text
        assert "all prescribed" not in text

    # It must plainly say nothing was logged.
    assert "no logged sets" in stood_out_text or "no sets" in headline_text or \
        "nothing" in stood_out_text
    assert recap["prs"] == []


@pytest.mark.asyncio
async def test_recap_partial_completion_does_not_generalize_to_all(monkeypatch):
    """Case B: SOME real work logged, but not all prescribed sets.

    completed_with_real_work (2) != total_sets (4) -> any "all sets" /
    "all exercises" claim in what_stood_out must be dropped.
    """
    sets = [
        {"exercise_name": "Bench Press", "set_type": "working", "reps": 8,
         "weight_kg": 60, "is_completed": True},
        {"exercise_name": "Bench Press", "set_type": "working", "reps": 6,
         "weight_kg": 60, "is_completed": True},
        {"exercise_name": "Incline Press", "set_type": "working", "reps": 0,
         "weight_kg": 0, "is_completed": False},
        {"exercise_name": "Incline Press", "set_type": "working", "reps": 0,
         "weight_kg": 0, "is_completed": False},
    ]
    actual_completion = derive_actual_session_completion(sets)
    assert actual_completion["has_real_logged_work"] is True
    assert actual_completion["all_completed"] is False

    recap = await _run_generate_recap(monkeypatch, actual_completion)
    stood_out_text = " ".join(recap["what_stood_out"]).lower()
    assert "all prescribed sets" not in stood_out_text
    assert "all five exercises" not in stood_out_text


@pytest.mark.asyncio
async def test_recap_unaffected_when_no_completion_evidence(monkeypatch):
    """actual_completion=None (old client, no sets_json) must fail OPEN —
    the guard must not run (and therefore must not raise), same as before
    this fix existed."""
    recap = await _run_generate_recap(monkeypatch, actual_completion=None)
    # Should not raise, and should return the (unguarded) LLM content as-is.
    assert recap["what_stood_out"]


# ---------------------------------------------------------------------------
# generate_detailed_workout_summary — the "AI Summary" card, same screen,
# same bug class. Markdown prose, not a structured payload, so the guard is
# whole-body (no real work) or bullet-level (partial), not a sentence list.
# ---------------------------------------------------------------------------

_FABRICATED_BUG_MARKDOWN = """**Strengths**
- Successfully completed all prescribed sets for the Balanced Kinetic Flow routine.
- Maintained consistent movement execution across all five exercises.

**Weaknesses**
- Nothing major stood out as a weakness — keep the standard high.

**What to improve**
- Push for a small load increase next session.

**What to do next**
- Add 2.5kg to your strongest lift next time."""


async def _run_generate_detailed_summary(monkeypatch, actual_completion, markdown=None):
    async def _fake_llm_call(**kwargs):
        return SimpleNamespace(text=markdown or _FABRICATED_BUG_MARKDOWN)

    monkeypatch.setattr(
        "services.gemini.constants.gemini_generate_with_retry",
        _fake_llm_call,
        raising=True,
    )

    return await generate_detailed_workout_summary(
        gemini_service=SimpleNamespace(model="fake-model"),
        rag_service=_FakeRagService(),
        user_id="test-user-1aa02a24",
        current_session=_bug_current_session(),
        earned_prs=None,
        logged_notes=None,
        total_workouts_completed=12,
        exercise_contexts=None,
        injury_context=None,
        rest_analysis=None,
        session_signals=None,
        use_kg=False,
        actual_completion=actual_completion,
    )


@pytest.mark.asyncio
async def test_detailed_summary_no_real_logged_work_is_honest_and_short(monkeypatch):
    """Same repro as the recap test (1-of-18 sets, all reps zero). The stubbed
    Gemini call returns the EXACT fabricated bug markdown — the deterministic
    whole-body override must replace it entirely with a short, honest summary,
    not a padded one."""
    actual_completion = derive_actual_session_completion(_bug_sets_json())
    result = await _run_generate_detailed_summary(monkeypatch, actual_completion)
    md = result["summary_markdown"].lower()

    # The fabricated claims must be completely gone.
    assert "successfully completed all prescribed sets" not in md
    assert "consistent movement execution" not in md
    assert "keep the standard high" not in md  # the fabricated "Weaknesses" bullet too

    # It must plainly say nothing was logged, and stay short (no padding to
    # invent 4 distinct sections' worth of content from zero data).
    assert "no logged sets" in md
    assert result["is_fallback"] is True
    # Structural contract (4 headers) still holds — the client parses these.
    for section in ("**Strengths**", "**Weaknesses**", "**What to improve**", "**What to do next**"):
        assert section.lower() in md


@pytest.mark.asyncio
async def test_detailed_summary_partial_completion_strips_overclaim_bullets(monkeypatch):
    """Case B: some real work logged (2 of 4 sets), but the fabricated markdown
    still claims full completion. Only the overclaiming bullets must be
    stripped — everything else in the summary survives untouched."""
    sets = [
        {"exercise_name": "Bench Press", "set_type": "working", "reps": 8,
         "weight_kg": 60, "is_completed": True},
        {"exercise_name": "Bench Press", "set_type": "working", "reps": 6,
         "weight_kg": 60, "is_completed": True},
        {"exercise_name": "Incline Press", "set_type": "working", "reps": 0,
         "weight_kg": 0, "is_completed": False},
        {"exercise_name": "Incline Press", "set_type": "working", "reps": 0,
         "weight_kg": 0, "is_completed": False},
    ]
    actual_completion = derive_actual_session_completion(sets)
    assert actual_completion["has_real_logged_work"] is True
    assert actual_completion["all_completed"] is False

    partial_markdown = """**Strengths**
- Completed all prescribed sets across every exercise today.
- Bench Press top set was a strong 8 reps at 60kg.

**Weaknesses**
- Nothing major stood out as a weakness.

**What to improve**
- Maintained consistent execution across all exercises this session.

**What to do next**
- Add a small load increase on Bench Press next time."""

    result = await _run_generate_detailed_summary(
        monkeypatch, actual_completion, markdown=partial_markdown
    )
    md = result["summary_markdown"]
    md_lower = md.lower()

    # Overclaiming bullets gone.
    assert "completed all prescribed sets across every exercise" not in md_lower
    assert "consistent execution across all exercises" not in md_lower
    # Genuine, non-overclaiming content survives untouched.
    assert "Bench Press top set was a strong 8 reps at 60kg." in md
    assert "Nothing major stood out as a weakness." in md
    assert "Add a small load increase on Bench Press next time." in md
    # The "What to improve" section, emptied by the strip, gets an honest
    # replacement rather than being left blank.
    assert "logged real work on 2 of 4 prescribed sets" in md_lower


@pytest.mark.asyncio
async def test_detailed_summary_unaffected_when_no_completion_evidence(monkeypatch):
    """actual_completion=None (no sets_json) must fail OPEN — same as the
    recap — so an old client still gets a working (unguarded) summary."""
    result = await _run_generate_detailed_summary(monkeypatch, actual_completion=None)
    assert result["summary_markdown"] == _FABRICATED_BUG_MARKDOWN
    assert result["is_fallback"] is False
