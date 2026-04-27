# Zealova Pricing Analysis — Is $4.99/mo Too Low?

*Created: 2026-04-15*
*Status: Decision memo — awaiting pricing call*

---

## TL;DR

**Yes, $4.99/mo is almost certainly underpriced.** It positions Zealova below every AI-forward fitness competitor ($7.99–$15.99/mo) while Zealova ships **more** AI features than any of them (conversational coach, Gemini workout gen, food vision, form video analysis, injury-aware plans). A $4.99 price signals "cheap tracker," not "premium AI coach," and caps LTV well below what the feature surface can support.

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
| **Zealova (current)** | **$4.99** | **$49.99** | **$4.17** | ✅ Full Gemini LLM + 5-agent swarm |

**Observation:** Zealova is priced in the **tracker tier** (Hevy/Strong range) while shipping a feature set that exceeds Fitbod and MacroFactor. The only app cheaper per month is Hevy, which has no AI and no nutrition.

---

## Why $4.99 Is Likely Too Low

### 1. Price signals quality
A $4.99 monthly price anchors users to "basic tracker." When a prospect comparison-shops between Fitbod at $15.99 and Zealova at $4.99, the cheaper option reads as **inferior**, not as a bargain — especially in a category where people associate cost with efficacy (trainers, supplements, gyms).

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
Gemini, OpenAI, and ChatGPT Plus all sit at $20/mo. If Zealova's differentiator is "conversational AI coach," pricing below ChatGPT implies the coach is a lesser experience. Raise price → defend the AI narrative.

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
- Announce via email with the Zealova voice (not Coach persona — per notification feedback guidance).

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

## Launch Decision (2026-04-16)

**Going to market with Premium only at $4.99/mo · $49.99/yr.**

- No free tier with usage limits (paywall-or-leave, as today).
- No Ultra / Premium Plus tier at launch.
- No Lifetime plan at launch.

Rationale: ship the simplest paywall possible, gather 2–3 months of cohort data (D1/D7/D30 retention, trial→paid, ARPU), then layer tiers on top once we know which features drive stickiness and have real marginal cost. Additional tiers below are **documented but not sold** — this section grows as tiers are added.

---

## Regional Pricing Matrix (PPP-Adjusted)

### Philosophy
- **Code is currency-agnostic.** Paywall uses `pkg.storeProduct.priceString` — each store returns the localized price for the user's country automatically.
- **All regional prices are set per country in App Store Connect + Google Play Console**, not in Dart code. `ProductPricing.products` map is dead fallback code (zero grep references).
- **Tiers are grouped by purchasing power, not geography.** A country lands in Tier N based on local disposable income + competitor pricing, not continent.

### Tier 1 — Full Price (high disposable income)
**Countries:** US, UK, Canada, Australia, NZ, Ireland, Nordics (Norway/Sweden/Denmark/Finland), Switzerland, Germany, Netherlands, France, Austria, Belgium, Luxembourg

| Market | Monthly | Yearly | USD equiv (monthly) |
|---|---|---|---|
| 🇺🇸 US | $4.99 | $49.99 | $4.99 |
| 🇬🇧 UK | £3.99 | £37.99 | ~$5.00 |
| 🇨🇦 Canada | C$6.99 | C$64.99 | ~$5.00 |
| 🇦🇺 Australia | A$7.99 | A$74.99 | ~$5.20 |
| 🇳🇿 New Zealand | NZ$7.99 | NZ$74.99 | ~$4.80 |
| 🇪🇺 EU (Germany/France/NL/Austria/Belgium/Lux/Ireland) | €4.99 | €49.99 | ~$5.35 |
| 🇨🇭 Switzerland | CHF 4.90 | CHF 49.00 | ~$5.55 |
| 🇳🇴 Norway | NOK 55 | NOK 549 | ~$5.20 |
| 🇸🇪 Sweden | SEK 59 | SEK 579 | ~$5.60 |
| 🇩🇰 Denmark | DKK 37 | DKK 369 | ~$5.40 |
| 🇫🇮 Finland | €4.99 | €49.99 | ~$5.35 |

### Tier 2 — Southern Europe + Higher APAC
**Countries:** Italy, Spain, Portugal, Greece, Japan, South Korea, Singapore, Hong Kong, Taiwan, UAE, Saudi Arabia, Israel

