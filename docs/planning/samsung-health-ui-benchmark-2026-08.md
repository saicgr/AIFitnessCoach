# Samsung Health + Google Health 2026 redesigns vs. Zealova — navigation & home-screen benchmark

**Date:** 2026-08-09 · **Revised:** 2026-08-10
**Scope:** Samsung Health's June 2026 redesign (v7.00, One UI 9) **and Google's May 2026
Fitbit→Google Health rebrand+redesign**, benchmarked against Zealova's current navigation and
Home screen. Every Zealova claim below was verified against the source
tree, with file references.

> **Revision note (2026-08-10).** The first draft claimed users' #1 complaint about the redesign
> was its three navigation layers (bottom nav + top bar + long dashboard). **That was wrong**, and
> it inverted the sign on the most important data point: the top shortcut bar is the redesign's
> *best-reviewed* feature. §1 and the recommendations have been corrected. The revision also adds
> §6, which was missing: Zealova ships no hardware, so a chunk of Samsung's metric list is not
> reachable on the same terms.
>
> **Second correction (same day):** a claim that Samsung's pillar bar "persists everywhere" was also
> wrong — it spans the dashboard and the five silos, not the whole app. R1's scope has been
> restated accordingly, and the Coach-tab question added as R1b.
>
> **Third revision:** added §2 (Google Health) and §3 (three-way comparison). Google's redesign is
> the stronger signal of the two and it moved several recommendations — most importantly, R1's Home
> rail is **deleted** (it duplicated existing tabs) and the Coach-tab removal is now evidence-backed
> rather than a preference.

---

## 1. What Samsung actually shipped

Rolled out **June 8, 2026**, app version **7.00.0.107**, initially One UI 9 / Galaxy S26.

| Change | Detail |
|---|---|
| **Five pillars** | The whole app reorganised around **Activity · Sleep · Vitals · Mindfulness · Nutrition**. |
| **Top shortcut bar** | A persistent 6-chip bar: the five pillars **plus a "Dashboard" chip** that returns you to the customisable home. A *silo* layer above the retained bottom nav. |
| **Customisable dashboard** | Home is a widget grid you can drag-reorder and **resize** (2×2 and 4×1 tiles; the old 3×1 was dropped). Explicitly modelled on "smartly designed weather apps". |
| **Quick Add** | Log a workout, weight, or food from anywhere without hunting for the owning card. |
| **Energy Score** | AI composite daily readiness number, surfaced on the dashboard. |
| **Vitals** | New pillar. Five overnight bio-signals — SpO₂, HRV, respiratory rate, HR, skin temperature — against a **personal baseline built from 7 nights**, then flags deviations. |
| **Heart Health Score** | Long-horizon 0–100 fusing activity, body composition, sleep, stress. |
| **Daily Cardio Load** | Prescribes workout target + recovery based on capacity. |
| **Fitness Index** | 5-axis fitness picture with **peer percentile** comparison. |
| **Hearing Health** | Cross-device audio-exposure monitoring. |
| **Visual language** | Heavy colour, ombre gradients, bright cards, rounded elements — a hard break from the previous mono white/black. |
| **Removed** | Several popular guided fitness programs were cut ahead of the redesign. |

### How it actually landed

Android Authority's hands-on ranks the changes explicitly, and the ranking matters:

- **Hit #1 — the top shortcuts bar.** The silo navigation is the *most-praised* part of the redesign.
- **Hit #5 — "addressing previous UI navigation problems."**

The **misses**, in the order that review presents them:

1. **Colour for colour's sake** — no logical connection between hue and metric (purple = calories
   *and* sleep, blue = workouts, orange = stress).
2. **Inconsistent pinch-to-zoom** — heart-rate graphs zoom, the sleep graph doesn't.
3. **Comparison limited to a single metric** — no cross-indicator overlay, so you can't correlate
   two signals over time.
4. **Device-incompatibility clutter** — unsupported features appear on the dashboard **by default**,
   must be hidden manually, and are *immovable* inside their silos. The review names this **the
   biggest problem**.
5. **Removed widgets reappearing** (e.g. Vascular Load).

Samsung Community threads repeat, in rough order of frequency:

- **"Insights" cannot be hidden** and is the biggest thing on screen.
- An **undismissable scrollable banner** taking half the screen.
- The colour scheme — "one of the ugliest things I have ever seen in an app", "awful pukey yellow".
- **More steps to reach a specific activity** (biking), and hunting for logging entry points.
- Step-count accuracy, lost history, reset favourite exercises — regressions, not design.

**So the dominant complaint is not navigation architecture.** It is *content you cannot get rid of,
and content that does not apply to your hardware*, plus colour. "Too many sections and tabs" does
appear in secondary summaries of community/Reddit sentiment, and the depth-to-action complaints are
real — but the layered silo navigation itself tested well. Any recommendation below that leans on
"don't add nav layers" is **my judgement, not their user data**, and is labelled as such.

---

## 2. What Google shipped — and it is the bigger signal

**On 19 May 2026 the Fitbit app became the Google Health app.** Fitbit Premium became Google Health
Premium. This is not a skin change; it is the same move Samsung made, three weeks earlier.

| Change | Detail |
|---|---|
| **Four tabs** | **Today · Fitness · Sleep · Health.** Organised by DATA DOMAIN. |
| **Today** | Focus-metric tiles at the top (one big circular tile + 3 small), then weekly trends alongside daily stats — Google's stated reason is that week-over-week reads progress better than a single-day snapshot. |
| **Fitness** | Activities, the workout video library, weekly cardio load; Premium adds weekly fitness plans co-created with the AI coach. |
| **Sleep** | **Its own top-level tab.** Improved sleep score + supporting metrics. |
| **Health** | "Health, fitness and medical records in one place" — heart rate, weight, breathing rate, SpO₂, plus mental wellbeing **and nutrition**. |
| **Google Health Coach** | Gemini-powered, Premium. Positioned as trainer + doctor + nutritionist + sleep expert in one. |
| **Focus tiles** | Editable via a pencil icon: Add / Remove / Expanded view. Reordering arrived later (long-press-drag on Android; drag-and-drop on iOS in 5.03). |
| **No wearable required** | Explicitly works phone-only, and can track a walk/run/hike from the phone alone. |
| **Removed** | **Social features and badges**, stress graphs, minute-by-minute skin temperature, hourly step graphics, 250-step move reminders, oxygen variation. |

