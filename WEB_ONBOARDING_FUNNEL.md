# Web Onboarding Quiz Funnel — Zealova

**Status**: DEFERRED — build after app is live in Play Store + App Store and paid UA is planned.
**Priority**: Post-launch growth feature, not a launch blocker.
**Estimated effort**: ~2-3 engineer-weeks.
**Last updated**: 2026-04-15

---

## Executive Summary

A web quiz funnel captures users from Instagram/TikTok ads BEFORE they reach the app store. Users answer 12 quick questions on a mobile web page, see a personalized "creating your plan..." loading screen, sign up with email, then download the app — where they skip onboarding because their data is already saved.

**Why build this:**
- **Conversion lift**: 3-5% quiz-to-subscriber vs 0.5-2% direct-to-app-store (RevenueCat 2024 benchmarks)
- **Retention lift**: D30 +8-15pp — quiz filters out tire-kickers via sunk-cost commitment (Adapty 2024 data)
- **AI personalization**: Quiz answers feed LangGraph coach agent system prompts before first app open
- **Data**: Every quiz answer is a training signal for workout generation

**Why NOT build for launch:**
The app isn't in stores yet. No paid UA budget. The funnel only pays off with ad spend driving traffic to it. Launch the app first, validate product-market fit, then build this when ads are ready.

---

## Competitor Reference

**Our model (Model A — SmartyMe/Fastic pattern):**
```
Instagram ad → Web quiz (12 Qs) → "Creating your plan..." → Plan reveal
→ Email signup (free) → "Get the app" → App Store / Play Store
→ User opens app → signs in → backend sees web_quiz → skips onboarding
→ Coach selection → Paywall (in-app IAP via RevenueCat)
```

**Alternative model we chose NOT to build (Model B — Noom/Cal AI pattern):**
```
Same as above, but inserts a Stripe web paywall BEFORE "Get the app".
User pays on web → keeps 100% revenue (no Apple/Google 30% cut).
Requires RevenueCat Web Billing + Stripe webhooks + entitlement sync.
```

| Aspect | Model A (ours) | Model B (Noom/Cal AI) |
|---|---|---|
| Web payment | No — paywall in-app via IAP | Yes — Stripe on web |
| Apple/Google cut | 30% (15% after year 1) | 0% on web purchases |
| Engineering cost | ~2-3 weeks | ~4-5 weeks |
| Complexity | Low | High (webhooks, entitlement sync, refunds) |
| Best for | Pre-scale, <$20k/mo ad spend | Scaled UA, >$20k/mo ad spend |

### Why no web payment (decision record)

1. **App isn't in stores yet.** Can't test the full handoff (web payment → app unlock) without a published app.
2. **No RevenueCat Web Billing needed.** Saves ~1 week of Stripe webhook + promotional entitlement plumbing.
3. **No App Store review risk.** Apple scrutinizes external-purchase links. Clean IAP-only launch is safer.
4. **No paid UA yet.** The margin uplift from skipping IAP is $0 until there's ad spend.
5. **The quiz itself is the lever, not the payment location.** ~70% of the conversion + retention uplift comes from commitment psychology. The remaining ~30% (margin) only materializes at scale.
6. **Easy to add later.** Nothing in Model A blocks adding a Stripe paywall step later as a separate project.

---

## Full User Flow (End-to-End)

### Phase 1: Web Quiz (Instagram/TikTok ad → web)

