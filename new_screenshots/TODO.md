# Screenshot Captures — Remaining TODO

**Device:** iPhone 17 Pro simulator (same as the first 5). Dark mode ON. `Cmd+S` to capture.
**Optional but recommended before capturing** (clean status bar so all frames match):

```bash
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
```

---

## ✅ Done (in this folder, mapped in `mockups/assets/`)

| Frame | Caption | File |
|---|---|---|
| F1 | One coach. Workouts AND FOOD | f1_home.png |
| F2 | Real programs. RUN SEVERAL | f2_schedule.png |
| F3 | Snap the menu. BEST PICK | f3_menu.png |
| F4 | Any length. ANY DAYS | f4_perday.png (per-day customize, swapped 07-02; f4_customize.png retired) |
| F5 | Set by set. YOU'RE READY | f5_workout.png |

---

## 📋 Remaining captures (tomorrow)

### F6 — Coach chat logging — SIMPLIFIED (one exchange is enough)
Fresh chat thread. Send ONE message:
1. `two chicken tacos and a Corona at dinner` → wait for the macro card + "Logged" reply

Capture with the message + full reply (macro card) visible. The macro card is the zoom-crop
hero. If a second exchange fits naturally (e.g. `30 min yoga this morning`), great — but one
clean food-logging exchange carries the frame. No keyboard open, no typing indicator,
no half-streamed reply, no exercise-swap messages.

### F7 — AI Form Check result — "Film a set. GET COACHED"
- Film a real squat or deadlift set (full body visible, decent lighting)
- Submit through Form Check, wait for the critique to fully return
- Capture the critique card: score + 3-4 notes visible, no spinner
- ⚠️ If the pipeline is flaky / result looks bad → tell Claude, we swap this frame for the Health Hub alt

### F8 — Overload Dashboard — "Watch your strength CLIMB"
- Home → tap any stat tile → Stats screen → **"Overload"** tab (2nd tab)
- Needs an account with 20+ workouts + a recent PR → use **reviewer@zealova.com** if current account is sparse
- Money shot: 1RM chart trending up + muscle heatmap + PR badge together, fully loaded (no skeletons)

### ✅ F9 — Fridge scan — DONE (07-02, 22:48 capture, post-UI-improvement)
"What's for dinner? / Scan your fridge." — fridge photo hero + 97-MATCH recipe card.
DECK IS 10/10. Next step: final PNG export. Original spec below for reference:

### F9 — Fridge scan → recipes — "Open fridge. GET RECIPES" (App Store slot 9)
- Scan a fridge photo → ingredient chips + 3 recipe cards visible
- ⚠️ Skip if not reliable — App-Store-only slot, Play needs just 8

### F10 — Imports screen — "Bring your history. KEEP GOING" (App Store slot 10)
- Imports/switcher screen showing MyFitnessPal / MacroFactor / Cronometer / Apple Health sources
- Mid-import progress or post-success state
- ⚠️ Skip if not wired — App-Store-only slot

---

## 🔁 Recommended re-shoots (current captures work, but these would be stronger)

### F1 Home (re-shoot suggested)
Current capture starts below the metric deck and shows the "Get Started Challenge 2 of 5"
panel + FAB overlapping at the bottom. Stronger version:
- Scroll to very top so the **metric deck** (steps / sleep / ready / score) is visible **with real values** (current alt capture shows "–" dashes — log some data or use a seeded account)
- Dismiss/collapse the Get Started Challenge card
- Coach card showing a **positive progress** insight (e.g. "Your bench is up...") rather than "Let's pick it up" comeback tone

### ✅ F2 Schedule — MULTI-PROGRAM RESTAGE DONE (07-02, 22:05 capture)
Pink HYROX RACE PREP cards + teal AI MAIN card + Saturday stacking BOTH programs w/ the
"2 sessions today" banner. Live in the working deck. History below kept for reference:

### F2 Schedule (UPDATE 07-02: new capture received — improved but not final)
The 12.45.33 capture now shows distinct card families (blue program badges + teal AI badge +
green TODAY) and is live in the mockups. The TRUE multi-program staging below is still the goal:

### F2 Schedule (re-shoot suggested — this is the moat frame)
Caption is "Real programs. RUN SEVERAL" but current capture shows only ONE program
(No-Equipment Home Workout) + AI sessions, and Sunday shows "No items scheduled".
Stronger version:
- Start 2–3 programs simultaneously (e.g. HYROX + PPL + Mobility) on the account
- Pick a week where ≥4 days have sessions from different programs, at least one day stacking two
- No empty days visible in frame
- If multi-program staging is too much effort, tell Claude — caption falls back to a single-program line ("Real programs. ON YOUR WEEK.")

---

## Universal rules
- No spinners, toasts, debug banners
- No real personal email/name visible
- Settled UI state only (no mid-animation)
- Drop new captures in this folder; Claude maps them into `mockups/assets/` and extends the mockup page

---

## 📌 Locked decisions + open experiments (2026-07-02 consolidated review)

