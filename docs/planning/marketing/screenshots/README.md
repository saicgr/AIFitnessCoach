# Screenshot library — Instagram content engine

Real, clean app screenshots the carousel/video renderers embed inside phone
frames. This is the still-image counterpart to the video B-roll library
(`../reels/broll-library.md`).

## Why a library (not re-capture every post)

The engine renders finished slides daily. Re-running the app to grab a fresh
screenshot every day is friction, so instead we keep a **maintained set of
canonical screens** here and the renderer pulls from them by a stable key. You
refresh a shot only when the UI changes — overwrite the file, keep the key, and
every future post picks up the new look automatically.

## Structure

- `app/<key>.png` — the screenshots (clean full-device captures, no marketing chrome).
- `manifest.json` — maps each `key` → file + feature + pillar + description.
  Carousel specs reference these via `slide.screenshot` / `slide.image` using
  either the **key** (resolved through the manifest) or a direct repo-relative path.

## How to capture a new / refreshed shot

1. Run the app on the iOS Simulator (iPhone 17 Pro, or match `manifest.json`'s `device`).
2. Navigate to the exact screen. Use a **demo/reviewer account** with realistic
   data (see `project_emulator_health_sample_data`) — never real user data.
3. Cmd-S in the Simulator (or `xcrun simctl io booted screenshot out.png`) — this
   gives a clean capture *with* the iOS status bar and *without* App Store
   marketing text.
4. Save to `app/<key>.png`. If it's a new surface, add an entry to `manifest.json`.
5. Prefer the payoff state (a *result*, a *score*, a *graded* item) over an empty
   or loading screen — the screenshot is the "here's the app" proof.

## Current pillars → best shots

| Pillar | Flagship shots |
|---|---|
| `menu-scan` (food exposé) | `menu-scan-result`, `fridge-scan` |
| `form` (you're doing it wrong) | `form-check-pushup` |
| `workout` (AI moat) | `strength-score`, `active-workout-set`, `coach-chat`, `schedule-programs`, `home-coach-nudge` |
| `nutrition` | `coach-chat`, `imports-ai` |

Seeded 2026-07-19 from `new_screenshots/` (16 clean iPhone 17 Pro captures).
