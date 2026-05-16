# Zealova Play Store Screenshots Guide

## Setup
- **Tool**: [theapplaunchpad.com](https://theapplaunchpad.com)
- **Play Store size**: 1080x1920px (portrait, 9:16), PNG/JPEG, max 8 MB
- **App Store size**: 1320x2868px (6.9" iPhone 16 Pro Max — 2026 required), PNG/JPEG, no alpha, 72 DPI
- **Counts**: Play allows **8 phone screenshots max** per Console docs (some apps like Mob ship 14 via API/custom listings — try uploading >8 in Console; if it caps you, use the 8 below). App Store allows **up to 10**.
- **Template style**: Mob-inspired — cream/off-white background, single phone tilted, prop objects bleeding off the edges, caption stacked top with one accent word
- **App mode**: Dark mode ON for in-phone screen capture; light cream backgrounds for the frame around the phone

---

## ASO Research Notes (2026)

These rules drive the deck below. Sources: [Apptweak](https://www.apptweak.com/en/aso-blog/how-to-optimize-your-app-screenshots), [ASO Mobile](https://asomobile.net/en/blog/screenshots-for-app-store-and-google-play-in-2025-a-complete-guide/), [AppScreenshotStudio](https://medium.com/@AppScreenshotStudio/app-store-screenshots-that-convert-the-2026-design-guide-4438994689d6), [Sensor Tower](https://sensortower.com/blog/top-10-health-and-fitness-apps-what-their-screenshots-teach-us-about-optimization), [SnapMonk](https://www.snapmonk.com/screenshot-templates/fitness), [Promodo](https://www.promodo.com/blog/aso-trends), [SplitMetrics](https://splitmetrics.com/blog/master-the-official-splitmetrics-a-b-testing-validation-framework-to-win-on-the-app-store/).

- **~90% of users don't scroll past frame 3** — first 3 frames must each stand alone as install reasons.
- **Main caption: 2-6 words** — longer becomes an unread text block at thumbnail.
- **Sub-caption: 8-12 words** with concrete details (numbers, timeframes, specific use cases).
- **Apple OCRs caption text into search keyword index** — captions need keyword density.
- **Outcome > feature**: *"Never forget a deadline again"* beats *"Advanced Task Management"*.
- **Specific numbers convert** — *"1,700+ exercises"* beats *"Tons of exercises"*.
- **Time-bounded outcomes work** — *"7-day yoga challenge starts today"* got +12% conversion.
- **Social proof on frame 1 → up to +90% conversion** (rating, install count, media logos, "as seen in").
- **Top-left of each frame** is where the eye lands first.
- **High-contrast text** Apple OCR can read.
- **Plain honest captions** outperform marketing speak.
- **Video preview** especially strong for fitness — first 3 sec must show value, not animated logo.

---

## The 8 Frames

| # | Main caption (orange in **bold**) | Sub-caption | Screen | Chars |
|---|---|---|---|---|
| 1 | Your fitness coach in **chat.** | *1,700+ exercises. Workouts + macros. Adapts to you.* | Home dashboard + props (dumbbell, meal bowl) — single phone, brand composition, capability pill top-left | 27 |
| 2 | Always know **what to lift** next | *Adapts to your last session, every time* | Exercise detail (Bench Press) — warmup sets + effective sets w/ green/blue progression bars + Start Workout button | 29 |
| 3 | Menu picks. **Fridge recipes.** | *Scored, ranked, logged — in seconds.* | 2-mockup composite — menu scan w/ TOP PICK badge + scores (left) + fridge scan w/ recipe suggestions (right) | 28 |
| 4 | Don't feel like it? **Swap it.** | *Coach swaps any exercise — by chat* | Chat: user *"swap deadlifts for trap bar"* → coach reply with updated workout card inline | 27 |
| 5 | Just **say what you ate.** | *Or what you trained — yoga, runs, anything* | Chat showing voice log of meal + yoga + cardio | 22 |
| 6 | Watch your **strength climb** | *Every PR, charted automatically* | Progress dashboard — heatmap, 1RM line chart, recent PR callout, streak counter | 25 |
| 7 | Photos & pounds, **side by side** | *See the change you can't feel* | Body tracking — weight trend line + before/after photo split-screen | 30 |
| 8 | Brag worthy. **Built-in.** | *15 ways to share your wins — Wrapped, receipt, trading card, more* | Shareable gallery — grid of 15+ viral format thumbnails | 22 |

---

## Story arc

```
1. WHAT IT IS (fitness coach in chat) →
2. WORKOUT INTELLIGENCE (knows what you should lift) →
3. NUTRITION INTELLIGENCE (picks + recipes from scans) →
4. WORKOUT FLEXIBILITY (chat-swap any exercise) →
5. MULTI-INPUT (voice log meals + yoga) →
6. WORKOUT PAYOFF (strength climbs) →
7. BODY PAYOFF (photos + pounds) →
8. SHARE/RETENTION (brag worthy)
```

Frame 1 = setup. Frames 2-5 = unfair advantages spread across workout (2, 4) and nutrition (3, 5). Frames 6-7 = payoffs. Frame 8 = retention/viral.

**Top 3 carry ~90% of the install decision** — each must stand alone as an install reason:
- Frame 1: chat-coach claim establishes category positioning
- Frame 2: exercise intelligence (proof on workout side)
- Frame 3: menu picks + fridge recipes (proof on nutrition side, output > input)

---

## Frame-by-Frame Capture Details

### Frame 1 — Brand Hero + Capability Pill (Mob-style)

**Main caption** (stacked top, last word oversized + orange):
```
Your fitness
coach in chat.    ← "chat" 1.5× size, brand green
```

**Sub-caption** (smaller, below main):
*1,700+ exercises. Workouts + macros. Adapts to you.*

**Capability pill** (top-left corner, small pill, brand green on cream):
```
1,700+ exercises · Workouts + macros · Adapts to you
```

This pre-launch pill substitutes for social proof. **Swap to real social proof badge as soon as you have it** — see Post-Launch Badge Progression below.

**What to capture (in-phone screen)**: Home dashboard — clean state, today's workout card visible, no error banners, no debug overlays.

**Frame composition**:
- Phone tilted ~12° clockwise, centered slightly low
- Bottom-left: half a meal bowl (oats + berries) bleeding off
- Bottom-right: dumbbell head bleeding off
- Top-right: optional sprig of herbs or water glass
- Top-left: the capability pill (do not bury it — eye lands top-left first)

---

### Frame 2 — Workout Intelligence (Progressive Overload Bars)

**Main caption**: `Always know what to lift next`
**Sub-caption**: *Adapts to your last session, every time*
**Background**: Soft sky `#D6E9F5`

**What to capture**: Exercise detail screen (Barbell Bench Press) showing:
- Warmup sets table (e.g. Set 1: 10 reps @ 20 kg, Set 2: 5 reps @ 37.5 kg)
- Effective sets table with green/blue progression bars (green = matched last session, blue = PR target)
- Start Workout button visible at bottom
- Clean state — no notes, no errors

**How to get this state**: Open today's workout → tap any exercise (must have prior bench sessions logged so progression bars have data) → screenshot the detail view.

**Pre-condition**: At least 2 prior bench sessions logged so progression bars render meaningfully.

---

### Frame 3 — Nutrition Intelligence (Menu Picks + Fridge Recipes)

**Main caption**: `Menu picks. Fridge recipes.`
**Sub-caption**: *Scored, ranked, logged — in seconds.*
**Background**: Warm peach `#FBE2C8`

**What to capture**: 2-mockup composite (composited in launchpad tool):

**Left mini phone — Menu scan result**:
- Restaurant menu photo at top (small)
- Parsed dish list below with health scores (e.g. "85", "72", "55")
- "TOP PICK" badge on the highest-scoring item
- Per-item cal + protein
- "Best macro fit" subtext on the top pick

**Right mini phone — Fridge scan result**:
- Fridge photo at top (small)
- Detected ingredients chips ("chicken breast", "broccoli", "rice", "eggs")
- 3 recipe cards below: "Chicken Stir-Fry · 32g protein · 25 min", "Veggie Bowl · 18g protein · 15 min", "Egg Scramble · 24g protein · 10 min"

**Why two phones, not three**: Showing OUTPUT (picks/recipes) is more compelling than input (camera viewfinder). Two clean output screens > three small ones.

---

### Frame 4 — Chat-Modify Workouts

**Main caption**: `Don't feel like it? Swap it.`
**Sub-caption**: *Coach swaps any exercise — by chat*
**Background**: Soft pink `#F4D5DA`

**What to capture**: Coach chat screen showing:
- User message: *"swap deadlifts for trap bar deadlifts"*
- Coach reply: confirmation message + updated workout card preview inline ("Tomorrow's workout: Trap bar deadlifts 4×5, …")
- Quick-action pills visible at bottom
- Coach avatar visible

**How to get this state**: Open chat with coach → request an exercise swap on a real generated workout → wait for the coach to confirm + display the updated plan card → screenshot.

---

### Frame 5 — Voice/Chat Multi-Input Logging

**Main caption**: `Just say what you ate.`
**Sub-caption**: *Or what you trained — yoga, runs, anything*
**Background**: Soft green `#D4ECD7`

**What to capture**: Coach chat screen showing 3 stacked example messages:
1. *"two slices of pizza and a coke"* → parsed macro card reply
2. *"did 30 min yoga at home"* → ✓ workout logged confirmation
3. *"30 min run, easy pace"* → ✓ cardio logged confirmation

This frame proves the chat coach handles meals AND non-strength workouts (yoga, runs) which is uniquely Zealova — Strong/Hevy/Fitbod can't log yoga via chat.

**How to get this state**: Send each test message in sequence in a clean chat thread → screenshot the resulting chat with all 3 exchanges visible.

---

### Frame 6 — Workout Payoff (Progress Dashboard)

**Main caption**: `Watch your strength climb`
**Sub-caption**: *Every PR, charted automatically*
**Background**: Steel blue `#2563EB`

**What to capture**: Progress dashboard with:
- GitHub-style activity heatmap (green squares filling)
- 1RM line chart trending upward
- Recent PR callout ("+15 lbs Bench")
- Streak counter (current streak prominent)

**Pre-condition**: 20+ workouts logged for a good-looking heatmap; at least one PR detected.

---

### Frame 7 — Body Payoff (Photos + Pounds)

**Main caption**: `Photos & pounds, side by side`
**Sub-caption**: *See the change you can't feel*
**Background**: Lavender purple `#B39DDB`

**What to capture**: Body tracking screen with:
- Weight trend line chart at top (real downward or upward trend)
- Before/after photo comparison below — split-screen with week labels (e.g. "Week 1" left, "Week 12" right)
- Visible composition change

**Pre-condition**: Weight entries + 2 progress photos at different timepoints.

---

### Frame 8 — Share/Retention (Shareable Gallery)

**Main caption**: `Brag worthy. Built-in.`
**Sub-caption**: *15 ways to share your wins — Wrapped, receipt, trading card, more*
**Background**: Muted gold `#B45309`

**What to capture**: Shareable gallery view with grid of 15+ format thumbnails:
- Wrapped card (center, largest if hierarchy)
- Receipt format
- Trading card format
- Newspaper format
- X.com card
- IG story
- Polaroid
- Stat sheet
- (etc — all 15+ visible in grid layout)

**How to get this state**: Navigate to share gallery from any logged workout → screenshot the full gallery view.

---

## Post-Launch Badge Progression (Frame 1)

The capability pill on frame 1 is a pre-launch placeholder. Swap it for real social proof as soon as you have data — research shows up to **+90% conversion** lift from frame 1 social proof.

| Stage | Top-left badge on frame 1 | When to switch |
|---|---|---|
| **Pre-launch (now)** | `1,700+ exercises · Workouts + macros · Adapts to you` | Ship state |
| **First 50 reviews** | `★ 4.7 · Trusted by early users` | Around Week 2-4 post-launch |
| **500+ reviews** | `★ 4.7 · 500+ five-star reviews` | Once you cross 500 |
| **5k+ installs** | `★ 4.7 · 10,000+ workouts logged this month` | Once active usage hits |
| **Press hits** | `As seen in: Product Hunt · TechCrunch` | After PR coverage |
| **Combined (peak)** | `★ 4.7 · 10,000+ users · Featured in TechCrunch` | Stack what's most credible |

Update the pill in `theapplaunchpad.com` and re-export frame 1 each time you cross a threshold. No need to redo other frames.

---

## Bottom-Testimonial Slots (Frames 2, 3, 6)

Once you have real reviews, add ★★★★★ + a short testimonial below the phone on the **install-decision frames**. Frame 1 = badge (broad trust). Frames 2/3/6 = testimonials (deepen trust on specific features).

| Frame | Testimonial slot pattern (post-launch only) |
|---|---|
| **2** (what to lift) | ★★★★★ *"Finally know what to lift each session"* — @username |
| **3** (menu picks) | ★★★★★ *"Used it at 4 restaurants this week"* — @username |
| **6** (strength climb) | ★★★★★ *"Up 25 lbs on bench in 8 weeks"* — @username |

**Pre-launch**: leave the bottom area blank. Do NOT use fake testimonials — Apple/Play can reject for fabricated social proof.

---

## Extended Deck (Slots 9-12)

For when Play Console accepts >8 (Mob ships 14 via API/custom listings — try uploading more in Console as a stretch), or for App Store's 10 slots:

| # | Main caption (orange in **bold**) | Sub-caption | Screen |
|---|---|---|---|
| 9 | **Import any recipe**, batch cook | *Paste any URL — IG, blog, TikTok. Cook once, eat 4 days.* | Recipe import sheet showing parsed recipe + batch-cook plan card |
| 10 | Hit your macros **without thinking** | *Macros, vitamins, water — auto-tracked from your logs* | Fuel tab — macros ring + micro pills + water glasses |
| 11 | Pick your **coach. Pick your vibe.** | *Voice, tone, style — all customizable* | Coach persona picker w/ avatar grid + voice samples |
| 12 | See **where you rank** — worldwide | *Weekly XP leaderboards, near-you boards, friend boards* | Discover screen — percentile hero card + Top 10 list |

Order on Play (when uncapped): 1-8 stays. Then 9 (recipes), 10 (Fuel), 11 (persona), 12 (Discover) — fans out from "the app does X" → "the app makes you better" → "the app is uniquely yours" → "and there's a community."

---

## Foldable Showcase (3 smaller mockups)

A single caption spans all three — the row of foldable mockups reads as one "Fits every form factor" beat without needing per-device copy.

**Caption (shared)**: *"Fold, Flip, Unfold. Fully Loaded."*

| # | Device | Orientation | Screen to capture |
|---|--------|-------------|-------------------|
| F1 | Samsung Z Fold (inner screen) | Portrait, book-unfolded | Full day view — home dashboard or nutrition tab so the taller canvas reads as "more at a glance" |
| F2 | Samsung Z Fold (inner screen) | Landscape, wide-unfolded | Chat + workout side-by-side layout so the wide mode reads as "coach on one side, set on the other" |
| F3 | Samsung Z Flip | Half-folded or cover display | Quick-log action (meal add / water log / start workout) — whatever surfaces best at that aspect ratio |

**Layout**: render the three mockups smaller than the main 8 screenshots and group them on a single card/frame so the caption applies to the row as one unit.

---

## App Preview Video (recommended for fitness)

Fitness apps see disproportionate lift from a 15-30s app preview video.

- **First 3 seconds**: a real-world scene (person snapping a meal, recording a set) — NO logo intro.
- **Order to demo** (mirrors the screenshot deck): chat-log meal → fridge scan → workout generation → active set → progress chart. Reinforcement compounds.
- **Captions burned into video** (not voiceover) — most users watch muted.
- **End frame**: app icon + "Zealova — your fitness coach in chat".

---

## Adding New Features Later

When a new feature ships, evaluate against three rules before changing the deck:

1. **Does it deserve its own frame, or is it a secondary mention on an existing one?**
   - Standalone if it's a category differentiator (form video analysis, fridge scan).
   - Secondary mention if it deepens an existing frame.
2. **Does it bump anything out of the top 8?**
   - Only if it ranks higher on **Visual wow × Differentiation × Daily-use** than the current frame it would replace.
   - Most new features land in the extended deck (slots 9-12), not the core 8.
3. **Does it change the frame-1 badge?**
   - Big partnerships, awards, or milestone numbers (10k users, App Store featuring) go into the social-proof badge.

---

## In-App Intro Screen

The app intro screen mirrors the first 7 of these screenshots — same captions, same background colors, one phone per page. Screenshot assets go in `assets/images/`:

| Page | Asset filename | Matches Frame # |
|------|---------------|-----------------|
| 1 | `intro_brand.png` | #1 |
| 2 | `intro_what_to_lift.png` | #2 |
| 3 | `intro_menu_fridge.png` | #3 |
| 4 | `intro_swap_exercise.png` | #4 |
| 5 | `intro_voice_log.png` | #5 |
| 6 | `intro_strength_climb.png` | #6 |
| 7 | `intro_body_track.png` | #7 |

(Frame 8 — Shareable gallery — is not in the intro; sharing/gamification is a retention scaffold, not a first-run hook.)

---

## Pre-Capture Checklist

- [ ] Dark mode enabled (in-phone screen)
- [ ] 20+ workouts logged (heatmap/stats — frame 6)
- [ ] At least one PR detected (frame 6)
- [ ] At least 2 progress photos at different dates (frame 7)
- [ ] At least 2 prior bench sessions logged so progression bars render (frame 2)
- [ ] At least one menu scan + fridge scan + 3 recipe outputs available (frame 3)
- [ ] Test chat messages drafted: pizza+coke, yoga 30min, easy run (frame 5)
- [ ] Test exercise-swap conversation drafted (frame 4)
- [ ] Shareable gallery has 15+ formats visible (frame 8)
- [ ] No sensitive personal data visible in any screenshot
- [ ] Status bar clean (good signal, battery, time)
- [ ] No debug banners showing
