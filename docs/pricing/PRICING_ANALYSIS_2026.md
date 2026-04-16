# FitWiz Pricing Analysis — Is $4.99/mo Too Low?

*Created: 2026-04-15*
*Status: Decision memo — awaiting pricing call*

---

## TL;DR

**Yes, $4.99/mo is almost certainly underpriced.** It positions FitWiz below every AI-forward fitness competitor ($7.99–$15.99/mo) while FitWiz ships **more** AI features than any of them (conversational coach, Gemini workout gen, food vision, form video analysis, injury-aware plans). A $4.99 price signals "cheap tracker," not "premium AI coach," and caps LTV well below what the feature surface can support.

**Recommended action:** Raise monthly to **$9.99** and yearly to **$59.99–$69.99** (≈$5/mo effective). Keep a legacy-price grandfather for existing subscribers. Run a 2-week A/B at the new price before committing.

---

## Current State (source of truth)

Values read from code, not docs — the root `/PRICING.md` is stale (Dec 2024).

| Field | Value | Source |
|---|---|---|
| Premium monthly | **$4.99** | `mobile/flutter/lib/core/providers/subscription_provider.dart:720` |
| Premium yearly | **$49.99** (~$4.17/mo effective, 16% off) | `subscription_provider.dart:725` |
| Free trial | 7 days (yearly only) | `subscription_provider.dart:729` |
| Lifetime plan | Not currently sold in-app | — |
| Premium Plus tier | Not currently sold in-app | — |

Docs that reference $5.99 / $9.99 / $79.99 / lifetime tiers (`/PRICING.md`, `/SUBSCRIPTION_TIER_GUIDE.md`, `research/COMPETITIVE_ANALYSIS.md`) are **aspirational / outdated**, not what users see today.

---

## Competitor Pricing (AI-forward / AI-adjacent, 2026)

Pulled from `research/COMPETITIVE_ANALYSIS.md` and current app-store listings.

| Competitor | Monthly | Annual | Eff. $/mo on annual | AI coach? |
|---|---|---|---|---|
| **Fitbod** | $15.99 | $95.99 | $8.00 | Algorithmic, no chat |
| **Gravl** | ~$14.99 | ~$89.99 | $7.50 | Algorithmic |
| **MacroFactor** | $11.99 | $71.99 | $6.00 | Rule-based nutrition |
| **Future** (human coach) | $199 | — | — | Human trainer |
| **Strong** | ~$8.33 | ~$99.99 | $8.33 | ❌ tracker only |
| **Hevy Pro** | $2.99 | $23.99 | $2.00 | ❌ tracker only |
| **FitWiz (current)** | **$4.99** | **$49.99** | **$4.17** | ✅ Full Gemini LLM + 5-agent swarm |

**Observation:** FitWiz is priced in the **tracker tier** (Hevy/Strong range) while shipping a feature set that exceeds Fitbod and MacroFactor. The only app cheaper per month is Hevy, which has no AI and no nutrition.

---

## Why $4.99 Is Likely Too Low

### 1. Price signals quality
A $4.99 monthly price anchors users to "basic tracker." When a prospect comparison-shops between Fitbod at $15.99 and FitWiz at $4.99, the cheaper option reads as **inferior**, not as a bargain — especially in a category where people associate cost with efficacy (trainers, supplements, gyms).

### 2. Unit economics leave money on the table
From the existing cost model (`/PRICING.md:129-138`):

| Price point | After 15% store cut | Variable cost/user | **Net profit/user/mo** |
|---|---|---|---|
| $4.99 | $4.24 | ~$0.15 | **$4.09** |
| $9.99 | $8.49 | ~$0.20 | **$8.29** (+103%) |
| $12.99 | $11.04 | ~$0.25 | **$10.79** (+164%) |

At average fitness-app retention of 6–8 months, moving from $4.99 → $9.99 roughly **doubles LTV** with minimal cost delta. The LLM/vision infra cost doesn't scale linearly with price — you capture almost all the upside.

### 3. Conversion elasticity in this category is weak
Published data from Revenuecat's 2024 State of Subscription Apps report (health & fitness category):
- Median monthly: **$9.99**
- Median annual: **$59.99**
- Trial → paid conversion rate is **roughly flat** between $4.99 and $9.99; it drops meaningfully above $14.99.

