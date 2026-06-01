# Zealova — Amy Feature-Board Audit (competitor demand signal)

**Source:** 236 screenshots in `next_update/amy_images/` of the **Amy** food-journal app's public feature-request board (Canny-style; the "Feedback / Roadmap / Updates" board run by founder **Chris Raroque**). Amy is a direct natural-language-text nutrition competitor (type your meal → AI calculates calories/macros via Perplexity Sonar over MyFitnessPal-class databases; ~1¢/log inference cost per the founder's own comments).

**Parsed:** 2026-06-01 by 14 parallel Sonnet vision agents (contiguous image ranges), then synthesised + de-duplicated here.

**Coverage:** 236 images → **~190 distinct requests**. Dropped 16 exact duplicates + 7 status-tab repeats; stitched 19 multi-screenshot continuations. Every image accounted for once.

**Why this matters:** This is a free, vote-ranked, comment-validated list of exactly what real nutrition-app users are begging for — and Amy's founder has publicly marked several **Completed** (validated demand he chose to ship). It's a high-signal input to Zealova's nutrition roadmap. Pairs with `youtube_audit_tasks_immediate.md` (the Fitbit-Air / Google-Health-Coach reviewer audit).

---

## Tag legend

Same scheme as `youtube_audit_tasks_immediate.md`:

