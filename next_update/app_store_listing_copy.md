# Zealova — App Store + Play Store listing copy

**Drafted 2026-05-26 for first iOS submission.** Paste directly into App Store Connect / Play Console; tune by region after first acceptance.

---

## App Name (max 30 chars)

`Zealova: AI Fitness Coach`

(25 chars — leaves room for localized subtitle expansions)

---

## Subtitle (iOS only, max 30 chars)

`Train, eat, recover smarter`

(26 chars)

---

## Promotional Text (iOS only, max 170 chars — updatable without new build)

`Your AI coach for workouts, food photos, menu scans, sleep, and cycle-aware training. Logs to Apple Health. No $99 device required.`

(133 chars)

---

## App Description

```
Zealova is your AI fitness coach — workouts, nutrition, recovery, and
cycle-aware training in one app. Built around an AI Coach that actually
knows your data: your last workout, your sleep, your goals, and the foods
you log.

WHY ZEALOVA
• AI coach you can chat with, voice-message, or send photos
• Photo food logging + menu scans with sort by macros
• Workouts that adjust mid-week from a single chat ("my shoulder is off")
• Cycle-aware programming for women
• Reads Apple Health, writes back to Apple Health
• Your training plan and history stay exportable — even if you cancel

WORKOUTS
• Personalized weekly plans built from your goals and history
• Exercise library with 500+ moves and progressive overload
• Live activity card mid-workout on iPhone Lock Screen
• Form scoring from a short video (educational, not medical advice)
• Voice-told set logging during a workout
• Drag-and-drop schedule with rest-day awareness

NUTRITION
• Snap any meal — AI identifies the dish and logs the macros
• Snap a menu at a restaurant — sort options by your goal (low-carb, high-protein)
• 601 regional Indian foods plus US, EU, and global coverage
• Fasting timer with intermittent-fasting protocols
• Hydration tracking and personalized targets

RECOVERY & WELLNESS
• Sleep quality breakdown using Apple Health
• Daily wellness check-in (mood, energy, stress, soreness)
• Cycle tracking with phase-aware workout adjustments
• Resting HR, HRV, and recovery trends

THE AI COACH IS DIFFERENT
• Cites sources when it makes claims
• Acknowledges uncertainty — not a doctor, not a diagnosis tool
• Available in 35+ languages including Hindi, Tamil, Telugu, Kannada,
  Malayalam, Marathi, Bengali, Punjabi, Odia, Urdu
• Connect Claude, ChatGPT, or Gemini via Zealova's MCP server (advanced)

PRIVACY
• Your chats are never used to train AI models
• Health data stays inside Zealova — we never sell it
• Export your full workout history any time (Hevy, Strong, Fitbod, JSON, CSV)
• Delete your account from Settings — Apple-required, fully supported

SUBSCRIPTION (optional)
• 7-day free trial
• $7.99/month or $59.99/year after the trial
• Subscription auto-renews until canceled in Settings → Apple ID → Subscriptions
• No commitment — cancel anytime
• Core tracking and history work without a subscription

HEALTH DISCLAIMER
Zealova is a fitness and wellness app, not a medical device. AI form
scoring and coaching are educational, not medical advice. If you have
pain, an injury, or a medical condition, consult a qualified doctor or
physical therapist.

LINKS
• Privacy Policy: https://zealova.com/privacy
• Terms of Service: https://zealova.com/terms
• Support: support@zealova.com
```

---

## Keywords (iOS only, 100-char limit — comma-separated, NO spaces after commas)

```
ai fitness,ai coach,workout plan,fitbit air alternative,google health coach,claude fitness,chatgpt fitness,myfitnesspal ai,macro tracker,form check,menu scan,cycle tracking,strava
```

(99 chars — packed against limit)

**Keyword strategy:**
- Lead with category ("ai fitness", "ai coach")
- Hit the 3 explicit competitor-comparison search terms (`fitbit air alternative`, `google health coach`, `myfitnesspal ai`)
- Layer the LLM-bring-your-own angle (`claude fitness`, `chatgpt fitness`)
- Long-tail features (`macro tracker`, `form check`, `menu scan`, `cycle tracking`)
- Anchor against the dominant ecosystem brand (`strava`) for adjacency searches

**Do NOT include in keywords** (Apple banned + redundant):
- App's own name (auto-indexed)
- Words already in title/subtitle (auto-indexed — "fitness", "coach" pull double duty)
- Trademark stuffing past 1-2 competitor brands (rejection risk)

---

## Play Store description (Android)

