# Google Play Store Publishing Checklist - FitWiz

## 1. Developer Account & Payment

- [x] Google Play Developer account ($25 one-time fee)
- [ ] Merchant account linked (for in-app purchase payouts)
- [ ] Tax information completed in Google Play Console
- [x] RevenueCat Android production key configured (`goog_lnoRpFUioBNbTpTzsRsIKswnIWj`)
- [x] In-app products defined (premium_monthly, premium_yearly, premium_plus_monthly, premium_plus_yearly, lifetime)
- [ ] RevenueCat products created & mapped in Google Play Console
- [ ] Google Play billing tested via internal testing track

## 2. App Signing & Build

- [x] Application ID set (`com.aifitnesscoach.app`)
- [x] Version name & code configured (`1.0.0+1` in pubspec.yaml)
- [x] Release keystore created (`android/keystores/release.keystore`, RSA 2048-bit)
- [x] Signing config in build.gradle.kts (env vars: KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD)
- [x] R8 minification enabled (`isMinifyEnabled = true`)
- [x] Resource shrinking enabled (`isShrinkResources = true`)
- [x] Proguard rules comprehensive (Flutter, Firebase, RevenueCat, Health Connect, ML Kit, Gson)
- [x] minSdk 26 (required for Health Connect)
- [x] targetSdk set via Flutter defaults (meets Play Store requirement)
- [x] Java 17 compatibility configured
- [ ] Build & test release AAB locally (`flutter build appbundle --release`)
- [ ] Version bumped from 1.0.0+1 to release version before submission

## 3. App Icon & Branding

- [x] Source icon asset exists (`assets/icon/app_icon.png`)
- [x] flutter_launcher_icons configured in pubspec.yaml
- [x] Standard icons generated (mdpi through xxxhdpi)
- [x] Adaptive icons generated (Android 8.0+, foreground + background)
- [x] Round icons generated
- [x] Monochrome notification icon (`ic_launcher_monochrome.png`)
- [x] Splash screen configured (LaunchTheme with white background)
- [ ] Splash screen enhanced with FitWiz branding (optional)

## 4. Store Listing Assets

- [ ] App name (max 30 chars) - "FitWiz - AI Fitness Coach"
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
- [ ] Website URL (https://fitwiz.app)
- [ ] Promotional video (optional, YouTube link)

## 5. Privacy & Compliance

- [x] Privacy policy URL configured (`https://fitwiz.app/privacy`) - referenced in paywall, settings, help screens
- [x] Terms of service URL configured (`https://fitwiz.app/terms`)
- [ ] Privacy policy page is LIVE and accessible at https://fitwiz.app/privacy
- [ ] Terms of service page is LIVE and accessible at https://fitwiz.app/terms
- [ ] Data safety form completed in Google Play Console
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
- [x] Health Connect permissions (24 total) - fitness tracking, body measurements, exercise data
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
| Critical | Privacy policy & terms pages must be live at fitwiz.app | Web hosting |
| High | Version should be bumped for release | `pubspec.yaml` |
| Medium | Splash screen is plain white - consider adding branding | `android/app/src/main/res/drawable/launch_background.xml` |

---

**Overall Status: ~70% complete** - All technical/code requirements are done. Remaining items are Play Console configuration, store listing assets, and testing.
