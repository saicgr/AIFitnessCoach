"""End-to-end tests against COMMITTED real-file fixtures.

Every share source from Zealova's marketing copy
("Import workouts, recipes, and meals from anywhere — Photos, ChatGPT,
YouTube, Instagram, your voice memos") is exercised here with a real
file or real URL, not a mock.

Fixture files live in `backend/tests/share/fixtures/` and are committed:
  - 5 JPG images (food plate, restaurant menu, gym equipment, exercise
    form, progress photo)
  - 3 voice memos generated via macOS `say` then encoded to AAC/.m4a
  - 2 PDFs generated via reportlab (recipe + workout program)
  - 4 text payloads simulating ChatGPT / Claude / Perplexity outputs

Costs ~$0.02 per full run (Gemini Vision + Flash-Lite calls). Gated
behind RUN_REAL_FIXTURES=1 so CI doesn't burn budget by accident.

Run:
  RUN_REAL_FIXTURES=1 backend/.venv/bin/pytest \\
    backend/tests/share/test_real_fixtures.py -v -s
"""
from __future__ import annotations

import os
import time
from pathlib import Path

import pytest

LIVE = os.environ.get("RUN_REAL_FIXTURES") == "1"
pytestmark = pytest.mark.skipif(not LIVE, reason="Set RUN_REAL_FIXTURES=1 to run")

FIXTURES = Path(__file__).parent / "fixtures"


# ===========================================================================
# Single combined test — pytest-asyncio closes the loop between
# `@pytest.mark.asyncio` tests, which tears down the shared Gemini
# aiohttp session. Keeping everything in one async function avoids that.
# ===========================================================================

@pytest.mark.asyncio
async def test_every_share_pipeline_with_real_fixtures() -> None:
    print("\n\n========== Imports feature — end-to-end fixture test ==========")
    await _photos_phase()
    await _voice_memos_phase()
    await _pdfs_phase()
    await _text_phase()
    await _urls_phase()
    print("\n========== All pipelines exercised against real data ==========\n")


# ---------------------------------------------------------------------------
# 1. Photos — VisionService.classify_media_content on committed JPGs
# ---------------------------------------------------------------------------

async def _photos_phase() -> None:
    print("\n--- 1. Photos (image classifier) ---")
    from services.vision_service import get_vision_service

    cases: list[tuple[str, str, set[str]]] = [
        ("food_plate.jpg",      "food_plate",     {"food_plate", "food_buffet"}),
        ("restaurant_menu.jpg", "restaurant menu", {"food_menu", "document"}),
        ("gym_equipment.jpg",   "gym equipment",   {"gym_equipment", "exercise_form"}),
        ("exercise_form.jpg",   "exercise form",   {"exercise_form", "gym_equipment", "progress_photo"}),
        ("progress_photo.jpg",  "progress",        {"progress_photo", "exercise_form"}),
    ]
    svc = get_vision_service()
    matches = 0
    for filename, label, acceptable in cases:
        path = FIXTURES / filename
        assert path.exists(), f"Missing fixture: {path}"
        data = path.read_bytes()
        t0 = time.time()
        ct = await svc.classify_media_content(image_data=data, mime_type="image/jpeg")
        elapsed = round(time.time() - t0, 2)
        ok = ct in acceptable
        matches += int(ok)
        print(f"  {'✅' if ok else '⚠️'} {label:20} → {ct:20} ({elapsed}s, {len(data)} B)")
    print(f"  Matched: {matches}/{len(cases)}")
    assert matches >= 4, f"Only {matches}/{len(cases)} photo classifications matched"


# ---------------------------------------------------------------------------
# 2. Voice memos — audio_transcriber on synthesized .m4a files
# ---------------------------------------------------------------------------

async def _voice_memos_phase() -> None:
    print("\n--- 2. Voice memos (audio transcriber + intent classifier) ---")
    from services.audio_transcriber import transcribe_and_hint
    from services.intent_classifier import classify_intent
    from services.text_intent_normalizer import normalize

    cases: list[tuple[str, str, set[str]]] = [
        # filename, expected hint substring(s), expected intent set
        ("voice_workout_log.m4a", "workout", {"workout_extract", "food_log_extract"}),
        ("voice_food_log.m4a",    "food",    {"food_log_extract", "discuss"}),
        ("voice_trainer_tip.m4a", "tip",     {"tip_save", "discuss", "nutrition_question"}),
    ]
    matches = 0
    for filename, expected_hint_kw, acceptable_intents in cases:
        path = FIXTURES / filename
        assert path.exists(), f"Missing fixture: {path}"
        data = path.read_bytes()
        t0 = time.time()
        u = await transcribe_and_hint(data, mime_type="audio/mp4")
        elapsed1 = round(time.time() - t0, 2)
        if not u.transcript:
            print(f"  ❌ {filename:30} → no transcript ({elapsed1}s)")
            continue

        # Run the transcript through the intent classifier (full pipeline).
        fp = normalize(u.transcript)
        t1 = time.time()
        r = await classify_intent(text=fp.text, source_origin="voicememos")
        elapsed2 = round(time.time() - t1, 2)
        ok = r["intent"] in acceptable_intents
        matches += int(ok)
        print(f"  {'✅' if ok else '⚠️'} {filename:30}")
        print(f"        transcript[:90]: {u.transcript[:90]!r}")
        print(f"        audio_hint={u.content_hint!r}  intent={r['intent']!r}"
              f"  conf={r['confidence']!r}  ({elapsed1+elapsed2}s)")
    print(f"  Matched: {matches}/{len(cases)}")
    assert matches >= 2, f"Only {matches}/{len(cases)} voice-memo pipelines matched"


