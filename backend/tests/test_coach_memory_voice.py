"""
Regression gate for row 199 (2026-08 backend prompt sweep): Settings ->
"What Coach remembers" showed a memory in third person ("User performs
workouts in the morning.") while every other string on that screen
addresses the user directly. The extraction prompt
(services/coach/memory/extractor.py `_SYSTEM`) used to instruct Gemini to
write `content` in "concise third-person-neutral form" — that's the exact
match for coach_memory row 3529030d-... (content = "User performs workouts
in the morning.").

Fix:
1. extractor.py `_SYSTEM` now instructs second-person voice for NEW memories.
2. services/coach/memory/voice.py `to_second_person()` — a deterministic
   (no LLM) best-effort rewrite applied at BOTH read chokepoints so legacy
   third-person rows display correctly without a paid bulk-rewrite pass:
     - api/v1/coach/memory.py `_to_item()` (the "What Coach remembers" list)
     - services/coach/memory/injector.py (the coach's own "WHAT I KNOW
       ABOUT YOU" prompt block + the morning-brief memory payload)

No paid Gemini calls: this whole suite is pure-Python string handling.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.coach.memory.voice import to_second_person  # noqa: E402
from api.v1.coach.memory import _to_item  # noqa: E402


class TestToSecondPerson:
    def test_the_exact_shipped_defect_row(self):
        # coach_memory row 3529030d-...: content = "User performs workouts
        # in the morning." (verbatim from row 199's evidence).
        assert (
            to_second_person("User performs workouts in the morning.")
            == "You perform workouts in the morning."
        )

    def test_user_has_pattern(self):
        assert (
            to_second_person("User has lower back pain, started this week.")
            == "You have lower back pain, started this week."
        )

    def test_user_possessive(self):
        assert (
            to_second_person("User's back hurts after deadlifts.")
            == "Your back hurts after deadlifts."
        )

    def test_elliptical_extraction_prompt_examples(self):
        # These are the literal example strings the OLD extraction prompt
        # modeled ("content: the fact in concise third-person-neutral
        # form (e.g. 'Has lower back pain, started this week', 'Prefers
        # morning workouts')") — both must normalize correctly.
        assert (
            to_second_person("Has lower back pain, started this week")
            == "You have lower back pain, started this week"
        )
        assert to_second_person("Prefers morning workouts") == "You prefer morning workouts"

    def test_already_second_person_is_a_noop(self):
        assert to_second_person("You already train in the morning.") == "You already train in the morning."

    def test_unrecognized_shape_is_left_alone(self):
        # Starts with a capitalized noun that happens to end in 's' but
        # isn't in the curated verb list — must not be mangled.
        assert to_second_person("Squats felt heavy on Tuesday.") == "Squats felt heavy on Tuesday."

    def test_empty_is_a_noop(self):
        assert to_second_person("") == ""
        assert to_second_person(None) is None


def test_memory_list_endpoint_serves_second_person():
    row = {
        "id": "3529030d-0000-0000-0000-000000000000",
        "memory_type": "semantic",
        "category": "schedule",
        "content": "User performs workouts in the morning.",
        "status": "active",
        "salience": 0.6,
        "sensitive": False,
        "source_quote": "What should I eat before a morning workout?",
    }
    item = _to_item(row)
    assert item.content == "You perform workouts in the morning."
    assert "User" not in item.content
