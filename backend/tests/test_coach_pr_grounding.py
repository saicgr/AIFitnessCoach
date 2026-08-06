"""
Regression gate for row 54 (2026-08 backend prompt sweep): the coach
congratulated a user on personal records and achievements that did not
exist. "Share my PRs this month" -> intent=navigate, destination=trophy_room
-> Coach Mike replied "Nice work on your progress this month! I've opened
your trophy room so you can see all your latest milestones and personal
records" for an account with 0 personal_records rows and 0 user_achievements
rows. Root cause: coach_action_node's acknowledgment prompt for a NAVIGATE
action never fetched or was told the user's actual PR/achievement counts —
it free-associated a celebratory reply purely from the user's message and
the destination name.

Fix (services/langgraph_agents/coach_agent/nodes.py):
1. `format_achievement_grounding(user_id, destination)` fetches REAL
   personal_records / user_achievements counts for the small set of
   gamification destinations (trophy_room, achievements, milestones,
   leaderboard, rewards) and folds them into the ACTION context.
2. The acknowledgment system prompt now explicitly forbids congratulating
   the user on progress/PRs/streaks/milestones not present in that context.

No paid Gemini calls here — GeminiService.chat is stubbed.
"""
import os
import sys
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from services.langgraph_agents.coach_agent.nodes import (  # noqa: E402
    coach_action_node,
    format_achievement_grounding,
)
from models.chat import CoachIntent  # noqa: E402


def _fake_db(pr_rows, ach_rows):
    """A minimal stand-in for get_supabase_db() covering only the
    `.table(...).select(...).eq(...).limit(...).execute().data` chain
    format_achievement_grounding uses."""
    db = MagicMock()

    def table(name):
        rows = pr_rows if name == "personal_records" else ach_rows
        chain = MagicMock()
        chain.select.return_value = chain
        chain.eq.return_value = chain
        chain.limit.return_value = chain
        chain.execute.return_value = MagicMock(data=rows)
        return chain

    db.client.table.side_effect = table
    return db


class TestFormatAchievementGrounding:
    def test_zero_counts_instructs_no_celebration(self):
        with patch("core.db.get_supabase_db", return_value=_fake_db([], [])):
            out = format_achievement_grounding("user-1", "trophy_room")
        assert "0 personal record" in out
        assert "0 achievement" in out
        assert "do NOT congratulate" in out

    def test_real_counts_are_reported(self):
        with patch(
            "core.db.get_supabase_db",
            return_value=_fake_db([{"id": "a"}, {"id": "b"}], [{"id": "c"}]),
        ):
            out = format_achievement_grounding("user-1", "trophy_room")
        assert "2 personal record" in out
        assert "1 achievement" in out

    def test_non_gamification_destination_is_a_noop(self):
        # Non-gamification destinations must never trigger the extra
        # DB round trip or grounding text — behavior for every other
        # navigate target stays byte-identical to before this fix.
        with patch("core.db.get_supabase_db") as mock_get_db:
            out = format_achievement_grounding("user-1", "nutrition")
        assert out == ""
        mock_get_db.assert_not_called()

    def test_no_user_id_is_a_noop(self):
        out = format_achievement_grounding(None, "trophy_room")
        assert out == ""

    def test_db_error_fails_open(self):
        with patch("core.db.get_supabase_db", side_effect=RuntimeError("boom")):
            out = format_achievement_grounding("user-1", "trophy_room")
        assert out == ""


@pytest.mark.asyncio
async def test_coach_action_node_grounds_trophy_room_navigation():
    """The DEFECT this guards: an account with 0 PRs/achievements asks to
    'share my PRs this month', the coach routes to navigate/trophy_room, and
    the system prompt sent to Gemini must contain the real (zero) counts and
    the anti-fabrication instruction — not just a bare 'Navigating to
    trophy_room' with free rein to invent a congratulation.
    """
    state = {
        "intent": CoachIntent.NAVIGATE,
        "destination": "trophy_room",
        "user_id": "user-1",
        "user_message": "Share my PRs this month",
        "conversation_history": [],
        "ai_settings": None,
        "locale": "en",
    }

    captured = {}

    async def fake_chat(user_message, system_prompt=None, conversation_history=None):
        captured["system_prompt"] = system_prompt
        return "I've opened your trophy room."

    with patch("core.db.get_supabase_db", return_value=_fake_db([], [])), \
         patch("services.langgraph_agents.coach_agent.nodes.GeminiService") as MockGemini:
        MockGemini.return_value.chat = AsyncMock(side_effect=fake_chat)
        result = await coach_action_node(state)

    prompt = captured["system_prompt"]
    assert prompt is not None, "GeminiService.chat was not called with a system_prompt"
    assert "0 personal record" in prompt, (
        "Real (zero) PR count missing from the acknowledgment prompt — the "
        "model has no way to know it should not celebrate a nonexistent PR."
    )
    assert "0 achievement" in prompt
    assert "Never congratulate the user on progress, PRs, streaks, or" in prompt
    assert result["action_data"]["destination"] == "trophy_room"
