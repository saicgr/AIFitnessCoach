"""
Regression tests for coach persona application in chat replies.

Pre-fix bug (Sentry 2026-05-10): Coach Mike (motivational) replied with
generic AI assistant tone — "That's a great choice for recovery and
mobility!" — because both coach_response_node and coach_action_node
appended a "Be friendly, helpful…" suffix AFTER the persona prompt,
overriding it.

This test verifies that the persona-defining tokens land in the prompt
that gets sent to Gemini for three contrasting personas. We don't call
Gemini (cost + flake) — we assert on the SYSTEM PROMPT shape, which is
the deterministic input that drives persona behavior.

Run with: pytest tests/test_coach_persona.py -v
"""
import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.langgraph_agents.coach_agent.nodes import get_coach_system_prompt
from services.langgraph_agents.personality import build_personality_prompt


# Three personas that should produce VERY different prompt content.
PERSONA_FIXTURES = {
    "drill_sergeant": {
        "ai_settings": {
            "coach_persona_id": "sergeant_max",
            "coach_name": "Sergeant Max",
            "coaching_style": "drill-sergeant",
            "communication_tone": "tough-love",
            "encouragement_level": 0.4,
        },
        "must_contain_in_persona_block": [
            "DROP AND GIVE ME 20",  # the VOICE example for drill-sergeant
            "ALL CAPS",
        ],
        "must_contain_in_lock": [
            "Sergeant Max",
            "drill-sergeant",
            "USE ALL CAPS",
        ],
    },
    "scientist": {
        "ai_settings": {
            "coach_persona_id": "dr_sarah",
            "coach_name": "Dr Sarah",
            "coaching_style": "scientist",
            "communication_tone": "formal",
            "encouragement_level": 0.6,
        },
        "must_contain_in_persona_block": [
            "Schoenfeld",  # cited mechanism in scientist VOICE example
            "Analytical and evidence-based",
        ],
        "must_contain_in_lock": [
            "Dr Sarah",
            "scientist",
            "cite mechanisms",
        ],
    },
    "zen_master": {
        "ai_settings": {
            "coach_persona_id": "zen_maya",
            "coach_name": "Zen Maya",
            "coaching_style": "zen-master",
            "communication_tone": "casual",
            "encouragement_level": 0.7,
        },
        "must_contain_in_persona_block": [
            "Calm, measured, philosophical",
            "Breathe into the movement",  # VOICE example
        ],
        "must_contain_in_lock": [
            "Zen Maya",
            "zen-master",
            "calm and grounded",
        ],
    },
}


@pytest.mark.parametrize("name,fixture", PERSONA_FIXTURES.items())
def test_persona_lock_appears_after_style_block(name: str, fixture: dict):
    """The persona-lock reminder must appear at the END of the personality
    prompt, AFTER the style/tone blocks. LLMs follow the most-recent
    instruction strongest, so the lock has to be last."""
    prompt = build_personality_prompt(
        ai_settings=_settings(fixture["ai_settings"]),
        agent_name="Coach",
        agent_specialty="fitness coaching",
    )

    # Persona-block content present
    for token in fixture["must_contain_in_persona_block"]:
        assert token in prompt, (
            f"[{name}] Expected persona-block token {token!r} missing from prompt"
        )

    # Persona-lock present and contains the persona name + style
    assert "PERSONA LOCK" in prompt, f"[{name}] Persona lock section missing"
    lock_idx = prompt.index("PERSONA LOCK")
    lock_section = prompt[lock_idx:]
    for token in fixture["must_contain_in_lock"]:
        assert token in lock_section, (
            f"[{name}] Expected lock-section token {token!r} missing from "
            f"the persona-lock block (at position {lock_idx})"
        )


@pytest.mark.parametrize("name,fixture", PERSONA_FIXTURES.items())
def test_coach_system_prompt_includes_persona(name: str, fixture: dict):
    """The full coach system prompt (base + personality) must include the
    user's persona name and style — not the default 'Coach' fallback."""
    full_prompt = get_coach_system_prompt(fixture["ai_settings"])

    coach_name = fixture["ai_settings"]["coach_name"]
    style = fixture["ai_settings"]["coaching_style"]

    assert coach_name in full_prompt, (
        f"[{name}] Coach name {coach_name!r} not in full system prompt"
    )
    assert style in full_prompt, (
        f"[{name}] Coaching style {style!r} not in full system prompt"
    )


def test_no_persona_killing_suffix_in_response_node():
    """Regression guard for the Sentry 2026-05-10 bug: ensure the previous
    'friendly, helpful coaching advice. Be personable, encouraging…'
    suffix is NOT being appended to the coach response system prompt.
    Read coach_agent/nodes.py source directly so any reintroduction is
    caught at unit-test time, not in a Gemini-billed integration test."""
    nodes_src_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "services", "langgraph_agents", "coach_agent", "nodes.py",
    )
    with open(nodes_src_path, "r") as f:
        src = f.read()

    forbidden_phrases = [
        "Be personable, encouraging, and adapt to their fitness level!",
        "Be friendly and helpful!",
    ]
    for phrase in forbidden_phrases:
        # Allow the phrase to appear inside a comment (the "NB:" explanation)
        # but NOT inside an f-string that gets sent to Gemini.
        # Heuristic: forbidden if the phrase appears OUTSIDE a python comment.
        for line in src.split("\n"):
            stripped = line.lstrip()
            if stripped.startswith("#"):
                continue
            assert phrase not in line, (
                f"Persona-killing suffix detected in active code line: {line!r}\n"
                f"This was the Sentry 2026-05-10 bug — the suffix overrode "
                f"non-friendly personas. Keep it inside a comment block only."
            )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _settings(d: dict):
    """Build an AISettings instance from a dict fixture."""
    from models.chat import AISettings
    return AISettings(**d)
