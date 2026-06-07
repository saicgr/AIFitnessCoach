# Zealova — Calorii Competitor Audit (screenshot teardown + improvement roadmap)

**Source:** 72 screenshots in `next_update/caloriii/` of **Calorii** (the in-app name renders inconsistently as both "Calorii" and "Caloriii"; CALORII LLC's **"all-in-one fitness"** app). Calorii is not a pure calorie counter — it competes with **all of Zealova's categories at once**: nutrition tracking + AI workout programming + AI body/physique analysis. Food database is **FatSecret Platform API**. Pricing: **$9.99/mo or $49.99/yr** ("Save 58%", anchored against a struck-through $119.88), **7-day free trial**, discount-code field, with hard free-tier metering ("Usage remaining: 5" on every AI surface; 2 free body scans).

**Parsed:** 2026-06-06 by 4 parallel vision agents (contiguous image ranges) + 4 codebase-verification agents (Flutter `mobile/flutter/lib/` + `backend/`), then synthesised and de-duplicated here.

**Coverage:** 72 images → all accounted for once in the appendix (§9). ~10 are duplicates / scroll-variants / multi-screenshot continuations, noted inline.

**Headline finding:** Zealova **already matches or beats roughly 95% of Calorii's feature set, frequently deeper.** Every "gap" in the first pass turned out to already ship in the Flutter app (body scan, health score, grocery, leaderboard, social, voice logging, home checklist, custom trends, from-fridge). So this audit is not a build-list — it is (1) **confidence** (we are ahead), (2) a short list of **genuine gaps**, (3) **wiring/discoverability** fixes that surface what we already built, and (4) **positioning wedges**. The one net feature the user wants pushed is the **Meal Planner** (exists, but buried + single-day).

> ⚠️ Verification note baked into this doc: an early agent inspected `frontend/src` (the React **marketing site**) instead of `mobile/flutter/lib/` (the **app**) and produced false "GAP" calls. All statuses below are re-verified against actual Flutter screen/widget code and registered backend routers. See `project_frontend_src_is_not_the_app` memory.

---

## ✅ Implementation status — _Shipped 2026-06-06_

The audit's build list has been executed (tracker: `~/.claude/plans/we-have-a-new-ethereal-scroll.md`). All touched files analyze-clean (zero new errors); backend parser unit-tested.

- **Meal Planner (P1):** `/nutrition/meal-planner` route + shell · 14-day multi-day strip · one-tap AI per-slot swap (reuses `simulate(withSwaps)`) · `/nutrition/grocery` route.
- **Quick Actions (P2):** Meal Plan · New Recipe (`RecipeBuilderSheet`) · From Fridge (`/nutrition/from-fridge`) · Custom Trends tiles added.
- **Mascot (P3):** `NutritionMascot` (shark "Finn") — 5-pose cross-fade by calorie progress, **centered inside the ring**, calm motion + particles + log-pulse; wired into `hero_nutrition_card.dart`. Assets in `assets/mascot/shark/`.
- **Nutrition Score 0–100 (P3.4):** `_ScoreDial` `outOf` option (stored score stays 1-10).
- **Workout (P4):** "Week X of N · phase" chip (`plan_header.dart`) · NL activity logging (`POST /cardio/parse-text`, deterministic MET, + "Describe it" field) · richer generation loader caption.
- **Onboarding (P6):** goal-feasibility line + confetti plan-reveal.
- **Already shipped (audit was stale):** before/after comparison gallery (Stats Photos tab), skip-a-scheduled-workout (home workout-options + missed-workout banner).
- **Covered by existing flows (no redundant build):** what-if (analyze-preview + companion totals + meal-plan simulate), burn view (net-burn row + burned sheet), pre-scan context (describe mode).
- **Dropped per user:** Social branch move (next update).

---

## 1. Tag legend

Same scheme as `amy_feature_requests_audit.md` / `youtube_audit_tasks_immediate.md`:

- **[NEW]** / **[CHANGE]** / **[WIRE]** / **[MKT]** / **[RESEARCH]** — primary type. **[WIRE]** = the feature already exists; the work is routing/surfacing it.
- **· AI** LLM/ML core · **· UI** Flutter frontend · **· BACKEND** FastAPI/cron/migration · **· DATA** data/content · **· VERIFY** confirm-already-shipped.
- **Zealova cross-check:** **✅ SHIPS** (don't rebuild — cite file) · **🟢 SHIPS+BURIED** (exists & reachable but hard to find — surface it) · **🟠 SHIPS-ORPHANED** (backend live, Flutter UI unrouted — wire it) · **🟡 PARTIAL** (have half) · **🔴 GAP** (true opportunity) · **⭐ WE WIN** (we beat Calorii here) · **⚪ N/A** (Calorii-specific bug — regression-guard class).

---

## 2. TL;DR scorecard

| | Where it stands |
|---|---|
| **Feature parity** | Zealova ships ~95% of what Calorii shows, usually deeper. |
| **Genuine net-new gaps** | Core 3: nutrition mascot w/ mood states · global "what-if" preview · per-slot alternate-meal regenerate. Plus 4 small ones (§3.11): AI activity logging from text/voice · skip-a-workout · "Week X of N" label · activity/burn view on the nutrition ring. |
| **"Exists but buried/orphaned"** | Meal planner (no route), grocery list (orphaned), before/after comparison UI (orphaned), social (buried in Nutrition branch). Fix = surface, not build. |
| **Where we clearly win** | Logging breadth (menu scan + label OCR), micronutrient depth, adaptive TDEE, accuracy machinery, coach depth, video form analysis, real in-app social, safety positioning. |
| **Their cons** | Brutal 5-use free cap, broken empty-state charts, brand/typo inconsistency, unsafe weight-loss claims, "community" = a Facebook-group link, no Apple Sign-In visible. |

### Pros / cons at a glance

**Calorii pros (what's genuinely nice):** charming mood-mascot in the calorie ring · polished 16-step linear onboarding with drum pickers + goal-feasibility/target-date + confetti reveal · 0–100 Nutrition Score dial (marketable) · optional "additional context" field before a photo scan · per-meal cuisine + type-a-craving meal generation · animated mascot generation loader · "Up Next" workout launcher.

**Calorii cons:** free tier capped at 5 AI uses ("can't even try it") · empty-state charts render as broken placeholders (axes read `1,1,1,0,0`) · brand name inconsistent (Calorii vs Caloriii) + copy typos ("AI Describe Mealing") · over-promises ("23 kg in 4 months = completely achievable", "changes in 7 days") · community is just an external Facebook-group link · no Apple Sign-In on an iPhone build (review risk) · photo-estimated body-fat % of dubious accuracy.

### 2a. Wiring confirmation table (reachability, not just file-existence)

| Feature | Status | Route / entry point |
|---|---|---|
| AI Body Scan | 🟢 WIRED | `/body-analyzer`, entry from Progress (`progress_screen_ui.dart`) |
| Body measurements + BMI bands | ✅ WIRED | `/measurements`, 7+ home/metrics entry points |
| Before/after transformation analysis | 🟠 ORPHANED (UI) | backend live (`progress_photos.py` + `progress_narrative.py`); Flutter `comparison_gallery.dart` / `photo_editor_screen.dart` **unrouted** |
| Meal health score (1–10) | ✅ WIRED | analyze-result preview + logged-meal detail (`logged_meals_section.dart`); end-to-end populated |
| Floating AI-coach launcher | ✅ WIRED | global overlay (`coach_floating_button.dart`, `app.dart`) |
| Logging modalities (text/snap/voice/barcode/menu/label/screenshot/multi-photo) | ✅ WIRED | all surfaced in `log_meal_sheet_ui*.dart` |
| Micronutrients | ✅ WIRED | collapsible in preview + full-screen `/nutrition/micros` |
| Adaptive/dynamic TDEE | ✅ WIRED | training/rest/fasting adjustment chip + `/nutrition/dynamic-targets` |
| Leaderboard | ✅ WIRED | **Discover** bottom-nav tab (`/discover`) + `/xp-leaderboard` |
| Friends / social | 🟢 BURIED | `/social` nested in the **Nutrition** shell branch; only via home cards (branch-stickiness quirk) |
| Achievements / XP / badges | ✅ WIRED | `/achievements`, `/xp` |
| Getting-Started home checklist | ✅ WIRED | `setup_checklist_card.dart` (home, first 7 days) |
| **Meal planner** | 🟢 BURIED | **NO route**; only via Nutrition → Recipes sub-tab (`recipes_tab.dart`) |
| **Grocery list** | 🟠 ORPHANED | no route; only via meal-planner Grocery button (`grocery_list_screen.dart`) |
| **Custom Trends** | 🟢 BURIED | `/trends/custom` exists; not a Quick Action |
| **From Fridge** | 🟢 BURIED | `recipe_from_fridge_screen.dart` + `/recipes/from-pantry`; only via a Recipes-tab button |
| AI form analysis (video) | 🟢 BY-DESIGN | inline cards in chat stream (no route, intentional) |
| Recipe creator/builder | 🟢 BURIED | glass sheet from Food Library only (`recipe_builder_sheet.dart`) |

Every backend router named above is **registered** (no defined-but-not-mounted): `progress_photos`, `body_analyzer`, `barcode`, `scan_imports`, `menu_analyses`, `food_logging_stream`, `adaptive`, `tdee_adherence`, `micronutrients`, `xp`, `achievements`, `leaderboard`, `social/connections`, `meal_plans`, `weekly_plans`, `recipe_suggestions`, `recipe_imports`, `ai_tools/form_check`.

### 2b. Where Zealova BEATS Calorii (defend + press the lead)

- ⭐ **Logging breadth** — we surface photo + barcode + **nutrition-label OCR** + **menu scan** + **app-screenshot parse** + multi-photo stitch + voice + text. Calorii has photo + barcode + voice + text only. **Menu scan + label OCR are clean wins** (and a marketing pairing per `feedback_menu_scan_always_paired`).
- ⭐ **Micronutrient depth** — 20+ vitamins/minerals with RDA progress bars + full-screen `/nutrition/micros`. Calorii shows only P/C/F plus a vague "Additional Nutrition" collapsible.
- ⭐ **Adaptive / dynamic TDEE** — MacroFactor-class, confidence-aware, with a training/rest/fasting-day adjustment chip. Calorii uses static targets that visibly diverge (plan summary 259/101/86 g vs dashboard 260/101/87 g).
- ⭐ **Accuracy machinery** — deterministic calorie cache, override DB, confidence bands, tap-to-explain health-score reasons. Calorii has no visible accuracy story (a known weakness class for text-AI nutrition apps).
- ⭐ **AI Coach depth** — coach memory + sessions + LangGraph multi-agent + a global floating launcher. Calorii's "AI orb" is a generic always-on chat with no memory surfaced.
- ⭐ **AI form analysis from video** — squat/bench/deadlift scored against NSCA/Rippetoe standards. Calorii has no form-analysis category at all.
- ⭐ **Real in-app social** — `/social` follow/friends + leaderboard. Calorii's "Community" is just a **Join Facebook Group** link.
- ⭐ **Recipes ecosystem** — community recipes, favorites, scheduled recipes, batch-cooking, from-fridge.
- ⭐ **Localization** — **36 locales** with a native-script language picker (`language_section.dart`, `locale_provider.dart`) vs Calorii's lone English switcher. Big edge for non-US growth.
- ⭐ **Safety positioning** — we don't promise "23 kg in 4 months = completely achievable" or "changes in 7 days." Their over-promises are a trust liability we can market against (pairs with our no-LLM-for-safety stance).

---

## 3. Feature-by-feature comparison (by surface)

### 3.1 Onboarding & goal-setting
Calorii: a **16-step linear "Your profile" flow** — goal (5 archetypes incl. a "Fast Weight Loss" split), gender (3 options), age/height/weight via tactile drum pickers w/ inline edit + dual units, activity level, **goal-feasibility card** (Current 98 → 23 kg to lose → Goal 75 · timeline 4 months · target Sep 2026), meals/day + diet pattern (Keto/Paleo/Vegan), food likes/dislikes + allergens, workout experience, training days + equipment + duration, **17-muscle-group focus picker with anatomical art**, free-text plan instructions + injury notes + **physique-photo upload** ("photos not saved"), avatar + auto-username, **confetti plan reveal**.

- [ ] **[VERIFY · UI] Onboarding goal/target/timeline + feasibility framing** — Calorii commits the user with a date + "achievable" reassurance. Zealova onboarding is conversational. *Adopt the framing (goal weight + target date + weekly-rate), DROP the unsafe "completely achievable" claim.* ✅ SHIPS goal/weight/activity/restrictions/rate (`backend/api/v1/nutrition/onboarding.py`, `preferences.py`); 🟡 the visible feasibility/target-date card + confetti reveal is the polish delta. _Added 2026-06-06._
- [ ] **[CHANGE · UI] Tactile drum/ruler pickers + inline manual-edit for age/height/weight** — verify whether our conversational onboarding already captures these tactilely; if not, the drum-picker is a nicer input. 🟡 verify-first. _Added 2026-06-06._

### 3.2 Food logging + Nutrition Score
Calorii: tri-modal — **voice ("tap to speak")**, photo "Food Scan" (with an optional "cooked with olive oil…" context field before analysis), conversational "Calorii AI" chat — each returns per-item macro parsing and a **0–100 Nutrition Score** dial. Barcode in free tier. Honestly rejects non-food ("no edible food items").

- [x] **[VERIFY · AI · UI] Multimodal logging** — ⭐ WE WIN. Zealova surfaces text/snap/voice + **barcode + menu scan + label OCR + app-screenshot + multi-photo** in `log_meal_sheet_ui*.dart`. Calorii lacks menu scan + label OCR. _Added 2026-06-06._
- [x] **[VERIFY · AI] Meal quality score** — ✅ SHIPS. We compute a **1–10 health score** with tap-to-explain reasons, shown on the analyze RESULT preview AND each logged-meal row (`logged_meals_section.dart`, populated via Gemini `overall_meal_score`/computed fallback in `food_logging.py`). _Added 2026-06-06._
- [ ] **[CHANGE · UI] Nutrition Score parity — 0–100 dial styling + more prominent placement** — ours is a 1–10 badge; Calorii's 0–100 arc dial reads more "scored." Cheap visual win: offer a 0–100 display option and a hero dial on the result preview. 🟡 polish. _Added 2026-06-06._
- [ ] **[NEW · UI] Optional "additional context" free-text on the photo-scan preview** ("cooked with olive oil, extra sauce") — improves portion/method accuracy before analysis. 🔴 GAP on the pre-scan affordance (we have post-hoc serving arbitration). _Added 2026-06-06._

### 3.3 Daily dashboard
Calorii: calories-left ring with an **animated mood mascot** ("Need energy."), 3 color-coded macro cards, an "Additional Nutrition" (micros) collapsible, 4 meal slots (Breakfast/Lunch/Dinner/Snacks), water tracking (cups + oz), Nutrition/Activity toggle.

- [x] **[VERIFY · UI] Calorie ring + macros + micros + meal slots + water** — ✅ SHIPS, deeper. Daily tab + `/nutrition/micros` full-screen + adaptive-target adjustment chip. ⭐ micros depth beats them. _Added 2026-06-06._
- [ ] **[NEW · UI] Nutrition mascot with mood states** — 🔴 GAP. Calorii's living calorie-ring character with mood captions is charming; ours `companion_picker_sheet.dart` is a food-pairing picker, NOT a character. This is the in-progress `project_nutrition_character_mascot` (hand-coded SVG rejected ~6×). **Ship via Rive/Lottie in Flutter**; must react across the full arc incl. over-limit. _Added 2026-06-06._

### 3.4 Meal planning, recipes, grocery, alternates
Calorii: AI meal plan, **type-a-craving → full recipe with portions + macros**, unlimited swipeable alternates per slot, per-meal cuisine selector, saved-meal library, **auto grocery-list builder**, multi-day plan.

- [ ] **[WIRE · UI] Meal planner — route + surface it (PRIORITY, user ask)** — exists (`meal_planner_screen.dart`: single-day, 4 slots, macro rings, coach review, grocery button) but 🟢 BURIED (no route; only via Recipes sub-tab). Register a route + Nutrition-tab entry + Quick Action tile. _Added 2026-06-06._
- [ ] **[NEW · UI] Multi-day plan view** — planner is single-day; backend `meal_plans.py` / `weekly_plans.py` already support multi-day. Wire the Flutter span-days view. 🟡 PARTIAL. _Added 2026-06-06._
- [ ] **[NEW · AI · UI] Per-slot "generate alternate / swap this meal"** — one-tap regenerate per slot. Backend `recipe_suggestions.py` + meal-plan `simulate with_swaps` exist; add the slot-level UI. 🟡 PARTIAL (today: remove+add). _Added 2026-06-06._
- [ ] **[WIRE · UI] Grocery list — give it a real route** — 🟠 ORPHANED (`grocery_list_screen.dart` reachable only via planner button). Route it + ensure the planner Grocery button reaches it reliably. _Added 2026-06-06._
- [x] **[VERIFY · AI] From-fridge / pantry → recipes** — ✅ SHIPS. `recipe_from_fridge_screen.dart` + backend `/recipes/from-pantry` + `pantry_analysis_service.py` (snap fridge → detect items → suggest recipes). Calorii doesn't have this — ⭐ potential win once surfaced. _Added 2026-06-06._
- [ ] **[NEW · AI · UI] Type-a-craving recipe inline in a slot + per-meal cuisine** — matches Calorii's "Your Plan, Your Way." Reuse `RecipeSuggestionService`. 🟡 stretch on the planner. _Added 2026-06-06._

### 3.5 AI coach / recommendations / what-if
- [x] **[VERIFY · AI] Coach + meal recommendation + daily recap** — ✅ SHIPS, ⭐ deeper (memory + sessions + LangGraph + global floating launcher). _Added 2026-06-06._
- [ ] **[NEW · AI · UI] Global "what-if" preview** — "+fries → +380 cal" from anywhere, simulate-before-commit. 🟡 PARTIAL (only meal-plan `simulate` + companion-picker running total today). _Added 2026-06-06._

### 3.6 Workout programming
Calorii: AI multi-week periodized programs (Week 1 of 6, % complete), PPL day tabs, per-exercise muscle + equipment tags, warm-ups, drop sets, tempo cues ("Slow Negative"), 3D illustrations, skip/swap/regenerate, "Up Next" launcher, animated mascot generation loader.

- [x] **[VERIFY · AI] Workout generation + programs + illustrations** — ✅ SHIPS (this is Zealova's Workout-AI moat). Parity or better on structure/illustrations/equipment-awareness. _Added 2026-06-06._
- [ ] **[VERIFY · UI] "Up Next" workout launcher card** — verify our home workout card already covers this (it's the moat surface per `feedback_workout_card_is_moat`); adopt the thumbnails+Skip pattern only if missing. 🟡 verify-first. _Added 2026-06-06._
- [ ] **[NEW · UI] Animated generation loader (mascot + progress messaging)** — "Finalizing your routine…" with an animated character beats a blank spinner (`feedback_instant_feel_ai_generation`). 🟡 polish. _Added 2026-06-06._

### 3.7 Body analysis
Calorii: AI Body Scan (body-fat % / muscle / symmetry, each /100), before/after transformation analysis ("photos not saved"), body measurements (chest/arms/thighs…), BMI classifier with band gauge.

- [x] **[VERIFY · AI] AI Body Scan** — ✅ SHIPS. `body_analyzer_screen.dart` (1,709 lines) + `backend/services/gemini/body_analyzer.py`: BF% (3–60), muscle %, overall rating /100, symmetry, body type, posture findings, improvement tips, program-retune proposals. Deeper than Calorii's. _Added 2026-06-06._
- [x] **[VERIFY] Body measurements + BMI bands** — ✅ SHIPS (`measurements_screen.dart`, `measurements_repository.dart`). _Added 2026-06-06._
- [ ] **[WIRE · UI] Before/after comparison gallery** — 🟠 ORPHANED. Backend before/after AI summary is live (`progress_photos.py` + `progress_narrative.py`) but Flutter `comparison_gallery.dart` / `photo_editor_screen.dart` are unrouted dead UI. Wire them in. _Added 2026-06-06._

### 3.8 Gamification & social
Calorii: Getting-Started 0/4 home checklist, 🔥 streak / 👥 friends / 🏆 leaderboard header chips, Global + Friends leaderboards (weekly + all-time, Monday reset, opt-in Join/Leave), Add Friends, avatars + auto-usernames. (But the actual "community" is an external Facebook-group link.)

- [x] **[VERIFY] Streaks · XP · achievements/badges · Getting-Started checklist** — ✅ SHIPS (`streaks.py`, `xp.py`, `achievements.py`, `setup_checklist_card.dart`). _Added 2026-06-06._
- [x] **[VERIFY] Leaderboard + friends/social** — ✅ SHIPS, ⭐ WE WIN (real in-app social vs their FB link). Leaderboard = Discover tab; `/social` follow/friends. _Added 2026-06-06._
- [ ] **[WIRE · UI] Move `/social` out of the Nutrition shell branch** — 🟢 BURIED; branch-stickiness UX quirk (tapping Nutrition can return you to Social). Give it its own entry/branch. _Added 2026-06-06._

### 3.9 Monetization & paywall
Calorii: $9.99/mo or $49.99/yr (Save 58%, anchor $119.88), 7-day trial, discount-code field, Free vs Premium toggle, hard free metering (5 AI uses; 2 body scans), "Continue with Free" de-emphasized vs gold Premium.

- [ ] **[RESEARCH · MKT] Trial/cap learnings** — their brutal 5-use cap visibly costs trial users ("can't even try it"); contrasts with our 7-day trial. Note for trial/paywall A/B. Our live pricing is $7.99/mo + $59.99/yr (`project_pricing`); single-tier Premium (`feedback_single_tier_paid`) — do NOT propose free-vs-Premium gating. A **discount-code field** is a low-effort adopt. _Added 2026-06-06._

### 3.10 Design / polish language
Calorii: persistent floating "AI orb" on every screen, dark-navy + spearmint-green theme, color-coded section accents (green nutrition / cyan workout / purple AI / gold leaderboard), soft notification pre-permission prompt, confetti, animated mascot. See §7 for the adopt list.

### 3.11 Completeness cross-check (every remaining screenshot element accounted for)

Re-verified against actual app/backend code so nothing observed in the 72 images is left off the executable list.

| Calorii element (screenshots) | Zealova status | File / action |
|---|---|---|
| Ingredient-level add/edit on a scan/log result ("+ Add Ingredient", macros recompute) | ✅ SHIPS | `recipe_builder_sheet.dart` (full ingredient CRUD + live totals) |
| Multi-language / language switcher (🇺🇸 English) | ⭐ WE WIN | `settings/sections/language_section.dart` + `core/providers/locale_provider.dart` — **36 locales** w/ native-script picker vs Calorii's single switcher |
| Reports: Calories Burned (7D/1M/1Y) | ✅ SHIPS | `trends/custom_trend_screen.dart` |
| Reports: Workout Volume over time | ✅ SHIPS | `workouts/.../workout_stats_trend_chart.dart`, `progress/charts/widgets/volume_chart.dart` |
| Reports: Calorie-intake macro stacked-bar | ✅ SHIPS | `stats/widgets/nutrition_tab.dart` (`MacroBreakdownCard`) |
| Reports: Weight trend | ✅ SHIPS | `home/widgets/cards/weight_trend_card.dart` + EWMA in custom trends |
| Avatar selection + display name/username | ✅ SHIPS | `profile/widgets/edit_personal_info_sheet.dart` |
| Program change/swap/regenerate | ✅ SHIPS | `backend/api/v1/workouts/program.py` (`quick-regenerate`) + `weekly_plan_screen.dart` |
| Generated plans include warm-ups | ✅ SHIPS | `workout/active_workout_screen_refactored.dart` (`WorkoutPhase.warmup`) |
| Drop sets / tempo cues ("Slow Negative", 3-1-2-0) | ✅ SHIPS | `models/gemini_schemas.py` (`is_drop_set`, `tempo`) |
| Profile/Settings table-stakes (notifications, theme dark/light, device & apps, delete account, subscription) | ✅ SHIPS | settings screens + health-sync + delete-account compliance |
| **AI activity logging from text/voice** ("30-min brisk walk" → burn) | 🟡 PARTIAL → **build** | manual `cardio/log_cardio_screen.dart` + `api/v1/cardio.py` exist; no NL/voice → MET burn. Add a text/voice parse on top |
| **Skip a scheduled workout** | 🔴 GAP → **build** | `active_workout_screen_refactored.dart` — add a Skip action (quit/abandon exists, explicit skip does not) |
| **"Week X of N" periodization label** | 🟡 PARTIAL → **build** | `weekly_plan_screen.dart` regenerates per-week but surfaces no phase/week-of-N header |
| **Activity/Burn view on the nutrition daily ring** (Nutrition/Activity toggle) | 🔴 GAP → **build** | `home/widgets/hero_nutrition_card.dart` (3-page carousel) + `calories_burned_sheet.dart`/`daily_activity_card.dart` — add a burn page/toggle |
| Non-food guard in text path (typed "iguana") | 🟡 VERIFY | media classifier handles photo; confirm text path refuses non-foods |
| AI Meal Generator (calorie + preference → meal) | ✅ SHIPS | `recipe_suggestions.py` (`SuggestRecipesRequest`) |
| Meal Plan Tips multi-slide onboarding modal | ⚪ polish | optional first-run education; low priority |

---

## 4. What Zealova actually needs from this (prioritized)

**Build / wire now:**
1. **MEAL PLANNER (user's #1 ask)** — route + surface on the Nutrition tab + Quick Action tile; multi-day view; per-slot generate-alternate/swap; route the grocery list; (stretch) type-a-craving recipe inline. Files in §5/§6.
2. **Quick Actions tiles** — Meal Planner, Recipe Creator, Custom Trends, From Fridge (all features exist — surfacing only). §6.
3. **Nutrition mascot w/ mood states** (Rive/Lottie) — the one genuinely missing daily-dashboard feature.
4. **Global what-if preview** + **Nutrition Score 0–100 styling**.
5. **Smaller verified gaps (from §3.11 cross-check):** AI activity logging from text/voice (NL→burn on top of `cardio/log_cardio_screen.dart`) · skip-a-scheduled-workout action (`active_workout_screen_refactored.dart`) · "Week X of N" periodization label (`weekly_plan_screen.dart`) · Activity/Burn view on the nutrition daily ring (`hero_nutrition_card.dart`).

**Wiring fixes (high ROI, low effort — surface what we already built):**
- Route the orphaned **grocery list** and **before/after comparison gallery**.
- Move `/social` out of the Nutrition branch.
- Deep-linkable, nav-surfaced meal planner.

**Discoverability / polish:** onboarding goal-feasibility + target-date + confetti reveal · optional-context field before photo scan · animated generation loader · richer empty states (theirs render broken).

**Positioning / marketing wedges (don't build — message):** safety vs their "23 kg in 4 months" claim · micronutrient depth · logging breadth (menu scan + label OCR) · real in-app social vs their FB-group link · deterministic-accuracy wedge.

**Research, don't build blind:** their 5-use free cap as a trial-friction data point · whether to adopt 0–100 vs keep 1–10 · discount-code field.

---

## 5. Priority build — Meal Planner (mini-roadmap)

Files: `mobile/flutter/lib/screens/nutrition/meal_planner/meal_planner_screen.dart`, `mobile/flutter/lib/screens/nutrition/grocery/grocery_list_screen.dart`, `mobile/flutter/lib/screens/nutrition/widgets/recipes_tab.dart` (current modal entry), `app_router_utility_routes.dart` (add route), backend `api/v1/nutrition/meal_plans.py` + `weekly_plans.py` (multi-day) + `recipe_suggestions.py` (alternates).

1. **Route + surface** — register `/nutrition/meal-planner`; add a first-class Nutrition-tab entry + a Quick Action tile (§6). Today it's a `Navigator.push(MaterialPageRoute(... MealPlannerScreen ...))` from `recipes_tab.dart`.
2. **Multi-day view** — extend the screen to span days (backend already multi-day capable).
3. **Per-slot alternates** — one-tap "generate alternate / swap" per slot, reusing `recipe_suggestions.py` + `simulate with_swaps`.
4. **Grocery route** — give `grocery_list_screen.dart` a route; verify the planner Grocery button reaches it.
5. **(Stretch)** type-a-craving → recipe-with-portions inline in a slot.

---

## 6. Quick Actions shortcuts to add

Infra: `mobile/flutter/lib/core/models/quick_action.dart` (`QuickAction` class + `quickActionRegistry` const map + `QuickActionBehavior` enum) and `mobile/flutter/lib/widgets/quick_actions_sheet.dart` (`_categories` map = Log/Plan/Tools + `_buildActionChip` behavior switch). Sheet opens from the home "+" More button (`quick_actions_row_part_more_actions_button.dart`).

To add a tile: (a) add an entry to `quickActionRegistry`, (b) add its id to a `_categories` section, (c) **route tiles** → `behavior: QuickActionBehavior.route, route: '…'`; **modal tiles** → add a `case` in `_buildActionChip`.

| Tile | Section | Target (already exists) | Wiring |
|---|---|---|---|
| **Custom Trends** | Plan | `/trends/custom` (`custom_trend_screen.dart`) | pure route tile — easiest |
| **Meal Planner** | Plan | `meal_planner_screen.dart` | needs route (§5) then route/modal case |
| **Recipe Creator** | Plan | `recipe_builder_sheet.dart` (glass sheet) | new `recipeBuilder` behavior case → `showGlassSheet(RecipeBuilderSheet)` |
| **From Fridge** | Log | `recipe_from_fridge_screen.dart` + `/recipes/from-pantry` | give it a route or a modal case |

All four are **existing features** — this is surfacing, not building.

---

## 7. UI/UX patterns worth adapting from Calorii

Honest framing: most Calorii UI maps to things we already have. These are the genuine deltas. Tags: **adopt-now** / **polish** / **verify-first**.

1. **Mascot mood caption** under the calorie ring ("Need energy.") — pairs with the mascot build. *(polish)*
2. **Goal feasibility + target-date** onboarding card as a commitment device — adopt framing, **drop** the unsafe "completely achievable / changes in 7 days" claim. *(adopt-now)*
3. **Confetti plan-reveal** after onboarding. *(polish)*
4. **Tactile drum/ruler pickers** + inline manual-edit for age/height/weight. *(verify-first)*
5. **Optional "additional context" field before a photo scan** ("cooked with olive oil"). *(adopt-now)*
6. **Per-meal cuisine selector + type-a-craving** inline in a meal slot. *(adopt-now, ties to planner)*
7. **0–100 score dial** styling for the health score. *(polish)*
8. **Soft notification pre-permission priming** modal before the OS dialog. *(verify-first)*
9. **Animated generation loader** with mascot + progress messaging. *(polish)*
10. **"Up Next" workout launcher card** (exercise thumbnails + Skip). *(verify-first)*

**Calorii UX mistakes NOT to copy:** broken empty-state charts (placeholder `1,1,1,0,0` axes) · brand/typo inconsistency (Calorii vs Caloriii; "AI Describe Mealing") · hard 5-use free cap · unsafe weight-loss claims · de-emphasized "Continue with Free" dark-pattern.

---

## 8. Calorii weaknesses / regression-guard list

- ⚪ Empty-state charts render as broken placeholders on a fresh account (axes `1,1,1,0,0`, no skeleton/sample). *Guard: our empty states must never look broken (`feedback_design_preferences`).*
- ⚪ Brand name inconsistent (Calorii vs Caloriii) + copy typos. *Guard: brand-string + copy QA.*
- ⚪ Macro goals diverge between plan summary (259/101/86 g) and live dashboard (260/101/87 g). *Guard: single source of truth for targets.*
- ⚪ Over-promises ("23 kg in 4 months = completely achievable", "changes in 7 days"). *Guard + wedge: safety-first copy.*
- ⚪ Photo-estimated body-fat % presented as precise (12%). *Guard: confidence framing on our body scan.*
- ⚪ "Community" = external Facebook-group link only. *We win with real in-app social.*
- ⚪ No Apple Sign-In on an iPhone build (App Review risk for them).

---

## 9. Per-screenshot appendix (all 72 accounted for)

Sorted by filename (`ls -1`); index = sort order.

1. My Meals → Saved (empty) · 2. Food Scan result — non-food (laptop) "0/100" · 3. Describe Meal (voice/text, Meal tab) · 4. Home + "Log Activity" sheet (blurred) · 5. Describe — Activity tab · 6. Describe Meal (dup of 3) · 7. Profile/Settings (lower) · 8. Paywall + "Continue with Free?" dialog · 9. Food Scan camera Preview + context field · 10. Profile (identity + body stats, kg/cm) · 11. Profile/Settings + Community (FB group) · 12. Progress → Reports (workout volume, empty) · 13. Leaderboard → Friends → All-Time (empty) · 14. Leaderboard → Friends → This-Week · 15. "Quick Actions" sheet (log meals + other) · 16. "Create a Custom Meal" sheet · 17. Leaderboard → Global → Join · 18. Reports (Calories Burned + Volume, empty).

19. Reports (Weight + Calorie + Macro charts, empty) · 20. Body Stats (Weight/BMI/Body Scan/Measurements) · 21. Body Stats (measurements + before/after "Get Feedback") · 22. Workouts → Programs (AI-Generated "Lean Cut 3-Day Split") · 23. Workout day detail (Leg Day, ex 4-7) · 24. Push Day (ex 4-7) · 25. Pull Day (ex 4-7) · 26. Day 2 Pull (top) · 27. Day 3 Leg (top) · 28. Day 1 Push (top) · 29. Workouts → Current (active program, Week 1 of 6, Up Next) · 30. Paywall (yearly $49.99 / monthly $9.99, FatSecret) · 31. Workout-plan generation loader (mascot) · 32. Meal Plan Tips modal (slide 2) · 33. Meal Plan Tips (slide 3) · 34. Meal Plan Tips (slide 1) · 35. Workouts → Current empty ("See My Program") · 36. Meals → Grocery empty ("Create Your Grocery List").

37. Paywall (dup variant) · 38. Meals → Plan landing ("See My MealPlan") · 39. Meals → Saved (5 entry methods) · 40. Home (fresh, Getting Started 0/4) · 41. Home (dup, mascot blink) · 42. Home Nutrition view (2221 cal left, macros, meals, water) · 43. Notifications pre-permission modal · 44. Onboarding 16/16 — avatar + username · 45. Home (dup/zoom of 40) · 46. Onboarding 13/16 — muscle focus (top) · 47. Onboarding 14/16 — instructions + physique photos · 48. Onboarding 13/16 — muscle focus (bottom, 17 groups) · 49. Onboarding 14/16 (dup, "photos not saved") · 50. Onboarding 15/16 — plan reveal (confetti mid-animation) · 51. Onboarding 15/16 — plan reveal (settled) · 52. Onboarding 9/16 — meals/cuisine (dropdown open) · 53. Onboarding 9/16 — meals/cuisine/diet (collapsed) · 54. Onboarding 9/16 (variant).

55. Onboarding 10/16 — food likes/dislikes + allergens · 56. Onboarding 11/16 — workout experience · 57. Onboarding 9/16 — meals + diet pattern (Keto/Paleo/Vegan) · 58. Onboarding 12/16 — training days + equipment + duration · 59. Onboarding 4/16 — height (drum picker) · 60. Onboarding 8/16 — activity level · 61. Onboarding 5/16 — weight (picker + edit) · 62. Onboarding 3/16 — age · 63. Onboarding 7/16 — goal feasibility (23 kg, 4 months, Sep 2026) · 64. Onboarding (dup of 63) · 65. Sign Up (email/pw + Google; no Apple) · 66. Tour slide — "Your Plan, Your Way" (custom meal gen) · 67. Onboarding 2/16 — gender · 68. Onboarding 1/16 — primary goal (5 archetypes) · 69. Tour slide — Week-1 Check-In (AI Body Analyzer) · 70. Tour slide — Instant Food Logging (snap/speak/type + 85/100 score) · 71. Tour slide — Transformation graph (7/30/all) · 72. Tour slide — Personalized Meal + Workout Plan.

---

**Maintained for:** Zealova nutrition + product roadmap. Pairs with `amy_feature_requests_audit.md` (text-AI nutrition demand) and `gravl_roadmap.md` / `macrofactor_roadmap.md` (workout + nutrition rivals). _Created 2026-06-06._
