# Zealova App Store Listing — copy-paste source of truth

Last updated: 2026-05-18

These strings go into App Store Connect → your app → version page → App Information / Pricing and Availability / version-specific fields.

---

## Field-by-field

### App Name — 30 chars max
**Recommended:** `Zealova: Workout & Meal` (23)

**Alternatives** (pick whichever survives App Store name uniqueness check):
- `Zealova: AI Fitness Coach` (25)
- `Zealova - Workout & Meals` (25)
- `Zealova: AI Workouts & Diet` (27)

**Note:** App Store name MUST be unique across the entire App Store. Check via search before locking it in. If `Zealova` alone is taken, fall back to a longer variant.

### Subtitle — 30 chars max (REQUIRED, indexed for search)
**Recommended:** `AI Workout & Meal Coach` (23)

**Alternatives:**
- `Smart Coach. Snap Your Meals.` (29)
- `AI Coach for Gym & Nutrition` (28)
- `Personalized Plans + Vision AI` (30)

### Promotional Text — 170 chars max (editable anytime, doesn't trigger re-review)
**Recommended:** `New: Fasting tracker with live metabolic-stage ring. Plus custom Trends for 100+ metrics. Snap meals, build workouts, track it all in one app.` (145)

### Keywords — 100 chars max, comma-separated, NO SPACES between
**Recommended:**
```
fitness,workout,AI,coach,meal,nutrition,calorie,macro,fasting,fast,strength,plan,tracker,health
```
(96 chars including commas)

Apple ranks keywords roughly equally — pack them tight, no duplicates of the App Name (those auto-index), prefer specific terms over generic ones. Don't include competitor names (Apple rejects) like "MyFitnessPal", "Fitbod", "Hevy".

### Description — 4000 chars max

```
Zealova is the AI coach that builds your workouts, tracks your meals, and runs your fasting timer — all in one place. No spreadsheets. No guesswork.

Type, snap, or scan. Build plans around your gym, your injuries, your schedule, and your real progress. Fast on a schedule that actually fits your life.

▶ AI WORKOUT GENERATION
Daily workouts personalized to your equipment (23+ types), goals, and recovery. The plan adapts every week based on what you actually lifted.

▶ CONVERSATIONAL AI COACH
Ask anything — "swap squats for my knee", "more chest volume", "what should I eat after a 16-hour fast?" The coach edits your plan, suggests meals, and answers in plain English. Unlimited chat on every tier.

▶ VISION FOOD LOGGING
Snap a photo of your plate. Zealova identifies foods, estimates portions, and logs calories + macros in seconds. Restaurant menus and food packaging work too.

▶ INTERMITTENT FASTING
A full fasting tracker — not just a countdown clock.
- Protocols: 14:10, 16:8, 18:6, 20:4, OMAD, 5:2, ADF, extended fasts, or a custom per-weekday schedule
- Live metabolic-stage ring: Fed → Blood Sugar Drop → Fat Burning → Ketosis → Autophagy → Deep Autophagy, with times calculated from your last meal
- Body Status stage-journey view so you always know where you are
- Hydration logging and mood/energy check-ins during fasts
- Pause and resume any fast without losing progress
- iOS Live Activity with controls on your Lock Screen and Dynamic Island
- Built-in Fasting Guide: what happens in your body from 0 hours to 30 days

▶ TRENDS AND CORRELATIONS
Chart 100+ metrics — weight, measurements, macros, micronutrients, calories, water, steps, sleep, mood, energy, glucose, fasting hours, workout volume, strength numbers, and more. Overlay any two on one chart to see their correlation. AI insights surface patterns you'd miss, with event overlays for workout days, fasts, and cycle phases.

▶ ADAPTIVE TDEE AND MACRO TARGETING
Our adaptive TDEE engine learns your real metabolism using trend-weight smoothing, detects metabolic adaptation, and recommends sustainable targets — not the generic 2,000 calories from a basic calculator.

▶ INJURY-AWARE TRAINING
Tell us where it hurts. Workouts auto-exclude problem movements and substitute safer alternatives. Built-in load management prevents overuse before it happens.

▶ MUSCLE AND PROGRESS ANALYTICS
Body heatmap across 24+ muscles. Per-exercise history charts strength gains over time. Streaks, personal bests, and milestone trophies.

▶ NUTRITION INTELLIGENCE
- Inflammation analysis on any logged meal
- Hormonal diet recommendations
- Cooked vs raw food converter
- Frequent foods one-tap re-log
- Voice-to-calories: "two slices pepperoni pizza" → logged

▶ GAMIFICATION THAT KEEPS YOU HONEST
35+ achievements, daily crates, weekly progress reports, and comeback bonuses for getting back on track after a break.

▶ NO ADS. NO DATA SOLD. NO DARK PATTERNS.
Cancel anytime in Settings. Real privacy policy at zealova.com/privacy.

PRICING
Premium: $7.99/mo or $59.99/yr — 7-day free trial, no charge until it ends.

WORKS WITH
- Apple Health (read + write)
- Live Activity for active workouts and active fasts (Dynamic Island + Lock Screen)
- Universal Links for invite and workout shares

Built solo by Sai. Real responses at support@zealova.com — usually within 24h.

Privacy: https://zealova.com/privacy  |  Support: https://zealova.com/support
```