| Market | Monthly | Yearly | USD equiv (monthly) |
|---|---|---|---|
| 🇮🇹 Italy | €4.49 | €44.99 | ~$4.80 |
| 🇪🇸 Spain | €4.49 | €44.99 | ~$4.80 |
| 🇵🇹 Portugal | €4.49 | €44.99 | ~$4.80 |
| 🇬🇷 Greece | €4.49 | €44.99 | ~$4.80 |
| 🇯🇵 Japan | ¥600 | ¥5,800 | ~$4.00 |
| 🇰🇷 S. Korea | ₩6,500 | ₩64,000 | ~$4.80 |
| 🇸🇬 Singapore | S$6.49 | S$64.99 | ~$4.85 |
| 🇭🇰 Hong Kong | HK$35 | HK$349 | ~$4.50 |
| 🇹🇼 Taiwan | NT$149 | NT$1,499 | ~$4.70 |
| 🇦🇪 UAE | AED 17.99 | AED 179.99 | ~$4.90 |
| 🇸🇦 Saudi Arabia | SAR 17.99 | SAR 179.99 | ~$4.80 |
| 🇮🇱 Israel | ₪17.99 | ₪179.99 | ~$4.90 |

### Tier 3 — Emerging Americas + E. Europe
**Countries:** Mexico, Brazil, Argentina, Chile, Colombia, Peru, Poland, Czech, Hungary, Romania, Croatia, Bulgaria, Turkey

| Market | Monthly | Yearly | USD equiv (monthly) |
|---|---|---|---|
| 🇲🇽 Mexico | MX$79 | MX$749 | ~$4.00 |
| 🇧🇷 Brazil | R$19.99 | R$189 | ~$4.00 |
| 🇦🇷 Argentina | AR$3,499 | AR$32,999 | ~$3.50 |
| 🇨🇱 Chile | CLP 3,900 | CLP 36,999 | ~$4.10 |
| 🇨🇴 Colombia | COP 17,900 | COP 169,900 | ~$4.20 |
| 🇵🇪 Peru | PEN 14.99 | PEN 139.99 | ~$4.00 |
| 🇵🇱 Poland | zł 16.99 | zł 159 | ~$4.10 |
| 🇨🇿 Czech Republic | Kč 99 | Kč 949 | ~$4.20 |
| 🇭🇺 Hungary | Ft 1,490 | Ft 13,990 | ~$4.00 |
| 🇷🇴 Romania | lei 19.99 | lei 189 | ~$4.30 |
| 🇭🇷 Croatia | kn 29 | kn 279 | ~$4.10 |
| 🇧🇬 Bulgaria | лв 7.99 | лв 74.99 | ~$4.30 |
| 🇹🇷 Turkey | ₺139 | ₺1,299 | ~$3.40 (frequent inflation resets) |

### Tier 4 — India + Asia-Pacific + MENA + Africa
**Countries:** India, Indonesia, Philippines, Vietnam, Thailand, Malaysia, Egypt, Morocco, South Africa, Nigeria, Kenya, Pakistan, Bangladesh, Sri Lanka

| Market | Monthly | Yearly | USD equiv (monthly) |
|---|---|---|---|
| 🇮🇳 **India** | **₹249** | **₹1,999** | **~$3.00** |
| 🇮🇩 Indonesia | Rp 45,000 | Rp 399,000 | ~$2.85 |
| 🇵🇭 Philippines | ₱149 | ₱1,299 | ~$2.70 |
| 🇻🇳 Vietnam | 59,000 VND | 499,000 VND | ~$2.40 |
| 🇹🇭 Thailand | ฿99 | ฿899 | ~$2.85 |
| 🇲🇾 Malaysia | RM 11.99 | RM 109 | ~$2.75 |
| 🇪🇬 Egypt | EGP 99 | EGP 899 | ~$2.00 |
| 🇲🇦 Morocco | MAD 29 | MAD 279 | ~$2.90 |
| 🇿🇦 S. Africa | R49 | R449 | ~$2.65 |
| 🇳🇬 Nigeria | ₦3,999 | ₦35,999 | ~$2.60 |
| 🇰🇪 Kenya | KES 299 | KES 2,699 | ~$2.30 |
| 🇵🇰 Pakistan | Rs 799 | Rs 6,999 | ~$2.85 |
| 🇧🇩 Bangladesh | ৳299 | ৳2,699 | ~$2.70 |
| 🇱🇰 Sri Lanka | Rs 799 | Rs 6,999 | ~$2.60 |

### India pricing — special competitive note (post-Dec 2025)
**Apple Fitness+ launched in India Dec 15, 2025 at ₹149/mo · ₹999/yr.**

