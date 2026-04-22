<!-- We are transparent about being a premium-only app, and include this in our app images, app description, and website. We also surface this information in-app before the user ever gives us their email. Google Play displays all subscription apps that are not also pay-to-download as free in search, and this is not controlled by us. -->

# FitWiz — Pricing Reference

> **Source of truth:** `docs/pricing/PRICING_ANALYSIS_2026.md` — this file is a quick-reference summary.
> **Last Updated:** 2026-04-21

---

## Current Live Pricing (as of 2026-04-21)

| Plan | Price | Billing | Trial | Status |
|------|-------|---------|-------|--------|
| **Premium Monthly** | $4.99/mo | Monthly | ❌ None | ✅ **Live** |
| **Premium Yearly** | $49.99/yr (~$4.17/mo) | Yearly | ✅ 7 days | ✅ **Live** |

**Not currently sold:** Premium Plus (Ultra), Lifetime, Family, Duo, Free-with-limits — all deferred. See PRICING_ANALYSIS_2026.md for detailed rationale.

---

## Regional Pricing (PPP-Adjusted)

All pricing below is set **per country in App Store Connect + Google Play Console**. Code does NOT need to know these values — stores return localized `priceString` to the app.

### Tier 1 — Full Price (high disposable income)
Countries: US, UK, Canada, Australia, NZ, Ireland, Nordics, Switzerland, Germany, Netherlands, France, Austria, Belgium, Luxembourg

| Market | Monthly | Yearly |
|---|---|---|
| 🇺🇸 US | $4.99 | $49.99 |
| 🇬🇧 UK | £3.99 | £37.99 |
| 🇨🇦 Canada | C$6.99 | C$64.99 |
| 🇦🇺 Australia | A$7.99 | A$74.99 |
| 🇪🇺 EU (Germany/France/NL/etc.) | €4.99 | €49.99 |

### Tier 2 — Southern Europe + Higher APAC
Countries: Italy, Spain, Portugal, Greece, Japan, South Korea, Singapore, Hong Kong, Taiwan, UAE, Saudi Arabia, Israel

| Market | Monthly | Yearly |
|---|---|---|
| 🇮🇹🇪🇸 S. Europe | €4.49 | €44.99 |
| 🇯🇵 Japan | ¥600 | ¥5,800 |
| 🇰🇷 S. Korea | ₩6,500 | ₩64,000 |

### Tier 3 — Emerging Americas + E. Europe
Countries: Mexico, Brazil, Argentina, Chile, Colombia, Peru, Poland, Czech, Hungary, Romania, Turkey

| Market | Monthly | Yearly |
|---|---|---|
| 🇧🇷 Brazil | R$19.99 | R$189 |
| 🇲🇽 Mexico | MX$79 | MX$749 |
| 🇹🇷 Turkey | ₺139 | ₺1,299 |
| 🇦🇷 Argentina | AR$3,499 | AR$32,999 |
| 🇵🇱 Poland | zł 16.99 | zł 159 |

### Tier 4 — India + Asia-Pacific + MENA
Countries: **India**, Indonesia, Philippines, Vietnam, Thailand, Malaysia, Egypt, Morocco, South Africa, Nigeria, Kenya, Pakistan, Bangladesh, Sri Lanka

| Market | Monthly | Yearly |
|---|---|---|
| 🇮🇳 **India** | **₹249** (see note) | **₹1,999** |
| 🇮🇩 Indonesia | Rp 45,000 | Rp 399,000 |
| 🇵🇭 Philippines | ₱149 | ₱1,299 |
| 🇻🇳 Vietnam | 59,000 VND | — |
| 🇹🇭 Thailand | ฿99 | — |
| 🇲🇾 Malaysia | RM 11.99 | — |
| 🇪🇬 Egypt | EGP 99 | — |
| 🇳🇬 Nigeria | ₦3,999 | — |
| 🇿🇦 S. Africa | R49 | R449 |
| 🇵🇰 Pakistan | Rs 799 | — |

### India pricing note
Apple Fitness+ launched in India Dec 15, 2025 at ₹149/mo · ₹999/yr. FitWiz at **₹249** undercuts HealthifyMe Pro (₹599) and Cult.fit (₹999) while differentiating from Apple Fitness+ on AI-coach vs class-library.

---

## Economics Snapshot

### Fixed monthly costs (today's actual bill)
| Service | Cost |
|---|---|
| Render (Standard) | $25 |
| Supabase (Pro) | $25 |
| Resend (Pro) | $20 |
| ChromaDB, Upstash, S3, Firebase | $0 (free/credits) |
| **Total fixed/mo** | **$70** |

### Variable cost per user (Gemini 3 Flash Preview)
| Usage profile | $/user/mo |
|---|---|
| Light | $0.15 |
| **Moderate (default)** | **$0.70** |
| Heavy | $1.50 |
| Max (abuse ceiling) | $4.00 |

### Net profit per user per month (moderate Gemini)
| Price | After 15% store | Net profit |
|---|---|---|
| $4.99 (US monthly) | $4.24 | **$3.54** |
| $49.99/12 (US yearly) | $3.54 | **$2.84** |
| ₹249 (India monthly) | ₹212 ($2.53) | **₹154 ($1.83)** |
| ₹1,999/12 (India yearly) | ₹141 ($1.69) | **₹83 ($0.99)** |