# ---------------------------------------------------------------------------
# 3. PDFs — pdf_extractor on generated PDFs
# ---------------------------------------------------------------------------

async def _pdfs_phase() -> None:
    print("\n--- 3. PDFs (pdf extractor + intent classifier) ---")
    from services.pdf_extractor import understand_pdf
    from services.intent_classifier import classify_intent
    from services.text_intent_normalizer import normalize

    cases: list[tuple[str, set[str]]] = [
        ("recipe_cookbook.pdf",  {"recipe_extract"}),
        ("workout_program.pdf",  {"workout_extract"}),
    ]
    matches = 0
    for filename, acceptable in cases:
        path = FIXTURES / filename
        assert path.exists(), f"Missing fixture: {path}"
        data = path.read_bytes()
        t0 = time.time()
        u = await understand_pdf(data)
        elapsed1 = round(time.time() - t0, 2)
        if not u.text:
            print(f"  ❌ {filename:25} → no text extracted (err={u.error!r})")
            continue

        fp = normalize(u.text)
        t1 = time.time()
        r = await classify_intent(text=fp.text, source_origin="files")
        elapsed2 = round(time.time() - t1, 2)
        ok = r["intent"] in acceptable
        matches += int(ok)
        print(f"  {'✅' if ok else '⚠️'} {filename:25}  text_chars={len(u.text)}  "
              f"intent={r['intent']:20}  conf={r['confidence']:6}  ({elapsed1+elapsed2}s)")
    print(f"  Matched: {matches}/{len(cases)}")
    assert matches >= 1, f"Only {matches}/{len(cases)} PDF pipelines matched"


# ---------------------------------------------------------------------------
# 4. Text — committed text fixtures through the intent classifier
# ---------------------------------------------------------------------------

async def _text_phase() -> None:
    print("\n--- 4. Text fixtures (ChatGPT / Claude / Perplexity) ---")
    from services.intent_classifier import classify_intent
    from services.text_intent_normalizer import normalize

    cases: list[tuple[str, str, set[str]]] = [
        ("chatgpt_workout.txt",  "chatgpt", {"workout_extract"}),
        ("chatgpt_recipe.txt",   "chatgpt", {"recipe_extract"}),
        ("claude_meal_plan.txt", "claude",  {"meal_plan_extract", "recipe_extract"}),
        ("perplexity_tip.txt",   "perplexity", {"tip_save", "discuss", "nutrition_question"}),
    ]
    matches = 0
    for filename, origin, acceptable in cases:
        text = (FIXTURES / filename).read_text(encoding="utf-8")
        fp = normalize(text)
        t0 = time.time()
        r = await classify_intent(text=fp.text, source_origin=origin)
        elapsed = round(time.time() - t0, 2)
        ok = r["intent"] in acceptable
        matches += int(ok)
        print(f"  {'✅' if ok else '⚠️'} {filename:25}  intent={r['intent']:20}"
              f"  conf={r['confidence']:6}  ({elapsed}s)")
    print(f"  Matched: {matches}/{len(cases)}")
    assert matches >= 3, f"Only {matches}/{len(cases)} text pipelines matched"


# ---------------------------------------------------------------------------
# 5. URLs — live network test against real public Instagram / Reddit / X /
#           generic-web posts. Hits the actual fetchers (yt-dlp, oEmbed,
#           Reddit JSON, HTML reader).
# ---------------------------------------------------------------------------

async def _urls_phase() -> None:
    print("\n--- 5. URLs (live network — Reddit / X / generic-web; "
          "YouTube/IG/TikTok behaviour-only without API key/login) ---")
    from services.url_content_fetcher import fetch

    targets: list[tuple[str, str, str]] = [
        # (label, url, expected source)
        ("reddit_fitness",
         "https://www.reddit.com/r/Fitness/comments/1tn1bsc/moronic_monday_your_weekly_stupid_questions_thread/",
         "reddit"),
        # X / Twitter — public oEmbed has been effectively dead since
        # late 2024 (404/405 on all paths). We test that the fetcher
        # still classifies the URL as `source=x` and gracefully reports
        # the error. Real tweet content requires paid X API tier.
        ("x_tweet",
         "https://x.com/X/status/1815263757435576738",
         "x"),
        # Generic recipe web — NYT Cooking responds 200 to default UAs
        # (unlike SimplyRecipes / AllRecipes which Cloudflare-block).
        ("generic_recipe_web",
         "https://cooking.nytimes.com/recipes/1019047-creamy-roasted-tomato-soup",
         "web"),
        # YouTube: with no YT_DATA_API_KEY set locally we expect
        # source=youtube and a graceful empty result rather than yt-dlp
        # being accidentally invoked. Set the key on Render for real
        # production results.
        ("youtube_short",
         "https://www.youtube.com/shorts/DJV0_QqzNNo",
         "youtube"),
    ]
    source_ok = 0
    for label, url, expected_source in targets:
        t0 = time.time()
        try:
            c = await fetch(url)
        except Exception as e:
            print(f"  ❌ {label:25} fetch raised: {e!s:.80}")
            continue
        elapsed = round(time.time() - t0, 2)
        body_chars = len((c.transcript or "") + (c.body or "") + (c.caption or ""))
        ok = c.source == expected_source
        source_ok += int(ok)
        title = (c.title or "—")[:50]
        err = (c.error or "")[:60]
        print(f"  {'✅' if ok else '⚠️'} {label:25} src={c.source:10}  "
              f"chars={body_chars:5}  title={title!r}  ({elapsed}s)  err={err!r}")
    print(f"  Source match: {source_ok}/{len(targets)}")
    assert source_ok >= 2, f"Only {source_ok}/{len(targets)} URL sources matched"
