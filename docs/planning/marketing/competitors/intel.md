# Competitor Intelligence — Zealova

> Canonical competitor profiles for downstream agents (comparison-page-writer, blog-writer, ad-creator, geo-strategist). Append, never overwrite.

---

## Gravl — Competitor Intelligence Profile

**Last updated:** 2026-06-03
**Peer set:** AI strength-training apps (Fitbod, Future, Freeletics, Caliber)
**Category:** Workout AI (direct moat overlap with Zealova workout generation)

### Identity (verified)
Gravl is "Personal Trainer: Gravl," an AI personal-trainer app focused on gym strength training / hypertrophy. Developer: **GAINS COACH PTY LTD** (brand "GAINS AI"); founder **Julian Gargicevich** (Reddit/community handle `juliang8`). Originally launched as "Gains AI," rebranded to Gravl. Site: gravl.ai. iOS App Store ID 6450921637; Android package `com.liteup.getgains`; support@gravl.ai. iOS + Android only — no standalone web app (app.gravl.ai serves only public workout-share pages that funnel to the mobile apps). Disambiguated from gravel-cycling/clothing brands and from gravl.io (an unrelated Techstars research-services company).

### What Gravl is (verified)
An adaptive, equipment-aware AI strength planner for home / outdoor / commercial-gym settings (gym profiles labeled Large/Small/Garage Gym). Goals: build muscle, get stronger, get lean. ~20-step onboarding then a soft paywall. Positions itself "Unlike existing fitness apps" against generic workout generators. Only benchmarks against Fitbod (its own help-center "Fitbod vs Gravl" page); no first-party head-to-head vs Future/Freeletics/Caliber.

### AI capabilities
- **Gravl Algorithm / Recovery Split (verified):** Recovery-aware split engine that models per-muscle-group fatigue and dynamically schedules which muscles to train. Recovery % drops after a session based on sets done + exertion rating; at <=60% recovery it suggests a rest day; self-compensates for skipped groups; aims to hit each muscle ~twice/week. Frequency scales with weekly goal. Adapts intensity/volume/weight from demographics + logged patterns.
- **Progressive overload (verified):** Weights/reps adjusted from recent performance, exertion rating, exercise position.
- **Strength Score (verified):** Demographic-benchmarked metric. Marketing: "8 subscores, millions of data points across same age/gender/bodyweight." Help center: deterministic formula (projected 1RM from best lift in last 3 months, normalized by bodyweight).
- **AI form checker (verified, opaque):** Shipped v1.39 (Jan 20 2026). Upload a lift video → technique feedback. ZERO technical detail disclosed (no pose model, CV framework, score corroboration, or supported-lift scope).
- **AI workout imports + voice-generated workouts (verified):** Import an existing split from link/PDF/photo/social media. Graduated beta → core by v1.44 (May 2026).
- **Underlying tech (UNVERIFIED):** Never names an LLM/GPT/CV library. Described only as a "scientific algorithm" — reads as rules + sports-science heuristics, not a learned model. React Native + Expo + .NET (founder-disclosed).
- **NO conversational AI chat coach (verified):** In-app "coach" messaging is with HUMAN trainers, not an LLM chatbot. Clear gap vs Zealova's multi-agent chat.
- **NO nutrition feature (likely absent):** Users praise the ABSENCE of forced food tracking. Deliberately out of scope.

### Pricing
- **Official (verified):** gravl.ai/pricing — $14.99/mo, $34.99/3mo, $69.99/yr (all "Unlimited workouts").
- **App Store IAP catalog (verified):** Monthly $14.99; 3 Months $34.99; multiple Yearly SKUs ($48 / $59.99 / $79.99); credit packs ($9.99/$19.99/$29.99); Lifetime $199 on at least one storefront. Multiple yearly SKUs = A/B/promo/regional cohorts.
- **Free start (verified):** First 3 workouts free, no card (usage-capped, not time-boxed).
- **Paywall (verified):** Soft paywall sprung AFTER ~20-step onboarding + plan generation; 25%-off close-intent popup. The post-onboarding placement is the #1 user complaint ("misleading/sketchy").
- **Revenue scale (founder-disclosed, not audited):** ~$440K/mo, 70,000+ paying subs, ~13-person team, bootstrapped, launched off a single Reddit post (~300K impressions). ~1/3 revenue (~$145K/mo) on ads (Meta/TikTok/Google/Apple Search).

