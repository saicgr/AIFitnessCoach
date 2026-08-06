"""
Regression gate for row 170 (2026-08 backend prompt sweep), second evidence
bullet: Library -> exercise detail for "Treadmill Incline Jog" showed
instruction copy with exercise-science jargon ("recruits the posterior
chain (glutes, hamstrings, calves) maximally", "shifts stress to the knee
and reduces efficiency"). The first bullet (Hip/Shoulder/Ankle CARs) is
covered by migrations/2405_plain_language_cars_instructions.sql +
tests/test_cars_instructions_plain_language.py; this is the same fix for the
second exercise the row's evidence names.

Root cause: same as 2405 — this row lives in `exercise_library_manual`, the
sibling table unioned into `exercise_library_cleaned` (the MV actually
served) that migrations 2084/2085 never touched. `exercise_library` (base
table) only has the already-plain "Treadmill Jogging" — verified via the DB.

Fix: migrations/2407_plain_language_treadmill_incline_jog.sql. NOT applied
(per this task's rule: write the migration, report it needs applying — do
not apply it yourself). This test statically parses the migration SQL.
"""
import os
import re

_MIGRATION_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "migrations", "2407_plain_language_treadmill_incline_jog.sql",
)

_JARGON_RE = re.compile(
    r"\b(posterior chain|recruits|maximally|efficiency|form breakdown"
    r"|overstride)\b",
    re.IGNORECASE,
)

_ORIGINAL_TEXT = (
    "1. Set incline to 4–8% and speed to 4.5–5.5 mph; step onto the belt "
    "with an upright posture — lean forward from the ankles, not the hips "
    "or waist, to work with the grade.\n"
    "4. Drive your knees forward and up on each step; push off the balls "
    "of the feet, keeping heels from slamming down — this recruits the "
    "posterior chain (glutes, hamstrings, calves) maximally."
)


def _read_migration_sql() -> str:
    with open(_MIGRATION_PATH, "r") as f:
        return f.read()


def _instructions_block(sql: str, exercise_id: str) -> str:
    pattern = re.compile(
        r"SET instructions = '(.*?)'\s*\nWHERE id = '" + re.escape(exercise_id) + r"'",
        re.DOTALL,
    )
    m = pattern.search(sql)
    assert m, f"Could not find UPDATE block for id={exercise_id} in migration SQL"
    return m.group(1)


def test_migration_file_exists():
    assert os.path.isfile(_MIGRATION_PATH), "Row 170 (Treadmill Incline Jog) fix migration is missing"


def test_new_instructions_are_plain_language():
    sql = _read_migration_sql()
    text = _instructions_block(sql, "6669527f-5f45-425a-936f-cdffff4d3971")
    hit = _JARGON_RE.search(text)
    assert not hit, f"Jargon still present: {hit}"
    assert "glutes, hamstrings, and calves" in text, "should still name the muscles worked, just plainly"


def test_jargon_checker_discriminates_on_the_original_text():
    # Negative-test proxy: the same check applied to the ORIGINAL (pre-fix,
    # still-live in exercise_library_manual) text must fail.
    assert _JARGON_RE.search(_ORIGINAL_TEXT), (
        "Jargon checker did not flag the known-bad original text — the "
        "checker itself is broken."
    )
