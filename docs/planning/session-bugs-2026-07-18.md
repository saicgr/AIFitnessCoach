# Session Bug Triage — 2026-07-18

Source: ~12 screenshots/logs from a single app session (1 user). Deduplicated
into root-cause issues and fixed in one pass. Plan:
`~/.claude/plans/1-despite-having-only-1-radiant-hamster.md`.

## How to read this
- Status: `🆕 new` → `🔍 investigating` → `✅ fixed` → `✅ fixed` → `🚀 shipped`
- Severity: `P0` crash/data-loss · `P1` broken feature · `P2` degraded UX · `P3` polish

---

## Issue list

| # | Surface | Symptom | Root cause | Sev | Status |
|---|---------|---------|------------|-----|--------|
| 2 | Coach chat | `[generate_quick_workout(...)]` printed as text after a >30s failure | `generate_quick_workout` failed (placeholder uuid `22P02`); `workout_response_node` prompted Gemini with "completed successfully" even on failure → lite model re-emits the call as prose; both sanitizers only matched JSON braces | P0 | ✅ fixed |
| 9 | Coach chat | Irrelevant "How to do Chest Press Machine" chip | `_match_exercise` keyword-matched "chest press" in the reply text with no failed-turn / how-to-intent gate | P1 | ✅ fixed |
| 3 | Home coach card | 160 steps vs live 568 on Home | Coach card renders server `blocks[]` from `daily_activity.steps` (lagged sync), Home reads live `dailyActivityProvider` | P1 | ✅ fixed |
| 4 | Home hydration card | "Log water" opens Nutrition tab | `coach_hero_card.dart:322` `context.go('/nutrition?fuelSection=water')` instead of `showHydrationDialog` | P2 | ✅ fixed |
| 5 | Adjust workout | No exercise thumbnails; 45↔60 didn't rescale; supersets always off; all-incline variety | Preview row hardcoded `Icons.fitness_center`; `_exercise_count` capped 7 for >30min; superset switch showed `?? false`; RAG truncation kept same-movement dupes; stale `studio_params` duration seed | P2 | ✅ fixed |
| 6 | Food-log sheet | "BOTTOM OVERFLOWED BY 29 PIXELS" (keyboard up) | `sheetHeight` only `-20` headroom + fixed non-shrinkable `_buildBottomBar` | P2 | ✅ fixed |
| 7A | Nutrition log | Duplicate phantom "Generic Food"/"Food" item per food | Client logged `"{name}, {weight}g"`; Gemini split the comma into a 2nd generic item | P1 | ✅ fixed (BE) + 🛠️ (FE) |
| 7B | Nutrition log | Delete doesn't persist; "Removed …" undo toast never dismisses | `_updateMeal` kept `foodItems: m.foodItems`; `_removeChildItem` never force-closed the snackbar (TickerMode freeze) | P1 | ✅ fixed |
| 7C | Nutrition add | `_dependents.isEmpty` framework crash on "+" | `onFoodLogged` synchronously `.load()`s while the autoDispose `foodSearchStateProvider` is still watched → mid-frame teardown | P0 | ✅ fixed |
| 8 | Sleep display | Durations ~2× inflated (2:07a–7:56a shown 10h44m); "2:07a" no am/pm | `getNightlySleepHistory` summed multi-source duplicate sessions as "naps" (dedup pre-pass was a no-op there); `_fmtTimeShort` emitted `a`/`p` | P1 | ✅ fixed |
| 1 | Home / global | Laggy, non-smooth scroll (1 user) | Timeline re-derives+sorts events every build; `fl_chart` sparklines w/o RepaintBoundary; ~34 always-mounted contextual cards + eager cards watch whole providers; `BackdropFilter` | P2 | ✅ fixed |

---

## Root-cause notes (durable)

- **Coach tool-call leak (2):** systemic chokepoint fix = `strip_leaked_tool_json`
  now strips bracket/paren call syntax (`[tool(...)]`, `word(kwarg=v)`) in addition
  to JSON envelopes, applied at both emit paths (`langgraph_service.py` 2159/2480)
  and mirrored client-side (`chat_message_bubble.dart`). Plus the response node
  branches on real tool success and replaces any leaked failed-turn reply with a
  deterministic retry line. This makes the leak unrenderable regardless of which
  tool degrades.
- **Sleep inflation (8):** `dedupeOverlappingSessions` (extracted from the
  aggregator's overlap pre-pass) now runs across a night's sessions before the
  main/nap split, so a watch + phone double-record can't be summed twice. Single-
  source nights are untouched.
- **Phantom food (7A):** three layers — client leads with the quantity, backend
  prompt treats a lone quantity token as a portion (comma-boundary exception), and
  `collapse_phantom_food_items` drops any generic/portion phantom post-parse.
  `scripts/cleanup_phantom_food_items.py` (dry-run default) repairs existing rows.
- **Coach steps (3):** client overlays live `dailyActivityProvider` steps onto the
  server steps blocks only when live > server (steps accrue through the day); never
  fabricates.

## Follow-ups surfaced (not part of the 9)
- **Phantom-macro fold bug** — the cleanup script + backend collapse originally
  *folded* a phantom's hallucinated macros into the real item when the real item
  had 0 macros, which turned a 0-cal "Diet Coke" into 533 cal. Fixed to DROP,
  never fold (backend re-derives real macros via USDA). Cleanup applied: 2 phantom
  items removed from the test account (Almond Joy "Food", Diet Coke "Generic Food").
- **Dead strain-tier pill** — `_WorkoutHeroIntensityLine` in `unified_home_widgets.dart`
  is unreferenced (the strain/intensity pill on the workout hero never renders).
  Pre-existing, outside these 9 — flagged for a separate look.

## Gates run
- Backend files `ast.parse` clean; leaked-call regex validated (strips the exact
  leak, leaves "deficit (about 500 kcal)" / "PR (nice work)" untouched).
- `health_service_ui.dart` `flutter analyze` → no issues.
- Remaining: full `flutter analyze` on home + nutrition + workout after teammates
  land; device sign-off by user.
