# Victor Sariv $0→$100k/mo Formula — Applied to Zealova

Source: indie app developer Victor Sariv ($15k/mo Q1 2025 → $100k/mo Q1 2026, ~7× in under a year). His public formula, mapped to Zealova's current code state. Reviewed 2026-05-06.

---

## Lever 1 — Bright icon + strong screenshots (highest leverage)

**Victor's claim:** Icon + screenshots are the highest-funnel decision. If they don't convert, nothing downstream matters.

**Zealova today:** No documented ASO discipline in repo. No A/B test infrastructure for icon/screenshots in fastlane / Play / App Store Connect.

**Action:**
- [ ] Audit current App Store + Play Store screenshots against top 10 fitness-app competitors (MyFitnessPal, Lose It, Cal AI, Macrofactor, Fitbod, Strong, etc.). Document deltas.
- [ ] Set up App Store Connect Product Page Optimization (3 variants of icon + first 3 screenshots).
- [ ] Set up Play Store Custom Store Listings + Store Listing Experiments (icon + feature graphic + first 2 screenshots).
- [ ] Define one conversion KPI per surface: store-page view → install rate. Target +20% lift per cycle.

---

## Lever 2 — 4–5 step VIDEO onboarding flow doing 75% of revenue

**Victor's claim:** Don't optimize every screen of the app. Optimize the first 90 seconds. Short, video-led, ends in trial-start.

**Zealova today:** `mobile/flutter/lib/screens/onboarding/` contains 22+ screens before paywall:
- welcome_affirmation_screen
- pre_auth_quiz_screen (+ ext, ui, data parts)
- personal_info_screen
- fitness_assessment_screen
- weight_projection_screen (+ ui, data point parts)
- plan_analyzing_screen
- program_summary_screen
- coach_selection_screen (+ ui)
- capability_and_community_screen
- commitment_pact_screen
- trust_and_expectations_screen
- demo_tasks_screen
- founder_note_sheet
- notification_prime_screen
- permissions_primer_screen
- workout_generation_screen
- workout_showcase_screen
- nutrition_showcase_screen

**Action:**
- [ ] Tag each screen: (a) gathers data the AI plan literally cannot generate without, or (b) trust/storytelling beat. Move all (b) screens to post-trial reveals.
- [ ] Target ≤5 screens before paywall hit.
- [ ] Add short looping video (3–5 sec each) to the screens that survive — match Victor's "video onboarding" pattern.
- [ ] Instrument funnel: log per-screen drop-off to backend. Identify the single highest-drop screen and rebuild it.

---

## Lever 3 — 3-day free trial (not 7, not 14)

**Victor's claim:** 3 days reduces fear without giving the user enough time to forget the app before the charge hits.

**Zealova today:** Hard-coded **7-day trial** on both SKUs. References:
- `mobile/flutter/lib/screens/paywall/paywall_pricing_screen.dart:111` (date helper comment)
- `paywall_pricing_screen.dart:113` ("in 7 days")
- `paywall_pricing_screen.dart:304` ('7-day free trial')
- `paywall_pricing_screen.dart:807` ('Free for 7 days. Cancel anytime.')
- `paywall_pricing_screen.dart:997` ('Start your 7-day FREE\\ntrial to continue')
- `paywall_pricing_screen.dart:1491` ('7-day free trial\\nCancel anytime…')
- `paywall_pricing_screen.dart:1545` ('Start with a 7-day free trial…')
- Memory: `project_pricing.md` ("7-day trial both SKUs")

**Action:**
- [ ] Extract trial duration to Remote Config / RevenueCat metadata (single source of truth) so the 7 hard-coded strings can be flipped without a release.
- [ ] Run RevenueCat experiment: 7-day vs 3-day on **trial-start → paid conversion** (not just trial-start rate). 3-day usually wins on net paid conversion.
- [ ] Update `project_pricing.md` memory once a winner is locked.

---

## Lever 4 — Localization (Victor's "easiest growth lever")

**Victor's claim:** Translate keywords, screenshots, and the app itself. Most indie devs ship English-only and leave the rest of the world on the table.

**Zealova today:** No `lib/l10n/` folder, no `.arb` files, no `flutter_localizations` dep. App is English-only.

**Action (cheapest to most expensive):**
- [ ] Phase 1 — Translate **App Store + Play Store metadata** (title, subtitle, keywords, description, screenshot text overlays) into ES, PT-BR, DE, FR, JA. Zero code change. Largest single TAM lift.
- [ ] Phase 2 — Add `flutter_localizations` + `intl`, generate `l10n.yaml` + ARB files. Wrap all hard-coded strings with `AppLocalizations.of(context).key`.
- [ ] Phase 3 — Translate the 4–5 surviving onboarding screens + paywall first (highest revenue surfaces).
- [ ] Phase 4 — Translate full app via professional native speakers (NOT Google Translate — fitness vocabulary needs native nuance).

---

