# Weekly Schedule + GEO Master Plan — Zealova + Hireable + Mobiprompt + Ultraviolet

> **This is the canonical operations doc.** It merges the prior `GEO_PLAN.md`, `AGENTS.md`, and the original weekly schedule into one source of truth.
>
> **Daily targets:** 100+ job apps · ~40 min active build + 2 background agents · daily Zealova X post · 7h 15m sleep
> **Weekly targets:** ~825 apps (~575 weekday + 250 weekend) · all 4 apps touched · ~33 posts · 6 hr gym · **1 comparison page shipped · 5 listicle pitches · 6-10 Reddit comments**

---

## TABLE OF CONTENTS

- **Part 1 — Doctrine** (§1: pick three and obsess)
- **Part 2 — 10 GEO strategies** (§2: P1-P3 pillars + A4-A10 accelerants)
- **Part 3 — 90-day phases** (§3)
- **Part 4 — Agent reference** (§4: 11 marketing agents, when to fire each, trigger prompts)
- **Part 5 — GEO weekly cadence — exact agent commands by day/time** (§5) ← *the lookup table you'll use most*
- **Part 6 — Daily schedule** (§6: Sun-Sat, augmented with agent commands)
- **Part 7 — Per-app social map** (§7)
- **Part 8 — Reels + carousel strategy** (§8)
- **Part 9 — Targets, metrics, anti-patterns** (§9)
- **Part 10 — Accounts, tool stack, weekly totals** (§10)

---

# PART 1 — DOCTRINE

## §1. Pick three and obsess

Out of ~10 viable Generative Engine Optimization (GEO) tactics, a one-person founder team can only execute **three** weekly at the depth required to move the needle. Everything else is a force-multiplier that pays off *after* the core three compound.

**Why three, not ten:** GEO is a co-citation game — LLMs (ChatGPT, Claude, Gemini, Perplexity) surface what's *repeatedly* mentioned across trusted third-party sources. Repetition + depth beats variety. Founders who diversify across all 10 tactics at week one execute each at ~30% quality and accumulate zero citation lift. Founders who pick three and grind weekly for six months show up in ChatGPT's "best AI fitness app" answers by month 6-12.

**The one rule that overrides everything else:**

> Every marketing agent runs live `WebSearch` + `WebFetch` before drafting. No cached knowledge.

The GEO landscape shifts weekly. Any agent that drafts off stale knowledge produces stale output that LLMs ignore. If you see an agent skip the Research log, that's a bug — re-fire it.

---

# PART 2 — THE 10 GEO STRATEGIES

## §2. Pillars (P1–P3) and accelerants (A4–A10)

### The three pillars — every founder hour during Phases 1-2 goes here

| # | Pillar | Why this one | Lead agent |
|---|---|---|---|
| **P1** | Get included in "Best AI Fitness App 2026" listicles | 41% of ChatGPT's product-recommendation influence comes from listicle co-mentions (HubSpot/Onely). Highest-leverage move that exists. | `outreach-agent` |
| **P2** | Build 12 comparison pages on `zealova.com/vs/*` and `/alternatives-to-*` | Comparison pages convert at 5-10% (vs 1-2% generic). LLMs cite the cleanest comparison page when asked "X vs Y". | `comparison-page-writer` |
| **P3** | Sustained Reddit presence in 8 target subs for 6+ months | Reddit is still the #1 single-domain LLM citation source averaged across engines (Semrush, Profound). Free, durable, compounds. | `reddit-agent` |

### The seven accelerants — layer in only when P1-P3 are auto-piloting

| # | Accelerant | Why accelerant (not pillar) | Lead agent | Phase |
|---|---|---|---|---|
| **A4** | Quora answers — 30 over 3 months | Quora is in every LLM training set; long-tail compounds. Lower per-action ROI than P1-P3. | `quora-and-forum-agent` | Phase 3 wk 9+ |
| **A5** | Niche fitness forum posts (T-Nation, BB.com, MFP community) | Surprisingly well-indexed. Low traffic per post — worth it after P3 covers Reddit. | `quora-and-forum-agent` | Phase 3 wk 9+ |
| **A6** | Tier-1 tech-review-site pitches (Tom's Guide, TechRadar, CNET, The Verge, MakeUseOf, Wirecutter) | Highest-trust citation source (Tom's Guide has direct OpenAI deal). Long sales cycle (60-120 days), needs P1 social proof first. | `outreach-agent` review-site mode | Phase 3 wk 10+ |
| **A7** | YouTube micro-influencer outreach (10-100K subs) | YouTube cites 16% of LLM answers, 200x other video platforms. Each collab takes weeks. | `outreach-agent` youtube mode | Phase 3 wk 12+ |
| **A8** | Original-data blog posts + Medium / dev.to / HN Show HN syndication | Data-rich posts lifted AI visibility +22-37% (Princeton GEO study). Each post is 2-4 founder-hours; only the right type counts. | `blog-writer` | Phase 3 wk 10-11+ |
| **A9** | Product Hunt launch (once 400+ pre-seeded supporters) | PH gets 8.3M monthly visits. One-shot. | manual | Phase 3 wk 12 |
| **A10** | Schema markup + llms.txt hygiene | Table stakes. Optimixed study: only +2.2% citation lift. Do once, move on. | one-off | Phase 0 setup |

**Anti-pattern:** if you find yourself working on A4-A10 while P1-P3 haven't shipped their weekly minimum, stop and redirect.

---

# PART 3 — 90-DAY PHASES

## §3. Phased rollout

### Phase 0 — Setup (days 1-3, one-time)

| Task | Output | Agent prompt |
|---|---|---|
| Keyword + competitor universe | `marketing/keywords/research.md` + `marketing/competitors/intel.md` | `"Refresh the keyword universe for 'AI workout app'"` → keyword-researcher; `"Profile Fitbod, Future, Sculptor, Gymscore"` → competitor-intel (one at a time) |
| Schema markup + llms.txt drop-in on zealova.com | committed to `/frontend/` | manual / claude-code direct |
| Citation baseline | `marketing/citations/tracker.md` (date-zero) | `"Baseline LLM mentions — we're starting from zero, take the snapshot"` → citation-tracker |

### Phase 1 — P1 + P2 ramp (weeks 1-4)

**Goal:** Ship 4 comparison pages live, send 15 listicle pitches, plant Reddit identity (no promo yet).

