# Zealova — App Store Submission Guide

**App:** Zealova (formerly FitWiz)
**Bundle ID:** `com.aifitnesscoach.aiFitnessCoach`
**Apple Team ID:** `G9RL26P89Q`
**Current version:** `1.2.60+1133` (from `pubspec.yaml`)
**Live Activity extension bundle ID:** `com.aifitnesscoach.aiFitnessCoach.FitWizLiveActivity`

> ⚠️ **Naming inconsistency to be aware of:** The display name is "Zealova" (rebranded), but the bundle identifier still contains `aiFitnessCoach` and the Live Activity target is named `FitWizLiveActivity`. **Do NOT change the bundle ID** — once an app is in App Store Connect with a bundle ID, it cannot be changed. Keep it as-is.

---

## 0. Prerequisites (one-time setup)

1. **Apple Developer Program membership** — $99/year, must be active. Verify at https://developer.apple.com/account.
2. **App Store Connect access** — sign in at https://appstoreconnect.apple.com with the same Apple ID that owns the dev account.
3. **Xcode** — latest stable (16.x). Sign in: Xcode → Settings → Accounts → add Apple ID. Confirm team `G9RL26P89Q` is visible.
4. **Mac with macOS 14+** — required for archiving/uploading.
5. **Distribution certificate + provisioning profiles** — Xcode "Automatically manage signing" handles this if logged in.

---

## 1. App Store Connect — Create the App Record

(Skip if the listing already exists.)

1. Go to https://appstoreconnect.apple.com → **My Apps** → **+** → **New App**.
2. Fill in:
   - **Platform:** iOS
   - **Name:** `Zealova` (must be globally unique on App Store; if taken, use `Zealova - AI Fitness Coach` or similar)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** `com.aifitnesscoach.aiFitnessCoach` (must match Xcode exactly — register it under Certificates, Identifiers & Profiles first if not already there)
   - **SKU:** any internal identifier, e.g. `zealova-ios-001`
   - **User Access:** Full Access
3. Click **Create**.

### Register Bundle ID (if first time)
https://developer.apple.com/account/resources/identifiers/list → **+** → App IDs → App → enter `com.aifitnesscoach.aiFitnessCoach`. Enable capabilities the app uses:

- Push Notifications
- Sign in with Apple (if used)
- HealthKit (if used)
- App Groups (for Live Activity / widgets — `group.com.aifitnesscoach.aiFitnessCoach` per memory)
- Associated Domains (deep links)

Repeat for the Live Activity extension bundle: `com.aifitnesscoach.aiFitnessCoach.FitWizLiveActivity`.

---

## 2. Pre-Build Checklist (parity with Google Play submission)

Most of this should already be done since you're shipping to Play this week. Verify the iOS-specific bits:

- [ ] **Version bumped** in `pubspec.yaml` (`1.2.60+1133` → bump build number for each TestFlight upload)
- [ ] **Privacy policy URL** live (required) — same URL as Play submission
- [ ] **Support URL** live (required, can be a contact page)
- [ ] **Marketing URL** (optional but recommended)
- [ ] All `Info.plist` usage descriptions present for permissions actually used:
  - `NSCameraUsageDescription` (food photos, form videos, progress photos)
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription` (saving share images)
  - `NSMicrophoneUsageDescription` (if voice input)
  - `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` (if HealthKit used)
  - `NSLocationWhenInUseUsageDescription` (if location used)
  - `NSUserTrackingUsageDescription` (if any SDK uses IDFA — RevenueCat does NOT require this by default)
- [ ] **App Tracking Transparency** prompt wired if any tracking SDK is integrated
- [ ] **Encryption export compliance** — add `ITSAppUsesNonExemptEncryption=false` to `Info.plist` if you only use HTTPS/standard encryption (most apps qualify for the exemption)
- [ ] **App Icon** — 1024×1024 PNG, no alpha, no transparency, in `Assets.xcassets/AppIcon.appiconset` plus all required smaller sizes (Flutter `flutter_launcher_icons` should have generated these)
- [ ] **Launch screen** uses `LaunchScreen.storyboard` (already configured)
- [ ] **No `arm64` simulator slices** in shipped binary (Flutter handles this with `flutter build ipa`)
- [ ] **iOS deployment target ≥ 15.0** (required by `google_maps_flutter_ios` per memory)
- [ ] **`flutter_gemma` strip script** is in iOS build phases (per memory `project_ios_build_pipeline.md`)
- [ ] **Embed Foundation Extensions phase comes BEFORE Thin Binary** in Runner build phases (per memory)

---

## 3. In-App Purchases / Subscriptions (RevenueCat)

Zealova uses RevenueCat with a 7-day free trial → $49.99/yr default → $39.99/yr retention popup.

1. **App Store Connect → Your App → Monetization → Subscriptions** (or In-App Purchases for non-renewing).
2. Create a **Subscription Group** (e.g., "Zealova Pro") — all renewable tiers must live in one group so users can upgrade/downgrade.
3. Create products with **Product IDs that match what RevenueCat is configured to look up.** Verify the IDs in your RevenueCat dashboard before creating them here.
   - Annual ($49.99): e.g., `zealova_pro_annual_4999`
   - Annual retention ($39.99): e.g., `zealova_pro_annual_3999`
4. For each product:
   - Set **Reference Name**, **Price** (Apple's $49.99 tier), **Localizations** (display name + description per locale)
   - Add **Introductory Offer** → 7-day Free Trial (eligibility: New Subscribers)
   - Upload a **Review Screenshot** (a screenshot showing the paywall) — Apple rejects without this
5. **Tax & Banking** must be completed in App Store Connect → Agreements, Tax, and Banking. Without active "Paid Apps" agreement, IAPs won't work in production.
6. In RevenueCat dashboard, ensure the iOS app is configured with:
   - **App-Specific Shared Secret** (App Store Connect → App → App Information → App-Specific Shared Secret)
   - **In-App Purchase Key** (Users and Access → Keys → In-App Purchase) — preferred over shared secret
7. **Test in sandbox**: create a sandbox tester (Users and Access → Sandbox Testers), sign into iPhone Settings → App Store → Sandbox Account, run a TestFlight build, attempt purchase.

---

## 4. Build the iOS Release Archive

Run from `mobile/flutter/`:

```bash
# Clean
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..

