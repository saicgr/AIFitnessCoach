# Home Metrics Redesign — Direction C — Implementation Plan

Status: **awaiting approval**. Mockup: `home_metrics_mockup.html` (Direction C, 2 home phones + My Space + custom-trend).

## Goal
Invert the home so a **compact, glanceable, fully-customizable metric deck** sits up top and the **full-size AI Coach** sits below. Every tile and every My Space row is openable; My Space rows show a live mini-graph + number; logging lives in a 3-button row (Log / Trends / Start) whose **Log opens a glassmorphic quick-actions sheet**; the FAB stays a pure AI Coach button.

## Non-negotiables (locked with user)
- AI Coach FAB unchanged (coach only — no speed-dial).
- Coach card full-size (message + task carousel).
- Metrics compact: segmented Today ring + live overlay tiles, swipe deck **Summary · More · Trends** (fixed categories; customization only reflows More/Trends, never the structure; Today ring pinned to Summary).
- Every metric tile is tappable → detail; every My Space row openable → per-widget editor.
- Glassmorphic bottom sheets via existing `GlassSheet` (lib/widgets/glass_sheet.dart) — same as all others.
- No mock/fallback data — live providers only.

## Differentiation guardrails (IP safety — enforced during build)
UI patterns/functionality aren't copyrightable; specific expression, assets, copy and trademarks are. The build must stay visibly distinct from Google Fit/Health:
1. **Brand & color:** orange accent + light data-card system; per-metric tints from our `ring_catalog`. No Google color values, icons, or logos.
2. **Signature shapes:** segmented multi-arc **Today ring** (Train/Nourish/Move/Sleep), not a single steps ring; **accent-graph tiles** (sparkline/bars/gauge/macro-bar overlays), not solid color-block tiles.
3. **Copy is ours:** nav = Home / Workouts / Nutrition / You; coach CTA = "Chat with coach"; coach message is Gemini-generated via `dailyCoachInsightProvider`. Strip every placeholder string borrowed from the Google screenshot in the mockup (e.g. "Ask Coach", "8:51 PM", "Time to let your system fully catch up", "Today/Fitness/Sleep/Health"). None ship.
4. **No comparative positioning** ("like Google Fit") anywhere in-app or in store copy.
5. Pre-submission: a quick IP-lawyer glance at final screens is advised (not a build blocker).

## Step 0 — Safety (before first edit)
Per root CLAUDE.md (redesign touches ≥3 screens):
- File-level backup of `mobile/flutter/lib` (+ assets if touched) to `docs/planning/redesign-2026-05/backup/`, MANIFEST + CHECKSUMS, gitignored.
- `git tag home-metrics-c-v0-snapshot HEAD`.

## 1 — Data model & persistence
- New `MetricWidgetSpec` (model): `id` (maps to RingKind / TrendMetric / saved-custom-trend id), `size` (small | wide | large), `chartType` (number | ring | bars | line | area | macroBar), `colorId?` (override; default = catalog color), `range` (7d | 30d | 90d | 1y), `order`, `enabled`.
- Catalog: extend `screens/home/widgets/ring_catalog.dart` (or new `metric_widget_catalog.dart`) to cover all live metrics: steps, calories burned, active min, resting HR, HRV, VO₂max, weight, body fat, hydration, sleep (duration+score), readiness, strain, zone min, mood, nourish/macros, + custom trends. Reuse `TrendMetric` enum where it already exists.
- Persistence: evolve `ringVisibilityProvider` → `metricWidgetsProvider` (StateNotifier + SharedPreferences, per-user key, versioned) storing the ordered `MetricWidgetSpec` list; one-time migration from existing ring order so current users keep their layout.
- Custom trends: reuse saved trends (`custom_trends_saved_v2` prefs from `custom_trend_screen.dart`) surfaced as large widgets in the deck/My Space.

## 2 — Live data providers
- `metricValueProvider = Provider.family<MetricValue, String metricId>` returning `{ value, unit, goal?, pct?, series<TrendPoint>?, deltaLabel? }`, composed (cache-first, deterministic — no RAG) from existing providers:
  - `dailyActivityProvider` (steps, caloriesBurned, restingHr, activeMinutes, sleepMinutes…)
  - `sleepScoreProvider`, `hydrationProvider`, `nutritionProvider` (nourish + macros), weight/body-metrics provider, readiness provider, strain signal, `trendSeriesProvider` (for sparkline/range series), `aiBurnedCaloriesProvider`.
- Drives both home tiles and My Space row mini-graphs from one source of truth.

## 3 — Home metric section (replaces the todayScore + metricTrio render)
New widgets under `screens/home/widgets/home/`:
- `MetricSummaryDeck` — `PageView`: **Summary** (segmented Today ring via existing `segmented_score_ring.dart` + small overlay tiles) · **More** (paginated small/wide tiles from enabled set) · **Trends** (large chart / custom-trend widgets). Labeled segment + dots + ✎ (opens My Space → Metrics).
- `MetricTile` — light card, accent color, big number, **graph overlay** by `chartType` (sparkline / bars / gauge / mini-ring / macro-bar). `onTap` → detail.
- `MetricActionsRow` — `Log` (glass sheet) · `Trends` (analytics) · `Start` (today's workout).
- Wire into `home_sections_provider.dart`: the metric deck renders as the `todayScore` (core) section; keep `coachHero` full-size directly below; standalone `quickActions` section default-off (its actions now live in the Log sheet) but still toggleable.

## 4 — Glassmorphic quick-actions sheet (Log)
- `showQuickLogSheet(context, ref)` built on existing `GlassSheet`. 12 actions routed to existing flows: Snap meal/Scan menu/Search food/Barcode/Quick add → nutrition logging (`log_meal_sheet.dart` etc.); Log water → hydration; Weigh in/Body stats → measurements; Log mood; Progress photo; Log sleep; Note. Grid, glassmorphic, consistent with app sheets.

## 5 — Tile detail (every tile openable)
- Tap a tile → metric detail. Reuse `CustomTrendScreen(initialMetric:)` where the metric maps to a `TrendMetric`; else a light metric-detail screen (chart + history + goal). Routed via go_router.

## 6 — My Space — Metrics tab (openable, live graph + numbers)
- Add **Metrics** tab to `home_my_space_screen.dart` (tabs: Metrics · Sections · Discover).
- Rows: drag-reorder · toggle on/off · size S/W/L · **live mini-graph + number** per row (ring/sparkline/gauge/dual-line from `metricValueProvider`). Core (Today score) pinned.
- Row/gear opens **per-widget editor** (glass sheet): color swatches · chart type · date range. `+ Add custom trend` → `CustomTrendScreen`; `Add metric` library section.
- All writes → `metricWidgetsProvider`.

## 7 — FAB
- Leave `CoachFloatingButton` exactly as-is (AI Coach only).

## 8 — Verification
- `flutter analyze` (no new errors beyond the ~3200 pre-existing).
- Run on simulator: deck swipe Summary/More/Trends; tile tap → detail; Log glass sheet → each action; My Space add/remove/resize/recolor/range persists across restart; light + dark; smallest device (SE) no overflow.
- **Guardrail audit:** grep the shipped widgets/strings for borrowed Google copy/nav names; confirm segmented ring + accent-graph tiles (no solid-block clone); confirm orange/light brand and our own coach copy.

## Execution order (continuous once approved)
P1 model + `metricWidgetsProvider` + `metricValueProvider` → P2 `MetricSummaryDeck` + `MetricTile` + actions row + home wiring → P3 glass Log sheet → P4 tile detail routing → P5 My Space Metrics tab + per-widget editor → P6 analyze + simulator smoke.