```
User sees Instagram ad → taps link → opens mobile web browser

Step 1: /start (marketing landing)
  "Get your personalized AI fitness plan"
  [Take the 90-second quiz →]

Step 2: /quiz/1 through /quiz/12 (one question per page)
  Progress bar fills from ~8% to ~90%
  Answers stored in localStorage (Zustand persisted store)
  Back button works, refresh doesn't lose progress

Step 3: /quiz/loading (8-12 second staged progress screen)
  "Creating your fitness plan..."
  ├── "Analyzing your goals..."          → 100% ✓
  ├── "Matching exercises..."            → 100% ✓
  ├── "Calibrating AI coach..."          → 100% ✓
  └── "Finalizing your plan..."          → 55%...
  
  Social proof card shown during loading:
  "1.5M+ workouts generated"
  ★★★★★ "Best AI fitness app I've used" — App Store Review
  
  Intermediate popup questions during loading (SmartyMe pattern):
  "A few final things..."
  "Do you prefer morning or evening workouts?" [Morning] [Evening]
  "Can you commit to 4 weeks?" [Yes] [I'll try]

Step 4: /quiz/plan (personalized plan reveal)
  "Based on your answers, you can reach {target_weight} lbs by {calculated_date}"
  + 3 sample workout previews (AI-generated from quiz data)
  + 1 testimonial card
  [Get my plan →]

Step 5: /quiz/signup (account creation)
  Email input + "Continue with Google" button
  → Supabase Auth: signInWithOtp({ email }) or Google OAuth
  → POST /api/v1/users/{user_id}/preferences with all 12 quiz answers
  → Sets acquisition_source = 'web_quiz' on user record
  → Backend kicks off Day-1 workout generation in background

Step 6: /quiz/download (terminal screen)
  "Your plan is ready! Download Zealova to start."
  [Get on Google Play]  [Download on App Store]
  "We also emailed you a magic link to sign in instantly."
```

### Phase 2: App Store → Install → First App Open

```
User taps Play Store / App Store badge → installs app → opens it
```

**Critical question: How does the app know this user came from the web funnel?**

**Answer: It doesn't. The app shows the same sign-in screen to ALL new users. The backend decides what happens after authentication.**

```
App opens for the first time:
┌─────────────────────────────┐
│       Welcome to Zealova     │
│                             │
│  ┌───────────────────────┐  │
│  │  Continue with Google  │  │  ← Same as current auth screen
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │  Continue with Email   │  │  ← Email OTP (passwordless)
│  └───────────────────────┘  │
└─────────────────────────────┘

User signs in with the SAME method they used on web
(Google OAuth matches Google OAuth, email matches email)
```

**After sign-in, the backend routes the experience:**

```
App calls GET /api/v1/users/me
  ↓
Backend checks user record:
  ├── acquisition_source = 'web_quiz' AND preferences populated?
  │     → YES: Skip entire pre-auth quiz (11 screens)
  │            Show welcome splash: "Welcome, {name}! Your plan is ready."
  │            Go directly to remaining in-app setup (4 screens)
  │
  └── acquisition_source = NULL?
        → NO: Normal full in-app onboarding (11 screens, same as today)
```

### Phase 3: Remaining In-App Setup (web-funnel users only — 4 screens, ~60 seconds)

```
Screen 1: Coach Persona Selection (required)
  Visual cards with personality previews
  "Choose your AI coach style"
  [Drill Sergeant] [Supportive Friend] [Science Nerd] [Zen Master]

Screen 2: Optional Tweaks (skippable)
  "Anything else to customize?"
  ├── Muscle focus points (slider — defaults to balanced)
  ├── Training style (strength / cardio / mixed — defaults to mixed)
  └── Progression pace (slow / moderate / fast — defaults to moderate)
  [Looks good →] (skip with defaults)

Screen 3: Notification Permission
  Native iOS/Android permission prompt

Screen 4: Paywall
  RevenueCat IAP subscription screen (same as current paywall)
  Monthly / Yearly / Free trial options
```

### Phase 4: Home Screen

```
Day-1 workout is already generated and waiting
(Backend started generating it when the web quiz was submitted)
User sees their personalized workout immediately — no "generating..." spinner
```

### Auth Matching: Avoiding Orphaned Accounts

**Problem:** If user signs up with email on web but taps "Continue with Google" in app, Supabase creates two different auth users. Quiz data is orphaned.

**Solution:** Offer the SAME auth methods on both web and app:
- Web signup screen: "Continue with Google" button + "Continue with Email" option
- App sign-in screen: "Continue with Google" button + "Continue with Email" option
- Users naturally pick the same method in both places → same Supabase auth ID → match

**Fallback:** If accounts don't match (different auth method), after sign-in check if the email exists in another auth record with `acquisition_source='web_quiz'`. If found, prompt: "We found your plan from zealova.com. Link accounts?" → Supabase admin API merges.

---

## Quiz Questions (12 total, ~2 minutes)

