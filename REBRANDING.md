# Rebranding playbook — FitWiz → NewName

Single-source guide for renaming the app. Lists every config file, every
external service, and every locked identifier. Tested end-to-end via dry-run.

---

## TL;DR — the 3 commands to rename

```bash
# 1. Rename across all source code, native configs, top-level docs
./scripts/rename_brand.sh "FitWiz" "NewName" "fitwiz.us" "newname.com"

# 2. Verify
cd mobile/flutter && flutter clean && flutter analyze && flutter test
cd backend && pytest tests/
cd frontend && npm run build

# 3. Commit + push (handles git history)
git add -A && git commit -m "rebrand: FitWiz → NewName"
```

Then do the **infra-side work** (you, not the script): see [§ External services](#external-services).

---

## Central config files (single source of truth)

When you rename, edit these three files. Everything else flows from them.

| Stack | Path | Constant accessor |
|---|---|---|
| Flutter (Dart) | `mobile/flutter/lib/core/constants/branding.dart` | `Branding.appName`, `Branding.fullTitle`, `Branding.supportEmail`, etc. |
| Backend (Python) | `backend/core/branding.py` | `branding.APP_NAME`, `branding.FROM_EMAIL`, `branding.SUPPORT_EMAIL`, etc. |
| Web frontend (TS) | `frontend/src/lib/branding.ts` | `BRANDING.appName`, `BRANDING.fullTitle`, `BRANDING.supportEmail`, etc. |

**Plus 1 helper file:**

| Path | Purpose |
|---|---|
| `frontend/src/lib/links.ts` | Derives URLs from `BRANDING.marketingDomain` + `BRANDING.packageIdAndroid` |

**Plus 1 build plugin:**

| Path | Purpose |
|---|---|
| `frontend/vite.config.ts` (HTML transform) | Substitutes `%BRAND_NAME%`, `%BRAND_FULL_TITLE%`, `%BRAND_DOMAIN%`, `%BRAND_WEBSITE%`, `%BRAND_TAGLINE%` in `frontend/index.html` at build time |

---

## Constants exposed by each file

### Flutter `Branding` (Dart)

```dart
Branding.appName           // 'FitWiz'
Branding.fullTitle         // 'FitWiz: Workout & Meal Coach'
Branding.tagline           // 'Workout & Meal Coach'
Branding.supportEmail      // 'support@fitwiz.us' (re-export from AppLinks)
Branding.websiteUrl        // 'https://fitwiz.us' (re-export from AppLinks)
Branding.marketingDomain   // 'fitwiz.us'
Branding.watermarkText     // = appName
Branding.version           // '1.0.0'

// LOCKED forever (informational — never change post-launch)
Branding.packageIdAndroid    // 'com.aifitnesscoach.app'
Branding.packageIdIos        // 'com.aifitnesscoach.app'
Branding.widgetAppGroupId    // 'group.com.aifitnesscoach.widgets'
Branding.deepLinkScheme      // 'fitwiz'
```

### Backend `branding` (Python)

```python
branding.APP_NAME              # "FitWiz"
branding.APP_FULL_TITLE        # "FitWiz: Workout & Meal Coach"
branding.APP_TAGLINE           # "Workout & Meal Coach"
branding.WEBSITE_URL           # "https://fitwiz.us" (env-overridable)
branding.MARKETING_DOMAIN      # "fitwiz.us" (env-overridable)
branding.SUPPORT_EMAIL         # "support@fitwiz.us" (env-overridable)
branding.PRIVACY_EMAIL         # "privacy@fitwiz.us" (env-overridable)
branding.FROM_EMAIL            # "FitWiz <hello@fitwiz.us>" (uses RESEND_FROM_EMAIL env)
branding.PLAN_SHARE_BASE       # "https://fitwiz.us/p"
branding.WORKOUT_SHARE_BASE    # "https://fitwiz.us/w"
branding.RECIPE_SHARE_BASE     # "https://fitwiz.us/r"
branding.INVITE_BASE           # "https://fitwiz.us/invite"
branding.UPGRADE_URL           # "https://fitwiz.us/upgrade"
branding.INSTAGRAM_URL         # "https://instagram.com/fitwiz.us"
branding.DISCORD_URL           # discord invite
branding.OPENAPI_TITLE         # "FitWiz API"
branding.SUPPORT_USER_NAME     # "FitWiz Support"
branding.MERCH_PRODUCT_PREFIX  # "FitWiz" (used for "FitWiz T-Shirt" etc.)

# LOCKED forever
branding.PACKAGE_ID_ANDROID    # "com.aifitnesscoach.app"
branding.PACKAGE_ID_IOS        # "com.aifitnesscoach.app"
branding.DEEP_LINK_SCHEME      # "fitwiz"
```

Env-var overrides (set in Render dashboard / `backend/.env`):
- `FITWIZ_WEBSITE_URL`
- `FITWIZ_MARKETING_DOMAIN`
- `FITWIZ_SUPPORT_EMAIL`
- `FITWIZ_PRIVACY_EMAIL`
- `RESEND_FROM_EMAIL`

### Web frontend `BRANDING` (TypeScript)

```typescript
BRANDING.appName            // 'FitWiz'
BRANDING.fullTitle          // 'FitWiz: Workout & Meal Coach'
BRANDING.tagline            // 'Workout & Meal Coach'
BRANDING.supportEmail       // 'support@fitwiz.us'
BRANDING.privacyEmail       // 'privacy@fitwiz.us'
BRANDING.websiteUrl         // 'https://fitwiz.us'
BRANDING.marketingDomain    // 'fitwiz.us'
BRANDING.instagram          // 'https://instagram.com/fitwiz.us'

// LOCKED forever
BRANDING.packageIdAndroid   // 'com.aifitnesscoach.app'
BRANDING.packageIdIos       // 'com.aifitnesscoach.app'
BRANDING.deepLinkScheme     // 'fitwiz'
```

### Vite HTML placeholders (auto-resolved at build)

In `frontend/index.html`:
- `%BRAND_NAME%` → `BRANDING.appName`
- `%BRAND_FULL_TITLE%` → `BRANDING.fullTitle`
- `%BRAND_TAGLINE%` → `BRANDING.tagline`
- `%BRAND_DOMAIN%` → `BRANDING.marketingDomain`
- `%BRAND_WEBSITE%` → `BRANDING.websiteUrl`

---

## Native config files

These cannot read the constants at compile time. The `rename_brand.sh` script
handles them via sed.

### iOS (`mobile/flutter/ios/`)

| File | What it controls |
|---|---|
| `Runner/Info.plist` | `CFBundleDisplayName`, `CFBundleName`, URL schemes |
| `RunnerWidget/Info.plist` | Widget display name |
| `FitWizLiveActivity/SETUP.md` | Live Activity setup instructions |

### Android (`mobile/flutter/android/`)

| File | What it controls |
|---|---|
| `app/src/main/res/values/strings.xml` | `app_name` (launcher label) |
| `app/src/main/AndroidManifest.xml` | `android:label`, deep-link host (`fitwiz.us`) |
| `app/src/main/res/xml/shortcuts.xml` | App shortcuts labels |
| `app/src/main/res/layout/widget_meal_suggestion.xml` | Widget labels |
| `app/src/main/res/drawable/launch_background.xml` | Splash screen comments |
| `keystores/README.md` | Keystore documentation |

### Wear OS (`wearos/app/src/`) — disabled, not shipping

| File | What it controls |
|---|---|
| `main/AndroidManifest.xml` | Wear OS app declaration |
| `main/res/values/strings.xml` | Wear OS launcher label |
| `main/kotlin/com/aifitnesscoach/wearos/**/*.kt` | All Kotlin source (package = `com.aifitnesscoach.wearos`) |

Note: WearOS module is disabled at `wearos/settings.gradle.kts` (commented out
`include(":app")`). Kotlin package was renamed from `com.fitwiz.wearos` →
`com.aifitnesscoach.wearos` to align with the locked Android package ID.

### Flutter `pubspec.yaml` — LOCKED

```yaml
name: fitwiz   # NEVER CHANGE
```

This is the internal Dart package name used by every `import 'package:fitwiz/...'`
statement (~191 imports) and Drift `.g.dart` codegen. Changing it would force a
build_runner regeneration which is forbidden by `mobile/flutter/CLAUDE.md`.
**Pubspec stays `fitwiz` forever, even after rebrand.** This is invisible to users.

---

## Locked identifiers (NEVER change post-launch)

Changing any of these breaks installs, subscriptions, share links, or widget
data on existing user devices.

| Identifier | Current value | Why locked |
|---|---|---|
| Bundle/package ID (Android) | `com.aifitnesscoach.app` | Play Store install continuity. Changing means publishing a new app, asking all users to manually re-install, losing reviews/ratings/subscriptions. |
| Bundle/package ID (iOS) | `com.aifitnesscoach.app` | Same — App Store install continuity. |
| Widget app-group ID | `group.com.aifitnesscoach.widgets` | iOS widget data is namespaced by this. Change = all installed widgets lose their state. |
| Deep link scheme | `fitwiz://` | Millions of share-card / widget / referral links in users' messages would 404. Users don't see the scheme; it's a hidden URL prefix. |
| Pubspec internal name | `fitwiz` | Dart package name. Changing breaks all 255 `import 'package:fitwiz/...'` lines AND all Drift `.g.dart` files which contain auto-generated `import 'package:fitwiz/data/local/...'` references. Regenerating .g.dart requires `dart run build_runner build` which is **forbidden** by `mobile/flutter/CLAUDE.md` (analyzer 7.x crash with Dart 3.11 dot-shorthand AST). See § Pubspec name deep-dive below. |
| RevenueCat product IDs | `fitwiz_yearly`, `fitwiz_premium_yearly`, `fitwiz_yearly_trial` | Hardcoded in RevenueCat dashboard + Play Console subscription products. Renaming requires creating new products + migrating existing subscribers. |
| Method channel names | `com.aifitnesscoach.app/wearable`, `.../widget_actions` | Must match exactly between Dart and native code at registration time. |

The rename script intentionally does NOT touch any of these. They contain
either `aifitnesscoach` (no fitwiz substring) or `fitwiz` lowercase that is
NOT swapped (script does case-sensitive `FitWiz` only).

---

## External services

These are dashboard/console actions that require manual login. The rename
script cannot do these.

### 1. Domain registrar (Namecheap / Cloudflare / etc.)

- Buy `<newname>.com` (or `.app`, `.us`, `.io`, `.fit`)
- Set DNS records:
  - `A` record `@` → `76.76.21.21` (Vercel)
  - `CNAME` record `www` → `cname.vercel-dns.com.`

### 2. Vercel — `https://vercel.com/dashboard`

- Project: `ai-fitness-coach`
- Settings → Domains → Add `<newname>.com`
- Set as **Production** domain
- Remove or move `fitwiz.us` to Preview

### 3. Resend (transactional email) — `https://resend.com/dashboard`

- Domains → Add `<newname>.com`
- Add the SPF + DKIM + DMARC records to your registrar
- Wait for verification (1–4h typically)
- Update `RESEND_FROM_EMAIL` env var on Render to `<NewName> <hello@<newname>.com>`

### 4. Render (backend hosting) — `https://dashboard.render.com`

- Service: `aifitnesscoach-zqi3`
- Environment → update env vars:
  - `RESEND_FROM_EMAIL`
  - `FITWIZ_WEBSITE_URL` (optional, defaults to `https://<newname>.com`)
  - `FITWIZ_MARKETING_DOMAIN` (optional)
  - `FITWIZ_SUPPORT_EMAIL` (optional)
  - `FITWIZ_PRIVACY_EMAIL` (optional)
- Redeploy

### 5. Google Play Console — `https://play.google.com/console`

- Production listing → edit:
  - **App name** (e.g., `<NewName>: Workout & Meal Coach`)
  - **Short description**
  - **Full description**
  - **Website URL** → `https://<newname>.com`
  - **Privacy policy URL** → `https://<newname>.com/privacy`
  - **Support email** → `support@<newname>.com`
- Re-do screenshots if any contain "FitWiz" text
- Re-do feature graphic if it contains the wordmark
- Upload new AAB with updated `app_name` in `strings.xml`
- Submit for review (typically 24–72h)

### 6. Apple App Store Connect — when iOS resumes

- App listing → edit name, subtitle, descriptions, keywords
- Re-do screenshots
- Submit through App Review

### 7. Universal Links / App Links

After domain change:
- `frontend/public/.well-known/assetlinks.json` — Android App Links verification
- `frontend/public/.well-known/apple-app-site-association` — iOS Universal Links

These deploy automatically with Vercel. App Links re-verification by Google
takes days to weeks (silent fallback to browser in interim).

### 8. Sentry — `https://sentry.io`

- Project name: rename for clarity (cosmetic)
- DSN: keep (changing breaks crash reporting)

### 9. Discord / Instagram social handles

- LOCKED — you can't typically change Instagram handle without losing followers
- Buy `instagram.com/<newname>` if available, point old handle there
- Keep Discord invite working (already a permanent invite link)

### 10. RevenueCat dashboard — `https://app.revenuecat.com`

- Project name: rename for clarity (cosmetic)
- **Product IDs**: do NOT rename. They're locked because existing subscribers' subscriptions are tied to the original product IDs.

### 11. Firebase Console (Crashlytics) — `https://console.firebase.google.com`

- Project name: rename for clarity (cosmetic)
- Bundle ID: LOCKED (`com.aifitnesscoach.app`)

### 12. Supabase — `https://supabase.com/dashboard`

- Project name: rename for clarity (cosmetic)
- Database schemas: NO CHANGES (no FitWiz strings stored)

---

## What stays "FitWiz" forever after rename

The rename script handles ~99% of references. The ~1% that stay:

1. **Pubspec name** `fitwiz` (LOCKED — see § Pubspec name deep-dive below)
2. **Dart imports** `package:fitwiz/...` (LOCKED — derived from pubspec, 255 imports across the codebase)
3. **Deep link scheme** `fitwiz://` (LOCKED — preserves user share links)
4. **RevenueCat product IDs** `fitwiz_*` (LOCKED — preserves subscriber data)
5. **Bundle/package IDs** `com.aifitnesscoach.app` — already don't contain "fitwiz"

These are intentional. They're internal stable identifiers that users never see.

---

## Pubspec name deep-dive — why 255 `package:fitwiz/` imports stay

`pubspec.yaml` declares `name: fitwiz`. Every `import 'package:fitwiz/...'`
line in the Flutter codebase resolves through this name. Currently **255
imports** across `mobile/flutter/lib` and `mobile/flutter/test`.

### Why it's locked

If you change `pubspec.yaml`'s `name` field, the cascade is:

| Effect | Severity |
|---|---|
| All 255 `import 'package:fitwiz/...'` lines break | Sed-able in 5 min |
| Every Drift `.g.dart` file under `lib/data/local/` breaks | Each contains internal `import 'package:fitwiz/data/local/...'` references in auto-generated code |
| Sed-fixing the `.g.dart` files works UNTIL someone regenerates them | The next `flutter pub get` or build_runner run wipes the manual edits |
| Regenerating .g.dart requires `dart run build_runner build` | **Explicitly forbidden** by `mobile/flutter/CLAUDE.md`: *"DO NOT run `dart run build_runner build` — analyzer 7.x crash with Dart 3.11 dot-shorthand AST. The 13 `.g.dart` files under `lib/data/local/` MUST stay in git."* |
| Lifting the ban requires upgrading Dart/Flutter version | Major version bump risk for the entire app |

### Why it doesn't matter (visibility)

`package:fitwiz/` imports are **invisible to end users**. They appear only in:

- **Source code** (devs see them in editor)
- **Crashlytics stack traces** (visible only to you in the dashboard, not to users)

Users in the Play Store / App Store see `BRANDING.appName` everywhere, never
the internal Dart package identifier.

### Real-world precedent (Twitter / X)

Twitter rebranded to X in 2023 but kept the Android package name
`com.twitter.android` and the iOS bundle `com.atebits.Tweetie2`. Internal
package identifiers that predate a rebrand stay forever — **changing them
costs more than the visibility benefit**.

### What to tell future devs

After the rebrand, update `mobile/flutter/CLAUDE.md` with one line:

> `fitwiz` is the legacy internal Dart package name from when the app was
> branded FitWiz. Users never see it; it only appears in source imports and
> stack traces. Do NOT attempt to rename — see `REBRANDING.md` for cascade
> analysis. Change is forbidden by the build_runner ban + .g.dart freeze.

### Honest trade-off

| Option | Cost | Risk | Verdict |
|---|---|---|---|
| Keep `fitwiz` pubspec name forever | $0 | None | ✅ Recommended |
| Change pubspec name + sed all imports | 5 min | Breaks .g.dart files; build fails until manually patched | ❌ Not worth it |
| Lift build_runner ban + regen | Days of engineering | Major version-bump risk | ❌ Way out of scope |

The rename script intentionally does not touch `pubspec.yaml` `name:` or any
`package:fitwiz/` imports for these reasons.

---

## Step-by-step rename procedure

### Day 0 — Prep (1–2 hours)

1. **Verify the new name is clean**:
   - USPTO: `https://tmsearch.uspto.gov/` search for `<newname>` in IC 009, IC 041, IC 044
   - Play Store: `https://play.google.com/store/search?q=<newname>&c=apps`
   - App Store: `https://www.apple.com/us/search/<newname>?platform=appstore`
   - Domain availability: Namecheap / Cloudflare for `.com`, `.app`, `.us`, `.io`, `.fit`
   - General web: Google `"<newname>"` (with quotes) — flag any commercial use in fitness/health
2. **Optional**: Pay $300–$500 for Trademarkia/Corsearch attorney clearance opinion
3. **Buy domain** and set DNS records

### Day 1 — Code rename (30 min)

```bash
# At repo root
./scripts/rename_brand.sh "FitWiz" "NewName" "fitwiz.us" "newname.com"

# Verify
cd mobile/flutter && flutter clean && flutter analyze && flutter test
cd ../../backend && python -c "from core import branding; print(branding.APP_NAME)"
cd ../frontend && npm run build

# Commit
cd .. && git add -A && git commit -m "rebrand: FitWiz → NewName"
git push
```

### Day 1 — Infra (1–2 hours)

1. Vercel domain swap
2. Resend domain verify
3. Update Render env vars
4. Wait for Render auto-deploy

### Day 2 — Mobile

1. `cd mobile/flutter && flutter build appbundle`
2. Upload AAB to Play Console
3. Update Play Console listing fields (name, descriptions, screenshots, URLs)
4. Submit for review

### Day 3–5 — Wait for Play review

- Listing review: 24–48h typically
- AAB review: 24–72h typically
- Production-access review (one-time): up to 7 days

### Day 5–7 — Promote to rollout

- Once approved: 20% rollout for 48h, watch Crashlytics + Vitals
- Bump to 50% if clean
- Bump to 100% by day 4 of rollout

---

## Rebrand script reference

`scripts/rename_brand.sh "OldName" "NewName" [OldDomain] [NewDomain]`

**What it does:**
1. Recursively sed-replaces case-sensitive `OldName` → `NewName` across all
   `.py` / `.dart` / `.tsx` / `.ts` / `.kt` / `.kts` / `.gradle` / `.swift` /
   `.html` / `.j2` / `.css` / `.xml` / `.plist` / `.json` / `.yml` / `.md`
   files in: `backend/`, `mobile/flutter/lib`, `mobile/flutter/test`,
   `frontend/src`, `wearos/app/src`, `mobile/flutter/ios`,
   `mobile/flutter/android/app/src`
2. Plus the explicit list of native config files + top-level docs
3. If `[OldDomain]` and `[NewDomain]` are passed, also sed-replaces those

**What it skips (correctly):**
- `node_modules/`, `.venv/`, `__pycache__/`, `build/`, `dist/`, `Pods/`
- `*.g.dart`, `*.freezed.dart` (generated)
- `package-lock.json`, `yarn.lock`, `pubspec.lock`
- `*/migrations/*` (frozen historical artifacts)
- Lowercase `fitwiz` (only swapped if explicit domain is passed) — preserves
  `fitwiz://` deep link scheme, `package:fitwiz/` Dart imports, RevenueCat
  product IDs

---

## Verification commands

After running the rename script, verify with these:

```bash
# Backend loads cleanly
cd backend && python -c "from core import branding; print(f'{branding.APP_NAME} | {branding.SUPPORT_EMAIL} | {branding.OPENAPI_TITLE}')"

# Backend syntax check
cd backend && python -m py_compile $(find . -name "*.py" -not -path "./.venv/*" -not -path "./__pycache__/*" -not -path "./data/*")

# Backend tests
cd backend && pytest tests/ -x

# Frontend builds
cd frontend && npm run build
# Verify HTML metadata resolved:
grep -E "title|og:" dist/index.html

# Flutter analyze (must show same warning count as before)
cd mobile/flutter && flutter clean && flutter analyze

# Flutter tests
cd mobile/flutter && flutter test

# Grep for residual references (excluding locked identifiers)
grep -rn "OldName" backend/ frontend/src/ mobile/flutter/lib/ \
  --include="*.py" --include="*.tsx" --include="*.ts" --include="*.dart" \
  | grep -v "package:fitwiz/" | grep -v "fitwiz://" | grep -v "fitwiz_yearly"
# Should be empty.
```

---

## Cost summary

| Path | Time | Money | Risk |
|---|---|---|---|
| **Stay as FitWiz** | 0 | $0 | ~15% C&D over 5 years (narrow IC 009 conflict, low-enforcement individual owner) |
| **Rebrand via this guide** | ~1 day code + 3–7 days Play review | ~$10–80/yr (domain) + optional $300–1500 attorney | Low if new name is verified clean |

---

## Files created during centralization (Apr 2026)

These are the artifacts that make this rename a one-shot operation:

- `mobile/flutter/lib/core/constants/branding.dart` (NEW)
- `backend/core/branding.py` (NEW)
- `frontend/src/lib/branding.ts` (NEW)
- `scripts/rename_brand.sh` (NEW, executable)
- `frontend/vite.config.ts` (added HTML transform plugin)
- `frontend/index.html` (replaced literals with `%BRAND_*%` placeholders)
- ~130 modified files across Flutter, backend, web that reference these constants instead of literals
- `mobile/flutter/lib/shareables/widgets/app_watermark.dart` (renamed from `fitwiz_watermark.dart`; class `FitWizWatermark` → `AppWatermark`)
- `mobile/flutter/lib/app.dart` (class `FitWizApp` → `AppRoot`)
- `wearos/app/src/main/kotlin/com/aifitnesscoach/wearos/` (renamed from `com/fitwiz/wearos/` to align with locked Android package ID)

---

**Owner:** ChetanG
**Last updated:** 2026-04-26