## Lever 5 — Pick one ad channel and master it

**Victor's claim:** Stop spreading thin across 5 platforms. Pick one. Master it. Add a second only after the first plateaus. Victor is still on Google Ads only at $100k/mo.

**Zealova today:** `marketing/` covers LinkedIn + X + Reddit + Instagram (organic + ads) + TikTok. The `social-post-creator` agent encourages parallel research across all of them.

**Action:**
- [ ] Pick ONE primary channel for paid acquisition (Google App Campaigns, Meta App Install Ads, or TikTok Ads). Write the choice into `marketing/CLAUDE.md` so the agent reads it every session.
- [ ] Pick ONE primary channel for organic build-in-public. Likely the platform where the founder's voice + audience already exist.
- [ ] **Updated** `social-post-creator.md` agent (2026-05-06) — added Hard Rule #8 (Primary channel discipline) — agent now defaults to one platform per session and asks before going cross-platform.

---

## Lever 6 — Reinvest aggressively

**Victor's claim:** Started by reinvesting 100% of revenue back into ads. At $100k/mo he still reinvests 40%. Most indie devs hit $10k/mo and start drawing a salary. Don't.

**Zealova today:** No reinvestment policy in repo (out of code scope).

**Action:**
- [ ] Once paid acquisition starts, document a target reinvestment % in founder ops notes.
- [ ] Treat the first 6 months of revenue as ad fuel, not income.

---

## Lever 7 — Lifetime offer (LATE-stage lever, do NOT ship now)

**Victor's nuance — get this right:** His ORIGINAL formula said "no lifetime ever, breaks subscription growth". He removed it for ~a year because it was breaking his **paid ads** (poisoned LTV math + ad attribution). He only re-introduced it after he'd figured out how to "work with it" — meaning his subscription funnel + ad LTV model were already dialed and he could gate lifetime in a position where it doesn't muddle attribution. His updated quote: *"It's fast money and Europeans love it"* — but he earned the right to use it.

**Zealova today:** `SubscriptionTier.lifetime` is plumbed in code (`paywall_pricing_screen_part_accent_border_card.dart:476`, etc.). `project_pricing.md` confirms only $7.99/mo + $59.99/yr are live in the mobile stores. **Lifetime is web-only and undiscoverable from paid-ad funnels** — this is actually the correct gating pattern (it sidesteps Victor's attribution problem because no paid-install ad can attribute a lifetime purchase).

**Status:** Current setup is safe. Keep it this way. Risks to actively avoid:

- [ ] **Never promote lifetime in any paid-ad creative** (Meta / Google / TikTok app-install ads, Google Search ads pointing at the web paywall, etc.). The moment a paid-ad clicker buys lifetime, attribution is poisoned.
- [ ] **Never link to the web lifetime page from the in-app paywall** if that paywall is reachable from a paid-install funnel. Keep lifetime an organic-only path (newsletter, direct site, build-in-public posts, Reddit comments).
- [ ] **Tag lifetime purchases distinctly in RevenueCat** (custom attribute or separate entitlement bucket) so cohort + LTV reports can exclude them when calculating subscription LTV for ad bid optimization.
- [ ] **Don't add a "Lifetime" card to the mobile paywall** even if it feels like an easy upsell — that's the exact mistake Victor made and removed for a year.
- [ ] **Updated** `social-post-creator.md` agent (2026-05-06) — Hard Rule #9 still stands: agent will not draft lifetime-pricing posts that target paid-ad audiences. Lifetime can still appear in organic-only build-in-public posts on the founder's personal channels (where there's no paid attribution overlap).

---

## Bonus — Voice / brand stance

**Victor's pattern:** Quiet family man. No yacht posts. No course pitch. No "escape the 9-to-5" energy. Documents failures publicly. Posts when he's giving up. Posts every loss + every win.

**Action:**
- [ ] Lock founder voice in `marketing/CLAUDE.md`: first-person, vulnerable + tactical, numbers > adjectives, no guru framing, no Lambo. (Already partially documented — reinforce.)
- [ ] Build-in-public posts must include real numbers (testers, conversion %, MRR) OR a real failure — never adjectives only.

---

## What NOT to do (Victor's anti-pattern list, applied)

- ❌ Don't ship lifetime now (Lever 7).
- ❌ Don't add a second ad channel before mastering the first (Lever 5).
- ❌ Don't keep the 22-screen onboarding (Lever 2).
- ❌ Don't ship English-only (Lever 4).
- ❌ Don't pull a salary at $10k MRR (Lever 6).
- ❌ Don't write highlight-reel posts. Post the loss when it happens.

---

**Last updated:** 2026-05-06
**Source video transcript:** Indie app developer interview re: Victor Sariv's public formula
**Agent updates landed:** `.claude/agents/social-post-creator.md` (Hard Rules 8 + 9, Step 3.5 ASO lane, Step 3.6 localization prompt, angle bank in Step 4)
