#!/usr/bin/env python3
"""show_imports_pipeline_outputs.py — call every share pipeline against
every committed fixture file and print the FULL extracted content, with
no truncation, so we can eyeball exactly what each pipeline returns to
the mobile client.

Hits the service layer directly (no FastAPI server) for clarity — the
endpoint tests already prove the HTTP plumbing works.

Run from repo root:
  backend/.venv/bin/python backend/scripts/show_imports_pipeline_outputs.py
"""
from __future__ import annotations

import asyncio
import json
import os
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "backend"))
os.chdir(REPO / "backend")

from dotenv import load_dotenv
load_dotenv(".env")

FX = REPO / "backend" / "tests" / "share" / "fixtures"


def box(s: str) -> None:
    print(f"\n{'=' * 90}\n  {s}\n{'=' * 90}")


def hr() -> None:
    print("-" * 90)


async def show_images() -> None:
    box("1. POST /share/classify  —  REAL IMAGE FIXTURES (Gemini Vision)")
    from services.vision_service import get_vision_service
    svc = get_vision_service()
    for fn in ["food_plate.jpg", "restaurant_menu.jpg", "gym_equipment.jpg",
               "exercise_form.jpg", "progress_photo.jpg"]:
        path = FX / fn
        data = path.read_bytes()
        t0 = time.time()
        ct = await svc.classify_media_content(image_data=data, mime_type="image/jpeg")
        elapsed = round(time.time() - t0, 2)
        print(f"\n📷 {fn}  ({len(data):,} bytes, {elapsed}s)")
        print(f"   content_type: {ct}")


async def show_voice_memos() -> None:
    box("2. POST /share/import-audio  —  REAL VOICE MEMOS (Gemini audio + intent)")
    from services.audio_transcriber import transcribe_and_hint
    from services.intent_classifier import classify_intent
    from services.text_intent_normalizer import normalize
    for fn in ["voice_workout_log.m4a", "voice_food_log.m4a", "voice_trainer_tip.m4a"]:
        path = FX / fn
        data = path.read_bytes()
        t0 = time.time()
        u = await transcribe_and_hint(data, mime_type="audio/mp4")
        r = await classify_intent(text=normalize(u.transcript).text, source_origin="voicememos")
        elapsed = round(time.time() - t0, 2)
        print(f"\n🎙️ {fn}  ({len(data):,} bytes, {elapsed}s)")
        print(f"   audio_hint: {u.content_hint}")
        print(f"   intent:     {r['intent']}  (confidence={r['confidence']})")
        print(f"   why:        {r.get('why', '')}")
        print(f"   FULL transcript:")
        for line in u.transcript.splitlines():
            print(f"     │ {line}")


async def show_pdfs() -> None:
    box("3. POST /share/import-pdf  —  REAL PDF FIXTURES (Gemini PDF + intent + workout extract)")
    from services.pdf_extractor import understand_pdf
    from services.intent_classifier import classify_intent
    from services.text_intent_normalizer import normalize
    from services.workout_extractor import extract_workout
    from services.url_content_fetcher import SharedContent

    for fn, do_workout in [
        ("recipe_cookbook.pdf", False),
        ("workout_program.pdf", True),
    ]:
        path = FX / fn
        data = path.read_bytes()
        t0 = time.time()
        u = await understand_pdf(data)
        r = await classify_intent(text=normalize(u.text).text, source_origin="files")
        elapsed = round(time.time() - t0, 2)
        print(f"\n📄 {fn}  ({len(data):,} bytes, {elapsed}s, {len(u.text):,} chars extracted)")
        print(f"   intent: {r['intent']}  (confidence={r['confidence']})")
        print(f"   why:    {r.get('why', '')}")
        print(f"   FULL extracted text:")
        for line in u.text.splitlines():
            print(f"     │ {line}")

        if do_workout and r["intent"] == "workout_extract":
            print(f"\n   → running workout extractor over the PDF text…")
            sc = SharedContent(source="files", kind="text",
                               original_url="(pdf fixture)", body=u.text)
            wk = await extract_workout(sc)
            print(f"   parsed workout title: {wk.title!r}")
            print(f"   duration_min:         {wk.estimated_duration_min}")
            print(f"   difficulty:           {wk.difficulty}")
            print(f"   equipment_needed:     {wk.equipment_needed}")
            print(f"   {len(wk.exercises)} exercises extracted:")
            for ex in wk.exercises:
                bits = []
                if ex.sets is not None:    bits.append(f"sets={ex.sets}")
                if ex.reps is not None:    bits.append(f"reps={ex.reps}")
                if ex.rest_s is not None:  bits.append(f"rest={ex.rest_s}s")
                if ex.weight_hint:         bits.append(f"weight={ex.weight_hint}")
                if ex.equipment:           bits.append(f"equip={ex.equipment}")
                print(f"     • {ex.name:32}  {'  '.join(bits)}")
                if ex.notes:
                    print(f"         notes: {ex.notes}")


