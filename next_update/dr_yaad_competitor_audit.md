# Zealova — Dr. Yaad App Competitor Audit (screenshot teardown + where-we-lack analysis)

**Source:** 21 screenshots in `next_update/dr_yaad__app/` + `blog.txt` (landing-page copy) + `yt.txt` (full launch-video transcript) + `yt_comments.txt` (~100 YouTube comments) of **Dr. Yaad's app** (a.k.a. "Doctor Ja" / "The App", `doctorja.com/theapp`). The dev is **Dr. Yaad** — a medical doctor (GP), 15 yr calisthenics athlete, 12 yr coach. Built solo over ~3 weeks in Bali (Expo/React-Native frontend + PostgreSQL backend; "Claude + Codex doing a lot of the heavy lifting on the UI").

**Parsed:** 2026-06-26 — 21 images viewed directly + full transcript/blog/comments read, then cross-checked against Zealova's actual Flutter (`mobile/flutter/lib/`) + backend (`backend/`) code by 3 verification passes.

**Scope of this doc (per request):** **analysis only** — compare/contrast, where we lack, where we win, positioning wedges. **No file-level build roadmap.** Each gap *is* tagged with an effort axis (**[QUICK] / [MEDIUM] / [HEAVY] / [ZERO-BUILD]**) and there's a Quick-Wins callout up top, so the speed signal isn't buried — but this is effort *characterization*, not a task list.

---

## 0. What this competitor actually IS (read this first — it frames everything)

Do **not** over-react. This is a **niche depth threat, not a breadth threat:**

- **Calisthenics-ONLY.** Planche / front lever / foundational strength / hypertrophy skill work. No nutrition. No cardio. No breadth. He confirmed in comments it is *not* for general weightlifting ("is this for calisthenics only?" → effectively yes).
- **Pre-launch / not released.** Pipeline is: 10 handpicked test athletes → 25–50 waitlist users → wider. The app in the video has "nothing in it right now" for exercise videos; multiple flows are described as "almost done" / "probably done today."
- **iOS-only.** Android is "on the roadmap" (asked ~4× in comments). No iPad UI yet.
- **Solo dev, vibe-coded frontend.** His own audience calls it out: *"obvious vibe coded app," "AI gradients in the background," "design looks like 95% of all other vibe-coded front ends."* He owns it ("as a solo dev in 2026 I'm absolutely using it").
- **The moat is the FOUNDER, not the software.** Doctor + elite athlete + 12 yr coach + a year of audience trust. Distribution = his channel. "Trained on 12 years of Doctor Yaad's coaching."

**But the intelligence design is genuinely strong**, and this is where it matters to us. His pitch — *"a training **decision system**, not a workout app"* — is built on ideas that map directly onto **Zealova's own stated moat backlog** (recovery-aware Daily Outlook; the advise→act loop that's still OPEN). His core architecture:

> **Four ledgers, every set:** category stimulus · **tissue fatigue** · systemic load · skill exposure.
> **AI for the messy, deterministic for the safety-critical:** AI interprets check-ins / summarizes / explains / *drafts* changes you **Accept/Reject**; a deterministic engine owns progression / volume / deload / constraints. *"It never silently swaps things on you."*
> **Personalization earned over time**, not a setup quiz. *"The longer you use it, the more confident it gets about you specifically."*

That philosophy is exactly ours — we already run deterministic progression with zero-LLM safety math. The gap is in **three places he's ahead on execution:** (1) a pre-workout check-in that *live-reshapes the session*, (2) a coach that *proposes a concrete change you Accept*, and (3) a **tissue/joint** fatigue model. Everything else we match or beat.

---

## 1. Tag legend

Same scheme as `caloriii_competitor_audit.md`:

