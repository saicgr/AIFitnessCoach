# Pre-Review Submission Guide

Last updated: 2026-04-25.
Use alongside `STORE_LISTING.md` (copy values from there) and
`TRADEMARK_TAKEDOWN_RESPONSE.md` (keep ready in case of IP complaint).

---

## How to set the Zealova long title BEFORE Google review

There are **two** "name" fields and they live in different places. Get
both right.

### 1. Launcher icon label (already correct, do NOT change)

The label that shows under your icon on the Android home screen comes
from `mobile/flutter/android/app/src/main/res/values/strings.xml`:

```xml
<string name="app_name">Zealova</string>
```

Keep this `Zealova`. Android launchers truncate around 12–15 characters
under an icon, so a long marketing title would render as `Zealova: Wo...`
on the home screen. Top-grossing fitness apps (Fitbod, Hevy, MyFitnessPal,
Strava) all use a short launcher label and a long Play Store title.

### 2. Play Store listing title (the marketing title — set in browser)

This is set in the **Play Console UI**, not in code. Steps:

1. Open https://play.google.com/console → select your developer account.
2. Left sidebar → **All apps** → click **Zealova**.
3. Left sidebar inside the app → **Grow** section → **Store presence** →
   **Main store listing**.
4. Field: **App name** (max 30 chars). Enter:
   ```
   Zealova: Workout & Meal Coach
   ```
   (28 characters — fits within the 30-char limit.)
5. Field: **Short description** (max 80). Enter:
   ```
   AI-built workout, meal, and strength plans that adapt to your goals.
   ```
6. Field: **Full description** (max 4 000). Paste the long description
   block from `STORE_LISTING.md` → "Long description (Play)" section.
7. Upload icon, feature graphic, and screenshots (see the screenshot
   checklist in `STORE_LISTING.md`).
8. Click **Save** at the top right.
9. Click **Send X changes for review** (Play queues the listing change
   along with the AAB review).

The title takes effect when Play approves the new release. You can edit
it later, but each edit re-triggers Play review (typically 24–72 h).

### 3. App Store Connect (when iOS is ready, separate flow)

1. Open https://appstoreconnect.apple.com → **My Apps** → **Zealova**.
2. Left sidebar → **App Store** → **iOS App** → **1.0 Prepare for Submission**.
3. Section: **App Information** → **Localizable Information** →
   - **Name** (max 30): `Zealova: Workout & Meal Coach`
   - **Subtitle** (max 30): `Personalized strength & cardio`
4. Section: **Version Information** →
   - **Promotional Text** (max 170): see `STORE_LISTING.md`
   - **Description** (max 4 000): paste the description block
   - **Keywords** (max 100, hidden): paste the comma-separated keyword list
5. **Privacy Policy URL**: `https://zealova.com/privacy`
6. **Support URL**: `https://zealova.com`
7. Click **Save** then **Submit for Review**.

---

## Critical: fix Vercel canonical domain BEFORE Play submission

**Problem:** `https://zealova.com/privacy` currently returns `307` redirect
→ `https://ai-fitness-coach-orcin.vercel.app/privacy` (verified
2026-04-25 with curl). Google's review bot follows redirects, and the
final URL bar will show `vercel.app`, not `zealova.com`. This is:

- Cosmetically bad — your privacy policy URL "looks fake" in the
  reviewer's browser.
- Trademark-relevant — if a reviewer or the FITWIZ trademark holder
  later inspects, the redirect shows your "marketing domain" isn't
  actually serving the legal pages you reference.
- ASO-relevant — Apple's review team treats redirect chains as a
  small risk signal.

**Fix (Vercel dashboard):**

1. Open https://vercel.com → select the `ai-fitness-coach` project.
2. **Settings** → **Domains**.
3. Find `zealova.com` in the domain list.
   - If it's listed but marked "Redirect to ai-fitness-coach-orcin.vercel.app"
     → click the three-dot menu → **Edit** → set to **No redirect**, then
     mark `zealova.com` as **Production** domain.
   - If `ai-fitness-coach-orcin.vercel.app` is the production domain →
     click the three-dot menu next to it → **Move to Preview** (or remove
     entirely). Mark `zealova.com` as the new Production domain.
4. **DNS check:** ensure your registrar's DNS for `zealova.com` points to
   Vercel:
   - `A` record `@` → `76.76.21.21`
   - `CNAME` record `www` → `cname.vercel-dns.com.`
5. Wait 5–10 minutes for propagation.
6. Re-verify with:
   ```bash
   curl -sIL -o /dev/null -w "%{http_code} → %{url_effective}\n" \
     https://zealova.com/privacy
   ```
   Expected: `200 → https://zealova.com/privacy` (no redirect to vercel.app).

**Also check:** Vercel **Settings** → **Deployment Protection** must be
**Disabled** for production (or "Only Preview Deployments"). If
production has password protection, Google's bot gets a 401 and
**rejects the app**.

---

## Pre-submission final blockers (in order)

| # | Item | How to verify | Status |
|---|---|---|---|
| 1 | Title set in Play Console | https://play.google.com/console → Main store listing → App name | Pending — do this in browser |
| 2 | Vercel canonical domain | curl `zealova.com/privacy` returns 200 directly | Failing — fix above |
| 3 | Vercel deployment protection | curl returns 200 (not 401) | Passing (200 OK) |
| 4 | google-services.json in CI | `.github/workflows/android-release.yml` decodes from secret | Workflow added; populate secrets |
| 5 | Release keystore | Generated, backed up, fingerprints in assetlinks.json | Fingerprints already in assetlinks.json — verify keystore is backed up |
| 6 | Internal testing track | Play Console → Testing → Internal testing → Create release | Do AFTER #1–4 |
| 7 | Reviewer test account | `reviewer@zealova.com` (already created per PRODUCTION_TODO.md) | Verify still works |
| 8 | Privacy policy / Terms / Refund pages live on zealova.com | curl all three return 200 directly | Pending fix #2 |
| 9 | Takedown response draft saved | `TRADEMARK_TAKEDOWN_RESPONSE.md` exists | Done |
| 10 | LLC formed (optional but recommended) | Delaware / Wyoming filing receipt | User-side action |

---

## Play Console submission flow (recommended)

1. **Internal testing track first.** Play Console → Testing →
   Internal testing → Create new release. Upload AAB. Add yourself +
   reviewer@zealova.com as testers. Verify install via opt-in link.
2. **Closed testing** (if Play requires it for new personal-account
   apps — currently 14-day requirement for personal accounts, not for
   organization accounts).
3. **Open testing** (optional, builds reviews).
4. **Production**.

**Why staged:** Play often surfaces metadata rejection at internal-test
review stage too — catching it on internal saves you a full production
re-review cycle (24–72 h).

---

## What to do the moment Play approves

1. Tag the release in git: `git tag v1.0.0-play-launch && git push --tags`
2. Take dated screenshots of the live Play listing for evidence.
3. Save the production AAB hash + Play release ID for your records.
4. Watch Play Console → Quality → Crashes & ANRs every 4 hours for
   first 48 hours.
5. Watch your support@zealova.com inbox for IP complaint forwards from
   Google. Have `TRADEMARK_TAKEDOWN_RESPONSE.md` open.
