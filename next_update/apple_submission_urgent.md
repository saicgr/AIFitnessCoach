# Zealova — First Apple App Store Submission · URGENT Checklist

**Scope:** Items that block first iOS App Store submission or are common rejection causes for health/fitness apps. Pure-submission checklist — feature work lives in `youtube_audit_tasks_immediate.md`.

**Tag legend:**

- **[URGENT · VERIFY]** — confirm-already-shipped task (no new code expected; test it works end-to-end on a fresh install)
- **[URGENT · UI]** — add/modify a visible UI element
- **[URGENT · BACKEND]** — backend change required
- **[URGENT · OPS]** — operational / App Store Connect / config task (no app code)

When this submission lands, mark every item `[x]` and the file becomes the pre-submission audit trail for the next release.

---

## App Store guideline compliance

- [ ] **[URGENT · VERIFY] Account deletion flow works end-to-end** — Apple guideline 5.1.1(v) requires in-app account deletion for any app that creates accounts. `delete_account_flow.dart` exists per project memory; confirm: tap → confirm → backend deletes user record → user logged out → cannot sign back in with same credentials. Test on a fresh test account before submitting. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Sign in with Apple is enabled** — Apple 4.8 requires it if any other 3rd-party login (Google) is offered. Verify the Apple sign-in button is present on `sign_in_screen.dart` AND completes successfully against Supabase Auth. _Added 2026-05-26._
- [ ] **[URGENT · OPS] Privacy policy URL accessible + accurate** — must declare every data category collected (health data, location, photos, biometric-derived metrics, ChromaDB embeddings of chat history, PostHog analytics). Apple 5.1.1. URL must be reachable from the App Store listing AND from in-app Settings. _Added 2026-05-26._
- [ ] **[URGENT · OPS] Terms of Service URL accessible + accurate** — required for subscriptions per Apple 3.1.2. Same accessibility requirement as privacy policy. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Info.plist permission usage strings are descriptive (not placeholder)** — Apple 5.1.1(i) rejects vague strings. Verify: `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription` all explain WHY in plain English. Example required: "Zealova reads your workouts and sleep from Apple Health to personalize your training and recovery." _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] "Restore Purchases" button on paywall** — Apple 3.1.1 requires it. Confirm `paywall_pricing_screen.dart` has a visible "Restore Purchases" CTA that calls RevenueCat's `Purchases.restorePurchases()`. _Added 2026-05-26._
- [ ] **[URGENT · UI] Subscription terms displayed prominently on paywall** — Apple 3.1.2(a): price, billing period, auto-renewal language, cancel-anytime link must be visible on the buying surface, not buried. Example required string: "Auto-renewing subscription. Cancel anytime in Settings → Apple ID → Subscriptions." Confirm this is on `paywall_pricing_screen.dart` and NOT just in fine print. _Added 2026-05-26._
- [ ] **[URGENT · UI] Medical disclaimer banner on form scoring + AI Coach replies that discuss symptoms/pain** — Apple 5.5 + 1.4.1 require clear "not medical advice" disclaimers for any health-adjacent guidance. `medical_disclaimer_screen.dart` exists per memory; verify it's gated as a one-time-acknowledged screen post-onboarding AND a persistent "not medical advice" footer renders on form-check results + injury-agent replies. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] No App Tracking Transparency violation** — confirm Zealova does NOT use IDFA / Facebook SDK / advertising ID for tracking. If we do, an ATT prompt must fire BEFORE any tracking call. PostHog with default config does not require ATT, but verify. Apple 4.5.4. _Added 2026-05-26._
- [ ] **[URGENT · OPS] App Store screenshots reflect current UI** — Apple 2.3.10 rejects stale screenshots. Re-shoot for current Material 3 theme + 4-pillar dashboard + My Space + AI Coach chat + paywall. iPhone 17 Pro Max (6.9") + iPhone 8 Plus (5.5") sizes required. _Added 2026-05-26._
- [ ] **[URGENT · OPS] App Store description text accurate — no false advertising** — every feature claimed in the description must exist and work. Audit the Play Store description (live) for any claim that doesn't match the iOS submission build. Apple 2.3.1. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Contact / support email working in Settings → Help** — Apple 1.5 requires accessible support contact. Verify `mailto:` link in `settings_screen.dart` opens with the correct support address AND the inbox is monitored. _Added 2026-05-26._
- [ ] **[URGENT · OPS] App Store Connect health-app questionnaire answered** — Apple's Data Use questionnaire (App Privacy section) must declare: health data collected, used to personalize, not shared with third parties (or list third parties: Supabase, Gemini, PostHog, Sentry, RevenueCat). Mismatch with actual code = rejection. _Added 2026-05-26._

