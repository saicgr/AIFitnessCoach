# Zealova content-angle catalog

The content brain's source of truth. Every marketable feature → ready-to-use
hooks → best format → screenshot. `/social-today` and the `social-content` agent
pull from here so posts span the WHOLE app, not the same 6 things.

- **Format:** `C` = carousel (ranked lists, comparisons, "here's how it works"),
  `R` = reel (one hook + a fast demo/payoff), `either` = works both ways.
- **Carousel MODES** (the "shape" — the agent picks per topic; slide types in
  `frontend/scripts/instagram/lib/slides.mjs`): **Reveal** (score ring), **Comparison**
  (head-to-head), **Insight** (the AI caught something), **Timeline** (fasting clock /
  phases), **Radar** (fitness axes), **Cards** (programs / tier lists), **Before/After**,
  **Consistency** (heatmap), **Stat/Explainer**. Through-line: *everything gets a score,
  and we reveal it — food AND training.*
- **📸** = screenshot key in `screenshots/manifest.json`; `⚠capture` = needs a shot.
- **Tone:** honest, useful, curiosity-driven. Never fear-mongering, never a claim
  we can't defend. No em-dashes/scare-quotes/ad-speak (`_OUTPUT_STANDARD.md`).

The app's real scope: **~1,400 workout programs**, a **12-dial customization
studio**, AI form check, menu/fridge scanning with inflammation scores, a
**7-stage fasting clock**, a full **wearable-score suite**, body analyzer,
cycle-aware coaching, NEAT, habit heatmaps, plateau detection, and deep
gamification. That's years of content.

---

## 1. Programs — the 1,400-program universe (deepest vein)

The program NAMES are the hooks. "There's a program for your exact life" is the
meta-angle.

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "There's a workout for your exact life: night-shift nurse, cruise vacation, apartment with thin walls, new dad." | C | schedule-programs ⚠capture: program-library | Screenshot the library grid |
| "I trained like Henry Cavill's Superman for a week. Here's the actual split." | R | ⚠capture: celebrity-program-detail | Celebrity vein: Thor, The Rock, Black Widow, Wolverine, Hrithik |
| "Gen-Z program names ranked: 'Delulu is the Solulu', 'Touch Grass Training', 'Ate and Left No Crumbs'." | C | ⚠capture: program-library | Pure curiosity/share bait |
| "'Don't Wake the Neighbors' — a whole quiet-apartment workout line (Whisper Workout, Tippy-Toe Gains, 2AM Club)." | either | ⚠capture | Ninja-mode line; very relatable |
| "Hell Mode: Prison Yard, 300 Workout, Death by Burpees, 1000-Rep Day. Would you survive?" | R | ⚠capture | hell_mode line |
| "Face/jaw workouts are real: Mewing, Jawline Definition, Gua Sha Flow, Face Yoga." | C | ⚠capture | face_jaw line — high curiosity, honest |
| "Peach Builder, Hip Thrust Specialization, 30-Day Glute Challenge — the glute program shelf." | either | ⚠capture | glute_building line |
| "Viral workouts, actually programmed: 12-3-30, Wall Pilates, 75 Hard, Hot Girl Walk, Cozy Cardio." | C | ⚠capture | viral line |
| "You can run MULTIPLE programs at once — stack a glute program ON TOP of your strength plan." | either | schedule-programs | Primary + Extra slots, Week X of Y |
| "Paste any Reddit PPL routine as text → it becomes an editable app program." | R | ⚠capture: program-template-builder | Build-your-own; Paste-my-program |
| "Tap any program and see all 12 weeks BEFORE you commit — it even shows which exercises it'll swap for your gym." | C | ⚠capture: program-detail | Program detail = phase/focus/equipment-match |
| "Couch to 5K → Marathon → Ironman: the endurance ladder in one app." | C | ⚠capture | Sport line (39 programs) |
| "Programs for real medical needs: PCOS, menopause, diabetes, lower-back pain, postpartum by phase." | C | ⚠capture | Women's/men's health, pain mgmt — handle sensitively |