Zealova at ₹249 is positioned as:
- **2× Apple Fitness+** (~₹100 premium) — justified by AI-coach differentiator (Apple is class-library only, no AI chat, no food logging, no injury-aware planning, no Android)
- **Under 50% of HealthifyMe Pro** (₹599) — closest AI-adjacent rival
- **25% of Cult.fit Live** (₹999)
- **Stays under ₹250 psychological threshold** (similar to "under $5" in US)

**Alternative considered: ₹199.** Rejected because:
- ₹249 generates 39% more profit/user on moderate Gemini use ($1.83 vs $1.32)
- Conversion diff between ₹199 and ₹249 is negligible (both well below HealthifyMe ₹599)
- ₹199 leaves thin margins on heavy users ($0.52/user/mo); ₹249 gives ~2× headroom ($1.04/user/mo)

**Alternative considered: matching Apple at ₹149.** Rejected because:
- Net after store cut + Gemini = $0.82/user/mo — one abuse user wipes out 5 moderate users
- User cannot win on price vs Apple brand trust in India; must win on differentiation (AI)
- ₹149 signals "me-too cheap class app" when Zealova is a different product category (AI coach vs. class library)

### Per-country breakeven math (fixed infra = $70/mo)
How many subs to cover **all fixed infrastructure**, assuming moderate Gemini use:

| Market | Net/user/mo | Subs to cover $70 |
|---|---|---|
| 🇺🇸 US @ $4.99 | $3.54 | **20 subs** |
| 🇬🇧 UK @ £3.99 | ~$3.55 | **20 subs** |
| 🇪🇺 EU @ €4.99 | ~$3.85 | **19 subs** |
| 🇦🇺 Australia @ A$7.99 | ~$3.72 | **19 subs** |
| 🇯🇵 Japan @ ¥600 | ~$2.70 | 26 subs |
| 🇧🇷 Brazil @ R$19.99 | ~$2.70 | 26 subs |
| 🇲🇽 Mexico @ MX$79 | ~$2.70 | 26 subs |
| 🇮🇳 India @ ₹249 | $1.83 | 38 subs |
| 🇮🇩 Indonesia @ Rp 45k | ~$1.70 | 42 subs |
| 🇳🇬 Nigeria @ ₦3,999 | ~$1.50 | 47 subs |

Since US/EU/UK/AU already cover fixed costs at ~20 subs, **all Tier 3/4 revenue is essentially pure marginal profit** once you have a modest Tier 1 base.

### App Store tier mapping (for implementation)
Both stores use **price tiers** (not custom prices). The stores round to the nearest available tier — if exact value isn't available, pick closest below target:

| Target USD | Apple tier | Google Play tier |
|---|---|---|
| $4.99 | Tier 5 | $4.99 |
| $3.99 | Tier 4 | $3.99 |
| $2.99 | Tier 3 | $2.99 |
| ₹299 (India) | Tier 59 | ₹299 |
| ₹249 (India) | Tier 49 | ₹249 |
| ₹149 (India) | Tier 29 | ₹149 |

When entering India price in App Store Connect, pick the tier closest to ₹249. If only ₹199 or ₹299 available, default to ₹299 — India Apple Fitness+ is at the ₹149 tier, so ₹299 still creates clean separation.

### Rollout sequence
1. **Today:** Set Tier 4 (India + top 5 emerging markets) in both stores — highest revenue lift, easiest setup
2. **This week:** Set Tier 3 (LatAm + E. Europe + Turkey)
3. **Next week:** Set Tier 2 (S. Europe, Japan, Korea, Singapore)
4. **Tier 1 is default** — no per-country override needed

### Verification
- Set Apple device country to India → paywall should show **₹249**
- Set to US → **$4.99**
- Set to UK → **£3.99**
- RevenueCat dashboard → Customer → Country Override → check each tier loads correct localized `priceString`
- Supabase `subscription_history.price` logs native currency + `currency` ISO code (not converted to USD server-side)

---

## Future Tier: Ultra (Premium Plus) — Planned, Not Launched

### Status
- **Not sold today.** Schema and entitlements already exist in code:
  - `SubscriptionTier.premiumPlus` enum value at `subscription_provider.dart:16`
  - Product IDs: `premium_plus_monthly`, `premium_plus_yearly` at `subscription_provider.dart:228-229`
  - Entitlement key: `premium_plus` at `subscription_provider.dart:234`
  - Tier checks: `isPremiumPlusOrHigher` at `subscription_provider.dart:119`
