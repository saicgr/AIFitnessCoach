"""Regression gate — "Coach noticed" card copy must read in plain language.

2026-08 bug report: the COACH NOTICED body on the home coach card repeated
the raw `injury.body_part` string TWICE, unmodified. When an injury was
inferred from a specific exercise's `target_muscle` text (Gemini/library
format `"quadriceps (quadriceps femoris), hamstrings (biceps femoris)"`),
the body read:

    "Your quadriceps (quadriceps femoris), hamstrings (biceps femoris) is
    still settling. I kept quadriceps (quadriceps femoris), hamstrings
    (biceps femoris)-loading work lighter today..."

Two faults: (a) Latin anatomical parentheticals leaking into user-facing
copy (project rule: plain language only), and (b) the whole phrase
interpolated twice — the second time hyphenated into "…-loading work",
which doesn't read as English. There was also a grammar bug: a
multi-muscle list took a singular verb ("quads, hamstrings **is** still
settling").

Fix lives in `api/v1/coach/daily_insight.py`:
  * `_short_muscle_label()` routes `body_part` through
    `services.exercise_muscle_resolver.text_to_muscles` — the SAME closed
    vocabulary the strength-score breadth work already uses to normalize
    this exact Gemini/library text shape — so plain names agree with the
    Flutter side's canonical bucket names (`muscle_aliases.dart`) instead of
    a second hand-rolled vocabulary. Unknown text falls back to a
    generically paren-stripped version of the raw value (no muscle
    enumeration added in this module).
  * `_build_coach_noticed()` uses the derived label ONCE per sentence, with
    a `verb`/`pronoun` pair ("is"/"it" vs "are"/"them") carrying the
    reference the rest of the way.
  * The `_build_greeting()` injury chip labels ("How's my X feeling?") had
    the same jargon-leak class and are fixed the same way — the dispatch
    `body_part` payload (consumed by POST /coach/injury-action) is left
    untouched; only the chip TEXT changed.

Run with: backend/.venv312/bin/python -m pytest tests/test_coach_noticed_muscle_copy.py -v
(backend/.venv is pinned to Python 3.9 and cannot import this package — see
tests/test_daily_insight_day0_honesty.py's note on the same constraint.)
"""
import os
import re
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from api.v1.coach.daily_insight import (  # noqa: E402
    _short_muscle_label,
    _build_coach_noticed,
    _build_greeting,
)

_MULTI_MUSCLE_BODY_PART = (
    "quadriceps (quadriceps femoris), hamstrings (biceps femoris)"
)
_PAREN_RE = re.compile(r"\([^)]*\)")


def _no_parens(text: str) -> bool:
    return not _PAREN_RE.search(text)


# ── _short_muscle_label ──────────────────────────────────────────────────
def test_short_muscle_label_strips_latin_parens_and_flags_plural():
    label, is_plural = _short_muscle_label(_MULTI_MUSCLE_BODY_PART)
    assert _no_parens(label), f"Latin parenthetical leaked into label: {label!r}"
    assert "femoris" not in label.lower()
    assert is_plural is True
    # Plain canonical tokens, not the raw clinical string.
    assert "quads" in label
    assert "hamstrings" in label


def test_short_muscle_label_single_muscle_is_singular():
    label, is_plural = _short_muscle_label("knee")
    assert label == "knee"
    assert is_plural is False


def test_short_muscle_label_unknown_token_falls_back_to_raw():
    # Not in the resolver's closed vocabulary — must still degrade
    # gracefully to the raw (paren-stripped) value, never raise/blank out.
    label, is_plural = _short_muscle_label("shin (tibialis anterior)")
    assert label == "shin"
    assert is_plural is False


def test_short_muscle_label_empty_input():
    label, is_plural = _short_muscle_label(None)
    assert label == ""
    assert is_plural is False


