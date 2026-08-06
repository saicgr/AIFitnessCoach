"""
Regression gate for row 170 (2026-08 backend prompt sweep): Library ->
exercise detail for "Hip CARs" / "Shoulder CARs" / "Ankle CARs" showed
instruction copy no ordinary user can parse ("create an irradiation brace
that anchors the pelvis", "maximum articular excursion", "neuromuscular
control and synovial fluid distribution") and never expanded the "CARs"
abbreviation (Controlled Articular Rotations).

Root cause: these 3 rows live in `exercise_library_manual`, a SIBLING table
to `exercise_library` that's unioned into the SAME `exercise_library_cleaned`
materialized view the Library tab and GET /exercises/{id} actually serve
(migrations/2037_materialize_exercise_library_cleaned.sql). Migrations
2084/2085 (the instruction-quality rewrite CLAUDE.md documents) only
touched the base `exercise_library` table, so `exercise_library_manual`'s
jargon-heavy hand-authored instructions shipped untouched.

Fix: migrations/2405_plain_language_cars_instructions.sql rewrites all 3
rows' `instructions` — plain language, technique-correct, CARs expanded on
first use. This migration has NOT been applied (per this task's rule: write
a migration for a data-content fix and report it needs applying — do not
apply it yourself). This test statically parses the migration SQL and
checks the NEW text against a jargon list; it also verifies the SAME check
correctly flags the ORIGINAL (pre-fix, still-live) instructions text as a
negative-test proxy, since the fix lives in an unapplied migration rather
than a code diff that can be toggled live.
"""
import os
import re

_MIGRATION_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "migrations", "2405_plain_language_cars_instructions.sql",
)

# Mirrors the spirit of scripts/audit_program_copy_clarity.py's JARGON list,
# scoped to the specific terms found in the pre-fix CARs instructions.
_JARGON_RE = re.compile(
    r"\b(irradiation|articular excursion|synovial|neuromuscular|distal tension"
    r"|plantarflex|dorsiflex|scapula loaded|spinal compensation)\b",
    re.IGNORECASE,
)

# The exact pre-fix instructions read from exercise_library_manual (row 170
# evidence + this task's own DB verification) — used only to prove the
# jargon checker actually discriminates (negative-test proxy).
_ORIGINAL_HIP_CARS = (
    "1. Stand on one leg next to a wall, fingertips touching lightly for "
    "balance. Inhale deeply and brace your entire body — squeeze the "
    "stance-side glute, lock the ribcage down, and flatten the lumbar spine "
    "slightly to create an irradiation brace that anchors the pelvis.\n"
    "3. Continue the rotation upward (hip abduction) and behind you into "
    "hip extension, maintaining pelvis stability throughout — the goal is "
    "maximum articular excursion, not spinal compensation.\n"
    "5. Switch legs. Move deliberately and slowly — 8-10 seconds per full "
    "circle — to maximize neuromuscular control and synovial fluid "
    "distribution at the hip joint."
)
_ORIGINAL_ANKLE_CARS = (
    "2. Lift one foot off the ground and begin drawing the largest possible "
    "circle with your toes, moving through full ankle range: point "
    "(plantarflex), invert, dorsiflex, evert."
)
_ORIGINAL_SHOULDER_CARS = (
    "1. Stand tall, feet hip-width apart, one arm at your side. Make a "
    "gentle fist to create mild distal tension; keep the torso completely "
    "still throughout.\n"
    "6. Keep the scapula loaded (not shrugged) and the rib cage stable — "
    "resist any trunk lean or rotation to compensate for limited range."
)


def _read_migration_sql() -> str:
    with open(_MIGRATION_PATH, "r") as f:
        return f.read()


def _instructions_block(sql: str, exercise_id: str) -> str:
    """Extract the SET instructions = '...' body immediately preceding a
    `WHERE id = '<id>'` clause."""
    pattern = re.compile(
        r"SET instructions = '(.*?)'\s*\nWHERE id = '" + re.escape(exercise_id) + r"'",
        re.DOTALL,
    )
    m = pattern.search(sql)
    assert m, f"Could not find UPDATE block for id={exercise_id} in migration SQL"
    return m.group(1)


def test_migration_file_exists():
    assert os.path.isfile(_MIGRATION_PATH), "Row 170 fix migration is missing"


def test_new_hip_cars_instructions_are_plain_language_and_expand_cars():
    sql = _read_migration_sql()
    text = _instructions_block(sql, "a39b6ec1-84b4-489f-8f1a-49c964c478d9")
    assert not _JARGON_RE.search(text), f"Jargon still present: {_JARGON_RE.search(text)}"
    assert "Controlled Articular Rotations" in text


def test_new_shoulder_cars_instructions_are_plain_language_and_expand_cars():
    sql = _read_migration_sql()
    text = _instructions_block(sql, "18b86417-1446-4224-9d50-68a226e4201b")
    assert not _JARGON_RE.search(text)
    assert "Controlled Articular Rotations" in text


def test_new_ankle_cars_instructions_are_plain_language_and_expand_cars():
    sql = _read_migration_sql()
    text = _instructions_block(sql, "07f0600b-5285-4925-b335-3d13c1b145f5")
    assert not _JARGON_RE.search(text)
    assert "Controlled Articular Rotations" in text


class TestJargonCheckerDiscriminates:
    """Negative-test proxy: the same jargon check applied to the ORIGINAL
    (pre-fix, still-live in exercise_library_manual) instructions text must
    fail — proving the assertions above aren't vacuously true."""

    def test_original_hip_cars_text_fails_the_check(self):
        assert _JARGON_RE.search(_ORIGINAL_HIP_CARS), (
            "Jargon checker did not flag the known-bad original Hip CARs "
            "text — the checker itself is broken."
        )

    def test_original_ankle_cars_text_fails_the_check(self):
        assert _JARGON_RE.search(_ORIGINAL_ANKLE_CARS)

    def test_original_shoulder_cars_text_fails_the_check(self):
        assert _JARGON_RE.search(_ORIGINAL_SHOULDER_CARS)