### The two facts that matter most

**1. Google has no Coach tab — and it deleted the one it had.** The 2023 Fitbit redesign shipped
three tabs: Today · **Coach** · You. In the 2026 redesign that Coach tab is *gone*, its workout-video
content folded into **Fitness**, and the new Gemini coach is delivered **contextually inside Fitness
and Sleep** rather than as a destination.

So: Samsung has no coach tab. Google *had* one and removed it. **Zealova is the only one of the
three with a dedicated Coach tab.**

**2. Google's users are complaining that the AI coach gets in the way.** Reported: coach prompts and
conversational suggestions "obstruct core health data access," and users **trigger it accidentally**
— "problematic for an app designed for quick, quiet data checking."

That is the guardrail for a global coach button: persistent is fine, *prompting* is not.

### How it landed

Backlash, for the mirror-image reason Samsung got backlash:

- **Excessive white space and oversized tiles** — "a huge block of empty space" under the top
  metrics; reads unfinished rather than intentional.
- **Customisation is counterintuitive** — at launch there was no drag-to-reorder at all; the
  recommended workaround was to delete every default tile and re-add them one by one in order.
  Drag arrived only in later point releases.
- **Feature removals** — hourly step graphics, move reminders, sleep prominence, oxygen variation.
- **Duplicate activity entries** when syncing with Google Fit / Strava simultaneously.

**Samsung's home was attacked for being too dense and undismissable. Google's was attacked for being
too empty and unarrangeable.** Nobody has landed this. That is worth knowing before copying either.

---

## 3. Three-way navigation comparison

| | Samsung Health (Jun 2026) | Google Health (May 2026) | Zealova today | Zealova proposed |
|---|---|---|---|---|
| **Top-level nav** | Bottom nav + 6-chip rail over dashboard + 5 silos | 4 tabs | 5 tabs | 5 tabs |
| **Organised by** | Data domain | Data domain | **User action** | Data domain + action |
| **The tabs/pillars** | Activity · Sleep · Vitals · Mindfulness · Nutrition | Today · Fitness · Sleep · Health | Home · Workout · **Coach** · Nutrition · You | Home · Workout · **Health** · Nutrition · You |
| **AI coach** | No tab — tips on dashboard | **No tab — deleted the 2023 one**; contextual in Fitness/Sleep | **Dedicated tab** | Global pill, all screens |
| **Sleep** | A pillar | **Its own tab** | Buried at `/health/sleep` | Inside Health |
| **Nutrition** | A pillar | Inside the Health tab | **Its own tab** | **Its own tab** |
| **Health/vitals** | Vitals pillar | Health tab | **No home** | Health tab |
| **Social** | — | **Removed** — badges/step-challenges, wrong comparable (see 3b) | Built at `/social`, hidden | Stage 2 (You to Community), Hevy model |
| **Home customisation** | Drag + resize (2×2 / 4×1) | Focus tiles: add/remove/expand, drag added later | Reorder + hide + presets | + tile sizing (R5) |
| **Works without a wearable** | Degraded | **Yes, by design** | **Yes** | Yes |
| **Home criticised for** | Too dense, undismissable | Too empty, unarrangeable | Too dense (80 contextual cards) | — |

### What this changes

1. **The industry moved to data-domain navigation in 2026, and Zealova didn't.** Both giants
   reorganised around what the data *is*, not what the user *does*. Zealova's action-based nav is now
   the outlier, and its specific symptom is the one already in the master table: health has no home.
2. **Removing Coach from the nav is now supported by both competitors, not just taste.** Google
   deleting its own Coach tab is the strongest single data point in this document.
3. **…but the global coach button must be quiet.** Google's users accidentally trigger theirs. The
   button should be persistent, small, hideable, and must never prompt unbidden. This is direct
   evidence for the restrained pill (Placement A) over anything modal or suggestive.
4. **Sleep may deserve more than a sub-tab.** Both competitors elevate it — Samsung to a pillar,
   Google to a *top-level tab*. The proposal buries it inside Health. Worth revisiting; it is the
   one place both competitors out-rank the proposal.
5. **Keeping Nutrition as its own tab is correct.** Google only just added nutrition logging and
   filed it under Health. For a training+nutrition product, a dedicated tab is the stronger position.
6. **Social — the "Google removed it" signal does NOT apply here.** See 3b: the intended model is
   Hevy's workout feed, a different product from the badge-and-step-challenge social Google deleted
   from a general health tracker. Wrong benchmark; corrected below.
7. **Nobody has solved the home screen.** Samsung shipped too dense, Google too sparse, both got
   backlash. Zealova's failure mode is Samsung's. There is no template to copy here — only two
   worked examples of what to avoid.

---

## 3b. The Social tab benchmark is Hevy, not Fitbit

An earlier draft filed "Google removed social features" as a warning against a Zealova Social tab.
**That was the wrong comparison.** What Google deleted was *badges and step-challenge social* inside
a general health tracker. The intended model here is **Hevy's workout feed** — a different product
with a different job, and one with a documented growth loop.

### What Hevy actually does