- "Formerly ultra" comment on line 16 — the tier was renamed Premium Plus in code; for marketing we can still call it **Ultra**. Pick one name before paywall copy goes live.

### Recommended pricing (when launched)

| Price point | Monthly | Yearly | vs. Premium ($4.99/$49.99) | Rationale |
|---|---|---|---|---|
| **Primary** | **$9.99** | **$99.99** | 2× | Industry norm (Notion, Spotify Family). Clean ladder. |
| Alternative | $12.99 | $129.99 | 2.6× | If feature gap is large (custom voices, priority Gemini 3 Pro) |
| Aggressive-close | $7.99 | $79.99 | 1.6× | Works only if Premium becomes **capped** (usage limits) and Ultra is **unlimited** — i.e., the gap is "capped vs unlimited," not "$3 more" |

**Default recommendation: $9.99/mo · $99.99/yr.** Revisit if the doc's Phase 2 A/B moves Premium to $9.99 — Ultra would then shift to $14.99+.

### Feature gating (proposed)

Only gate features with **real marginal cost** or that unlock outcomes Premium can't. Don't gate on vanity.

| Feature | Premium ($4.99) | Ultra ($9.99) | Why gate |
|---|---|---|---|
| AI coach chat | ✅ Unlimited | ✅ Unlimited | Core to the product; don't cap |
| Workout generation | ✅ 4/mo | ✅ Unlimited | Gemini cost + anchors value |
| Food photo scans | ✅ 30/mo | ✅ Unlimited | Vision API cost is real |
| Video form analysis | ❌ | ✅ Unlimited | Highest-cost feature (keyframe extraction + vision) |
| Gemini model tier | Flash | **Pro** | Better reasoning for plans, costs ~6× more |
| Custom coach voices | ❌ | ✅ | Persona differentiation |
| Offline Gemma AI model | ✅ | ✅ | Shipped; no cost to gate |
| Batch cooking flows | ✅ | ✅ | Core nutrition |
| Priority support | ❌ | ✅ | Cheap to offer at low volume |

Rule of thumb: **if it costs us Gemini tokens, it's a gating candidate.** If it's just UI, it belongs in Premium.

### Launch prerequisites