# DO NOT run build_runner — .g.dart files are committed (per memory project_codegen_gotcha.md)

# Build release IPA
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

If you don't have an `ExportOptions.plist`, build the archive in Xcode instead:

```bash
open ios/Runner.xcworkspace
```

Then in Xcode:

1. Select **Runner** scheme, target device **Any iOS Device (arm64)**
2. **Product → Archive**
3. Wait for build (~5–10 min). Organizer opens automatically.
4. Click **Distribute App** → **App Store Connect** → **Upload** → use automatic signing.
5. Wait for upload + processing (10–30 min).

### CLI alternative (after `flutter build ipa`)

```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```

(Requires App Store Connect API key from Users and Access → Integrations → App Store Connect API.)

---

## 5. TestFlight (Internal Testing)

1. App Store Connect → Your App → **TestFlight** tab.
2. Wait for build to finish processing (status changes from "Processing" to a build number).
3. **Test Information** (required before any external test): provide beta app description, feedback email, marketing URL.
4. **Export Compliance**: answer encryption questions. If you set `ITSAppUsesNonExemptEncryption=false` in `Info.plist`, Apple skips this prompt.
5. **Internal Testing** group → add yourself + team → builds become available immediately on the TestFlight iOS app.
6. Install TestFlight on iPhone, accept invite, run build, smoke-test:
   - Sign up / sign in (Supabase auth)
   - Generate workout (Gemini integration)
   - Subscribe (sandbox)
   - Live Activity / widget (per memory, this has historically been fragile — verify)
   - Camera, photos, notifications permissions all prompt with the right copy

---

## 6. App Store Listing Content

Reuse most copy/screenshots from your Google Play submission. Differences:

### Required text fields
- **Name** (30 chars): `Zealova`
- **Subtitle** (30 chars): e.g., `AI Fitness Coach & Workouts`
- **Promotional Text** (170 chars, can update without resubmitting): current marketing hook
- **Description** (4000 chars): same as Play long description, but no Markdown
- **Keywords** (100 chars total, comma-separated, NO spaces after commas): e.g., `fitness,workout,ai,coach,gym,strength,cardio,meal,nutrition,training`
- **Support URL**: required
- **Marketing URL**: optional
- **Privacy Policy URL**: required
- **Copyright**: e.g., `© 2026 Zealova`

### Screenshots (required)
Apple is strict about resolutions. Easiest path: provide **6.9" (iPhone 16 Pro Max)** and **6.5"** sets — Apple auto-scales to smaller devices.

- **6.9" iPhone (1320×2868 portrait)** — 3 to 10 screenshots
- **6.5" iPhone (1284×2778 portrait)** — 3 to 10 screenshots
- **iPad 13" (2064×2752)** — required ONLY if you ship as universal/iPad-supported. If iPhone-only, set "Made for iPhone" and skip iPad.

Screenshots can be raw screen captures or designed marketing images (PNG, no alpha).

### App Preview videos (optional)
15–30 seconds, .mov/.mp4, per device size. Not required for first submission.

### Age Rating
Answer the questionnaire. Fitness apps with no objectionable content typically rate **4+**. Be honest about any user-generated content (chat).

### App Privacy ("Privacy Nutrition Label")
**Most-rejected step for first-time submitters.** Open App Privacy section and declare every data type your app collects. Common for Zealova:

- **Contact Info → Email Address** (linked to user, used for Account, app functionality)
- **Health & Fitness** (linked, used for App Functionality, Analytics)
- **User Content → Photos or Videos** (form videos, food photos)
- **User Content → Other User Content** (chat messages)
- **Identifiers → User ID** (Supabase user ID)
- **Usage Data → Product Interaction** (analytics)
- **Diagnostics → Crash Data + Performance Data** (Sentry)
- **Purchases → Purchase History** (RevenueCat)

