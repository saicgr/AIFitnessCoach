# AGENTS.md — Zealova Marketing Agent Reference

> **This is the agent-reference-only view.** Daily schedule with agent commands at exact times lives in `WEEKLY_SCHEDULE.md` (canonical master). Strategy lives in `GEO_PLAN.md`. This doc is the per-agent trigger menu and hand-off rules.

---

## §0. The one rule

> **Every agent runs live `WebSearch` + `WebFetch` before drafting. No exceptions. No cached knowledge.**

If an agent produces output without a Research log block (3-8 source URLs with one-line findings), it skipped the search step — re-fire it.

---

## §1. Folder structure

```
.claude/agents/
├── engineering/   ← 8 code/infra agents
└── marketing/     ← 12 agents grouped by function
    ├── _OUTPUT_STANDARD.md          ← shared 3-section preamble standard ALL agents follow
    ├── _ZEALOVA_FACTS.md            ← canonical Zealova facts (features, pricing, wedges, banned phrases)
    ├── strategy/
    │   ├── geo-strategist.md        ← weekly orchestrator
    │   ├── citation-tracker.md      ← monthly LLM-mention snapshots
    │   └── market-research-expansion.md  ← quarterly competitive landscape
    ├── research/
    │   ├── keyword-researcher.md    ← search volume + SERP + PAA
    │   └── competitor-intel.md      ← per-competitor deep dives
    ├── content/
    │   ├── comparison-page-writer.md  ← /vs/*.tsx scaffolds + markdown drafts
    │   ├── blog-writer.md            ← /blog/*.tsx scaffolds + Medium syndication
    │   └── quora-and-forum-agent.md  ← Quora + T-Nation / BB.com / MFP
    ├── community/
    │   ├── reddit-agent.md          ← scout + write + rules (pillar P3 — outbound)
    │   ├── reddit-analyzer.md       ← analyze pasted threads / screenshots / URLs (inbound intel)
    │   ├── reels-producer.md        ← shot list + repurpose + log + monthly perf
    │   └── social-post-creator.md   ← LinkedIn / X / IG / TikTok captions
    ├── outreach/
    │   ├── outreach-agent.md        ← listicle / review-site / YouTube pitches (pillar P1 — written press)
    │   └── creator-outreach.md      ← IG + TikTok UGC creators <80K — find + draft anti-bot DMs + retainers (Cal AI playbook)
    └── conversion/
        ├── aso-optimizer.md          ← App Store + Play Store + onboarding optimization (Phase 0 audit + monthly check)
        └── ad-creator.md             ← Meta / TikTok / Reddit / YouTube / Google ad creative (Phase 3+ only, NEVER before)
```

**The `_OUTPUT_STANDARD.md` + `_ZEALOVA_FACTS.md` pair is the most important set of files in this folder.** Every agent's body now includes a footer pointing to both:

