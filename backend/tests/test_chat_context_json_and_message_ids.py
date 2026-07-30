"""Regression gate for E2E register rows 19, 36 and 37.

Row 36 — `chat_history.context_json` is JSONB and `_save_chat_to_db` wrote
`json.dumps(...)` into it, so every coach turn persisted as a double-encoded
jsonb STRING. The client's `contextJson is Map` was false (saved conversations
lost every action card / chart / agent identity) and every jsonb operator
missed those rows.

Row 37 — `/chat/history` and `/chat/search` minted `<uuid>_assistant` bubble
ids. That is not a uuid, so DELETE /chat/messages/{id} and
PATCH /chat/messages/{id}/pin were rejected by PostgREST and the mutation never
landed (delete came back on reload; regenerate left the stale reply on screen).

Row 19 — the onboarding coach-preview degraded path returned a canned
persona paragraph that does not answer the question asked, and the client
renders any non-empty reply under "<Coach>'s mid-set — here's how he answers
that:". The degraded path must carry NO reply text.
"""

import asyncio
import uuid

import pytest
from fastapi import HTTPException

import api.v1.chat as chat_api
import api.v1.coach_preview as coach_preview_api


# ── Row 36 — writer must pass a dict into the JSONB column ──────────────────

class _CapturingDB:
    def __init__(self):
        self.chat_data = None
        self.sessions = self

    def create_chat_message(self, chat_data):
        self.chat_data = chat_data
        return {"id": chat_data.get("id")}

    def touch_session(self, session_id, user_id):  # pragma: no cover - unused
        pass


def test_save_chat_to_db_writes_a_jsonb_object_not_a_string(monkeypatch):
    db = _CapturingDB()
    monkeypatch.setattr(chat_api, "get_supabase_db", lambda: db)

    chat_api._save_chat_to_db(
        user_id=str(uuid.uuid4()),
        message="log my lunch",
        response_message="Logged.",
        response_intent="log_food",
        response_agent_type="nutrition",
        response_rag_context_used=False,
        response_action_data={"action": "food_logged", "food_log_id": "abc"},
        response_blocks=[{"type": "macro_bar"}],
        coach_persona_id="coach_mike",
    )

    ctx = db.chat_data["context_json"]
    assert isinstance(ctx, dict), (
        "context_json must be handed to PostgREST as a dict — a str stores a "
        "double-encoded jsonb scalar and breaks every jsonb operator"
    )
    # The nested payload the client reads must survive as real structure.
    assert ctx["action_data"]["action"] == "food_logged"
    assert ctx["blocks"] == [{"type": "macro_bar"}]
    assert ctx["coach_persona_id"] == "coach_mike"
    assert ctx["agent_type"] == "nutrition"


def test_save_chat_to_db_omits_context_when_there_is_no_intent(monkeypatch):
    db = _CapturingDB()
    monkeypatch.setattr(chat_api, "get_supabase_db", lambda: db)

    chat_api._save_chat_to_db(
        user_id=str(uuid.uuid4()),
        message="hi",
        response_message="hey",
        response_intent=None,
        response_agent_type="coach",
        response_rag_context_used=False,
        response_action_data=None,
    )
    assert db.chat_data["context_json"] is None


# ── Row 37 — bubble ids must round-trip to the row PK ───────────────────────

def test_resolve_chat_row_id_strips_every_role_suffix():
    row_id = str(uuid.uuid4())
    for bubble_id in (row_id, f"{row_id}_u", f"{row_id}_user", f"{row_id}_assistant"):
        assert chat_api._resolve_chat_row_id(bubble_id) == row_id


def test_resolve_chat_row_id_rejects_a_malformed_id_with_400():
    with pytest.raises(HTTPException) as exc:
        chat_api._resolve_chat_row_id("not-a-uuid_assistant")
    assert exc.value.status_code == 400

    with pytest.raises(HTTPException) as exc:
        chat_api._resolve_chat_row_id("")
    assert exc.value.status_code == 400


