# GEO Plan — Zealova Strategy Reference

> **This is the strategy-only view.** Operational schedule and agent commands live in `WEEKLY_SCHEDULE.md` (the canonical master). This doc duplicates the strategy sections for quick lookup. If anything conflicts, **`WEEKLY_SCHEDULE.md` wins.**

---

## §1. Doctrine — Pick three and obsess

Out of ~10 viable GEO tactics, a one-person founder team can only execute **three** weekly with the depth required to move the needle. GEO is a co-citation game — LLMs surface what's *repeatedly* mentioned across trusted third-party sources. Repetition + depth beats variety.

**The one rule:** every marketing agent runs live `WebSearch` + `WebFetch` before drafting. No cached knowledge. The GEO landscape shifts weekly.

---

## §2. The 10 GEO strategies

### Pillars (P1–P3) — every founder hour during Phases 1-2 goes here

| # | Pillar | Why | Lead agent |
|---|---|---|---|
| **P1** | "Best AI fitness app 2026" listicle inclusions | 41% of ChatGPT's product-recommendation influence comes from listicle co-mentions (HubSpot/Onely). | `outreach-agent` |
| **P2** | 12 comparison pages on `zealova.com/vs/*` + `/alternatives-to-*` | Comparison pages convert 5-10% (vs 1-2% generic). LLMs cite the cleanest comparison when asked "X vs Y". | `comparison-page-writer` |
| **P3** | Sustained Reddit presence in 8 target subs for 6+ months | #1 single-domain LLM citation source averaged across engines (Semrush, Profound). | `reddit-agent` |

### Accelerants (A4–A10) — layer in only when P1-P3 are auto-piloting