Translation: you probably don't lose many conversions doubling the price, because the people who pay are buying **outcomes** (stronger, leaner) and a $5 delta is noise next to a gym membership ($30–$80/mo) or a trainer ($50+/session).

### 4. You can't discount into premium
Lifetime plans, Premium Plus tiers, and referral upgrades all get **more valuable** when anchored against a higher base price. Launching a $99 lifetime looks great next to $9.99/mo (10 months breakeven); next to $4.99/mo it takes 20 months to pencil out and reads as a weak deal.

### 5. You're training users that AI is cheap
Gemini, OpenAI, and ChatGPT Plus all sit at $20/mo. If FitWiz's differentiator is "conversational AI coach," pricing below ChatGPT implies the coach is a lesser experience. Raise price → defend the AI narrative.

---

## Counter-arguments (when $4.99 makes sense)

Honest cases for keeping the current price:

1. **Land-grab phase.** If the top goal is installs/MAU for a fundraise or an acquisition narrative, low price + high conversion rate is a valid playbook. RC can show 2–3× higher paid conversion vs. $9.99.
2. **Review velocity matters more than ARPU.** Lower price = faster trust, more reviews, better ASO ranking. If you're at <500 paying users, the flywheel value of reviews may outweigh ARPU.
3. **International PPP.** $4.99 is near the sweet spot for India/LatAm/SE Asia. If those markets are strategic, regional pricing beats a global raise. (RevenueCat supports regional price tiers — use them.)
4. **Churn is unknown.** Without 3+ months of cohort retention data, raising prices can mask a product-market-fit problem. If D30 retention is <20%, fix retention first.

---

## Recommendation