## Crash + completeness

- [ ] **[URGENT · VERIFY] First-launch flow on a fresh install with no prior account** — install → splash → intro → sign up (Apple) → onboarding → first paywall view → home. Must complete without crash, freeze, or dead-end screen. Test on iPhone SE (smallest screen) + iPhone 17 Pro Max (largest). _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Empty-state handling on every primary screen** — Home (no workouts logged), Workouts (no plan yet), Nutrition (no foods logged), Chat (empty thread), Profile (no photo). Apple 4.0 / 2.1 rejects placeholder-looking screens. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Network failure recovery** — airplane-mode test on every primary screen: no infinite loaders, no white screens. Per `feedback_no_silent_fallbacks.md`: throw errors visibly, show retry CTA. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Sign-out + re-sign-in flow works cleanly** — tap sign out → confirm → land on intro → sign back in → user state restored (no orphaned local data, no stale auth tokens). _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Sandbox subscription purchase flow** — buy via Apple sandbox account → unlock premium → cancel via sandbox Settings → see grace period → fall back to free state correctly. Same for restore. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] iOS 17 + iOS 18 + iOS 26 tested** — minimum deployment target is iOS 15.0 per memory; confirm last 3 major versions render correctly. iOS 26 (current) is the priority since it's where most users will be. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Crash reporting (Sentry) live and capturing first-launch crashes** — sanity-check Sentry dashboard for the build under submission. A first-launch crash that surfaces in sandbox testing is a Day-1 fix. _Added 2026-05-26._

## Health-data-specific (Apple is strict here)

- [ ] **[URGENT · VERIFY] HealthKit permissions request only what's needed** — Apple 5.1.1(ii) data-minimization rule. Verify Zealova doesn't request `bloodType`, `dateOfBirth`, or sensitive types it doesn't actually use. Cross-reference the requested types in `health_service_ui.dart` against actual code consumers. (Project memory `project_play_health_connect_rejection.md` already documented Android HC rejection for over-asking — same risk on iOS.) _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] No coach reply gives diagnostic / treatment advice** — Apple 1.4.1 rejects medical-claim language. Spot-check coach replies for "you should take X", "this means you have Y", "stop doing Z because it's dangerous." Coach must redirect to "consult your doctor" for symptom questions. _Added 2026-05-26._
- [ ] **[URGENT · VERIFY] Form scoring results don't claim injury diagnosis** — `form_analysis_service.py` returns a 1-10 form score; verify the UI in `form_check_result_card.dart` frames it as "technique feedback" not "injury prevention" / "you have impingement risk" / etc. _Added 2026-05-26._

## Optional but recommended before first submission

- [ ] **[URGENT · OPS] TestFlight external testing with 5+ real users for ≥3 days** — catches the rejection-bait issues internal testing always misses. _Added 2026-05-26._
- [ ] **[URGENT · OPS] App Review demo account credentials provided** — App Review uses the credentials you give them on the build. Per memory, `reviewer@fitwiz.us` is permanently premium. Confirm those credentials are in App Store Connect's "App Review Information" field. _Added 2026-05-26._

---

## Submission-day checklist (run top to bottom on the morning of submission)

1. All items in this file checked.
2. Build archived in Xcode → upload to App Store Connect via Transporter or Xcode.
3. TestFlight build available + tested by you on a fresh device.
4. Screenshots uploaded for all required device sizes.
5. App description, keywords, support URL filled in.
6. App Privacy questionnaire matches code reality.
7. App Review Information notes filled (test creds + any flow notes for the reviewer).
8. Submit for review.

If rejected, the rejection email tells you the guideline number — find the matching item in this file, fix it, resubmit. Update this file with the lesson so the next release doesn't repeat the issue.
