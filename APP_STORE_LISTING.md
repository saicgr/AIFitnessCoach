# Zealova App Store Listing — copy-paste source of truth

Last updated: 2026-04-30

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
**Recommended:** `New: Snap any meal — our vision AI logs calories and macros instantly. Plus injury-aware workouts, adaptive TDEE, and a coach that actually answers back.` (168)

### Keywords — 100 chars max, comma-separated, NO SPACES between
**Recommended:**
```
fitness,workout,gym,AI,coach,meal,nutrition,calorie,macro,trainer,plan,strength,cardio,health
```
(99 chars including commas)

Apple ranks keywords roughly equally — pack them tight, no duplicates of the App Name (those auto-index), prefer specific terms over generic ones. Don't include competitor names (Apple rejects) like "MyFitnessPal", "Fitbod", "Hevy".

### Description — 4000 chars max

```
Zealova is the AI coach that builds your workouts and tracks your meals in one place — no spreadsheets, no guesswork.

Type, snap, or scan. Our AI builds plans around your gym, your injuries, your schedule, and your real progress.

▶ AI WORKOUT GENERATION
Daily workouts personalized to your equipment (23+ types from dumbbells to commercial machines), goals, and recovery state. The plan adapts every week based on what you actually lifted.

▶ CONVERSATIONAL AI COACH
Ask anything — "swap squats for my knee", "more chest volume this week", "what should I eat after legs". The coach edits your plan in real time, suggests meals, and answers in plain English. Unlimited chat on every tier.

▶ VISION FOOD LOGGING
Snap a photo of your plate. Zealova identifies foods, estimates portions, and logs calories + macros in seconds. No barcode hunting, no manual database digging. Restaurant menus, grocery labels, and food packaging all work.

▶ ADAPTIVE TDEE & MACRO TARGETING
Our MacroFactor-style adaptive TDEE engine learns your real metabolism using EMA smoothing, detects metabolic adaptation, and recommends sustainable targets — not the generic 2000 calories from a calculator.

▶ INJURY-AWARE TRAINING
Tell us where it hurts. Workouts auto-exclude problem movements and substitute safer alternatives. Built-in 10% rule prevents overuse injuries before they happen.

▶ MUSCLE & PROGRESS ANALYTICS
Body heatmap shows training balance across 24+ muscles. Per-exercise history charts strength gains over time. Visual progress with weekly streaks and milestone trophies.

▶ NUTRITION INTELLIGENCE
- Inflammation analysis on any meal you log
- Hormonal diet recommendations (testosterone, estrogen, PCOS, fertility, menopause)
- Cooked vs raw food converter
- Frequent foods one-tap re-log
- Voice-to-calories: "two slices pepperoni pizza" → logged

▶ FASTING TIMER + STREAKS
16:8, 18:6, OMAD, custom windows. Hydration tracking integrated. Streak system across workouts, meals, fasting, hydration, and habits.

▶ GAMIFICATION THAT WORKS
35+ achievements, daily crates, weekly progress reports, comeback bonuses for getting back on track after a break.

▶ SENIOR-AWARE MODE
Recovery scaling, injury caution, and joint-friendly progressions for users 55+.

▶ HABITS, HORMONES, KEGELS
Track 50+ positive habits, optimize hormonal health, dedicated pelvic floor training (16 gender-specific exercises).

▶ NO ADS. NO DATA SOLD. NO DARK PATTERNS.
Cancel anytime in Settings. Real privacy policy at zealova.com/privacy.

PRICING
- Free tier: 2 workouts/month, 1 food photo/day, 3 voice-log/day, unlimited AI chat
- Premium: $7.99/mo or $59.99/yr (7-day free trial)

WORKS WITH
- Apple Health (read + write)
- Live Activity for active workouts (Dynamic Island + Lock Screen)
- Universal Links for invite + workout shares

Built by a small team that actually trains. Real responses on support@zealova.com — usually within 24h.

Privacy policy: https://zealova.com/privacy
Support: https://zealova.com/support
Terms: https://zealova.com/terms
```

(approx 3380 chars, well under 4000 cap)

### What's New in This Version — 4000 chars max
**For first version (1.2.61):**
```
Welcome to Zealova! Your AI workout & meal coach. Sign up for a 7-day free trial and get:

• Personalized daily workouts that adapt as you progress
• A conversational AI coach that edits your plan on the fly
• Photo-based food logging — no barcodes, no databases
• MacroFactor-style adaptive metabolism tracking
• Injury-aware exercise substitution
• Body-part heatmap and per-exercise progress charts
• Apple Health sync, Live Activity workouts, fasting timer

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