### Phase 1 (next 2 weeks) — measure before moving
- Pull from RevenueCat: trial-start → paid conversion, D1/D7/D30 retention, ARPU, refund rate.
- Confirm: is $4.99 currently underconverting (meaning price isn't the problem) or overconverting with high churn (meaning price is too low)?

### Phase 2 (price test) — A/B at checkout
Run a 14-day RevenueCat Offerings experiment:
- **Control:** $4.99 / $49.99
- **Variant A:** $9.99 / $59.99 (+7-day trial on monthly too)
- **Variant B:** $7.99 / $59.99 (compromise)

Pass/fail metric: **trial-start revenue per visitor** at 14 days (not conversion rate alone). If Variant A wins or ties Control on revenue-per-visitor, ship it.

### Phase 3 (if test wins) — roll out with grandfathering
- New installs → new price.
- Existing subscribers → keep legacy $4.99 (RevenueCat handles this automatically on plan changes; just don't migrate SKUs).
- Announce via email with the FitWiz voice (not Coach persona — per notification feedback guidance).

### Phase 4 (later) — reintroduce tier structure
Once a stable paid base exists at $9.99, reintroduce the Premium Plus tier at $14.99 gated on the highest-leverage unlimited features (video form checks, unlimited AI generations, unlimited food photo scans). The root `/PRICING.md` already has a full feature gating matrix for this — just update the dollar amounts.

---

## Decisions Needed From You

1. Is the goal for the next 90 days **ARPU** or **installs**? Determines whether to raise price now or run the land-grab longer.
2. Is international PPP a priority? If yes, price by region instead of globally raising.
3. Are current retention numbers (D30, month-2) good enough to blame price for low LTV? If you don't know, the first action is not a price change — it's pulling the cohort data.

---

## Cost & Profit Model — $4.99 vs $9.99

### 1. Fixed costs (today's actual bill)

| Service | Cost |
|---|---|
| Render (Standard) | $25 |
| Supabase (Pro) | $25 |
| Resend (Pro) | $20 |
| ChromaDB, Upstash, S3, Firebase | $0 (free / credits) |
| **Total fixed/mo** | **$70** |

### 1b. Store commissions (what Apple/Google take)

These come **off the top of every subscription** before you see a dollar.

| Revenue level | Apple rate | Google rate | Your share |
|---|---|---|---|
| First $1M/year (Small Business Program) | **15%** | **15%** | **85%** |
| Above $1M/year | **30%** | **30%** (15% on renewals) | **70–85%** |
| Yearly subscription after year 1 (both stores) | — | **15%** (renewal discount) | 85% |

**Example at $4.99/mo:**
- User pays: $4.99
- Store takes 15%: –$0.75
- You receive: **$4.24**

**Example at $9.99/mo:**
- User pays: $9.99
- Store takes 15%: –$1.50
- You receive: **$8.49**

This is already baked into every "After Store" column in the profit tables below. Small Business status is automatic if your prior-year earnings were under $1M.

### 2. Gemini cost per user

**Gemini 3 Flash Preview:** $0.50/1M input, $3.00/1M output

| User type | Profile | **Gemini/mo** |
|---|---|---|
| Light | Casual logger, rare chat | **$0.15** |
| Moderate (model default) | 50 chats, 30 photos, 4 workouts | **$0.70** |
| Heavy | Daily power user | **$1.50** |
| **Max** | **Abuse ceiling — 300 chats, 200 photos** | **$4.00** |

### 3. Profit at $4.99 vs $9.99 (moderate use, $0.70/user variable)

| Users | Fixed | Variable | $4.99 profit/mo | $9.99 profit/mo |
|---|---|---|---|---|
| 10 | $70 | $7 | **–$35** | **+$8** |
| 100 | $70 | $70 | **+$284** | **+$709** |
| 1,000 | $70 | $700 | **+$3,422** | **+$7,622** |
| 10,000 | $299 | $7,000 | **+$34,617** | **+$61,632** |
| 100,000 | $3,698 | $70,000 | **+$270,612** | **+$615,612** |

*Assumes 15% store cut (30% above $1M/yr), 1% RevenueCat above $2.5K MTR. 100% paying subscribers.*

### 4. Worst-case — if all users are heavy ($1.50/user variable)

| Users | $4.99 profit/mo | $9.99 profit/mo |
|---|---|---|
| 10 | **–$43** | **$0** |
| 100 | **+$204** | **+$629** |
| 1,000 | **+$2,622** | **+$6,822** |
| 10,000 | **+$26,617** | **+$53,632** |

### 4b. With prompt caching re-enabled at scale (~30% Gemini savings)

Only re-enable caching once you hit ~500+ daily-active paying users — below that, storage fees eat the savings. At moderate use, caching drops variable from $0.70 → **$0.50/user**.

| Users | $4.99 profit/mo (no cache) | $4.99 profit/mo (with cache) | $9.99 profit/mo (with cache) |
|---|---|---|---|
| 1,000 | +$3,422 | **+$3,622** (+$200) | **+$7,822** (+$200) |
| 10,000 | +$34,617 | **+$36,617** (+$2,000) | **+$63,632** (+$2,000) |
| 100,000 | +$270,612 | **+$290,612** (+$20K) | **+$635,612** (+$20K) |

Caching is a **scale optimization**, not a launch lever. Net worth of caching = ~$240K/year once you hit 100K users.

### 5. Break-even

| Price | Moderate use | Heavy use | Max use |
|---|---|---|---|
| $4.99 | **20 users** | 26 users | **292 users** ⚠ |
| $9.99 | **9 users** | 10 users | 16 users |

### 6. Marketing costs (new founder primer)

Marketing isn't in the cost model above because it's **discretionary** — you spend as much or as little as you want. But to make money, you need to spend something.

#### The core equation: LTV > CAC

- **LTV** (lifetime value) = what an average user pays you before churning
- **CAC** (customer acquisition cost) = what you spent to get that user
- If LTV > CAC, you're profitable. If not, you're lighting money on fire.

#### Your LTV today

Fitness apps average **6 months retention**.

| Price | Monthly net (after 15% + $0.70 var) | 6-mo LTV |
|---|---|---|
| $4.99 | $3.54 | **$21** |
| $9.99 | $7.79 | **$47** |

That $21 is your ceiling — every dollar you spend acquiring a paying user at $4.99 above $21 is a loss.

#### Marketing channels (cheapest → most expensive)

| Channel | Cost | What you get | Fit for you |
|---|---|---|---|
| **Organic TikTok / Reels / Shorts** | **$0** (your time) | Viral reach if content hits | ⭐ Start here. Fitness content thrives. |
| **Reddit (r/fitness, r/gainit, etc.)** | $0 | Niche, high-trust | ⭐ Post honestly, not spammy |
| **Product Hunt launch** | $0 | One-shot burst (500–5K visits) | ⭐ Use when v1 is polished |
| **ASO (App Store Optimization)** | $0–50/mo tools | Long-term discoverability | Essential |
| **Referral program** | 1 free month / referral | Viral coefficient | Build in RevenueCat |
| **Micro-influencers (5K–50K followers)** | $50–500/post | Targeted audience | Fitness creators love AI tools |
| **Mid influencers (100K+)** | $1K–5K/post | Bigger reach, variable quality | Wait until you have revenue |
| **Meta / TikTok ads** | $2–6 per install | Scalable but needs $$ to test | **Skip at $4.99** — math doesn't work |
| **Google UAC (App campaigns)** | $3–8 per install | Intent-driven, higher converting | Same problem |

#### Why paid ads don't work at $4.99

Fitness app install → paid conversion: industry avg **3–8%** (call it 5%).

| Cost per install (CPI) | 5% convert to paid | Cost per paying user (CAC) | Profitable at $4.99? |
|---|---|---|---|
| $3 | 1 in 20 | **$60** CAC | ❌ LTV $21, you lose $39 |
| $5 | 1 in 20 | **$100** CAC | ❌ LTV $21, you lose $79 |
| $3 | 1 in 20 | **$60** CAC at $9.99 | ❌ LTV $47, still lose $13 |
| $5 | 1 in 20 | **$100** CAC at $9.99 | ❌ Still negative |

**Paid ads only work if:**
- Your conversion is >10% (strong paywall + onboarding), OR
- Your retention is >12 months (far above fitness average), OR
- You're at $9.99+ AND annual uptake is high (yearly subscribers 3x LTV)

#### Realistic marketing budget by stage

| Stage | Monthly budget | Where it goes |
|---|---|---|
| **Pre-launch (now)** | $0–100 | Design assets, beta tester incentives, 1 ASO tool |
| **Launch month** | $200–1,000 | Product Hunt prep, 2–3 micro-influencer posts, ASO |
| **Months 1–3 post-launch** | $0–500 | Double down on whatever organic channel worked |
| **Months 4–6** | $500–2,000 | Small paid test ($20/day on Meta for learning) |
| **Months 6–12 (if PMF)** | $2,000–10,000 | Scale the paid channels that pencil |

#### Your marketing priorities as a new founder

1. **Build in public on X / TikTok** — free, compounds, humanizes the app
2. **Get 100 organic users** before spending on ads — if you can't convert organic traffic, paid traffic won't save you
3. **Launch on Product Hunt** when v1 is solid (one-shot shot of 1–5K visitors)
4. **Target micro-influencers in your niche** — $100/post to a 20K-follower fitness creator often beats $1K on Meta
5. **Add a referral program** — RevenueCat supports this natively; lets paying users bring friends for a free month

#### Marketing cost in the profit model

Add it as a **line item you choose**:

| Marketing spend/mo | Effect on profit at 1,000 users, $4.99 |
|---|---|
| $0 (organic only) | +$3,422 profit |
| $500 | +$2,922 |
| $2,000 | +$1,422 |
| $5,000 | –$1,578 ⚠ |

At $4.99, you can afford **~$3K/mo** in marketing at 1K users. At $9.99, you can afford **~$7K/mo** — another reason higher price unlocks growth channels.

---

### Bottom line

- **$9.99 earns ~2× the profit of $4.99** at every scale (1k users = +$50K/yr, 10k = +$324K/yr).
- **$4.99 is fragile** — if users skew heavy or hit the Max tier, margins crater (-69% at 10 users, 38% at 100k).
- **$9.99 stays profitable** across all usage profiles above 100 users.
- Fixed costs are small ($70/mo today) — Gemini is the variable that matters.

---

## Appendix: Files to update if price changes

- `mobile/flutter/lib/core/providers/subscription_provider.dart:719-731` — `ProductPricing.products` fallback map
- RevenueCat dashboard — Offerings + pricing phases (source of truth for live price)
- App Store Connect + Google Play Console — product SKU prices
- `/PRICING.md` (root) — refresh to match reality (currently shows $5.99/$9.99 — misleading)
- `/SUBSCRIPTION_TIER_GUIDE.md` — same
- `research/COMPETITIVE_ANALYSIS.md:91-93` — update "Your App" row
- Paywall copy in `mobile/flutter/lib/screens/paywall/paywall_pricing_screen.dart`