Same body copy as iOS App Description above, but Google Play allows up to
4,000 chars and supports light HTML / line breaks. Add the following lead
paragraph above the body for Play:

```
Zealova is the AI fitness coach that knows your data — not a generic
chatbot. Workouts, nutrition, recovery, sleep, and cycle-aware training
in one app. 7-day free trial, then $7.99/month or $59.99/year. Cancel
anytime. Export your full history any time, even after canceling.
```

**Play Console — short description (max 80 chars):**

```
AI fitness coach: workouts, food photos, menu scans, sleep, cycle-aware training.
```

(78 chars)

---

## App Review Information (App Store Connect "App Review" tab)

**Demo account credentials** (from project memory `project_qa_user_premium.md`):
- Email: `reviewer@fitwiz.us`
- Password: (set in App Store Connect — do NOT commit here)
- Tier: Premium (no expiry, no RC link)

**Notes for the reviewer:**

```
Zealova is an AI fitness coaching app. The AI Coach (powered by Google
Gemini) provides workout plans, nutrition guidance, and recovery
recommendations. It is NOT a medical device and includes prominent
disclaimers stating so.

To exercise key flows:

1. Sign in with the test account above (Apple sign-in is also available).
2. Onboarding is skippable via "Already a member" - the test account
   has completed onboarding.
3. AI Coach: tap the chat icon (bottom right). Try "create a workout for
   tomorrow" or "I had a chicken bowl for lunch — log it."
4. Photo food logging: in Nutrition tab, tap camera, select a meal photo
   from gallery. AI identifies dish + logs macros.
5. Form check: in chat, send a short workout video. AI returns a score
   1-10 + technique feedback. Disclaimer is visible at the bottom of every
   form-check card.
6. Subscription: Settings → Subscription. The test account is Premium
   (no purchase required). Restore Purchases CTA on the paywall pricing
   screen for the reviewer to verify Apple 3.1.1 compliance.
7. Account deletion: Settings → Privacy & Data → Delete Account. Full
   confirmation flow with password verification.

Health data: Zealova reads from Apple Health (workouts, sleep, HRV,
heart rate, weight) and writes back workouts + calories + distance.
HealthKit usage descriptions in Info.plist explain the WHY for each
permission. The app does not request bloodType, dateOfBirth, or any
sensitive type it doesn't actually consume.

The AI Coach is instructed (system prompt) to never give diagnostic
or treatment advice and to redirect symptom questions to a doctor /
physical therapist.

Contact: support@zealova.com (monitored daily).
```

---

## App Privacy questionnaire — answers to paste in App Store Connect

**Data collected:**

| Data type | Purpose | Linked to user | Used for tracking |
|---|---|---|---|
| Email address | App functionality, account | Yes | No |
| Name | App personalization | Yes | No |
| Health & fitness | App functionality (core feature) | Yes | No |
| Photos (food, progress) | App functionality (AI analysis) | Yes | No |
| Voice (mic input) | App functionality (voice logging) | Yes | No |
| Coarse location | App functionality (gym auto-switching) | Yes | No |
| Diagnostics / crash data (Sentry) | App functionality | No | No |
| Product interaction (PostHog) | Analytics | Yes | **Yes if user opts in via ATT** |

**Third parties data is shared with:**
- Supabase (data hosting + auth)
- Google Gemini (AI Coach inference — content of chat messages, photos)
- Anthropic / OpenAI (only if user wires MCP — opt-in advanced feature)
- PostHog (product analytics — anonymous-by-default, identified after sign-in)
- Sentry (crash reporting)
- RevenueCat (subscription state)

Important: declare **all** of these in the App Privacy section. A mismatch
between the questionnaire and the SDKs in the binary is the #1 first-time-
submission rejection cause for indie health apps.

---

## Submission-day checklist (10 minutes the morning of submit)

1. Build version + build number bumped in `pubspec.yaml`.
2. App icon + launch screen current (no Lorem placeholder).
3. Screenshots uploaded for iPhone 8 Plus (5.5"), iPhone 17 Pro Max (6.9"),
   iPad Pro (12.9") if iPad support declared.
4. Description, subtitle, promo text pasted from above.
5. Keywords pasted from above.
6. Privacy Policy URL: https://zealova.com/privacy (verify loads).
7. Support URL: https://zealova.com/support (verify loads).
8. Marketing URL: https://zealova.com (verify loads).
9. App Privacy questionnaire matches code reality (audit Supabase + Gemini
   + PostHog + Sentry + RevenueCat declarations).
10. Demo credentials in App Review Information.
11. Submit.