- **[NEW]** / **[CHANGE]** / **[MKT]** / **[RESEARCH]** — primary type
- **· AI** — LLM/ML-driven behaviour is core · **· UI** — Flutter frontend · **· BACKEND** — FastAPI/cron/migration · **· UI+BACKEND** — both · **· DATA** — data/DB/content · **· VERIFY** — confirm-already-shipped/guard-against-bug-class
- **Amy board:** `<votes> votes · <status> · <N> comments` — `status` ∈ {Pending, Reviewing, Planned, In Progress, Completed}. **Completed** = Amy already shipped it (strongest demand signal).
- **Zealova cross-check:** **✅ SHIPS** (don't rebuild — cite file) · **🟡 PARTIAL** (have half) · **🔴 GAP** (true opportunity) · **⚪ N/A** (Amy-specific bug, not a Zealova feature — kept as a regression-guard class).

**Vote tiers:** **Tier 1** ≥10 votes · **Tier 2** 3-9 votes · **Tier 3** 1-2 votes. (Amy's board skews to 1 vote per item because each request is narrow; vote count is still the cleanest demand proxy.)

---

## 🔥 Top demand — the items to act on first

| Votes | Request | Amy status | Zealova |
|---:|---|---|---|
| **101** | Barcode scan + nutrition-label photo scan | ✅ Completed | 🔴 GAP |
| **36** | Summarise long food titles ("…22g protein" → "protein shake") | Pending | 🔴 GAP |
| **26** | Recommend a meal to fill remaining macros (from history) | Pending | 🟡 PARTIAL |
| **25** | OAuth sign-in (Apple / Google) | ✅ Completed | ✅ SHIPS |
| **23** | Don't show "thinking…" until user pauses typing | In Progress | 🔴 GAP |
| **23** | Sugar tracking | ✅ Completed | ✅ SHIPS (2223) |
| **19** | Dark / glass / tinted app-icon support | Planned | 🔴 GAP |
| **13** | Reorder/auto-group entries by time eaten | Pending | 🟡 PARTIAL |
| **13** | Display vs edit mode (tap "Done" to commit a row) | Pending | 🔴 GAP |
| **12** | Weight-loss-rate selector (fast/moderate/light) | In Progress | ✅ SHIPS |
| **10** | Space out streak vs settings buttons (mis-tap) | Pending | ⚪ N/A |

**Amy's "Completed" list = pre-validated wins** (he saw the demand and shipped): Barcode + label scan (101), OAuth (25), Sugar tracking (23), Send protein→Apple Health, Data export CSV, Body-weight tracker, sodium/other micros, decimal-separator locale fix, music-pause fix. Several Zealova already has — proof we're aligned with the market.

---

## 1. Food-logging input & text-editing UX (Amy's core loop)

The single richest theme — Amy is a text-first journal, so input ergonomics dominate the board.

- [ ] **[NEW · AI · UI+BACKEND] Auto-summarise verbose food titles** — collapse "protein shake with almond milk and banana and one scoop of 22g protein" to "protein shake" in the list; full text on tap-into-detail. *(Amy board: 36 votes · Pending · 2 comments)* Top organic request; commenter wants full meal shown in detail view. 🔴 GAP. _Added 2026-06-01._
- [ ] **[CHANGE · UI] "Display vs edit" mode — commit a row with Done instead of always-editable text** — users feel uneasy being in permanent edit mode; want a clear enter-then-commit affordance. *(Amy board: 13 votes · Pending · 5 comments)* 🔴 GAP. _Added 2026-06-01._
- [ ] **[CHANGE · UI+BACKEND] Reorder / auto-group log entries by time eaten + section breaks** — let users insert breakfast/lunch/dinner separators (grey divider) and reorder; show per-section kcal subtotals. *(Amy board: 13 votes · Pending · 2 comments)* Recurs across many requests (#0037, #0071, #0189, #0190, #0201). 🟡 PARTIAL — Zealova has meal-slot tagging (`food_logging.py`); free-form section dividers + reorder is the gap. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Group entries into named sections with per-section totals** — "Breakfast / Lunch / Dinner" headings that roll up calories; founder liked a "type a special token to make a heading" idea. *(Amy board: 2 votes · Pending · 1 comment)* Companion to reorder-by-time. 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[NEW · UI] Title/heading formatting that's excluded from calorie math** — add a heading row ("Breakfast") that doesn't count as food but sums the items beneath it; enables quick-save-as-meal. *(Amy board: 1 vote · Pending · 1 comment)* 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[NEW · UI] Markdown-ish formatting in the log** — "—" inserts a visual break (fasting gap), "# Heading" sums kcal beneath it; adds organisation + coziness. *(Amy board: 1 vote · Pending)* 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · AI · BACKEND] Comments/notes the AI ignores (flagged with a symbol)** — let users append "# so good and filling" / "# craving sweets" that's stored but excluded from nutrition parsing. *(Amy board: 1 vote · Pending)* 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · UI] Visual line dividers between entries for readability** *(Amy board: 1 vote · Pending)*. 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · AI · BACKEND] "Polish my entry" cleanup button** — one tap rewrites a messy multi-line entry into a clean one (founder suggested a cheap Gemini call). *(Amy board: 2 votes · Pending)* 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · AI · BACKEND] Input normalisation toggle** — optionally standardise the raw typed text after calc so the UI looks clean; commenter pushed back wanting verbatim, so make it optional. *(Amy board: 1 vote · Pending · 1 comment)* 🔴 GAP. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Tab/swipe-to-delete a log row** — backspacing whole entries is tedious. *(Amy board: 1 vote · Pending)* 🟡 PARTIAL (Zealova has per-row delete on food_history; quick gesture is the gap). _Added 2026-06-01._
- [ ] **[NEW · UI] Undo last change (avoid an AI recalc)** — accidental edit should be revertible without re-querying the model. *(Amy board: 1 vote · Pending)* 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · UI] Auto-capitalise first letter on a new line** *(Amy board: 1 vote · Pending)*. ⚪ minor. _Added 2026-06-01._
- [ ] **[NEW · UI] Duplicate a dish with a "+" (2nd/3rd coffee)** — fast repeat-add for items eaten multiple times/day. *(Amy board: 1 vote · Pending)* 🔴 GAP. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Drop-down preview of a meal card instead of opening edit** — tapping the description currently opens edit (rarely wanted); a preview expander is clearer. *(Amy board: 1 vote · Pending)* 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · UI] Submit a raw calorie number as-is** — typing "100" should log 100 cal, not have the AI invent 350. *(Amy board: 1 vote · Pending)* 🔴 GAP — a "just trust my number" fast path. _Added 2026-06-01._

## 2. AI accuracy, calculation & determinism (Amy's #1 trust problem)

Amy's biggest weakness per the board: **same meal returns different calories on different days** (no result caching), and hallucination on vague inputs. This is the wedge `feedback_no_silent_fallbacks` + confidence-band work already targets.

- [ ] **[CHANGE · AI · BACKEND] Deterministic calorie caching — identical input must return identical result** — multiple users logged the *same text* on two days and got 180 vs 103 cal, 200-cal swings, branded items 60% off label. Erodes trust fast. *(Amy board: aggregated across #0033, #0075, #0205, multiple 1-2 vote · Pending)* 🟡 PARTIAL — Zealova has confidence band + `verified_source='override_db'` cross-check (`log_meal_sheet.dart`), and the 198k-row override DB; the determinism guarantee (cache the per-text result) is the explicit gap. _Added 2026-06-01._
- [ ] **[CHANGE · AI · BACKEND] Fix quantity double-counting ("2 pieces of chocolate" logged as 2×2)** — AI lists the item twice and doubles/quadruples macros. *(Amy board: 2 votes · Pending · 1 comment, screenshots attached)* 🟡 PARTIAL — Zealova's serving-arbitration work (`serving_arbitration.py`) is the right home; add a multiplier-dedup guard. _Added 2026-06-01._
- [ ] **[CHANGE · AI · BACKEND] Editing a meal via natural language must actually update macros** — "the patty is 90g with 32g protein" / "6 potatoes not 4" updates the text but not the totals; same for the "something's not right" edit path. *(Amy board: aggregated #0046, #0109, #0183, #0230 · Pending/In Progress)* 🟡 PARTIAL — Zealova has the something's-not-right confirm flow; verify the AI-edit path recomputes + persists. _Added 2026-06-01._
- [ ] **[CHANGE · AI · BACKEND] Don't recalculate on cosmetic edits (capitalisation/reformat)** — wastes an expensive model call with no change. *(Amy board: 1 vote · Pending)* 🔴 GAP — cheap win: hash-compare normalised text before re-querying. _Added 2026-06-01._
- [ ] **[NEW · AI · UI+BACKEND] Ingredient-level breakdown instead of whole-meal estimate** — split a meal into ingredients + cooking method (oil/butter/sauce) and sum, for real-world accuracy. *(Amy board: 1 vote · Pending)* 🟡 PARTIAL — Zealova's Stage-1 dish identification does multi-item; explicit cooking-method adjustment is the gap. _Added 2026-06-01._
- [ ] **[NEW · AI · UI] AI follow-up question when an entry is ambiguous** — instead of silently dropping or guessing, ask a structured multiple-choice ("which option did you mean?"). *(Amy board: 1 vote · Pending)* 🔴 GAP — strong UX: surfaces the model's branch point as a tappable clarifier. _Added 2026-06-01._
- [ ] **[NEW · AI · UI+BACKEND] Database mode vs web-search mode toggle** — let users force official brand-DB lookup vs web search for accuracy. *(Amy board: 1 vote · Pending)* 🟡 PARTIAL — Zealova has the override DB; exposing a source-mode toggle is new. _Added 2026-06-01._
- [ ] **[NEW · UI] Show + edit the assumed serving size / grams** — surface "I assumed 100g, tap to change" so users can correct the portion, not just the food. *(Amy board: aggregated #0085, #0217 scale-slider, #0222 grams · Pending)* 🟡 PARTIAL — companion to "AI calorie estimate cites source food row" (youtube audit). Add a portion slider + editable grams. 🔴 for the slider. _Added 2026-06-01._
- [ ] **[NEW · AI · BACKEND] Calorie-estimate bias must persist across days** — Amy's "more/less" estimate bias resets daily. *(Amy board: 1 vote · In Progress)* 🔴 GAP — if Zealova adds an estimate-bias control, persist it on prefs. _Added 2026-06-01._
- [ ] **[NEW · AI · UI] Photo to refine a typed entry** — type the meal, then optionally attach a photo to improve portion/accuracy; and snap a nutrition label to override the AI guess. *(Amy board: aggregated #0125, #0133, #0137 · Pending)* 🟡 PARTIAL — Zealova has photo portion estimate + multi-photo stitch; the "text-first, photo-as-refinement" combine flow is the gap (ties to multi-image food-log task). _Added 2026-06-01._
- [ ] **[VERIFY · AI · BACKEND] Non-food guard in the TEXT path, not just the photo path** — Amy correctly rejected a photo of an iguana but returned "163 cal" when "iguana" was typed. *(Amy board: 1 vote · Pending)* 🟡 PARTIAL — Zealova has media classifier non-food handling; verify the text path also refuses non-foods. _Added 2026-06-01._

## 3. AI meal recommendation, coach & chat

- [ ] **[NEW · AI · UI+BACKEND] Recommend a meal to fill remaining macros from eating history** — "I have X protein left → suggest a meal from foods I've had before or would like." *(Amy board: 26 votes · Pending · 4 comments)* 2nd-highest organic request; commenter "exactly what this app needs." 🟡 PARTIAL — Zealova has meal-gen; the "fill the gap from MY history" personalisation is the gap. _Added 2026-06-01._
- [ ] **[NEW · AI · UI+BACKEND] Daily AI nutrition coach recap** — daily recommendations on what was good/bad and how to improve. *(Amy board: 1 vote · Pending)* ✅ SHIPS — Zealova has the coach + 7 langgraph agents + nutrition agent + weekly recap is a youtube-audit TODO. _Added 2026-06-01._
- [ ] **[NEW · AI · UI+BACKEND] Ask diet questions in natural language / nutrition chatbot** — "how do I change this meal to hit my goal?"; one user even asked for an MCP connector to use their own Claude. *(Amy board: aggregated #0103, #0129 · Pending)* ✅ SHIPS — Zealova coach chat already does this; MCP connector is a separate MKT wedge (already planned). _Added 2026-06-01._
- [ ] **[NEW · AI · UI] "What if…?" preview mode** — "what if I add fries?" → "+380 cal" preview with an add button, without committing to the log. *(Amy board: 1 vote · Pending · 1 comment, founder "interesting 👀")* 🔴 GAP — delightful, novel; a simulate-before-commit affordance. _Added 2026-06-01._

## 4. Macros, micros & custom trackers

Amy shipped sugar + sodium tracking from this board (validated). Micronutrient depth is a recurring ask — directly aligns with Zealova's micronutrient-depth TODO.

- [ ] **[CHANGE · UI+BACKEND] Sugar tracking** — *(Amy board: 23 votes · ✅ Completed · 2 comments)* ✅ SHIPS — Zealova optional sugar tracker shipped (migration 2223, `optional_trackers_strip.dart`). High-vote validation that this was worth building. _Added 2026-06-01._
- [ ] **[CHANGE · UI+BACKEND] Caffeine tracking (swappable into the macro ring)** — let users replace a ring they don't care about (fiber) with caffeine. *(Amy board: 1 vote · Pending)* ✅ SHIPS — caffeine optional tracker shipped (2223). The *swap-a-ring* customisation is the remaining slice. _Added 2026-06-01._
- [ ] **[NEW · DATA · UI] Micronutrient + vitamin tab (where am I deficient?)** — estimate vitamins/minerals from logged food and show where to improve; users cited **Cronometer** as the benchmark, and asked for potassium (vs sodium), calcium, oxalates, collagen, fiber. *(Amy board: aggregated #0068, #0119, #0139, #0158, #0166 · Pending · multiple comments)* 🔴 GAP — Zealova's "Micronutrient depth" is a youtube-audit TODO; this board confirms strong demand + names the competitor to beat. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Fully customisable tracked macros/micros** — users have specific health needs (kidney stones → sodium+oxalates; arthritis → collagen) and want to pick what's tracked. *(Amy board: 1 vote · Pending · 3 comments)* 🟡 PARTIAL — optional-trackers strip exists; extend the vocabulary + make it user-pickable (`feedback_no_hardcoded_enumerations`). _Added 2026-06-01._
- [ ] **[NEW · UI] Percentages instead of grams toggle on goal bars/widgets** *(Amy board: 1 vote · Pending)*. 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · UI] Customise which single metric shows beside each entry** — some users want protein-per-entry instead of calories. *(Amy board: 1 vote · Pending · founder "interesting, let me see")* 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · UI] Tap a macro → see which foods contributed it (per day)** — "I hit 69g protein, which foods gave me that?"; also "how far over the sodium goal am I?" *(Amy board: aggregated #0028 color-code, #0141, #0215, #0229 · Pending)* 🔴 GAP — a macro-source breakdown for the whole day, not just per-item. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Progressive (current-progress) macro ring colour, not all-or-nothing red** — protein ring stays red until 100%, making a good breakfast feel like failure; colour by current ratio, optionally a full-day-vs-progressive setting. *(Amy board: 3 votes · Pending · 1 comment)* 🔴 GAP — ties to `feedback_accent_colors` macro-colour logic. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Macro rings should show past 100% (Apple-Watch overlap style)** — can't see 150% of sugar goal today. *(Amy board: 2 votes · Pending · 1 comment)* + overflow handling on overconsumption (#0138). 🟡 PARTIAL — `feedback_no_overflow_adaptive_screens`; verify rings render >100%. _Added 2026-06-01._
- [ ] **[NEW · UI] Show goal values (not just consumed/remaining)** — add a "Goal" display option so users see total daily targets without doing the math; also macro at-a-glance "3g / 200g". *(Amy board: aggregated #0043, #0092, #0093 · Pending)* 🟡 PARTIAL. _Added 2026-06-01._

## 5. Calorie balance, burned calories & activity integration

Heavily requested: pull workout/step burn (Apple Health, Peloton) into the daily calorie budget. Recurs ~8 times.

- [ ] **[NEW · UI+BACKEND] Add burned calories (Apple Health / steps / workouts) into the daily budget** — if I burned 300, let me eat 300 more before the ring goes red; cited CalAI as the reference. *(Amy board: aggregated #0036, #0091, #0099, #0107, #0130 · Pending · multiple)* 🟡 PARTIAL — Zealova reads HealthKit/HC active energy + has TDEE; verify the food budget visibly adds exercise burn (adjustable %). Strong cluster. _Added 2026-06-01._
- [ ] **[NEW · AI · BACKEND] Log burned calories from text ("burned 250 cal" / "walked 2 miles")** — estimate burn from a typed activity. *(Amy board: 1 vote · Pending)* 🔴 GAP — natural-language workout-burn entry. _Added 2026-06-01._
- [ ] **[NEW · UI] Weekly calories-in vs calories-out dashboard card** *(Amy board: 3 votes · Pending)*. 🟡 PARTIAL — Zealova trends exist; a dedicated energy-balance card is the gap. _Added 2026-06-01._
- [ ] **[NEW · UI] Display calorie balance = consumed − (TDEE + exercise)** and a per-day Total-Daily-Burn goal. *(Amy board: aggregated #0094, #0095 · Pending)* 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[CHANGE · AI · BACKEND] Don't inflate intake target just because a workout was logged (gain-weight case)** — user gaining weight saw daily target jump on a logged workout, unexpectedly. *(Amy board: 1 vote · Pending)* ⚪/🟡 — verify Zealova's deficit/surplus formula (`feedback_calorie_deficit_formula`) handles exercise correctly per goal direction. _Added 2026-06-01._

## 6. Goals & targets

- [ ] **[CHANGE · UI+BACKEND] Weight-loss-rate selector (fast / moderate / light) that adjusts goals** *(Amy board: 12 votes · In Progress)*. ✅ SHIPS — Zealova has rate→deficit (`feedback_calorie_deficit_formula`, kg/wk × 7700/7). _Added 2026-06-01._
- [ ] **[VERIFY · AI · BACKEND] Never recommend an unsafe calorie target (e.g. 700 cal/day)** — Amy told a user to eat 700 cal to lose 30 lb, eroding trust (MyFitnessPal said 1500). *(Amy board: 1 vote · Pending)* ✅ SHIPS — Zealova's sustainability guardrail + floor on final target (URGENT, shipped); strong validation that the guardrail matters. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Set custom macro + calorie goals directly** *(Amy board: 1 vote · Pending — founder notes it's in Settings)*. ✅ SHIPS (verify discoverability). _Added 2026-06-01._
- [ ] **[NEW · AI · UI] Automatic macro balancing — entered macros should sum to the calorie goal** — set protein, auto-fill carbs/fat to hit the kcal target. *(Amy board: 1 vote · Pending)* 🔴 GAP — nice deterministic helper. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Flexible per-day goals (training vs rest days)** — different calorie/macro targets by day. *(Amy board: 1 vote · Pending)* 🔴 GAP — calorie cycling. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] More goal types beyond lose/gain weight (e.g. gain muscle → higher protein)** *(Amy board: 2 votes · Pending)*. 🟡 PARTIAL — Zealova has goal infra; verify muscle-gain macro skew. _Added 2026-06-01._
- [ ] **[CHANGE · BACKEND] Body-fat % input for more accurate TDEE** *(Amy board: 1 vote · Pending)*. 🔴 GAP. _Added 2026-06-01._
- [ ] **[NEW · UI] Display TDEE in-app (so users see surplus/deficit)** *(Amy board: 6 votes · In Progress)*. 🟡 PARTIAL — verify TDEE is surfaced, not just used internally. _Added 2026-06-01._
- [ ] **[CHANGE · UI+BACKEND] Weekly-average weight + realistic trajectory from actual intake** — smooth daily noise into a trend; project from real (not just goal) calorie surplus. *(Amy board: aggregated #0146, #0154 · Pending)* 🟡 PARTIAL — Zealova has measurements/trends; weekly-average smoothing + intake-based projection is the gap. _Added 2026-06-01._

## 7. Saved meals, recipes, meal-prep & batch cooking

Directly validates Zealova's `feedback_batch_cook_leftovers` model.

- [ ] **[NEW · UI+BACKEND] Meal-Prep / batch-cook mode — enter batch ingredients + N portions → auto per-serving macros + save as reusable recipe** — detailed request: cooked a 14-portion batch, app only showed full-batch totals. *(Amy board: 1 vote · Pending, long writeup)* 🟡 PARTIAL — Zealova models cook events + portions_remaining (`feedback_batch_cook_leftovers`); verify the per-serving divide + save-as-recipe UX exists. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Save common foods/brands so the AI stops re-guessing** — "I always use this milk/bread/protein powder"; remember the brand. *(Amy board: aggregated #0151, #0120 saved-items, #0192 frequent/recent · Pending/Reviewing)* 🟡 PARTIAL — Zealova has food overrides + recents; a user-pinned "my brands" memory is the gap. _Added 2026-06-01._
- [ ] **[NEW · AI · BACKEND] "From yesterday" / reference-a-prior-meal by name** — "the egg sandwich from yesterday" should fetch the exact prior entry, not re-query. *(Amy board: 1 vote · Pending)* 🔴 GAP — also saves inference cost. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Scale a saved meal up/down (½, ×2) reliably** — "/2" worked once then broke. *(Amy board: 1 vote · Pending)* 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Verified-meals database (official brand/restaurant data)** — select a verified "McDonald's cheeseburger" instead of paying for an AI lookup. *(Amy board: 1 vote · Pending)* ✅ SHIPS — Zealova's 198k-row override DB is exactly this; ensure the scan/text path hits it (memory: image scan currently bypasses it — 60s→2-3s fix). _Added 2026-06-01._
- [ ] **[CHANGE · UI+BACKEND] Save a logged entry directly as a reusable meal** — make a meal from what's already on the homepage without re-entering. *(Amy board: from #0015 comment · Pending)* 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Reusable recipe from a URL → log "one portion"** — import a recipe by URL, then log a single serving of it. *(Amy board: aggregated #0200, #0072 · Pending)* ✅ SHIPS — Zealova recipe URL import (`recipe_imports.py`, SSE). Confirm "log one portion of an imported recipe" affordance. _Added 2026-06-01._

## 8. Barcode & photo/label scanning

- [ ] **[NEW · UI+BACKEND] Barcode scanning + nutrition-label photo OCR** — scan a UPC or snap a label to skip AI inference (faster, cheaper, more accurate); a user said barcode is *the* missing feature keeping them from renewing. *(Amy board: 101 votes · ✅ Completed (Amy shipped it) · 8 comments; reinforced by #0136 retention comment, #0113 photo-%-consumed)* 🔴 GAP — **highest-demand item on the entire board.** Zealova's "Barcode scan for food logging" is a youtube-audit TODO; this is the single strongest cross-source signal to prioritise it, wired to the override DB by UPC/EAN. _Added 2026-06-01._
- [ ] **[NEW · UI] Photo-package "% consumed" input** — when snapping a nutrition label, let the user say how much of the package they ate. *(Amy board: within #0113 · Reviewing)* 🔴 GAP — companion to label scan. _Added 2026-06-01._
- [ ] **[NEW · UI] Photo log — attach one photo per logged food (memory + portion check)** *(Amy board: aggregated #0096 marker, #0216 photo-log · Pending)*. 🟡 PARTIAL — Zealova has photo logging; a per-entry thumbnail + list marker is the gap. _Added 2026-06-01._
- [ ] **[NEW · UI] Connect to iOS Visual Intelligence (share a photo into the app)** *(Amy board: 1 vote · Pending)*. 🔴 GAP — iOS share-extension entry point. _Added 2026-06-01._

## 9. Calendar, dates & multi-day data integrity (Amy's worst bug cluster)

Amy has a severe recurring bug class: **switching days copies the previous day's entries across all days / overwrites them**, plus UTC-vs-local date drift. ~10 reports. For Zealova these are **regression-guard** items — directly reinforces `feedback_user_local_time_only` and the home-timeline "yesterday bug" we already fixed.

- [ ] **[VERIFY · UI+BACKEND] Per-day data isolation — switching dates must never copy/overwrite another day's entries** — Amy's most-reported bug (day-switch overwrites all days; can't edit/delete afterward). *(Amy board: aggregated #0021, #0050, #0052, #0208, #0212, #0231 · Pending, several reproductions)* ⚪/🟡 — guard with a date-keyed widget test (mirrors the youtube-audit "metric-card date-integrity guard"). _Added 2026-06-01._
- [ ] **[VERIFY · BACKEND] Timezone-correct date assignment (UTC vs local)** — PST user's 13th data showed on the 14th; post-midnight logs land on the wrong day. *(Amy board: aggregated #0203, #0190 · Pending)* ✅ pattern owned by `feedback_user_local_time_only`; add a guard test. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Move/copy a food entry to a different day** — fix mislogged-after-midnight without re-entering. *(Amy board: 1 vote · Pending)* 🔴 GAP — explicit "move to date" action. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Edit/add data on past days from the streak/calendar view** *(Amy board: 1 vote · Pending)*. 🟡 PARTIAL — verify retro-date editing. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Calendar marks which days have a log vs not; fix date-picker jumping to last year** — show journaled days; tapping a date jumped to 2024. *(Amy board: aggregated #0055 Planned, #0186, #0231 · Planned)* 🟡 PARTIAL — Zealova home date-nav exists; add the has-data marker. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Remove/guard the ability to log to a day that hasn't started** — accidental next-day logging. *(Amy board: 1 vote · Pending)* ⚪ minor guard. _Added 2026-06-01._

## 10. Notifications & re-engagement

- [ ] **[CHANGE · UI+BACKEND] "Only one notification per day" option + fully custom notification times** — users eat at the same times; want control, not 3 fixed pings. *(Amy board: aggregated #0057 (2 votes, Planned), #0226 · Planned)* 🟡 PARTIAL — Zealova has quiet-hours + minimum-mode is a youtube-audit TODO; per-user custom schedule + 1/day cap is the gap. _Added 2026-06-01._
- [ ] **[CHANGE · BACKEND] Follow-up notification only after AI finishes processing** — don't notify for entries still mid-calculation. *(Amy board: aggregated #0209 · Pending)* ⚪/🟡 — relevant to Zealova's `feedback_instant_feel_ai_generation` background-persist flow. _Added 2026-06-01._

## 11. Apple Health & integrations

Amy shipped protein→Apple Health from this board. Reinforces Zealova's "Expand Apple Health write-back" youtube-audit TODO.

- [ ] **[CHANGE · UI+BACKEND] Write nutrients (protein, etc.) to Apple Health** *(Amy board: 2 votes · ✅ Completed)*. 🟡 PARTIAL — Zealova writes workouts+energy; expand write-back to nutrients/water (youtube-audit TODO). Amy shipping it = demand validation. _Added 2026-06-01._
- [ ] **[CHANGE · UI+BACKEND] Two-way water intake with Apple Health (read + write)** *(Amy board: 1 vote · Pending)*. 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[NEW · BACKEND] Use Apple Health "resting energy" / smart-scale weight instead of a generic formula** — cited Foodnoms; pull RMR + body weight from HealthKit. *(Amy board: aggregated #0134, #0168 · Pending)* 🟡 PARTIAL — Zealova reads HealthKit; verify RMR + auto weight import feed TDEE. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Pull workout calories from Apple Watch / Peloton into the budget** *(Amy board: see §5 cluster · Pending)*. 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[CHANGE · UI+BACKEND] Data export (CSV) for sharing with a dietician** *(Amy board: 2 votes · ✅ Completed)*. 🔴 GAP — Zealova has chat-export TODO; a nutrition CSV export is not confirmed. Amy shipped it on demand. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Simple in-app workout tracking (food + workouts hand-in-hand)** *(Amy board: 1 vote · Pending)*. ✅ SHIPS — Zealova is a full workout app; this is a nutrition-app user wanting what Zealova already is (positioning signal). _Added 2026-06-01._

## 12. UI, display, widgets & navigation

- [ ] **[NEW · UI] Dark / glass / tinted app-icon variants (iOS 18 style)** *(Amy board: 19 votes · Planned)*. 🔴 GAP — high-vote polish item; add alternate app icons. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Charts/graphs overview of calories + macros over weeks** *(Amy board: 1 vote · Pending)*. ✅ SHIPS — Zealova trends; ties to youtube-audit graphs-first wedge. _Added 2026-06-01._
- [ ] **[NEW · UI] Timeline view of eating times (spot "always eating dinner late")** — assume log timestamp ≈ eating time unless specified. *(Amy board: 1 vote · Pending)* 🟡 PARTIAL — Zealova home timeline exists; an eating-time-pattern view is the gap. _Added 2026-06-01._
- [ ] **[NEW · UI] Save the meal *time* with the entry** *(Amy board: 2 votes · Pending)*. 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[NEW · UI] "Calorie-only" mode (hide macro goals)** — cited LoseIt; also a "hide the calories, show a simplified score" variant for users who don't want to obsess. *(Amy board: aggregated #0227, #0106 · Pending)* 🔴 GAP — a density/簡-mode for nutrition; mirrors youtube-audit "Data-first low-AI mode." _Added 2026-06-01._
- [ ] **[CHANGE · UI] Fix home-screen widget cutting off the calorie number; keep lock-screen widget live** *(Amy board: aggregated #0088, #0213 · Pending)*. 🟡 PARTIAL — Zealova has iOS/Android widgets; verify number fit + live update. _Added 2026-06-01._
- [ ] **[NEW · UI] Optional bottom nav bar (richer multi-page feel)** — some users want more structure than single-page. *(Amy board: 1 vote · Pending)* ✅ SHIPS — Zealova already has a tab bar (Amy-specific minimalism request). _Added 2026-06-01._
- [ ] **[CHANGE · UI] Improve detail-view discoverability (tap the calorie number)** — users couldn't find that tapping calories opens the breakdown; suggest an onboarding wizard or clearer affordance. *(Amy board: aggregated #0032, #0193, #0229 · Pending)* 🟡 PARTIAL. _Added 2026-06-01._
- [ ] **[CHANGE · UI] Carbs icon should read as carbs (bread/wheat glyph)** *(Amy board: 1 vote · Pending)*. ⚪ minor. _Added 2026-06-01._

## 13. Units, localization & i18n

- [ ] **[CHANGE · UI+BACKEND] Universal imperial↔metric toggle (kg/cm), incl. kJ/kcal energy units** — multiple non-US users (UK, AU, EU) can't switch; "donkey measurements" complaint; Australia uses kJ. *(Amy board: aggregated #0026, #0038 (In Progress), #0157, #0188, #0237, #0138 · multiple)* ✅ SHIPS — Zealova has lb/kg separation (`feedback_weight_units`, `feedback_weight_unit_separation`); verify a single global metric toggle + kJ option. Strong cross-user demand. _Added 2026-06-01._
- [ ] **[VERIFY · BACKEND] Locale-aware decimal separator (comma) in numeric inputs** *(Amy board: 1 vote · ✅ Completed by Amy)*. 🟡 PARTIAL — verify Zealova parses "7,5" in comma locales. _Added 2026-06-01._
- [ ] **[CHANGE · AI · BACKEND] Show the AI reasoning in the user's configured app language** *(Amy board: 1 vote · Pending)*. 🟡 PARTIAL — Zealova has 9-language i18n; ensure AI output respects locale. _Added 2026-06-01._
- [ ] **[NEW · DATA] Regional food-database accuracy (UK/EU/Pakistan/Germany)** — UK McDonald's 400 cal off (defaults to US); Pakistani "Savor Foods" + German "Zwiebelrostbraten" mis-estimated by ~500 cal. *(Amy board: aggregated #0171, #0196, #0228 · Pending)* 🔴 GAP — Zealova has India food DB + US/EU depth audit is a youtube-audit TODO; this confirms regional parity matters. _Added 2026-06-01._
- [ ] **[NEW · DATA] German app translation (+ general non-English UI)** *(Amy board: 1 vote · Pending)*. ✅ SHIPS-adjacent — Zealova has 9 Indian languages; German is a net-new locale (Gujarati already the next i18n gap). _Added 2026-06-01._

## 14. Onboarding & first-run

- [ ] **[CHANGE · UI] Fix onboarding under iOS Display Zoom / large font** — onboarding clipped in Zoom mode; survey number-pickers lag. *(Amy board: aggregated #0165, #0169 · Pending)* 🟡 PARTIAL — ties to `feedback_no_overflow_adaptive_screens`; verify onboarding at largest accessibility sizes. _Added 2026-06-01._
- [ ] **[NEW · UI] First-run wizard pointing out the detail view + key gestures** *(Amy board: see #0193 · Pending)*. 🟡 PARTIAL. _Added 2026-06-01._

## 15. Pricing, trial & monetization (competitor intel)

Amy is paid-only with a 24h trial and no free taste — and the board shows real friction. Validates Zealova's `feedback_single_tier_paid` while flagging the trial-friction risk.

- [ ] **[RESEARCH · MKT] Trial friction — let users taste the app before subscribing** — multiple "instant turn-off, can't even try it" + "didn't realise my 24h trial expired" + confusing pricing → fear-driven "delete account." *(Amy board: aggregated #0090, #0164, #0178, #0182 · Pending, founder: core AI logging is too expensive to make free)* relevant to Zealova's 7-day trial + paywall; study whether a no-credit-card / limited-taste variant lifts conversion (mirrors youtube-audit 30-day-trial RESEARCH). _Added 2026-06-01._
- [ ] **[RESEARCH · MKT] Family / shared plan demand** *(Amy board: within #0164 · Pending)*. Zealova single-tier; note as pricing input only. _Added 2026-06-01._
- [ ] **[NEW · UI+BACKEND] Referral system** *(Amy board: 1 vote · Pending)*. 🔴 GAP — growth lever. _Added 2026-06-01._

## 16. Privacy & permissions

- [ ] **[VERIFY · UI+BACKEND] Revoked location permission must stay revoked** — Amy re-enabled its in-app location toggle and showed precise location after the user disabled it in iOS Settings. *(Amy board: 1 vote · Pending)* ⚪/🟡 — Apple-review + trust risk; verify Zealova never re-requests/overrides a revoked permission. _Added 2026-06-01._

## 17. Social & community

- [ ] **[RESEARCH · AI · UI+BACKEND] Friend groups / shared streaks / nudges** — diet-with-friends community: see how friends are doing, nudge them, group streaks. *(Amy board: 3 votes · Reviewing — founder "experimenting on it this week!")* 🔴 GAP — Zealova has gamification scaffold (`project_gamification_role`); a social layer is net-new — research before building. _Added 2026-06-01._

## 18. Persona-specific goals

- [ ] **[NEW · AI · UI+BACKEND] Breastfeeding / pregnancy calorie+macro adjustment** — nursing users need ~300-400 extra cal/day; requested twice, founder engaged. *(Amy board: aggregated #0160, #0173 · Pending · founder interested)* 🔴 GAP — Zealova has women's-health/cycle infra + "Mira" persona TODO; add a lactation/pregnancy goal modifier. _Added 2026-06-01._

## 19. Performance, queue & connectivity (regression-guard class)

Amy-specific reliability failures — for Zealova these reinforce the no-silent-fallback + connection-pool lessons already in memory.

- [ ] **[VERIFY · BACKEND] AI request queue must not stall / hit provider rate limits silently** — items "stuck in queue" for days; founder hit his AI-provider cap. *(Amy board: aggregated #0023 (4 votes), #0034, #0164 · Pending)* ⚪/🟡 — relevant to `project_http_connection_pool_starvation`; ensure graceful degradation + visible error, not infinite "in queue." _Added 2026-06-01._
- [ ] **[VERIFY · UI+BACKEND] Logs must never silently disappear (offline / network-switch / multi-device)** — many "my meals vanished" reports tied to wifi↔lte handoff, eduroam, second device, app crash. *(Amy board: aggregated #0019, #0098, #0126, #0140, #0144 (In Progress), #0145, #0199 · multiple)* ⚪/🟡 — reinforces Zealova's Drift offline-save-queue TODO + `feedback_no_silent_fallbacks`. _Added 2026-06-01._
- [ ] **[VERIFY · BACKEND] Don't re-query the model on cosmetic/no-op edits; let users delete a single queued item** *(Amy board: aggregated #0083, #0164 · Pending)*. cost + UX. _Added 2026-06-01._
- [ ] **[CHANGE · AI · BACKEND] Background AI processing — let users log a batch and leave while it computes** *(Amy board: 4 votes · Planned)*. 🟡 PARTIAL — mirrors Zealova `feedback_instant_feel_ai_generation` (optimistic + background persist). _Added 2026-06-01._
- [ ] **[VERIFY · UI] Don't pause the user's music/video when the app opens** *(Amy board: 3 votes · ✅ Completed by Amy)*. ⚪ — verify Zealova's audio session doesn't grab playback. _Added 2026-06-01._

## 20. Pure bug-class guards (Amy implementation failures, low Zealova relevance)

Logged for completeness; mostly Amy-specific. Treat as a checklist of failure modes a text-first nutrition UI can hit:

- Streak/settings buttons too close → mis-tap (10 votes); streak icon == calorie icon confusion (consolidate iconography). *(#0013, #0022, #0141)*
- Streaks silently stop / don't update despite logging. *(#0086, #0210)*
- Horizontal-scroll leaking in settings + nutrition-detail drawer (should lock to vertical). *(#0061, #0124)*
- Keyboard-open scroll-to-bottom feels broken; long lists need bottom padding. *(#0110, #0131)*
- Text overlap (food name vs calorie label). *(#0132, #0053 misalignment)*
- Camera sheet flickers/dismisses on iPhone 16 Max. *(#0076)*
- Calories computed but not added to the total after a crash. *(#0140)*
- "Error calculating" with no explanation; everything resolves to 0 cal. *(#0031, #0098)*
- React error #300 after liking a feedback post. *(#0121)*
- Can't select a saved meal (plus button no-ops). *(#0247, ✅ fixed by Amy)*

---

## Cross-source reinforcement (Amy board ↔ youtube_audit)

These appear in **both** the Amy board and the Fitbit-Air/Google-Health-Coach reviewer audit — highest-confidence roadmap items:

1. **Barcode + label scan** (Amy 101 votes, Completed) ↔ youtube nutrition-depth TODO → **prioritise.**
2. **Micronutrient depth, Cronometer-class** (Amy multi-request) ↔ youtube "Micronutrient depth" TODO.
3. **Add exercise burn to the calorie budget** (Amy ~8 reports) ↔ youtube activity-integration.
4. **Concise / data-first / hide-the-prose mode** (Amy "calorie-only" + "hide calories") ↔ youtube "AI-slop / Data-first mode" (the strongest youtube wedge).
5. **Apple Health write-back (nutrients/water)** (Amy Completed protein write-back) ↔ youtube "Expand Apple Health write-back."
6. **Deterministic / accurate estimates with confidence** (Amy's #1 trust gripe) ↔ youtube URGENT calorie-accuracy + confidence band (Zealova ✅ shipped — a live differentiator vs Amy).
7. **Timezone / per-day date integrity** (Amy's worst bug cluster) ↔ youtube "metric-card date-integrity guard" + Zealova's already-fixed home "yesterday bug."