| # | Question | Input Type | Options |
|---|---|---|---|
| 1 | What's your gender? | Single-select tiles (illustrated) | Male / Female / Other |
| 2 | What's your primary goal? | Single-select tiles | Lose weight / Build muscle / Increase strength / Stay active |
| 3 | How old are you? | Number input (13-80) | -- |
| 4 | How tall are you? | Number + ft-in or cm toggle | -- |
| 5 | What's your current weight? | Number + lb/kg toggle | -- |
| 6 | What's your target weight? | Number (same unit as Q5) | Derives direction + timeline |
| 7 | How would you describe your activity level? | Single-select | Sedentary / Lightly active / Moderately active / Very active |
| 8 | What's your training experience? | Single-select | Beginner / Intermediate / Advanced |
| 9 | How many days per week can you work out? | Single-select | 3 / 4 / 5 / 6-7 |
| 10 | How long can each session be? | Single-select | 15-30 min / 30-45 min / 45-60 min / 60+ min |
| 11 | What equipment do you have access to? | Single-select | Full gym / Dumbbells + bench at home / Bodyweight only / Mixed |
| 12 | Any injuries or areas to avoid? | Multi-select tiles | None / Knees / Lower back / Shoulders / Neck / Other |

**Ordering rationale:** Easy demographic (low friction) → aspirational goal (emotional hook) → body stats (investment) → experience/commitment → safety. Mirrors Noom/Cal AI/SmartyMe sequencing. More questions = more commitment, which is a net conversion win up to ~20 questions.

---

## Question Migration Table

What moves from in-app onboarding to web, what stays, what gets defaults:

| Current In-App Question | Where It Goes | Why |
|---|---|---|
| Fitness goals (multi-select) | **Web Q2** (single primary goal) | Primary goal is enough to start; secondary goals inferred |
| Fitness level + experience + activity | **Web Q7 + Q8** | Separate single-selects on web |
| Days/week + specific days + duration | **Web Q9 + Q10** (specific days dropped) | Day-picker is awkward on mobile web; default to "any day" |
| Equipment + environment | **Web Q11** | Simplified to preset bundles |
| Injuries/limitations | **Web Q12** | Safety-critical, must collect before any plan |
| Body metrics (name, DOB, gender, height, weight, target) | **Web Q1-Q6** | Name at signup, DOB derived from age |
| Primary training focus | **In-app** | Better as illustrated tiles next to coach persona |
| Muscle focus points slider | **In-app** | Complex drag UI, doesn't translate to mobile web |
| Training style preference | **In-app (optional, defaults to "mixed")** | Skippable |
| Progression pace | **In-app (optional, defaults to "moderate")** | Skippable |
| Coach persona selection | **In-app (required)** | Visual tiles with personality previews |
| Nutrition goals + dietary restrictions | **In-app (if nutrition enabled)** | Off critical path for workout launch |
| Meals/day, fasting, wake/sleep time | **In-app (if enabled)** | Secondary nutrition setup |
| Fitness assessment (pushup/pullup/plank/squat) | **Dropped from mandatory flow** | Move to optional "Calibrate" from home screen |
| Sleep quality, obstacles | **Dropped from mandatory flow** | Prompted contextually later |
| Notification permission | **In-app (required)** | Platform API, must be native |
| Paywall | **In-app (required)** | RevenueCat IAP by design |

**Result:** In-app onboarding drops from **11 screens → 4 screens** for web-funnel users.

---

## Technical Implementation

### Existing Code We Reuse

| Component | Path | What It Does |
|---|---|---|
| Vite React SPA | `/frontend/` | Already deployed on Vercel with Tailwind 4, Zustand, Framer Motion |
| Supabase client | `/frontend/src/lib/supabase.ts` | Auth + DB client wired up |
| API client | `/frontend/src/api/client.ts` | Already calls `parseOnboardingResponse()`, `saveOnboardingConversation()` |
| Existing onboarding | `/frontend/src/pages/ConversationalOnboarding.tsx` (28KB), `Onboarding.tsx` (51KB) | Fork for quiz-style presentation |
| Preferences endpoint | `POST /api/v1/users/{user_id}/preferences` | Writes quiz payload to `users.preferences` JSONB + individual columns |
| Deep link scheme | `fitwiz://` in `ios/Runner/Info.plist` | URL scheme configured |

### New Web Files (under `/frontend/src/`)

