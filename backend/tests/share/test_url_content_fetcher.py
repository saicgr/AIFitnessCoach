"""Tests for backend/services/url_content_fetcher.py.

Critical assertion: YouTube URLs MUST go through the YouTube Data API +
youtube_transcript_api code path, NEVER yt-dlp. This is the App Store
compliance contract baked into the plan.
"""
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from services.url_content_fetcher import (
    SharedContent,
    _extract_youtube_id,
    _parse_description_chapters,
    _parse_iso8601_duration,
    detect_source,
    fetch,
)


# ---------------------------------------------------------------------------
# detect_source
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("url,source", [
    ("https://www.youtube.com/watch?v=abc",   "youtube"),
    ("https://youtu.be/abc",                  "youtube"),
    ("https://www.instagram.com/reel/abc/",   "instagram"),
    ("https://www.tiktok.com/@u/video/123",   "tiktok"),
    ("https://reddit.com/r/x/comments/abc",   "reddit"),
    ("https://x.com/u/status/123",            "x"),
    ("https://nytcooking.com/recipes/abc",    "web"),
])
def test_detect_source(url: str, source: str) -> None:
    assert detect_source(url) == source


# ---------------------------------------------------------------------------
# YouTube ID extraction
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("url,vid", [
    ("https://www.youtube.com/watch?v=dQw4w9WgXcQ", "dQw4w9WgXcQ"),
    ("https://youtu.be/dQw4w9WgXcQ",                "dQw4w9WgXcQ"),
    ("https://www.youtube.com/shorts/abcdef123",    "abcdef123"),
    ("https://www.youtube.com/",                    None),
])
def test_extract_youtube_id(url: str, vid: str) -> None:
    assert _extract_youtube_id(url) == vid


# ---------------------------------------------------------------------------
# ISO8601 duration parser
# ---------------------------------------------------------------------------

@pytest.mark.parametrize("iso,seconds", [
    ("PT1H2M3S", 3723.0),
    ("PT45M",    2700.0),
    ("PT30S",    30.0),
    ("",         None),
    ("garbage",  None),
])
def test_parse_iso8601_duration(iso: str, seconds: float) -> None:
    assert _parse_iso8601_duration(iso) == seconds


# ---------------------------------------------------------------------------
# Description chapter parser
# ---------------------------------------------------------------------------

def test_description_chapters_requires_first_at_zero() -> None:
    # Valid: first timestamp is 0:00
    desc = "0:00 Warm-up\n2:30 Bench\n5:00 Squat"
    chapters = _parse_description_chapters(desc)
    assert len(chapters) == 3
    assert chapters[0]["title"] == "Warm-up"


def test_description_chapters_rejects_when_not_starting_at_zero() -> None:
    desc = "2:30 Random\n5:00 More"
    chapters = _parse_description_chapters(desc)
    assert chapters == []


# ---------------------------------------------------------------------------
# Critical: NO yt-dlp on YouTube URLs
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
async def test_youtube_url_never_invokes_ytdlp() -> None:
    """If this ever fails, an App Store reviewer can argue the app
    downloads YouTube content. Keep this gate green."""
    with patch("services.url_content_fetcher._fetch_youtube") as ytfn, \
         patch("services.url_content_fetcher._fetch_via_ytdlp") as ytdlp:
        ytfn.return_value = SharedContent(
            source="youtube", kind="video",
            original_url="https://youtu.be/abc",
        )
        await fetch("https://youtu.be/abc")
        assert ytfn.await_count == 1
        assert ytdlp.await_count == 0


@pytest.mark.asyncio
async def test_instagram_url_invokes_ytdlp_path() -> None:
    with patch("services.url_content_fetcher._fetch_via_ytdlp") as ytdlp, \
         patch("services.url_content_fetcher._fetch_youtube") as ytfn:
        ytdlp.return_value = SharedContent(
            source="instagram", kind="video",
            original_url="https://www.instagram.com/reel/abc/",
        )
        await fetch("https://www.instagram.com/reel/abc/")
        assert ytdlp.await_count == 1
        assert ytfn.await_count == 0


# ---------------------------------------------------------------------------
# SharedContent.as_text composition
# ---------------------------------------------------------------------------

def test_shared_content_as_text_includes_all_fields() -> None:
    c = SharedContent(
        source="instagram", kind="video", original_url="x",
        title="My workout",
        author_handle="@coach",
        caption="3 sets bench",
        transcript="Today we are doing a chest day…",
    )
    blob = c.as_text()
    assert "Title: My workout" in blob
    assert "By: @coach" in blob
    assert "3 sets bench" in blob
    assert "chest day" in blob
