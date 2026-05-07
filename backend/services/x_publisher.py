"""
X (Twitter) publisher — mints access tokens via OAuth 2.0 refresh-token rotation
and posts threads to @chetwitt123 on demand.

Refresh-token persistence: X invalidates the prior refresh token on every use,
so the rotated value is written back to x_oauth_state immediately after the
token endpoint responds. If the DB write fails after a successful rotation,
the next call will be locked out — log loudly and surface the new token in
the exception so an operator can re-seed manually.
"""
from __future__ import annotations

import base64
import logging
import os
from typing import Optional

import asyncpg
import httpx

logger = logging.getLogger(__name__)

X_TOKEN_URL = "https://api.x.com/2/oauth2/token"
X_TWEETS_URL = "https://api.x.com/2/tweets"
X_USERNAME = "chetwitt123"


class XPublisherError(Exception):
    pass


def _basic_auth_header() -> str:
    cid = os.environ["X_CLIENT_ID"]
    secret = os.environ["X_CLIENT_SECRET"]
    return base64.b64encode(f"{cid}:{secret}".encode()).decode()


async def _load_refresh_token(conn: asyncpg.Connection) -> str:
    row = await conn.fetchrow(
        "SELECT refresh_token FROM x_oauth_state WHERE id = 1"
    )
    if row is None:
        raise XPublisherError(
            "x_oauth_state empty — re-run scripts/x_oauth_bootstrap.py and "
            "seed the refresh token."
        )
    return row["refresh_token"]


async def _save_refresh_token(conn: asyncpg.Connection, refresh_token: str) -> None:
    await conn.execute(
        "UPDATE x_oauth_state SET refresh_token = $1, updated_at = now() WHERE id = 1",
        refresh_token,
    )


async def mint_access_token(conn: asyncpg.Connection) -> str:
    """Exchange the stored refresh token for a fresh access token, rotating
    the refresh token in the DB before returning."""
    refresh_token = await _load_refresh_token(conn)

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(
            X_TOKEN_URL,
            data={
                "grant_type": "refresh_token",
                "refresh_token": refresh_token,
                "client_id": os.environ["X_CLIENT_ID"],
            },
            headers={
                "Authorization": f"Basic {_basic_auth_header()}",
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )

    if response.status_code != 200:
        raise XPublisherError(
            f"refresh failed ({response.status_code}): {response.text}"
        )

    payload = response.json()
    new_refresh = payload.get("refresh_token")
    access_token = payload.get("access_token")

    if not new_refresh or not access_token:
        raise XPublisherError(f"malformed token response: {payload}")

    # Persist the rotated refresh token BEFORE we hand the access token to the
    # caller. If this write fails we want to fail loudly with the new token in
    # the error so an operator can manually re-seed the DB.
    try:
        await _save_refresh_token(conn, new_refresh)
    except Exception as e:
        raise XPublisherError(
            f"refresh token rotated but DB write failed; re-seed manually: "
            f"{new_refresh!r} (original error: {e})"
        )

    return access_token


async def post_thread(
    conn: asyncpg.Connection, tweets: list[str]
) -> dict[str, str | list[str]]:
    """Post a list of tweet bodies as a reply-chained thread.
    Returns {'tweet_ids': [...], 'url': 'https://x.com/<user>/status/<first_id>'}.
    """
    if not tweets:
        raise XPublisherError("post_thread called with empty tweets")

    access_token = await mint_access_token(conn)
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json",
    }

    tweet_ids: list[str] = []
    in_reply_to: Optional[str] = None

    async with httpx.AsyncClient(timeout=30) as client:
        for i, body in enumerate(tweets):
            payload: dict = {"text": body}
            if in_reply_to:
                payload["reply"] = {"in_reply_to_tweet_id": in_reply_to}

            response = await client.post(X_TWEETS_URL, json=payload, headers=headers)
            if response.status_code not in (200, 201):
                raise XPublisherError(
                    f"tweet {i+1}/{len(tweets)} failed "
                    f"({response.status_code}): {response.text}"
                )
            data = response.json().get("data", {})
            tweet_id = data.get("id")
            if not tweet_id:
                raise XPublisherError(f"tweet {i+1} missing id: {response.text}")
            tweet_ids.append(tweet_id)
            in_reply_to = tweet_id

    return {
        "tweet_ids": tweet_ids,
        "url": f"https://x.com/{X_USERNAME}/status/{tweet_ids[0]}",
    }