(3 416 chars, well under 4 000 cap)

### What's New in This Version — 4000 chars max
**For first version (1.2.61) — update this block for each subsequent release:**
```
Welcome to Zealova! Your AI workout, meal, and fasting coach. Sign up for a 7-day free trial and get:

• Personalized daily workouts that adapt as you progress
• A conversational AI coach that edits your plan on the fly
• Photo-based food logging — no barcodes, no databases
• Intermittent fasting tracker with live metabolic-stage ring (14:10 through OMAD and beyond)
• Custom Trends: chart 100+ metrics and see correlations between any two
• Injury-aware exercise substitution and adaptive TDEE targeting
• Apple Health sync and Live Activity for workouts and active fasts

Real coach. Real food vision. No ads. Tap to get started.
```

### Marketing URL — full URL
`https://zealova.com`

### Support URL — full URL (REQUIRED)
`https://zealova.com/faq`
(or `https://zealova.com/contact`)

### Privacy Policy URL — full URL (REQUIRED, will reject without)
`https://zealova.com/privacy`

### Copyright — App Store Connect "Copyright" field
`© 2026 Zealova`
(or your legal entity name once LLC is formed)

### Trade Representative Contact — only required for South Korea localization, skip if not targeting

---

## App Information (set once, applies to all versions)

| Field | Value |
|---|---|
| Primary Category | **Health & Fitness** |
| Secondary Category | **Lifestyle** (or leave blank) |
| Content Rights | "Does your app contain, show, or access third-party content?" → **No** (you generate all workouts via AI; food images are user-uploaded) |
| Age Rating | likely **4+** or **12+** (driven by questionnaire — see below) |

---

## Age Rating Questionnaire — pre-decided answers

App Store will ask 30+ yes/no questions. Pre-decide these:

| Question | Answer | Reason |
|---|---|---|
| Cartoon or Fantasy Violence | None | — |
| Realistic Violence | None | — |
| Profanity or Crude Humor | None | — |
| Mature/Suggestive Themes | None | — |
| Horror/Fear Themes | None | — |
| Medical/Treatment Information | **Infrequent/Mild** | You provide fitness guidance, NOT medical advice — but mention of injuries/PCOS/menopause crosses this line |
| Alcohol, Tobacco, Drug Use or References | None | — |
| Simulated Gambling | None | — |
| Sexual Content / Nudity | None | — |
| Contests | None | — |
| Unrestricted Web Access | **No** | App opens external links via SFSafariViewController, not arbitrary browser |
| Gambling | No | — |
| User-Generated Content | **Yes, with moderation** if your social/sharing features show other users' photos/posts. **No** if everything is private to the user |
| Made for Kids | **No** | — |

Likely outcome: **4+** (or **12+** if "Medical/Treatment" trips it)

---

## App Privacy Questionnaire (the long one)

This is brutal. Apple requires you to declare every category of data your app collects. Fill in for each SDK / system below.

### Data Linked to User (yes — your Supabase user account stores this)

- **Health & Fitness**: Workouts, body measurements, heart rate, calories burned (HealthKit + manual logs)
- **Sensitive Info**: Body measurements, menstrual cycle (if user enables hormonal tracking)
- **Contact Info**: Email address (sign-in)
- **User Content**: Workout notes, food photos, progress photos, AI chat messages
- **Identifiers**: User ID (Supabase), Device ID (PostHog `$device_id`), Push Token (FCM/APNs)
- **Usage Data**: Product interaction (which screens, which features), Other Usage Data (PostHog events)
- **Diagnostics**: Crash logs (Sentry), Performance Data (Sentry), Other Diagnostic Data (Sentry breadcrumbs)
- **Purchases**: Purchase History (RevenueCat)

### Data Used to Track User → **NO** (assuming you don't use IDFA / cross-app tracking)
If you use AppsFlyer / Branch / Adjust → flip to **YES** for "Identifiers", and need to add `NSUserTrackingUsageDescription` to Info.plist.

### Data NOT Collected
- Financial Info (RevenueCat handles, not you)
- Location: confirm whether your gym auto-detect feature stores precise location → if yes, declare "Coarse Location"
- Browsing History: No
- Search History: No
- Audio Data: Only when user uses voice food logging — declare under "User Content > Audio Data"
- Photos or Videos: User Content > Photos (food photos, progress photos)