### Breakeven subs to cover $70/mo fixed infra
- **US @ $4.99 (moderate):** ~20 subs
- **India @ ₹249 (moderate):** ~38 subs
- **India @ ₹199 (moderate):** ~53 subs

---

## Future Tiers — Not Currently Sold

All documented in detail in `docs/pricing/PRICING_ANALYSIS_2026.md`. Summary:

| Tier | Planned Price | Status | Launch Prerequisite |
|---|---|---|---|
| **Ultra / Premium Plus** | $9.99/mo · $99.99/yr | Deferred | 500+ Premium subs, 3mo retention data |
| **Lifetime** | $149.99 (web-only) | Deferred | Premium raises to $9.99 first |
| **Family (4 seats)** | $19.99/mo (breakeven) | Deferred | 2,000+ Premium subs; user research confirms demand |
| **Duo (2 seats)** | $9.99/mo (breakeven) | Deferred | Same as Family |
| **Free-with-limits** | $0 | Not recommended | 50K+ MAU + conversion data |

### Family Plan note
**Don't launch.** Fitness isn't a family-plan category (data is personalized per user, can't be shared like music/video). Fitbod, MacroFactor, Hevy, Strong all avoid family SKUs. At $10.99/4-seats you lose 54% of revenue vs 4 individuals. **$19.99/4-seats = breakeven** — only worth launching for pure acquisition leverage, which doesn't apply until you have strong retention data.

**Preferred alternative:** Enable native **Apple Family Sharing** on `premium_monthly` in App Store Connect (zero engineering, family members get Premium access via OS-level Family Sharing). Same outcome, no new SKU.

---

## Competitor Comparison (AI-forward fitness apps, 2026)

| Competitor | Monthly | Annual | AI coach? |
|---|---|---|---|
| **Hevy Pro** | $2.99 | $23.99 | ❌ tracker only |
| **FitWiz (current)** | **$4.99** | **$49.99** | ✅ Gemini + 5-agent swarm |
| **Apple Fitness+** | $9.99 (India: ₹149) | $79.99 (India: ₹999) | ❌ pre-recorded classes |
| **Strong** | $8.33 | $99.99 | ❌ |
| **MacroFactor** | $11.99 | $71.99 | Rule-based nutrition |
| **Fitbod** | $15.99 | $95.99 | Algorithmic (no chat) |
| **Gravl** | $14.99 | $89.99 | Algorithmic |
| **ChatGPT Plus** (for reference) | $20 | — | ✅ generic LLM |
| **Future (human coach)** | $199 | — | Human trainer |

---

## App Store Commission Structure

| Revenue tier | Apple rate | Google rate |
|---|---|---|
| First $1M/year (Small Business Program) | **15%** | **15%** |
| Above $1M/year | 30% | 30% (15% on renewals after year 1) |
| Yearly subscription after year 1 | — | 15% renewal discount |

Small Business status is automatic if prior-year earnings were under $1M.

---

## Paywall Flow

Current flow (see `mobile/flutter/lib/screens/paywall/`):
1. `paywall_features_screen.dart` — features showcase
2. `paywall_timeline_screen.dart` — trial/subscription timeline (yearly only today)
3. `paywall_pricing_screen.dart` — 2-column monthly vs yearly
4. `hard_paywall_screen.dart` — no-dismiss paywall for re-engagement

Pricing display uses `pkg.storeProduct.priceString` (localized automatically by user's device/store). No hardcoded USD values in production paywall.

---

## Next Steps to Earn Revenue Faster

Ranked by ROI (per PRICING_ANALYSIS_2026.md):
1. **Set India PPP pricing (₹249/₹1,999)** — free revenue lift from an untapped market
2. **Set Tier 3/4 PPP pricing** in Play Console + App Store Connect (15 countries)
3. **Add 7-day trial to monthly plan** — today only yearly has a trial
4. **Annual upsell popup at day 30** — converts month-2 churners
5. **Referral program** — "Invite a friend, both get 1 month free" (mimics family-plan virality, no revenue cannibalization)
6. **Enable Apple/Google Family Sharing toggle** — free family perk, no new SKU
7. **A/B test raising US to $6.99-7.99** — only after 3 months of retention data

---

## Files That Source Pricing

- **Live prices:** App Store Connect + Google Play Console (per-country overrides)
- **Paywall display:** `mobile/flutter/lib/screens/paywall/paywall_pricing_screen.dart:74` uses `storeProduct.priceString`
- **RevenueCat:** Offerings map products to paywall packages (does not set prices)
- **Fallback (dead code):** `mobile/flutter/lib/core/providers/subscription_provider.dart:718-731` — USD-only, not rendered in production
- **Product IDs:** `subscription_provider.dart:225-234` — `premium_monthly`, `premium_yearly`; `premium_plus_*` exist but unused
- **Backend:** `backend/api/v1/subscriptions/lifetime.py:206` — backend default is still $99.99 (update if lifetime launches at new price)

---

## Historical Notes

- **Dec 2024:** Original PRICING.md wrote $5.99/$9.99/$79.99 + $99.99 lifetime — never shipped at those prices.
- **Apr 16, 2026:** Launch decision — Premium-only at $4.99/$49.99. No Ultra, no Lifetime, no Family, no Free tier.
- **Apr 21, 2026:** This refresh — added India PPP (₹249), Apple Fitness+ India competitive context, Family Plan deferral rationale.

*Source of truth for all rationale: `docs/pricing/PRICING_ANALYSIS_2026.md`*
