# Zealova Home Redesign — Build Plan

The home redesign, from design (12 mockups, see `index.html`) to shipped code.
Six phases, shipped **one at a time with a verification gate between each**.

---

## Architecture decisions

- **The score is computed client-side, in Dart.** Two of its three inputs are
  on-device only (Health Connect steps; live workout/food state). It must
  update instantly as you log a meal or finish the workout — no server
  round-trip. The backend is not involved in computing the score.
- **Deterministic, no LLM.** The score and the coach nudge line are pure
  functions. (Per project rule: no LLM for scoring/classification.)
- **No `build_runner`.** `.g.dart` files are committed and Flutter is pinned —
  so no new Drift tables. Score snapshots persist via `SharedPreferences`
  (same store the home layout already uses).
- **The Today Score is a home tile** (`TileType.todayScore`) inside the
  existing `home_layout` system — not a bespoke screen. The score card's
  ✎ Edit opens the existing My Space editor.

---

## The score formula

```
applicable = the contributors that have data today
  Train  applicable if a workout is scheduled today (rest day / no plan → not applicable)
  Fuel   applicable if nutrition targets exist (set at onboarding → ~always)
  Move   applicable if Health Connect is linked and providing steps

effectiveWeightᵢ = baseWeightᵢ / Σ(baseWeight of applicable)     base: Train .50, Fuel .35, Move .15
score = round( Σ( effectiveWeightᵢ × completionᵢ ) × 100 )

completion (0–1):
  Train = workout complete ? 1.0 : exercisesDone / exercisesTotal
  Fuel  = ( min(protein/target,1) + min(calories/target,1) ) / 2
  Move  = min(steps / stepGoal, 1)
```

Rest day / no plan → Train drops out, Fuel+Move renormalize to .70/.30.
No Health Connect → Move drops out, Train+Fuel renormalize to .59/.41.

---

## Cross-cutting — every phase respects these

**Flavor scoping.** This is a 3-flavor codebase (Zealova `consumer`, Reppora
`client`, Reppora `coach`). The Today Score, the score card and the new tiles
are **Zealova consumer only**. `home_layout.dart` is shared, so the new
`TileType`s go in the (shared) enum, but are only added to
`defaultVisibleTiles` / presets for the consumer flavor and the home renderer
guards the new tile widgets behind the flavor — Reppora's home is untouched.

**Adding a `TileType` without `build_runner`.** `build_runner` is forbidden and
`TileType` is a `@JsonValue` enum with a committed `home_layout.g.dart`. Each
new value (`todayScore`, `water`) needs, by hand: (1) the enum value +
`@JsonValue`; (2) an entry in `_$TileTypeEnumMap` in `home_layout.g.dart`;
(3) a `case` in **every** exhaustive `TileType` switch — `displayName`,
`description`, `iconName`, `category`, `supportedSizes`, the home tile
renderer, and any other app-wide `switch`. `flutter analyze` is what finds
every switch still missing a case.

**Routing.** The Today Score detail screen (Phase 5) registers a route in the
app router. The score card's ✎ Edit reuses the existing `/settings/homescreen`.

**Card states.** The score card handles loading (skeleton), error (retry — no
silent fallback), and the setup state (`isSetupState` ⇒ a "finish setup"
prompt, never a bare 0).

**Header.** The home header's streak pill is relabelled to the readable form
("Lv 2 · 64% to Lv 3 · 🔥3") as part of Phase 2 — a small existing-widget edit.

**Verification standard.** The repo carries ~3,200 pre-existing analyzer
infos/warnings. "Verified" per phase = `flutter analyze` shows **no new
errors**, the phase's tests pass, and the screen runs on a device.

**Score history & backend.** Score history is **local only** (`SharedPreferences`,
Phase 6) — it does not sync to the backend. The `home_layout` backend simply
stores the layout JSON, so a new tile-type string needs no backend change.

---

## Phase 1 · Scoring engine + tests

**Goal:** the score as pure, tested Dart. No UI.

**New files**
- `lib/data/models/today_score.dart` — `TodayScore`, `ScoreContributor`
  (`kind`, `label`, `color`, `baseWeight`, `applicable`, `completion`,
  `effectiveWeight`, `statusText`).
- `lib/services/today_score_service.dart` — `computeTodayScore({workout,
  nutrition, health})` → `TodayScore`. Holds the applicability +
  renormalization rule above.
- `lib/data/providers/today_score_provider.dart` — `todayScoreProvider`,
  watches the workout / nutrition / health providers and recomputes.
- `test/today_score_service_test.dart` — unit tests.

**Tests must cover:** training day · rest day · no plan · no Health Connect ·
no-plan+no-HC (Fuel only) · zero applicable (setup state) · the
renormalization math · score clamps 0–100.

**Verification:** `flutter test test/today_score_service_test.dart` green.

---

## Phase 2 · The score card + home integration

**Goal:** the score card visible on the home with live data.

**New files**
- `lib/screens/home/widgets/segmented_score_ring.dart` — `SegmentedScoreRing`
  + `SegmentedRingPainter` (`CustomPainter`). Per applicable contributor: a
  tinted-track arc + a done arc; weighted segment sweeps, gaps, round caps.
  Driven by an `AnimationController`. Handles 3 / 2 / 1 segments dynamically.
