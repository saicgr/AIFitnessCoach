# Universal Links / App Links setup for referral invites

The Flutter app captures `/invite/{code}` links via `IncomingLinkService`
(`lib/data/services/incoming_link_service.dart`) and funnels them to
`PendingReferralService` → auto-apply after auth.

**The two well-known files are now co-located with the Vercel web app
under `frontend/public/.well-known/`** and are deployed automatically on
every `git push` via Vite + Vercel. No separate server hosting step.

Web host: **`fitwiz.us`** (Vercel). Bundle / package id remains
`com.fitwiz.app` — do NOT conflate the two.

## What you still need to do before production

1. **Replace `REPLACE_WITH_TEAM_ID`** in
   `frontend/public/.well-known/apple-app-site-association`:
   - Get the 10-char Apple Team ID from App Store Connect → Membership.
   - The resulting `appIDs` value looks like `ABC123DEFG.com.fitwiz.app`.

2. **Replace the two `REPLACE_WITH_*_SHA256`** lines in
   `frontend/public/.well-known/assetlinks.json`:
   ```bash
   # Release cert SHA-256:
   keytool -list -v -keystore ~/.android/fitwiz-release.jks -alias release \
     | grep "SHA256"
   # If Play App Signing is enabled, also grab the upload cert SHA-256
   # from Play Console → Setup → App integrity.
   ```

3. **Commit + push** — Vercel redeploys; the files will be live at:
   - `https://fitwiz.us/.well-known/apple-app-site-association`
   - `https://fitwiz.us/.well-known/assetlinks.json`
   Both will serve with `Content-Type: application/json` thanks to the
   `headers` block in `frontend/vercel.json`.

4. **Validate:**
   - Apple: https://branch.io/resources/aasa-validator/ → enter `fitwiz.us`
   - Google: https://developers.google.com/digital-asset-links/tools/generator
     → enter host `fitwiz.us`, relation `delegate_permission/common.handle_all_urls`,
     package `com.fitwiz.app`.

5. **TestFlight / Play internal test** — tap a share link in iMessage /
   WhatsApp → app should open directly to the home flow with the code
   already applied (look for `✅ [Auth] Applied pending referral` in
   `adb logcat -s flutter` or the Xcode console).

## How this repo is wired

### App side (already done)

- **iOS entitlement** (`mobile/flutter/ios/Runner/Runner.entitlements`):
  `applinks:fitwiz.us` under `com.apple.developer.associated-domains`.

- **Android intent-filter** (`mobile/flutter/android/app/src/main/AndroidManifest.xml`):
  `autoVerify="true"` on `https://fitwiz.us/invite/*`.

- **Flutter listener** (`mobile/flutter/lib/data/services/incoming_link_service.dart`):
  Subscribes to `app_links` cold-start + warm-start streams; extracts
  code from path or `?code=` query; stores via `PendingReferralService`;
  applies immediately if signed-in, else waits for post-auth flush
  (`AuthStateNotifier._flushPendingReferral`).

### Web side (now done)

- **`frontend/public/.well-known/apple-app-site-association`** — Apple fetches
  on first launch with the app installed. Declares `/invite/*` as an app-
  handled path.

- **`frontend/public/.well-known/assetlinks.json`** — Android verifies on
  install. Same intent.

- **`frontend/vercel.json` `headers` block** — forces
  `Content-Type: application/json` (Apple requires JSON; defaults to
  `application/octet-stream` otherwise). Also sets a 1-hour cache so
  Apple / Google's CDN doesn't thrash.

- **`frontend/src/pages/Invite.tsx` + `/invite/:code` route** — landing
  page for users who tap the link in a desktop browser, Slack preview,
  or before the app is installed. Shows the code big, copy-to-clipboard
  button, App Store + Play Store CTAs. On iOS/Android it also fires a
  one-shot `fitwiz://invite/{code}` to open the app if installed (silent
  fallback to the web UI if not).

## Testing without production files

The custom-scheme fallback works immediately, no server setup:
```
fitwiz://invite/ABC123
fitwiz://invite?code=ABC123
```
Use these for manual QA. Share links from the app use
`https://fitwiz.us/invite/...` — those land on the web page until the
AASA / assetlinks files have valid Team ID / SHA-256 values deployed.

## Deferred install (app NOT yet installed)

Neither Universal Links nor App Links can deliver the code when the
target app isn't installed — Safari/Chrome loads the web URL, the user
taps "Get the app", and after install the code context is lost.

Backstops:
- The `/invite/:code` web page shows the code prominently + copy button.
- The `ReferralsScreen` has a "Have a code from a friend?" card for
  post-signup manual entry.
- The pre-auth `PreAuthReferralChip` lets users paste the code they
  remembered/screenshotted before signing in.
- If this channel grows meaningful, integrate Branch.io or Firebase
  Dynamic Links so the code survives the App Store round-trip.