### App-store presence + cadence (verified)
- iOS: 4.9/5 from ~2.8K ratings; current v1.45 (May 23 2026).
- Android: `com.liteup.getgains`, "1M+" installs; current v1.46 (May 25 2026).
- **Cadence:** Very high — 2-4 releases/month sustained. Active public feedback board users love. **No formal roadmap/changelog/TestFlight; founder telegraphs upcoming features via community posts.** Blog stale (last 2024).
- Shipped integrations: Strava (Oct 2025), AirPods Pro HR (Feb 2026), Apple Watch (sync + PR feedback), Health Connect (Android), offline warm-up videos, iOS 26 "Liquid Glass" styling, 300+ trainer-led exercise videos.
- **Android wearable gap (verified):** No Samsung/Galaxy Watch sync (most-requested Android complaint).

### User sentiment
Strongly positive (4.9 both stores; ~66.7% positive free-text across ~2,277 reviews).
- **Praises:** Kills decision fatigue / gym anxiety; clean app; good progressive overload; plate calculator; trainer-led form videos; no forced food tracking; fast-shipping devs + public feedback board.
- **Complaints:** Hard paywall after onboarding (#1); white-screen-on-finish bug (lost workouts, patched); freezes/lockouts; **limited exercise library / missing standard lifts** (flat barbell bench disappeared); **weak AI "memory" week-to-week**; **history limited to ~1 month**; clunky editing; Android crashes + no Galaxy Watch; "Fitbod copycat" is the sharpest competitive jab; value gripes at ~$11-15/mo.
- **Top user requests:** Bigger movement DB; **custom/adjustable equipment** (grip trainers, grip rings); **cardio session inside a strength split** (e.g. 5-10 min treadmill/row on leg day); smarter AI memory; longer history; Samsung wearable support; less rigid scheduling/editing.

---

## Gravl vs Zealova — Capability Matrix (2026-06-03)

| Capability | Gravl | Zealova | Edge |
|---|---|---|---|
| Workout generation engine | Recovery Split: recovery-aware per-muscle fatigue model; "scientific algorithm" (no LLM/ML named); equipment-aware gym profiles | Hybrid pipeline: deterministic Exercise RAG selection → Gemini orchestration → deterministic post-gen rules (age caps, recovery-aware RIR, goal-aware RIR); ~80 context fields incl. cycle phase, wearable recovery | **parity** |
| Form analysis (CV) | Shipped but a black box; no method/score/scope disclosed | FFmpeg keyframe → Gemini Vision → structured schema; 1-10 score, rep count, per-issue severity/correction, breathing + tempo, NSCA-cited cues, multi-video trend; public unauth tool; form score gates progression | **zealova-ahead** |
| Adaptive / progressive programming | Progressive overload from performance + exertion + recovery; AI "memory" criticized as weak | Explicit RPE thresholds (7.5/8.5/9.5), user-set pace, per-exercise strategies (linear/double/wave/deload), form-gated, deload detection, bidirectional RPE↔%1RM, 6-bracket age caps | **zealova-ahead** |
| Injury handling / RTP | None found (recovery = fatigue scheduling, not rehab) | Phase-aware injury directives resolver, rehab library (McGill Big 3, ACL, shoulder), deterministic safe-swap validator (fail-closed), RTP protocols w/ load milestones | **zealova-ahead** |
| Conversational AI coach chat | NONE — "coach" = human trainers | LangGraph multi-agent (coach/nutrition/workout/injury/hydration) + Vision media routing + apply-able changes + in-workout "this hurts" | **zealova-ahead** |
| Nutrition | None; users praise the absence | Full stack: calculator, meal rec, RAG, food-photo + menu-scan + screenshot OCR, dynamic targets | **zealova-ahead** |
| Strength/benchmark score | Strength Score (projected-1RM, peer-benchmarked); well-marketed, "mysterious" | Fitness Score (Strength 40% / Consistency 30% / Nutrition 20% / Readiness 10%), 5 levels; broader but less peer-benchmark marketing | **parity** |
| Social / community + leaderboards | Active build-out: "Crew" feed (scores/badges/heatmaps/streaks/rankings) + username search, QR invites | Leaderboard service (challenges, volume kings, streaks, weekly), social RAG, gamification (XP/trophies/Wrapped); friend-discovery less polished | **parity** |
| Wearable / health integration | Apple Health, Apple Watch (sync+PR), Health Connect, Strava, AirPods HR; NO Samsung Watch | Wearable recovery (HRV/RHR/sleep) feeds generation; Health Connect parity build (17 gaps); Strava/AirPods parity unconfirmed | **unknown** |
| Pricing | $14.99/mo, $69.99/yr; 3 free workouts | $7.99/mo + $59.99/yr + 7-day trial → $47.99/yr retention; single-tier | **zealova-ahead** |
| Ship cadence | Very high (2-4 releases/mo), public feedback board | High velocity across many surfaces; store-release rhythm not directly measurable | **unknown** |

---

## CONFIRMED UPCOMING RELEASE — posted pre-release by founder (`juliang8`), ~June 2026

> Founder posted the full feature list before release: *"Trying something new this time and will post the new features before we release them, we recently grew our team and it's showing, probably one of our biggest releases yet."* This validates the recon finding that Gravl has no formal roadmap and telegraphs releases through community posts. Screenshots confirm an iOS-first "Liquid Glass"-styled feature carousel.

**Shipped in this release:**
1. **Workout share editor** — templates, stickers, photo effects, fonts, color controls, Instagram sharing improvements. Notable distinctive format: a "now playing"/music-track share card ("UPPER BODY feat CORE — 9,128 kg, 258 kcal") — founder's personal favorite.
2. **Progress photos for body metrics** — capture, upload, gallery, before/after comparison.
3. **Workout AI summaries for completed workouts** — "AI summary: See what stood out in this workout" card on the completed-session screen. (Only net-new *AI* capability in the release; post-hoc + lightweight.)
4. **Updated dark/light theme.**
5. **Strength Score upgrades** — per-exercise score targets, in-workout score badges, level celebrations, friend score badges, stale-score recommendations, new excluded-muscle settings.
6. **Smarter exercise recommendations** — prioritize muscles/exercises that need updated score data.
7. **Streak improvements** — streak rewards, freeze syncing, equipped freezes (earn 1 per 10 streak weeks), timeframe sheets, celebration screens, refreshed streak/progress UI, leaderboard (Current Streak / Workouts tabs).
8. **First-day-of-week setting** — respected across streaks, trends, measurements, calendars, activity views. (Repeatedly requested; community delighted.)
9. **Onboarding / coachmarks / quick-workout walkthroughs / deep-link recovery** for web/onboarding flows.
10. **Screen refreshes** — Library, Progress, Profile, Settings, exercise analytics, workout summary, friend activity.
11. **Apple Health workout sync** — incl. background sync for external workouts.
12. **Bug fixes** — timezone date-shifting across feed/calendar/summaries/history; background rest-timer + short rest times; logging responsiveness, keyboard/input polish, note editing; start/back-stack, active-workout cancel, pending-save visibility, watch sync.

**Strategic read:** This is a large release but it is ~90% **growth/viral + retention/gamification + polish** (share editor, progress photos, AI summaries, Strength-Score gamification, streaks/freezes, first-day-of-week, UI refresh, bug fixes). It is **NOT a frontal assault on the AI-programming or form-analysis moat** — no new programming intelligence, no form-checker expansion, no conversational AI. The single net-new AI feature ("workout AI summaries") is post-hoc and shallow.

**Predicted-vs-actual (from 2026-06-03 recon):**
| Recon prediction | Likelihood called | Outcome |
|---|---|---|
| Deeper social/competitive layer (leaderboards, streaks, feed) | HIGH | ✅ **HIT** (streaks new home + freezes + friend score badges + leaderboard) |
| Onboarding/paywall + reliability hardening | MEDIUM | ✅ **HIT** (onboarding/coachmark/deep-link + heavy bug-fix list) |
| Cardio/wearable expansion | MEDIUM | ⚠️ **PARTIAL** (Apple Health background sync; cardio-in-split still NOT shipped despite repeated requests) |
| Expanded AI form checker | HIGH | ❌ **MISS** (not in this release) |
| Exercise library expansion / better AI memory / longer history | MEDIUM | ❌ **MISS** (top churn complaints still unaddressed) |
| Conversational AI chat coach | LOW | ❌ **MISS** (still human-trainer only — moat intact) |

**Open opportunities Gravl's own users are begging for (NOT shipped):**
- **Custom / adjustable equipment** (grip strength trainer 10-160 lbs, grip rings, finger exercisers). Top sticky comment.
- **Cardio session inside a strength split** (5-10 min treadmill/row on leg day). Repeated comment.
- Bigger movement DB / missing standard lifts; smarter week-to-week AI memory; longer history; Samsung Watch sync.

---
