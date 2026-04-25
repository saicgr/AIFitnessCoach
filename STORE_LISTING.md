# FitWiz Play Store Listing — copy-paste source of truth (Play only)

Last updated: 2026-04-25.
iOS submission deferred — this file covers Google Play only. When iOS
work resumes, restore the App Store Connect section from git history.

These strings go into the **Play Console** dashboard, NOT into Android
`strings.xml`. Launcher label (`app_name`) stays short — `FitWiz` —
because Android launchers truncate around 12–15 chars under the icon,
and a long marketing title turns into `FitWiz: Wo...` on the home screen.

> Trademark note (2026-04-25): USPTO Reg #7111694 / Serial 97441093
> "FITWIZ" is LIVE / REGISTERED in IC 009, owner LIN, JIANGJUAN
> (Ningbo, China; Canadian citizen), and competitor app `fitwiz.app`
> last updated Oct 2025. Title below uses a real product descriptor
> (Workout & Meal Coach) as a disambiguator. This does not immunize
> against an IP takedown but it (a) reduces consumer-confusion evidence
> in any DuPont analysis, (b) gives Play reviewers metadata grounds to
> differentiate. Takedown response ready at
> `TRADEMARK_TAKEDOWN_RESPONSE.md`.

---

## Google Play Console — Main store listing

**Path:** Play Console → All apps → FitWiz → Grow → Store presence → Main store listing.

| Field | Limit | Value |
|---|---|---|
| App name | 30 | `FitWiz: Workout & Meal Coach` (28) |
| Short description | 80 | `AI coach that builds your workouts & tracks meals — type, snap, or scan.` (72) |
| Full description | 4 000 | See `PLAY_STORE_LISTING_COPY.md` (~3 970 chars) |
| App category | — | Health & Fitness |
| Tags | up to 5 | Strength training, Nutrition, Personal trainer, Workout planner, Calorie counter |
| Contact email | — | `support@fitwiz.us` |
| Website | — | `https://fitwiz.us` |
| Privacy policy | — | `https://fitwiz.us/privacy` |

### Play Store screenshots checklist

- 1080×1920 minimum, 8 max, no `fitwiz.app` strings, no competitor mark.
- Lead screenshot = the differentiator (workout + meal in one shot).
- Caption every screenshot — Play surfaces captions in search.

---

## What stays in code (already correct, don't change)

| File | Field | Value | Why |
|---|---|---|---|
| `mobile/flutter/android/app/src/main/res/values/strings.xml` | `app_name` | `FitWiz` | Launcher icon label — keep short or it truncates |
| `mobile/flutter/pubspec.yaml` | `name` | `fitwiz` | Dart package — never user-visible |

---

## Status — Play submission

### Done
- [x] AndroidManifest applicationId `com.aifitnesscoach.app`
- [x] Both `assetlinks.json` files have real release + upload SHA-256
- [x] No `fitwiz.app` / `com.fitwiz.app` strings in shipping code
- [x] Wear OS module disabled at `wearos/settings.gradle.kts`
- [x] CI workflow added at `.github/workflows/android-release.yml`
- [x] Takedown response draft at `TRADEMARK_TAKEDOWN_RESPONSE.md`
- [x] Listing title set in Play Console: `FitWiz: Workout & Meal Coach`
- [x] Short description set, em-dash compliant
- [x] Full description set (~3 970 chars, em-dash compliant, pricing matches paywall)
- [x] Data safety form completed
- [x] Icon, feature graphic, screenshots uploaded
- [x] Signed AAB built and uploaded
- [x] Internal testing complete
- [x] Closed testing complete
- [x] Ready for production promotion

### Outstanding before production rollout
- [ ] **fitwiz.us canonical domain fix** — STILL redirecting to `ai-fitness-coach-orcin.vercel.app` as of 2026-04-25. Privacy/Terms/Refunds links in the live Play listing will land users on `vercel.app`. Fix in Vercel dashboard → Settings → Domains; full walkthrough in `PRE_REVIEW_SUBMISSION_GUIDE.md`.
- [ ] Subscription product status = ACTIVE in Play Console → Monetize → Products → Subscriptions (verify, not Draft)
- [ ] Tax + payments profile complete in Play Console → Setup → Payments
- [ ] Reviewer test account `reviewer@fitwiz.us` verified end-to-end on the closed-testing build (login + paywall trial flow works)
- [ ] Final dated screenshot of competitor's FITWIZ App Store listing saved to evidence folder

### Production rollout strategy
- Stage at 20% for first 48 hours → 50% if no crash spike → 100% by day 4
- Watch Play Console → Quality → Android vitals every 4 h for first 48 h
- Watch `support@fitwiz.us` daily for forwarded IP complaints

### User-side, no software needed
- [ ] LLC formed (Delaware/Wyoming) — liability shield given known FITWIZ trademark overlap
- [ ] Release keystore backed up (1Password / iCloud encrypted / Google Drive encrypted) — losing it means you can never update the app under this signing key
- [ ] Full TSDR record for FITWIZ Reg #7111694 saved as PDF (`https://tsdr.uspto.gov/#caseNumber=97441093`) — the "namely" clause matters for any future dispute