| Week | P1 (listicles) | P2 (comparison pages — runs Sunday) | P3 (Reddit) |
|---|---|---|---|
| 1 | Identify top 30 listicles; draft 5 pitches | `/vs/fitbod` (workout AI #1 target) | Comment-only week, 5 genuine answers, no links |
| 2 | Send 5 pitches; identify next 5 | `/vs/myfitnesspal` (nutrition #1 target — post-Cal-AI-acquisition angle) | 5 more comments; first r/FlutterDev technical answer |
| 3 | Send 5 more; follow up week-1 batch | `/vs/hevy` (workout tracker — "generate vs log" wedge) | 5 comments; first r/Fitness Saturday self-promo |
| 4 | Send 5 more; first inclusions land | `/vs/macrofactor` (nutrition — concede algorithm, win on breadth) | 7 comments across 4 subs |

### Phase 2 — P2 expansion + P3 deepen (weeks 5-8)

| Week | P1 | P2 | P3 |
|---|---|---|---|
| 5 | Pitch round 4; cite first inclusions as social proof | `/vs/future` (workout AI — price wedge) | 8 comments; first long-form r/SideProject build story |
| 6 | Pitch round 5 | `/vs/cronometer` (nutrition — concede micros, win on AI coach) | 8 comments; reply in 2 "Fitbod alternative" threads |
| 7 | Warm pitch to writer covering competitor | `/vs/sculptor` + `/vs/gymscore` (form analysis pair) | r/IndieHackers AMA prep |
| 8 | Pitch round 6; cumulative 5-7 listicle inclusions | `/alternatives-to-fitbod` (Phase 2 roundup) | r/IndieHackers AMA goes live |

### Phase 3 — Accelerants on (weeks 9-12) — **BLOG ENTERS THE CADENCE HERE**

| Week | Add | Lead agent |
|---|---|---|
| 9 | First 5 Quora answers | `quora-and-forum-agent` |
| 10 | **First 3 data-rich blog posts (Phase 3 = blog kickoff)** — written on Sundays, scaffolded into `/frontend/src/pages/blog/`. NO generic fitness tips. | **`blog-writer` own-site** |
| 11 | Medium / dev.to / HN syndication of top 3 blogs | `blog-writer` syndicate |
| 12 | 3 YouTube micro-influencer pitches + Product Hunt prep | `outreach-agent` youtube mode |

### Phase 4 — Compounding (months 4-6)

Continue P1-P3 weekly. Quarterly: re-research listicle list, update top 5 comparison pages (freshness signal — 76% of cited pages are <30 days old), monthly citation snapshot.

---

# PART 4 — AGENT REFERENCE

## §4. The 11 marketing agents

All agent files live in `.claude/agents/marketing/`. Engineering agents (8 of them) live in `.claude/agents/engineering/`. Nested folders are organizational only — invocation uses the `name:` frontmatter, not the path.

### §4.0 Folder structure

```
.claude/agents/
├── engineering/   ← 8 code/infra agents (existing)
└── marketing/     ← 11 agents (the focus of this doc)
    ├── geo-strategist.md
    ├── keyword-researcher.md
    ├── competitor-intel.md
    ├── reddit-agent.md
    ├── comparison-page-writer.md  ← also scaffolds frontend/src/pages/vs/*.tsx
    ├── blog-writer.md             ← also scaffolds frontend/src/pages/blog/*.tsx
    ├── quora-and-forum-agent.md
    ├── outreach-agent.md
    ├── citation-tracker.md
    ├── social-post-creator.md     ← LinkedIn/X/IG/TikTok platform posts (pre-existing)
    └── market-research-expansion.md ← quarterly landscape (pre-existing)
```

```
docs/planning/marketing/   ← append-only agent output store
├── reddit/{posts.md, sub-rules.md}
├── blogs/{posts.md, ideas.md}
├── medium/posts.md
├── comparison-pages/posts.md
├── quora/answers.md
├── outreach/{listicles.md, review-sites.md, youtube-creators.md}
├── keywords/research.md
├── competitors/intel.md
└── citations/tracker.md
```

```
frontend/src/pages/        ← deployable React pages (auto-scaffolded by agents)
├── blog/<PascalSlug>.tsx
├── vs/<Competitor>.tsx
├── alternatives/<Slug>.tsx
└── best/<Segment>.tsx
```

### §4.1 `geo-strategist` — weekly orchestrator
**Fires:** Mon 9:00 PM. Also daily "5-min status check" if time allows.
**Sample triggers:**
- `"Run the weekly GEO cadence"`
- `"What should I work on this week for Zealova marketing?"`
- `"I have 60 minutes — what's the most leveraged thing?"`
- `"Are we on track? Diff planned vs shipped"`
- `"60-day flat tactics — should we drop any?"`

### §4.2 `keyword-researcher` — search-volume analyst
**Fires:** Before any comparison page / blog post; weekly refresh.
**Sample triggers:**
- `"Find the top keywords for the /vs/fitbod page"`
- `"What do people search for around AI form analysis?"`
- `"Long-tail variants of 'Fitbod alternative'"`
- `"PAA questions for 'best AI fitness app'"`
- `"Reddit thread frequency for 'form check app' across target subs"`

### §4.3 `competitor-intel` — per-competitor analyst
**Fires:** Before `comparison-page-writer`; monthly refresh.
**Sample triggers:**
- `"Profile Fitbod"`
- `"Deep-dive on Future's pricing changes past 90 days"`
- `"What are users saying about Sculptor on Reddit?"`
- `"Refresh the Fitbod profile — last updated 60 days ago"`
- `"List 5 weaknesses of Future we should highlight (honestly)"`

### §4.4 `reddit-agent` — community contributor (pillar P3)
**Fires:** 5-7×/week across daily slots.

**Scout mode triggers:**
- `"Find 3 Reddit threads I should engage with this week"`
- `"What's hot in r/IndieHackers this week?"`
- `"Find recent 'Fitbod alternative' threads I should reply to"`

**Write mode — reply to thread URL:**
- `"Reply to this thread for me: <URL>"`
- `"Someone asked about AI form-check apps in r/Fitness: <URL>. Draft my answer"`

**Write mode — reply to comment / DM:**
- `"Draft my reply to: 'How is this different from Fitbod?'"`
- `"Reply to this DM: '<text>'"`

**Write mode — top-level post:**
- `"Draft a top-level post for r/IndieHackers about the Gemini multi-agent architecture"`
- `"Write my r/Fitness Saturday self-promo post"`
- `"Help me prep an AMA in r/SideProject — draft post + 10 Qs with answers"`

**Rules mode:**
- `"Can I post my app in r/loseit?"`
- `"Refresh promo rules for r/Fitness"`

### §4.5 `comparison-page-writer` — SaaS comparison specialist (pillar P2)
**Fires:** Once per week (Sunday). **Scaffolds TSX into `/frontend/src/pages/vs/`.**
**Sample triggers:**
- `"Write the /vs/fitbod comparison page"`
- `"Draft a 'best Fitbod alternatives in 2026' page"`
- `"Refresh /vs/fitbod — check current Fitbod pricing"`
- `"Markdown only (no scaffold): draft the /vs/jefit page"`
- `"Comparison page: Zealova vs Future, lean on price wedge"`

### §4.6 `blog-writer` — content strategist (accelerant A8, **starts Phase 3 week 10**)
**Fires:** Once per week Sunday, Phase 3+. **Scaffolds TSX into `/frontend/src/pages/blog/`.** Refuses generic fitness tips.

**Topic-ideation mode:**
- `"What should I blog about this week?"`
- `"Give me 10 blog ideas tied to this-week's fitness trends"`
- `"Ideate blog topics around our form-analysis feature"`

**Own-site mode (writes TSX + markdown):**
- `"Write a data-rich post on the most common squat form errors"`
- `"Scaffold the blog page in the frontend for the squat-errors topic"`
- `"Write a deep technical post on Zealova's multi-agent chat architecture"`
- `"Draft a founder-tested benchmark: 'I tested 9 AI fitness apps for 30 days'"`
- `"Glossary entry: 'What is RIR-based programming?' with FAQ schema"`

**Syndicate mode (markdown only):**
- `"Syndicate the squat-errors post to Medium"`
- `"Draft a Show HN version of the multi-agent post"`
- `"Repost the form-analysis blog to dev.to"`

**Refresh mode:**
- `"Refresh the squat-errors post — check if any stats shifted"`
- `"Update /blog/best-fitbod-alternatives — last touched 90 days ago"`

### §4.7 `quora-and-forum-agent` — long-form answer writer (A4/A5)
**Fires:** Phase 3+ (week 9+).
**Sample triggers:**
- `"Find 5 Quora questions I should answer this week"`
- `"Draft a Quora answer for: <URL>"`
- `"Find T-Nation threads about AI workout apps"`
- `"Answer: 'Is Fitbod worth it in 2026?' — here's the link"`

### §4.8 `outreach-agent` — founder pitcher (pillar P1, A6, A7)
**Fires:** Weekly listicle mode; Phase 3+ for review-site and YouTube modes.

**Listicle mode:**
- `"Send 5 listicle pitches this week"`
- `"Pitch the next 5 listicles on the target list"`
- `"Find new 'best AI fitness app 2026' listicles published this past month"`
- `"Follow up on last week's listicle pitches"`

**Review-site mode (Phase 3+):**
- `"Pitch Tom's Guide on Zealova"`
- `"Find the current TechRadar writer covering fitness apps"`
- `"Draft a pitch to <name> at CNET — they just reviewed Fitbod"`

**YouTube mode (Phase 3+):**
- `"Find 3 YouTube fitness-tech creators (10-100K subs) to pitch"`
- `"Pitch <creator> for a comparison video"`

**Status / followup:**
- `"<Name> replied — log it and draft a followup"`
- `"<Name> included us in their roundup: <URL> — log and update citation tracker"`

### §4.9 `citation-tracker` — empirical scoreboard
**Fires:** Monthly (1st of each month). Spot-checks on demand.
**Sample triggers:**
- `"Run the monthly citation snapshot"`
- `"Spot check: are we mentioned for 'best AI fitness app' in Google AI Overview?"`
- `"Compare this month's grid vs last month — what moved?"`
- `"Any tactic flat 60+ days?"`

### §4.10 `social-post-creator` — platform-native social
**Fires:** Sunday batch — replaces manual drafting for X/LinkedIn/IG/TikTok platforms.
**Sample triggers:**
- `"Write social posts for all platforms about <event>"`
- `"Draft a LinkedIn post about the AI coach feature"`
- `"Give me an X thread on multi-agent fitness coaching"`
- `"Make an IG Reel script for the form-analysis demo"`

### §4.11 `market-research-expansion` — quarterly landscape
**Fires:** Quarterly competitive review; new-feature ideation.
**Sample triggers:**
- `"What features are competitors offering that we don't have?"`
- `"Quarterly competitive landscape review"`

### §4.12 Hand-off chains

```
Comparison page chain (P2 weekly):
  keyword-researcher → competitor-intel → comparison-page-writer

Blog chain (Phase 3+):
  blog-writer (ideation) → keyword-researcher → blog-writer (own-site)
  → (7 days later) blog-writer (syndicate)

Reddit chain (daily):
  reddit-agent (scout) → reddit-agent (write thread #1) → reddit-agent (write reply if responded)

Outreach chain (P1 weekly):
  outreach-agent (listicle) → ...wait 7 days... → outreach-agent (followup) → citation-tracker (when inclusion lands)

Strategy chain (Monday):
  geo-strategist → dispatches specialists for the week
```

---

# PART 5 — GEO WEEKLY CADENCE: EXACT AGENT COMMANDS BY DAY/TIME

## §5. The lookup table — use this every day

This is the table you'll reference most. It overlays GEO agent commands onto your existing daily schedule. **Total added GEO time: ~3-4 hr/week** (mostly absorbing existing Reddit/X slots).

### §5.1 Master cadence table

| Day | Time | Duration | Agent | Copy-paste prompt | Notes |
|---|---|---|---|---|---|
| **Mon** | 9:00 PM | 15 min | `geo-strategist` | `"Run the weekly GEO cadence"` | Weekly action brief. New slot, before night bulk. |
| **Mon** | 12:00 PM | (within existing Hireable Reddit slot) | `reddit-agent` | `"Scout 1 Zealova-relevant thread to reply to today"` | Use 5 min of the existing 15-min comment slot. |
| **Mon** | 12:50 PM | (existing Zealova X tweet slot) | `social-post-creator` | (pre-drafted Sunday — fires auto) | No new work. |
| **Tue** | 12:50 PM | (existing Zealova Reddit slot) | `reddit-agent` | `"Draft today's r/loseit or r/fitness Zealova post"` | Replaces manual drafting. |
| **Tue** | 9:00 PM | 10 min (within night engagement) | `reddit-agent` | `"Find 2 Reddit threads in target subs I should reply to tomorrow"` | Scout to queue Wed engagement. |
| **Wed** | 12:00 PM | 15 min (within Hireable Reddit slot — co-runs) | `outreach-agent` | `"Send 5 listicle pitches this week"` | P1 pillar. Email-only, low time. |
| **Wed** | 12:50 PM | (existing Zealova X tweet slot) | `social-post-creator` | (pre-drafted Sunday — fires auto) | No new work. |
| **Wed** | 5:30 PM | 30 min (carved from existing 60-min build) | `reddit-agent` | `"Reply to the highest-engagement thread from Tue scout"` | Quality comment. |
| **Thu** | 9:00 PM | 10 min (within night engagement) | `outreach-agent` | `"Follow up on this week's listicle pitches sent Wed"` | One-line emails. |
| **Fri** | 12:50 PM | 2 min (existing reply-to-trending) | `reddit-agent` or manual | `"Find a viral fitness X post and draft Zealova POV reply"` | Live. |
| **Sat** | 5:00 PM | (existing Reddit post slot) | `reddit-agent` | `"Draft my r/getmotivated post for tonight"` OR `"Draft my r/Fitness Saturday self-promo post"` | Live posting. |
| **Sun** | 9:30-10:00 AM | 30 min | `competitor-intel` | `"Profile <next competitor in /vs/ queue>"` | Sets up Sun comparison page. |
| **Sun** | 10:00-11:30 AM | 1h 30m | `comparison-page-writer` | `"Write the /vs/<competitor> page"` (scaffolds TSX) | P2 weekly. Ship a page. |
| **Sun** | 11:30-12:00 PM | 30 min (Phase 3+ only) | `blog-writer` | `"What should I blog about this week?"` then `"Write a <topic> post"` | A8 weekly (Phase 3 week 10+). |
| **Sun** | 12:00-12:30 PM | 30 min (Phase 3+ only) | `quora-and-forum-agent` | `"Find 5 Quora questions to answer this week"` + `"Draft an answer for #1"` | A4/A5. |
| **1st of month** | Mon 9:15 PM | 30 min | `citation-tracker` | `"Run the monthly citation snapshot"` | After the geo-strategist call. |

### §5.2 The daily 5-min ritual (every morning, every day)

While coffee with wife at 5:50 AM:

```
"Quick GEO status check — anything urgent today?"
```

Routes to `geo-strategist`. Returns 1-3 bullets: pitches due, hot threads closing in 24-48h, any flagged citation drops. If nothing urgent, says so. Tab-close. Move on.

### §5.3 The "react to live events" cheat sheet

| Trigger | Prompt | Agent |
|---|---|---|
| Inbound Reddit DM | `"Reply to this DM: '<text>'"` | `reddit-agent` |
| Live thread blowing up about competitor | `"This thread is hot: <URL>. Draft my reply"` | `reddit-agent` |
| New roundup article published | `"<Writer> just published <URL> — pitch them on inclusion next refresh"` | `outreach-agent` |
| Competitor raises price / changes feature | `"Fitbod just raised price to $X — refresh /vs/fitbod"` | `comparison-page-writer` (refresh mode) |
| Inclusion landed | `"<Site> included us: <URL> — log and update citation tracker"` | `outreach-agent` + `citation-tracker` |
| Someone asks for HIPAA / privacy / compliance | `"Draft a factual reply: '<question>'"` | `reddit-agent` |
| Bad review on App Store / Play | `"Draft a public reviewer response"` | manual or `social-post-creator` |

### §5.4 GEO weekly time budget

| Activity | Time |
|---|---|
| Mon 9pm geo-strategist | 15 min |
| Mon-Sat Reddit (5 comments + 2 posts) — already in schedule, now agent-drafted | 0 new |
| Wed listicle outreach | 15 min |
| Wed comparison-page comment | 30 min |
| Thu listicle followups | 10 min |
| Sun comparison page chain (intel + writer) | 2 hr |
| Sun blog (Phase 3+ only) | 30 min |
| Sun Quora (Phase 3+ only) | 30 min |
| Daily 5-min ritual × 7 | 35 min |
| **Total new GEO time/wk** | **~3.5 hr Phase 1-2, ~4.5 hr Phase 3+** |

This fits within the existing 7-9 hr/wk founder marketing budget since Reddit/X social slots are already in the schedule — agents just replace manual drafting.

---

# PART 6 — DAILY SCHEDULE

## §6.0 Accounts

| Account | Used for |
|---|---|
| **Your personal X handle** | ALL X posts — Zealova, Hireable, Mobiprompt, Ultraviolet, founder content. Mention products by name within posts. |
| **Your personal LinkedIn** | ALL LinkedIn posts — same logic. LI personal profiles get 5-10x more reach than company pages. |
| **Personal Reddit account** | All Reddit posts. Diversify across subs (already handled by sub rotation). |
| **Zealova Instagram (separate)** | Zealova-only fitness IG carousels. Fitness niche needs its own visual feed. |
| **Dev-app Instagram** | SKIP. Dev tools (Hireable/Mobi/UV) tank on IG. |

**Why no brand X/LinkedIn accounts:** indie hackers (Pieter Levels, Marc Lou, Daniel Vassallo) all run from 1 personal handle. Audience compounds faster, simpler to manage. Founder voice + product mentions = best ROI.

## §6.1 Tool stack ($19/mo total)

| Tool | Use | Cost |
|---|---|---|
| **Typefully** | X + LinkedIn scheduling, thread editor, analytics (handles ~22 weekly posts) | $19/mo |
| **Meta Business Suite** | Zealova IG carousel scheduling (free, native) | Free |
| **Notion** (or Apple Notes) | Reddit drafts (paste natively day-of — schedulers shadowban Reddit) | Free |

**One-tool alternative:** Buffer Essentials $15/mo (X + LI + IG + Reddit + Threads from one dashboard).

## §6.2 How posts work in this schedule

| When | What happens |
|---|---|
| **Sunday 9:30-12:30** | **CREATE all 33+ posts** for the week (via `social-post-creator` agent calls) + **SCHEDULE them** in Typefully (X + LI), Meta Business Suite (IG), and save Reddit drafts in Notion |
| **Weekday auto-fire times** | Pre-scheduled X + LinkedIn posts fire silently throughout the day — no action needed |
| **Reddit live slots** | You paste pre-drafted Reddit posts natively day-of (schedulers shadowban Reddit); when the day arrives, fire `reddit-agent` to draft based on that day's actual thread |
| **Live exceptions** | Fri 12:50pm reply-to-trending (2 min via `reddit-agent`). Quote tweets when user reviews come in (1 min ad-hoc). |

**Rule:** if you're creating content during the week, something went wrong on Sunday. Fix Sunday next week.

## §6.3 Cold-start engagement rules (Phase 1 = weeks 1-8)

Your accounts are new. Your own posts won't get many comments yet. So engagement slots are **"comment on OTHER people's viral posts"**, not "reply to your own". Flip back to own-reply once your posts start getting 10+ comments (~weeks 8-12).

**Pre-product Hireable rules:**
- ❌ NO recruiter DMs until landing page + waitlist signup exists
- ❌ NO posing as an HR/recruiting expert
- ✅ Comment as a **builder asking questions**: "Curious how recruiters here handle [X]?"
- ✅ "Building in public" framing: "I'm building Hireable because [pain point]. What's your take?"

## §6.4 How build sessions work (vibe-coding mode)

Active build slots are **time-boxed, not app-locked**. Each session = pick from the 4-app pool (Zealova, Hireable, Mobiprompt, Ultraviolet) based on what's hottest that day. Background Claude agents fill the other 2-3 apps in parallel.

**How to pick the active app each session:**
1. Bug or outage shipping today → that app
2. Demo / customer deadline this week → that app
3. Yesterday's background agent shipped a PR you need to extend → that app
4. Any app you haven't touched in 3+ days → that app (keeps all 4 alive)
5. Default → trust the vibe

**Sunday rule:** write 1+ task spec per app so any can be launched as background agent.

---

## §6.5 MONDAY (non-gym)

| Time | What to do |
|---|---|
| 5:45 | Wake, water, sunlight |
| 5:50 | Coffee with wife (she leaves 6:20). **5-min GEO ritual:** `"Quick GEO status check — anything urgent today?"` → `geo-strategist` |
| 6:20 | **Job fresh-catch**: LinkedIn "Past 24h" → Simplify autofill → 15 apps |
| 6:50 | **Active build session (40 min)**. Kick off 2 background agents. |
| 7:30 | Shower, breakfast |
| 7:50 | **Posts fire**: Zealova X thread (fitness myth-bust) + Hireable LinkedIn post #1 + Mobiprompt X tweet (auto midday 11am) → 5 min check |
| 8:00 | Day job |
| 12:00 | **Hireable Reddit post live** (r/indiehackers) + comment on 5 viral founder/HR posts (15 min). **In this slot:** `reddit-agent: "Scout 1 Zealova-relevant thread for me to reply to tomorrow"` (5 min, runs in background) |
| 12:15 | Lunch + **LazyApply bulk** (45 apps) |
| 12:50 | **Zealova X single tweet fires** (auto) → 5 min reply |
| 1:00 | Day job |
| 5:00 | **Evening fresh-catch**: 18 apps |
| 5:30 | **Active build session (60 min)** |
| 6:30 | Dinner with wife |
| 7:30 | Wife time (laptop closed, phone DND) |
| **9:00** | **🎯 GEO WEEKLY ANCHOR — 15 min:** `geo-strategist: "Run the weekly GEO cadence"`. Returns the week's dispatch plan. **1st of the month only:** add 30 min → `citation-tracker: "Run the monthly citation snapshot"`. |
| 9:15 | **Night bulk**: LazyApply 40 + 5 dream-tier tailored apps |
| 10:15 | Wind down |
| 10:30 | Bed |

**Auto-drops today:** Zealova IG carousel 11am · Mobiprompt X tweet 11am · Hireable X tweet 2pm (auto-scheduled)
**Apps today:** ~123
**Social today:** Zealova X thread (7:50) · Hireable LI #1 (7:50) · Mobiprompt X auto (11am) · Hireable X auto (2pm) · Zealova IG carousel (11am) · Hireable Reddit (12:00, live) · Comment on 5 viral X posts (12:00) · Zealova X tweet (12:50)
**GEO today:** Daily 5-min ritual + Mon 9pm weekly cadence + (1st of month) citation snapshot

---

## §6.6 TUESDAY (gym)

| Time | What to do |
|---|---|
| 5:45 | Wake |
| 5:50 | Coffee with wife. **5-min GEO ritual:** `"Quick GEO status check"` → `geo-strategist` |
| 6:20 | **Job fresh-catch**: 15 apps |
| 6:50 | **Active build session (40 min)** |
| 7:30 | Shower |
| 7:50 | **Posts fire**: Zealova X tweet (fitness tip) + Mobiprompt X thread + Mobiprompt LinkedIn #1 (8am) → 5 min check |
| 8:00 | Day job |
| 12:00 | **Mobiprompt Reddit post live** (r/ChatGPT) + comment on 5 r/PromptEngineering posts (15 min) |
| 12:15 | Lunch + **LazyApply bulk** (45 apps) |
| **12:50** | **Zealova Reddit post live** (r/loseit OR r/fitness biweekly rotate) + reply. **Fire:** `reddit-agent: "Draft today's r/loseit or r/fitness Zealova post"` (5 min before posting). |
| 1:00 | Day job |
| 5:00 | **Pre-gym fresh-catch**: LinkedIn Easy Apply only (10 apps) |
| 5:30 | **GYM block (2 hr)** — 30 min drive · 60-75 min workout · 30 min drive home. Use commute: drive there = fitness podcast / Zealova competitor app demos · drive home = call wife or voice-note content ideas |
| 7:30 | Shower + dinner with wife |
| 8:30 | Wife time |
| **9:00** | **Night bulk**: LazyApply 40 + 5 dream-tier tailored + **Hireable + Ultraviolet LinkedIn engagement on phone in parallel**: 10 thoughtful comments (questions, not pitches). **In parallel:** `reddit-agent: "Find 2 Reddit threads in target subs I should reply to tomorrow"` (10 min, queues Wed work). |
| 10:15 | Wind down |
| 10:30 | Bed |

**Auto-drops today:** Hireable X tweet 11am (auto) · Ultraviolet X tweet 3pm (auto)
**Apps today:** ~115 (15 + 45 + 10 + 45)
**Social today:** Zealova X tweet (7:50) · Mobiprompt X thread (7:50) · Mobiprompt LI #1 (8am) · Hireable X auto (11am) · UV X auto (3pm) · Mobiprompt Reddit (12:00, live) · Zealova Reddit (12:50, live, agent-drafted) · Hireable+UV LinkedIn comments (9pm, 30 min)
**GEO today:** Daily 5-min ritual + 12:50 Reddit draft + 9pm scout

---

## §6.7 WEDNESDAY (non-gym) — **PRIMARY GEO OUTREACH DAY**

| Time | What to do |
|---|---|
| 5:45 | Wake |
| 5:50 | Coffee with wife. **5-min GEO ritual:** `"Quick GEO status check"` → `geo-strategist` |
| 6:20 | **Job fresh-catch**: 15 apps |
| 6:50 | **Active build session (40 min)** |
| 7:30 | Shower |
| 7:50 | **Posts fire**: Founder X thread (PEAK day — lessons across all 4 apps) + Hireable X tweet + Hireable LinkedIn #2 (8am) → 5 min check |
| 8:00 | Day job |
| **12:00** | **Hireable Reddit post #2 live** (r/cscareerquestions) + comment on 5 #buildinpublic X posts (15 min). **🎯 IN PARALLEL — 15 min:** `outreach-agent: "Send 5 listicle pitches this week"` + `outreach-agent: "Follow up on last week's pitches"`. |
| 12:15 | Lunch + **LazyApply bulk** (45 apps) |
| 12:50 | **Zealova X tweet fires** (screenshot/UI tease, auto) → 5 min reply |
| 1:00 | Day job |
| 5:00 | **Evening fresh-catch**: 18 apps |
| **5:30** | **Active build session (60 min)** — OR split: **30 min build + 30 min:** `reddit-agent: "Reply to the highest-engagement thread from Tue scout"` (write a quality comment, then post). |
| 6:30 | Dinner with wife |
| 7:30 | Wife time |
| 9:00 | **Night bulk**: 45 apps (LazyApply + 5 dream-tier) |
| 10:15 | Wind down |
| 10:30 | Bed |

**Auto-drops today:** UV X tweet 2pm (auto) · Mobiprompt X tweet 4pm (auto)
**Apps today:** ~123
**Social today:** Founder X thread (7:50) · Hireable X tweet (7:50) · Hireable LI #2 (8am) · UV X auto (2pm) · Zealova X tweet (12:50) · Mobiprompt X auto (4pm) · Hireable Reddit #2 (12:00, live)
**GEO today:** Daily ritual + **12pm listicle outreach (P1 pillar — primary GEO day)** + 5:30 PM Reddit reply

---

## §6.8 THURSDAY (gym)

| Time | What to do |
|---|---|
| 5:45 | Wake |
| 5:50 | Coffee with wife. **5-min GEO ritual:** `"Quick GEO status check"` → `geo-strategist` |
| 6:20 | **Job fresh-catch**: 15 apps |
| 6:50 | **Active build session (40 min)** |
| 7:30 | Shower |
| 7:50 | **Posts fire**: Zealova X thread (transformation/UI — biggest Zealova post of week) + Ultraviolet LinkedIn #1 + Hireable X tweet auto (11am) → 5 min check |
| 8:00 | Day job |
| 12:00 | **Mobiprompt Reddit post #2 live** (r/PromptEngineering) + comment on 5 r/sideproject posts (15 min) |
| 12:15 | Lunch + **LazyApply bulk** (45 apps) |
| 12:50 | **Ultraviolet Reddit post live** (r/sideproject) + reply |
| 1:00 | Day job |
| 5:00 | **Pre-gym fresh-catch**: 10 apps |
| 5:30 | **GYM block (2 hr)** — 30 min drive · 60-75 min workout · 30 min drive home. Use commute: drive there = fitness/AI podcast · drive home = call wife OR voice-note content ideas |
| 7:30 | Shower + dinner with wife |
| 8:30 | Wife time |
| **9:00** | **Night bulk**: LazyApply 40 + 5 dream-tier tailored + **Mobi + Zealova engagement on phone in parallel**: 5 r/LocalLLaMA/r/OpenAI comments (Mobi) · 10 r/loseit/r/fitness comments (Zealova) · Zealova IG replies. **🎯 IN PARALLEL — 10 min:** `outreach-agent: "Follow up on this week's listicle pitches sent Wed"` (one-line nudge emails). |
| 10:15 | Wind down |
| 10:30 | Bed |

**Auto-drops today:** Hireable X auto 11am · Mobiprompt LinkedIn #2 (8am auto)
**Apps today:** ~115 (15 + 45 + 10 + 45)
**Social today:** Zealova X thread (7:50) · UV LI #1 (7:50) · Mobiprompt LI #2 (8am) · Hireable X auto (11am) · Mobiprompt Reddit #2 (12:00, live) · UV Reddit (12:50, live) · Mobi+Zealova night engagement (9pm, 30 min)
**GEO today:** Daily ritual + 9pm outreach followups

---

## §6.9 FRIDAY (non-gym)

| Time | What to do |
|---|---|
| 5:45 | Wake |
| 5:50 | Coffee with wife. **5-min GEO ritual:** `"Quick GEO status check"` → `geo-strategist` |
| 6:20 | **Job fresh-catch**: 15 apps |
| 6:50 | **Active build session (40 min)** |
| 7:30 | Shower |
| 7:50 | **Posts fire**: Zealova X tweet (weekend warm-up) + Ultraviolet X thread + Mobiprompt LinkedIn #2 (8am) → 5 min check |
| 8:00 | Day job |
| 12:00 | **Ultraviolet Reddit post #2 live** (r/webdev) + comment on 5 fitness creator IG + 5 AI builder X (15 min) |
| 12:15 | Lunch + **LazyApply bulk** (45 apps) |
| **12:50** | **Zealova reply-to-trending live** on X — find viral fitness post, drop Zealova POV (2 min live). **Optional:** `reddit-agent: "Find a viral fitness X or Reddit post from today and draft my Zealova POV reply"` (run in background while you eat). |
| 1:00 | Day job |
| 5:00 | **Evening fresh-catch + bulk (1.5 hr)**: 40 apps |
| 6:30 | **DATE NIGHT** with wife — phone away, no laptop |
| 10:30 | Bed |

**Auto-drops today:** Zealova IG carousel 11am · UV X auto 2pm · Hireable X auto 4pm
**Apps today:** ~100 (15 + 45 + 40, no night bulk — date night)
**Note:** Build session moved to weekend since 5pm slot expanded for apps. Friday = no active build.
**Social today:** Zealova X tweet (7:50) · UV X thread (7:50) · Mobi LI #2 (8am) · Zealova IG carousel (11am) · UV X auto (2pm) · Hireable X auto (4pm) · UV Reddit #2 (12:00, live) · Zealova reply-trending live (12:50)
**GEO today:** Daily ritual + 12:50 reply-to-trending (Reddit-or-X)

---

## §6.10 SATURDAY (gym + cleaning day)

| Time | What to do |
|---|---|
| 6:45 | Wake, breakfast with wife. **5-min GEO ritual:** `"Quick GEO status check"` → `geo-strategist` |
| 7:30 | **Zealova post fires** on X (Saturday peak day) + **UV LinkedIn #2 fires** (9am auto) → 10 min reply boost (comment on 5 r/loseit posts too) |
| 7:45 | **GYM block (2.5 hr)** — 30 min drive · 90 min biggest session of week · 30 min drive home. Commute use: drive there = high-energy music / Zealova competitor research · drive home = call wife or content voice-notes |
| 10:15 | Shower, food |
| 11:00 | **CLEANING DAY** (1.5 hr — apartment deep-clean, with wife) |
| 12:30 | Lunch with wife |
| 1:30 | **Job apps block (1.5 hr)**: 75 weekend apps (fresh Sat postings — LinkedIn "Past 24h" + LazyApply bulk) |
| 3:00 | **REEL RECORDING + EDIT (2 hr)** — Week 6+ steady state: shoot 3 app-demo Reels (1 hr) + edit all 3 in CapCut (1 hr). Cal AI external-camera technique. |
| **5:00** | **Zealova Reddit post #2 live** (r/getmotivated OR r/Fitness Saturday self-promo, 10 min). **Fire:** `reddit-agent: "Draft my <sub-name> Saturday post for tonight"` (5 min before posting). |
| 5:10 | Wife time — outdoors, errands, dinner prep |
| 6:30 | Wife evening |
| 10:30 | Bed |

**Apps today:** ~75 (down from 150 to make room for Reel block)
**Reels today:** 3 recorded + edited (cross-post Sunday batch)
**Social today:** Zealova X tweet (8am, peak Sat) · UV LI #2 (9am auto) · Zealova r/loseit engagement (10 min) · Zealova Reddit #2 (5:00pm, live, agent-drafted)
**GEO today:** Daily ritual + 5pm Reddit Saturday post (agent-drafted)

---

## §6.11 SUNDAY — keystone batch (CREATE & SCHEDULE all week's posts) + **GEO CONTENT BLOCK** + big build block + weekend apps

| Time | What to do |
|---|---|
| 6:00 | Wake, coffee. **5-min GEO ritual:** `"Quick GEO status check"` → `geo-strategist` |
| 6:30 | **GYM block (2 hr)** — 30 min drive · 60 min mobility + cardio · 30 min drive home |
| 8:30 | Shower, breakfast with wife |
| 9:30 | **POST CREATION + SCHEDULING — see breakdown below** (2h 15m Phase 1-2, 2h 30m Phase 3+) |
| 11:45 | **Job-search planning** (30 min): refresh resume variants, set LazyApply filters, list 25 dream companies |
| 12:15 | **Background agent task specs** (15 min): write 1+ task spec per app |
| 12:30 | Lunch with wife |
| **1:00** | **🎯 GEO CONTENT BLOCK (Sun) — 2 hr total:** see §6.12 breakdown |
| 3:00 | **Active build big block (2 hr — reduced from 3 since 1 hr was carved for GEO)** — pick 1-2 apps that need it most |
| 5:00 | **Job apps Block 1 (1 hr)**: 50 apps |
| 6:00 | **Job apps Block 2 (1 hr)**: 50 apps |
| 7:00 | Meal prep compressed |
| 6:30 | Wife dinner + evening |
| 9:30 | **5-min weekly review**: hit 600+ apps? each app touched? comparison page shipped? listicle pitches sent? all posts scheduled? |
| 10:00 | Bed |

**Posts today:** Founder X reflection 8am · LinkedIn long-form 11am (rotates: Hireable / Mobiprompt / Ultraviolet)
**Apps today:** ~100 (50 + 50)
**Build today:** 2 hr (1 hr carved for GEO content block)
**Social today:** Founder X reflection (8am) · LinkedIn long-form (11am, rotates dev app)
**GEO today:** Daily ritual + Sunday batch (drafted via social-post-creator) + **GEO content block (comparison page + blog) — see §6.12**

---

## §6.12 Sunday GEO content block — 1:00–3:00 PM (2 hr)

This is the most important GEO time of the week. It ships the comparison page (P2 pillar) and, in Phase 3+, a blog post (A8 accelerant).

### Phase 1-2 (weeks 1-8) — 2 hr

| Time | Activity | Agent + prompt |
|---|---|---|
| 1:00-1:30 | Refresh competitor intel for this week's `/vs/` target | `competitor-intel: "Profile <competitor>"` OR `"Refresh the <competitor> profile if >30 days old"` |
| 1:30-3:00 | Write the week's comparison page (1,500-2,500 words + TSX scaffold) | `comparison-page-writer: "Write the /vs/<competitor> page"` — scaffolds `frontend/src/pages/vs/<Name>.tsx` + registers route |

### Phase 3+ (weeks 9+) — 2 hr split

| Time | Activity | Agent + prompt |
|---|---|---|
| 1:00-1:30 | Comparison page intel refresh (every other week now — P2 cadence drops to 1 page every 2 weeks once 12 pages exist) | `competitor-intel: "Refresh <competitor>"` |
| 1:30-2:30 | **Blog post (A8)** — write OR refresh OR syndicate (rotate: Wk N = write, Wk N+1 = syndicate to Medium, Wk N+2 = refresh top 5) | `blog-writer: "What should I blog about this week?"` then `"Write a data post on <topic>"` (scaffolds TSX) — OR `blog-writer: "Syndicate the <slug> post to Medium"` — OR `blog-writer: "Refresh the <slug> post"` |
| 2:30-3:00 | Quora answers (A4) — draft 2 answers | `quora-and-forum-agent: "Find 5 Quora questions to answer this week"` then `"Draft an answer for question #1"` |

**Why Sunday for blog + comparison:** uninterrupted 2-hour blocks happen nowhere else in the week. Deep content needs deep time.

---

## §6.13 Sunday Post Creation + Scheduling — 9:30 AM batch

Now agent-driven via `social-post-creator`. The agent runs WebSearch for current platform algos + trending hooks before drafting each post.

### Phase 1-2 (Weeks 1-4) — 2h 15m

| Time | Create | Agent prompt | Schedule into |
|---|---|---|---|
| 9:30-10:00 | **Zealova** (7 X posts + 2 Reddit drafts + 3 IG carousels) | `social-post-creator: "Write Zealova's weekly social pack — 7 X posts, 2 Reddit drafts, 3 IG carousels"` | (collect) |
| 10:00-10:40 | **Hireable** (2 LinkedIn + 1 X tweet + 1 X auto + 2 Reddit drafts) | `social-post-creator: "Write Hireable's weekly social pack"` | (collect) |
| 10:40-11:20 | **Mobiprompt** (2 LinkedIn + 1 X thread + 1 X auto + 2 Reddit drafts) | `social-post-creator: "Write Mobiprompt's weekly social pack"` | (collect) |
| 11:20-11:50 | **Ultraviolet** (2 LinkedIn + 1 X thread + 1 X auto + 2 Reddit drafts) | `social-post-creator: "Write Ultraviolet's weekly social pack"` | (collect) |
| 11:50-12:05 | **Founder** (Wed X thread + Sun reflection draft for next week) | `social-post-creator: "Write founder Wed thread + next Sun reflection"` | (collect) |
| **12:05-12:25** | — | — | **Queue X + LinkedIn → Typefully** · **Queue IG carousel + 3 Reels → Meta Business Suite** (Mon/Wed/Fri 11am) · **Manual upload 3 Reels to TikTok @zealova + YouTube Shorts @zealova** · **Save Reddit drafts → Notion** |
| 12:25-12:30 | Engagement targets list (5 fitness creators, 3 indie founders, target subreddits) | manual | — |

### Phase 3+ (Week 5 onward) — 2h 30m
Same as above + 30 min for additional carousels and videos (see §8).

---

# PART 7 — PER-APP SOCIAL MAP

## §7. By app (search by name)

### §7.1 Zealova social (15+ posts/wk including 3 Reels)

| Day | Time | Action | Platform | Type | Agent prompt |
|---|---|---|---|---|---|
| Mon | 7:50am | X thread (fitness myth-bust) | X | Post (auto) | (drafted Sun via `social-post-creator`) |
| Mon | 11:00am | **Reel #1** (app demo, Cal AI style) | IG + TikTok + YT Shorts | **Reel (auto IG, manual TT/YT)** | (drafted Sat) |
| Mon | 12:50pm | X single tweet (stat/hook) | X | Post (auto) + reply | (drafted Sun) |
| Tue | 7:50am | X tweet (fitness tip) | X | Post (auto) | (drafted Sun) |
| Tue | 12:50pm | Reddit post (r/loseit OR r/fitness biweekly) | Reddit | Post (live) | `reddit-agent: "Draft today's r/loseit or r/fitness Zealova post"` |
| Wed | 11:00am | **Reel #2** (stat/hook with Veo b-roll OR screen recording) | IG + TikTok + YT Shorts | **Reel** | (drafted Sat) |
| Wed | 12:50pm | X screenshot/UI tease tweet | X | Post (auto) + reply | (drafted Sun) |
| Thu | 7:50am | X thread (transformation/UI — biggest of week) | X | Post (auto) | (drafted Sun) |
| Thu | 9:00pm | 10 r/loseit/r/fitness engagement + IG/TikTok replies | Reddit + IG + TikTok | Engagement | `reddit-agent: "Draft replies to these 3 threads"` (paste URLs) |
| Fri | 7:50am | X tweet (weekend warm-up) | X | Post (auto) | (drafted Sun) |
| Fri | 11:00am | **Reel #3** (app demo, different angle than Mon) | IG + TikTok + YT Shorts | **Reel** | (drafted Sat) |
| Fri | 12:50pm | Reply-to-trending fitness post | X | Post (live, 2 min) | `reddit-agent: "Find a viral fitness X post and draft my Zealova POV reply"` |
| Sat | 8:00am | X tweet (Saturday peak day) | X | Post (auto) + 10 min reply boost | (drafted Sun) |
| Sat | 5:00pm | Reddit post #2 (r/getmotivated OR r/Fitness Saturday) | Reddit | Post (live) | `reddit-agent: "Draft my r/getmotivated OR r/Fitness Saturday self-promo for tonight"` |

**Zealova weekly totals (Week 6+ steady state):** 7 X posts · 2 Reddit posts (agent-drafted) · 3 Reels · 1 IG carousel · ~75 min engagement on others

### §7.2 Hireable social (6 posts/wk)

| Day | Time | Action | Platform | Type |
|---|---|---|---|---|
| Mon | 7:50am | LinkedIn post #1 (builder questions on HR pain) | LinkedIn | Post (auto) |
| Mon | 12:00pm | Reddit post #1 (r/indiehackers) | Reddit | Post (live) |
| Mon | 2:00pm | X tweet (auto) | X | Post (auto) |
| Tue | 11:00am | X tweet (auto) | X | Post (auto) |
| Tue | 9:00pm | 5 LinkedIn comments on HR/recruiter posts (no DMs, questions only) | LinkedIn | Engagement (15 min) |
| Wed | 7:50am | X tweet (job-search hack) | X | Post (auto) |
| Wed | 8:00am | LinkedIn post #2 | LinkedIn | Post (auto) |
| Wed | 12:00pm | Reddit post #2 (r/cscareerquestions) | Reddit | Post (live) |
| Fri | 4:00pm | X tweet (auto) | X | Post (auto) |
| Sun | 11:00am | LinkedIn long-form (1/3 weeks) | LinkedIn | Post (auto) |

### §7.3 Mobiprompt social (7 posts/wk)

| Day | Time | Action | Platform | Type |
|---|---|---|---|---|
| Mon | 11:00am | X tweet (auto) | X | Post (auto) |
| Tue | 7:50am | X thread (prompt engineering tip) | X | Post (auto) |
| Tue | 8:00am | LinkedIn post #1 | LinkedIn | Post (auto) |
| Tue | 12:00pm | Reddit post #1 (r/ChatGPT) | Reddit | Post (live) |
| Wed | 4:00pm | X tweet (auto) | X | Post (auto) |
| Thu | 8:00am | LinkedIn post #2 | LinkedIn | Post (auto) |
| Thu | 12:00pm | Reddit post #2 (r/PromptEngineering) | Reddit | Post (live) |
| Thu | 9:00pm | 5 r/LocalLLaMA/r/OpenAI comments | Reddit | Engagement (10 min) |
| Fri | 8:00am | LinkedIn post (Mobi LI #2 alt) | LinkedIn | (if not Thu) |
| Fri | 12:00pm | 5 AI builder X comments (@levelsio, @swyx, etc.) | X | Engagement (5 min) |
| Sun | 11:00am | LinkedIn long-form (1/3 weeks) | LinkedIn | Post (auto) |

### §7.4 Ultraviolet social (6 posts/wk)

| Day | Time | Action | Platform | Type |
|---|---|---|---|---|
| Tue | 3:00pm | X tweet (auto) | X | Post (auto) |
| Tue | 9:00pm | 5 LinkedIn comments on dev/PM posts | LinkedIn | Engagement (share with Hireable, 15 min) |
| Wed | 2:00pm | X tweet (auto) | X | Post (auto) |
| Thu | 7:50am | LinkedIn post #1 (dev tool angle) | LinkedIn | Post (auto) |
| Thu | 12:00pm | 5 r/sideproject comments | Reddit | Engagement (5 min) |
| Thu | 12:50pm | Reddit post #1 (r/sideproject) | Reddit | Post (live) |
| Fri | 7:50am | X thread (build update) | X | Post (auto) |
| Fri | 12:00pm | Reddit post #2 (r/webdev or relevant) | Reddit | Post (live) |
| Fri | 2:00pm | X tweet (auto) | X | Post (auto) |
| Sat | 9:00am | LinkedIn post #2 | LinkedIn | Post (auto) |
| Sun | 11:00am | LinkedIn long-form (1/3 weeks) | LinkedIn | Post (auto) |

### §7.5 Founder personal social (2 posts/wk)

| Day | Time | Action | Platform |
|---|---|---|---|
| Wed | 7:50am | X thread (PEAK day) — lessons across all 4 apps | X |
| Sun | 8:00am | X reflection thread — MRR / shipped features / build progress | X |

### §7.6 Post count per product per week

| Product | Posts/wk | Where |
|---|---|---|
| Zealova | 15+ | 7 X + **3 Reels × 3 platforms (= 9 video impressions)** + 1 IG carousel + 2 Reddit + reply-trending |
| Hireable | 6 | 2 LI + 2-4 X + 2 Reddit |
| Mobiprompt | 6 | 2 LI + 2-3 X + 2 Reddit |
| Ultraviolet | 6 | 2 LI + 2-4 X + 2 Reddit |
| Founder | 2 | 2 X (Wed + Sun) |
| **Total** | **~35 posts + 3 Reels/wk** | All created + scheduled Sunday; Reels recorded Saturday 2:30-4:30 |

---

# PART 8 — REELS + CAROUSEL STRATEGY

## §8. Cal AI playbook, post-launch

**Research basis:** Cal AI (faceless AI fitness app, direct Zealova analog) grew **0 → $1M MRR in 34 days, 100K downloads in 4 months**, acquired by MyFitnessPal March 2026. Their playbook: faceless app-demo Reels on TikTok + IG, NO carousels-as-primary.

**Algorithm reality (Sprout/Hootsuite/Later 2026):**
- Reels reach: **1.36× carousels, 2.25× static photos**
- Carousels-only B2C fitness ceiling: ~30-50K followers
- Mixed format (Reels + Carousels) grows **2.5× faster** than carousel-only
- <2 Reels/wk = shadowban hell. 3 Reels/wk = baseline. 5-7/wk = optimum cold-start growth

### §8.1 Reel cadence (post-launch — Week 4 onward)

| Week | Reels/wk | Carousels/wk | Notes |
|---|---|---|---|
| **Week 4** (re-entry after launch) | 1 | 2 | Familiarize with Cal AI shoot format |
| **Week 5** | 2 | 1 | Add second weekly Reel + cross-post |
| **Week 6+** | **3** | **1** | Steady state. 3 Reels Mon/Wed/Fri + 1 carousel Sun |

### §8.2 Reel formats — ranked by install ROI for fitness apps (2026 data)

| Rank | Format | Why for Zealova | Time per Reel |
|---|---|---|---|
| **#1** | **External-camera app demo** (Cal AI style: hand + real-world + phone showing Zealova) | Looks like UGC; algo treats as "real content"; install conversion highest | 15-20 min shoot + edit |
| #2 | Stat / hook Reel with stock or AI b-roll | "70% of fitness apps fail at week 2" + Veo 3 fitness footage | 15 min |
| #3 | Pure screen recording of Zealova UI | Use for feature highlight reels; ~30% of mix (not primary) | 10 min |
| #4 | Slideshow Reel (Canva auto-video) | Convert carousels → animated 15-sec videos in 1 click | 5 min |
| #5 | AI-generated b-roll only (Veo 3.1) | Hooks only, NOT product demos | 15 min |
| **AVOID** | AI avatar (HeyGen / D-ID) | Users smell the AI in 2026 — trust collapse | — |

### §8.3 External-camera technique (Cal AI signature)

Camera A (mounted/propped) films Camera B (your phone) doing Zealova app stuff in real-world context:
- **At the gym**: hand + phone showing today's workout → cut to barbell on floor
- **At meal time**: hand + phone meal-log feature → cut to plate on counter
- **At bedtime**: hand + phone showing tomorrow's plan → cut to laid-out gym clothes
- **Pure UI moment**: thumb scrolling Zealova features quickly, ambient sound

All faceless, all bodyless (hand only), all 5-15 seconds.

**Why external > pure screen recording:** algo detects "real" content, +25-50% reach. Cal AI did ~70% external camera, ~30% screen recording.

### §8.4 Cross-post strategy

| Platform | Account | Method |
|---|---|---|
| Instagram Reels | @getzealova | Auto-schedule via Meta Business Suite |
| TikTok | @zealova | Manual upload (TikTok native scheduler exists for business accounts) |
| YouTube Shorts | @zealova | Manual upload |

**TikTok is the #1 platform for B2C fitness app installs in 2026** (Cal AI proof). Don't skip it.

### §8.5 Tool stack (post-launch additions)

| Tool | Use | Cost |
|---|---|---|
| **CapCut** | Mobile/desktop Reel editing | Free |
| **QuickTime** (Mac) or built-in screen recorder | Pure screen-record Reels | Free |
| **Phone tripod** ($10-15) | External-camera setup | One-time |
| **Veo 3.1 Fast** | AI b-roll for stat/hook Reels | $20/mo (add at Week 6+ only) |
| **Canva Pro** | Auto-video conversion from carousels | $15/mo |

**Total post-launch additional monthly cost: $20-35/mo** (on top of $19/mo Typefully).

### §8.6 Realistic 90-day growth projection (post-launch, 3 Reels/wk)

| Milestone | Timeline |
|---|---|
| 3 → 1K followers | 30-60 days |
| 1K → 10K | 3-6 months |
| First 200-800 app installs from social | If ONE Reel breaks 100K views (possible in 4-12 weeks) |

Cal AI's curve: **one viral demo Reel changes the trajectory.** Cadence exists to roll the dice 12-15 times/month.

### §8.7 Saturday 2:30-4:30 PM = video recording block (post-launch)

This block was already reserved. Convert it to weekly Reel batch recording:
- 2:30-3:30: shoot 3 app-demo Reels in one session
- 3:30-4:30: edit all 3 in CapCut (9:16 vertical, captions, trending audio)
- Sunday batch adds 15 min for uploads to MBS + TikTok + YouTube Shorts

**Total weekly video time: ~2h 15m**.

---

# PART 9 — TARGETS, METRICS, ANTI-PATTERNS

## §9.1 Concrete GEO targets (locked, refreshed quarterly)

### Competitors to name in comparison pages

**Canonical matrix lives in `.claude/agents/marketing/_ZEALOVA_FACTS.md` §4** (refreshed quarterly by `competitor-intel`). Zealova competes in 4 categories — pick the right one per page:

**4A Workout AI** (priority — biggest search volume):
1. **Fitbod** ($12.99/mo) — #1 search volume, default listicle entry
2. **Future** ($199/mo) — premium price wedge (1/25 cost)
3. **Freeletics** (~$80/yr) — bodyweight/HIIT
4. **Caliber** (~$29-200/mo) — AI + human hybrid
5. **FitnessAI** ($89/yr) — single-model AI
6. **Gravl** ($10.99/mo or $59.99/yr) — AI strength + Strength Score
7. **Dr. Muscle / Alpha Progression** — RIR programming
8. **Centr / Nike Training Club / Ladder** — celebrity-brand competitors
9. **Trainiac** — hybrid AI + human coach

**4B Workout tracking** (huge user bases, "we generate vs they log" wedge):
10. **Hevy** (Free / Pro $2.99-9.99/mo) — fast logging, social feed
11. **Strong** — minimalist logger
12. **JEFIT** (Free / Pro $12.99/mo) — 12M users, largest exercise DB
13. **Boostcamp** ($4.99/mo annual) — programs + tracker hybrid

**4C Nutrition / calorie** (Zealova's screenshot OCR + food logging competes here):
14. **MyFitnessPal** (Free / Premium $79.99/yr / Premium+ $99.99/yr) — 280M users, **acquired Cal AI March 2026** — pivotal competitor
15. **MacroFactor** ($5.99-11.99/mo) — superior macro algorithm; concede + win on breadth
16. **Cronometer** (Free / Gold $4.99/mo annual) — micronutrient gold standard; concede + win on AI coach
17. **Cal AI** (~$30/yr, MFP-acquired) — direct food-photo AI competitor
18. **Lose It!** (Free / Premium ~$39.99/yr) — Snap It AI in Premium
19. **Noom** ($70/mo or $209/yr) — psychology / human coaching
20. **Lifesum**, **YAZIO**, **FatSecret**, **MyNetDiary**, **PlateLens**, **Foodvisor**, **Carbon Diet Coach** — broader nutrition landscape

**4D AI form analysis** (direct lookalikes):
21. **Sculptor** — AI rep counter + form analysis
22. **Gymscore** — AI form scoring

### Listicle targets (P1 — top 30, refreshed weekly by `outreach-agent`)
Arvo · SensAI · MakeUseOf · Unite.ai · The Manual · GetFit AI · IndieHackers GEO posts · Welling · Medigy · Tom's Guide app roundups · AppAdvice · MacStories · Lifehacker app guides · Android Authority · 9to5Mac/9to5Google · ZDNet wellness · TechRadar fitness apps · PCMag fitness apps · Wirecutter (long-shot) · Health Reporter · NerdWallet wellness tools · Engadget · The Verge app reviews · MindBodyGreen · Self.com tech roundups · Women's Health app picks · Men's Health gear · Gear Patrol · BarBend.

Stored in `marketing/outreach/listicles.md`.

### Subreddit targets (P3)
**Primary (weekly engagement):** r/Fitness · r/xxfitness · r/bodyweightfitness · r/loseit · r/HomeGym · r/IntermittentFasting
**Builder audience (LLM-cite-heavy):** r/IndieHackers · r/SideProject · r/SaaS · r/FlutterDev · r/iOSProgramming · r/ChatGPT · r/singularity · r/ArtificialIntelligence
**Discovery / launch:** r/AppHookup · r/iOSApps · r/AndroidApps

Per-sub rules cached in `marketing/reddit/sub-rules.md`.

### Tier-1 review sites (Phase 3+)
Tom's Guide (highest priority — OpenAI content deal) · TechRadar · CNET · The Verge · Engadget · MakeUseOf · Android Authority · 9to5Mac · 9to5Google · AppAdvice · MacStories · Lifehacker · PCMag · ZDNet · Wirecutter.

## §9.2 Metrics — what to track (monthly)

Stored in `marketing/citations/tracker.md` by `citation-tracker`.

| Metric | How measured | Target by month 6 |
|---|---|---|
| ChatGPT mentions for "best AI fitness app" | Manual query, monthly | Appears in 1+ list |
| ChatGPT mentions for "Fitbod alternative" | Manual query, monthly | Appears in 1+ list |
| Claude.ai recommendations | Manual query, monthly | Appears occasionally |
| Gemini AI Overview inclusion | Search "best AI workout app" in Google | Cited once |
| Listicle inclusions | Manual count | 8+ |
| Comparison pages indexed | `site:zealova.com/vs` | 12 |
| Reddit karma in target subs | Profile stats | 500+ |
| Branded search volume | Google Search Console + Ahrefs free | Trending up MoM |
| Backlinks earned (unique referring domains) | Ahrefs free / SE Ranking | 30+ |

**Hard rule:** No tactic survives a quarter without showing movement on at least one of these. `citation-tracker` flags 60+ day flat tactics for the doctrine §1 cut-or-double decision.

## §9.3 Anti-patterns — what NOT to do

- ❌ **Don't generic-fitness-blog.** Healthline owns SERP forever. `blog-writer` refuses by design.
- ❌ **Don't bypass `geo-strategist` Monday brief.** Skipping it = scattered week.
- ❌ **Don't fire `comparison-page-writer` before `competitor-intel`.** It will stop and ask anyway.
- ❌ **Don't mass-post the same link across multiple subs in one day.** Reddit algo flags.
- ❌ **Don't self-promote outside designated sub-threads.** r/Fitness = Saturday only. r/xxfitness = never link.
- ❌ **Don't write one-sided comparison pages.** LLMs penalize. Concede competitor strengths honestly.
- ❌ **Don't pitch `press@` at review sites.** Always a named staff writer.
- ❌ **Don't treat llms.txt and schema as growth levers.** They're hygiene. Drop in once, move on.
- ❌ **Don't pay GEO agencies before month 4.** Spend nothing until P1-P3 are running.
- ❌ **Don't layer accelerants (Quora, blog, YouTube) in Phase 1.** They start Phase 3 (week 9+).
- ❌ **Don't accept agent output without a Research log block.** That means WebSearch was skipped — re-fire.
- ❌ **Don't run the same agent twice in one day on the same topic.** Second run reads its own draft and produces mush.
- ❌ **Don't edit output files manually.** Leave a `<!-- HUMAN EDIT YYYY-MM-DD -->` marker if you must.

## §9.4 Reality check — timeline

| Month | What's measurable |
|---|---|
| 1 | 4 comparison pages indexed, Reddit identity warm, 15 listicle pitches sent. Zero LLM lift yet. |
| 2 | 1-2 listicle inclusions land. Brand search volume tick-up. |
| 3 | 5-7 listicle inclusions, 8 comparison pages, Reddit karma 200+. ChatGPT mentions on narrow queries (~10%). |
| 4-6 | Accelerants compound. ChatGPT mentions broader queries (~20%). Gemini AI Overviews start citing. |
| 6-12 | Top-5 LLM recommendation for at least one segment. |

HubSpot/UltraScout average for measurable GEO lift: **89 days.** Anyone promising faster is lying.

---

# PART 10 — ACCOUNTS, TOOL STACK, WEEKLY TOTALS

## §10.1 Weekly totals (life-wide)

| Bucket | Hours |
|---|---|
| Sleep | ~52 |
| Day job | 45 |
| Job apps (~625-825/wk) | ~16 |
| Active build (vibe-coding across 4-app pool) | ~10 (1 hr carved for GEO content Sun) |
| **GEO content (comparison + blog + Quora Sun + Mon strategist + Wed outreach)** | **~3.5-4.5** |
| Saturday cleaning | 1.5 |
| Gym + commute (2 hr × 4 days) | 8 |
| Content creation + scheduling + engagement (incl. 2 hr Sat Reel block + 20 min Sun video uploads) | ~8 |
| Wife time | ~10 |
| Meals/shower/transition | ~12 |
| **Total** | **~165 / 168** |

**Slack: ~3 hr/wk** for sickness, friends, life. Tight.

## §10.2 Gym commute productivity

Each 30-min drive (60 min/gym day = 4 hr/wk total) is dead time you can use:

| Direction | Use |
|---|---|
| **Drive TO gym** | Audio: fitness podcasts (Zealova research) · AI/dev podcasts (Mobiprompt + UV) · indie hacker podcasts (Hireable + founder ideas) |
| **Drive HOME from gym** | **Call wife** (sneaky wife time) · Voice-note content ideas into Otter.ai or Apple Notes (becomes Sunday batch fuel) · Reply to LinkedIn DMs via voice |

**Worth ~3-4 extra hr/wk** of productive time that doesn't take from any other block.

---

## CHANGELOG

- **2026-05-12** — v2.0. Merged prior `GEO_PLAN.md` + `AGENTS.md` into this single canonical doc. Added explicit agent-command rows to every weekday slot. Carved a 2-hr Sunday GEO content block for comparison pages (Phase 1-2) and blog work (Phase 3+). Added Mon 9pm `geo-strategist` weekly anchor and monthly `citation-tracker` snapshot. Added 5-min daily ritual at coffee-with-wife time.
- **2026-05-07** — v1.x — original weekly schedule + initial GEO plan separated.

**Next review:** 2026-06-12 (alongside monthly citation snapshot).
