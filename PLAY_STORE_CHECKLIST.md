# Google Play Store Publishing Checklist - Zealova

## 1. Developer Account & Payment

- [x] Google Play Developer account ($25 one-time fee)
- [ ] Merchant account linked (for in-app purchase payouts)
- [ ] Tax information completed in Google Play Console
- [x] RevenueCat Android production key configured (`goog_oWxJnYQrUSCtIxMqTPcEPfWgBxq`)
- [x] In-app products defined (premium_monthly, premium_yearly, premium_plus_monthly, premium_plus_yearly, lifetime)
- [ ] RevenueCat products created & mapped in Google Play Console
- [ ] Google Play billing tested via internal testing track

## 2. App Signing & Build

- [x] Application ID set (`com.aifitnesscoach.app`)
- [x] Version name & code configured (`1.2.56+1121` in pubspec.yaml)
- [x] Release keystore created (`android/keystores/release.keystore`, RSA 2048-bit)
- [x] Signing config in build.gradle.kts (env vars: KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD)
- [x] R8 minification enabled (`isMinifyEnabled = true`)
- [x] Resource shrinking enabled (`isShrinkResources = true`)
- [x] Proguard rules comprehensive (Flutter, Firebase, RevenueCat, Health Connect, ML Kit, Gson)
- [x] minSdk 26 (required for Health Connect)
- [x] targetSdk set via Flutter defaults (meets Play Store requirement)
- [x] Java 17 compatibility configured
- [ ] Build & test release AAB locally (`flutter build appbundle --release`)
- [ ] Version bumped (currently `1.2.56+1121`) to next release before submission

## 3. App Icon & Branding

- [x] Source icon asset exists (`assets/icon/app_icon.png`)
- [x] flutter_launcher_icons configured in pubspec.yaml
- [x] Standard icons generated (mdpi through xxxhdpi)
- [x] Adaptive icons generated (Android 8.0+, foreground + background)
- [x] Round icons generated
- [x] Monochrome notification icon (`ic_launcher_monochrome.png`)
- [x] Splash screen configured (LaunchTheme with white background)
- [ ] Splash screen enhanced with Zealova branding (optional)

## 4. Store Listing Assets