## 2. Customization studio — 12 dials, live preview

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "One workout, 12 dials: I turned a 45-min session into a 20-min quiet-apartment version in 3 taps." | R | customize-program ⚠capture: customization-studio | Duration/warmup/cooldown/intensity/style/muscles/equipment/impact |
| "Tell it what's SORE today and it reroutes the entire workout around it." | R | ⚠capture: customization-studio-bodymap | Body-map sore selector |
| "Set Monday to 'Hell 🔥 legs', leave the rest on 'AI decide'." | either | customize-perday-focus | Per-day focus + intensity Easy/Moderate/Hard/Hell |
| "8 training splits — Full Body, PPL, PHUL, Arnold, HYROX, Bro — or let AI pick your split." | C | customize-perday-focus ⚠capture: split-picker | Vibe/split picker |
| "Swap Tuesday with Friday, copy one day's setup to the rest. Your schedule bends to your life." | R | customize-program | Swap day / copy day |
| "Your gym's 'dumbbells' aren't the labeled weight — calibrate real weights for accurate plate math." | R | ⚠capture: equipment-calibration | Niche but nerdy-credible |
| "AMRAP finisher, supersets, active recovery, 'prioritize my staples' — toggles that change the whole session." | C | ⚠capture: customization-studio | |

## 3. AI workout + coach (the moat)

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "Answered 6 questions, AI built my whole plan in seconds. Watch it generate." | R | home-coach-nudge ⚠capture: plan-reveal | Onboarding reveal is a payoff |
| "The coach moved my leg day after a bad night's sleep. Here's the reasoning it gave." | R | home-recovery, coach-chat | Health-aware adaptation |
| "I logged 'two tacos and a Corona' in the chat — watch the coach react." | R | coach-chat | Voice + text coach |
| "Guided set-by-set: it tells me the target weight and next exercise mid-workout." | R | active-workout-set | |
| "Ask the coach anything mid-set without leaving the workout." | either | active-workout-set | |

## 4. Menu / food / fridge scan (flagship exposé)

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "Two dishes, same menu — one scores 82, one scores 24. Scan before you order." | C | menu-scan-result | The proven format |
| "Point your camera at a menu → every dish ranked by macros + inflammation in 3s." | R | menu-scan-result | |
| "Scanned my fridge → it found 5 meals I could make right now." | R | fridge-scan | |
| "'Clean' pantry snacks: 3 that failed the scan." | C | fridge-scan, menu-scan-result | |
| "Your protein bar vs a candy bar — the scan surprises people." | C | ⚠capture: product-scan | |
| "Airport food, ranked: the 5 least-bad terminal meals." | C | menu-scan-result | |

## 5. Form check

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "The app scored my push-up an 80 — here's the 20 it docked (Form/Tempo/Range)." | R | form-check-pushup | |
| "5 push-up mistakes quietly killing your gains (with the fix)." | C | form-check-pushup | |
| "Squat depth: what the camera sees that your mirror doesn't." | either | ⚠capture: form-check-squat | |

## 6. Strength & fitness scores

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "What a 'strength score' actually measures — and how to raise it." | C | strength-score | |
| "Stronger than 49% of comparable lifters. The number that keeps me showing up." | R | strength-score | |
| "My fitness radar vs people my age: body comp, cardio, strength, endurance, flexibility." | C | ⚠capture: fitness-index-radar | 5-axis radar + percentile |
| "See your percentile vs everyone Near You." | R | ⚠capture: discover-percentile | Discover screen |

## 7. Progress & body

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "I uploaded 4 photos → AI estimated my body-fat %, muscle %, symmetry AND flagged my posture." | R | ⚠capture: body-analyzer-result | Strong payoff screen |
| "Drag the slider on my 90-day before/after." | R | ⚠capture: before-after | Classic viral shot |
| "It proved my bench plateaus every week I sleep under 6 hours." | C | ⚠capture: training-journal | Journal correlations |
| "It caught my bench plateau before I did — and told me why." | R | ⚠capture: plateau-dashboard | |
| "Track how workouts change your MOOD and energy, not just your body." | C | ⚠capture: feel-results | Feel Results trends |
| "Log 12 body measurements and see them on a body map." | either | ⚠capture: measurements | |