| File | Purpose |
|---|---|
| `pages/funnel/QuizLanding.tsx` | `/start` route — hero + "Take the 90-second quiz" CTA |
| `pages/funnel/QuizQuestion.tsx` | Reusable component driven by step config — progress bar + question + tiles + back/next |
| `pages/funnel/QuizLoading.tsx` | Staged fake-progress screen with 4 checkpoints + social proof cards + intermediate popup questions |
| `pages/funnel/QuizPlanReveal.tsx` | Personalized plan — computes target date, shows 3 sample workouts + testimonial |
| `pages/funnel/QuizSignup.tsx` | Email OTP + Google OAuth signup → calls Supabase Auth + preferences endpoint |
| `pages/funnel/QuizDownload.tsx` | Terminal screen — App Store + Play Store badges + magic link reminder |
| `store/quizStore.ts` | Zustand store for quiz answers — localStorage-persisted so refresh doesn't lose progress |
| `config/quizSteps.ts` | Array of 12 step configs (question, type, options, validation rules) |
| `hooks/useQuizProgress.ts` | Centralizes navigation + progress bar + localStorage sync |

### Web Files to Modify

| File | Change |
|---|---|
| `App.tsx` (or router) | Add `/start`, `/quiz/*` routes |
| `pages/MarketingLanding.tsx` | Add secondary CTA linking to `/start` |
| `api/client.ts` | Add `submitQuizAnswers(userId, answers)` wrapper |
| `vercel.json` | Verify SPA rewrite catches `/start` and `/quiz/*` |

### Backend Changes

| Change | Details |
|---|---|
| New migration | Add `users.acquisition_source VARCHAR DEFAULT NULL` column |
| Existing endpoint (no change) | `POST /api/v1/users/{user_id}/preferences` already handles the quiz payload |
| New endpoint | `GET /api/v1/users/me/onboarding-state` → returns `{ acquisition_source, onboarding_completed, missing_fields }` so mobile app knows which screens to show |
| Welcome email | Extend `email_lifecycle.py` — send "your plan is ready" email when `acquisition_source='web_quiz'` AND `onboarding_completed=FALSE`. Include magic link + app store badges. Personalize with first name. |

### Mobile App Changes

| File | Change |
|---|---|
| `screens/onboarding/pre_auth_quiz_screen.dart` | Gate entry: if `acquisition_source='web_quiz'` + preferences populated → skip entire pre-auth quiz |
| `navigation/app_router.dart` | Route web-funnel users to `/onboarding/coach-select` on first authenticated open |
| `main.dart` + `AppDelegate.swift` + `AndroidManifest.xml` | Universal-link / app-link handlers for magic link sign-in |
| NEW: `onboarding/web_funnel_welcome_screen.dart` | 1.5s "Welcome, {name}! Your plan is ready" splash for web-funnel users |
| NEW: `onboarding/remaining_setup_screen.dart` | Consolidated optional tweaks (muscle focus, style, pace) with smart defaults + skip |
| `pubspec.yaml` | Add `app_links` package for universal-link handling |

### Deep-Link / Universal-Link Setup

| Platform | Setup |
|---|---|
| **iOS** | Add `applinks:zealova.com` to `ios/Runner/Runner.entitlements`. Host `apple-app-site-association` JSON on marketing domain. |
| **Android** | Add intent-filter with `android:autoVerify="true"` in `AndroidManifest.xml`. Host `assetlinks.json` at `zealova.com/.well-known/assetlinks.json`. |
| **Flutter** | `app_links` package captures inbound universal link → extracts magic-link token → `SupabaseClient.auth.getSessionFromUrl()` |

---

## Analytics (Non-Negotiable)

Funnels require A/B testing from day 1. Without analytics, you can't optimize.

**Tool:** PostHog (free tier, `npm i posthog-js`)

**Events to track:**

| Event | When |
|---|---|
| `quiz_started` | User lands on `/start` and taps CTA |
| `quiz_step_completed_{N}` | Each question answered (N = 1-12) |
| `quiz_abandoned_{N}` | User leaves at question N (inferred from last step without completion) |
| `quiz_loading_started` | Loading screen begins |
| `quiz_plan_revealed` | Plan reveal page shown |
| `quiz_email_captured` | Email submitted on signup page |
| `quiz_google_auth` | Google OAuth used on signup page |
| `quiz_download_clicked` | App Store or Play Store badge tapped |
| `quiz_download_email_clicked` | Magic link in welcome email clicked |