- [ ] App name (max 30 chars) - "Zealova - AI Fitness Coach"
- [ ] Short description (max 80 chars)
- [ ] Full description (max 4000 chars)
- [ ] Hi-res icon uploaded (512x512 PNG, 32-bit)
- [ ] Feature graphic created & uploaded (1024x500)
- [ ] Phone screenshots (min 2, max 8, 1080x1920 recommended)
- [ ] 7-inch tablet screenshots (recommended)
- [ ] 10-inch tablet screenshots (recommended)
- [ ] App category selected (Health & Fitness)
- [ ] Tags added
- [ ] Contact email set
- [ ] Website URL (https://zealova.com)
- [ ] Promotional video (optional, YouTube link)

## 5. Privacy & Compliance

- [x] Privacy policy URL configured (`https://zealova.com/privacy`) - referenced in paywall, settings, help screens
- [x] Terms of service URL configured (`https://zealova.com/terms`)
- [ ] Privacy policy page is LIVE and accessible at https://zealova.com/privacy
- [ ] Terms of service page is LIVE and accessible at https://zealova.com/terms
- [ ] Data safety form completed in Google Play Console (REVIEW REQUIRED 2026-05-07: ensure removed Health Connect types — distance, floors climbed, HRV, elevation, power, speed, respiratory rate, basal metabolic rate, oxygen saturation, body temperature — are NOT listed under "Data types collected" / "Data types shared". See section "Play Console action items — 2026-05-07 Health Connect minimum-scope cleanup" below.)
  - [ ] Data collected: health/fitness data, personal info, app activity
  - [ ] Data shared: Supabase (backend), RevenueCat (payments), Firebase (analytics)
  - [ ] Data security: HTTPS encryption, JWT auth
  - [ ] Data deletion: mechanism for users to request data deletion
- [ ] Content rating questionnaire completed (IARC)
- [ ] Target audience declaration (not targeting children under 13)
- [ ] Ads declaration (no ads)
- [ ] Health app policy compliance confirmed (Google health & fitness app requirements)

## 6. Permissions Justification

All permissions are declared in AndroidManifest.xml. Google Play Console requires justification for sensitive ones:

- [x] INTERNET - API communication
- [x] CAMERA - food photo logging, barcode scanning, progress photos
- [x] RECORD_AUDIO - voice commands / speech recognition
- [x] ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION - gym profile auto-switch
- [x] POST_NOTIFICATIONS - workout reminders, hydration reminders
- [x] BLUETOOTH_SCAN / BLUETOOTH_CONNECT - wearable device sync
- [x] Health Connect permissions (16 total, minimum scope as of 2026-05-07) — body measurements (weight, body fat), heart rate (live + resting), steps, active/total calories, sleep, exercise sessions, blood glucose, hydration. Removed 2026-05-07 per Google Play "Excessive data access" rejection: distance, floors climbed, HRV, elevation, power, speed, respiratory rate, basal metabolic rate, oxygen saturation, body temperature.
- [x] READ_MEDIA_IMAGES (Android 13+) - progress photo access
- [ ] Write justification text for each sensitive permission in Play Console

## 7. Technical Configuration

- [x] Network security config (HTTPS-only for backend & Supabase)
- [x] Firebase configured (`google-services.json` present)
- [x] FCM push notifications set up
- [x] Deep linking configured (`fitwiz://` scheme)
- [x] Home screen widgets declared (11 widget receivers)
- [x] Health Connect integration (`health: ^11.1.0`)
- [x] Core library desugaring enabled

## 8. Testing Before Submission

- [ ] Release build runs without crashes on physical device
- [ ] All permissions properly requested at runtime (not just declared)
- [ ] RevenueCat purchases work on internal testing track
- [ ] Health Connect data sync works
- [ ] Push notifications received
- [ ] Deep links open correctly
- [ ] All widgets render properly
- [ ] App survives process death and recreation
- [ ] No ANR (Application Not Responding) issues
- [ ] Pre-launch report reviewed in Play Console (automatic)

## 9. Release Strategy

- [ ] Upload AAB to internal testing track first
- [ ] Test with 5-10 internal testers
- [ ] Move to closed testing (beta) with wider audience
- [ ] Fix any issues from beta feedback
- [ ] Submit for production review
- [ ] Prepare release notes / changelog for v1.0.0

## 10. Post-Launch

- [ ] Monitor Android vitals (crash rate, ANR rate)
- [ ] Respond to initial user reviews
- [ ] Set up crash reporting dashboard (Firebase Crashlytics)
- [ ] Monitor RevenueCat dashboard for subscription metrics
- [ ] Plan first update based on user feedback

---

## Known Issues to Fix Before Submission

| Priority | Issue | File |
|----------|-------|------|
| Critical | Privacy policy & terms pages must be live at zealova.com | Web hosting |
| High | Version should be bumped for release | `pubspec.yaml` |
| Medium | Splash screen is plain white - consider adding branding | `android/app/src/main/res/drawable/launch_background.xml` |

---

**Overall Status: ~70% complete** - All technical/code requirements are done. Remaining items are Play Console configuration, store listing assets, and testing.

---

## Play Console action items — 2026-05-07 Health Connect minimum-scope cleanup

These steps **must be completed in the Play Console UI** before resubmitting; they cannot be automated from the repo. They correspond 1:1 with the manifest / Dart / backend code edits made on 2026-05-07.

### 1. Health Connect declaration form

**Path:** Play Console → App content → Health Connect by Android (Health apps declaration).

Untick / remove these 10 data types from the declared list (they are no longer in the manifest):

- Distance
- FloorsClimbed
- HeartRateVariabilityRmssd (and SDNN if it was listed under that name)
- ElevationGained
- Power
- Speed
- RespiratoryRate
- BasalMetabolicRate
- OxygenSaturation
- BodyTemperature

Keep declared (matches the manifest's `<uses-permission android:name="android.permission.health.READ_…">` / `WRITE_…` entries):

| Permission | Read | Write | Feature |
|---|---|---|---|
| Weight | ✅ | ✅ | Body-measurements card, weight history graph |
| BodyFat | ✅ | ✅ | Body composition card |
| HeartRate | ✅ | — | Live HR during workouts, post-workout zones |
| RestingHeartRate | ✅ | — | Recovery readiness score |
| Steps | ✅ | — | Daily Activity card, NEAT |
| ActiveCaloriesBurned | ✅ | ✅ | Daily Activity card; push completed workouts |
| TotalCaloriesBurned | ✅ | — | Workout enrichment |
| Sleep | ✅ | — | Sleep summary card, recovery score |
| BloodGlucose | ✅ | — | Diabetic-mode CGM display |
| Exercise (workout sessions) | ✅ | ✅ | Auto-import other apps' workouts; write Zealova workouts |
| Hydration | ✅ | ✅ | Water-intake tile + in-app logging |

For each, write a one-sentence justification using the per-permission feature-map block in `mobile/flutter/android/app/src/main/AndroidManifest.xml`.

### 2. Data Safety form

**Path:** Play Console → App content → Data safety.

Under **"Data types your app collects or shares"**, remove these entries if they were previously declared under the **Health and fitness** category:

- Heart rate variability
- Distance
- Floors climbed (or elevation)
- Speed / pace / power
- Respiratory rate
- Body temperature
- Oxygen saturation (SpO₂)
- Basal metabolic rate / basal calories

What should remain declared under **Health and fitness** (collected, transmitted to backend / Vertex AI):

- Heart rate (live + resting) — collected, encrypted in transit + at rest, used for app functionality + AI personalization
- Steps — same
- Sleep — same
- Weight + Body fat — same
- Active / total calories — same
- Exercise sessions — same
- Blood glucose — only if user enables diabetic mode
- Water / hydration — same

For every retained data type confirm: encrypted in transit (TLS), encrypted at rest (Supabase managed), not sold, not used for advertising, user can request deletion via Settings → Privacy & Data → Delete Account.

### 3. Privacy policy

The hosted policy at `zealova.com/privacy` (sourced from `mobile/flutter/privacy_policy.html` and `frontend/src/pages/PrivacyPolicy.tsx` — both updated 2026-05-07) now lists only the minimum-scope set and explicitly disclaims the removed data types. **Re-deploy the marketing site so the live URL matches the AAB before resubmitting** — Play reviewers cross-reference the linked privacy policy against the Data Safety form and the Health Connect declaration.

### 4. Backend write paths (already done in this commit)

`POST /api/v1/activity/sync` and `POST /api/v1/activity/sync-batch` no longer persist `hrv`, `blood_oxygen`, `body_temperature`, `respiratory_rate`, `flights_climbed`, `basal_calories`, or `distance_meters` to the `daily_activity` table. Pydantic ignores those keys silently if older clients still send them. The matching DB columns are kept for historical rows; new rows leave them NULL.

### 5. Resubmission

1. Bump `versionCode` in `mobile/flutter/android/app/build.gradle.kts` (or `local.properties`).
2. Build a new AAB.
3. Push backend with the activity.py edits (FastAPI auto-redeploys on Render).
4. Update `mobile/flutter/privacy_policy.html` deploy + `frontend/src/pages/PrivacyPolicy.tsx` deploy so the live URL is current.
5. Update Health Connect declaration + Data Safety form per sections 1 + 2 above.
6. Submit for review with a release-note line: *"Resubmission for Health Connect Permissions policy compliance — narrowed Health Connect data types to minimum scope."*