# ── _build_coach_noticed: acute/subacute (protect) branch ───────────────
def test_coach_noticed_acute_multi_muscle_no_jargon_no_repeat_grammatical():
    snapshot = {
        "injury": {
            "body_part": _MULTI_MUSCLE_BODY_PART,
            "phase": "acute",
            "severity": "moderate",
        }
    }
    cn = _build_coach_noticed(snapshot)
    assert cn is not None
    body = cn["body"]
    assert _no_parens(body), f"Latin parenthetical leaked into body: {body!r}"
    assert "femoris" not in body.lower()
    # The verbose muscle phrase must not be interpolated twice.
    assert body.count("quads") <= 1
    assert body.count("hamstrings") <= 1
    # No hyphenated "-loading work" mangling from a second interpolation.
    assert "-loading" not in body
    # Plural subject takes a plural verb.
    assert "quads and hamstrings are" in body or "hamstrings and quads are" in body
    assert " is still settling" not in body
    assert cn["chat_seed"].count("quads") <= 1
    assert _no_parens(cn["chat_seed"])


def test_coach_noticed_acute_single_muscle_grammatical():
    snapshot = {
        "injury": {"body_part": "knee", "phase": "subacute", "severity": "mild"},
    }
    cn = _build_coach_noticed(snapshot)
    assert cn is not None
    body = cn["body"]
    assert "Your knee is still settling" in body
    assert "aggravate it" in body
    assert "aggravate them" not in body


# ── _build_coach_noticed: recovery/reintroduction branch ────────────────
def test_coach_noticed_recovery_multi_muscle_no_jargon_grammatical():
    snapshot = {
        "injury": {
            "body_part": _MULTI_MUSCLE_BODY_PART,
            "phase": "recovery",
            "severity": "moderate",
        }
    }
    cn = _build_coach_noticed(snapshot)
    assert cn is not None
    body = cn["body"]
    assert _no_parens(body)
    assert "femoris" not in body.lower()
    assert body.count("quads") <= 1
    assert body.count("hamstrings") <= 1
    assert "are far enough along" in body
    assert "loads them hard" in body
    assert "loads it hard" not in body


def test_coach_noticed_recovery_single_muscle_grammatical():
    snapshot = {
        "injury": {"body_part": "elbow", "phase": "reintroduction", "severity": "mild"},
    }
    cn = _build_coach_noticed(snapshot)
    assert cn is not None
    body = cn["body"]
    assert "Your elbow is far enough along" in body
    assert "loads it hard" in body


def test_coach_noticed_single_muscle_canonical_plural_noun_takes_plural_verb():
    # "shoulder" normalizes to the canonical bucket "shoulders" — a single
    # reported body part, but a grammatically plural noun ("your shoulders
    # ARE", not "your shoulders IS"). Regression case for the naive
    # "one item => singular" heuristic.
    snapshot = {
        "injury": {"body_part": "shoulder", "phase": "reintroduction", "severity": "mild"},
    }
    cn = _build_coach_noticed(snapshot)
    assert cn is not None
    body = cn["body"]
    assert "Your shoulders are far enough along" in body
    assert "loads them hard" in body


def test_coach_noticed_no_injury_returns_none():
    assert _build_coach_noticed({}) is None
    assert _build_coach_noticed({"injury": {}}) is None


# ── _build_greeting chip labels (same jargon-leak class) ─────────────────
def test_greeting_injury_chip_label_has_no_jargon_dispatch_value_untouched():
    snapshot = {
        "injury": {"body_part": _MULTI_MUSCLE_BODY_PART, "phase": "recovery"},
    }
    result = _build_greeting(
        first_name="Alex",
        bucket="morning",
        snapshot=snapshot,
        next_workout=None,
        local_date_iso="2026-08-05",
        rotate=0,
    )
    chip = next(
        c for c in result["chips"] if c.get("action") == "injury_resolved"
    )
    assert _no_parens(chip["label"])
    assert "femoris" not in chip["label"].lower()
    # Functional dispatch payload must stay the RAW value — unrelated to
    # display copy, and consumed as-is by POST /coach/injury-action.
    assert chip["body_part"] == _MULTI_MUSCLE_BODY_PART


def test_greeting_injury_chip_label_acute_phase_no_jargon():
    snapshot = {
        "injury": {"body_part": _MULTI_MUSCLE_BODY_PART, "phase": "acute"},
    }
    result = _build_greeting(
        first_name="Alex",
        bucket="morning",
        snapshot=snapshot,
        next_workout=None,
        local_date_iso="2026-08-05",
        rotate=0,
    )
    chip = next(c for c in result["chips"] if "feeling?" in c.get("label", ""))
    assert _no_parens(chip["label"])
    assert "femoris" not in chip["label"].lower()