### Per-category, declare for each:
- Linked to user identity? (Yes for almost everything)
- Used to track user across apps? (No, unless using IDFA)
- Purpose: App Functionality + Analytics + Product Personalization

---

## Pricing & Availability

### Pricing Tier
- **App is Free** with In-App Purchases (subscription model)

### IAP products to configure (must match RevenueCat product IDs)
| Product | Type | Price | Trial |
|---|---|---|---|
| `zealova_premium_monthly` | Auto-Renewable Subscription | $7.99/month | 7-day free trial |
| `zealova_premium_yearly` | Auto-Renewable Subscription | $59.99/year | 7-day free trial |
| `zealova_premium_yearly_retention` | Auto-Renewable Subscription | $47.99/year | (offered only via cancel ladder) |

### Subscription Group
Create one group: `Zealova Premium` — group all 3 products together so users can switch between them without re-trial.

### Family Sharing
**Enable** — Family Sharing for subscriptions is a App Store Connect toggle. Users in the same Family will all get Premium. Industry standard, expected.

### Localization
Start with English (U.S.) only. Add other locales in subsequent versions.

### Territories
**All territories** unless you have specific legal restrictions (some health-related apps are restricted in China — likely fine for fitness).

---

## App Review Information (the page Apple reviewers actually read)

### Demo Account credentials
```
Email: reviewer@zealova.com
Password: [your secure password]
```

### Reviewer Notes (CRITICAL — fill this in)

```
Hi Apple Review team,

DEMO ACCOUNT
Email: reviewer@zealova.com
Password: [REPLACE WITH ACTUAL]

This account is pre-configured with a 7-day free trial active. No payment required to test all premium features during the review window.

WHAT THE APP DOES
Zealova is an AI fitness and nutrition coach. Users get personalized workout plans (generated by Google Gemini via our backend) and can log food via photo (Google Gemini Vision) or voice/text. The app integrates with Apple HealthKit to read activity data and write workout records.

KEY FLOWS TO TEST
1. Onboarding (~3 min): Goals → equipment → injuries → preferred workout days
2. Today's Workout: Tap "Start" on home screen → run through one set → tap "Complete"
3. AI Coach Chat: Tap chat tab → ask "give me a 20-minute back workout" → workout appears in timeline
4. Food Photo Log: Nutrition tab → camera button → snap any food photo → review identified items → save
5. Paywall: Settings → Subscriptions, or attempt 3rd workout in a day on free tier

HEALTH DATA USAGE
We request HealthKit access during onboarding. We READ: weight, body fat, heart rate, steps. We WRITE: workout sessions. Users can decline; app works without HealthKit access.

AI / GEMINI USAGE
All AI requests go through our authenticated backend, never directly from the device to Google. We never send PII to Gemini — only anonymized profile data (age range, goals, equipment). Food vision uploads are temporary; images are deleted from S3 after analysis (24h max retention).

USER-GENERATED CONTENT
Users can share workout plans publicly via zealova.com/p/{token} links. We moderate content via Gemini safety classifiers before any link is publicly viewable.

CONTACT
support@zealova.com — checked daily, response within 24h
```

### Sign-in required to use the app?
**Yes** — Sign-in via Email/Password (Supabase Auth) or Sign in with Apple

### Notes
Mention HealthKit, Gemini AI, RevenueCat IAP. Don't lie about features.

---

## Pre-submission checklist

- [ ] App Name unique on App Store (search to verify)
- [ ] All URLs return HTTP 200 (privacy, support, terms, delete-account)
- [ ] In-App Purchases configured matching RevenueCat
- [ ] Demo account works end-to-end on a fresh install (test on TestFlight)
- [ ] Screenshots: 5 × 1290×2796 (iPhone 16 Pro Max)
- [ ] App Privacy questionnaire reviewed against actual data flows
- [ ] Age rating answered honestly (Medical/Treatment: Infrequent → 4+ likely)
- [ ] No "FitWiz" strings visible to users (settings, about, footer)
- [ ] Build uploaded via Transporter, processing complete (no warnings)
- [ ] Export Compliance answered (ITSAppUsesNonExemptEncryption=false in Info.plist ✅)
- [ ] Encryption: standard HTTPS only — exempt from EAR

---

## After approval

- Phased Release: enable 7-day phased rollout for first version
- Monitor in-app crashes (Sentry) + Crashlytics first 48h
- Reply to first 10 reviews personally — Apple's algorithm weights early-review velocity
- Add App Store ID to RevenueCat dashboard (App > settings > App Store ID)
- Add App Store ID to Firebase iOS app entry (Firebase > Project Settings > iOS app > App Store ID)
- Update `mobile/flutter/lib/core/constants/app_links.dart`:
  ```dart
  static const String appStore = 'https://apps.apple.com/app/idXXXXXXXXX';
  ```