## 8. Health / wearables (whole score suite)

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "One number for your heart health, built from sleep + activity + resting HR + body comp." | R | ⚠capture: heart-health-gauge | Animated 360° gauge |
| "It tells you if today's a PUSH day or a RECOVER day (readiness score)." | either | ⚠capture: readiness-card | |
| "It warned me I was overtraining 3 days before I felt it." | R | ⚠capture: strain-recovery-mismatch | |
| "It estimates my VO2max from my runs and predicts my 5K/10K/half time." | either | ⚠capture: race-predictor | |
| "5 overnight vitals — resting HR, HRV, respiratory rate, blood O2, skin temp — scored vs your baseline." | C | ⚠capture: vitals-detail | |
| "My body battery hit 12% — no wonder I bailed on leg day." | R | ⚠capture: body-battery | |

## 9. Fasting

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "It tells you the exact clock time you hit ketosis tonight." | R | ⚠capture: fasting-body-status | 7-stage clock journey |
| "Hour-by-hour: what actually happens in a 16:8 fast (Fed → Ketosis → Autophagy)." | C | ⚠capture: fasting-body-status | |
| "Best workout to do fasted, by fasting hour." | C | ⚠capture: fasting-impact | Fasted-training advice |

## 10. Wellness (cycle / NEAT / habits / pelvic / mindfulness)

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "A period-aware AI coach that adjusts training to your cycle phase." | either | ⚠capture: cycle-screen | Handle warmly |
| "The calories you burn WITHOUT working out — and how to raise your NEAT score." | C | ⚠capture: neat-dashboard | |
| "GitHub-style yearly heatmap for your habits." | R | ⚠capture: habits-heatmap | Very shareable |
| "A guided pelvic-floor trainer with a timer — yes, for men too." | either | ⚠capture: kegel-session | Surprising, honest |
| "60-second breathing timer that counts toward your daily rings." | R | ⚠capture: mindfulness | |
| "Log an injury and every future workout auto-adapts around it." | R | ⚠capture: report-injury | |

## 11. Gamification

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "Hit a milestone level and they ship you REAL merch." | R | ⚠capture: merch-claims | Strong hook |
| "There's loot: XP tokens, streak shields, fitness crates." | either | ⚠capture: inventory | |
| "It auto-freezes your streak when life happens — no manual equip." | R | ⚠capture: streak-freeze | |
| "137 trophies to earn — hunting the rarest one." | C | ⚠capture: trophy-room | |
| "Skill tree for calisthenics — unlock the muscle-up path." | either | ⚠capture: skill-progressions | |
| "1v1 workout battle with a friend — who won each exercise?" | R | ⚠capture: challenge-compare | |

## 12. Gym / travel / equipment

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "One tap turns your program into a hotel-room version — then switches back home." | R | ⚠capture: travel-mode | |
| "It knows what equipment your local gym has — crowd-sourced, confirmed by other members." | R | ⚠capture: find-gyms | |
| "Home vs gym? Save both equipment profiles and switch instantly." | either | ⚠capture: gym-switcher | |
| "Can't do a full push-up? Here's the 6-step progression it gives you." | C | ⚠capture: exercise-progressions | |

## 13. Social / accountability

| Angle / hook | Fmt | 📸 | Notes |
|---|---|---|---|
| "Add friends and compare strength scores on the leaderboard." | either | ⚠capture: leaderboard | |
| "Steal your friend's exact workout with one tap." | R | ⚠capture: shared-workout | |
| "Users vote on what we build next." | either | ⚠capture: feature-voting | Build-trust angle |

---

## Capture priority (unlocks the most content)

Most `⚠capture` shots above are worth one Simulator session. Highest-leverage
first: **program-library grid**, **program-detail (12 weeks)**, **customization-studio**,
**body-analyzer-result**, **fasting-body-status**, **heart-health-gauge**,
**fitness-index-radar**, **habits-heatmap**, **before-after**, **plateau/journal**,
**travel-mode**, **merch-claims**. Add them to `screenshots/manifest.json` as you go.
