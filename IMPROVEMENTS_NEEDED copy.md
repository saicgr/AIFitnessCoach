# FitWiz — Improvements Needed

## Programming & Training Logic

- [ ] **Mesocycle visibility** — expose 4-6 week block view with volume/intensity curves so users see *why* Wednesday is lighter
- [ ] **Progressive overload legibility** — surface per-exercise targets: "Bench 185×5 last week → target 190×5 or 185×6 today, RIR 2"
- [ ] **"Why today" 1-liner** on every workout — e.g. "Push day, slight deload, lower volume because sleep avg dropped 8% this week"
- [ ] **Program-thinking trust signals** — deloads triggered by fatigue/sleep, not fixed calendar
- [ ] **Velocity-based training** — optional RPE/velocity input for advanced users
- [ ] **ACWR fatigue model** — chronic:acute workload ratio to flag overtraining risk

## Exercise Library & Coaching Depth

- [ ] **Replace LLM-generic form cues** with structured cues: primary fault → corrective drill → regression/progression ladder
- [ ] **Tie safety tagging (NSCA/NASM/ACSM research) to on-screen coaching**, not just exercise filtering

## Nutrition

- [ ] **Training-day vs. rest-day macro split** by default
- [ ] **Batch cook leftover tracking** surfaced on plate-log screen (model already exists)
- [ ] **Refeed / diet-break logic** for cutters — scheduled high-carb days + planned maintenance breaks

## Retention Anti-Patterns to Fix

- [ ] **Rest-day home redesign** — show mobility, NEAT target, recovery score, tomorrow's preview (no dead-screen)
- [ ] **Streak fragility** — replace hard streaks with consistency scores + forgiveness windows
- [ ] **Lifecycle email tone** — guilt-free, schedule-aware copy (already in memory feedback)
- [ ] **Coach voice continuity** — enforce single persona across push, email, chat

## Retention Levers, Ranked

1. [ ] **Weekly review ritual (Sunday Wrapped push)** — 90-sec AI summary: volume, PRs, sleep correlation, next-week preview; $0 cost, highest-ROI lever in Strong/Hevy/Whoop
2. [ ] **Progression legibility** — every exercise shows last 3 sessions + next target
3. [ ] **Coach continuity** — single persona voice across all touchpoints
4. [ ] **One-tap "adjust today"** — sore / tired / short on time → workout adapts in place; surface on active-workout screen, not buried in chat
5. [ ] **CSV export of every log** — practitioners trust apps that let data leave
6. [ ] **Progress hub consolidation** — merge trophies/achievements/rewards/XP/skills into one tab for discoverability (tighten, don't delete)

---

## Obese Beginner Track

*Persona: 240+ lb, sedentary 4+ years, joint pain, no gym experience, borderline comorbidities (prediabetes/hypertension/sleep apnea). High-risk churn persona — 60% drop by Day 30 industry-wide. These items close that gap.*

### Onboarding & First-Run
- [ ] **Obese-beginner onboarding track** — separate flow from general "beginner": chair-based progressions, wall/incline push-ups, 5-10 min sessions Week 1, no jumping/impact exercises
- [ ] **Defer the scale** — first weigh-in optional with "I'd rather wait" option (no guilt); use tape measurements or progress photos as alternative baselines
- [ ] **Jargon-free mode** — toggle replaces "RIR 2" with "2 reps in the tank"; hides "mesocycle," "split," "periodization"; inline tooltips on every jargon term
- [ ] **Medical flag handling** — if user enters hypertension, diabetes, or BMI >35, gentle nudge for doctor clearance + disclaimer on high-intensity workouts

### Programming for Zero-Baseline
- [ ] **True zero-baseline progressions** — chair squats before bodyweight squats, wall push-ups before knee push-ups, seated rows before standing; injury screen should filter exercises, not just suggest swaps
- [ ] **Joint-aware exercise swaps** — bad knees auto-swaps squats → sit-to-stand, lunges → low step-ups, running → walking/water walking
- [ ] **Chair/bed exercise library** — for days user physically can't stand for 10 min
- [ ] **"I'm in pain" button mid-workout** — one tap, swap to joint-friendly alternative, no judgment
- [ ] **"How do you feel today?" pre-workout check** — adapts session based on energy/pain; some days a 10-min walk is the win
- [ ] **Hydration and walking as "real" workouts** — log 10-min walk as a W, not an asterisk; dopamine matters more than rigor

### Nutrition for the Obese Beginner
- [ ] **Calorie ramp, not cliff** — Week 1: -200 cal deficit, Week 4: -500; show ramp visually so user doesn't feel starved day one
- [ ] **Grocery-list meal plans** — 5 recipes for the week + shopping list; decision fatigue drives users back to DoorDash
- [ ] **No "clean eating" shame language** — swap "junk food," "cheat meal," "bad foods" → neutral framing

### UX & Tone
- [ ] **"Just Today" minimal home mode** — hide achievements/challenges/discover until Week 3; show only today's workout, food target, water
- [ ] **Body-neutral copy audit** — no "burn that belly fat," "shred," "torch"; use "feel stronger," "move more freely," "build energy"
- [ ] **Progress photos with privacy-first UX** — local-only storage option, blurred by default in UI, unlocked on tap
- [ ] **Hide leaderboards/social for obese-beginner track** — comparison triggers spiral and churn for this persona
- [ ] **Start-line celebration** — Day 1 completing a 5-min chair workout celebrated as big as a 225 lb bench PR; calibrate gamification to user level

### Non-Scale Retention Hooks
- [ ] **Non-scale victories dashboard** — "walked 2,000 more steps than last week," "slept 7+ hrs 4 nights," "resting HR dropped 3 bpm" — not just weight
- [ ] **Weight-plateau empathy** — when scale stalls 2+ weeks (it will), coach proactively messages "this is normal, here's why" — not silence
- [ ] **Day 3 + Day 7 re-engagement** — highest beginner drop-off points; warm push notification, not guilt
- [ ] **Plateau prediction + pre-emptive message** — AI anticipates the stall and messages *before* user gets discouraged

### The Four Churn Moments to Engineer For
1. **Day 3** — "I can't do the workout, it's too hard" → zero-baseline progressions + "I'm in pain" button
2. **Day 7** — "I weighed myself, no change, I quit" → non-scale victories dashboard + deferred scale + plateau empathy
3. **Day 14** — "I ate a pizza, broke my streak, shame-quit" → streak forgiveness windows + body-neutral copy
4. **Day 21** — "Too many screens, I got lost" → Just Today minimal mode + consolidated Progress hub