- `lib/screens/home/widgets/today_score_card.dart` — ring (left) + Train/Fuel/
  Move legend rows with chevrons (right) + coach-line footer. Reads
  `todayScoreProvider`.

**Modified files**
- `lib/data/models/home_layout.dart` (+ `home_layout_part_tile_type.dart`) —
  add `TileType.todayScore`; add it to `defaultVisibleTiles`; add a
  `coreTiles` set so it can be reordered but not hidden.
- The home tile renderer — a `case TileType.todayScore` → `TodayScoreCard`.

**Also:** the "▲ today" momentum badge — on first compute each day, store the
score as that day's baseline in `SharedPreferences`; delta = now − baseline.

**Verification:** card renders on the home with live values, animates on
change, rest-day state shows 2 segments correctly.

---

## Phase 3 · Tracking tiles — Health Connect, water & fasting

**Goal:** the body-metric tiles AND the hydration / fasting tiles — every
"what have I tracked today" surface the home should carry.

**Tile types (in `home_layout.dart` / `home_layout_part_tile_type.dart`)**
- Health Connect metrics — reuse the existing `stepsCounter` and `sleepScore`;
  add `activeEnergy` and `restingHr`. (Reuse, never duplicate a tile type.)
- `fasting` — **already exists** as a tile type; just make sure it's wired and
  available in the editor + presets, not orphaned.
- `water` — **new** `TileType.water` ("Water Intake"): cups logged vs daily
  goal, with a quick +1 tap. Water is currently only a quick-action and a
  sub-row of `todayStats`; it gets its own first-class tile.

**Widgets / wiring**
- `lib/screens/home/widgets/metric_tile.dart` — small ring/number metric tile
  (ring for goal-based metrics, number + sparkline for HR/HRV).
- `lib/screens/home/widgets/water_tile.dart` — cups + goal + quick-add, reading
  the app's existing hydration provider.
- The fasting tile reads the existing fasting provider/timer (start-a-fast and
  active-window states).
- Health Connect metrics route through `health_service_ui.dart`; each HC tile
  shows a "Connect Health" state when HC is unlinked — never fake data.

**Editor / presets**
- Add `water` + `fasting` (+ the metric tiles) to `defaultHiddenTiles` so
  they're switch-on-able in My Space.
- `fasting` + `water` belong in the **Nutrition** preset; the metric tiles
  belong in the **Tracker** preset (added in Phase 4).

**Score note:** water and fasting are **tracked tiles, not score
contributors** — the Today Score stays Train / Fuel / Move. Hydration and
fasting are shown and logged on the home, they do not feed the number.

**Verification:** on a device with Health Connect — metric tiles show real
data, "Connect" state when off; water tile logs a cup and persists; fasting
tile reflects an active/idle fast.

---

## Phase 4 · My Space — Customize + Discover

**Goal:** the editor matches the mockup — two tabs, floating bottom bar.

**Modified files**
- `lib/screens/home/home_my_space_screen.dart` — add a **Discover** tab
  alongside Customize; move the tab control to a **floating bottom pill**;
  render the `todayScore` row with a 🔒 (core, reorder-only).
- `home_layout.dart` — `layoutPresets`: ensure `todayScore` is in every
  preset; add a **Tracker** preset (bundles the metric tiles); each preset
  carries the data for a real mini-preview thumbnail.
- `lib/screens/home/widgets/preset_thumbnail.dart` — the mini-render of a
  layout (score ring, workout block, macro bars, habit grid, metric rings).

**Verification:** Customize reorders/toggles and persists; core tile won't
hide; Discover previews render real tiles; Apply swaps the layout.

---

## Phase 5 · Coach line + Today Score detail

**Goal:** the coach nudge, and the screen behind a tapped legend row.

**New files**
- `lib/services/score_coach_line.dart` — deterministic nudge generator. Finds
  the highest-leverage incomplete contributor, computes the resulting score,
  picks from a **variant pool** (≥4 phrasings, no single template).
- `lib/screens/home/today_score_detail_screen.dart` — opened from the card or
  a legend-row chevron: the score broken down, each contributor with its
  formula made plain ("Train is worth 50 points — leg day not started").

**Verification:** coach line varies and stays accurate across states; detail
screen reads correctly on rest day / no-HC.

---

## Phase 6 · Score history + trend

**Goal:** the score remembered over time.

**New files / modified**
- `lib/services/score_history_store.dart` — append one daily score snapshot to
  `SharedPreferences` (a rolling ~90-day JSON list — no Drift, no codegen).
- A trend view in the Today Score detail screen — last 30 days, drawn with a
  lightweight `CustomPainter` sparkline.
- Streak/level wiring — feed the existing gamification from score history.

**Verification:** snapshots accumulate daily; the trend renders; the streak
reads from real history.

---

## Sequencing

Phase 1 is the foundation and is fully testable on its own — start there.
Each later phase depends only on the ones before it. Ship and verify one
phase, gate, then start the next. Long-running or device-only verification
steps are run by you; the code and the exact commands come with each phase.
