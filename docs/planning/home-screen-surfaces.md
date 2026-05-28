# Zealova Home Screen — Surface Catalogue

> Single source of truth for every render branch on the Home tab. Onboarding + reference for any contributor adding to the home screen.
>
> Companion: [`home-screen-nudges-schedule.md`](./home-screen-nudges-schedule.md) — hour-by-hour view of proactive nudges (water, breakfast, etc.).

**Last updated:** 2026-05-27 · **Surface count:** 120 existing + 123 planned = **243 distinct conditional render branches**.

---

## 0. Vocabulary — three distinct nudge surfaces

The word "nudge" is used loosely in product chats; this doc fixes three precise meanings:

| Surface | Where it renders | Capacity | Lifecycle | Owned by |
|---|---|---|---|---|
| **Coach sub-card** | Inside the YOUR COACH hero card, in a horizontal `PageView` (2-per-page, swipe to next) | up to **8 / day** after ranking + cap (F4) | Per-day; resets at local midnight. Dismissed sub-cards are tracked per `dedupKey` in SharedPreferences. | `SubCardRanker` (F4) + `unified_home_widgets.dart` |
| **Stacked banner** | Between the header and the coach card | up to **3 concurrent** (per existing panel logic) | Mostly per-day; some per-week (Discord/Instagram); some persistent until acted (PR banner). Each has its own dismiss key. | `stacked_banner_panel.dart` |
| **Push notification** | OS notification tray (outside the app) | OS-rate-limited; we cap at ~3 / day per user | Backend cron + event-driven. Shares `dedupKey` with the matching in-app sub-card so dismiss in one suppresses the other for 24h. | `backend/services/notifications/` |

Within this doc, **"nudge" always means coach sub-card unless explicitly tagged `[banner]` or `[push]`**.

### Dismiss semantics

| Type | Dismiss button on widget | What happens |
|---|---|---|
| Coach sub-card | swipe / explicit ✕ if shown | suppressed for the rest of today; re-evaluates tomorrow |
| Stacked banner | ✕ at top right of each banner | suppressed per its own rule — most per-day, some per-week, some per-event |
| Onboarding card | ✕ at top right | varies — see §2.6 below for per-card lifetime |
| Push | swipe-away in OS tray | OS handles; we mark the dedupKey "seen" for 24h server-side |

### Onboarding cards — every one is dismissable

User decision: every onboarding-block card has an ✕ in the top-right and a documented persistence rule. None are "informational only / can't be dismissed".

| Surface | Dismiss UX | Persistence on dismiss |
|---|---|---|
| Calibration banner | ✕ top-right | Persisted `calibration_banner_dismissed = <date>`; never re-shows. Continues to auto-hide on day 8 regardless. |
| First-action prompt | ✕ top-right | Persisted `seen_first_action_prompt = true`; never re-shows. |
| Cycle-setup home prompt | ✕ top-right | Persisted `cycle_setup_dismissed = <date>`; re-shows after **30 days** if still not set up. |
| Setup checklist [F3.1] | ✕ top-right | Persisted `setup_checklist_snoozed_until = today + 7 days`. After 7 days, re-shows once if items still incomplete. Auto-hides permanently once `allComplete` OR `daysSinceSignup > 14`. |
| Week-1 tip banner | ✕ top-right | Per-day dismiss; rotates to next tip tomorrow. Hard-stops on day 8. |
| Notification opt-in prompt | "Not now" button | Persisted; re-prompts on day 3 + day 7 if still denied. |
| App tour spotlight | "Skip tour" link | Persisted per feature key; never re-shows that key. |

**Universal rule (all 7 cards above)**: dismissing one card does not affect the others — they each have their own persistence key namespaced with `userId`.

---

## 1. At-a-glance — top-of-tree home layout

```
┌─────────────────────────────────────────────────────────────┐
│ HEADER · greeting + streak + bell + ⚙ settings              │  always
│   "Good morning, Sai · 3d 🔥"                                │
├─────────────────────────────────────────────────────────────┤
│ STACKED BANNER PANEL · 13 dismissable banners (precedence)  │  conditional
│   (renewal · rank · crate · 2× XP · week-1 tip · contextual │
│    · wrapped · health insight · weekly plan · PR · social   │
│    · missed-workout)                                        │
├─────────────────────────────────────────────────────────────┤
│ ONBOARDING BLOCK                                            │  ≤ day 7
│   · Calibration banner                                      │
│   · First-action prompt                                     │
│   · Cycle-setup prompt (if eligible)                        │
│   · Setup checklist [NEW · F3.1]                            │
├─────────────────────────────────────────────────────────────┤
│ YOUR COACH HERO CARD                                        │  always (self-gated)
│   · Gemini-driven headline + body                           │
│   · 2 main CTAs ([Log meals] / [Ask me anything])           │
│   · 3-dot menu [NEW · F5]                                   │
│   · Sub-card PageView (2-per-page swipe) [NEW · F4]         │
│       · 💧 Overnight reset / catch-up / late-day            │
│       · 🍳 Breakfast / 🥗 Lunch / 🍽️ Dinner [NEW · F3.3]    │
│       · 🧘 Wind-down / 🌅 Tomorrow                          │
│       · …up to 8 eligible per day, ranked                   │
├─────────────────────────────────────────────────────────────┤
│ HERO WORKOUT CARD · 22 WorkoutCardMode variants             │  always
├─────────────────────────────────────────────────────────────┤
│ TODAY RINGS · Train / Nourish / Move / Sleep                │  always
│   · 5th micro-ring: Mindful Minutes [NEW · F3.40]           │
├─────────────────────────────────────────────────────────────┤
│ QUICK ACTIONS TILE ROW · 6 customizable tiles               │  always
├─────────────────────────────────────────────────────────────┤
│ WEEK STRIP · M T W T F S S with completion dots             │  conditional
├─────────────────────────────────────────────────────────────┤
│ TIMELINE · today's date-ordered event feed                  │  always
├─────────────────────────────────────────────────────────────┤
│ NUTRITION HERO · macro rings + sub-rows                     │  always
├─────────────────────────────────────────────────────────────┤
│ CONTEXTUAL CARDS (28 TileType branches via tile factory)    │  per-user-config
│   · weeklyGoals · personalRecords · aiCoachTip · sleepScore │
│   · macroRings · caloriesSummary · habitsSection · etc.     │
└─────────────────────────────────────────────────────────────┘
```

Render order is fixed; visibility per row is gated. All conditional widgets collapse to `SizedBox.shrink()` when gated false — zero layout cost, never a blank card.

---

## 2. Existing surfaces — by category

Sources: agent run `a7a908099eb45122c` (deep code inventory), plus our own audit.

### 2.1 Static chrome (always visible)

| # | Slot | File:Line | What user sees |
|---|---|---|---|
| 1 | Greeting + Streak + Bell | `lib/screens/home/widgets/minimal_header.dart` | "Good morning, {name} · Nd 🔥" + notifications bell |
| 2 | Settings cog | `minimal_header.dart` | ⚙ icon → routes to `/settings` (or the new AI Settings sheet [F5]) |
| 3 | Today rings (TodayScoreCard) | `lib/screens/home/widgets/today_score_card.dart` | 4 rings (Train/Nourish/Move/Sleep). Health Connect prompt if not connected. |
| 4 | Quick actions tile row | `lib/screens/home/widgets/components/quick_actions_row.dart` | 6 customizable tiles (Log Food / Scan Menu / Water / Weight / Snap Food / Progress Photo). User can reorder via overflow. |
| 5 | Home Timeline | `lib/screens/home/widgets/home/home_timeline.dart` | Date-ordered event feed; planned + logged items for selected date. |
| 6 | Week strip | `unified_home_widgets.dart:98-113` | M-Sun with completion dots (✓/⊙/∅); gated by `weekCalendarHiddenProvider == false` + `workoutDays.isNotEmpty`. |

### 2.2 Stacked banner panel — 13 dismissable banners

`lib/screens/home/widgets/stacked_banner_panel.dart:220-950`. Evaluated in precedence order; up to 3 concurrent rendered.

