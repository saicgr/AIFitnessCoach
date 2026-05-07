"""
X publisher endpoints — Telegram-driven daily build-in-public posting.

Two routes:
  POST /api/v1/x/draft           — called by the daily Anthropic routine.
                                   Sends a draft to Telegram with 🚀/❌ buttons
                                   and inserts a x_pending_drafts row.
  POST /api/v1/x/telegram-webhook — called by Telegram on every update for our
                                    bot. Handles button taps (post / skip) and
                                    arbitrary text (currently no-op).

Auth model:
  - /draft is gated by X-Internal-Token == X_DRAFT_INTERNAL_TOKEN env var
    (the routine has the secret; nobody else does).
  - /telegram-webhook is gated by X-Telegram-Bot-Api-Secret-Token header
    set when registering the webhook with Telegram. Telegram echoes the
    secret on every callback so we can authenticate the source.
"""
from __future__ import annotations

import json
import logging
import os
from typing import Any, Optional

import asyncpg
import httpx
from fastapi import APIRouter, Header, HTTPException, Request
from pydantic import BaseModel, Field

from services import x_publisher

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/x", tags=["x-publisher"])

TELEGRAM_API = "https://api.telegram.org"


# ---------- helpers ----------


async def _db() -> asyncpg.Connection:
    db_url = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://")
    # statement_cache_size=0 — Supabase's transaction-mode PgBouncer pooler
    # does not support prepared statements; asyncpg's default cache breaks
    # with DuplicatePreparedStatementError on the second query.
    return await asyncpg.connect(db_url, statement_cache_size=0)


def _bot_url(method: str) -> str:
    token = os.environ["TELEGRAM_BOT_TOKEN"]
    return f"{TELEGRAM_API}/bot{token}/{method}"


def _format_draft_message(angle: str, tweets: list[str]) -> str:
    header = f"📝 X DRAFT\n\nAngle: {angle}\n\n"
    body_parts = []
    for i, t in enumerate(tweets, 1):
        body_parts.append(f"[Tweet {i}/{len(tweets)} — {len(t)} chars]\n{t}")
    return header + "\n\n---\n\n".join(body_parts)


def _draft_keyboard(draft_id: int) -> dict:
    return {
        "inline_keyboard": [
            [
                {"text": "🚀 Post to X", "callback_data": f"post:{draft_id}"},
                {"text": "❌ Skip", "callback_data": f"skip:{draft_id}"},
            ]
        ]
    }


# ---------- /draft ----------


class DraftRequest(BaseModel):
    angle: str = Field(..., max_length=200)
    tweets: list[str] = Field(..., min_length=1, max_length=20)


@router.get("/recent-drafts")
async def list_recent_drafts(
    limit: int = 30,
    status: Optional[str] = None,
    x_internal_token: Optional[str] = Header(None, alias="X-Internal-Token"),
) -> list[dict]:
    """Return recent drafts so the social-post-creator agent can avoid
    re-pitching angles the user already skipped or posted. Same internal
    token gating as /draft."""
    expected = os.environ.get("X_DRAFT_INTERNAL_TOKEN")
    if not expected or x_internal_token != expected:
        raise HTTPException(status_code=401, detail="unauthorized")
    if limit < 1 or limit > 200:
        raise HTTPException(status_code=422, detail="limit must be 1-200")
    if status and status not in ("pending", "posted", "skipped", "failed"):
        raise HTTPException(status_code=422, detail="invalid status")

    conn = await _db()
    try:
        if status:
            rows = await conn.fetch(
                "SELECT id, status, angle, created_at, posted_url "
                "FROM x_pending_drafts WHERE status = $1 "
                "ORDER BY id DESC LIMIT $2",
                status, limit,
            )
        else:
            rows = await conn.fetch(
                "SELECT id, status, angle, created_at, posted_url "
                "FROM x_pending_drafts ORDER BY id DESC LIMIT $1",
                limit,
            )
        return [
            {
                "id": r["id"],
                "status": r["status"],
                "angle": r["angle"],
                "created_at": r["created_at"].isoformat(),
                "posted_url": r["posted_url"],
            }
            for r in rows
        ]
    finally:
        await conn.close()


@router.post("/draft")
async def submit_draft(
    payload: DraftRequest,
    x_internal_token: Optional[str] = Header(None, alias="X-Internal-Token"),
) -> dict[str, Any]:
    expected = os.environ.get("X_DRAFT_INTERNAL_TOKEN")
    if not expected or x_internal_token != expected:
        raise HTTPException(status_code=401, detail="unauthorized")

    # Per-tweet length validation. X allows 280 chars but our cap is 225 —
    # tighter safety margin (LLM char-counters are unreliable, especially
    # with embedded newlines and emoji), AND shorter tweets read better.
    for i, t in enumerate(payload.tweets):
        if len(t) > 225:
            raise HTTPException(
                status_code=422,
                detail=f"tweet {i+1} is {len(t)} chars (max 225)",
            )

    chat_id = int(os.environ["TELEGRAM_CHAT_ID"])
    text = _format_draft_message(payload.angle, payload.tweets)

    conn = await _db()
    try:
        # Send placeholder first so we can capture message_id, then update
        # the row with the keyboard after we have a draft_id to embed in
        # callback_data.
        async with httpx.AsyncClient(timeout=30) as client:
            send_resp = await client.post(
                _bot_url("sendMessage"),
                json={"chat_id": chat_id, "text": text, "disable_web_page_preview": True},
            )
            if send_resp.status_code != 200:
                raise HTTPException(
                    status_code=502,
                    detail=f"telegram sendMessage failed: {send_resp.text}",
                )
            message_id = send_resp.json()["result"]["message_id"]

            row = await conn.fetchrow(
                """
                INSERT INTO x_pending_drafts
                  (telegram_message_id, telegram_chat_id, tweets, angle)
                VALUES ($1, $2, $3, $4)
                RETURNING id
                """,
                message_id,
                chat_id,
                json.dumps(payload.tweets),
                payload.angle,
            )
            draft_id = row["id"]

            await client.post(
                _bot_url("editMessageReplyMarkup"),
                json={
                    "chat_id": chat_id,
                    "message_id": message_id,
                    "reply_markup": _draft_keyboard(draft_id),
                },
            )

        return {"draft_id": draft_id, "telegram_message_id": message_id}
    finally:
        await conn.close()


