# Social Video Recipe Import — Implementation Plan

**Goal:** Import recipes from Instagram / TikTok / YouTube (Shorts) / Pinterest videos into the
existing recipe importer, reusing the infra we already maintain. The result must surface in the
Recipes list like any other recipe — visible, badged, and filterable — never hidden.

**Decision (resolved):** Do **NOT** adopt `social-to-mealie` (TypeScript/Next.js, coupled to the
Mealie API, OpenAI+Whisper). We take only its *technique* (download → transcribe → LLM-parse) and
build it natively on our Python/FastAPI + Gemini stack, reusing existing components.

**Extraction depth (user-chosen):** transcript **+** caption **+** key-frame OCR (most complete).
Audio transcription via **Gemini native audio** (no `faster-whisper` / no new heavy dependency).

---

## What we reuse unchanged

| Component | File | Role |
|---|---|---|
| `detect_source(url)` | `backend/services/url_content_fetcher.py:96` | platform detection |
| `fetch(url)` → `SharedContent` | `backend/services/url_content_fetcher.py:117` | download video → S3, caption, YT transcript |
| `_sample_video_frames(content)` | `backend/services/workout_extractor.py:138` | 12 Gemini-ready frames |
| `_parse_text_to_recipe(blob, ...)` | `backend/services/recipe_import_service.py:290` | text blob → `RecipeCreate` + nutrition + SSE |
| Recipes list + source badge | `mobile/flutter/lib/screens/nutrition/widgets/recipes_tab.dart:1229` | imported recipes already shown |
| Import → review/create flow | `mobile/flutter/lib/screens/nutrition/recipes/recipe_import_screen.dart` | SSE → prefill RecipeCreateScreen |

yt-dlp, youtube-transcript-api, imageio-ffmpeg, google-genai are **already** in `requirements.txt`.
No new dependency. No DB migration. No new table.

---

## Build steps

### Backend

1. **`RecipeSourceType` enum** — `backend/models/recipe.py`
   - Add `IMPORTED_VIDEO = "imported_video"` (single value; grouped under existing "Imported" pill).
   - Add `ImportSocialRecipeRequest` model (`url: str`, optional `servings_override`).

2. **Frame OCR** — `backend/services/vision_service.py`
   - Add `extract_text_from_frames(frames: list[types.Part]) -> str`: Gemini Vision call that returns
     ALL readable on-screen text (titles, ingredient overlays, step text), temp ~0.1.

3. **Audio transcript** — `backend/services/recipe_import_service.py` (or a small helper)
   - For IG/TikTok (which return no spoken transcript): extract audio from the S3 video via the bundled
     ffmpeg, send the audio Part to Gemini for transcription. Skip when `SharedContent.transcript`
     already populated (YouTube). Best-effort: failure → continue with caption + OCR only (no hard fail).

4. **`import_social()`** — `backend/services/recipe_import_service.py`
   - Pipeline (streams SSE the same shape as existing imports):
     1. `fetching` → `fetch(url)`; if `content.error` or `content.locked` → yield `error` with a
        user-friendly message (private/age-gated post).
     2. Assemble text: `title + caption + body + transcript`.
     3. `analyzing` → `_sample_video_frames()` → `extract_text_from_frames()` (OCR) + audio transcript.
     4. Concat all sources into one blob.
     5. `parsing` → delegate to `_parse_text_to_recipe(blob, source_type=IMPORTED_VIDEO, source_url=url)`
        which yields the remaining `parsing → analyzing → done` events untouched.
   - Guard: if the blob is empty/too short → yield `error` ("Couldn't read a recipe from this video"),
     per the no-silent-fallback rule.

5. **Endpoint** — `backend/api/v1/nutrition/recipe_imports.py`
   - `POST /recipes/import-social` (body `ImportSocialRecipeRequest`, `user_id` query, `get_current_user`
     dep) wrapping `importer.import_social(url, user_id)` in the existing `_sse` StreamingResponse.

### Flutter

6. **4th import tab** — `mobile/flutter/lib/screens/nutrition/recipes/recipe_import_screen.dart`
   - Add a "Social / Video" tab: URL field + paste-from-clipboard + platform hint (IG/TikTok/YT/Pinterest).
   - Reuse the existing `_runImport()` SSE flow pointed at `/recipes/import-social`; on `done` →
     same `_recipeFromMap()` → navigate to `RecipeCreateScreen(prefill: ...)`. Identical downstream path.
   - Add the endpoint constant to `api_constants.dart` and the call to `recipe_repository.dart`.

7. **Surfacing (the "not hidden" requirement)** — `recipes_tab.dart`
   - Add `'imported_video'` to the imported-source grouping list (~line 55–61) so the new recipes:
     - appear in **My Recipes** by default (no source filter excludes them — confirmed), and
     - are caught by the **📥 Imported** filter pill, and
     - show the source badge (`_shouldShowSourceBadge` already returns true for non-manual types).

### Verify

8. **Local backend test** — a small script that runs `import_social()` against one public YouTube
   Short + one public TikTok recipe URL, asserting a non-empty `RecipeCreate` with ≥1 ingredient and
   a sane confidence. (Uses threaded uvicorn + httpx for any HTTP-level check — `TestClient` is broken
   repo-wide per project notes.)
9. **`flutter analyze`** scoped to the touched files; fix new issues (don't chase the ~3200 pre-existing).

---

## Edge cases handled explicitly
- **Private / age-gated post** → `locked` → friendly error, no crash.
- **IG/TikTok cookie auth** → optional `INSTAGRAM_COOKIES_B64` / `TIKTOK_COOKIES_B64` already supported
  in `_fetch_via_ytdlp`; unauthenticated still attempted (may rate-limit). Document env vars in plan.
- **Non-recipe video** → `_parse_text_to_recipe` already returns `is_recipe:false` + low confidence → rejected.
- **No spoken audio + no on-screen text + thin caption** → empty-blob guard → explicit error.
- **YouTube vs IG/TikTok** → YouTube uses official transcript API (no yt-dlp); IG/TikTok use yt-dlp +
  Gemini audio. App Store policy preserved.

## Out of scope (this pass)
- Per-platform source types (we use one `imported_video`).
- Whisper / local speech-to-text (Gemini audio covers it).
- Batch import from Mealie or other recipe managers.

## Risk / the one judgment call
Gemini audio transcription quality on short, music-over-voice clips. Mitigation: we feed audio +
on-screen OCR + caption together, so on-screen-text recipes (the TikTok norm) don't depend on audio at all.
