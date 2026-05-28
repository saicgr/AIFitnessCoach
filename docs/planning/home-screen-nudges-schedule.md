# Zealova Home Screen — Nudges & Suggestions Schedule

> Hour-by-hour view of every proactive nudge / suggestion the home screen surfaces. The "what shows when" companion to [`home-screen-surfaces.md`](./home-screen-surfaces.md).

**Last updated:** 2026-05-27. **Total nudges catalogued:** 68 (original) + 83 (round 2 research) = **151 distinct nudges**.

## What's a "nudge"?

The home tab has **three distinct nudge surfaces**. The word "nudge" is used loosely across product chats; this doc disambiguates everywhere:

| Surface tag | Where it lives | Capacity | Dismiss behaviour |
|---|---|---|---|
| **`sub-card`** | Inside the YOUR COACH hero card — horizontal `PageView`, 2-per-page, swipe to next | up to 8/day after ranking | swipe / ✕ → suppressed today only, re-evaluates tomorrow |
| **`banner`** | Stacked banner panel (between header and coach card) | up to 3 concurrent | ✕ → per-banner rule (most per-day, some per-week, some per-event) |
| **`push`** | OS notification tray (outside the app) | ~3/day cap | OS dismiss → server marks dedupKey seen for 24h |

Each catalogue row below is tagged with its primary surface. Some nudges fire via multiple surfaces simultaneously (e.g. streak-at-risk fires as both a `banner` and a `push`) — those are flagged.

**The dedupKey rule across surfaces**: a single dedupKey (e.g. `streak_risk_2026_05_27`) covers all surface variants. Tapping a `push` for that key suppresses the in-app `banner` variant for 24h, and vice versa. No double-pestering.

---

## 1. Time bands

The home screen classifies the current local hour into one of seven bands. Most nudges are gated to one or more bands.

| Band | Hours (local) | Mood | Default behaviour |
|---|---|---|---|
| `early` | 05:00 – 06:59 | gentle wake | Hydration first. No heavy CTAs. |
| `morning` | 07:00 – 10:59 | active start | Breakfast + water + day-prep nudges. |
| `midday` | 11:00 – 13:59 | sustenance | Lunch + hydration catch-up + pre-workout fuel. |
| `afternoon` | 14:00 – 16:59 | steady | Caffeine cutoff window, mid-afternoon hydration. |
| `evening` | 17:00 – 20:59 | activity + dinner | Dinner + workout + post-workout refuel + streak risk. |
| `late` | 21:00 – 22:59 | wind down | Sleep prep, tomorrow's preview, last-chance streak save. |
| `quiet` | 23:00 – 04:59 | silent | All proactive nudges suppressed. Home renders a minimal "sleep in progress" state. |

Industry convention: every researched app (WHOOP, Oura, Apple Watch, Garmin, Fitbit, Strava, MyFitnessPal, Noom, Headspace) treats 23:00–04:00 as a quiet window. Zealova matches.

---

## 2. Nudge catalogue

One row per distinct nudge. Sorted by typical time-of-day order, then priority within the same hour. **Surface** column tags where it renders: `sub-card` (inside coach card PageView) · `banner` (stacked banner panel) · `push` (OS notification) · `passive` (informational tile, no action). Some nudges fire on multiple surfaces — both are listed.

