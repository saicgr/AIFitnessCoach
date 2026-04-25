# FitWiz — Play Store Listing Copy (Default — English US)

Last updated: 2026-04-25.
Paste each block into the matching field in **Play Console → All apps →
FitWiz → Grow → Store presence → Main store listing → Default store
listing**.

> Em-dash policy: every long dash below is `—` (U+2014). Number ranges
> use `–` (U+2013, en dash). Don't auto-correct to `--` or `-` —
> Google's metadata bot rejects both.

---

## App name (max 30, currently 28)

```
FitWiz: Workout & Meal Coach
```

---

## Short description (max 80, currently 72)

```
AI coach that builds your workouts & tracks meals — type, snap, or scan.
```

---

## Full description (max 4 000, currently ~3 970 after REQUIREMENTS trim)

```
Your workouts and diet finally talk to each other.

FitWiz connects your training and nutrition into one AI-powered plan. It knows what you ate, how you trained, and adjusts both to keep you on track. No more juggling a workout app and a separate food tracker. Start with a 7-day free trial — $49.99/year (about $4.17/month).

HOW IT WORKS
Tell FitWiz your goal — lose weight, build muscle, train for an event, or just feel better. It builds your workout program, sets daily nutrition targets, and updates both as you log sets and meals. As you train and eat, it learns your preferences and adapts. That's it.

WORKOUTS BUILT FOR YOU
Every workout is generated around your equipment, fitness level, and weekly schedule. Not a template — a plan that's actually yours.
• Adapts around injuries automatically — sub any movement in one tap
• Auto-progression: weights, reps, and rest adjust based on what you logged last time
• Warm-ups and cool-downs included for every session
• Quick sessions (5–15 min) for busy days
• Multiple gym profiles for home, work, hotel, or travel
• Bodyweight-only mode if you have zero equipment
• AI explains why each exercise was chosen for you

LOG MEALS YOUR WAY
However is fastest for you in the moment:
• Type it — "2 eggs, toast, coffee" and it's logged in seconds
• Snap it — take a photo of your plate and AI identifies the food
• Scan it — barcode scanner for packaged foods
• Paste it — drop in a menu screenshot and FitWiz parses calories and macros
Calories, protein, carbs, fats, fiber, and 20+ micronutrients tracked automatically. Every meal gets a health score with personalized tips from your coach.

RECIPES AND BATCH COOKING
A growing library of high-protein, easy-prep recipes. Cook once on Sunday, log portions through the week — FitWiz tracks how many servings are left and reminds you before they expire.

FORM CHECK
Record a quick video of your set, send it in chat, and get scored cues you can fix on the next rep. Built-in coaching for the lifts that matter most.

YOUR COACH, ANYTIME
Ask anything. "Can I replace squats — my knee hurts?" "How much protein have I had today?" "What should I eat before my workout?" "I missed yesterday, reshuffle my week." Your AI coach knows your full workout history, your nutrition, your injuries, and your goals. It gives answers that actually apply to you — not generic advice from a blog.

TRACK YOUR PROGRESS
• Workout streaks and personal records
• Weight and body composition trends
• Progress photos from multiple angles, side-by-side comparisons
• Weekly performance summaries
• Monthly Wrapped recap of your training story
• Health Connect sync (steps, heart rate, sleep, calories burned)

EXERCISE PREFERENCES
FitWiz learns what you love. Mark your favorite exercises, avoid the ones you hate, and queue up moves you want to try. Your workouts get smarter over time.

PRIVACY AND YOUR DATA
Your health data stays yours. Delete your account and export everything in two taps. We never sell your data, never share it with advertisers, and never use it to train third-party AI. Account-level encryption at rest, transit-level encryption everywhere else.

WHO IT'S FOR
Lifters who want their nutrition to actually match their training. Beginners who want a real plan instead of YouTube playlists. Busy people who don't have time to design programs. Anyone who's tired of switching between five apps.

DETAILS
• Works with any equipment setup, including bodyweight only
• Nutrition targets that adjust to your goals
• XP, trophies, streaks, and monthly achievements to keep you motivated
• Water intake tracking with daily reminders
• Dark mode
• Personalized warm-up and cool-down routines

NOT MEDICAL ADVICE
FitWiz provides fitness and nutrition guidance, not medical advice. Talk to your doctor before starting any new program, especially if you have an existing condition or injury.

One app for training and nutrition. No guesswork. Start your 7-day free trial today.
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
| Contact email | `support@fitwiz.us` |
| Website | `https://fitwiz.us` |
| Privacy policy | `https://fitwiz.us/privacy` |

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
- [ ] Pricing matches in-app paywall ($49.99/yr default per `paywall_pricing_screen.dart`)
- [ ] Every feature claimed is actually shipping in the AAB you'll upload (Wrapped, Form Check, Health Connect sync, batch-cook portions, screenshot parsing)
- [ ] Privacy policy URL `https://fitwiz.us/privacy` returns 200 directly, NOT a 307 redirect to vercel.app (see `PRE_REVIEW_SUBMISSION_GUIDE.md` § Vercel canonical domain fix)
- [ ] No `fitwiz.app` strings anywhere in the listing or screenshots