| | Hevy |
|---|---|
| **Nav** | Three tabs: **Home / Workout / Profile**. Home **is** the social feed — there is no separate "Social" tab. A toggle top-right flips Home between *Following* and *Discover*. |
| **Post anatomy** | Poster, session name, description, stats (**duration, training volume, PR count**), attached photos/videos. |
| **Interactions** | Like, comment (with clickable links), reply to comments, like comments, follow, and **per-athlete workout notifications**. |
| **Discover** | Recent workouts from people you do *not* follow, plus a horizontal carousel of suggested athletes on Home. |
| **The reuse loop** | Tap any workout in the feed, then **"Save as Routine" / "Copy Workout"**. Someone else's session becomes your routine in one tap. |
| **Profiles** | Bio, workout count, followers/following, activity graphs, media, saved routines, recent workouts, and **Compare** (two athletes side by side). |
| **Privacy** | Public or private profiles with follow requests; Profile > Settings > Privacy & Social. |

The competitive evidence in this category is unambiguous: Hevy's community "helped solidify user
retention and created organic growth loops", while **Strong — its closest competitor — deliberately
ships no feed, no community, no notifications about other people**, and is described as "speed and
silence". Two viable positions; Hevy's is the growth one.

### What Zealova already has vs. what Hevy's loop needs

Zealova's `/social` is *broader* than Hevy's: 5 tabs (feed, challenges, leaderboard, friends,
messages) plus stories, hashtag feeds, groups, conversations, reactions (richer than a like),
`create_post_sheet` with stat pills and visibility options, comments sheet, activity share cards,
friend search and friend profiles. And `social_service.dart` already exposes **both** graph models:
`followUser` / `unfollowUser` / `followers` / `following` **and** `sendFriendRequest` /
`acceptFriendRequest`.

The gaps are narrower than a first pass suggested. **Correction (2026-08-10):** an earlier draft of
this section claimed "Save as Routine / Copy Workout" was absent and had to be built. That was wrong
— it came from grepping only the literal Hevy strings. The mechanic exists end to end:

- **Backend:** `POST /saved-workouts/save-from-activity` — docstring: *"Save a workout from a social
  feed activity to user's library."* Plus `POST /do-now/{id}` and `POST /schedule`.
- **Service:** `saved_workouts_service.dart` → `saveWorkoutFromActivity()`, plus two composed flows
  — `acceptChallenge()` (save + start immediately, the "BEAT THIS" flow) and `saveAndSchedule()`
  (save into a "From Friends" folder + schedule).
- **UI:** `shared_workout_detail_screen.dart:267` (accept-challenge button) and
  `schedule_workout_dialog.dart:190` (schedule).