| # | Nudge name | Surface | Type | Trigger condition | Copy / CTA | Time window | Frequency cap | Suppression |
|---|---|---|---|---|---|---|---|---|
| **EARLY (05:00–06:59)** |
| 1 | Wake hydration · Overnight reset | sub-card | hydration | `water_today < 8oz && water_tracker_user` | "💧 Overnight reset · Log your first 16oz of water" · `[Log 16oz]` | 05:00–10:59 | once/day, hides on log | dismissed-this-morning |
| 2 | Cycle phase chip | passive | passive info | `menstrualTrackingEnabled` | "🟠 Luteal · day 22" (tap → insights) | always | — | tracking disabled |
| **MORNING (07:00–10:59)** |
| 3 | Breakfast suggestion | sub-card | nutrition | `!breakfastLogged` | "🍳 Breakfast suggestion · Aim 30g protein + 50g carbs" · `[Quick log]` | 06:00–10:59 | once/day, hides on log | breakfast logged |
| 4 | Daily Readiness Score [F3.5] | passive | recovery | wearable data ready | "Readiness: 78 · Train ready" (or "52 · Take it lighter") | morning band | — | no wearable data |
| 5 | RHR anomaly chip [F3.7] | banner | health alert | `rhr_today ≥ baseline+5 && yesterday +3` | "RHR elevated 3 days · auto-rest suggested" | always when triggered | once until resolved | already in rest mode |
| 6 | Setup checklist [F3.1] | banner | onboarding | `daysSinceSignup ≤ 7 && !complete` | 6-item progress card | always | — | all items complete |
| 7 | Calibration banner | banner | onboarding | `daysSinceSignup ≤ 7` | "Day 3 of 7 — we're learning" | always | — | post day 7 |
| 8 | Cycle setup prompt | banner | onboarding | `!menstrualTrackingEnabled && cycle_capable` | "Track your cycle for smarter workouts" | always | once until dismissed | dismissed |
| 9 | Mood check-in [F3.39] | sub-card | mental | first foreground of day | "😢 😕 😐 🙂 😄 · How's the day?" | once/day | once | logged |
| 10 | Pre-workout fuel timing [F3.73] | sub-card | nutrition | high-int workout in 60–90 min | "Eat 30g carbs by 4:30 PM for your 5 PM lift" | pre-workout window | once/day per workout | meal logged |
| **MIDDAY (11:00–13:59)** |
| 11 | Lunch suggestion [F3.3] | sub-card | nutrition | `!lunchLogged` | "🥗 Lunch suggestion · 35g protein, balanced plate" · `[Quick log]` | 11:00–14:59 | once/day, hides on log | lunch logged |
| 12 | Midday hydration catch-up [F3.4] | sub-card | hydration | `cupFraction < 0.4 && hours_since_last_log >= 2` | "💧 Catch up · {logged}oz / {goal}oz" · `[Log 8oz]` | 11:00–17:00 | up to 2x/day | hit ≥ 40% today |
| 13 | Hourly Stand reminder [F3.22] | sub-card · push | movement | `lastMovementAt < now-50min` | "🪑 Time to stand · 2 min of any movement" | 07:00–21:00 | hourly | movement detected |
| 14 | Long-sit walk-break [F3.26] | sub-card | movement | >90 min continuous sitting | "🚶 Walk 5 min — your back will thank you." | 09:00–18:00 | once/sitting block | walked |
| **AFTERNOON (14:00–16:59)** |
| 15 | Caffeine cutoff warning [F3.18] | sub-card | nutrition | caffeine after 14:00 AND yesterday sleep < 70 | "☕ Caffeine after 2 PM correlated with last night's REM drop" | 14:00–18:00 | once/day | no caffeine logged today |
| 16 | Missed workout banner | banner | schedule | scheduled workout past start AND not started | "Missed at {time} · [Do Today] / [Skip]" | always | until acted | done or skipped |
| 17 | RPE / target effort chip [F3.102] | sub-card | pre-workout | workout scheduled today | "Target RPE: 7-8 today" | 12:00–end-of-workout | once | workout done |
| **EVENING (17:00–20:59)** |
| 18 | Pre-workout T-30m band [F3.100] | sub-card | pre-workout | workout in next 30 min | "Up in 28 min — start warming up" · `[Start warm-up]` | T-30 → T-now | once | workout started |
| 19 | Hydration target pre-workout [F3.106] | sub-card | pre-workout | workout in next 60 min | "💧 Pre-workout: 16oz water now" | T-60 → T-0 | once | water logged |
| 20 | Post-workout refuel | sub-card | nutrition | workout completed + window open + no meal logged | "🔥 Refuel window · Eat {protein}g protein in next 30 min" | T+0 → T+45 | once | meal logged |
| 21 | Dinner suggestion [F3.3] | sub-card | nutrition | `!dinnerLogged` | "🍽️ Dinner suggestion · Wind down with protein + veggies · {remaining}kcal left" · `[Quick log]` | 17:00–21:30 | once/day, hides on log | dinner logged |
| 22 | Streak-at-risk pre-warning [F3.2] | banner · push | gamification | `now == historicalCompletionTime + 2h && !todayLogged` | "🔥 Streak at risk · log to keep" · `[Quick log]` | from historical+2h | once/day | log made |
| 23 | Personal record banner | banner | celebration | recent PR (today/yesterday) | "🏆 New PR · {exercise} {weight}lb" | always while fresh | per-PR | dismissed |
| 24 | Contextual breathwork CTA [F3.41] | sub-card | mental | stress elevated OR HRV dropped today | "🌬️ Try 4-7-8 breathing · 90 sec" | 17:00–22:00 | once/day | done or dismissed |
| **LATE (21:00–22:59)** |
| 25 | Bedtime window countdown [F3.27] | sub-card | sleep | `now ≥ sleepTarget - 90min` | "60 min to bedtime · wind-down recommended" | 21:00–sleep | once | wound down |
| 26 | Tomorrow's preview tile [F3.69] | sub-card | schedule | `tomorrowWorkout != null` | "🌅 Tomorrow: Upper Body · 60 min · 7 exercises" | from 20:00 | once | dismissed |
| 27 | Late-day hydration · close the day | sub-card | hydration | `cupFraction < 0.60` | "💧 Close the day · Log 16oz" · `[Log 16oz]` | from 20:00 | once | hit ≥ 60% |
| 28 | Wind-down nudge | sub-card | sleep | `now ≥ 21 && sleepTargetSet` | "🧘 60 min to bedtime · dim screens" | 21:00–sleep | once | done |
| 29 | Blue-light cutoff reminder [F3.30] | sub-card · push | sleep | `now == sleepTarget - 60min` | "🌙 60 min to bed · dim screens" | once per night | once | dismissed |
| 30 | Gratitude / journal prompt [F3.43] | sub-card | mental | `hour ≥ 20` | "📔 What went well today?" (single line input) | from 20:00 | once | logged |
| 31 | Evening sleep-story tile [F3.44] | sub-card | mental | `hour ≥ 21` | "🌙 Tonight's sleep story · 12 min" | from 21:00 | once | dismissed |
| 32 | Streak-at-risk last-chance [F3.2] | banner · push | gamification | `hour == 23 && !todayLogged` | "⏰ 60 min · log anything to keep streak" | 23:00–23:55 | once/day | log made |
| **QUIET (23:00–04:59)** |
| 33 | Sleep-in-progress state | passive | passive | always | Minimal "Sleeping" home view; cards collapsed | always | — | foreground only |
| **NON-TIME-BANDED (any hour)** |
| 34 | Hourly Stand reminder | sub-card · push | movement | every sedentary hour | "🪑 Time to stand" | 07:00–21:00 | hourly | moved |
| 35 | Approaching-end fast nudge [F3.89] | sub-card · push | fasting | `fastingActive && remaining < 60min` | "⏰ Fast ends in 45 min — prep your first meal" | last hour of fast | once/fast | meal logged |
| 36 | Refeed window state [F3.90] | sub-card | fasting | fast ended last 2h | "🍽️ Refeed: protein first (25g) · then complex carbs (40g)" | first 2h post-break | once/fast | window passed |
| 37 | Pre-fast countdown [F3.95] | sub-card | fasting | scheduled fast in next 60 min | "⏰ Fast starts in 45 min — last meal window" | T-60 → T-0 | once | fast started |
| 38 | Extend-current-fast CTA [F3.96] | sub-card | fasting | `now ≥ scheduledEnd && fastingActive` | "💪 Past your goal — extend by 4h?" | always when triggered | hourly | declined |
| 39 | Sweat-day electrolyte chip [F3.21] | sub-card | nutrition | hot weather OR cardio > 45 min OR sauna log | "🧂 Sodium + potassium today — sweat session" | varies | once/day | acted or dismissed |
| 40 | Skin-temperature deviation alert [F3.13] | banner | health alert | deviation > 0.5°C from baseline | "🌡️ Body temp elevated — fever or hormonal shift?" | always when triggered | once until resolved | resolved |
| 41 | Respiratory rate spike chip [F3.8] | banner | health alert | `resp_today ≥ baseline + 2 bpm` | "🫁 Resp rate up — possible illness." | always when triggered | once until resolved | resolved |
| 42 | PMS prep card [F3.34] | sub-card | cycle | last 5 days of luteal phase | "🌙 PMS window approaching — magnesium-rich foods + 8h sleep" | luteal end | once/cycle | dismissed |
| 43 | Period-symptom one-tap log [F3.36] | passive | cycle | during menstrual phase | 5 chips (cramps / headache / etc.) tappable | menstrual phase | always present | not in menstrual phase |
| 44 | Ovulation-peak strength window [F3.35] | sub-card | cycle | ovulation ± 2 days | "💪 Strength PR window open — go for that lift" | ovulation ±2 | once per ovulation | dismissed |
| 45 | Period prediction countdown [F3.33] | banner | cycle | `daysToNextPeriod ≤ 5` | "🩸 Period in 3 days · log symptoms when ready" | always when triggered | once/cycle | dismissed |
| 46 | Perimenopause cues [F3.38] | banner | cycle | `age > 40 && cycle_variability > 5 days` | "Cycle variability up — could be perimenopause" | always when triggered | once/month | dismissed |
| 47 | Pregnancy mode | passive | cycle | `pregnancyModeOn` user setting | Reroutes copy + suppresses cycle prompts | always | — | toggled off |
| 48 | Achievement-near-unlock chip [F3.51] | banner | gamification | within 3 events of unlock | "1 more workout to unlock 'Consistent Trainer'" | always | once/achievement | unlocked |
| 49 | Streak freeze inventory [F3.47] | passive | gamification | streak > 0 AND freezes available | "🧊 2 streak freezes" | always | passive (info) | streak ended |
| 50 | Daily Quest deck [F3.48] | passive | gamification | always (3 rotating quests) | "📋 Today's 3 quests" with checkboxes | always | — | all complete |
| 51 | Birthday card [F3.82] | banner | special | `today == birthday` | "🎂 Happy birthday! Bonus: pick today's workout" | birthday | once/year | dismissed |
| 52 | App-anniversary card [F3.63] | banner | special | `daysSinceSignup ∈ {365, 730, …}` | "🎉 1 year on Zealova! 156 workouts · 32 lbs lost · Share?" | anniversary | once/year | shared/dismissed |
| 53 | First-of-month reset [F3.84] | banner | special | `day == 1` | "📅 New month · review goals + adjust targets" | day 1 | once/month | dismissed |
| 54 | Workout-count milestone [F3.64] | banner | celebration | `totalWorkouts ∈ {10, 25, 50, 100, 250, 500}` | Celebration card | on milestone hit | once per milestone | dismissed |
| 55 | Body-comp milestone [F3.65] | banner | celebration | weight delta crosses {1,5,10,20} kg | "🎯 5kg down · share?" | on milestone hit | once per milestone | dismissed |
| 56 | Weigh-in day reminder [F3.83] | sub-card · push | habit | weekly weigh-in day AND not weighed | "⚖️ Weigh-in day — step on the scale before breakfast" | on weigh-in day | once/week | weighed |
| 57 | Wearable battery low [F3.66] | banner | wearable | `battery < 20%` | "🔋 Apple Watch battery low · charge for sleep tracking" | always when triggered | once until charged | charged |
| 58 | Scale sync prompt [F3.67] | banner | wearable | paired scale + no weigh-in 7d | "⚖️ Scale needs a sync · step on" | always when triggered | once/week | synced |
| 59 | Missing-data nudge [F3.68] | banner | wearable | data hole > 24h | "📡 No activity data since yesterday · check device pairing" | always when triggered | once until resolved | resolved |
| 60 | Jet-lag adjust [F3.80] | sub-card | travel | timezone changed > 3h in past 7d | "✈️ Jet lag — shift bedtime 30 min earlier each night" | first 7 days post-change | daily | gone |
| 61 | Return-to-exercise progression [F3.78] | passive | injury | active injury logged | "{Muscle} return plan · Week 2 of 4 · today: bodyweight only" | always when triggered | — | injury cleared |
| 62 | Affected-muscle workaround [F3.79] | sub-card | injury | today's workout hits active injury | "Today targets your knee — swap to upper-body alternative?" | per workout | once/workout | swapped |
| 63 | Usage-based upsell [F3.56] | banner | subscription | free user + power-user signal | "You're a power user — Premium pays for itself" | rate-limited | once/week | upgraded/dismissed |
| 64 | Trial progress widget | passive | subscription | `billingPeriod == "trial"` | "X days left in trial · Upgrade" | always | passive | converted |
| 65 | Daily lesson tile [F3.60] | passive | educational | content available | "📖 Today's lesson · 4 min read" | always | once/day | read |
| 66 | Knowledge-is-Power 3 cards [F3.59] | passive | educational | always (rotates) | 3 micro-cards in horizontal carousel | always | — | — |
| 67 | Sunday Weekly Digest [F3.61] | banner | educational | `weekday == 0` | "This week: 4 workouts · 1500g protein · -0.3 kg" | Sunday | once/week | dismissed |
| 68 | Discovery insight feed [F3.62] | sub-card | educational | pattern detected | "📊 You sleep 30 min less on workout days" | always when triggered | once/insight | dismissed |