async def show_text_fixtures() -> None:
    box("4. POST /share/import-text  —  REAL CHATGPT / CLAUDE / PERPLEXITY FIXTURES")
    from services.intent_classifier import classify_intent
    from services.text_intent_normalizer import normalize
    for fn, hint in [
        ("chatgpt_workout.txt",  "chatgpt"),
        ("chatgpt_recipe.txt",   "chatgpt"),
        ("claude_meal_plan.txt", "claude"),
        ("perplexity_tip.txt",   "perplexity"),
    ]:
        path = FX / fn
        text = path.read_text(encoding="utf-8")
        t0 = time.time()
        r = await classify_intent(text=normalize(text).text, source_origin=hint)
        elapsed = round(time.time() - t0, 2)
        print(f"\n📝 {fn}  ({len(text):,} chars, {elapsed}s, source_hint={hint!r})")
        print(f"   intent: {r['intent']}  (confidence={r['confidence']})")
        print(f"   why:    {r.get('why', '')}")
        print(f"   FULL input text:")
        for line in text.splitlines():
            print(f"     │ {line}")


async def show_urls() -> None:
    box("5. POST /share/fetch-url  —  REAL PUBLIC URLs (live network)")
    from services.url_content_fetcher import fetch
    from services.intent_classifier import classify_intent
    from services.text_intent_normalizer import normalize
    from services.workout_extractor import extract_workout

    targets: list[tuple[str, str, bool]] = [
        ("NYT Cooking recipe blog",
         "https://cooking.nytimes.com/recipes/1019047-creamy-roasted-tomato-soup", False),
        ("Wikipedia recipe page",
         "https://en.wikipedia.org/wiki/Chicken_tikka_masala", False),
        ("Reddit r/Fitness post",
         "https://www.reddit.com/r/Fitness/comments/1tn1bsc/moronic_monday_your_weekly_stupid_questions_thread/", False),
        ("YouTube workout video (AthleanX)",
         "https://www.youtube.com/watch?v=vc1E5CfRfos", True),
    ]
    for label, url, do_workout in targets:
        print(f"\n🔗 {label}")
        print(f"   {url}")
        t0 = time.time()
        c = await fetch(url)
        if c.error:
            print(f"   ❌ fetch error: {c.error}")
            continue
        text = c.as_text()
        r = await classify_intent(text=normalize(text).text, source_origin=c.source)
        elapsed = round(time.time() - t0, 2)
        print(f"   source:        {c.source}")
        print(f"   title:         {c.title!r}")
        print(f"   author:        {c.author_handle!r}")
        print(f"   intent:        {r['intent']}  ({r['confidence']})")
        print(f"   fetched chars: {len(text):,}")
        print(f"   elapsed:       {elapsed}s")
        # First 1000 chars of the body/transcript
        if c.body:
            print(f"\n   First 800 chars of BODY:")
            for line in c.body[:800].splitlines():
                print(f"     │ {line}")
        if c.transcript:
            print(f"\n   First 800 chars of TRANSCRIPT:")
            for line in c.transcript[:800].splitlines():
                print(f"     │ {line}")

        if do_workout and r["intent"] == "workout_extract":
            print(f"\n   → running workout extractor…")
            wk = await extract_workout(c)
            print(f"   parsed workout title: {wk.title!r}")
            print(f"   duration_min:         {wk.estimated_duration_min}")
            print(f"   difficulty:           {wk.difficulty}")
            print(f"   equipment_needed:     {wk.equipment_needed}")
            print(f"   {len(wk.exercises)} exercises extracted:")
            for ex in wk.exercises:
                bits = []
                if ex.sets is not None:    bits.append(f"sets={ex.sets}")
                if ex.reps is not None:    bits.append(f"reps={ex.reps}")
                if ex.rest_s is not None:  bits.append(f"rest={ex.rest_s}s")
                print(f"     • {ex.name:36}  {'  '.join(bits)}")


async def main() -> None:
    print("\n🟢 Imports feature — full pipeline output dump")
    print(f"   Repo: {REPO}")
    print(f"   Fixtures: {FX}")
    t0 = time.time()
    await show_images()
    await show_voice_memos()
    await show_pdfs()
    await show_text_fixtures()
    await show_urls()
    print(f"\n✅ Done — total wall time {round(time.time() - t0, 1)}s\n")


if __name__ == "__main__":
    asyncio.run(main())