**Funnel visualization:** PostHog funnel from `quiz_started` → `quiz_email_captured` shows drop-off per question.

**First A/B test:** 8 questions vs 12 questions to find conversion sweet spot.

---

## Verification Plan

**End-to-end test on staging:**

1. `cd frontend && npm run dev` — open `/start`, walk through all 12 questions. Verify progress bar fills and back button works at every step.
2. Refresh browser mid-quiz — verify localStorage rehydrates all answers.
3. Complete loading screen — verify 4 stages animate with correct timing (8-12s total) and intermediate popup questions appear.
4. Plan reveal — verify target date calculation is reasonable and sample workouts render.
5. Sign up with email — check Supabase dashboard: new row in `auth.users` + `public.users` with correct `preferences` JSONB and `acquisition_source='web_quiz'`.
6. Query backend: `SELECT preferences, acquisition_source FROM users WHERE email = 'test@test.com'` — confirm all 12 answers persisted.
7. Check that welcome email was sent with magic link + app store badges.
8. Open Flutter app on emulator → sign in with test email → verify pre-auth quiz screens are **skipped** → user lands on coach selection.
9. Complete remaining 4 in-app screens → verify home screen shows pre-generated Day-1 workout.
10. PostHog dashboard — verify `quiz_started` through `quiz_email_captured` funnel shows all events.

**Lighthouse target:** Mobile performance >85 on `/start` (ad landing page speed matters for CPM).

---

## Open Questions (Resolve When Building)

- **Abandoned-quiz emails:** If user reaches Q8 but doesn't sign up, should we capture email earlier (e.g. Q6) for retargeting? Trade-off: earlier email = more friction, more emails.
- **Localization:** English-only initially. When to add Spanish/other?
- **Meta/TikTok pixel:** Add when ads go live — not before.
- **Account linking edge cases:** What if user uses different email on web vs app? Prompt to link, or treat as separate accounts?
- **Pre-generated workouts:** How many days of workouts to pre-generate when quiz completes? 1 day? 7 days? 14 days?

---

## Industry Research (Reference)

### Competitor data points

| App | Revenue model | Web funnel? | Scale |
|---|---|---|---|
| **Cal AI** | Web funnel + Stripe | Yes (custom Next.js) | $30M+ ARR in <12 months, ~90% from web funnel |
| **Noom** | Web funnel + Stripe | Yes (gold standard) | $400M+ ARR, scaled largely on this funnel |
| **BetterMe** | Web funnel + Stripe | Yes (aggressive) | ~$600M revenue, 70%+ from web funnel |
| **SmartyMe** | Quiz → app store (no web payment) | Yes (our model) | Growing, simpler model |
| **Fastic** | Quiz → app store (no web payment) | Yes | Mid-tier, similar to our scope |

### Key conversion numbers (industry benchmarks)

| Metric | Direct-to-app-store | Web quiz funnel |
|---|---|---|
| Ad click → subscriber | 0.5-2% | 3-5% |
| Install → subscriber | 1-3% | 4-8% |
| D30 retention | Baseline | +8-15 percentage points |
| LTV multiplier | 1x | ~1.4x (RevenueCat 2024) |

### Psychology mechanics that drive conversion

1. **IKEA effect / sunk cost:** 12+ questions = user owns "their plan." 2-3x conversion vs cold app store.
2. **Commitment escalation:** Easy questions first → harder → emotional → payment feels natural.
3. **Personalization theater:** "Creating your plan..." loading screen converts ~15% better than instant reveal.
4. **Social proof interstitials:** Testimonials + user counts during loading reinforce trust.
5. **Specific numbers hook:** "You can reach 165 lbs by August 12" is stronger than "lose weight."

### Sources

- Cal AI founder Zach Yadegari on Lenny's Podcast, Oct 2024
- RevenueCat 2024 State of Subscription Apps report
- Adapty 2024 conversion benchmarks
- Growth.Design case study on Noom's quiz funnel
- Superwall 2024 data on trial vs hard paywall
- Epic v. Apple ruling (Judge Gonzalez Rogers, May 2025)