Don't turn on Ultra until:
- [ ] Premium has ≥500 paying subscribers (need a real base to upsell from)
- [ ] 3+ months of D30 retention data proves PMF at $4.99
- [ ] At least 3 Ultra-only features are built and QA'd (video form, unlimited photos, Pro model routing)
- [ ] Paywall copy rewritten as a 3-column comparison (today it's 2-column)
- [ ] RevenueCat Offerings configured with Premium + Ultra + trial phase
- [ ] App Store Connect / Play Console SKUs created and approved

### RevenueCat / Store setup (when the time comes)

- Create 2 new SKUs per store: `premium_plus_monthly` ($9.99), `premium_plus_yearly` ($99.99)
- Attach both to `premium_plus` entitlement in RevenueCat
- Keep `premium` entitlement on existing SKUs (don't migrate)
- Update paywall to show tier comparison — code lives at `mobile/flutter/lib/screens/paywall/paywall_pricing_screen.dart`

### Why Ultra over Lifetime

Documented at length above (Launch Decision section). Short version: lifetime = one-time cash + forever Gemini liability. Ultra = recurring revenue that scales with cost. If we ever do lifetime, it's a **scarcity lever** (e.g., "Founding 500") at $149.99 — never a permanent SKU.

---

## Future Tier: Lifetime — Deferred

### Status
Not planned for launch. `SubscriptionTier.lifetime` exists in code (`subscription_provider.dart:20`) for potential future use.

### If we ever launch it

- **Only after Premium moves to $9.99** — at $4.99 the math doesn't pencil (20-month break-even vs monthly reads as weak).
- **Price: $149.99** (3× yearly at $9.99/$49.99 era; adjust if yearly changes).
- **Cap at 500 seats** ("Founding Member" scarcity) — never a permanent SKU.
- **Exclude future tiers** from lifetime — covers today's Premium only, so Ultra/Plus upsell still works.

---

## Future Tier: Family Plan — Deferred (Do Not Launch Yet)

### Status
Not planned for launch. No `SubscriptionTier.family` enum exists in code. Requires new schema, entitlement-sharing logic, and invitation flow — **3-4 weeks of engineering**.

### Why not now (Apr 2026)
Family plans are a **retention lever, not a growth lever**. At the current stage (<500 paying subs, $4.99 anchor, no PMF data), a family plan would:
- Cannibalize individual revenue (a couple who'd pay 2× $4.99 = $9.98 downgrades to 1× $10.99 = $10.99 — almost flat revenue but you carry 2× Gemini cost)
- Require 3-4 weeks of engineering (invitations, shared entitlements, multi-user auth, data isolation)
- Likely net *less* revenue than 2-4 individual subs for the first 6 months
- Signal "family-friendly app" when the product is single-user-personalized by design

### Why fitness family plans generally fail
- **Data is personalized per user** — your plan ≠ your spouse's plan. No "shared library" to pool.
- **AI coaching can't be shared** — chat history, goals, injuries are individual
- **Each user is a separate active cost** (Gemini $0.70-1.50/user/mo)
- **Buying decisions are individual** — "I want to get in shape" is not "the family wants Netflix"
- **Industry evidence:** Fitbod, MacroFactor, Apple Fitness+, Gravl, Strong, Hevy — **none** offer family plans. Only Apple Fitness+ includes family via Apple Family Sharing (native OS-level, not a separate SKU).

### Math — why $10.99/4-user plan doesn't pencil

Per-family-plan-subscription at $10.99:
- Gross: $10.99
- After 15% store cut: $9.34
- After 4× Gemini ($0.70 moderate): **$6.54 net/mo**

Compare to 4 individual Premium subscribers at $4.99:
- 4 × ($4.99 × 0.85 – $0.70) = **$14.16 net/mo**

**Family plan at $10.99 loses 54% of revenue** for the same active user count and Gemini cost.

### Breakeven pricing table (4-user family vs 4 individuals @ $4.99)

| Family price | Net after store | After 4× Gemini | Profit vs 4 individuals ($14.16) |
|---|---|---|---|
| $9.99 | $8.49 | $5.69 | –$8.47 (lose 60%) |
| $10.99 | $9.34 | $6.54 | –$7.62 (lose 54%) |
| $12.99 | $11.04 | $8.24 | –$5.92 (lose 42%) |
| $14.99 | $12.74 | $9.94 | –$4.22 (lose 30%) |
| $17.99 | $15.29 | $12.49 | –$1.67 (lose 12%) |
| **$19.99** | **$16.99** | **$14.19** | **+$0.03 (breakeven)** |

**True breakeven family price = $19.99/mo for 4 seats.** Anything lower only makes sense as an acquisition discount — worth it if it drives net-new users who wouldn't have subscribed solo.

### Duo plan — the middle ground (2 seats)

If we revisit family plans later, **Duo (2 seats) is more viable than Family (4 seats)** because the Gemini cost scales with seats but acquisition incrementality is higher for couples than for full families:

| Duo price | Net after store | After 2× Gemini | Profit vs 2 individuals ($7.08) |
|---|---|---|---|
| $7.99 | $6.79 | $5.39 | –$1.69 (lose 24%) |
| $8.99 | $7.64 | $6.24 | –$0.84 (lose 12%) |
| **$9.99** | **$8.49** | **$7.09** | **+$0.01 (breakeven)** |

**Duo at $9.99 = breakeven vs 2 individuals.** Only worth launching if the 2nd seat captures someone who wouldn't have paid on their own.

### Industry benchmarks (2026)
| App | Individual | Family | Seats | Per-seat family cost |
|---|---|---|---|---|
| Spotify | $10.99 | $16.99 | 6 | $2.83 |
| Apple Music | $10.99 | $16.99 | 6 | $2.83 |
| YouTube Premium | $13.99 | $22.99 | 5 | $4.60 |
| Headspace | $12.99 | $19.99 | 6 | $3.33 |
| **Apple Fitness+** | $9.99 | Native Family Sharing | 6 | $0 incremental |
| **Fitbod** | $12.99 | ❌ none | — | — |
| **MacroFactor** | $11.99 | ❌ none | — | — |
| **Hevy / Strong / Gravl** | varies | ❌ none | — | — |

### The free alternative — Apple/Google Family Sharing
Before building a Family SKU, enable **native Family Sharing on the existing Premium SKU**:
- **App Store Connect** → Subscriptions → `premium_monthly` → toggle "Family Sharing" → ON
- **Google Play** → Subscriptions → `premium_monthly` → Family Library → enable
- Zero engineering work
- Primary subscriber's family members get Premium access via Apple Family / Google Family
- You lose some per-family-unit revenue but gain engagement/retention without building a new tier
- **Recommended default** whenever we're ready for any family behavior

### Better alternatives to family plan for growth
Ranked by ROI for the "earn money ASAP" goal:
1. **India PPP pricing (₹249)** — free revenue lift, zero cannibalization
2. **7-day trial on monthly plan** — +20-40% trial starts (today monthly has no trial)
3. **Referral program** — "Invite a friend, both get 1 month free" — mimics family-plan virality without revenue cannibalization
4. **Annual upsell at month 2** — converts monthly churners
5. **Apple/Google Family Sharing toggle** — free "family" perk without new SKU
6. Then, much later: Family/Duo SKU if data justifies

### Launch prerequisites (when/if we ever ship a Family or Duo SKU)
Don't build until:
- [ ] 2,000+ paying individual subscribers (proves PMF, provides upsell base)
- [ ] 3+ months of cohort retention data at current single-user pricing
- [ ] User research shows ≥20% of users have a spouse/partner/family member who would use Zealova
- [ ] Premium price stable at $9.99+/mo (Family pricing ladder only reads as a deal when individual is higher)
- [ ] Multi-user entitlement infrastructure built (invitation tokens, seat management, per-user data isolation)

### If launched (recommended future specs)
- **Duo (2 seats):** $9.99/mo — breakeven, good for couples, minimal engineering
- **Family (4-6 seats):** $19.99/mo — breakeven at 4 seats, upside at 5-6 seats
- **Yearly family:** $199.99/yr (~$16.67/mo, 17% savings)
- **India Duo:** ₹399/mo (breakeven at ₹199 single)
- **India Family:** ₹799/mo (breakeven at ₹199 × 4)

### Implementation notes (when we build it)
- New `SubscriptionTier.family` enum in `subscription_provider.dart`
- New Supabase table `family_group_members (group_id, user_id, role, joined_at)`
- Invitation endpoint: `POST /api/v1/subscriptions/family/invite` (generates single-use token, emails via Resend)
- Entitlement check: user is Premium if they're in a `family_group_members` record with `status=active`
- RevenueCat: new product `premium_family_monthly`, attach to new `family` entitlement
- Paywall copy: 3rd column "Family Plan — $19.99/mo · up to 4 people"
- Refund/cancel: removing primary cancels for all members (grace period recommended)

---

## Future Tier: Free with Limits — Not Recommended

A capped free tier (e.g., 3 workouts/mo, 5 photo logs, no chat) is plumbed in code via `SubscriptionTier.free` but **not implemented as a product**. Today `free` = "paywall was dismissed."

Don't build this until:
- Organic install volume is high enough that paywall-or-leave is leaving money on the table (likely at 50K+ MAU)
- We have data showing which features convert free users → paid (i.e., which limits actually drive conversion)

Premature freemium = revenue loss with no learning.

---

## Appendix: Files to update if price changes

- `mobile/flutter/lib/core/providers/subscription_provider.dart:719-731` — `ProductPricing.products` fallback map (add `premium_plus_monthly` / `premium_plus_yearly` entries when Ultra launches; add `premium_family_monthly` when Family launches)
- `mobile/flutter/lib/core/providers/subscription_provider.dart:228-229` — Premium Plus product ID constants (already exist); Family product IDs need to be added
- `mobile/flutter/lib/core/providers/subscription_provider.dart:234` — `premiumPlusEntitlement` key; `familyEntitlement` key needed when Family launches
- `subscription_provider.dart` — add `SubscriptionTier.family` enum when launching Family/Duo
- New Supabase migration — `family_group_members` table when Family launches
- RevenueCat dashboard — Offerings + pricing phases (source of truth for live price); create Premium Plus Offering when adding Ultra; Family Offering when adding Family
- App Store Connect + Google Play Console — product SKU prices; enable Family Sharing toggle on `premium_monthly` when we want native Apple/Google family behavior (no new SKU needed)
- `/PRICING.md` (root) — refresh to match reality (currently shows $5.99/$9.99 — misleading)
- `/SUBSCRIPTION_TIER_GUIDE.md` — same
- `research/COMPETITIVE_ANALYSIS.md:91-93` — update "Your App" row
- Paywall copy in `mobile/flutter/lib/screens/paywall/paywall_pricing_screen.dart` (rewrite as 3-column when Ultra launches; 4-column if Family added on top)