- **Zealova cross-check:** **✅ SHIPS** (don't rebuild — cite file) · **🟡 PARTIAL** (have half) · **🔴 GAP** (true opportunity) · **⭐ WE WIN** (we beat him here) · **⛔ DON'T-CHASE** (calisthenics-niche; note, don't build).
- **Effort axis (on gaps):** **[QUICK]** = data/infra already exist, pure surfacing (~hours–days) · **[MEDIUM]** = existing infra, new wiring/flow · **[HEAVY]** = new model/strategic · **[ZERO-BUILD]** = messaging only.

---

## 2. TL;DR scorecard

| | Where it stands |
|---|---|
| **Feature/breadth parity** | Zealova is a **vastly broader, shipped product**: nutrition + workout-AI + video form analysis + coach memory + social + Android, in 36 locales. His app is one deep calisthenics vertical, pre-launch, iOS-only. |
| **Where HE is genuinely ahead (execution)** | **3 things:** (1) pre-workout check-in that **live-reshapes today's session** · (2) a proactive coach that **proposes a concrete change with [Accept]** · (3) **per-joint/tissue** fatigue tracking. All three map to *our own* open "advise→act / recovery-aware" moat work. |
| **Where we already match him** | Deterministic progression engine · readiness scoring · injury→exercise filtering · skill-progression system (chains/holds) · mesocycle blocks + "Week X of N" · movement-pattern ontology · equipment-aware generation. Much of his "magic" we already have — sometimes unsurfaced. |
| **Where we clearly WIN** | Breadth (nutrition/form-video/social) · shipped + Android + 36 locales · real exercise-image library · injury-safe chokepoint · DOTS/overload analytics. |
| **His cons** | Vibe-coded UI (audience-voiced) · pre-launch (10 testers) · iOS-only · no breadth · over-eager promises in the comments ("yes it will absolutely work for you" to a 15-yo with 3 tendon injuries — a liability we avoid). |

### Pros / cons at a glance

**Dr. Yaad app pros (genuinely good):** the **pre-workout check-in → session reshape** loop (sleep/readiness gauges → "anything to flag?" → engine rewrites the session) · the **proactive "Coach Noticed" card** that names yesterday's pain and proposes a fix with [Accept]/[Talk more] · **3D pain body-map** with per-region severity + which-exercise-triggers-it tagging + monitor/swap thresholds · **four-ledger tissue/joint fatigue** concept · **fast 2-swipe set logging** with goal/last-session/rep-range dials + adaptive caption · **strength-to-skill ratio → block picker** ("the ratio decides, not a template") · **deterministic-engine-as-trust** framing (never silent-swaps).

**Dr. Yaad app cons:** pre-launch / unreleased · iOS-only, no Android/iPad · calisthenics-only (no nutrition/cardio/breadth) · **vibe-coded frontend (his own audience says so)** · exercise videos empty ("nothing in it right now") · no import from other apps (admits the data model can't) · solo-dev bus-factor · over-promising in comments to injured minors · pricing unset, accessibility worry voiced repeatedly.

---

## 3. ⚡ QUICK WINS — fast, high-ROI, data/infra already exist (called out first)

These are the gaps where **we already have the data or backend** and the work is *surfacing*, not building:

1. **[QUICK · UI] Movement-category chips on the active-workout exercise list** — his Today screen tags each exercise `SKILL` / `STRENGTH` / `PREHAB` (image copy 4). We already populate `movement_pattern` / `mechanic_type` (migration 235) but render only `isChallenge`/`isFinisher` badges. Pure UI surfacing of data we own.
2. **[QUICK · UI] Relocate the adaptive set-caption onto the set row** — he shows "You matched last session. Beat it and next week goes heavier" right under the dials (image copy). We already *compute* the adaptation (`set_logging_mixin_ui.dart:253`) but bury it in the rest row. Move it onto the set.
3. **[QUICK · UI] Surface skill progressions + a hold-time chart into Today** — full skill system already exists (`models/skill_progression.py`, `exercise_progressions_screen.dart`) but lives on a *separate* screen. He weaves it into the daily flow + a "planche 10s→14s, plan to 16s by deload" history chart (image copy 19). Surfacing + one chart.
4. **[QUICK · UI] A "Coach Noticed" card on Today** (the *card*, not the apply-action) — `daily_insight.py` infra already produces injury-aware chips; rendering a prominent "Right shoulder at 5/10 — here's the plan" card is surfacing. (The deeper *apply-session-edit* behind [Accept] is MEDIUM — see §4.)

**[ZERO-BUILD] messaging wins** (just say them — see §6/§7): Android, 36 languages, **camera form analysis** (he calls it "very ambitious, ideas list"), **import from other apps** (he can't), **manual logging + AI feedback** (he's "not v1"), nutrition/breadth, shipped-vs-waitlist.

---

## 4. Where Zealova LACKS (ranked by significance; effort-tagged; analysis, not tasks)

> ### 🛠️ BUILD PROGRESS (implementing all 12 — one continuous run, started 2026-06-26)
> The user approved building every gap below at full fidelity. This table is struck off as each ships.
>
> | # | Gap | Cluster | Status | Commit |
> |---|-----|---------|--------|--------|
> | 8 | Movement-category chips | C polish | ✅ shipped | Phase 1 |
> | 9c | On-set adaptive caption | C polish | ✅ shipped | Phase 1 |
> | 11 | Skill→Today + hold chart | C polish | ✅ shipped | Phase 1 |
> | 2c | "Coach Noticed" card (surface) | A | ✅ shipped | Phase 1 |
> | 1 | Pre-workout reshape gate | A | ✅ shipped | Phase 2 |
> | 2a | Coach apply-action | A | ✅ shipped | Phase 2 |
> | 3 | Pain→today's-exercise swap | A | ✅ shipped | Phase 2 |
> | 9d | Set-logging dials | C polish | ✅ shipped | Phase 3 |
> | 10 | Equipment-aware progression method | C polish | ✅ shipped | Phase 3 |
> | 12 | Accept/Reject draft step | D trust | ✅ shipped | Phase 3 |
> | 5 | Exercise effect-profiles | B engine | ⬜ pending | — |
> | 4 | Per-tissue fatigue ledger | B engine | ⬜ pending | — |
> | 6 | Per-user volume learning | B engine | ⬜ pending | — |
> | 7 | Strength→skill block picker | B engine | ⬜ pending | — |

### Cluster A — the advise→act loop (his real edge; = our OPEN moat item)

**#1 · Pre-workout check-in GATE that live-reshapes today's session — 🟡 PARTIAL → effectively 🔴 GAP · [MEDIUM]**
He gates **Start Workout** behind a 2-step check-in: (1) Sleep + Readiness 0–10 gauges (image copy 9), (2) "Anything to flag?" cards — Soreness / Pain / Training time / Equipment / Note for Coach (image copy 7). On submit, a deterministic engine **rewrites the already-prescribed session on the spot**: "only 40 min today" → cut low-priority, keep priority work; bad sleep → pull load back; sore shoulder → swap the aggravator (image copy 17).
- **Our status:** we have readiness scoring (Hooper Index: sleep/fatigue/stress/soreness) + `adjust_workout_params_for_readiness()` (`backend/api/v1/workouts/readiness_utils.py:255`) — but it runs at **generation time** and surfaces as an *advisory daily card* on the Progress screen (`readiness_checkin_card.dart`), **not** as a gate on "Start Workout" that live-edits the session you're about to do.
- **The delta:** we *adjust at generation*; he *reshapes at the door*. This is precisely the **advise→act loop our own memory flags as OPEN** (`project_coach_capability_menu`). The intelligence exists; the *gated start-flow + on-the-spot reshape* is the missing wiring.

**#2 · Proactive "Coach Noticed" card that proposes a CONCRETE change with [Accept]/[Talk more] — 🔴 GAP · [QUICK] card / [MEDIUM] apply-action**
His Today screen and morning chat name yesterday's pain and propose a specific fix: *"Right shoulder at 5/10 this morning. Planche lean loads it directly. Start with cuban rotations to warm the shoulder before planche work."* with **[Accept]** (applies the edit) / **[Talk more]** (image copy 2, image copy 4).
- **Our status:** `daily_insight.py:218` produces injury-aware chips, but they're **check-ins** ("How's my shoulder?" / `injury_resolved` / `start_rehab`) — not a session edit. We have `fatigue_alert_modal.dart` (accept a weight reduction) but it's **reactive, mid-workout**, not a pre-session proposal.
- **The delta:** ours advises; his **proposes a concrete change and applies it on Accept**. Card-surfacing is QUICK; the apply-session-edit action is MEDIUM.

**#3 · Pain → current-session exercise linking + swap thresholds — 🟡 PARTIAL · [MEDIUM] lite / [HEAVY] full**
He logs pain on a **3D body map** (front/back/L/R + medial/lateral/anterior sub-regions, image copy 3 / 5), rates 0–10, and tags **which of today's exercises trigger it** (Planche Lean, Weighted Dips…). Thresholds are explicit: **≤3 = "monitor," 4+ = "swap zone"** (engine swaps the aggravator). Post-workout it offers a **rehab plan** if pain is high.
- **Our status:** we have a **2D** `body_muscle_selector.dart` + 0–10 pain on the **injury detail** screen — but it's *retrospective*, not linked to today's specific exercises, and there's no monitor/swap threshold or rehab-plan-from-pain generation. `avoided_exercises` ("pain:") and `get_muscles_to_avoid_from_injuries()` exist but operate at generation, not in-session.
- **The delta:** a *lite* version (tag which of today's exercises hurt on the existing 2D selector → swap at a threshold) is MEDIUM; the full 3D map + rehab generation is HEAVY (and partly calisthenics-flavored).

### Cluster B — the deeper moat-deepeners (strategic, heavy)

**#4 · Per-JOINT / TISSUE fatigue accumulation — 🔴 GAP · [HEAVY]**
His "four ledgers" include a **tissue ledger** — load building in *elbows/wrists/tendons* across exercises that share a category, so it "sees injuries coming before they happen."
- **Our status:** we track **per-muscle-group** volume only (`volume_tracking_service.py`, `strain_prevention_service.py` weekly set caps keyed by muscle). No joint/tendon/connective-tissue accumulation model.
- **The delta:** real conceptual gap and arguably his single best idea — but heavy (new model) and matters most for high-joint-stress calisthenics (planche/levers); weigh ROI for a general-population app.

**#5 · Exercise effect profiles (recoverability / tissue-stress / time-cost / prehab) — 🔴 GAP · [HEAVY]**
He models each exercise as a tool with a measurable effect profile (what it stimulates, what tissue it stresses, how recoverable, how time-costly).
- **Our status:** rich movement metadata already (migration 235: `movement_pattern`, `mechanic_type`, `force_type`, `plane_of_motion`, `impact_level`, `form_complexity`, `hold_seconds`…) — but **no** recoverability / tissue-stress / time-cost / `is_prehab` fields. These are the *inputs* that power #1's "cut low-priority work" and #4's tissue ledger.
- **The delta:** the ontology backbone exists; the effect-profile columns + a prehab flag don't.

**#6 · Earned per-user adaptive volume landmarks — 🔴 GAP · [HEAVY]**
*"It learns how your body responds… you handle vertical-pull volume well, your elbow flexors get hot fast… assertive where it has data, conservative where it doesn't."* (image copy 19).
- **Our status:** progression is deterministic but **rule-based** (RPE thresholds / plateau / deload, `progression_service.py:119`). No learned per-user/per-muscle response model.
- **The delta:** ours is good auto-regulation; his is a per-user volume *history*. Aspirational/ML-ish; heaviest item.

**#7 · Strength-to-skill RATIO → block recommendation — 🔴 GAP · [HEAVY]**
He computes basic-lift strength vs skill level into a ratio and **picks the block**: Skill / Foundational Strength (daily undulating) / Hypertrophy — *"the ratio decides, not a template"* (image copy 11/12 → 18).
- **Our status:** we ship the **blocks** (mesocycle rampUp/overreach/deload + "Week X of N · phase" chip, `mesocycle_planner.dart` / `plan_header.dart:72`) but no logic that *selects* a block from a strength↔skill assessment. We have `cardio_to_strength_ratio`, not strength↔skill.
- **The delta:** structure exists; the *recommender* doesn't.

### Cluster C — polish

**#8 · Movement-category chips on the workout list — 🔴 GAP (UI) · [QUICK]** — see §3.1.
**#9 · Fast set-logging dials (goal/last/rep-range) + on-set caption — 🟡 PARTIAL · [QUICK] caption / [MEDIUM] dials.** His set screen (image copy): big REPS, a horizontal dial with **goal (yellow) / last-session (blue) / rep-range (boxed band)**, same for LOAD, + an adaptive caption, ~2 swipes to log. Ours (`set_row.dart:366`) shows "Prev: X" text only (Hevy-style), no visual dial, caption in the rest row, ~4 taps.
**#10 · Per-session "what can you load today?" + equipment-DIFFERENTIATED progression *method* — 🟡 PARTIAL · [MEDIUM/HEAVY].** He asks per-session "what can you load today?" (image copy 8/20) and **progresses differently** for limited equipment (leverage/variation, not added weight). We filter exercises by equipment + snap to owned weights, but the *method* stays LINEAR/WAVE/DOUBLE regardless.
**#11 · Skill progressions into Today + hold-time history charts — 🟡 PARTIAL · [QUICK]** — see §3.3.

### Cluster D — trust framing

**#12 · Deterministic/AI separation as a TRUST feature + universal Accept/Reject draft step — 🟡 PARTIAL · [MEDIUM].** His headline trust pitch: AI only *drafts*; you **Accept/Reject/Modify**; the engine never silently swaps. Our progression *is* deterministic (a real win) — but generation **silently commits**; there's no explicit Accept/Reject/Modify gate for coach-proposed changes. We have the better engine; he has the better *transparency UX*.

---

## 5. Feature-by-feature by surface

| Surface | His app (screenshots) | Zealova status | Evidence / note |
|---|---|---|---|
| **Strength assessment (onboarding)** | Pull-ups/dips/press: can't-yet/bodyweight/weighted + added-load & max-reps drum pickers (image copy 11) | ✅ SHIPS | onboarding strength capture + 16-muscle scoring, DOTS percentile |
| **Skill assessment (onboarding)** | "Where are you on the climb?" tuck→adv-tuck→straddle→full planche (image copy 12) | 🟡 PARTIAL | skill chains exist (`skill_progression.py`); onboarding skill-level capture is calisthenics-flavored ⛔ |
| **Plan reveal** | "Your plan is ready," block + per-day list, expandable, "Adjust with the coach" (image copy 14/16) | ✅ SHIPS | weekly plan + confetti reveal (added in caloriii pass) |
| **Pre-workout check-in** | Sleep+Readiness gauges → "Anything to flag?" → reshape (image copy 7/9/10) | 🟡 PARTIAL → 🔴 | **#1** — adjust-at-generation, not gated reshape |
| **Active set logging** | goal/last/range dials + adaptive caption, 2 swipes (image copy) | 🟡 PARTIAL | **#9** — "Prev:" text only, no dial |
| **Movement-category tags** | SKILL/STRENGTH/PREHAB chips per exercise (image copy 4) | 🔴 GAP (UI) | **#8** — `movement_pattern` data exists |
| **Pain logging** | 3D body map + region + 0–10 + trigger-exercise + monitor/swap (image copy 3/5/6) | 🟡 PARTIAL | **#3** — 2D, retrospective, no thresholds |
| **Proactive coach card** | "Coach Noticed" + [Accept]/[Talk more] applies edit (image copy 2/4) | 🔴 GAP | **#2** — chips are check-ins, not edits |
| **Coach chat** | reshapes plan from NL ("only 40 min"), explains "why" (image copy 17) | ✅ SHIPS ⭐ | LangGraph multi-agent + memory + sessions; he admits "explain why" not in his beta |
| **Programming / blocks** | Skill/Foundational/Hypertrophy via ratio; "Week X of N" (image copy 18) | 🟡 PARTIAL | blocks ✅ (`mesocycle_planner.dart`) · ratio picker 🔴 **#7** |
| **History / skill progress** | hold-time charts + skill-event log (image copy 19) | 🟡 PARTIAL | **#11** — system exists, unsurfaced |
| **Equipment** | per-session "what can you load today?" + presets (image copy 8/20) | 🟡 PARTIAL | filter ✅; per-session quick-pick + method-differentiation 🔴 **#10** |
| **Tissue/joint fatigue** | tissue ledger across category-sharing exercises (blog) | 🔴 GAP | **#4** — per-muscle only |
| **Nutrition / cardio / form video / social** | — (none) | ⭐ WE WIN | entire categories he doesn't have |

---

## 6. Comment-derived signal (`yt_comments.txt`, ~100 comments)

**(a) Audience asks that are OUR wins — [ZERO-BUILD], just message:**
- **Android** — asked ~4× (Luki, rajdeepsingh, wangxuerui — a software engineer offering to help build it). He's iOS-only. *We're live on Android.*
- **Other languages / Russian** (ДанилИльин). *We ship 36 locales.*
- **Camera form analysis** (LANCELOT_SW) — he: *"technically very ambitious but on the ideas list."* *We ship squat/bench/deadlift video scoring today.*
- **Import history from other apps** (wary8792) — he: *"can't do this yet… the data model is vastly different."* (We can position around this.)
- **Manual logging + AI feedback on your own sessions** (sTuBdino) — he: *"definitely want to add… not in v1."* *We have manual logging.*
- **General weightlifting, not just calisthenics** (zacharybovard) — out of his scope by design.

**(b) Demand signals relevant to us (validate our roadmap):**
- **Explain the "why" behind decisions** (tsitegeist, -esox-) — repeatedly wanted; *not in his beta.* Our coach already explains reasoning — lean into it.
- **Lower-body / leg day** in a calisthenics plan (elsecox, aaronbgym).
- **Hybrid athlete (running/walking) + Apple Health** (nat008_64) — he says "on the list." We have cardio + Health Connect/Apple Health.
- **Hypermobility** (uznaz1783), **menstrual cycle** (NatureGreek), **streetlifting** (botoboto) — niche segment demand.

**(c) His audience-voiced weaknesses (wedge material — don't invent, quote them):**
- *"obvious vibe coded app"* (hexa_editor, 12 likes) · *"AI gradients in the background"* (ninetailed) · *"wish the design didn't look like 95% of all other vibe-coded front ends"* (apfelbaum). His own fans flag the design.
- Waitlist **name-field font color** bug (ninetailed).
- **Pre-launch reality:** 10 testers → 25–50 waitlist. Exercise videos empty.
- **Pricing unset** + accessibility worry voiced repeatedly (revali, Kili, yosefkesef: one-time vs subscription unknown).
- **Over-promising to injured users** — told a 15-yo with three tendon injuries *"yes it will absolutely work for you."* A trust/liability line we deliberately don't cross (pairs with our no-LLM-for-safety + "see a physio" stance — which, to his credit, he does say elsewhere for sternum/scapular cases).

---

## 7. Where Zealova WINS (defend + press the lead)

- ⭐ **Breadth** — nutrition + AI form-analysis video + coach memory/sessions + real in-app social + recipes, vs one calisthenics vertical.
- ⭐ **Shipped + cross-platform** — live on iOS **and Android**, in **36 locales**, vs an iOS-only waitlist with 10 testers.
- ⭐ **Same deterministic-safety philosophy, already in production** — our progression/volume/deload is computed with **zero Gemini calls** (`progression_service.py`). His headline pitch is our status quo.
- ⭐ **Injury-safe generation chokepoint** (`enforce_injury_safety`) + injury→muscle surgical filtering — a *general-population* safety system, already enforced on generation.
- ⭐ **Analytics depth** — 16-muscle strength scoring, DOTS percentile, overload dashboard, RPE/RIR-mandatory logging, crash-safe workout checkpoint.
- ⭐ **Real exercise-image/illustration library + camera form analysis** — he explicitly has "nothing in it right now"; form analysis is on his "ideas list."
- ⭐ **No over-promising** — we don't tell injured minors a plan will "absolutely work."

---

## 8. Calisthenics-niche — ⛔ DON'T-CHASE (note, don't build)

These are real in his app but specific to his audience; logging them so we don't reflexively chase:
- Full planche/front-lever **skill trees as a headline** (we have the skill *system*; don't make it the app's spine).
- **Hypermobility-specific** programming logic.
- **Streetlifting** specialization track.
- **Counterweight-pulley / "dream machine"** equipment mode.
- Calisthenics-only **strength-to-skill** onboarding framing (adopt the *ratio→block* idea #7 generically if at all, not the planche-centric UI).

---

## 9. Per-screenshot appendix (all 21 accounted for)

Sorted by filename.

1. **image.png** — Marketing: "Workout apps don't understand calisthenics. Here is one that does." (sun motif).
2. **image copy.png** — Active set logging: "Weighted Dips · Set 2 of 4," REPS 9 + horizontal dial (goal/last-session/rep-range), LOAD 20kg dial, caption "You matched last session. Beat it and next week goes heavier." Nav: Today/Week/Coach/History/Profile. → **#8/#9**.
3. **image copy 2.png** — Coach chat (BETA): references yesterday's 4/10 shoulder, PROPOSAL "Start with cuban rotations… before planche work" + [Accept]/[Talk more] + chips (Why this order? / Make today shorter / Swap). → **#2**.
4. **image copy 3.png** — Pain sheet: 3D body, FRONT/RIGHT/BACK/LEFT, "Right shoulder 3/10 monitor" slider, "Which movements trigger it?" chips, "3/10 monitors. 4+ may swap." → **#3**.
5. **image copy 4.png** — Today: "Friday, June 5 · Week 3 of 7 · Checked in," "The Coach Noticed" card + [Accept]/[Talk more], Push Day w/ SKILL/STRENGTH/PREHAB chips, Start Workout. → **#1/#2/#8**.
6. **image copy 5.png** — Pain zoom: shoulder sub-region pins (MEDIAL/LATERAL/ANTERIOR), "Tap the spot on your body." → **#3**.
7. **image copy 6.png** — Pain: "Right shoulder 5/10 swap zone" (red), Weighted Dips flagged as trigger. → **#3**.
8. **image copy 7.png** — Pre-workout check-in 2/2 "Anything to flag?": Soreness / Pain (Right shoulder · 5) / Training time / Equipment / Note for Coach. → **#1**.
9. **image copy 8.png** — Equipment sheet "What can you load today?": pull-up bar/rings/parallettes/dip station/bands/vest/belt/backpack/bench/cable/barbell/dumbbells/gym. → **#10**.
10. **image copy 9.png** — Pre-workout check-in 1/2 "How are you today?": Sleep 7 "good" / Readiness 7 "ready" green gauges. → **#1**.
11. **image copy 10.png** — Loader "Coach is reading your check-in. Your plan is saved." → **#1**.
12. **image copy 11.png** — Onboarding strength check 1/3 Pull-ups: can't-yet/bodyweight/weighted/not-sure → +6kg added load, 8 max reps (drum pickers). → §5.
13. **image copy 12.png** — Onboarding skill check 1/2 "Where are you on the climb?": full planche/straddle/adv-tuck(YOU)/tuck/never. → **#7** ⛔.
14. **image copy 13.png** — Loader "building your plan — reading your goals, equipment and strength."
15. **image copy 14.png** — "Your plan is ready": Hypertrophy block 7 weeks · Mon Pull / Tue Push / Fri Legs+Core / Sun Skill. → **#7**.
16. **image copy 15.png** — Onboarding "I train 4 days/wk, 53 min/session, starting today" (day toggles + minutes dial).
17. **image copy 16.png** — Plan expanded: Skill Day — Handstand Practice (SKILL), Wall Handstand/Pike "use this," Front Lever Tuck (SKILL), L-sit. → **#8/#11** ⛔.
18. **image copy 17.png** — Marketing "Ask it anything": NL plan reshapes ("only 40 min" → shorten; move Friday→Saturday; "Why weighted dips? Your push strength is behind your planche goal. The ratio decides, not a template"). → **#1/#7/#12**.
19. **image copy 18.png** — Marketing "It picks the block that fits": Skill / Foundational Strength (daily undulating) / Hypertrophy from strength ratios. → **#7**.
20. **image copy 19.png** — Marketing "It keeps learning you": Day-one measure → every-set volume profile of muscles **and joints** → any-day reshape → months-in volume history; History/Progress screen w/ planche 10s→14s chart + skill-event log. → **#4/#6/#11**.
21. **image copy 20.png** — Onboarding equipment grid "What do you have?" Minimal/Home-gym/Park/Gym presets + tunable grid. → **#10**.

---

**Maintained for:** Zealova workout-AI roadmap + competitive positioning. Pairs with `caloriii_competitor_audit.md` (nutrition rival), `gravl_roadmap.md` / `gravl_feature_requests_audit.md` (workout-AI rival), and `macrofactor_roadmap.md`. _Created 2026-06-26._

> **One-line takeaway:** Don't chase the calisthenics niche. Do steal the **three execution ideas that are also our own open moat work** — the pre-workout check-in that *reshapes the session*, the coach that *proposes a change you Accept*, and *tissue-level* (not just muscle-level) fatigue — and ship the §3 quick wins (category chips, on-set caption, skill-on-Today) cheaply now. Everything else, we already win on.