| # | Banner | Gate | Persistence |
|---|---|---|---|
| 7 | Renewal reminder | `renewal.showBanner` (within 5 days) | Auto-hides post-renewal |
| 8 | Discover rank | `discoverSnap.yourRank > 0 && cohort >= min` | Per-session dismiss |
| 9 | Daily crate | `(showCrate || unclaimedCount>0) && !dailyCrateDismissedToday` | Per-day dismiss |
| 10 | Double-XP event | `doubleXPEvent != null` | Auto-hides at event end |
| 11 | Week-1 tip | `week1Tip != null && !dismissedToday` | Per-day dismiss |
| 12 | Contextual (fasting / weekly / PR) | per-key gate | Persisted dismiss |
| 13 | Wrapped summary | `wrappedSummary != null` | Per-year |
| 14 | Health insight (HRV / RHR / sleep debt) | `healthInsight.shouldShow` | Per-day |
| 15 | Weekly plan progress | `weekday >= 4 && remaining ∈ [1..3]` | Per-week |
| 16 | Personal record | recent PR (today/yesterday) | Per-PR dismiss |
| 17 | Discord community | `daysSince >= 3 && !joined` | Per-session |
| 18 | Instagram follow | `daysSince >= 5 && !following` | Per-session |
| 19 | Missed workout (up to 3 concurrent) | per-workout-id missed window | Per workout-id dismiss |

### 2.3 Coach hero card variants (6 + 5 sub-slots existing)

`lib/screens/home/widgets/coach_hero_card.dart`. Headline + body sourced from backend `daily_insight.py` Gemini call (`source=home`).

| # | Variant | Gate |
|---|---|---|
| 20 | Default Gemini insight | always (unless dismissed today) |
| 21 | Cycle-aware variant | system prompt appends cycle phase |
| 22 | Time-of-day branch | morning/midday/afternoon/evening/late/quiet phrasing |
| 23 | Fallback deterministic | Gemini failure → highest-leverage pillar |
| 24 | Dismissed-today state | user tapped ✕ |
| 25 | Minimised state | user tapped ⌃ collapse |

**Existing sub-slots** (inside coach card, below CTAs):

| # | Sub-slot | Gate | File:Line |
|---|---|---|---|
| 26 | 💧 Overnight reset (water) | `morning && water_today < 8oz && water_tracker` | `unified_home_widgets.dart:1245` |
| 27 | 🍳 Breakfast suggestion | `morning && !breakfastLogged` | `unified_home_widgets.dart:895` |
| 28 | 💧 Late-day overnight-reset chip | `hour >= 20 && cupFraction < 0.60` | `unified_home_widgets.dart:1016` |
| 29 | 🧘 Wind-down (if exists) | `hour >= 21 && sleepTargetSet` | `unified_home_widgets.dart` |
| 30 | 🌅 Tomorrow's preview | `hour >= 22 && tomorrowWorkout != null` | `unified_home_widgets.dart` |

### 2.4 Hero workout card — 22 WorkoutCardMode variants

`lib/screens/home/widgets/workout_card_mode.dart:313-459` resolver. Each mode renders a distinct pill, body and CTA via `hero_workout_card_modes.dart`.

| # | Mode | Trigger |
|---|---|---|
| 31 | `error` | provider failure |
| 32 | `loading` | async resolving |
| 33 | `inProgress` | live session |
| 34 | `completedToday` | celebration |
| 35 | `postWorkoutRefuel` | `postWorkoutWindow == unloggedWithin30min && completed` |
| 36 | `bonus` | `(morning\|\|midday) && recovery==green && completed` |
| 37 | `vacationOrPaused` | `planState == paused` |
| 38 | `noPlan` | `planState == noPlan` |
| 39 | `overtrainingAlert` | `priorTwoDaysHardCount >= 2 && recovery == red && volumeTrend4wk == up` |
| 40 | `windDown` | `(late\|\|quiet) \|\| (evening && coachPillar=='sleep')` |
| 41 | `fastingActive` | `fastingActive && scheduledNotStarted` |
| 42 | `recoveryLighter` | `recovery == red && scheduledNotStarted` |
| 43 | `cycleAdjusted` | `cyclePhase == luteal && todayHighIntensity` |
| 44 | `preWorkoutFuelGap` | `isFuelTime && preWorkoutWindow == longGap && todayHighIntensity && !fastingActive` |
| 45 | `equipmentMismatch` | `equipmentMatch == missing && scheduledNotStarted` |
| 46 | `comebackSession` | `daysSincePrimaryMuscleGroup > 10 && scheduledNotStarted` |
| 47 | `prOpportunityToday` | `hasPrOpportunityToday && recovery != red` |
| 48 | `scheduledNotStarted` | default happy path |
| 49 | `nextWorkoutInFuture` | `none && hasNextWorkout` |
| 50 | `nothingScheduled` | `none && !hasNextWorkout` |
| 51 | `restDayWithCoach` | `restDay && !(yesterdayMissed && isRecoveryWindow)` |
| 52 | `yesterdayMissedRecovery` | `restDay && yesterdayMissed && (morning\|\|midday)` |

### 2.5 Tile factory branches (28 cases, `tile_factory.dart:28-228`)

Active tiles only — `SizedBox.shrink()` placeholders for unbuilt features are omitted from this count.

