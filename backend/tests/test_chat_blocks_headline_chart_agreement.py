"""
E2E register #132a — the Evening Recap / home coach card's headline and its
chart disagreed ("Stack a few more steps" over a "Protein · last 3 logged
days" chart). Root cause: build_briefing_blocks silently substituted the
next-priority topic when the leading pillar had no data of its own. Pure
unit test -- _compute_by_topic (the only DB-touching part) is monkeypatched.

Run with: pytest tests/test_chat_blocks_headline_chart_agreement.py -v
"""

import uuid

import pytest

from services.coach import chat_blocks as cb


@pytest.fixture(autouse=True)
def _fake_by_topic(monkeypatch):
    """Only 'nourish' has data -- mirrors the reported repro (no Health
    connection, so 'move' never has a chart of its own)."""
    fake = {
        "nourish": [{"type": "chart", "title": "Protein · last 3 logged days", "spec": {}}],
    }
    monkeypatch.setattr(cb, "_compute_by_topic", lambda user_id: dict(fake))
    cb._by_topic_cache.clear()
    yield
    cb._by_topic_cache.clear()


def test_strict_suppresses_unrelated_chart_for_dataless_pillar():
    """The home card's actual call site (_home_blocks) always passes
    strict=True. A 'move' headline with no move data must render NO chart,
    not a substituted, unrelated one."""
    blocks = cb.build_briefing_blocks(
        str(uuid.uuid4()), leading_pillar="move", max_blocks=3,
        bypass_cache=True, strict=True,
    )
    assert blocks == []


def test_non_strict_callers_keep_old_substitution_behavior():
    """morning_brief/evening_recap's early call (before the headline pillar
    is known) doesn't pass strict -- unaffected by this fix, by design."""
    blocks = cb.build_briefing_blocks(
        str(uuid.uuid4()), leading_pillar="move", max_blocks=3, bypass_cache=True,
    )
    assert len(blocks) == 1
    assert blocks[0]["title"].startswith("Protein")


def test_strict_pillar_with_data_renders_normally():
    blocks = cb.build_briefing_blocks(
        str(uuid.uuid4()), leading_pillar="nourish", max_blocks=3,
        bypass_cache=True, strict=True,
    )
    assert len(blocks) == 1
    assert blocks[0]["title"].startswith("Protein")


def test_strict_pillar_with_no_chartable_topic_is_unaffected():
    """'train' has no chart type of its own -- falling through to the
    default priority for it is pre-existing, intentional design, not the bug
    this row targets."""
    blocks = cb.build_briefing_blocks(
        str(uuid.uuid4()), leading_pillar="train", max_blocks=3,
        bypass_cache=True, strict=True,
    )
    assert len(blocks) == 1
    assert blocks[0]["title"].startswith("Protein")
