# Zealova — Play Store Listing Copy (Default — English US)

Last updated: 2026-05-18.
Paste each block into the matching field in **Play Console → All apps →
Zealova → Grow → Store presence → Main store listing → Default store
listing**.

> Em-dash policy: every long dash below is `—` (U+2014). Number ranges
> use `–` (U+2013, en dash). Don't auto-correct to `--` or `-` —
> Google's metadata bot rejects both.

---

## App name (max 30, currently 28)

```
Zealova: Workout & Meal Coach
```

---

## Short description (max 80, currently 67)

```
AI coach for workouts, meals & fasting — type, snap, scan, or fast.
```

---

## Full description (max 4 000, currently 3 833)

```
Your workouts, meals, and fasts — finally in one place.

Zealova connects training, nutrition, and fasting into one AI-powered plan. It knows what you ate, how you trained, how long you fasted, and adjusts everything to keep you on track. No more juggling separate apps. Start with a 7-day free trial — $7.99/mo or $59.99/yr (save 37%).

HOW IT WORKS
Tell Zealova your goal — lose weight, build muscle, or just feel better. It builds your workout program, sets nutrition targets, picks a fasting schedule that fits your life, and updates everything as you log sets, meals, and fasts. It learns and adapts as you go.

WORKOUTS BUILT FOR YOU
Every workout is generated for your equipment, fitness level, and schedule — not a template.
• Adapts around injuries — sub any movement in one tap
• Auto-progression: weights, reps, and rest adjust from what you logged last time
• Warm-ups and cool-downs for every session
• Quick sessions (5–15 min) for busy days
• Multiple gym profiles: home, work, hotel, travel
• Bodyweight-only mode with zero equipment

LOG MEALS YOUR WAY
• Type it — "2 eggs, toast, coffee" logged in seconds
• Snap it — photo of your plate; AI identifies food, estimates portions, logs calories + macros
• Scan it — barcode scanner for packaged foods
• Paste it — restaurant menu screenshot; Zealova parses calories and macros per dish
Calories, protein, carbs, fats, fiber, and 20+ micronutrients tracked automatically.

INTERMITTENT FASTING
A full fasting tracker — not just a countdown clock.
• Protocols: 14:10, 16:8, 18:6, 20:4, OMAD, 5:2, ADF, extended fasts, or a custom per-weekday schedule
• Live metabolic-stage ring: Fed → Blood Sugar Drop → Fat Burning → Ketosis → Autophagy → Deep Autophagy, with calculated times based on your last meal
• Body Status stage-journey view so you always know where you are in the fast
• Hydration logging and mood/energy check-ins during the fast window
• Pause and resume any fast — never lose your progress
• iOS Live Activity + Android ongoing notification with controls
• Built-in Fasting Guide: what happens inside your body from 0 hours to 30 days

TRENDS AND CORRELATIONS
Stop guessing what's driving your results.
• Chart 100+ metrics — weight, measurements, all macros and micronutrients, calories, water, steps, sleep, mood, energy, glucose, fasting hours, workout volume, strength numbers, and more
• Overlay any two metrics on one chart and see the correlation between them
• AI-generated trend insights surface patterns you'd miss in a data table
• Event overlays mark workout days, fasting windows, and cycle phases

YOUR COACH, ANYTIME
Ask anything. "Can I replace squats — my knee hurts?" "How much protein today?" "What should I eat after a 16-hour fast?" "I missed yesterday, reshuffle my week." Your AI coach knows your full history — workouts, nutrition, active fast, injuries, goals — and gives answers that apply to you, not generic blog advice.

RECIPES AND BATCH COOKING
A growing library of high-protein, easy-prep recipes. Cook once, log portions through the week — Zealova tracks servings remaining and reminds you before they expire.

TRACK YOUR PROGRESS
• Personal records and workout streaks
• Weight, measurements, and composition trends
• Progress photos with side-by-side comparisons
• Weekly summaries and Monthly Wrapped recap
• Health Connect sync (steps, heart rate, sleep, calories burned)

PRIVACY AND YOUR DATA
Your health data stays yours. Delete your account and export everything in two taps. We never sell your data or share it with advertisers.

NOT MEDICAL ADVICE
Zealova provides fitness and nutrition guidance, not medical advice. Talk to your doctor before starting any new program, especially if you have an existing condition.

One app for training, nutrition, and fasting. No guesswork. Start your 7-day free trial today.
```

---

## Other Main store listing fields (verify each)

| Field | Value |
|---|---|
| App icon | 512×512 PNG, 32-bit, no alpha — use the icon from `mobile/flutter/assets/icons/` |
| Feature graphic | 1024×500 PNG/JPG — must NOT contain key screenshot text or device frames |
| Phone screenshots | 4–8 screenshots, min 320 px, max 3840 px, 16:9 or 9:16, lead with workout + meal in same shot |
| 7-inch tablet screenshots | Optional but recommended (helps with tablet category) |
| 10-inch tablet screenshots | Optional |
| App category | Health & Fitness |
| Tags | Strength training, Nutrition, Personal trainer, Workout planner, Calorie counter |
| Contact email | `support@zealova.com` |
| Website | `https://zealova.com` |
| Privacy policy | `https://zealova.com/privacy` |

---

## What NOT to do (Play metadata gotchas)

- ❌ Words `free`, `sale`, `top`, `best`, `#1`, `new`, `exclusive` in **App name**
- ❌ Emoji or `™ ® ©` symbols in **App name** or **Short description**
- ❌ ALL CAPS sentences (one-word emphasis OK; full sentences in caps trigger spam flag)
- ❌ Repeating the same keyword 5+ times in **Full description**
- ❌ References to Apple, Google, or competitor brands ("works like Apple Fitness+")
- ❌ Medical claims (`treats`, `cures`, `diagnoses`)
- ❌ Hyphens (`-`) or double hyphens (`--`) where an em dash (`—`) belongs

The copy above is clean on all of these.

---

## Pre-save checks

- [ ] All `--` are `—` and all between-word `-` between full words is `—`
- [ ] Pricing matches in-app paywall ($59.99/yr, confirmed live on Play Store 2026-05-14)
- [ ] Every feature claimed is actually shipping in the AAB you'll upload (Wrapped, Form Check, Health Connect sync, batch-cook portions, screenshot parsing)
- [ ] Privacy policy URL `https://zealova.com/privacy` returns 200 directly, NOT a 307 redirect to vercel.app (see `PRE_REVIEW_SUBMISSION_GUIDE.md` § Vercel canonical domain fix)
- [ ] No `fitwiz.app` strings anywhere in the listing or screenshots