| Hevy mechanic | In Zealova? | What is actually missing |
|---|---|---|
| Asymmetric follow | Service YES (`followUser`, `followers`, `following`) | The **surfaced UX is friend-request shaped** (`friend_card`, `friend_search_screen`, accept/decline). A mutual-consent graph caps distribution. UX decision, not a backend one. |
| Feed of followed users | YES — `feed_tab` + `activityFeedProvider` + `activity_card` | — |
| Likes / comments / replies | YES — `comments_sheet`, reaction types | Richer than Hevy: reactions, not just likes. |
| Save someone's workout to your library | **YES, end to end** | Only the **framing**. It is reachable as "accept challenge" or "schedule it" — never as a plain one-tap *"Save as routine."* That is a copy-and-affordance change over existing plumbing, not a build. |
| Stranger discovery | **PARTIAL** | `hashtag_feed_screen.dart` shows "all public posts with a specific hashtag" — real stranger discovery. But there is **no general Discover / For-You feed of strangers**, and no suggested-athletes carousel. (Note: the `discoverFeed` l10n key is just the label **"Feed"** — the screen's strings are all `discover*`-prefixed because it used to live at `/discover`. It is not a discovery feed.) |
| Per-athlete workout notifications | **ABSENT** — 0 matches | Genuinely needs building. |
| Profile compare (two athletes side by side) | **ABSENT** — 0 matches | Genuinely needs building. |

### Consequences

1. **Do not use Google's removal as evidence against Social.** Different product, different mechanic.
   The right comparables are Hevy and Strava, and both say activity-feed social retains.
2. **The nav conclusion is unchanged.** Hevy can put the feed on Home because Hevy's Home has no
   other job — it is a logger with a feed. Zealova's Home is a coach-and-today dashboard, so the feed
   belongs in a **destination**: exactly the Step 2 You-to-Community conversion in R1b.
3. **Re-frame the save action before shipping the tab.** The distribution engine is already wired —
   it is just dressed as "accept a challenge" or "schedule it". Adding a plain one-tap *"Save as
   routine"* on every feed post is copy plus an affordance over existing plumbing, and it turns every
   posted workout into a distribution event into a library that already exists. Cheapest, highest
   leverage item in this section.
4. **Decide the graph topology deliberately.** Both models already exist in the service layer, so this
   is a UX decision, not a backend one — but a friend-request-gated graph will not produce Hevy's
   growth loop.

---

## 4. Master comparison table

Verdict key: **🟢 Zealova ahead** · **🟡 parity** · **🔴 Samsung ahead / Zealova gap**
Hardware key: **⚙️ requires a wearable the user owns** (see §6)

| # | Dimension | Samsung Health 2026 | Zealova today (verified) | Verdict |
|---|---|---|---|---|
| 1 | **Primary nav model** | Bottom nav **+** persistent 6-chip top silo bar. | Bottom nav only — Home · Workout · Coach · Nutrition · You (`main_shell_part_edge_panel_handle.dart:235-313`), 5 `StatefulShellBranch`es. | 🔴 theirs tested better |
| 2 | **Organising principle** | **Data domain** (Activity/Sleep/Vitals/Mindfulness/Nutrition). | **User action** (Workout/Coach/Nutrition/You). | 🟡 both valid |
| 3 | **Does health data have a home?** | Yes — Vitals/Activity/Sleep are top-level pillars, one tap from anywhere. | **No.** `/health/combined`, `/health/sleep`, `/health/vitals`, `/health/heart-health`, `/health/fitness-index`, `/stats` — none is a tab; all pushed full-screen from cards. | 🔴 |
| 4 | **Discoverability of flagship metrics** | Pillar chip, always visible. | `/health/fitness-index` has **1** entry point in the whole app; `/health/heart-health` has **2**; both only from inside `combined_health_screen.dart`. | 🔴 |
| 5 | **Can users remove content they don't want?** | **No — their #1 complaint.** Insights unhideable, banner undismissable, incompatible widgets immovable inside silos. | Yes — My Space reorder + hide + presets (`home_my_space_screen.dart`); banners individually swipe-dismissable + dismiss-all. | 🟢 **biggest structural lead** |
| 6 | **Irrelevant-to-your-hardware content** | Shown by default, manual hide required. | Health cards self-collapse when unconnected; Vitals renders **per-signal** `no_data` states rather than a dead screen (`vitals_detail_screen.dart:316-343`). | 🟢 |
| 7 | **Home length** | Dashboard of resizable widgets; deliberately shortened. | 11 default sections + fixed chrome + `ExtendedHomeCardsStack` (**80 self-collapsing contextual cards**) + fasting hero + timeline. 103 files under `screens/home/widgets/`. | 🔴 |
| 8 | **Home customisation** | Drag-reorder **and resize** (2×2 / 4×1). | Drag-reorder + show/hide + presets. **No resize.** | 🟡 |
| 9 | **Dead sections in the customiser** | n/a | `strainCoach` + `metricTrio` are in `_defaultOrder` and appear as draggable, toggleable rows in My Space, but `_widgetForSection` returns `SizedBox.shrink()` for both. `metricsCarousel` has a comment saying it "sits immediately after coachHero by user request" but is **absent from `_defaultOrder`**. | 🔴 self-inflicted — and it is Samsung's #1 complaint in miniature |
| 10 | **Quick logging** | New "Quick Add". | Already shipped: "+" FAB in `main_shell.dart` + `QuickActionsRow` + quick-log sheet. | 🟢 |
| 11 | **Daily composite score** | Energy Score. ⚙️ | Today Score + Strength Score + Recovery/Readiness — **three** composites, no stated hierarchy. Today Score computes from logged data, no wearable needed. | 🟡 |
| 12 | **Personal baseline vs. absolute** | Vitals, 7-night baseline. ⚙️ | `/health/vitals` — 28-day baseline, "Building baseline" state, per-signal empty states. Built; buried; ⚙️ for the bio-signals. | 🟡 built, not surfaced |
| 13 | **Peer comparison** | Fitness Index percentile. | `/health/fitness-index` — "5-axis fitness radar + k-anon peer percentile". Same feature, 1 entry point. Mostly ⚙️-free. | 🟡 built, not surfaced |
| 14 | **Colour semantics** | **Broken** — miss #1 in every review. | Single accent + `accent-allowlist` discipline enforced in review; error/success/warning reserved. Learnable. | 🟢 |
| 15 | **Light/dark parity** | Colour-heavy, both themes. | Theme-derived on the workout hero (`workout_hero_palette.dart`) with WCAG contrast tests; light-mode debt baseline in `test/ui_gates/light_mode_gate_test.dart`. | 🟡 |
| 16 | **Coaching** | Tips + prescriptions on the dashboard. | Full LLM coach as a **first-class tab** with memory, sessions, actions, proactive nudges. | 🟢 |
| 17 | **Guided programs** | **Cut** several popular ones. | 18+ published programs, variant matrix, session-volume floors, media pipeline. | 🟢 |
| 18 | **Hardware sensors** | Owns the watch + ring — BIA body comp, skin temp, SpO₂, hearing exposure. | **None.** HealthKit / Health Connect passthrough only. | 🔴 structural, see §4 |
| 19 | **Hardware lock-in** | Complaint source — features visible but unusable without new firmware. | Device-agnostic; works with Apple Watch, Galaxy, Oura, Whoop, Fitbit alike. | 🟢 |
| 20 | **Ads** | Ads in Discover, criticised. | None. | 🟢 |
| 21 | **Multi-metric correlation** | Absent — miss #3. | Also absent. `/stats` tabs are per-metric; no overlay. | 🔴 both weak — open field |
| 22 | **Graph interaction** | Inconsistent pinch-to-zoom. | Consistent chart components; no pinch-zoom. | 🟡 |
| 23 | **Notification / inbox model** | Not a differentiator. | Banner stack + unified bell; day-scoped dedupe with re-raise. | 🟢 |

---

## 5. The findings that matter

### Finding 1 — Samsung's actual #1 complaint is a bug Zealova already has, in miniature

Their worst-reviewed problem is **content you can't remove and content that doesn't apply to you,
occupying prime space**. Zealova's equivalent: `strainCoach` and `metricTrio` sit in `_defaultOrder`
and render as draggable, toggleable rows in My Space while `_widgetForSection` returns
`SizedBox.shrink()` for both — two controls that do nothing. And `metricsCarousel` is documented as
sitting "immediately after coachHero by user request" but isn't in `_defaultOrder`, so it never
renders by default.

Zealova is structurally *ahead* here (everything else is hideable, banners are dismissable, health
cards self-collapse) — which makes these three the exact thing to clean up before they grow.

### Finding 2 — Zealova already built Samsung's headline features and then hid them

`/health/vitals`, `/health/heart-health`, `/health/fitness-index` all exist, with a router comment
literally saying *"Samsung-parity"*. Samsung made these a **permanently visible pillar chip**.
Zealova made them a tap inside a card inside a screen reached from a strip on Home —
`fitness-index` is reachable from exactly **one** widget in the codebase.

The cheapest win available: no new screens, no new data, just a navigation layer.

> Related: the Home metrics strip now collapses entirely when Health isn't connected (2026-08-09).
> Correct for the strip, but it leaves an unconnected user with **no visible route from Home into
> the health hub at all**.

### Finding 3 — the home scroll grows by accretion

11 default sections + up to 80 contextual cards + banner stack + pinned timeline. `_defaultOrder`
carries a v28→v34 changelog in its own comments. Samsung's fix for the same problem was
destinations, and their users liked it. Reordering has been tried here 34 times.

---

## 6. The hardware constraint — what is and isn't reachable

Zealova ships no wearable. Per the existing product decision, **HealthKit / Health Connect
passthrough is the ceiling**. That is not the same as "impossible", but it changes the terms: the
data arrives only if *the user already owns* a device that writes it, and Zealova never controls
sampling rate, overnight cadence, or firmware.

| Samsung metric | Reachable for Zealova? | On what terms |
|---|---|---|
| **Energy Score** (daily composite) | ✅ Already shipped | Today Score computes from logged training/nutrition/sleep. No sensor required. |
| **Fitness Index** (5-axis + peer percentile) | ✅ Already shipped | Derived from logged performance. `/health/fitness-index` exists. |
| **Daily Cardio Load** | 🟡 Partial | Needs workout HR. Passthrough if the user has a watch; otherwise approximate from RPE + volume, which Zealova already collects. |
| **Heart Health Score** | 🟡 Partial | Activity + sleep + stress arrive via passthrough. **Body composition does not** — Samsung uses on-watch BIA. |
| **Vitals: HR, HRV, SpO₂, respiratory rate** | 🟡 Passthrough only | Apple Watch / Galaxy Watch / Oura / Whoop / Fitbit all write these. Users without one get `no_data` per signal — already handled correctly at `vitals_detail_screen.dart:316`. |
| **Vitals: skin temperature** | 🔴 Rarely available | Few devices write it to HealthKit/Health Connect. Expect this signal to be `no_data` for most users. |
| **Body composition (BIA)** | 🔴 Not reachable | Requires Samsung's watch hardware. Manual entry or a smart scale is the only path. |
| **Hearing Health** | 🟡 iOS only | HealthKit exposes headphone audio exposure. No confident Health Connect equivalent. Cross-platform parity isn't achievable, so this is a poor investment. |

**Consequences for this document:**

1. **None of R1–R6 below require hardware.** They are navigation and information architecture.
2. **R3 (deviation-from-baseline) survives**, but should be framed against metrics Zealova owns
   outright — weight trend, training volume, calorie adherence, sleep duration, step count — not
   only the wearable bio-signals. The phrasing shift is the value, not the sensor.
3. **The pillar bar must gate on data availability** (R1). Showing a "Recovery" chip that opens a
   screen of `no_data` capsules is *precisely* Samsung's #1 complaint — irrelevant-to-your-hardware
   content occupying prime space. Zealova's per-signal empty states are good; a chip that leads
   nowhere would undo them.
4. **Stop treating the Samsung metric list as a parity checklist.** Two of its most-marketed items
   (BIA body composition, skin temperature) are hardware moats. Competing there loses. The parity
   worth having — composite score, peer index, baseline framing — is already built.

---

## 7. Recommendations

Ordered by leverage ÷ cost. All additive; no existing surface is deleted. None need hardware.

### R1 — A Health tab, not a rail on Home  *(revised 2026-08-10)*

**The earlier version of R1 — a six-chip pillar rail on Home — is withdrawn.** It was half-redundant
against the nav that already exists:

| Chip | Duplicate of |
|---|---|
| TODAY | the Home screen you are already on |
| TRAINING | the **Workout** tab |
| FUEL | the **Nutrition** tab |
| SLEEP · RECOVERY · BODY | *nothing — these are the genuinely homeless domains* |

Half the rail was chrome for destinations one tap away. The three that matter are the health
domains, and the right container for them is a **destination**, not a chip row.

**So: add a Health tab. The rail survives only as Health's own sub-navigation** — OVERVIEW · SLEEP ·
RECOVERY · VITALS · BODY. That is also what both competitors do (§3), and it is what Samsung's own
rail actually is: a bar spanning one dashboard and its silos, which is why its sixth chip reads
"back to Dashboard".

Home therefore gets **no rail at all**. Its changes reduce to R2, R3, R4 and R6.

**Wireability audit — the data and screens are 100% present; the container is not.**

| Need | Status |
|---|---|
| Screens: combined / sleep / vitals / heart-health / fitness-index | OK — all five built |
| Providers: dailyActivity, healthSync, sleepScore, recovery, vitals, heartHealth, fitnessIndex | OK |
| Backend `GET /health/vitals` | OK — `health_metrics_endpoints.py` |
| Body data (weight, measurements, photos) | OK — `WeightTrackingCard` + `/stats` |
| Aggregation card | OK — `HealthOverviewCard` (currently in You / Overview) |
| Health shell screen with sub-nav | **MISSING** |
| `StatefulShellBranch` for Health | **MISSING** — `/health/*` are **pushed** utility routes today; moving them into a branch changes back-stack behaviour |
| `navHealth` across 36 ARB files | **MISSING** (`navCoach` is in all 36 — same job) |
| Nav-tour key + `_warmActiveTab` entry (`main_shell.dart:812`) | **MISSING** |

**Empty-state gating still applies** (§6.3): a RECOVERY sub-tab that opens a wall of `no_data`
capsules is Samsung's worst-reviewed behaviour. `vitals_detail_screen.dart:316` already does this
correctly per signal — preserve it.

### R1b — Coach leaves the nav; a quiet global pill replaces it

Coach occupies the **centre** nav slot today (`Icons.auto_awesome` + unread badge), decided
2026-06-11. Removing it frees the only slot a Health tab can take, and §3 now backs this with
evidence rather than taste:

- **Samsung** has no coach tab — coaching is dashboard tips.
- **Google** *had* a Coach tab in its 2023 Fitbit redesign and **deleted it** in 2026, folding the
  content into Fitness and delivering its Gemini coach contextually.
- Zealova is the only one of the three still spending a nav slot on it.

Coach does not become unreachable: **26 coach entry points exist app-wide** across 20+ files, and
`lib/widgets/coach_floating_button.dart` — an "Ask coach" pill — already exists and is live on the
library screen. Promote it app-wide.

**The constraint, from Google's backlash:** their users report the AI coach "obstructs core health
data access" and gets **triggered accidentally**. So the global affordance must be *persistent but
quiet* — small, hideable, never prompting unbidden, and deferring on the Coach screen itself and
during an active workout (which already has its own Ask-coach pill).

**Nav evolution, inside the 5-slot Material 3 cap:**

| | Nav |
|---|---|
| Today | Home / Workout / **Coach** / Nutrition / You |
| Step 1 | Home / Workout / **Health** / Nutrition / You — Coach becomes a global pill |
| Step 2, if Social earns it | Home / Workout / Health / Nutrition / **Community** — profile behind the header avatar |

Step 2 follows the recorded 2026-06-11 decision. The slot for Social comes from converting You, never
from a sixth tab. `/social` is **already built** — a 5-tab `SocialScreen` (feed / challenges /
leaderboard / friends / messages) plus friend profiles, search, groups, stories, hashtag feeds and
conversations — so this is a promotion, not a build. Note the contrarian read in §3.6: Google just
*removed* social and badges.

Mockup: `docs/planning/nav-home-mockup-2026-08/index.html`.

### R1c — Where the global coach button goes  *(researched 2026-08-11)*

The mockup offered **Placement A** (coach pill bottom-LEFT, Quick Log bottom-RIGHT) and **Placement
C** (one merged segmented pill). The evidence rejects A.

**Reachability data (Hoober, 1,333 field observations — still the canonical study):**

| | |
|---|---|
| One-handed grip | **49%** of observed use |
| Cradled (one hand holds, other finger taps) | 36% |
| Two-handed thumbs | 15% |
| Of one-handed use, **right** thumb | **67%** (left 33%) |
| Interactions that are thumb-driven | ~75% |

And the specific finding that decides it: **the lower-left quarter is not reachable by any finger
for a right-handed one-handed user without a grip change.** Bottom-left is the single worst zone on
the screen for the dominant grip — roughly a third of all sessions (49% one-handed × 67% right).
For a control whose entire premise is "on every screen", that is the wrong corner.

**Three more inputs:**

1. **Convention.** Bottom-right is the established home for assistant/chat entry points (the
   Intercom/Zendesk lineage), and it is the default FAB position precisely because most users are
   right-handed.
2. **Material 3 deprecates the stacked pattern.** The M3 **FAB Menu** "replaces speed dial and
   stacked small FABs" — so stacking a coach pill above Quick Log is a superseded pattern, not a
   neutral choice.
3. **The app already answered this.** `lib/widgets/coach_floating_button.dart` is
   `Positioned(right: 16, bottom: …)` — **bottom-right** — with a collapsed icon-only form and a
   `liftAboveNav` flag. Placement A contradicts Zealova's own shipped widget.

**The constraint nobody had accounted for:** the Quick Log pill is *not* a fixed-width object. It
collapses to an icon-only circle the moment the tab scrolls and re-expands at the top
(`quickLogFabExpandedProvider`, 12px hysteresis, `main_shell.dart:683`), and it is already hidden on
the Coach tab (`selectedIndex != 2`). So the bottom-right band breathes horizontally during scroll.

That kills the naive version of both placements: a coach pill sitting immediately left of Quick Log
would have a neighbour that changes width under it, and a merged control would have to re-flow its
own half.

**Recommendation — a coach button in the bottom-right band, secondary to Quick Log, sharing its
collapse behaviour.**

- Icon-only ✦ circle by default (the `CoachFloatingButton` collapsed form already exists), sitting
  immediately inboard of Quick Log in the same horizontal band.
- Both objects adopt the same scroll-collapse state, so the pair moves as one cluster and the gap
  never breathes independently.
- Quick Log stays the larger, expanded target — it is the daily habitual action; coach is
  deliberate and lower-frequency, so the size ordering matches the frequency ordering.
- Hide rules already have precedent: Quick Log hides on the Coach tab; the coach button should hide
  there too, and defer during an active workout (which has its own Ask-coach pill).

**Both frequent controls stay inside the green thumb zone. Neither is exiled to the one quadrant the
dominant grip cannot reach.**

*Counter-consideration, recorded not dismissed:* the neutral, left-hand-inclusive option is
bottom-**centre**, which discriminates against nobody — but the nav bar already owns that band, so it
is unavailable here. And note Google Health's warning from §2: their users **trigger the AI coach
accidentally** and report it obstructing data. A small, quiet, collapsed icon is the right answer to
that; an expanded labelled pill competing with Quick Log is not.

### R2 — Pick one hero number

Three composites (Today Score, Strength Score, Recovery/Readiness) with no stated hierarchy.
Samsung ships exactly one dashboard number and makes the rest drill-downs. Nominate one, give it the
largest type on Home, demote the others to inputs. **No hardware dependency** — Today Score is the
natural pick precisely because it computes without a wearable.

### R3 — Deviation-from-baseline copy

Their genuinely better idea. "Ready 68%" is a number; "12% below your 30-day baseline" is an
instruction. Apply it first to metrics Zealova owns outright — weight, volume, calorie adherence,
sleep duration, steps — and to wearable signals only where data exists. The 28-day baseline
machinery behind `/health/vitals` is already there.

### R3b — The state ramp must encode VALENCE, not position  *(found 2026-08-11)*

A naive below / at / above ramp is **wrong for inverted metrics**, and it will ship wrong if this
is not specified.

Rendering "2% above baseline" on **resting heart rate** in the same green used for "6 pts above
your Today Score" tells the user that a rising RHR is good. It is not — for RHR, above baseline is
mild strain. The ramp as first described encodes *position relative to baseline*; what the user
reads is *valence* (good / neutral / bad). Those two are the same for some metrics and opposite for
others:

| Metric | Above baseline means |
|---|---|
| Today Score, steps, HRV, sleep duration, readiness | better |
| **Resting HR, respiratory rate, stress, skin temperature** | **worse** |
| Weight, calories | depends on the user's goal — neither by default |

**The requirement:** each metric declares its own valence, and the ramp reads that, not the sign of
the delta. Three states — `supports` / `neutral` / `strains` — not `above` / `at` / `below`. This is
also exactly Oura's framing (§2): their semantic colour system communicates how habits *"support or
strain"* health, which is valence, not direction. Getting this wrong is worse than shipping no
colour at all, because a confidently-wrong colour is trusted.

Inverted metrics with no configured goal (weight, calories) take `--t3` and no dot — neutral is a
legitimate state and must be renderable.

### R4 — Delete the dead sections

Remove `strainCoach` and `metricTrio` from `_defaultOrder` (keep the enum values so persisted custom
layouts don't break — the existing pattern), and either add `metricsCarousel` to `_defaultOrder` or
delete its misleading comment. This is Finding 1, and it is the cheapest item here.

### R5 — Tile sizing in My Space

The one customisation feature Zealova lacks. Two sizes (full-width / half-width) over the cards that
already have compact variants — avoids the 2×2 grid complexity that forced Samsung to drop 3×1.

### R6 — Rank and cap the contextual card stack

`ExtendedHomeCardsStack` mounts 80 self-collapsing cards. Even at zero render cost, it is the
mechanism by which Home grows without anyone deciding it should. Cap how many may fire on one day
and rank them. Samsung's own experience says unwanted cards in prime space is the thing users
punish hardest.

### Do **not** copy

| Samsung did | Why not |
|---|---|
| Undismissable Insights / banners; immovable widgets | Their #1 complaint. Zealova's hideable-everything model is a real lead — protect it. |
| Colour-per-card with no rule | Miss #1 in every review. Zealova's accent discipline is a differentiator. |
| Shipping visible-but-locked features | Zealova has no hardware gate; keep it that way, and keep per-signal empty states over dead screens. |
| Chasing BIA body comp / skin temp | Hardware moats. Unwinnable without shipping a device (§4). |
| Cutting guided programs | Programs are a Zealova moat, not a cost centre. |
| Ads in a health surface | — |

---

## 8. Proposed Home structure

> **Constraint — read before touching `_defaultOrder`.**
> A home reorder was **proposed and REJECTED on 2026-06-11**, with the recorded lesson: *"home
> layout is heavily user-tuned — read the version-history comments in `home_sections_provider.dart`
> before proposing any home reorder."* The order carries a deliberate v27→v34 history.
> **Therefore: the only default-order edit proposed here is deleting the two sections that cannot
> render (R4). Everything else is additive.** An earlier draft of this section proposed dropping
> `quickActions`, `cycle` and `weekStrip` and re-sequencing the rest; that has been withdrawn.
> `quickActions` in particular is protected by a separate explicit decision (the shortcut row must
> stay visible, and the trailing **More** tile must never be removed).

**Now** (default layout, top to bottom):

```
MinimalHeader
StackedBannerPanel
CycleSetupHomePrompt
HomeMetricsStrip
weekStrip (hidden by default)
todayScore  → StrengthBreakdown
quickActions
coachHero
workoutCard + TodayAddonsRow + SetupChecklistCard
strainCoach → renders nothing        ← DELETE (R4)
nutritionCard → FuelStrip
cycle
metricTrio → renders nothing         ← DELETE (R4)
weeklyReport → Reports · Recap
ExtendedHomeCardsStack (up to 80)
HeroFastingCard
timeline
```

**Proposed** — two deletions and three in-place content changes. **No insertion, no re-sequencing**
(the pillar bar from an earlier draft is withdrawn — see R1):

```
MinimalHeader                        ← + quiet global coach pill (R1b)
StackedBannerPanel
CycleSetupHomePrompt
HomeMetricsStrip                     ← same slot, deviation copy (R3)
weekStrip (hidden by default)
todayScore                           ← same slot, becomes THE hero number (R2)
quickActions                         ← unchanged, protected
coachHero                            ← same slot, drops its duplicate composites (R2)
workoutCard + TodayAddonsRow + SetupChecklistCard
nutritionCard
cycle
weeklyReport
ExtendedHomeCardsStack               ← same slot, ranked + capped (R6)
HeroFastingCard
timeline
```

Every existing section keeps its position. Nothing becomes unreachable. The two deleted entries
stay in the `HomeSection` enum so persisted custom layouts don't break — the established pattern.

## 9. Verification receipts

| Claim | Checked |
|---|---|
| 5 bottom tabs | `lib/widgets/main_shell_part_edge_panel_handle.dart:235-313` |
| 5 shell branches | `lib/navigation/app_router_main_shell_routes.dart:12-131` |
| Health routes exist | `lib/navigation/app_router_utility_routes.dart:98-127` |
| `fitness-index` entry points = 1 | grep across `lib/`, excluding `navigation/` |
| `heart-health` entry points = 2 | same |
| Vitals: 28-day baseline, per-signal `no_data` | `lib/screens/health/vitals_detail_screen.dart:15-18, 316-343`; `lib/data/repositories/vitals_repository.dart:6-11` |
| Default order / dead sections | `lib/data/providers/home_sections_provider.dart:233-262`; `home_screen.dart` `_widgetForSection` |
| My Space lists `order` verbatim | `lib/screens/home/home_my_space_screen.dart:129-138, 214` |
| 80 contextual cards | `lib/screens/home/home_screen.dart` — `ExtendedHomeCardsStack` comment |
| 103 home widget files | `ls lib/screens/home/widgets/ \| wc -l` |

---

## Sources

### Google Health (2026)

- [What is new with the redesigned Google Health app — Google Health Help Center](https://support.google.com/googlehealth/answer/17068213?hl=en)
- [Explore the Google Health app — Google Health Help Center](https://support.google.com/googlehealth/answer/14237011?hl=en)
- [I actually don't hate the new Google Health app, but it could still use some work (Android Central)](https://www.androidcentral.com/apps-software/google-health-app-impressions)
- [Fitbit users revolt against Google Health app redesign as missing features & UI issues pile up (PiunikaWeb)](https://piunikaweb.com/2026/05/25/google-health-app-fitbit-backlash-missing-features-ui-changes/)
- [Here's the best way to set up the new Google Health app (Droid Life)](https://www.droid-life.com/2026/06/01/heres-the-best-way-to-setup-the-new-google-health-app/)
- [Google Health 5.0 brings new Fitbit app design, AI coach, and Android widget (TechRepublic)](https://www.techrepublic.com/article/news-google-health-fitbit-app-ai-coach-widget/)
- [Google previews personal health coach for Fitbit (Google blog)](https://blog.google/products-and-platforms/devices/fitbit/fitbit-ai-personal-health-coach-preview/)
- [Personal Health Coach with Gemini (Google Store)](https://store.google.com/magazine/personal_health_coach?hl=en-US)
- [Google Health 5.02 rolls out: expanded stats view, hourly activity (9to5Google)](https://9to5google.com/2026/06/22/google-health-5-02-release-notes/)
- [Focus on key stats in Google Health: July update (Android Central)](https://www.androidcentral.com/wearables/fitbit/focus-on-key-stats-in-google-health-july-update-drops-tiles-and-more-on-android)
- [Get to know the redesigned Fitbit app — the 2023 three-tab redesign, incl. the Coach tab later deleted (Google blog)](https://blog.google/products-and-platforms/devices/fitbit/fitbit-app-redesign/)

### Hevy (the social model)

- [Hevy App Social Guide: Connect, Follow, and Share Your Workouts — Hevy Help Centre](https://help.hevyapp.com/hc/en-us/articles/35688036014231-Hevy-App-Social-Guide-Connect-Follow-and-Share-Your-Workouts)
- [Hevy's Social Features and How to Use Them](https://www.hevyapp.com/features/social-features/)
- [Explore Hevy's Social Content Feed and Options](https://www.hevyapp.com/features/content-feed/)
- [Use the Discovery Feed to Find New Users](https://www.hevyapp.com/features/discovery-feed/)
- [How Hevy Achieved $160K MRR by Revolutionizing Workout Tracking (Starter Story)](https://www.starterstory.com/hevy-breakdown)
- [Hevy vs Strong (2026): Which Workout Tracker Should You Use? (GainFrame)](https://gainframe.app/blog/hevy-vs-strong/)

### Coach-button placement (reachability + FAB patterns)

- [How Do Users Really Hold Mobile Devices? — Steven Hoober, UXmatters](https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php)
- [The Thumb Zone: Designing for Mobile Users — Smashing Magazine](https://www.smashingmagazine.com/2016/09/the-thumb-zone-designing-for-mobile-users/)
- [How to Design for Thumbs in the Era of Huge Screens — Scott Hurff](https://www.scotthurff.com/posts/how-to-design-for-thumbs-in-the-era-of-huge-screens/)
- [Mastering the Thumb Zone: Mobile UX & UI Design Guide](https://parachutedesign.ca/blog/thumb-zone-ux/)
- [FAB Menu — Material Design 3](https://m3.material.io/components/fab-menu)
- [FAB — Material Design 3](https://m3.material.io/components/floating-action-button)
- [Floating Action Button UI Design: best practices and variants — Mobbin](https://mobbin.com/glossary/floating-action-button)
- [Where should AI sit in your UI? — UX Collective](https://uxdesign.cc/where-should-ai-sit-in-your-ui-1710a258390e)
- [Floating Action Buttons are bad, and what to do instead — Erik Kroes (accessibility counterpoint)](https://www.erikkroes.nl/blog/floating-action-buttons-are-bad-and-what-to-do-instead-1/)

### Samsung Health (2026)

- [I tried Samsung Health's huge redesign for 2026 — 5 biggest hits and misses (Android Authority)](https://www.androidauthority.com/samsung-health-app-2026-update-hands-on-3679261/)
- [Samsung Health gets a major redesign and new AI-powered health features (SamMobile)](https://www.sammobile.com/news/major-samsung-health-update-revamped-ui-new-ai-features/)
- [Samsung finally releases major Health app update with revamped UI (SamMobile)](https://www.sammobile.com/news/samsung-finally-releases-major-health-app-update-revamped-ui-new-features/)
- [There's an all new Samsung Health, and here's what's changed (SamMobile)](https://www.sammobile.com/news/theres-an-all-new-samsung-health-and-heres-whats-changed/)
- [5 recent updates to Samsung's Health app that have users talking (SlashGear)](https://www.slashgear.com/2205926/new-samsung-health-app-updates-have-users-split-love-hate-useful-or-not/)
- [Samsung Health Update feedback — Samsung Community](https://us.community.samsung.com/t5/Samsung-Apps-and-Services/Samsung-Health-Update-feedback/m-p/3604909)
- [The Samsung Health App update from 25 June 2026 is not good — Samsung Community](https://us.community.samsung.com/t5/Samsung-Apps-and-Services/The-Samsung-Health-App-update-from-25-June-2026-is-not-good/m-p/3602987)
- [The Samsung Health App Update Issues — Samsung Community](https://us.community.samsung.com/t5/Samsung-Apps-and-Services/The-Samsung-Health-App-Update-Issues/td-p/3601965)
- [Samsung Health One UI 9 redesign is finally rolling out (Sammy Fans)](https://www.sammyfans.com/2026/06/17/samsung-health-one-ui-9-redesign-is-finally-rolling-out/)
- [Samsung Health app redesign arrives June 8 with home dashboard (NewsBytes)](https://www.newsbytesapp.com/news/science/samsung-health-app-redesign-arrives-june-8-with-home-dashboard/tldr)
- [Samsung Health is axing popular fitness programs as a bigger redesign looms (Android Central)](https://www.androidcentral.com/apps-software/samsung-health-is-axing-popular-fitness-programs-as-a-bigger-redesign-looms)
- [Samsung Health Update Leaves Galaxy Watch Owners Waiting on Key AI Features (TechRepublic)](https://www.techrepublic.com/article/news-samsung-health-watch-features/)