| # | Tile | Widget |
|---|---|---|
| 53 | `nextWorkout` | NextWorkoutCard with tour key |
| 54 | `quickActions` | QuickActionsRow (in #4 above) |
| 55 | `weeklyGoals` | WeeklyGoalsCard |
| 56 | `upcomingWorkouts` | slice of 3 |
| 57 | `personalRecords` | DeloadRecommendationCard + PersonalRecordsCard |
| 58 | `aiCoachTip` | SmartInsightCard + AICoachTipCard |
| 59 | `caloriesSummary` | CaloriesSummaryCard |
| 60 | `macroRings` | MacroRingsCard |
| 61 | `fasting` | FastingTimerCard |
| 62 | `sleepScore` | HealthInsightCard + LastNightSleepCard |
| 63 | `achievements` | AchievementsSection |
| 64 | `quickLogWeight` | QuickLogWeightCard |
| 65 | `habits` | HabitsSection |
| 66 | `todayStats` | TodayStatsRow |
| 67 | `stepsCounter` | DailyStepsTile OR CombinedHealthCard+TodaysHealthCard |
| 68 | `nutritionPatterns` | top draining food OR first-time CTA |

### 2.6 Onboarding (day 1–7 surfaces)

| # | Surface | Gate | File |
|---|---|---|---|
| 69 | CalibrationBanner | `daysSinceSignup ≤ 7` | `calibration_banner.dart` |
| 70 | FirstActionPrompt | `!seen_first_action_prompt` | `first_action_prompt.dart` |
| 71 | CycleSetupHomePrompt | `!menstrualTrackingEnabled && cycle_capable && !dismissed` | `cycle_setup_home_prompt.dart` |
| 72 | Week1TipBanner | `week1Tip != null && !dismissedToday` | `week1_tip_banner.dart` |
| 73 | App tour overlay | `AppTour.unseen(featureKey)` | `widgets/app_tour/` |
| 74 | Notification opt-in prompt | day 1 if denied | `widgets/notification_permission_prompt.dart` |

### 2.7 Subscription / paywall

| # | Surface | Gate |
|---|---|---|
| 75 | Trial progress widget | `billingPeriod == "trial"` |
| 76 | Renewal reminder banner | see #7 |
| 77 | Premium feature teasers | gated content access attempts |

### 2.8 Health alerts (wearable-gated)

| # | Surface | Gate |
|---|---|---|
| 78 | Recovery score (green/yellow/red) | HRV+RHR+sleep composite available |
| 79 | HRV drop alert | `hrv_today < baseline - 1 SD` (30-day window) |
| 80 | RHR elevation alert | `rhr_today >= baseline + 5 bpm` |
| 81 | Sleep debt > 2h | computed from 7-day average vs target |
| 82 | Body Battery low | <50 |
| 83 | Last-night sleep score tile | `lastNightSleepData != null` |

### 2.9 Cycle phase content

| # | Surface | Gate |
|---|---|---|
| 84 | Phase chip on workout card | small badge for high-intensity in non-optimal phase |
| 85 | CycleStatusCard | `menstrualTrackingEnabled` |
| 86 | Cycle setup prompt | see #71 |

### 2.10 Streak / gamification / social

| # | Surface | Gate |
|---|---|---|
| 87 | Streak chip in header | `streakDays > 0` |
| 88 | XP earned animation | level-up event (see F1 fix) |
| 89 | Daily login result | first foreground of day |
| 90 | Trophy ceremony overlay | achievement unlock |
| 91 | Pending celebrations queue | multi-event queue |
| 92 | Discord community CTA | see #17 |
| 93 | Instagram follow CTA | see #18 |
| 94 | Wrapped reveal | year-end |

### 2.11 Empty / error / disconnected states

| # | State | Surface |
|---|---|---|
| 95 | Workout card loading | skeleton |
| 96 | Workout card error | retry button |
| 97 | TodayScoreCard disconnected | "Connect Apple Health / Health Connect" pill |
| 98 | Hero card no-image fallback | accent gradient |
| 99 | CombinedHealthCard hidden | `!healthSync.isConnected` |
| 100 | EmptyWorkoutCard | "Nothing scheduled today · Generate" |

### 2.12 Quick actions / AI surfaces

| # | Surface | Gate |
|---|---|---|
| 101 | Quick actions tile row | see #4 |
| 102 | Ask coach floating pill (Home tab only) | `selectedIndex == 0 && isNavBarVisible` |
| 103 | Floating chat bubble | opt-in via Settings → AI Coach |
| 104 | Voice note CTA in coach card | when applicable |
| 105 | Photo log CTA in coach card refuel mode | post-workout window |

### 2.13 Travel / vacation / sick (partial today)

| # | Surface | Gate |
|---|---|---|
| 106 | Vacation mode | `planState == paused` → vacationOrPaused workout-card variant |

### 2.14 Static "coming soon" placeholders (rendered as SizedBox.shrink today)

| # | TileType | Notes |
|---|---|---|
| 107 | `quickStart` | placeholder |
| 108 | `fitnessScore` | placeholder |
| 109 | `moodPicker` | placeholder — F3.39 will materialise this |
| 110 | `dailyActivity` | placeholder |
| 111 | `weeklyProgress` | removed; replaced by F3.70 |
| 112 | `weekChanges` | placeholder |
| 113 | `upcomingFeatures` | removed |
| 114 | `streakCounter` | deprecated |
| 115 | `challengeProgress` | placeholder |
| 116 | `bodyWeight` | placeholder |
| 117 | `progressPhoto` | placeholder — F3.122 will materialise |
| 118 | `socialFeed` | placeholder — F3.52–55 will materialise |
| 119 | `leaderboardRank` | placeholder — F3.49 will materialise |
| 120 | `weeklyCalendar` | placeholder — F3.70 will materialise |

---

## 3. Planned surfaces (F3.1 – F3.123) — by phase

All marked **[NEW · Phase X]**. Each row: ID, Surface, Gate, What user sees, Mounting widget.

### Phase A · Quick wins (4)

| ID | Surface | Gate | What user sees |
|---|---|---|---|
| F3.1 | Setup checklist (Day 1–7) [NEW · A] | `daysSinceSignup ≤ 7 && !allComplete` | Card listing 6 setup items with ✓/○ + progress bar. Mounts above coach card. |
| F3.2 | Streak-at-risk push (historical+2h) [NEW · A] | `historicalCompletionTime + 2h reached && no log today` | Stacked-banner row "Streak at risk · log to keep". |
| F3.3 | 🥗 Lunch suggestion sub-slot [NEW · A] | `midday && !lunchLogged` | Inside coach card. Macros from remaining budget. |
| F3.3 | 🍽️ Dinner suggestion sub-slot [NEW · A] | `evening && !dinnerLogged` | Inside coach card. |
| F3.4 | 💧 Midday hydration catch-up chip [NEW · A] | `(midday\|\|afternoon) && cupFraction < 0.40 && hours_since_last_log ≥ 2` | "Catch up · {logged}oz / {goal}oz · [Log 8oz]" |

### Phase B · Recovery & physiological (9)

| ID | Surface | Gate |
|---|---|---|
| F3.5 | Daily Readiness Score card [NEW · B] | `hrvProvider + rhrProvider + lastNightSleep` data available |
| F3.6 | HRV trend strip (7-day sparkline) [NEW · B] | `hrvData.length >= 7` |
| F3.7 | RHR anomaly chip (illness warning) [NEW · B] | `rhr_today ≥ baseline + 5 && rhr_yesterday ≥ baseline + 3` |
| F3.8 | Respiratory rate spike chip [NEW · B] | `resp_today ≥ baseline + 2 bpm` |
| F3.9 | Body Battery gauge tile [NEW · B] | sleep + HRV + RHR composite available |
| F3.10 | Daytime Stress score tile [NEW · B] | HRV+RHR waking-hours composite |
| F3.11 | REM/Deep balance call-out [NEW · B] | `REM% < 18 \|\| Deep% < 13` |
| F3.12 | VO2max trend chip [NEW · B] | HealthKit/Health Connect VO2 data |
| F3.13 | Skin-temperature deviation alert [NEW · B] | `temp_today - baseline > 0.5 °C` |

### Phase C · Nutrition / metabolic (8)

| ID | Surface | Gate |
|---|---|---|
| F3.14 | Micronutrient gap of the day [NEW · C] | 2+ meals logged AND lowest_micro_coverage < 50% |
| F3.15 | Adaptive calorie target shift banner [NEW · C] | 3+ weeks weight-trend settled AND deviates from goal trajectory |
| F3.16 | Fiber gap chip [NEW · C] | `meals_today ≥ 3 && fiber_today < 0.5 × goal && hour > 16` |
| F3.17 | Post-workout protein deficit nudge [NEW · C] | workout done && protein_today < target && last_log > 1h |
| F3.18 | Caffeine cutoff warning [NEW · C] | caffeine logged after 14:00 AND yesterday sleep < 70 |
| F3.19 | Planned indulgence / refeed day [NEW · C] | in deficit ≥ 14 days AND goal == loseFat |
| F3.20 | Smoothed weight trend chip [NEW · C] | 7+ weigh-ins in last 14 days |
| F3.21 | Sweat-day electrolyte chip [NEW · C] | hot weather OR cardio > 45 min OR sauna log |

### Phase D · Movement non-workout (5)

| ID | Surface | Gate |
|---|---|---|
| F3.22 | Hourly Stand reminder [NEW · D] | `lastMovementAt < now-50min && hour ∈ [7..21]` |
| F3.23 | Daily step streak tile [NEW · D] | step data available |
| F3.24 | Intensity / Zone Minutes weekly bar [NEW · D] | zone-min data available |
| F3.25 | Active calorie micro-ring (Apple Move) [NEW · D] | HealthKit active-cal data |
| F3.26 | Long-sit walk-break suggestion [NEW · D] | >90 min continuous sitting |

### Phase E · Sleep / circadian (5)

| ID | Surface | Gate |
|---|---|---|
| F3.27 | Bedtime window countdown [NEW · E] | `now ≥ sleepTarget - 90min` |
| F3.28 | Wake-consistency score tile [NEW · E] | 7+ days of wake-time data |
| F3.29 | Sleep-latency tile [NEW · E] | sleep onset data available |
| F3.30 | Blue-light cutoff reminder [NEW · E] | `now == sleepTarget - 60min` |
| F3.31 | Chronotype-aware copy [NEW · E] | wake-time pattern detected |

### Phase F · Cycle / hormonal (7)

| ID | Surface | Gate |
|---|---|---|
| F3.32 | Cycle phase chip on home [NEW · F] | `menstrualTrackingEnabled` |
| F3.33 | Period prediction countdown [NEW · F] | `daysToNextPeriod ≤ 5` |
| F3.34 | PMS prep card [NEW · F] | last 5 days of luteal phase |
| F3.35 | Ovulation-peak strength window [NEW · F] | ovulation ± 2 days |
| F3.36 | Period-symptom one-tap log [NEW · F] | during menstrual phase |
| F3.37 | Pregnancy mode [NEW · F] | `pregnancyModeOn` user setting |
| F3.38 | Perimenopause cues [NEW · F] | `age > 40 && cycle_variability > 5 days` |

### Phase G · Mental health / mindfulness (6)

| ID | Surface | Gate |
|---|---|---|
| F3.39 | Daily mood check-in strip [NEW · G] | always |
| F3.40 | Mindful Minutes 5th micro-ring [NEW · G] | mindfulness data tracked |
| F3.41 | Contextual breathwork CTA [NEW · G] | stress score elevated OR HRV dropped |
| F3.42 | Daily meditation tile [NEW · G] | always (content rotates) |
| F3.43 | Gratitude / journal prompt (evening) [NEW · G] | `hour ≥ 20` |
| F3.44 | Evening sleep-story tile [NEW · G] | `hour ≥ 21` |

### Phase H · Hydration extras (2)

| ID | Surface | Gate |
|---|---|---|
| F3.45 | Weather/heat-adjusted hydration goal [NEW · H] | temp > 28 °C |
| F3.46 | Electrolyte-specific tile [NEW · H] | sauna/heavy-cardio frequency user |

### Phase I · Habit / gamification (5)

| ID | Surface | Gate |
|---|---|---|
| F3.47 | Streak freeze inventory display [NEW · I] | streak > 0 AND freezes available |
| F3.48 | Daily Quest deck (3 quests/day) [NEW · I] | always (rotates) |
| F3.49 | League / cohort rank tile [NEW · I] | enrolled in active league |
| F3.50 | Monthly quest tile [NEW · I] | always (rotates monthly) |
| F3.51 | Achievement-near-unlock chip [NEW · I] | within 3 events of unlock |

### Phase J · Social (4)

| ID | Surface | Gate |
|---|---|---|
| F3.52 | Friend activity snippet [NEW · J] | friends count > 0 AND friend active today |
| F3.53 | Kudos count dot [NEW · J] | unread kudos > 0 |
| F3.54 | Group challenge progress bar [NEW · J] | enrolled in active group challenge |
| F3.55 | Accountability-partner check-in nudge [NEW · J] | partner active today AND user not |

### Phase K · Subscription (3)

| ID | Surface | Gate |
|---|---|---|
| F3.56 | Usage-based upsell [NEW · K] | free user AND power-user signal |
| F3.57 | Referral / gift Premium [NEW · K] | always (rotates rate-limited) |
| F3.58 | Premium content preview [NEW · K] | free user (1/day rotation) |

### Phase L · Educational (4)

| ID | Surface | Gate |
|---|---|---|
| F3.59 | Knowledge-is-Power 3 daily cards [NEW · L] | always (rotates) |
| F3.60 | Daily lesson tile [NEW · L] | content available |
| F3.61 | Sunday Weekly Digest tile [NEW · L] | `weekday == 0` |
| F3.62 | Discovery insight feed [NEW · L] | pattern detected for user |

### Phase M · Milestones (3)

| ID | Surface | Gate |
|---|---|---|
| F3.63 | App-anniversary card [NEW · M] | `daysSinceSignup ∈ {365, 730, …}` |
| F3.64 | Workout-count milestone [NEW · M] | `totalWorkouts ∈ {10,25,50,100,250,500}` |
| F3.65 | Body-composition milestone [NEW · M] | weight delta crosses {1,5,10,20} kg |

### Phase N · Equipment / wearable (3)

| ID | Surface | Gate |
|---|---|---|
| F3.66 | Wearable battery low chip [NEW · N] | battery % < 20 |
| F3.67 | Scale sync prompt [NEW · N] | paired scale + no weigh-in 7d |
| F3.68 | Missing-data nudge [NEW · N] | data hole > 24h |

### Phase O · Schedule / planning (5)

| ID | Surface | Gate |
|---|---|---|
| F3.69 | Tomorrow's preview tile [NEW · O] | `hour ≥ 20` AND tomorrowWorkout exists |
| F3.70 | Weekly plan progress strip [NEW · O] | program active |
| F3.71 | Missed-meal catch-up window [NEW · O] | meal time passed > 90 min AND not logged |
| F3.72 | Smart rescheduling proposal [NEW · O] | missed workout AND today < 60 min recovery |
| F3.73 | Pre-workout fuel timing card [NEW · O] | workout in 60–90 min |

### Phase P · AI pattern detection (4)

| ID | Surface | Gate |
|---|---|---|
| F3.74 | Day-of-week skip pattern [NEW · P] | missed dayX ≥ 60% past 8 weeks |
| F3.75 | Workout-time → sleep correlation [NEW · P] | 4+ weeks paired data |
| F3.76 | Macro-pattern callout [NEW · P] | 3-week macro pattern detected |
| F3.77 | Strain ↔ recovery mismatch [NEW · P] | strain rising AND recovery flat 3 weeks |

### Phase Q · Injury (2)

| ID | Surface | Gate |
|---|---|---|
| F3.78 | Return-to-exercise progression card [NEW · Q] | active injury logged |
| F3.79 | Affected-muscle workaround surfacing [NEW · Q] | today's workout hits active injury |

### Phase R · Travel (2)

| ID | Surface | Gate |
|---|---|---|
| F3.80 | Jet-lag adjust card [NEW · R] | timezone changed > 3h in past 7 days |
| F3.81 | Busy-week compressed-workout mode [NEW · R] | calendar-detected travel OR user toggle |

### Phase S · Special days (3)

| ID | Surface | Gate |
|---|---|---|
| F3.82 | Birthday card [NEW · S] | `today == birthday` |
| F3.83 | Weigh-in day reminder [NEW · S] | weekly weigh-in day AND not weighed |
| F3.84 | First-of-month reset [NEW · S] | `day == 1` |

### Phase T · Onboarding leftovers (4)

| ID | Surface | Gate |
|---|---|---|
| F3.85 | Sticky connect-a-wearable tile [NEW · T] | `!healthSyncConnected && daysSinceSignup > 1` |
| F3.86 | Day 2-7 tutorial cards [NEW · T] | `daysSinceSignup ∈ [2..7]` |
| F3.87 | Day-14 goal-recalibration prompt [NEW · T] | `daysSinceSignup == 14` |
| F3.88 | Coach-persona pick-up tile if skipped [NEW · T] | onboarding done + persona == default |

### Phase U · Fasting (11)

| ID | Surface | Gate |
|---|---|---|
| F3.89 | Approaching-end nudge [NEW · U] | `fastingActive && remaining < 60min` |
| F3.90 | Refeed window state [NEW · U] | fast ended in last 2h |
| F3.91 | Length-adapted post-fast guidance [NEW · U] | post-fast, branch on length |
| F3.92 | Zone-progression strip on home tile [NEW · U] | `fastingActive` |
| F3.93 | Fasting Live Activity / iOS home widget [NEW · U] | iOS only, fastingActive |
| F3.94 | `fastedTrainingWarningsOn` wiring [NEW · U] | toggle ON AND workout during fast |
| F3.95 | Pre-fast countdown [NEW · U] | scheduled fast in next 60 min |
| F3.96 | Extend-current-fast CTA [NEW · U] | now >= scheduledEnd && fastingActive |
| F3.97 | Protein-target shift on fast days [NEW · U] | active fast in user's day |
| F3.98 | "You broke earlier than planned" acknowledgement [NEW · U] | meal logged before scheduledEnd |
| F3.99 | Fast-streak independent from workout streak [NEW · U] | always (when fasting tracked) |

### Phase V · Pre-workout (11)

| ID | Surface | Gate |
|---|---|---|
| F3.100 | T-30m band on hero card [NEW · V] | workout in next 30 min |
| F3.101 | Warm-up visible on hero card [NEW · V] | workout scheduled today |
| F3.102 | RPE / target effort chip [NEW · V] | workout scheduled today |
| F3.103 | Honest variant-swap CTAs [NEW · V] | always (replaces snackbar stubs) |
| F3.104 | Skippable mood check-in [NEW · V] | pre-workout |
| F3.105 | Caffeine timing relative to workout [NEW · V] | caffeine logged AND workout scheduled |
| F3.106 | Hydration target shown pre-workout [NEW · V] | workout in next 60 min |
| F3.107 | Expected duration / calories / HR-zone preview [NEW · V] | workout scheduled today |
| F3.108 | Daily strain target [NEW · V] | recovery data available |
| F3.109 | Pre-fuel macro target [NEW · V] | high-intensity workout in 60-90 min |
| F3.110 | Equipment pre-flight [NEW · V] | workout uses unavailable equipment |

### Phase W · Post-workout (13)

| ID | Surface | Gate |
|---|---|---|
| F3.111 | Training Effect / strain delta [NEW · W] | workout completed today |
| F3.112 | Recovery-time countdown [NEW · W] | workout completed today |
| F3.113 | Concrete protein-grams target on refuel [NEW · W] | workout completed, refuel window |
| F3.114 | Planned-vs-actual delta sub-card [NEW · W] | workout completed today |
| F3.115 | Live PR banner during a set [NEW · W] | inside active workout |
| F3.116 | Tomorrow auto-adjust [NEW · W] | high-strain workout completed |
| F3.117 | Kudos / social loop [NEW · W] | workout completed AND friends > 0 |
| F3.118 | HR-zone breakdown [NEW · W] | workout completed with HR data |
| F3.119 | Mood-post-workout one-tap log [NEW · W] | workout completion screen |
| F3.120 | RHR delta during workout [NEW · W] | workout with HR data |
| F3.121 | 1RM recompute notification [NEW · W] | working sets meet threshold |
| F3.122 | Progress-photo prompt post-workout [NEW · W] | weekly photo day |
| F3.123 | Workout-felt journal prompt [NEW · W] | workout completion screen |

---

### Phase X · Pre-meal, cooking, grocery (10) — round 2 of research

| ID | Surface | Gate · Copy · Ref |
|---|---|---|
| F3.124 | Grocery-store geofence reminder | inside grocery polygon + unchecked items. "At Trader Joe's. 7 items still on the list." Ref: AnyList |
| F3.125 | Restaurant pre-order menu scan | restaurant geofence dwell >90s + no recent food log. "Scan the menu before you order — I'll flag the protein winners." |
| F3.126 | Batch-cook Sunday slot | Sunday 9–2 + free calendar block ≥2h + 3+ planned dinners. "2-hour gap Sunday. Batch-cook Mon-Wed now?" |
| F3.127 | Leftover countdown / food-safety | cook event ≥3 days old + portions_remaining>0. "Tuesday's chili expires today — log a serving?" |
| F3.128 | Hidden-sugar warning post-scan | just-logged packaged food >12g added sugar/serving. "18g added sugar in that. Want a swap?" |
| F3.129 | Sodium cap watch | cumulative sodium ≥2000mg by 4pm. "Salt's at 2,100mg. Lean dinner tonight." |
| F3.130 | Fiber gap by meal | any meal <4g fiber. "Lunch was 2g fiber. Toss a fruit at snack?" |
| F3.131 | Protein gap by meal | any meal <15g protein. "Breakfast came in at 9g protein. Add Greek yogurt?" |
| F3.132 | Late-night snack alternative | log attempt 21:00+ on >300kcal item. "Swap to cottage cheese + berries — sleep-friendly." |
| F3.133 | Ingredient running low | pantry item count ≤1 + in this week's planned recipe. "Out of oats by Thursday. Add to list?" |

### Phase Y · Mid-workout (8)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.134 | Mid-session hydration | workout duration >25min + no in-workout water log. "Sip break." · `[+8oz]` |
| F3.135 | Cool-down stretch reminder | workout marked done + HR still >60% MHR. "60s of cool-down keeps the gains." |
| F3.136 | Variation prompt — 3 sessions same lift | same exercise_id logged 3 consecutive sessions. "Bench 3 days running — sub incline today?" |
| F3.137 | Set rest exceeded | rest timer >180% of programmed rest. "Still resting? Tap Done when back." |
| F3.138 | Inter-set RPE check | 2 sets logged, RPE field empty. "How hard was that set?" (6/7/8/9/10 chips) |
| F3.139 | Late-workout sleep impact warning | workout start <90 min before bedtime. "Heavy at this hour can cost 30min deep sleep. Switch to mobility?" |
| F3.140 | Music/podcast resume | last session had Spotify/Apple Music handoff. "Pick up where you left off?" `[Resume playlist]` |
| F3.141 | Partner-watching-live | friend/coach opens shared workout view. "Sarah is watching this session." (passive banner sub-row) |

### Phase Z · Macro / weight specific advanced (7)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.142 | Deficit-too-aggressive warning | 14-day rolling deficit >25% TDEE OR weight loss >1% bw/wk for 2 wks. "Cutting harder than the plan. Refeed Friday?" Ref: MacroFactor |
| F3.143 | Refeed needed signal | 10+ days deficit + HRV ↓ + energy ≤2. "Body's asking for fuel. Maintenance day tomorrow?" |
| F3.144 | Carb cycling reminder | high-intensity day tomorrow, today is rest. "Tomorrow's leg day — bump carbs at dinner." |
| F3.145 | Sugar spike prediction (CGM-aware) | predicted ΔBG >40 mg/dL based on user history. "This combo usually spikes you. 10-min walk after?" Ref: Signos |
| F3.146 | Adaptive expenditure adjustment | weekly TDEE model shifted ≥75 kcal. "TDEE updated to 2,310. Targets adjusted." Ref: MacroFactor V3 |
| F3.147 | Weigh-in fluctuation explainer | weigh-in swings ±0.8% bw. "Up 1.2 lb — likely sodium from yesterday's takeout." |
| F3.148 | Body-recomp signal | weight flat 4wks + waist ↓ + lifts ↑. "Scale stuck, but shrinking and stronger — that's recomp." |

### Phase AA · Recovery / wearable advanced (8)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.149 | Sauna / cold-shower nudge | hard session done + sauna habit ≥3x/30d. "10-min sauna tonight tops off recovery." |
| F3.150 | Foam-roll reminder | DOMS likely (volume >120% 4wk avg). "Quads will hate tomorrow. 5min roll?" |
| F3.151 | Active recovery on rest day | rest day + steps <3k by 5 PM. "Light 20-min walk = better tomorrow." |
| F3.152 | Aerobic decoupling alert | HR drift >5% vs pace last cardio. "HR drifted from pace — fatigue or heat." Ref: Strava Athlete Intelligence |
| F3.153 | RHR spike during rest week | RHR +5 vs 14d baseline on rest day. "Resting HR elevated. Sickness or stress?" |
| F3.154 | Sleep efficiency drop | 3-night rolling efficiency <80%. "Time in bed up, sleep down. Caffeine cutoff at 2 PM?" Ref: Oura |
| F3.155 | Social jetlag warning | weekend bedtime >90min later than weekday avg. "Weekends are giving you Monday jet lag." |
| F3.156 | Deload-week suggestion | E1RM drop ≥5% across 2 wks at same RPE. "Lifts slipping at the same RPE. Deload week Monday?" |

### Phase BB · Cognitive / habit advanced (6)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.157 | Habit-stack suggestion | habit A completed 5+ days at same time. "You always coffee at 7am. Stack 5-min mobility on top?" Ref: Fogg model |
| F3.158 | Boredom / disengagement signal | app opens <2 in 72h after weeks of daily. "Quick win — log 1 thing today." (no streak guilt) |
| F3.159 | Mindful-eating slowdown | meal logged <8min after previous bite log. "Eating fast — try one chew-only minute." |
| F3.160 | Phone-free meal challenge | meal-time at home + screen-time API shows phone use during last meal. "Phone down for dinner?" `[Start 30-min timer]` |
| F3.161 | Weekly reflection prompt | Sunday 7 PM. "Three words for the week?" `[Voice journal]` |
| F3.162 | Gratitude streak prompt | last gratitude log >48h. "What landed well today?" |

### Phase CC · Emotion / energy / safety (6)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.163 | Energy-crash prediction | lunch was >70% refined carbs + low protein. "Expect 3pm slump. 10-min walk + water at 2:45?" |
| F3.164 | Stress-eating risk | HRV crash + last meal <90min ago + history of evening grazing. "Stress + appetite pattern — tea + 4-7-8 breath?" |
| F3.165 | Reward-eating risk post-PR | just-logged big PR + dinner not yet planned. "Don't out-eat the PR. Plan dinner now?" |
| F3.166 | Migraine trigger log | user has migraine pattern tag. "Sleep <6h + skipped breakfast = your migraine combo. Eat now?" |
| F3.167 | Allergy-season heads-up | local pollen ≥high + outdoor session planned. "Pollen spike — indoor or pre-medicate." |
| F3.168 | Medication reminder coupling | paired Rx schedule + scheduled supplement. "Iron + vit C window opens in 10min." |

### Phase DD · Goal / contract (4)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.169 | Goal halfway nudge | 50% of timeline elapsed. "Halfway to your 20-lb goal. 11.4 lb to go." |
| F3.170 | Goal slipping warning | 4-week rate <40% of target rate. "Pace half what we planned. Tighten or extend?" |
| F3.171 | Monthly review | 1st of month. "April recap ready — 60s read." (sub-card, distinct from #53 banner) |
| F3.172 | Race countdown | registered event T-14 to T-1. "14 days to the 10K. Taper Friday." |

### Phase EE · Specialty diets (4)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.173 | Keto carb-spike alert | logged meal >25g net carbs + keto goal active. "That broke ketosis math. Walk it off?" |
| F3.174 | Vegan B12 reminder | 5-day rolling B12 <50% RDA. "B12 low all week. Fortified plant milk or supplement?" |
| F3.175 | IF break-fast window opening | T-15min to user's eating window. "Window opens at 12:00. Pre-pour water now." |
| F3.176 | Halal/kosher/dietary-tag meal find | restaurant geofence + dietary tag set. "Halal options at this venue: 4." (Yelp API) |

### Phase FF · Aerobic / cardio (3)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.177 | Zone 2 minutes today | rolling Z2 <150min last 7d. "30min easy spin tonight = Z2 target hit." |
| F3.178 | VO2max-day suggestion | 14d since last threshold session + recovered. "Body primed for 5×3min VO2 workout." |
| F3.179 | Fitness-test reminder | 8 wks since last benchmark. "Re-test 5K? See real progress." |

### Phase GG · PCOS / hormonal disorders (3)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.180 | Insulin-friendly breakfast (PCOS) | PCOS tag + breakfast attempt + last AM meal spiked. "Protein + fat first — eggs over oats today." Ref: PCOS Pal |
| F3.181 | Inositol reminder | supplement scheduled. "Inositol — 15min before lunch." |
| F3.182 | Cycle irregularity acknowledgement | 2 consecutive cycles >35d apart. "Cycle running long. Want a hormone-focused plan?" |

### Phase HH · Men's hormonal (3)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.183 | Morning-erection marker (opt-in T-tracking) | opt-in + AM log window. "Quick T-marker check?" (Y/N) Ref: Mojo / Aware |
| F3.184 | Cortisol cap | HRV ↓ + sleep <6h + steps high. "Cortisol-load day — skip caffeine after noon." |
| F3.185 | Zinc/Mg nutrition prompt | 7d rolling Zn/Mg <60% RDA. "Pumpkin seeds or oysters this week." |

### Phase II · Calendar integration (4)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.186 | Meeting-heavy day → lighter workout | ≥5h meetings + ≥3 back-to-backs. "Meeting marathon — 25-min mobility instead of leg day?" |
| F3.187 | Lunch-meeting menu pre-scout | 'lunch' titled calendar event + restaurant likely. "Pre-scout the menu?" `[Scan menu]` |
| F3.188 | Free 30-min block hold | gap ≥30min between meetings + no session today. "30-min window at 2pm. Hold for a quick lift?" |
| F3.189 | End-of-workday wind-down | last meeting ended + bedtime <4h. "Clock-out: 10-min walk to flip the switch." |

### Phase JJ · Family / dependent (2)

| ID | Surface | Gate · Copy |
|---|---|---|
| F3.190 | Family-plan partner check-in | family-plan partner logged a workout. "Jess just lifted. Send props?" |
| F3.191 | Family nutrition share | dinner logged + family plan. "Share this recipe with Dad's plan?" |

### Phase KK · Backend-enabled but not wired (already-built insight types)

These are infrastructure gaps from the code audit — backend serves them today, frontend doesn't consume.

| ID | Surface | Source |
|---|---|---|
| F3.192 | Morning-brief multi-line insight | `daily_insight.py:51-114` supports `source="morning_brief"` (5–10 AM, 3-4 bullet chips) — not currently requested by home |
| F3.193 | Evening-recap insight | `daily_insight.py:153-163` supports `source="evening_recap"` (20–22 local) — not currently requested |
| F3.194 | Nutrition_card_morning/lunch/dinner single-line | `daily_insight_prompt.py:182-211` defines 3 distinct single-line variants per meal — only `nutrition_card_morning` is wired |
| F3.195 | Workout-card mode justifications (swap_to_lighter, reschedule, mark_rest_day action chips) | `daily_insight_prompt.py:213-225` defines chip-action kinds — not consumed |
| F3.196 | Daily-crate in-app sub-card pair | `notification_service_helpers_part2.py` sends `TYPE_DAILY_CRATE` push only; no in-app sub-card pair |
| F3.197 | Daily-bundle in-app sub-card pair | same — `TYPE_DAILY_BUNDLE` push has no in-app twin |
| F3.198 | Live-chat-message inline preview | `TYPE_LIVE_CHAT_MESSAGE` push has no home preview surface |
| F3.199 | Mood-trend home sub-card | `mood_history_provider.dart` fully wired but only consumed by orphan `TileType.moodPicker` |
| F3.200 | Food-mood post-meal pulse | `FoodLog.moodAfter` + `FoodLog.energyLevel` collected on every meal — never surfaced |
| F3.201 | Sauna-log home tile | `sauna_logs` table (migration 1874) collected — no home surface |
| F3.202 | Recipe-from-leftover prompt | `cook_event` portions_remaining model exists — no home prompt referencing it |
| F3.203 | HormoneLog symptoms sub-card | `hormonal_health.dart:555` HormoneLog collects libido/motivation/stress/symptoms — no aggregator surface |
| F3.204 | Blood-glucose trend mini | HealthKit BLOOD_GLUCOSE read but not displayed |
| F3.205 | Active-energy-burned distinct micro-ring | HealthKit ACTIVE_ENERGY_BURNED ingested but rolls into calorie math; no standalone ring |
| F3.206 | Cycle-day chip with day-of-cycle | `MenstrualCycleLog` has cycle phase + day; only phase chip shown |

**Total new surfaces (F3.124 – F3.206): 83.** Combined with F3.1–F3.123: **206 planned surfaces** layered onto the 120 existing ones — **326 total when shipped**.

---

## 4. Sub-card ranking algorithm (F4 spec)

### 4.1 Priority pyramid (default)

```
Priority 1 — HEALTH ALERTS  (anomalies, illness early-warning)
  • RHR anomaly (F3.7), HRV drop, respiratory rate spike (F3.8),
    skin-temp deviation (F3.13), overtrainingAlert workout-mode

Priority 2 — TIME-SENSITIVE  (perishable opportunity)
  • Post-workout refuel window (existing, F3.113)
  • Pre-workout fuel gap (F3.109), pre-workout T-30 (F3.100)
  • Fasting approaching-end (F3.89), refeed window (F3.90)
  • Bedtime window countdown (F3.27), blue-light cutoff (F3.30)
  • PR opportunity today (existing)

Priority 3 — STREAK-AT-RISK  (loss-aversion)
  • Streak-at-risk push (F3.2)
  • 23:00 last-chance push (F3.2)
  • Achievement-near-unlock (F3.51)

Priority 4 — HABIT NUDGES  (routine reinforcement)
  • Overnight reset water (existing), midday catch-up (F3.4),
    late-day reset (existing)
  • Breakfast / lunch / dinner suggestions (existing + F3.3)
  • Hourly stand reminder (F3.22)
  • Mood check-in (F3.39)

Priority 5 — EDUCATIONAL  (passive learning)
  • Knowledge-is-Power cards (F3.59)
  • Daily lesson (F3.60)
  • Discovery insight feed (F3.62)
  • Daily meditation (F3.42)

Priority 6 — SOCIAL  (lowest perishability)
  • Friend activity snippet (F3.52)
  • Group challenge (F3.54)
  • Accountability partner nudge (F3.55)
```

### 4.2 Algorithm pseudocode

```dart
class SubCardCandidate {
  final String id;                 // dedupKey
  final int priorityTier;          // 1..6
  final DateTime perishesAt;       // when this card stops being relevant
  final String category;           // for user-override weighting
  final Widget render(BuildContext);
}

class SubCardRanker {
  static const int kDailyCap = 8;
  
  List<SubCardCandidate> rank(
    List<SubCardCandidate> eligible,
    Map<String,int> userPriorityOverrides,
    Set<String> shownDedupKeysThisWeek,
  ) {
    // 1. De-dupe — skip cards user already saw + acted on this week
    eligible = eligible.where((c) => !shownDedupKeysThisWeek.contains(c.id));
    
    // 2. Apply user-override re-weighting (Settings → AI Settings → priorities)
    eligible = eligible.map((c) => c.copyWith(
      priorityTier: userPriorityOverrides[c.category] ?? c.priorityTier,
    ));
    
    // 3. Sort: priority tier asc, then perishesAt asc (sooner-perishing first)
    eligible.sort((a, b) {
      final p = a.priorityTier.compareTo(b.priorityTier);
      if (p != 0) return p;
      return a.perishesAt.compareTo(b.perishesAt);
    });
    
    // 4. Cap at kDailyCap = 8
    return eligible.take(kDailyCap).toList();
  }
}
```

### 4.3 User override semantics

`Settings → AI Settings → Nudge category priorities` exposes a drag-rank list. Persisted to `aiSettingsProvider.nudgeCategoryPriorities` (Map<String, int>). The ranker reads this and overrides default `priorityTier` per category. Categories: `health_alert`, `time_sensitive`, `streak`, `habit`, `educational`, `social`.

If the user demotes `habit` from 4 → 6, a 7 AM eligible-set of `[breakfast(4), water(4), step-stand(4), gratitude(5)]` becomes `[gratitude(5), breakfast(6), water(6), step-stand(6)]` and surface order shifts.

### 4.4 Render: PageView + dots

```dart
PageView.builder(
  itemCount: (rankedList.length / 2).ceil(),
  itemBuilder: (ctx, page) => Column(
    children: [
      rankedList[page * 2].render(ctx),
      if (page * 2 + 1 < rankedList.length)
        rankedList[page * 2 + 1].render(ctx),
    ],
  ),
)
DotIndicator(count: (rankedList.length / 2).ceil())
```

---

## 5. Edge cases — applied per surface family

Each surface needs to handle these. Listed once here; each implementer must verify their surface against every applicable case.

### 5.1 Data state

- **Loading**: provider AsyncValue is `.loading`. Per F2 strictness: show the slot while loading, hide on confirmed-met. Never hide while loading.
- **Error**: provider AsyncValue is `.error`. Slot renders neutral state with retry CTA or hides per nature of slot.
- **Null user**: signed out mid-render. Every slot guards with `if (user == null) return SizedBox.shrink()`.
- **Empty data**: e.g. 0 logs ever. Slots that need history (HRV trend, weight trend, streak risk) hide.
- **Stale cache vs fresh**: provider returns cached value while refreshing. Slot uses the cached value; rebuilds when fresh arrives.

### 5.2 Time / locale

- **Time-zone change mid-day**: device crosses DST or user travels. Re-evaluate `timeBucket()` on next foreground.
- **Midnight rollover while card visible**: dismiss state per-day-key resets at local midnight; surface re-evaluates.
- **First-of-month rollover**: `F3.84` fires once per month, gated on `day == 1 && !shown_this_month`.
- **Locale-specific copy overflow**: German "Vollständiger Fitnessstudio-Zugang", Telugu / Arabic RTL. All slot Text widgets must use `maxLines + TextOverflow.ellipsis` and respect `MediaQuery.textScaler`.
- **RTL layout**: surface chrome built with `EdgeInsetsDirectional`, `Alignment.directional`, and `CrossAxisAlignment.start` so it mirrors correctly.

### 5.3 Subscription state

- **Trial → paid transition**: `Trial progress widget` disappears, `Renewal reminder` may appear in 5 days.
- **Paid → cancelled**: premium teasers (F3.58) become unlock-prompts at the next gated tap; usage-based upsell (F3.56) starts re-evaluating.
- **Refund / charge-back**: backend syncs status; surfaces re-evaluate within 5 min of foreground.

### 5.4 Multi-account

- **Account switch**: every slot's persistence key is namespaced with `userId`. Dismiss state, setup checklist progress, dedupKey set — all reset on switch. Provider invalidate fires on `authStateProvider` change.

### 5.5 Wearable / health data

- **Wearable disconnect mid-day**: HRV / RHR / sleep providers re-emit null. F3.5–F3.13 slots gracefully hide; combined health card hides; F3.66 "wearable battery low" surface may fire.
- **Data hole > 24h**: F3.68 "missing-data nudge" fires.
- **First-time-ever wearable pair**: requires 7-14 days of baseline before F3.5–F3.13 stabilise. During calibration: slots show with "Calibrating" sub-state.

### 5.6 App lifecycle

- **Cold start**: F2 strictness applies — show while loading.
- **Hot reload**: dev-only. Providers may emit synthetic loading.
- **Hot restart**: dev-only. Per F1, level-up dialog uses persisted celebratedLevel to avoid re-fire.
- **App returns from background after > 4h**: re-evaluate all time-gated slots. Streak-at-risk recomputes against current time. Cycle phase may have advanced a day.
- **Notification tap**: deep-link bypasses home tab; doesn't affect surfaces.

### 5.7 Server / API

- **Insight cache hit**: returns existing Gemini insight unchanged.
- **Insight cache miss**: backend re-computes; UI shows previous insight or skeleton until new arrives.
- **Backend down**: client falls back to deterministic insights from `score_coach_line.dart` + on-device heuristics.
- **AI rate limit**: free-tier limits surface a "Limit reached · Premium for more" upsell (F3.56).

### 5.8 Concurrency / race conditions

- **Two slots compete for the same dedupKey**: ranker de-dupes by `id` not `category`; identical-id candidates are merged.
- **Two providers re-emit simultaneously**: ranker recomputes on every parent rebuild; idempotent.
- **User taps CTA while data still loading**: CTA queues the action and applies once data is in.

### 5.9 Accessibility

- **Screen reader (VoiceOver / TalkBack)**: every interactive slot wraps the tap area in `Semantics` with `button: true, label: …`.
- **Dynamic Type / `textScaleFactor` > 1.3**: slots use `Flexible` + `maxLines` + ellipsis. Layouts gracefully wrap to 2 rows.
- **Reduced motion**: confetti animations (F1 fix scope) skipped when `MediaQuery.disableAnimations == true`.
- **High contrast**: opaque pill backgrounds (per earlier fix). No 6% alpha bleed-through.

### 5.10 Notification + push interaction

- **Push for a slot the user dismissed in-app**: push is suppressed for 24h after in-app dismiss.
- **Push fires + user opens app**: deep-link sets `auto_dismiss_<slotKey> = true` so the slot doesn't re-render the same nudge on the home tab they just landed on.

### 5.11 Privacy / compliance (regulatory)

- **GDPR analytics consent withdrawn mid-render**: a sub-card whose ranker uses analytics-cohort data must purge its cohort assignment and re-pick a non-analytics card within 1 paint. Don't keep rendering with a stale cohort.
- **Right-to-be-forgotten request approved mid-session**: backend deletes user; client cache may still hold a card payload containing PII (first name, weight). Card must degrade copy to a generic ("Hey there") or hide entirely.
- **CCPA "Do not sell" toggled on**: third-party-data-derived cards (Yelp menu scout, weather-aware hydration, AQI alert) suppressed.
- **Children / under-13 detection**: any sub-card with social-loop or commerce CTA suppressed; only educational + safety surfaces remain.
- **Screen-recording / casting in progress** (`UIScreen.isCaptured == true`): suppress weight, calorie, period, T-marker and any PII-bearing card; render neutral placeholder.
- **Parental Controls / Screen Time category blocked**: pre-flight `FamilyControls` authorization before rendering any sub-card whose CTA opens a blocked surface.

### 5.12 Subscription / commerce state transitions

- **Trial → paid mid-day**: upsell cards (F3.56, F3.58) disappear immediately on next foreground; renewal banner armed for renewal date.
- **Paid → grace period (failed renewal)**: RevenueCat returns `in_grace_period`. Sub-card upsells should remain hidden during grace (don't punish a card-failed user); banner explains the renewal failure.
- **Paid → expired**: premium-feature CTAs downgrade in-place to upsell variant; never crash.
- **Receipt validation race**: RevenueCat says "grace", server says "expired". Trust the *more restrictive* of the two so users don't get free Premium on a race window.
- **In-app purchase modal interrupts a sub-card tap**: on modal dismiss without purchase, the card must not auto-retrigger the purchase flow.

### 5.13 Experimentation / feature flags

- **A/B variant flip mid-session**: feature-flag SDK reassigns variant while user is viewing variant A. Pin variant per session-card-instance so copy doesn't swap mid-paint.
- **Feature-flag kill-switch mid-scroll**: a card type globally disabled; in-flight cards fade out gracefully, no jank.
- **Holdout group**: control-group user gets a "stable" priority pyramid; treatment-group user gets the new ranker. Per-user randomization persisted.
- **Variant rollout collision with dedup**: changing a card's dedupKey across variants resets dismiss state — flag it as a known cost of variant cuts.

### 5.14 Locale / unit / mode toggles mid-session

- **Locale switched in iOS Settings mid-session**: cached card strings still in old locale until reload. Subscribe to `LocaleChanged` and invalidate copy without restart.
- **Workout-unit (lb/kg) toggle mid-render**: per memory `feedback_weight_unit_separation`, workout-unit, body-weight-unit, and increment-unit are three separate persistent settings. A card showing "Log 28g protein · 0.5lb gained" must atomically reformat all units.
- **Dark / light mode toggle mid-paint**: gradient and shadow tokens must reflow without crashing the animation.
- **System "Reduce Motion" ON**: PageView swipe collapses to instant transition; coach card confetti suppressed; level-up dialog uses cross-fade not springs.
- **Bold Text / Dynamic Type at XXXL**: 2-line copy must wrap to N lines, height grows, intrinsic-height carousel must remeasure. Per `feedback_no_overflow_adaptive_screens` — verify on smallest device + largest type.

### 5.15 Device / runtime / sandbox

- **Kiosk / shared-device / demo mode**: suppress PII-bearing cards (weigh-ins, period, T-marker); serve generic content.
- **App Clip / Instant App handoff**: no auth — CTAs must gracefully promote to full-app install, not return 401.
- **Background fetch throttled (iOS BGAppRefresh > 12h skipped)**: silent age-indicator on stale cards, not an error state.
- **Low Power Mode**: skip rich animations (confetti, gradient cycling, particle effects). Cards still render fully functional.
- **RAM-pressure widget eviction**: iOS Live Activity OOMs; sub-card timer-state (e.g., fasting countdown) must reattach without a visible jump.
- **Android Doze / foreground-service kill**: sync worker killed during a sub-card countdown (workout timer). On resume, reconcile actual elapsed vs displayed.
- **Multi-account quick-switch (multi-profile)**: switching mid-render must invalidate *all* per-profile card state, not just the visible card.

### 5.16 Network / connectivity

- **Cellular-only with Low Data Mode**: image-heavy sub-cards (recipe of day, AR scan preview) serve text variant.
- **Offline + queued sync conflict**: card was triggered by local SQLite (water logged offline) but server returns 409 on sync. Card must not double-render the action.
- **Airplane mode mid-session**: graceful — keep cards on screen, gray out CTAs that require network with retry-when-online toast.
- **Slow / flaky network**: card paint must not block on a backend insight fetch > 2 s; fall back to deterministic insight after.

### 5.17 Render / paint / interaction

- **Paint during scroll-fling (low-end Android, ≤ 4 GB RAM)**: defer image decode until fling settles to avoid frame drops.
- **Sub-card collision with floating CTA / FAB** (e.g., iPhone SE): bottom-anchored sub-card overlaps Chat FAB; shift FAB up or reserve safe-area.
- **Deep-link landing on already-dismissed card**: push deep-links to `surface=sub-card-id-X` but user already swiped it away this hour. Route to its action screen directly, don't re-render the card.
- **Sub-card CTA fails (network)**: dismiss state should NOT persist; revert and surface the retry inline.
- **Sub-card hot-reload while animating**: dev-only, but the AnimatedSwitcher must not crash.

### 5.18 Permissions / OS-mediated

- **Notification permission revoked mid-session**: sub-card was "Tap to schedule reminder" — on tap, OS returns denied. Card pivots in-place to in-app reminder.
- **Health permission revoked**: HRV/RHR/sleep providers re-emit null. F3.5–F3.13 cards gracefully hide. Banner suggests re-grant.
- **ARKit / Camera permission denied for form-scan CTA**: check `AVAuthorizationStatus` before rendering; if denied, swap to "Upload video" variant.
- **Location permission denied**: weather, AQI, geofence-based cards (F3.45, F3.124, F3.125) suppressed; non-location variants surface.
- **Calendar permission denied**: calendar-integration cards (F3.186–F3.189) suppressed.

### 5.19 Multi-device / sync

- **Two devices open simultaneously, same account**: dismiss on one must propagate to the other within 30 s.
- **Sync conflict on dedup state**: device A dismisses card X at 09:00, device B dismisses card Y at 09:01. Backend must merge both; neither device should resurrect the other's dismiss.
- **Apple Watch shows the same nudge inline + iPhone home card**: both should respect a single dedupKey.

### 5.20 Clock / time edge cases

- **DST transition mid-render** (fall-back 1:55 AM → 1:00 AM): bedtime countdown computed from wall clock would jump. Pin computation to monotonic clock.
- **Birthday at midnight rollover** while card visible: F3.82 birthday card auto-mounts at 00:00 if user has the app open.
- **Anniversary at midnight rollover**: same as birthday.
- **Leap day**: weigh-in-day reminder (F3.83) on Feb 29 — fallback rule documented in provider (snap to Feb 28 in non-leap years).
- **User edits their birthday in profile mid-day**: birthday card re-evaluates at next foreground.
- **TimeZone change crossing > 3h**: all time-banded cards re-evaluate; F3.80 jet-lag card may immediately apply.

---

## 6. Category cross-references

Every category from §3 with its surface IDs:

- **Onboarding** — 69, 70, 71, 72, 73, 74, F3.1, F3.85, F3.86, F3.87, F3.88
- **Recovery** — 78, 79, 80, 81, 82, 83, F3.5–F3.13, F3.27, F3.28, F3.29, F3.149–F3.156
- **Nutrition** — 27, 59, 60, 68, F3.3, F3.14–F3.21, F3.71, F3.124–F3.133, F3.163–F3.165, F3.173–F3.176
- **Hydration** — 26, 28, F3.4, F3.45, F3.46, F3.134
- **Movement** — 67, 78, F3.22–F3.26, F3.135–F3.141
- **Sleep** — 62, 81, 83, 29, 30, F3.27–F3.31, F3.43, F3.44, F3.139
- **Cycle / hormonal** — 71, 84, 85, F3.32–F3.38, F3.180–F3.185, F3.203
- **Mental health** — F3.39–F3.44, F3.123, F3.157–F3.162, F3.166
- **Streak / gamification** — 87, 88, 89, 90, 91, F3.47–F3.51
- **Social** — 17, 18, 92, 93, F3.52–F3.55, F3.117, F3.141, F3.190, F3.191
- **Subscription** — 7, 75, 76, 77, F3.56, F3.57, F3.58
- **Educational** — 72, F3.59–F3.62, F3.86
- **Milestones / goals** — 16, 94, F3.63–F3.65, F3.169–F3.172
- **Equipment / wearable** — 97, F3.66–F3.68, F3.110
- **Schedule / planning** — 6, F3.69–F3.73, F3.186–F3.189
- **AI pattern detection** — 58, F3.74–F3.77
- **Injury / medical** — 45, F3.78, F3.79, F3.166, F3.167, F3.168
- **Travel / lifestyle** — 106, F3.80, F3.81
- **Special days** — F3.82–F3.84, 7
- **Fasting** — 41, 61, F3.89–F3.99, F3.175
- **Pre-workout** — 38, 44, 45, F3.100–F3.110, F3.139
- **Mid-workout** — F3.115, F3.134–F3.138, F3.140, F3.141
- **Post-workout** — 35, 36, F3.111–F3.123, F3.149, F3.150, F3.151
- **Macro / weight specific** — F3.142–F3.148, F3.20
- **Aerobic / cardio** — F3.177–F3.179
- **Backend-enabled / unsurfaced data** — F3.192–F3.206

---

## 7. Open questions / decisions still owed

- **Live Activity** (F3.93): which iOS minimum target? Live Activities require iOS 16.1+.
- **Streak freeze inventory** (F3.47): pricing for buyable freezes vs. free?
- **Daily Quest deck** (F3.48): per-day generation rules — random or template-based?
- **AI pattern detection** (Phase P): backend model — heuristic SQL or a lightweight ML model on `pattern_detector` service?
- **WeatherKit integration** (F3.45): we'd need to add `weather_provider` and request location consent.
- **Notification permission re-prompt cadence** (#74): re-ask on day 3 if dismissed day 1?
- **Mood check-in** (F3.39): does it appear on every home foreground or once per day after sleep wake?