| # | Accelerant | Why accelerant (not pillar) | Lead agent | Phase |
|---|---|---|---|---|
| **A4** | Quora answers — 30 over 3 months | Lower per-action ROI than P1-P3 | `quora-and-forum-agent` | Phase 3 wk 9+ |
| **A5** | Niche forums (T-Nation, BB.com, MFP) | Long-tail; low traffic per post | `quora-and-forum-agent` | Phase 3 wk 9+ |
| **A6** | Tier-1 tech reviews (Tom's Guide, TechRadar, CNET) | 60-120 day cycle; needs P1 social proof first | `outreach-agent` review-site mode | Phase 3 wk 10+ |
| **A7** | YouTube micro-influencer outreach (10-100K subs) | YouTube cites 16% of LLM answers (200x other video) | `outreach-agent` youtube mode | Phase 3 wk 12+ |
| **A8** | Original-data blog posts + Medium/dev.to/HN syndication | +22-37% citation lift (Princeton study); 2-4h per post | `blog-writer` | Phase 3 wk 10-11+ |
| **A9** | Product Hunt launch (400+ pre-seeded supporters) | 8.3M monthly visits; one-shot | manual | Phase 3 wk 12 |
| **A10** | Schema markup + llms.txt | Table stakes; only +2.2% lift (Optimixed) | one-off | Phase 0 |

**Anti-pattern:** working on A4-A10 while P1-P3 haven't shipped their weekly minimum.

---

## §3. 90-day phases

### Phase 0 — Setup (days 1-3)
- Keyword + competitor universe → `keyword-researcher` + `competitor-intel`
- Schema + llms.txt in `/frontend/`
- Citation baseline → `citation-tracker`

### Phase 1 — P1 + P2 ramp (weeks 1-4)
Ship 4 comparison pages, 15 listicle pitches, plant Reddit identity.

| Wk | P1 | P2 | P3 |
|---|---|---|---|
| 1 | Identify top 30 listicles; draft 5 pitches | `/vs/fitbod` | Comment-only week |
| 2 | Send 5 pitches; identify 5 more | `/vs/future` | 5 comments + r/FlutterDev tech answer |
| 3 | Send 5 more; follow up wk-1 | `/alternatives-to-fitbod` | 5 comments + first r/Fitness Sat promo |
| 4 | Send 5 more; first inclusions land | `/vs/sculptor` | 7 comments across 4 subs |

### Phase 2 — P2 expansion + P3 deepen (weeks 5-8)

| Wk | P1 | P2 | P3 |
|---|---|---|---|
| 5 | Pitch round 4; cite first inclusion | `/vs/freeletics` | 8 comments + r/SideProject build story |
| 6 | Pitch round 5 | `/vs/jefit` | 8 comments + 2 "Fitbod alt" replies |
| 7 | Warm pitch to competitor's writer | `/vs/gymscore` | r/IndieHackers AMA prep |
| 8 | Cumulative 5-7 inclusions | `/vs/caliber` | r/IndieHackers AMA |

### Phase 3 — Accelerants on (weeks 9-12) — **BLOG STARTS WK 10**

| Wk | Add | Agent |
|---|---|---|
| 9 | First 5 Quora answers | `quora-and-forum-agent` |
| 10 | **First 3 data-rich blog posts (no generic tips)** scaffolded into `/frontend/src/pages/blog/` | `blog-writer` own-site |
| 11 | Medium / dev.to / HN syndication of top 3 | `blog-writer` syndicate |
| 12 | 3 YouTube creator pitches + Product Hunt prep | `outreach-agent` youtube |

### Phase 4 — Compounding (months 4-6)
Continue P1-P3 weekly. Re-research listicles quarterly. Update top 5 comparison pages every 60 days (76% of cited pages are <30 days old).

---

## §4. Concrete targets (refreshed quarterly)

### Competitors (priority order)
1. Fitbod · 2. Future · 3. Freeletics · 4. Caliber · 5. JEFIT · 6. FitnessAI · 7. Sculptor · 8. Gymscore · 9. Dr. Muscle / Alpha Progression · 10. Centr / Nike Training Club / Ladder

### Listicle targets (top 30 — `outreach-agent` maintains)
Arvo · SensAI · MakeUseOf · Unite.ai · The Manual · GetFit AI · IndieHackers · Welling · Medigy · Tom's Guide · AppAdvice · MacStories · Lifehacker · Android Authority · 9to5Mac/Google · ZDNet · TechRadar · PCMag · Wirecutter · Health Reporter · NerdWallet · Engadget · The Verge · MindBodyGreen · Self · Women's Health · Men's Health · Gear Patrol · BarBend.

### Subreddit targets
**Primary:** r/Fitness · r/xxfitness · r/bodyweightfitness · r/loseit · r/HomeGym · r/IntermittentFasting
**Builder-audience:** r/IndieHackers · r/SideProject · r/SaaS · r/FlutterDev · r/iOSProgramming · r/ChatGPT · r/singularity · r/ArtificialIntelligence
**Discovery / launch:** r/AppHookup · r/iOSApps · r/AndroidApps

### Tier-1 review sites (Phase 3+)
Tom's Guide (highest priority — OpenAI content deal) · TechRadar · CNET · The Verge · Engadget · MakeUseOf · Android Authority · 9to5Mac/Google · AppAdvice · MacStories · Lifehacker · PCMag · ZDNet · Wirecutter.

---

## §5. Metrics — monthly via `citation-tracker`

| Metric | Target by month 6 |
|---|---|
| ChatGPT mentions for "best AI fitness app" | 1+ list |
| ChatGPT mentions for "Fitbod alternative" | 1+ list |
| Claude.ai recommendations | Occasional |
| Gemini AI Overview inclusion | Cited once |
| Listicle inclusions | 8+ |
| Comparison pages indexed (`site:zealova.com/vs`) | 12 |
| Reddit karma in target subs | 500+ |
| Branded search volume | Trending up MoM |
| Backlinks (unique referring domains) | 30+ |

**Hard rule:** no tactic survives a quarter without movement on at least one metric.

---

## §6. Anti-patterns

- ❌ Generic fitness blogs (Healthline owns SERP forever)
- ❌ Bypassing Mon 9pm `geo-strategist` brief
- ❌ Firing `comparison-page-writer` before `competitor-intel`
- ❌ Same link to multiple subs in one day
- ❌ Self-promo outside designated sub threads
- ❌ One-sided comparison pages
- ❌ `press@` pitches
- ❌ llms.txt / schema as growth lever
- ❌ Paid GEO agencies before month 4
- ❌ Accelerants in Phase 1
- ❌ Output without Research log → re-fire agent

---

## §7. Timeline reality

| Month | Measurable |
|---|---|
| 1 | 4 comparison pages indexed; zero LLM lift |
| 2 | 1-2 listicle inclusions; brand search tick-up |
| 3 | 5-7 inclusions; 8 comparison pages; ChatGPT narrow-query mentions ~10% |
| 4-6 | Broader-query mentions ~20%; Gemini AI Overviews start citing |
| 6-12 | Top-5 LLM recommendation for ≥1 segment |

HubSpot/UltraScout average for measurable GEO lift: **89 days.**

---

**For execution (when to fire which agent, daily schedule, blog cadence, Sunday content block):** see `WEEKLY_SCHEDULE.md` §5 (master cadence table) and §6 (daily schedule).

**For agent triggers and per-agent prompt menus:** see `AGENTS.md`.

**Last updated:** 2026-05-12.