---

## 3. 24-hour timeline — typical engaged user

A "typical engaged user" = logs water + meals consistently, tracks workouts, female with cycle on, has wearable. Times in user-local hours.

| Hour | Surface stack (in render order, top → bottom) |
|---|---|
| 05:00 | sleep-in-progress (still quiet hours) |
| 05:30 | sleep-in-progress |
| 06:00 | header · cycle phase chip · **💧 Wake hydration (#1)** · breakfast suggestion (early-band variant) · cycle setup or calibration if applicable · coach hero card minimised |
| 07:00 | header · **Setup checklist (F3.1)** if day≤7 · **💧 Wake hydration** · **🍳 Breakfast suggestion (#3)** · **Daily Readiness Score (F3.5)** · coach card · today rings · hourly stand if sedentary |
| 08:00 | (water logged) breakfast suggestion still up · coach card refreshed midday-leverage · today rings ticking |
| 09:00 | (breakfast logged) morning slots fade · coach card normal · hourly stand |
| 10:00 | hourly stand · long-sit chip if seated 90 min · standard home |
| 11:00 | **🥗 Lunch suggestion (#11)** · hourly stand · **Pre-workout fuel timing if afternoon workout (#10)** |
| 12:00 | lunch suggestion · midday hydration if under 40% · today rings progressing |
| 13:00 | (lunch logged) lunch slot fades · pre-workout T-2h fuel chip if 3 PM workout |
| 14:00 | **Caffeine cutoff warning (#15) if applicable** · midday hydration · RPE chip if workout coming |
| 15:00 | (workout starting) **Pre-workout T-30 (#18)** · **Hydration pre-workout (#19)** · hero card switches to inProgress |
| 16:00 | workout inProgress mode · live PR banner if hit · "Live · 18:42" |
| 17:00 | (workout done) **🔥 Post-workout refuel (#20)** · **Training Effect (F3.111)** · **HR-zone breakdown (F3.118)** · 1RM banner if applicable · **Dinner suggestion (#21)** |
| 18:00 | dinner suggestion · refuel slot starts fading (window ended) · today rings near full |
| 19:00 | (dinner logged) dinner slot fades · streak-at-risk pre-warning if no log AND past historical+2h |
| 20:00 | **Bedtime window countdown (#25)** · **Tomorrow's preview (#26)** · **Late-day hydration (#27)** · **Gratitude prompt (#30)** · home wind-down state |
| 21:00 | **Wind-down nudge (#28)** · **Evening sleep-story (#31)** · tomorrow preview · blue-light cutoff |
| 22:00 | **Streak-at-risk last-chance (#32)** if still no log · sleep-story · quiet mode preparing |
| 23:00 | sleep-in-progress (#33) · all proactive nudges silent |
| 00:00–04:59 | sleep-in-progress |

**Daily nudge density** (this profile): ~14 distinct nudges fire across the day, spaced so the user sees 2-4 per home-tab visit. No hour has more than 8 simultaneously eligible (the F4 cap).

---

## 4. Profile-variant timelines

### 4.1 New user (day 1)

| Hour | Surface stack |
|---|---|
| 07:00 | header · **Calibration banner (#7)** · **First-action prompt** · **Cycle setup prompt (#8)** · **Setup checklist (#6)** · **Notification opt-in prompt** · coach hero card (welcome variant) · 💧 Wake hydration · 🍳 Breakfast suggestion · today rings (empty) |
| 09:00 | Setup checklist · onboarding prompts persist · breakfast slot if not logged |
| 12:00 | lunch suggestion · Setup checklist still anchored above coach card |
| 17:00 | onboarding prompts · dinner suggestion · home workout card "Generate your plan" |
| 20:00 | wind-down · setup checklist · evening prompts |
| 23:00 | quiet |

### 4.2 Power user (no cycle tracking)

| Hour | Differences from typical engaged user |
|---|---|
| 06:00 | Adds **Daily Quest deck (#50)** · Daily lesson (#65) |
| 10:00 | League rank tile (F3.49) appears at this user's check-in hour |
| 17:00 | **Friend activity snippet (#52)** · accountability partner nudge if applicable |
| 21:00 | **Sunday Weekly Digest** if Sunday |

### 4.3 Cycle-tracking user, luteal phase

Adds on top of typical engaged user:
- **Cycle phase chip (#2)** anchored all day at top
- **PMS prep card (#42)** in evening if last 5 days of luteal
- Cycle-aware coach hero copy ("Fueling for luteal phase")
- Cycle-adjusted workout-card mode if a high-intensity day

### 4.4 Fasting user (currently 16h fast)

| Hour | Adds |
|---|---|
| 05:00 | Fast tile ring + zone badge · No breakfast suggestion (fasting active) |
| 11:00 | Approaching-end nudge (#35) at 30 min before scheduled break |
| 12:00 | **Refeed window state (#36)** for first 2h post-break |
| All day | Protein-target shift on fast days · zone-progression strip · iOS Live Activity if iOS 16.1+ |

### 4.5 Wearable user (Oura / Apple Watch / WHOOP)

Adds:
- **Daily Readiness Score (F3.5)** prominent in morning
- **HRV trend strip (F3.6)** in combined health card
- **RHR anomaly chip (F3.7)** if triggered
- **Body Battery gauge (F3.9)** all day
- **Stress score (F3.10)** waking hours
- **Sleep-latency tile (F3.29)** if data available
- **VO2max trend chip (F3.12)** weekly

### 4.6 Free / trial user

Adds:
- **Trial progress widget (#64)** all day
- **Usage-based upsell (#63)** weekly rate-limited
- **Premium content preview (F3.58)** 1/day
- **Locked feature CTAs** on advanced cards

### 4.7 Paid (premium) user

Same as typical, minus all upsell surfaces.

---

## 5. Cap + conflict-resolution rules

When > 2 nudges are eligible at the same minute:

1. **Hard cap**: 8 sub-cards inside the coach card's PageView, per F4. If more than 8 evaluate true, the lowest-priority items are pruned (priority tier → perishesAt asc within tier).
2. **Per-page slots**: 2 cards per page → swipe to next pair. Dots below indicate page count.
3. **Per-band limits**:
   - `early` band: max 3 sub-cards
   - `morning` band: max 6 sub-cards
   - `midday` band: max 5 sub-cards
   - `afternoon` band: max 4 sub-cards
   - `evening` band: max 6 sub-cards (busy band — workouts + refuel + dinner + bedtime prep)
   - `late` band: max 4 sub-cards (winding down — less aggressive)
   - `quiet` band: 0 nudges
4. **De-dup**: once a card's `dedupKey` is dismissed or its CTA tapped, it does not re-render the rest of that day. Some dedupKeys carry into the next week (e.g. educational lesson #65 — don't show the same lesson twice in 7 days).
5. **Priority pyramid** (default — overridable in AI Settings):
   - P1 Health alerts (RHR/HRV anomaly, illness, temp deviation)
   - P2 Time-sensitive (refuel window, bedtime, pre-workout fuel, fast-approaching-end)
   - P3 Streak-at-risk
   - P4 Habit nudges (water, meals, stand)
   - P5 Educational
   - P6 Social
6. **User override**: drag-rank in Settings → AI Settings → "Nudge category priorities". Persists per user.
7. **Notification dedup**: if a push for nudge X was tapped to open the app, that nudge X is suppressed in-app for the next 24h (so the user doesn't see "log water" both in the push and on the screen they just landed on).

### 5.1 Example collision scenarios

**08:00 morning, returning user, no water yet, no breakfast, RHR up 3 days, ovulation peak, league rank changed yesterday, daily quest available:**

Eligible at this minute:
- RHR anomaly (P1)
- 💧 Wake hydration (P4)
- 🍳 Breakfast suggestion (P4)
- Ovulation-peak strength chip (P4)
- League rank tile (P6)
- Daily Quest deck (P6)
- Daily lesson (P5)

After ranking + cap:
- Page 1: RHR anomaly · Wake hydration
- Page 2: Breakfast suggestion · Ovulation chip
- Page 3: Daily lesson · League rank
- (Daily Quest deck pruned via per-band limit)

**17:30 evening, workout just completed, no dinner, streak-at-risk near, partner crushed it, kudos waiting:**

- Post-workout refuel (P2 — time-sensitive)
- 1RM banner (P2)
- Training Effect (P5 informational)
- Dinner suggestion (P4)
- Streak-at-risk pre-warning (P3)
- Friend activity snippet (P6)
- Accountability partner nudge (P6)
- Kudos count dot (P6)

After ranking + cap:
- Page 1: Refuel · 1RM banner
- Page 2: Streak-at-risk · Dinner suggestion
- Page 3: Training Effect · Friend activity
- (Accountability + kudos pruned)

---

## 6. Quiet-hours convention

`23:00–04:59` local: home renders a minimal state. Cards collapse. No animations. No new push notifications fire. Foreground during these hours shows:

- Greeting (e.g. "Sleeping in progress")
- Today rings (frozen with last-known values)
- Tomorrow's preview tile (passive)
- Hero workout card in `quiet` mode (no CTAs, read-only)

No proactive nudges fire. If the user opens the app at 2 AM, they see a minimal home — no "log water" pestering at 2 AM.

After `05:00`, the home re-enables the `early` band's nudge set.

---

## 7. Notification suppression bridges

In-app dismissal links to push suppression for the same nudge type:

- Dismiss in-app at 09:00 → push for that nudge suppressed until next eligible window (e.g. tomorrow morning).
- Tap a push → that nudge auto-marked seen in-app (don't re-show same nudge in the home tab the push deep-linked into).
- "Quiet hours" toggle in Settings → all push fully muted; in-app surfaces still render but pushes don't fire.

---

## 8. Round 2 — additional 83 nudges from deeper research

Same row shape as §2; consolidated here to keep the original 68 stable. Surface tag still applies (`sub-card` unless noted).

### Pre-meal / cooking / grocery

| # | Nudge | Surface | Trigger | Copy / CTA | Window | Cap |
|---|---|---|---|---|---|---|
| 69 | Grocery-store geofence | sub-card · push | inside grocery polygon + unchecked items | "At Trader Joe's. 7 items still on the list" | any | 1/store/day |
| 70 | Restaurant pre-order scan | sub-card | restaurant geofence dwell >90s + no recent log | "Scan the menu — protein winners flagged" | any | 1/venue/day |
| 71 | Batch-cook Sunday slot | sub-card | Sun 9–2 + free calendar ≥ 2h + ≥3 dinners planned | "2-hour gap Sunday. Batch-cook Mon-Wed?" | Sunday | 1/week |
| 72 | Leftover countdown / food-safety | sub-card | cook event ≥3 days old + portions_remaining>0 | "Tuesday's chili expires today — log a serving?" | any | 1/leftover |
| 73 | Hidden-sugar warning post-scan | sub-card | logged packaged food >12g added sugar/serving | "18g added sugar — want a swap?" | <2min after log | 1/log |
| 74 | Sodium cap watch | sub-card | sodium ≥2000mg by 4pm | "Salt's at 2,100mg. Lean dinner tonight." | from 16:00 | 1/day |
| 75 | Fiber gap by meal | sub-card | any meal <4g fiber | "Lunch was 2g fiber. Fruit at snack?" | any | 2/day |
| 76 | Protein gap by meal | sub-card | any meal <15g protein | "Breakfast came in at 9g. Add Greek yogurt?" | any | 2/day |
| 77 | Late-night snack alternative | sub-card | log attempt 21:00+ on >300kcal item | "Swap to cottage cheese + berries — sleep-friendly" | 21:00–23:00 | 1/log |
| 78 | Ingredient running low | sub-card | pantry count ≤1 + in week's planned recipe | "Out of oats by Thursday. Add to list?" | any | 1/item |

### Mid-workout

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 79 | Mid-session hydration | sub-card | duration >25min + no in-workout water log | "Sip break." `[+8oz]` |
| 80 | Cool-down stretch | sub-card | workout done + HR still >60% MHR | "60s of cool-down keeps the gains" |
| 81 | Variation prompt — 3 sessions same lift | sub-card | same exercise_id 3 consecutive sessions | "Bench 3 days running — sub incline today?" |
| 82 | Set rest exceeded | sub-card | rest timer >180% programmed | "Still resting? Tap Done when back" |
| 83 | Inter-set RPE check | sub-card | 2 sets logged + RPE empty | "How hard?" (6/7/8/9/10) |
| 84 | Late-workout sleep impact warning | sub-card | workout start <90 min before bedtime | "Heavy at this hour costs 30min deep sleep" |
| 85 | Music/podcast resume | sub-card | last session had Spotify handoff | "Pick up where you left off?" `[Resume]` |
| 86 | Partner-watching-live | passive | friend/coach opens shared workout view | "Sarah is watching this session" |

### Macro / weight advanced

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 87 | Deficit-too-aggressive warning | banner | 14d rolling deficit >25% TDEE | "Cutting harder than the plan. Refeed Friday?" |
| 88 | Refeed needed signal | sub-card | 10+ days deficit + HRV↓ + energy ≤2 | "Body's asking for fuel. Maintenance day?" |
| 89 | Carb cycling reminder | sub-card | high-intensity tomorrow + today rest | "Tomorrow's leg day — bump carbs at dinner" |
| 90 | Sugar spike prediction (CGM) | sub-card | predicted ΔBG >40 mg/dL | "This usually spikes you. 10-min walk after?" |
| 91 | Adaptive expenditure adjustment | sub-card | weekly TDEE shifted ≥75 kcal | "TDEE updated to 2,310. Targets adjusted." |
| 92 | Weigh-in fluctuation explainer | sub-card | weigh-in swings ±0.8% bw | "Up 1.2 lb — likely sodium from yesterday" |
| 93 | Body-recomp signal | sub-card | weight flat 4wks + waist ↓ + lifts ↑ | "Scale stuck, shrinking + stronger — recomp" |

### Recovery / wearable advanced

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 94 | Sauna / cold-shower nudge | sub-card | hard session done + sauna ≥3x/30d | "10-min sauna tonight tops off recovery" |
| 95 | Foam-roll reminder | sub-card | DOMS likely (volume >120% 4wk avg) | "Quads will hate tomorrow. 5min roll?" |
| 96 | Active recovery rest day | sub-card | rest day + steps <3k by 5 PM | "Light 20-min walk = better tomorrow" |
| 97 | Aerobic decoupling alert | sub-card | HR drift >5% vs pace last cardio | "HR drifted from pace — fatigue or heat" |
| 98 | RHR spike during rest week | sub-card | RHR +5 vs 14d baseline on rest day | "Resting HR elevated. Sickness or stress?" |
| 99 | Sleep efficiency drop | sub-card | 3-night rolling efficiency <80% | "Time in bed up, sleep down" |
| 100 | Social jetlag warning | sub-card | weekend bedtime >90min later than weekday | "Weekends giving you Monday jet lag" |
| 101 | Deload-week suggestion | sub-card | E1RM drop ≥5% across 2 wks at same RPE | "Lifts slipping. Deload week Monday?" |

### Cognitive / habit / emotion

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 102 | Habit-stack suggestion | sub-card | habit A done 5+ days same time | "You always coffee at 7am. Stack mobility?" |
| 103 | Boredom signal (re-engage) | sub-card | app opens <2 in 72h after weeks daily | "Quick win — log 1 thing today" (no guilt) |
| 104 | Mindful-eating slowdown | sub-card | meal logged <8min after previous bite | "Eating fast — one chew-only minute" |
| 105 | Phone-free meal challenge | sub-card | meal-time at home + phone use during last meal | "Phone down for dinner?" `[30-min timer]` |
| 106 | Weekly reflection (Sunday voice) | sub-card | Sun 7 PM | "Three words for the week?" `[Voice journal]` |
| 107 | Energy-crash prediction | sub-card | lunch >70% refined carbs + low protein | "Expect 3pm slump. Walk + water at 2:45?" |
| 108 | Stress-eating risk | sub-card | HRV crash + last meal <90min + history evening grazing | "Stress + appetite pattern — tea + 4-7-8 breath?" |
| 109 | Reward-eating risk post-PR | sub-card | big PR + dinner not planned | "Don't out-eat the PR. Plan dinner?" |

### Medical / safety

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 110 | Migraine trigger pattern | sub-card | user has migraine tag + trigger combo today | "Sleep <6h + skipped breakfast = your migraine. Eat now?" |
| 111 | Allergy-season heads-up | sub-card | local pollen ≥high + outdoor session planned | "Pollen spike — indoor or pre-medicate" |
| 112 | Medication / supplement window | sub-card · push | paired schedule + timing met | "Iron + vit C window opens in 10min" |

### Goal / contract

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 113 | Goal halfway nudge | sub-card | 50% of timeline elapsed | "Halfway to your 20-lb goal. 11.4 lb to go" |
| 114 | Goal slipping warning | banner | 4-week rate <40% target | "Pace half what we planned. Tighten or extend?" |
| 115 | Monthly review (sub-card variant) | sub-card | 1st of month | "April recap ready — 60s read" |
| 116 | Race countdown | sub-card | registered event T-14 to T-1 | "14 days to the 10K. Taper Friday." |

### Specialty diets

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 117 | Keto carb-spike alert | sub-card | logged meal >25g net carbs + keto goal | "That broke ketosis math. Walk it off?" |
| 118 | Vegan B12 reminder | sub-card | 5-day rolling B12 <50% RDA | "B12 low all week. Fortified milk or supplement?" |
| 119 | IF break-fast window opens | sub-card | T-15min to eating window | "Window opens at 12:00. Pre-pour water now" |
| 120 | Halal/kosher/dietary meal find | sub-card | restaurant geofence + dietary tag | "Halal options here: 4" (Yelp API) |

### Aerobic / cardio

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 121 | Zone 2 minutes today | sub-card | rolling Z2 <150min last 7d | "30min easy spin = Z2 target hit" |
| 122 | VO2max-day suggestion | sub-card | 14d since last threshold + recovered | "Body primed for 5×3min VO2 workout" |
| 123 | Fitness-test reminder | sub-card | 8 wks since last benchmark | "Re-test 5K? See real progress" |

### PCOS / hormonal

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 124 | Insulin-friendly breakfast (PCOS) | sub-card | PCOS tag + breakfast + last AM meal spiked | "Protein + fat first — eggs over oats today" |
| 125 | Inositol reminder | sub-card | supplement scheduled | "Inositol — 15min before lunch" |
| 126 | Cycle irregularity ack | banner | 2 consecutive cycles >35d apart | "Cycle running long. Hormone-focused plan?" |

### Men's hormonal

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 127 | Morning-erection marker (opt-in T) | sub-card | opt-in + AM log window | "Quick T-marker check?" (Y/N) |
| 128 | Cortisol cap | sub-card | HRV↓ + sleep <6h + steps high | "Cortisol-load day — skip caffeine after noon" |
| 129 | Zinc/Mg nutrition prompt | sub-card | 7d rolling Zn/Mg <60% RDA | "Pumpkin seeds or oysters this week" |

### Calendar integration

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 130 | Meeting-heavy day → lighter workout | sub-card | ≥5h meetings + ≥3 back-to-backs | "Meeting marathon — 25-min mobility?" |
| 131 | Lunch-meeting menu pre-scout | sub-card | 'lunch' calendar event + restaurant likely | "Pre-scout the menu?" `[Scan menu]` |
| 132 | Free 30-min block hold | sub-card | gap ≥30min between meetings + no session today | "30-min window at 2pm. Hold for a quick lift?" |
| 133 | End-of-workday wind-down | sub-card | last meeting ended + bedtime <4h | "Clock-out: 10-min walk to flip the switch" |

### Family / dependent

| # | Nudge | Surface | Trigger | Copy |
|---|---|---|---|---|
| 134 | Family-plan partner check-in | sub-card | family-plan partner logged a workout | "Jess just lifted. Send props?" |
| 135 | Family nutrition share | sub-card | dinner logged + family plan | "Share this recipe with Dad's plan?" |

### Already-built backend / unsurfaced data (gaps from code audit)

| # | Nudge | Surface | Source |
|---|---|---|---|
| 136 | Morning-brief multi-line insight (3-4 bullet chips) | sub-card | `daily_insight.py` source=morning_brief — unwired |
| 137 | Evening-recap insight | sub-card | `daily_insight.py` source=evening_recap — unwired |
| 138 | Single-line nutrition variants per meal | sub-card | `daily_insight_prompt.py` 3 distinct variants — only morning wired |
| 139 | Workout-card mode action chips (swap_to_lighter, reschedule, mark_rest_day) | sub-card | prompt defines chip kinds — not consumed |
| 140 | Daily-crate in-app pair | sub-card | TYPE_DAILY_CRATE push exists, no in-app twin |
| 141 | Daily-bundle in-app pair | sub-card | TYPE_DAILY_BUNDLE push exists, no in-app twin |
| 142 | Live-chat-message inline preview | sub-card | TYPE_LIVE_CHAT_MESSAGE push — no home preview |
| 143 | Mood-trend home sub-card | sub-card | `mood_history_provider` wired only to orphan TileType |
| 144 | Food-mood post-meal pulse | sub-card | FoodLog.mood_after + energyLevel collected — never surfaced |
| 145 | Sauna-log home tile | sub-card | `sauna_logs` migration 1874 — no home surface |
| 146 | Recipe-from-leftover prompt | sub-card | `cook_event.portions_remaining` model exists — no home prompt |
| 147 | HormoneLog symptoms aggregator | sub-card | hormonal_health.dart:555 collects symptoms — no aggregator surface |
| 148 | Blood-glucose trend mini | passive | HealthKit BLOOD_GLUCOSE read — not displayed |
| 149 | Active-energy-burned distinct micro-ring | passive | HealthKit ACTIVE_ENERGY_BURNED ingested — rolls into kcal math, no own ring |
| 150 | Cycle-day chip (day-of-cycle) | passive | MenstrualCycleLog has cycle phase + day — only phase chip shown |
| 151 | Notes field surfacing | passive | FoodLog.notes collected — no display |

---

## 9. Open questions

- **Mood check-in cadence** (#9): every foreground or once per day after sleep-wake? Industry: Daylio = once/day prompt, dismiss-able.
- **Lesson rotation** (#65, F3.60): random, or based on user's recent gaps (e.g. user has low fiber → fiber lesson)?
- **Quiet hours customization**: should the user be able to set their own quiet window? Industry default: yes (Apple Health, Garmin).
- **Sub-card cap per band**: is 6 for morning / evening the right number, or should it be lower to reduce cognitive load?
- **First-foreground-of-day rules**: should mood check-in / daily lesson / Knowledge-is-Power cards all fire on first foreground, or staggered?
- **Geofence-based nudges (#69, #70, #131, F3.124, F3.125, F3.176)**: require background location permission. Are we comfortable asking? Industry: Strava + Yelp do, MyFitnessPal doesn't.
- **CGM integration (#90, F3.145)**: would require Signos / Dexcom partnership. Defer or roadmap?
- **Calendar permission cards (#130–133, F3.186–189)**: read-only calendar permission needed; iOS prompt at first use.
- **Family-plan surfaces (#134, F3.190–191)**: do we have a family plan SKU yet? If not, gate behind that build.
- **Late-night snack alternative (#77)**: avoiding "diet culture" tone — needs sensitivity review.
- **Reward-eating risk (#109)**: same — psychology-sensitive copy. May need a way to opt out.