def test_history_and_search_hand_back_a_deletable_assistant_id(monkeypatch):
    """Assistant bubbles must carry the bare row PK, not a `_assistant` composite."""
    row_id = str(uuid.uuid4())
    user_id = str(uuid.uuid4())
    rows = [{
        "id": row_id,
        "user_id": user_id,
        "user_message": "what should I eat before a morning workout?",
        "ai_response": "Something light with carbs.",
        "context_json": {"intent": "question", "agent_type": "nutrition"},
        "timestamp": "2026-07-30T12:00:00+00:00",
        "is_pinned": False,
    }]

    class _DB:
        def list_chat_history(self, uid, limit=50, offset=0):
            return rows

        def search_chat_history(self, uid, query, limit):
            return rows

    monkeypatch.setattr(chat_api, "get_supabase_db", lambda: _DB())
    current_user = {"id": user_id}

    history = asyncio.run(
        chat_api.get_chat_history.__wrapped__(
            request=None, user_id=user_id, current_user=current_user,
            limit=50, offset=0,
        )
    )
    search = asyncio.run(
        chat_api.search_chat.__wrapped__(
            request=None,
            body=chat_api.ChatSearchRequest(query="morning", limit=20),
            current_user=current_user,
        )
    )

    for messages, surface in ((history, "history"), (search, "search")):
        assistant = [m for m in messages if m.role == "assistant"]
        assert assistant, f"{surface} returned no assistant bubble"
        for msg in assistant:
            assert msg.id == row_id, (
                f"{surface} assistant id {msg.id!r} is not the row PK — "
                "delete/regenerate/pin cannot send it back"
            )
            # Whatever the surface hands out must survive the mutating path.
            assert chat_api._resolve_chat_row_id(msg.id) == row_id
        for msg in messages:
            assert chat_api._resolve_chat_row_id(msg.id) == row_id


# ── Row 19 — the degraded preview must not answer a different question ──────

def _preview_body(**kw):
    return coach_preview_api.CoachPreviewRequest(
        coach_id="coach_mike",
        coach_name="Coach Mike",
        coaching_style=kw.pop("coaching_style", "motivational"),
        question=kw.pop("question", "What should I eat before a morning workout?"),
        **kw,
    )


@pytest.mark.parametrize(
    "style", ["motivational", "scientist", "drill-sergeant", "zen-master", "hype-beast"]
)
def test_coach_preview_fallback_carries_no_reply_text(style):
    """Any non-empty reply is rendered as "here's how he answers that"."""
    resp = coach_preview_api._fallback("timeout")
    assert resp.fallback is True
    assert resp.reply == "", (
        "a degraded preview turn must carry NO answer text — the client labels "
        "any reply as the coach answering the question that was asked"
    )
    assert resp.reason == "timeout"
    # And there is no canned per-style answer table left to regress to.
    assert not hasattr(coach_preview_api, "_FALLBACK_REPLIES")


@pytest.mark.parametrize(
    "failure,reason",
    [
        (asyncio.TimeoutError(), "timeout"),
        (RuntimeError("gemini exploded"), "model_error"),
        (None, "empty_completion"),
    ],
)
def test_coach_preview_degrades_without_an_answer(monkeypatch, failure, reason):
    async def _chat(**kwargs):
        if failure is not None:
            raise failure
        return "   "  # safety-filtered / blank completion

    monkeypatch.setattr(
        coach_preview_api, "_get_gemini", lambda: type("G", (), {"chat": staticmethod(_chat)})()
    )

    resp = asyncio.run(
        coach_preview_api.coach_preview.__wrapped__(
            body=_preview_body(), request=None, user={"id": str(uuid.uuid4())}
        )
    )
    assert resp.fallback is True
    assert resp.reply == ""
    assert resp.reason == reason


def test_coach_preview_passes_a_real_reply_through(monkeypatch):
    async def _chat(**kwargs):
        return '"Oats and a banana about an hour out — light, quick carbs."'

    monkeypatch.setattr(
        coach_preview_api, "_get_gemini", lambda: type("G", (), {"chat": staticmethod(_chat)})()
    )

    resp = asyncio.run(
        coach_preview_api.coach_preview.__wrapped__(
            body=_preview_body(), request=None, user={"id": str(uuid.uuid4())}
        )
    )
    assert resp.fallback is False
    assert resp.reason is None
    assert resp.reply.startswith("Oats and a banana")
