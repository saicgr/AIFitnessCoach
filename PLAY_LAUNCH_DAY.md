# FitWiz Play Launch — Day-Of Punch List

Last updated: 2026-04-25.
iOS deferred. This file is the only thing you need open when promoting
to Production.

---

## Status

Closed testing is complete. Build is ready for Production promotion.
Six items left, in order.

---

## 1. Fix Vercel canonical domain (5 min, blocks production rollout)

**Verified 2026-04-25 still broken:**

```
$ curl -sIL https://fitwiz.us/privacy
…
location: https://ai-fitness-coach-orcin.vercel.app/privacy
```

When users tap the privacy/terms/refund links in your live Play
listing, they'll land on `vercel.app` — looks fake, weakens you in any
future trademark dispute, and is a one-click reviewer ding.

### Fix

1. Open https://vercel.com → select project `ai-fitness-coach`.
2. **Settings → Domains.**
3. Find `fitwiz.us` in the list.
   - If marked "Redirect to ai-fitness-coach-orcin.vercel.app" → click
     ⋯ → **Edit** → set to **No redirect**, mark `fitwiz.us` as
     **Production**.
   - If `ai-fitness-coach-orcin.vercel.app` is currently the Production
     domain → click ⋯ next to it → **Move to Preview** (or remove
     entirely). Then mark `fitwiz.us` as the Production domain.
4. **DNS check** (registrar):
   - `A` record `@` → `76.76.21.21`
   - `CNAME` record `www` → `cname.vercel-dns.com.`
5. Wait 5–10 min, then re-verify:

```bash
curl -sIL -o /dev/null -w "%{http_code} → %{url_effective}\n" \
  https://fitwiz.us/privacy
# Expected: 200 → https://fitwiz.us/privacy   (no vercel.app)
```

Also confirm the `assetlinks.json` resolves directly on `fitwiz.us`:

```bash
curl -sIL -o /dev/null -w "%{http_code} → %{url_effective}\n" \
  https://fitwiz.us/.well-known/assetlinks.json
```

If this still hits `vercel.app`, Android App Links verification will
break for any post-launch deep-link work.

---

## 2. Confirm subscription product is ACTIVE (2 min)

Play Console → **Monetize → Products → Subscriptions.**

- [ ] Subscription exists for the SKU your app references in RevenueCat
- [ ] Status = **Active** (not "Draft" — Draft lets you submit but
      paywall fails on first user)
- [ ] Price = `$49.99/yr` (matches the description text and
      `paywall_pricing_screen.dart`)
- [ ] 7-day free trial offer attached
- [ ] $39.99/yr retention offer configured (per
      `paywall_pricing_screen.dart`)

---

## 3. Confirm Tax + Payments profile (2 min)

Play Console → **Setup → Payments profile.**

All sections must show ✅ green:

- [ ] Business information
- [ ] Tax information
- [ ] Payment method

If any are red/yellow, paid product won't transact even though the AAB
ships.

---

## 4. Verify reviewer test account end-to-end (10 min)

On a clean Android device (or emulator):

1. Install the closed-testing build via the opt-in URL.
2. Sign in as `reviewer@fitwiz.us`.
3. Verify:
   - [ ] Onboarding completes without errors
   - [ ] Home screen loads with at least one workout
   - [ ] Open the paywall, start the 7-day trial flow, complete with a
         real card (you'll refund) or sandbox payment method
   - [ ] Premium features unlock after subscription
   - [ ] Account deletion path works (Settings → Danger Zone)

If anything errors, fix in code before promoting.

---

## 5. Save dated competitor evidence (1 min)

Open the existing FitWiz iOS App Store listing in a browser (Safari
private window so it doesn't pull your account context). Screenshot:

- Title and developer name
- Icon
- Screenshots (all of them)
- "More from this developer" section
- App Store description

Save to a folder like `~/Documents/fitwiz-trademark-evidence/2026-04-25/`
with date in folder name. Keep this for the life of the app — if the
FITWIZ trademark holder later updates their listing to look more like
yours, your dated capture is the proof.

---

## 6. Promote to Production with staged rollout (5 min)

Play Console → **Production → Releases → Edit release** (or create
release from internal/closed track).

- [ ] Release notes filled in (English US, ~500 chars max for first
      release): a short version of "What's new" — for v1.0.0,
      "Initial release. AI workout and nutrition coach in one app."
- [ ] **Rollout percentage = 20%** (NOT 100%)
- [ ] Click **Start rollout to Production**

Play review takes 24–72 h for a new app on first production submission.

---

## After rollout starts (day 1–2)

- [ ] Play Console → Quality → Android vitals — check every 4 h for
      first 48 h. Crash-free rate goal: > 99%. ANR rate goal: < 0.5%.
- [ ] `support@fitwiz.us` inbox — Apple/Google forward IP complaints
      here. Response template in `TRADEMARK_TAKEDOWN_RESPONSE.md`,
      respond within 48 h.
- [ ] Day 2: if clean → bump rollout to 50%
- [ ] Day 4: if still clean → bump to 100%
- [ ] After 100%: `git tag v1.0.0-play-launch && git push --tags`

---

## User-side (do these this week, no software needed)

- [ ] **Form an LLC** (Delaware or Wyoming, ~$100–500). Liability
      shield matters disproportionately given the known FITWIZ
      trademark overlap.
- [ ] **Back up the release keystore.** Copy `~/.android/<release>.jks`
      to two locations (1Password vault + Google Drive encrypted, or
      iCloud encrypted + a USB drive in a fireproof box). Losing this
      file means you can never push another update under this signing
      key, and Play won't let you re-sign.
- [ ] **Pull the full TSDR record for FITWIZ Reg #7111694** as a PDF.
      Go to https://tsdr.uspto.gov/#caseNumber=97441093 → Documents
      tab → save the registration certificate + specimen of use. The
      "namely" clause in the goods description is your strongest
      non-confusion argument if a complaint arrives.

---

## What is NOT on this list (already done)

- ✅ Listing title, short desc, full desc set with em-dash compliance
- ✅ Data safety form
- ✅ Icon, feature graphic, screenshots
- ✅ Signed AAB built
- ✅ Internal + closed testing
- ✅ Code clean of `fitwiz.app` / `com.fitwiz.app`
- ✅ Wear OS disabled
- ✅ assetlinks.json + AASA fingerprints
- ✅ Takedown response draft
- ✅ CI workflow scaffold (use later if you want, not blocking)

---

## What is NOT on this list (deferred)

- iOS App Store submission — will resume after Play is stable
- GitHub Actions secrets population — only needed if/when CI builds
  replace local `flutter build appbundle` runs