# ---------- /telegram-webhook ----------


@router.post("/telegram-webhook")
async def telegram_webhook(
    request: Request,
    x_telegram_bot_api_secret_token: Optional[str] = Header(
        None, alias="X-Telegram-Bot-Api-Secret-Token"
    ),
) -> dict[str, str]:
    expected = os.environ.get("TELEGRAM_WEBHOOK_SECRET")
    if not expected or x_telegram_bot_api_secret_token != expected:
        raise HTTPException(status_code=401, detail="unauthorized")

    update = await request.json()

    callback = update.get("callback_query")
    if not callback:
        # Non-button update (text message, edited message, etc.) — ignored
        # for now. Future: "post-now <text>" command for ad-hoc posting.
        return {"status": "ignored"}

    data = callback.get("data", "")
    if ":" not in data:
        return {"status": "bad_callback"}
    action, draft_id_str = data.split(":", 1)
    try:
        draft_id = int(draft_id_str)
    except ValueError:
        return {"status": "bad_draft_id"}

    callback_id = callback["id"]
    msg = callback.get("message", {})
    chat_id = msg.get("chat", {}).get("id")
    message_id = msg.get("message_id")

    conn = await _db()
    try:
        row = await conn.fetchrow(
            "SELECT id, tweets, angle, status FROM x_pending_drafts WHERE id = $1",
            draft_id,
        )
        if row is None:
            await _answer_callback(callback_id, "Draft not found.")
            return {"status": "not_found"}
        if row["status"] != "pending":
            await _answer_callback(callback_id, f"Already {row['status']}.")
            return {"status": "already_resolved"}

        if action == "skip":
            await conn.execute(
                "UPDATE x_pending_drafts SET status = 'skipped', updated_at = now() "
                "WHERE id = $1",
                draft_id,
            )
            await _strip_keyboard_and_append(
                chat_id, message_id, "\n\n❌ Skipped — draft preserved in DB"
            )
            await _answer_callback(callback_id, "Skipped.")
            return {"status": "skipped"}

        if action == "post":
            tweets_raw = row["tweets"]
            tweets = json.loads(tweets_raw) if isinstance(tweets_raw, str) else tweets_raw
            try:
                result = await x_publisher.post_thread(conn, tweets)
            except Exception as e:
                logger.exception("post_thread failed for draft %s", draft_id)
                await conn.execute(
                    "UPDATE x_pending_drafts SET status = 'failed', "
                    "error_message = $2, updated_at = now() WHERE id = $1",
                    draft_id,
                    str(e)[:500],
                )
                await _strip_keyboard_and_append(
                    chat_id, message_id, f"\n\n⚠️ Post failed: {e}"
                )
                await _answer_callback(callback_id, "Post failed — see message.")
                return {"status": "failed", "error": str(e)}

            url = result["url"]
            await conn.execute(
                "UPDATE x_pending_drafts SET status = 'posted', "
                "posted_url = $2, updated_at = now() WHERE id = $1",
                draft_id,
                url,
            )
            await _strip_keyboard_and_append(
                chat_id, message_id, f"\n\n✅ Posted: {url}"
            )
            await _answer_callback(callback_id, "Posted.")
            return {"status": "posted", "url": url}

        return {"status": "unknown_action"}
    finally:
        await conn.close()


async def _answer_callback(callback_id: str, text: str) -> None:
    async with httpx.AsyncClient(timeout=10) as client:
        await client.post(
            _bot_url("answerCallbackQuery"),
            json={"callback_query_id": callback_id, "text": text},
        )


async def _strip_keyboard_and_append(
    chat_id: int, message_id: int, suffix: str
) -> None:
    """Remove the inline keyboard and append a status line so the user can
    see at-a-glance whether the draft was posted, skipped, or failed."""
    async with httpx.AsyncClient(timeout=10) as client:
        # editMessageText replaces both the text and the reply_markup; we
        # fetch the current text via getChat? No — Telegram doesn't expose
        # message text on inline-keyboard updates without extra calls. Easier:
        # remove the keyboard, then append the suffix as a reply.
        await client.post(
            _bot_url("editMessageReplyMarkup"),
            json={"chat_id": chat_id, "message_id": message_id, "reply_markup": {}},
        )
        await client.post(
            _bot_url("sendMessage"),
            json={
                "chat_id": chat_id,
                "text": suffix.strip(),
                "reply_to_message_id": message_id,
                "disable_web_page_preview": False,
            },
        )