- `_OUTPUT_STANDARD.md` mandates the **three-section preamble** (current trends → why they matter → what I'm generating) on every run, so reasoning is visible.
- `_ZEALOVA_FACTS.md` mandates **Zealova-grounding** — every output references *actual* Zealova features (multi-agent chat, form video analysis via Gemini Vision, screenshot calorie OCR, $7.99/mo or $59.99/yr, iOS + Android), not generic "AI fitness app" placeholder content. The facts file lists what we DO have, what exists but isn't shipped, and what we explicitly DON'T have (no HIPAA, no human coaches, no live form analysis, no wearable app). Agents reading this file before drafting can't accidentally invent features or claim wedges that don't exist. The standard mandates a 3-section preamble on every run:

1. **§1 Current trends** — live researched, two layers: (a) platform/channel-specific trends from the last 7 days with sources, (b) fitness-industry trends from the last 7-30 days with sources
2. **§2 Why these matter for THIS output** — each trend explicitly translated into a decision arrow
3. **§3 What I'm generating because of the above** — the output justified, traceable back to §2

This is what the user sees first in every agent reply. The actual draft follows. Reasoning is visible, not buried in URL footers.

```
docs/planning/marketing/   ← append-only agent output
├── reddit/{posts.md, sub-rules.md}
├── blogs/{posts.md, ideas.md}
├── medium/posts.md
├── comparison-pages/posts.md
├── quora/answers.md
├── outreach/{listicles.md, review-sites.md, youtube-creators.md}
├── keywords/research.md
├── competitors/intel.md
├── reels/{shot-lists.md, posted-log.md, performance.md}
├── reddit/{posts.md, sub-rules.md, analysis-log.md}
├── creators/{log.md, sent.md, rate-card.md}
├── aso/{audits.md, changelog.md, screenshot-specs.md}
├── ads/{campaigns.md, creative.md, performance.md}
├── feature-ideas/log.md                                ← build-it-now signals from competitors + users + new AI capabilities
├── landscape/YYYY-MM-DD.md                              ← NEW: full daily-status landscape (18 sections per day, agent writes file; chat returns summary + file path)
└── citations/tracker.md
```

```
frontend/src/pages/        ← deployable React pages (auto-scaffolded)
├── blog/<PascalSlug>.tsx
├── vs/<Competitor>.tsx
├── alternatives/<Slug>.tsx
└── best/<Segment>.tsx
```

Nested folders are organizational. Agents are invoked by `name:` frontmatter, not path.

---

## §2. Per-agent trigger menus

### §2.1 `geo-strategist` — weekly orchestrator
**Fires:** Mon 9:00 PM. Daily 5-min status check at coffee time.

```
"Run the weekly GEO cadence"
"What should I work on this week?"
"I have 60 minutes — what's most leveraged?"
"Are we on track? Diff planned vs shipped"
"60-day flat tactics — should we drop any?"
"Quick GEO status check — anything urgent today?"  ← daily 5-min ritual
```

### §2.2 `keyword-researcher`
**Fires:** Before any comparison page / blog; weekly refresh.

```
"Find the top keywords for the /vs/fitbod page"
"What do people search for around AI form analysis?"
"Long-tail variants of 'Fitbod alternative'"
"PAA questions for 'best AI fitness app'"
"Reddit thread frequency for 'form check app' across target subs"
"What's the search volume for 'cheap AI fitness coach'?"
```

### §2.3 `competitor-intel`
**Fires:** Before `comparison-page-writer`; monthly refresh.

```
"Profile Fitbod"
"Deep-dive on Future's pricing changes past 90 days"
"What are users saying about Sculptor on Reddit?"
"Refresh the Fitbod profile — last updated 60 days ago"
"List 5 weaknesses of Future we should highlight (honestly)"
"Compare Fitbod's and Caliber's onboarding flows"
```

### §2.4 `reddit-agent` (pillar P3)
**Fires:** 5-7×/week across daily slots.

**Scout:**
```
"Find 3 Reddit threads I should engage with this week"
"What's hot in r/IndieHackers this week?"
"Find recent 'Fitbod alternative' threads"
"Scout r/xxfitness for AI-fitness questions"
"Find 2 threads in target subs I should reply to tomorrow"
```

**Write — reply to thread URL:**
```
"Reply to this thread for me: <URL>"
"Someone asked about AI form-check apps in r/Fitness: <URL>. Draft my answer"
"This thread is high-engagement: <URL>. Draft a 200-word comment"
```

**Write — reply to comment / DM:**
```
"Draft my reply to: 'How is this different from Fitbod?'"
"Someone is skeptical: 'AI can't really tell if my form is wrong, can it?'"
"Reply to this DM: '<text>'"
```

**Write — top-level posts:**
```
"Draft a top-level post for r/IndieHackers about the Gemini multi-agent architecture"
"Write my r/Fitness Saturday self-promo post"
"Draft a Show-HN-style post for r/SideProject announcing v1.2"
"Help me prep an AMA in r/SaaS — draft post + 10 Qs with answers"
"Write a launch post for r/AppHookup with a promo code"
"Draft my r/loseit or r/fitness Zealova post for today"
"Draft my r/getmotivated Saturday post for tonight"
```

**Rules:**
```
"Can I post my app in r/loseit?"
"Refresh promo rules for r/Fitness"
"What's r/bodybuilding's current self-promotion policy?"
```

### §2.5 `comparison-page-writer` (pillar P2)
**Fires:** Sunday 10:00 AM-12:00 PM (carved time block). Scaffolds TSX into `/frontend/src/pages/vs/`.

```
"Write the /vs/fitbod comparison page"
"Draft a 'best Fitbod alternatives in 2026' page"
"Comparison page: Zealova vs Future, lean on price wedge"
"Write the /vs/sculptor page (form analysis competitor)"
"Draft a 'cheapest AI fitness coach' segment listicle"
"Refresh /vs/fitbod — check current Fitbod pricing"
"Markdown only (no scaffold): draft /vs/jefit"
"I want a 'Fitbod vs Freeletics vs Future' three-way comparison"
```

### §2.6 `blog-writer` (accelerant A8 — starts Phase 3 week 10)
**Fires:** Sunday 1:30-2:30 PM (Phase 3+). Scaffolds TSX into `/frontend/src/pages/blog/`. Refuses generic fitness tips.

**Topic ideation:**
```
"What should I blog about this week?"
"Give me 10 blog ideas tied to this-week's fitness trends"
"Ideate blog topics around our form-analysis feature"
"Suggest 5 data-rich posts I could write based on user data"
```

**Own-site (writes TSX + markdown):**
```
"Write a data-rich post on the most common squat form errors"
"Scaffold the blog page in the frontend for the squat-errors topic"
"Ship a blog post to the React app: 'How AI Form Analysis Actually Works'"
"Write a deep technical post on Zealova's multi-agent chat architecture"
"Draft a founder-tested benchmark: 'I tested 9 AI fitness apps for 30 days'"
"Glossary entry: 'What is RIR-based programming?' with FAQ schema"
"Markdown only: draft the squat errors post"
```

**Syndicate:**
```
"Syndicate the squat-errors post to Medium"
"Draft a Show HN version of the multi-agent post"
"Repost the form-analysis blog to dev.to"
"Make an IndieHackers founder-narrative version of the benchmark post"
```

**Refresh:**
```
"Refresh the squat-errors post — check if any stats shifted"
"Update /blog/best-fitbod-alternatives — last touched 90 days ago"
```

### §2.7 `quora-and-forum-agent` (A4/A5)
**Fires:** Phase 3+. Sunday 2:30-3:00 PM.

```
"Find 5 Quora questions I should answer this week"
"Scout T-Nation forums for AI-tool discussions"
"Draft a Quora answer for: <URL>"
"Answer this Quora question: 'Is Fitbod worth it in 2026?' — link: <URL>"
"Find MyFitnessPal community threads about calorie scanning"
"Write a T-Nation forum reply for this thread: <URL>"
```

### §2.8 `outreach-agent` (pillar P1; A6, A7)
**Fires:** Wed 12:00 PM (listicle); Thu 9:00 PM (followups); Phase 3+ for review-site / YouTube modes.

**Listicle:**
```
"Send 5 listicle pitches this week"
"Pitch the next 5 listicles on the target list"
"Find new 'best AI fitness app 2026' listicles published this past month"
"Follow up on last week's pitches"
"Draft a pitch to <site/writer name>"
"Pitch the writer behind <URL>"
```

**Review-site (Phase 3+):**
```
"Pitch Tom's Guide on Zealova"
"Find the current TechRadar staff writer covering fitness apps"
"Draft a pitch to <name> at CNET — they just reviewed Fitbod"
"Pitch The Verge on the multi-agent angle"
```

**YouTube (Phase 3+):**
```
"Find 3 YouTube fitness-tech creators (10-100K subs) to pitch"
"Pitch <creator name> for a comparison video"
"Find creators who've recently reviewed Fitbod or Future"
"Draft a YouTube outreach with affiliate offer"
```

**Status / followup:**
```
"<Name> replied — log and draft a followup"
"<Name> ghosted after 7 days — draft the final nudge"
"<Name> included us: <URL> — log and update citation tracker"
```

### §2.9 `citation-tracker`
**Fires:** 1st of each month after `geo-strategist` Mon 9pm call. Spot-checks on demand.

```
"Run the monthly citation snapshot"
"Spot check: are we mentioned for 'best AI fitness app' in Google AI Overview?"
"Compare this month's grid vs last month — what moved?"
"Any tactic flat 60+ days?"
"Baseline LLM mentions — we're starting from zero, take the snapshot"
```

### §2.10 `social-post-creator` (pre-existing)
**Fires:** Sunday 9:30 AM-12:05 PM (post-creation batch).

```
"Write Zealova's weekly social pack — 7 X posts, 2 Reddit drafts, 3 IG carousels"
"Write Hireable's weekly social pack"
"Write founder Wed thread + next Sun reflection"
"Draft a LinkedIn post about the AI coach feature"
"Tweak the X post — make it punchier"  ← Edit mode
```

### §2.11 `market-research-expansion` (pre-existing)
**Fires:** Quarterly.

```
"What features are competitors offering that we don't have?"
"Quarterly competitive landscape review"
"Should we build a social workout sharing feature? Research the market"
```

---

## §3. Hand-off chains

**Comparison page chain (Sun P2):**
```
keyword-researcher → competitor-intel → comparison-page-writer
```

**Blog chain (Sun Phase 3+):**
```
blog-writer (ideation) → keyword-researcher → blog-writer (own-site, scaffolds TSX)
→ 7 days later → blog-writer (syndicate)
```

**Reddit chain (daily):**
```
reddit-agent (scout) → reddit-agent (write thread #1) → reddit-agent (reply if responded)
```

**Outreach chain (Wed-Thu P1):**
```
outreach-agent (listicle Wed) → ...wait 7d... → outreach-agent (followup Thu) → citation-tracker (when inclusion lands)
```

**Strategy chain (Mon):**
```
geo-strategist → dispatches specialists for the week
```

---

## §4. Daily call reference (where to find exact times)

For exact day/time/duration of each agent call, see **`WEEKLY_SCHEDULE.md` §5** (master cadence table) and **§6** (daily schedule with agent commands embedded in each weekday row).

Quick-glance:

| Day/Time | Agent | Prompt |
|---|---|---|
| Daily 5:50 AM | `geo-strategist` | `"Quick GEO status check"` |
| Mon 9:00 PM | `geo-strategist` | `"Run the weekly GEO cadence"` |
| 1st Mon of month 9:15 PM | `citation-tracker` | `"Run the monthly citation snapshot"` |
| Tue 12:50 PM | `reddit-agent` | `"Draft today's r/loseit or r/fitness Zealova post"` |
| Tue 9:00 PM | `reddit-agent` (scout) | `"Find 2 threads in target subs for tomorrow"` |
| Wed 12:00 PM | `outreach-agent` | `"Send 5 listicle pitches this week"` |
| Wed 5:30 PM | `reddit-agent` (write) | `"Reply to highest-engagement thread from Tue scout"` |
| Thu 9:00 PM | `outreach-agent` | `"Follow up on this week's listicle pitches"` |
| Fri 12:50 PM | `reddit-agent` | `"Find a viral fitness post and draft Zealova POV reply"` |
| Sat 5:00 PM | `reddit-agent` | `"Draft my r/getmotivated OR r/Fitness Saturday post"` |
| Sun 9:30 AM | `social-post-creator` | `"Write <app>'s weekly social pack"` × 5 apps |
| Sun 1:00 PM | `competitor-intel` | `"Profile <competitor>"` |
| Sun 1:30 PM | `comparison-page-writer` | `"Write the /vs/<competitor> page"` |
| Sun 1:30 PM (Phase 3+) | `blog-writer` | `"What should I blog about?"` then `"Write <topic>"` |
| Sun 2:30 PM (Phase 3+) | `quora-and-forum-agent` | `"Find 5 Quora Qs"` + `"Draft answer #1"` |

---

## §5. Anti-patterns

- ❌ Bypassing Mon 9pm `geo-strategist` brief
- ❌ Firing `comparison-page-writer` before `competitor-intel`
- ❌ Mass-posting same link across subs same day
- ❌ One-sided comparison pages
- ❌ `press@` pitches (always named staff writer)
- ❌ Generic fitness blogs (refused by `blog-writer`)
- ❌ Accelerants in Phase 1 (they start Phase 3 wk 9+)
- ❌ Output without Research log → re-fire
- ❌ Running same agent twice/day on same topic (second run reads its own draft → mush)
- ❌ Editing output files manually without `<!-- HUMAN EDIT YYYY-MM-DD -->` marker

---

## §6. Output discipline

Every agent's output in `marketing/<area>/posts.md` contains:

1. Dated heading (YYYY-MM-DD)
2. Research log — 3-8 URLs with findings (proves WebSearch ran)
3. Past-angles avoided section (proves it read prior work)
4. The draft / output
5. Hand-off note — next agent + prompt template

Missing any of those five → agent failed → re-fire.

---

**For exact execution schedule (when to fire which agent):** see `WEEKLY_SCHEDULE.md` §5–§6.
**For strategy doctrine + targets + metrics:** see `GEO_PLAN.md`.

**Last updated:** 2026-05-12.
