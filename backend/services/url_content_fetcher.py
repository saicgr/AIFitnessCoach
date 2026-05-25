"""
url_content_fetcher.py — normalizes any shared URL into a SharedContent blob
the rest of the share pipeline can reason over.

Per the App Store compliance section of the Imports plan, YouTube uses the
official YouTube Data API + youtube_transcript_api ONLY — no yt-dlp on
youtube.com / youtu.be URLs. yt-dlp is used for Instagram and TikTok,
where there is no equivalent official path. Reddit uses an unauthenticated
HTTP fetch modeled on `scripts/reddit_scout.py`. X uses oEmbed.

Downloaded media (Instagram, TikTok) is uploaded to S3 with the
`imports/social/` prefix and is scheduled for deletion by the existing media
cleanup cron after successful extraction. We never re-surface the raw
downloaded video file to the user.
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import shutil
import tempfile
from dataclasses import dataclass, field
from typing import Any, Optional
from urllib.parse import urlparse

import httpx

from core.config import get_settings
from services.s3_service import get_s3_service

settings = get_settings()

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Data shapes
# ---------------------------------------------------------------------------

@dataclass
class MediaAsset:
    s3_key: str
    type: str                   # "video" | "image" | "audio"
    duration_s: Optional[float] = None
    content_type: Optional[str] = None
    size_bytes: Optional[int] = None


@dataclass
class SharedContent:
    source: str                 # "youtube" | "instagram" | "tiktok" | "reddit" | "x" | "web"
    kind: str                   # "video" | "image" | "carousel" | "text" | "mixed"
    original_url: str
    title: Optional[str] = None
    caption: Optional[str] = None
    body: Optional[str] = None
    transcript: Optional[str] = None
    author_handle: Optional[str] = None
    author_name: Optional[str] = None
    media: list[MediaAsset] = field(default_factory=list)
    locked: bool = False        # True when content is private / age-gated
    error: Optional[str] = None

    def as_text(self) -> str:
        """Concatenated text representation for the intent classifier."""
        parts: list[str] = []
        if self.title:
            parts.append(f"Title: {self.title}")
        if self.author_handle or self.author_name:
            parts.append(f"By: {self.author_handle or self.author_name}")
        if self.caption:
            parts.append(f"Caption:\n{self.caption}")
        if self.body:
            parts.append(f"Body:\n{self.body}")
        if self.transcript:
            parts.append(f"Transcript:\n{self.transcript}")
        return "\n\n".join(parts).strip()


# ---------------------------------------------------------------------------
# Limits
# ---------------------------------------------------------------------------

MAX_VIDEO_BYTES = 500 * 1024 * 1024              # 500 MB
MAX_VIDEO_DURATION_S = 60 * 60                   # 60 min cap
MAX_TRANSCRIPT_CHARS = 60_000                    # ~60k chars; anything longer truncated


# ---------------------------------------------------------------------------
# Source detection
# ---------------------------------------------------------------------------

def detect_source(url: str) -> str:
    host = (urlparse(url).hostname or "").lower()
    if not host:
        return "web"
    if any(host == h or host.endswith("." + h) for h in ("youtube.com", "youtu.be")):
        return "youtube"
    if "instagram.com" in host:
        return "instagram"
    if "tiktok.com" in host:
        return "tiktok"
    if "reddit.com" in host or host == "redd.it":
        return "reddit"
    if host in {"x.com", "www.x.com", "twitter.com", "www.twitter.com"}:
        return "x"
    return "web"


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------

async def fetch(url: str) -> SharedContent:
    """Dispatch to the right per-source fetcher and return a SharedContent."""
    source = detect_source(url)
    try:
        if source == "youtube":
            return await _fetch_youtube(url)
        if source in ("instagram", "tiktok"):
            return await _fetch_via_ytdlp(url, source=source)
        if source == "reddit":
            return await _fetch_reddit(url)
        if source == "x":
            return await _fetch_x(url)
        return await _fetch_generic(url)
    except Exception as exc:
        logger.warning(f"[url_content_fetcher] {source} fetch failed: {exc}", exc_info=True)
        return SharedContent(
            source=source,
            kind="text",
            original_url=url,
            error=str(exc)[:240],
        )


# ===========================================================================
# YouTube — Data API v3 + youtube_transcript_api (NO yt-dlp)
# ===========================================================================

_YT_VIDEO_ID_RE = re.compile(
    r"(?:youtu\.be/|youtube\.com/(?:watch\?v=|shorts/|embed/|v/))([A-Za-z0-9_-]{6,})"
)


def _extract_youtube_id(url: str) -> Optional[str]:
    m = _YT_VIDEO_ID_RE.search(url)
    return m.group(1) if m else None


async def _fetch_youtube(url: str) -> SharedContent:
    video_id = _extract_youtube_id(url)
    if not video_id:
        return SharedContent(
            source="youtube", kind="text", original_url=url,
            error="couldn't extract video id",
        )

    api_key = os.environ.get("YT_DATA_API_KEY") or getattr(settings, "yt_data_api_key", None)

    title: Optional[str] = None
    description: Optional[str] = None
    channel: Optional[str] = None
    duration_s: Optional[float] = None
    chapters: list[dict[str, Any]] = []

    if api_key:
        try:
            async with httpx.AsyncClient(timeout=10) as client:
                resp = await client.get(
                    "https://www.googleapis.com/youtube/v3/videos",
                    params={"part": "snippet,contentDetails", "id": video_id, "key": api_key},
                )
                if resp.status_code == 200:
                    items = resp.json().get("items", [])
                    if items:
                        snippet = items[0].get("snippet", {})
                        details = items[0].get("contentDetails", {})
                        title = snippet.get("title")
                        description = snippet.get("description")
                        channel = snippet.get("channelTitle")
                        duration_s = _parse_iso8601_duration(details.get("duration", ""))
        except Exception as e:
            logger.info(f"[YT] Data API call failed (continuing transcript-only): {e}")

    transcript: Optional[str] = None
    try:
        # youtube_transcript_api is sync; run in a thread
        transcript = await asyncio.to_thread(_fetch_youtube_transcript, video_id)
    except Exception as e:
        logger.info(f"[YT] transcript fetch failed: {e}")

    # Pull simple chapter markers out of the description ("00:00 Warm-up\n02:30 Bench …")
    if description:
        chapters = _parse_description_chapters(description)

    body_extras = ""
    if chapters:
        body_extras = "\n\nChapters:\n" + "\n".join(
            f"{c.get('start_ts','?')} — {c.get('title','')}" for c in chapters
        )

    return SharedContent(
        source="youtube",
        kind="video",
        original_url=url,
        title=title,
        body=(description or "") + body_extras if (description or chapters) else None,
        transcript=(transcript[:MAX_TRANSCRIPT_CHARS] if transcript else None),
        author_handle=channel,
        author_name=channel,
        media=[],  # we never download the bitstream from YouTube — compliance
    )


def _fetch_youtube_transcript(video_id: str) -> Optional[str]:
    """Sync transcript fetcher — runs in a thread. Returns a plain-text
    transcript with newlines per segment.

    Handles both the legacy `YouTubeTranscriptApi.get_transcript(video_id)`
    classmethod (versions <= 0.6.x) AND the new instance-based
    `YouTubeTranscriptApi().fetch(video_id)` API (>= 1.x). The new API
    returns FetchedTranscriptSnippet objects via __iter__.
    """
    try:
        from youtube_transcript_api import YouTubeTranscriptApi  # type: ignore
    except Exception:
        return None

    # New API (instance method `.fetch()` returning FetchedTranscript).
    try:
        if hasattr(YouTubeTranscriptApi, "fetch") and not hasattr(YouTubeTranscriptApi, "get_transcript"):
            api = YouTubeTranscriptApi()
            ft = api.fetch(video_id)
            lines: list[str] = []
            for snip in ft:
                text = getattr(snip, "text", None)
                if text:
                    lines.append(text)
            return "\n".join(lines) if lines else None
    except Exception as e:
        logger.info(f"[YT transcript] new API failed: {e}")

    # Legacy classmethod API.
    try:
        segments = YouTubeTranscriptApi.get_transcript(video_id)  # type: ignore[attr-defined]
        return "\n".join(s.get("text", "") for s in segments if s.get("text"))
    except Exception:
        return None


def _parse_iso8601_duration(s: str) -> Optional[float]:
    """PT1H2M3S → 3723.0 seconds. Returns None on parse failure."""
    if not s or not s.startswith("PT"):
        return None
    m = re.match(r"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?", s)
    if not m:
        return None
    h, mi, se = (int(g) if g else 0 for g in m.groups())
    return float(h * 3600 + mi * 60 + se)


_CHAPTER_LINE_RE = re.compile(r"^(\d{1,2}:\d{2}(?::\d{2})?)\s+(.+)$")


def _parse_description_chapters(text: str) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for line in text.splitlines():
        m = _CHAPTER_LINE_RE.match(line.strip())
        if m:
            out.append({"start_ts": m.group(1), "title": m.group(2)[:120]})
    # Heuristic: YT description chapters need at least 3 lines starting at 0:00
    if out and out[0]["start_ts"] in ("0:00", "00:00", "0:00:00"):
        return out
    return []


# ===========================================================================
# Instagram / TikTok — yt-dlp
# ===========================================================================


def _write_cookies_for_source(source: str, tmp_dir: str) -> Optional[str]:
    """If a base64-encoded Netscape cookies file is in the env for this
    source, decode it and write it to a tmp path that yt-dlp can read.

    Env vars:
      INSTAGRAM_COOKIES_B64 — for source == "instagram"
      TIKTOK_COOKIES_B64    — for source == "tiktok"

    Returns the path or None when no cookies env is set. Failures
    (bad base64, empty file) are logged and treated as "no cookies".
    """
    import base64

    env_key = {
        "instagram": "INSTAGRAM_COOKIES_B64",
        "tiktok": "TIKTOK_COOKIES_B64",
    }.get(source)
    if not env_key:
        return None
    raw = os.environ.get(env_key)
    if not raw:
        return None
    try:
        decoded = base64.b64decode(raw, validate=False)
        if not decoded.strip():
            return None
        cookies_path = os.path.join(tmp_dir, f"{source}_cookies.txt")
        with open(cookies_path, "wb") as fh:
            fh.write(decoded)
        os.chmod(cookies_path, 0o600)
        logger.info(f"[url_content_fetcher] using {env_key} for {source}")
        return cookies_path
    except Exception as e:
        logger.warning(f"[url_content_fetcher] failed to write {env_key}: {e}")
        return None




async def _fetch_via_ytdlp(url: str, *, source: str) -> SharedContent:
    """Use yt-dlp to fetch caption + a single video asset. Uploads the
    downloaded media to S3 with the `imports/social/` prefix. We never
    re-surface the raw media to the user — extraction-only.

    Cookie support: when the env var INSTAGRAM_COOKIES_B64 is set (for
    `source=="instagram"`) the base64-decoded cookies file is written to
    a tmp path and passed to yt-dlp as `cookiefile`. Same for
    TIKTOK_COOKIES_B64. This is the free workaround for Meta / Bytedance
    blocking unauthenticated server IPs. See docs/instagram-cookies-setup.md
    for the one-time export procedure.
    """
    try:
        import yt_dlp  # type: ignore
    except ImportError:
        return SharedContent(
            source=source, kind="text", original_url=url,
            error="yt-dlp not installed on server",
        )

    tmp_dir = tempfile.mkdtemp(prefix="zealova-share-")
    cookies_path = _write_cookies_for_source(source, tmp_dir)
    try:
        ydl_opts = {
            "outtmpl": os.path.join(tmp_dir, "%(id)s.%(ext)s"),
            "format": "best[filesize<500M]/best",
            "max_filesize": MAX_VIDEO_BYTES,
            "quiet": True,
            "no_warnings": True,
            "noplaylist": True,
            "writesubtitles": False,
        }
        if cookies_path:
            ydl_opts["cookiefile"] = cookies_path

        def _ytdlp_extract() -> dict[str, Any]:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(url, download=True)
                return info  # type: ignore[return-value]

        info = await asyncio.to_thread(_ytdlp_extract)
        if not isinstance(info, dict):
            raise RuntimeError("yt-dlp returned no info")

        if info.get("is_live"):
            return SharedContent(source=source, kind="text", original_url=url,
                                 error="live streams not supported", locked=True)

        title = info.get("title")
        description = info.get("description") or info.get("alt_title")
        author = info.get("uploader") or info.get("channel")
        duration = info.get("duration")

        media_assets: list[MediaAsset] = []
        # yt-dlp puts the local path in different places depending on
        # version and post type. Check the canonical spots in order.
        downloaded_path = (
            info.get("_filename")
            or info.get("filepath")
            or info.get("filename")
        )
        if not downloaded_path:
            reqs = info.get("requested_downloads") or []
            if reqs and isinstance(reqs, list) and isinstance(reqs[0], dict):
                downloaded_path = (
                    reqs[0].get("filepath")
                    or reqs[0].get("_filename")
                    or reqs[0].get("filename")
                )
        if downloaded_path and os.path.exists(downloaded_path):
            with open(downloaded_path, "rb") as fh:
                data = fh.read()
            s3 = get_s3_service()
            key = s3.upload_bytes(
                data,
                key_prefix=f"imports/social/{source}",
                filename=os.path.basename(downloaded_path),
                content_type="video/mp4",
            )
            media_assets.append(MediaAsset(
                s3_key=key,
                type="video",
                duration_s=duration,
                content_type="video/mp4",
                size_bytes=len(data),
            ))

        return SharedContent(
            source=source,
            kind="video",
            original_url=url,
            title=title,
            caption=description,
            author_handle=author,
            author_name=author,
            media=media_assets,
        )
    except Exception as e:
        msg = str(e).lower()
        # Both Meta and Bytedance now aggressively block unauthenticated
        # bot fetches. Map their telltale strings to `locked=True` so the
        # client surfaces the user-friendly "Paste the caption instead?"
        # fallback instead of a raw yt-dlp error.
        locked_signals = (
            "login required", "login-walled", "logged-in",
            "empty media response",     # Instagram
            "ip address is blocked",    # TikTok
            "private", "not available", "rate-limit", "rate limited",
            "sign in to confirm", "age-restricted",
        )
        locked = any(sig in msg for sig in locked_signals)
        # Friendlier short error for clients — the full yt-dlp output is
        # not something we want surfacing in the UI.
        # User-facing copy: nudge people toward the share-from-inside-the-
        # app path (which always works) rather than blaming Zealova.
        friendly = (
            "Instagram blocks URL imports for most posts. Open the reel in "
            "Instagram and tap Share → Zealova instead, or paste the caption "
            "below." if source == "instagram"
            else "TikTok blocks URL imports from servers. Open the video in "
            "TikTok and tap Share → Zealova instead, or paste the caption "
            "below." if source == "tiktok"
            else str(e)[:200]
        )
        return SharedContent(
            source=source, kind="text", original_url=url,
            error=friendly, locked=locked,
        )
    finally:
        try:
            shutil.rmtree(tmp_dir, ignore_errors=True)
        except Exception:
            pass


# ===========================================================================
# Reddit — unauthenticated JSON endpoint
# ===========================================================================

async def _fetch_reddit(url: str) -> SharedContent:
    # reddit.com supports `.json` suffix for any post URL. Skip if the
    # URL already ends in .json (covers the case where the caller passed
    # us the raw JSON endpoint).
    bare = url.split("?", 1)[0].rstrip("/")
    json_url = bare if bare.endswith(".json") else (bare + ".json")
    headers = {
        "User-Agent": "Zealova/1.0 (compatible; ImportsFetcher) by /u/zealova",
    }
    try:
        async with httpx.AsyncClient(timeout=15, headers=headers, follow_redirects=True) as client:
            resp = await client.get(json_url)
            resp.raise_for_status()
            arr = resp.json()
            if not isinstance(arr, list) or not arr:
                raise RuntimeError("unexpected reddit JSON shape")
            post = arr[0]["data"]["children"][0]["data"]
            title = post.get("title")
            body = post.get("selftext")
            author = post.get("author")
            subreddit = post.get("subreddit_name_prefixed") or post.get("subreddit")
            return SharedContent(
                source="reddit",
                kind="text" if body else "mixed",
                original_url=url,
                title=title,
                body=body,
                author_handle=author,
                author_name=subreddit,
            )
    except Exception as e:
        return SharedContent(source="reddit", kind="text", original_url=url, error=str(e)[:240])


# ===========================================================================
# X / Twitter — oEmbed
# ===========================================================================

async def _fetch_x(url: str) -> SharedContent:
    try:
        async with httpx.AsyncClient(timeout=10, follow_redirects=True) as client:
            resp = await client.get(
                "https://publish.twitter.com/oembed",
                params={"url": url, "dnt": "true", "omit_script": "true"},
            )
            if resp.status_code == 200:
                data = resp.json()
                html = data.get("html") or ""
                # Strip HTML tags for a clean text payload.
                text = re.sub(r"<[^>]+>", " ", html)
                text = re.sub(r"\s+", " ", text).strip()
                return SharedContent(
                    source="x",
                    kind="text",
                    original_url=url,
                    title=data.get("title"),
                    body=text or None,
                    author_handle=data.get("author_name"),
                    author_name=data.get("author_name"),
                )
        return SharedContent(source="x", kind="text", original_url=url,
                             error=f"oEmbed returned {resp.status_code}")
    except Exception as e:
        return SharedContent(source="x", kind="text", original_url=url, error=str(e)[:240])


# ===========================================================================
# Generic web — Readability-style HTML → text
# ===========================================================================

async def _fetch_generic(url: str) -> SharedContent:
    try:
        async with httpx.AsyncClient(timeout=15, follow_redirects=True, headers={
            "User-Agent": "Mozilla/5.0 (compatible; Zealova/1.0; +https://zealova.com)"
        }) as client:
            resp = await client.get(url)
            resp.raise_for_status()
            html = resp.text
        title = _extract_title(html)
        text = _html_to_text(html)
        return SharedContent(
            source="web",
            kind="text",
            original_url=url,
            title=title,
            body=text[: MAX_TRANSCRIPT_CHARS],
        )
    except Exception as e:
        return SharedContent(source="web", kind="text", original_url=url, error=str(e)[:240])


_TITLE_RE = re.compile(r"<title[^>]*>(.*?)</title>", re.IGNORECASE | re.DOTALL)
_SCRIPT_STYLE_RE = re.compile(r"<(script|style)[^>]*>.*?</\1>", re.IGNORECASE | re.DOTALL)
_TAG_RE = re.compile(r"<[^>]+>")


def _extract_title(html: str) -> Optional[str]:
    m = _TITLE_RE.search(html)
    return (m.group(1).strip()[:240] if m else None)


def _html_to_text(html: str) -> str:
    s = _SCRIPT_STYLE_RE.sub(" ", html)
    s = _TAG_RE.sub(" ", s)
    s = re.sub(r"&nbsp;", " ", s)
    s = re.sub(r"&amp;", "&", s)
    s = re.sub(r"&lt;", "<", s)
    s = re.sub(r"&gt;", ">", s)
    s = re.sub(r"&#39;", "'", s)
    s = re.sub(r"&quot;", '"', s)
    s = re.sub(r"\s+", " ", s)
    return s.strip()
