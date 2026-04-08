# FitWiz Production Launch TODO

**Deadline**: 14 days from closed testing start (before applying for production)

---

## MUST DO WITHIN 14 DAYS (Production Blockers)

Google will reject or the app will break in production without these. Everything else can be updated after launch.

### 1. Payments Working (Google will reject if broken)
### 2. Prod vs Dev Environment (can't ship pointing to dev servers)
### 3. No Crashes on Main Flows (test end-to-end before submitting)

---

## Critical (Must Have Before Production)

### Payments & Subscriptions
- [ ] RevenueCat integration working end-to-end
- [ ] Subscription plans configured (monthly $4.99)
- [ ] Purchase flow tested (subscribe, restore, cancel)
- [ ] Paywall UI working correctly
- [ ] Free trial flow working
- [ ] Receipt validation on backend
- [ ] Handle subscription expiry gracefully (lock premium features, don't crash)
- [ ] Google Play Billing integration tested in sandbox mode

### Prod vs Dev Environment
- [ ] Separate prod and dev backend URLs (Render)
- [ ] Separate Supabase projects or environment flags
- [ ] Separate Gemini API keys (prod vs dev quotas)
- [ ] Separate Firebase projects (prod vs dev crashlytics)
- [ ] Environment switching in Flutter (--dart-define or .env)
- [ ] No debug logs in release builds
- [ ] No hardcoded dev URLs in production code
- [ ] API rate limits configured for production traffic

### Notifications
- [ ] Inexact alarm scheduling working (exact alarms removed)
- [ ] Workout reminders firing correctly
- [ ] Nutrition reminders working
- [ ] Fasting timer notifications working
- [ ] FCM push notifications from backend working
- [ ] Notification preferences saving/loading correctly
- [ ] Test notifications on real device (not just emulator)

### Delete Account
- [x] Black screen fix (navigating to /intro instead of /stats-welcome)
- [ ] Verify delete actually removes all user data from Supabase
- [ ] Verify RevenueCat subscription cancelled on delete
- [ ] Test delete flow end-to-end on real device

### Google Play Review Account
- [ ] Create a fresh test account with temp username/password for Google reviewers
- [ ] Complete onboarding on the test account so reviewer lands in the app
- [ ] Generate workouts for the test account so home screen isn't empty
- [ ] Add test credentials in Play Console > App access > Instructions
- [ ] Credentials: see GOOGLE_PLAY_TEST_ACCOUNT.md

---

## Important (Can Update After Launch)

### Reports / Wrapped
- [ ] Weekly summary generation working
- [ ] Monthly wrapped/recap feature
- [ ] Progress insights display correctly
- [ ] Stats dashboard populated with real data

### UI Fixes
- [ ] "Set your workout days" card navigates to settings (done)
- [ ] Review all empty states (no workouts, no meals, no progress)
- [ ] Loading states for all async operations
- [ ] Error states with retry options
- [ ] Dark mode consistency check
- [ ] Light mode consistency check

### Play Store Listing
- [ ] Update Screenshot #1 (AI coach - shorter chat exchange)
- [ ] Update Screenshot #5 (transformation - better photos)
- [ ] Remove subtitle text from screenshots (too small to read)
- [ ] Feature graphic uploaded (1024x500)
- [ ] App icon uploaded (512x512)
- [ ] Privacy policy URL live (https://fitwiz.us/privacy)
- [ ] Delete account URL live (https://fitwiz.us/delete-account)
- [ ] All data safety declarations completed
- [ ] Health Connect permissions descriptions filled

### Closed Testing
- [ ] 12 testers opted in and installed
- [ ] Collect feedback from testers
- [ ] Fix any critical bugs reported during testing

---

## Nice to Have (Can Do After Launch)

### Features
- [ ] WearOS companion app
- [ ] App Store (iOS) submission
- [ ] Social/sharing features
- [ ] Partial data deletion option

### Optimization
- [ ] Reduce AAB size (193MB - mostly Gemma AI model)
- [ ] Consider on-demand asset delivery for Gemma model
- [ ] Performance profiling on low-end devices
- [ ] Tablet screenshots for Play Store

### Marketing
- [ ] App preview video for Play Store
- [ ] A/B test screenshots with Google Play Console Experiments
- [ ] ASO keyword optimization based on search data

---

## Completed

- [x] Internal testing release uploaded
- [x] Google Play Console account setup
- [x] App icon and feature graphic created
- [x] 7 screenshots created
- [x] Store listing (name, short description, full description)
- [x] Content rating questionnaire
- [x] Data safety form completed
- [x] Target audience (18+)
- [x] App category (Health & Fitness)
- [x] Privacy policy page
- [x] Delete account page
- [x] Test reviewer account created (reviewer@fitwiz.us)
- [x] Exact alarm permissions removed
- [x] ABI splits disabled for app bundle
- [x] Android cmdline-tools installed
- [x] Build script created (build_appbundle.sh)
- [x] Foreground service declaration filled
- [x] Photo/video permissions declaration filled
- [x] Health Connect permissions descriptions filled
- [x] Merchant profile setup