- **Working deck = `mockups/proofs_pano.html`** (9 frames, all self-contained, F1 upright).
  `proofs.html` = stable 5-frame baseline.
- **Green accent LOCKED** as default; orange stays in the toggle as the Play Listing
  Experiment challenger.
- **Pano/frame-crossing effect REMOVED from store frames** — reserve the panoramic look for
  the Play feature graphic (1024×500) and/or the website hero.
- **Social proof: option-by-option verdict (2026-07-02):**
  · Usage counts (2M+ workouts…) — ✗ real numbers too small (245 workouts / 11 users)
  · Community counts — ✗ same
  · **Outcome proof — ✓ SHIPPED, this is our launch social proof**: F8's on-screen
    "Stronger than 49% of comparable lifters" + pill "+10 strength in 30 days" (both real)
  · **Integration credibility — ✓ SHIPPED**: F10 names MFP · MacroFactor · Cronometer ·
    Apple Health · Fitbod · Gravl
  · Press/Featured — ✗ none yet (add when true)
  · Expert credibility — ✗ CANNOT claim "built by certified coaches" (programs are
    AI-authored + reviewed); do not use unless a credentialed advisor signs off
  · Testimonial — ⏳ no quotable public review yet. FOUNDER ACTION: if any beta user said
    something quotable (12–15 words, real), send it → becomes a one-frame sub-line on F1.
  Upgrade triggers: 50+ reviews @4.5+ → ★ badge; 10k+ logged workouts → usage-count pill.
  One line, one frame, always true — a hollow stat hurts more than an absent one.
  **→ This is the FIRST v2 EXPERIMENT once real usage data exists** ("X workouts logged"
  pill on F1, or an aggregate result on F8). F8's "stronger than 49%" carries launch.
- **Play 8-frame selection (LOCKED for export):** F1 · F2 · F3 · F9-fridge · F5 · F6 · F7 ·
  F8. F4 (customize) + F10 (imports) are App-Store-only — fridge is the stronger universal
  frame for Play's 8-slot cap. App Store ships all 10 in order F1→F10.
- **Localization note:** deck ships US-English only (matches live Play listing). If/when
  localizing: two-line headlines are tight — German/French run ~30% longer; re-run the
  auto-size length check + squint test per locale before export.
- **Green accent LOCKED** (default on load); orange toggle retained only as the future
  Play Listing Experiment challenger.
- **Copy A/B variants queued (Play Listing Experiments, one at a time):**
  F2 question: "Marathon and gym?" (shipped) vs "Lifting and running?" vs "Two sports at once?".
  F6 headline: "Hate logging? / Just tell your coach." (shipped) vs "Ask anything? / Ask your coach.".
  F1 hero coach-message: current recovery message vs a workout/meal message (needs re-capture w/
  different Daily Focus state) — headline stays "One coach. / Lifts, meals, recovery."
- **Sequencing A/B to run post-launch:** current order (coach → programs → nutrition →
  customize → workout → chat → form → PROOF → imports) vs moving F8 proof frame to slot 3-4.
  One element per experiment, 7+ days, ~25K impressions/variant.

---

## ✍️ Copy-driven capture fixes (2026-07-02 review)

- ✅ **"Savage Beast Annihilation" renamed in the DB** (2026-07-02): Jul 3 workout →
  "Upper Body Power", Jul 4 → "Full-Body Conditioning" (saipy252@gmail.com). Long-term fix
  shipped: naming prompts + the algorithmic namer's hard/hell word pools rewritten to
  credible coach-speak (backend uncommitted). **Re-shoot the F2 schedule** — the old name
  is still baked into the current capture's pixels.
- F1 headline is now "One coach. / Lifts, meals, recovery." — matches the rest-coaching
  hero card, so NO coach-card re-stage needed. If a future re-shoot lands a workout/meal
  coach message instead, the alternate headline is "One coach. / Trains and feeds you."
- Credibility stats (4.8★ / 2M workouts / 500k athletes) are NOT yet real — do not add
  until true. The 1,700+ exercises pill is the only verified stat.

---

## 🎨 v2 design decisions (affect tomorrow's captures)

- **Mockups now ZOOM-CROP hero UI elements** out of each capture (protein/kcal deck, session cards, TOP PICK card, day picker, 55×12 set counter). Those elements get magnified 2–3×, so they must be **clean and fully rendered** in the capture — no truncation, no placeholder values.
- **F6 chat:** the macro card from the tacos message is the zoom-crop hero — make sure it renders fully.
- **F7 form check:** the score + first 2 critique lines are the zoom-crop hero.
- **F8 Overload Dashboard** is the deck's closing PROOF frame — real numbers, upward 1RM chart, PR badge all visible. This converts hardest in fitness ASO.
- **Optional stretch:** a lifestyle "device in hand" photo for the F1 hero (adds a human moment before pure-UI frames) — any clean shot of holding the phone with the app home screen on, good light.
- **F2 re-shoot reminder:** with 2–3 active programs, the two stacked session-card crops will show DIFFERENT program badges — that's what proves "RUN SEVERAL".