Mark which are linked to identity vs anonymous, and which are used for tracking. Match your privacy policy exactly.

### Pricing & Availability
- **Price tier:** Free (since IAP unlocks Pro)
- **Availability:** All countries (or restrict if needed)
- **Pre-Order:** off

---

## 7. Submit for Review

1. App Store Connect → Your App → **App Store** tab → **iOS App 1.0** (or your version).
2. Under **Build**, select the TestFlight build that processed.
3. Fill **Version Information**:
   - What's New in This Version (skip for first submission)
   - Promotional Text
   - Description, Keywords, etc.
4. **App Review Information**:
   - Sign-in info: Apple reviewers MUST be able to log in. Provide a demo account: `reviewer@zealova.us` / strong password. Pre-populate that account with sample workouts/data so reviewers see the full feature set.
   - Notes: explain anything non-obvious, e.g., "This app uses RevenueCat for IAP. Free trial is 7 days; reviewer demo account has Pro auto-granted to bypass paywall."
   - Contact info (your phone + email)
5. **Version Release**:
   - **Manual** (release after approval — recommended for first launch)
   - **Automatic**
   - **Phased Release** for auto-updates (recommended for subsequent versions)
6. Click **Add for Review** → **Submit to App Review**.

**Review time:** typically 24–48 hours, occasionally up to 7 days.

---

## 8. Common Rejection Reasons (and how to dodge them)

1. **IAP not using StoreKit** — If you sell digital goods, you MUST use IAP (RevenueCat → StoreKit). No Stripe for digital subscriptions on iOS.
2. **Missing demo account** — Provide reviewer credentials. If reviewer can't get past login, instant rejection.
3. **Privacy label mismatch** — Your declared data types must match what your privacy policy says.
4. **Permissions without justification** — Every `NS*UsageDescription` string must clearly explain why. "We need your photos" → reject. "Used to upload food photos for nutrition analysis" → approve.
5. **Sign in with Apple required** — If you offer Google or Facebook login, you MUST also offer Sign in with Apple.
6. **Crashes on launch** — Test the production-signed IPA on a real device via TestFlight before submitting.
7. **Placeholder content** — Lorem ipsum, "TODO", or test data visible in the UI is an instant reject.
8. **Health claims** — Don't promise medical/clinical outcomes. Phrase as "may help" / "supports your fitness goals."
9. **Web views that look like apps** — fully-native-feeling screens are fine; embedding a website that does everything is not.
10. **Mismatched bundle metadata** — App display name "Zealova" but description constantly says "FitWiz" — make sure all marketing copy is rebranded.

---

## 9. Pre-submit Smoke Test (run from a TestFlight build, not debug)

- [ ] Sign up new account → onboarding → home loads
- [ ] Generate workout → completes within 30s
- [ ] Start workout → log set → finish workout
- [ ] Chat with AI Coach → text + image upload
- [ ] Subscribe via paywall (sandbox) → Pro unlocks
- [ ] Cancel/restore purchases works
- [ ] Push notification permission prompt shows
- [ ] Live Activity launches when workout starts (if enabled)
- [ ] No crashes after backgrounding/foregrounding 5 times
- [ ] Sign out → sign back in → data still there

---

## 10. After Approval

1. If you set **Manual release**, click **Release This Version** in App Store Connect.
2. App appears in App Store within 2–24 hours globally.
3. Monitor:
   - **Crashes**: Xcode → Window → Organizer → Crashes, plus Sentry
   - **Reviews**: respond to user reviews from App Store Connect → Ratings and Reviews
   - **Subscriptions**: RevenueCat dashboard
4. For each subsequent release, bump `version: 1.2.60+1133` → `1.2.61+1134` (build number must be unique and increasing within a CFBundleShortVersionString).

---

## 11. Quick Differences vs Google Play

| Topic | Google Play | App Store |
|---|---|---|
| Review time | A few hours – 3 days | 24h – 7 days |
| Bundle/Package ID immutable | yes | yes |
| IAP system | Google Play Billing | StoreKit (via RevenueCat) |
| Privacy declaration | Data Safety form | App Privacy "nutrition label" |
| Tracking permission prompt | Optional | Required (ATT) if using IDFA |
| Sign in with Apple | not required | required IF you offer other social logins |
| Test track | Internal/Closed/Open testing | TestFlight |
| Phased rollout | yes | yes (Phased Release) |
| Screenshots | flexible | strict size requirements |
| Free trial config | in Play Console | in App Store Connect (per product) |

---

## 12. Reference URLs

- App Store Connect: https://appstoreconnect.apple.com
- Developer Portal: https://developer.apple.com/account
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- TestFlight: https://testflight.apple.com
- RevenueCat iOS docs: https://www.revenuecat.com/docs/getting-started/installation/ios
- Privacy nutrition labels: https://developer.apple.com/app-store/app-privacy-details/
