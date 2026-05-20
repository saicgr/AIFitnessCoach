# GEO posted log

Single canonical ledger of what actually went live across every channel — Reddit, X,
Threads, LinkedIn, build-in-public, blog, listicle pitches, Reels — so geo-strategist can
diff planned vs shipped and citation-tracker can measure real posting volume and detect
flat tactics over time.

This file records **posted items only**. Drafts live in the per-agent files
(`reddit/posts.md`, `build-in-public/<date>.md`, etc.). When something is posted, it gets
one block here.

How entries get created: see the **Log-posted protocol** in
`.claude/agents/marketing/_OUTPUT_STANDARD.md`. The user posts manually, then says a
trigger phrase (`build-in-public posted — log it`, `Reddit posted — log it`,
`X posted — log it`, `Zealova Reddit post posted — log it`), and the responsible agent
appends a schema-compliant block below in log-posted mode — no research, no drafting.

---

## Entry schema — every posted item is one block like this

```
### YYYY-MM-DD · <channel> · <type>
- Drafted by: <build-in-public-writer | reddit-agent | social-post-creator | ... | hand-written>
- Thread sourced: <scout/cadence | manual — Sai found it | n/a — own post>
- Source draft: <draft file path + which item, or "none — hand-written">
- Edited before posting: <no | yes — what changed>
- Pillar: <P1 listicles | P2 comparison | P3 Reddit | build-in-public | other>
- Angle: <one line>
- URL: <live URL of the posted item; thread URL for a comment>
- Status: <live | removed by mod | deleted>
- Metrics — 48h (date): <e.g. 0 upvotes / 0 replies> · 1wk (date): <...>
- Notes: <traction diagnosis, mod reaction, anything>
```

Field rules:
- **channel** — Reddit / X / Threads / LinkedIn / Medium / blog / listicle-pitch / Reel.
- **type** — comment / top-level post / thread / reply / pitch email / page / Reel.
- **Drafted by** — which agent wrote the draft, or `hand-written` if no agent was used.
- **Thread sourced** — Reddit/Quora/forum replies only. `manual — Sai found it` means Sai
  discovered the thread himself (even if an agent drafted the reply). `scout/cadence`
  means it came from scout mode or the weekly schedule. `n/a — own post` for own tweets,
  top-level posts, build-in-public.
- **Edited before posting** — `no`, or `yes — <what changed>` if the live version diverged
  from the draft. The log must reflect what actually went live.
- **URL** — mandatory. For a Reddit comment, the thread URL is the minimum; the comment
  permalink is optional backfill.
- **Metrics** — leave `—` until the checkpoint. Fill 48h and 1wk so citation-tracker can
  spot flat tactics.

---

## 2026-05-17

> These two entries predate this schema. The original log captured only a one-line
> summary with no URLs — so they cannot be fully backfilled or diagnosed. They are the
> reason the schema now requires a hard URL per item.

### 2026-05-17 · Reddit · 3 comments
- Drafted by: reddit-agent
- Thread sourced: cadence — first-ever Reddit batch
- Source draft: `reddit/posts.md` (Group A comment batch)
- Edited before posting: unknown — predates this schema
- Pillar: P3 Reddit
- Angle: first Reddit presence — MyFitnessPal-frustration comments in r/MyFitnessPal
- URL: NOT CAPTURED — posted before this schema; the 3 thread URLs were never recorded
  and cannot be reliably backfilled
- Status: live (assumed)
- Metrics — 48h (2026-05-19): no traction — no meaningful upvotes or replies on any of the
  3 · 1wk (—): —
- Notes: First batch, treat as zero-signal baseline. NOT diagnosable — the thread URLs
  were never logged, so reddit-analyzer cannot review why they flatlined. Root cause: the
  Group A drafts gave a "search the sub for a keyword" recipe instead of hard thread URLs,
  so there was no URL to record. Fixed going forward by the hard-thread-URL rule in the
  Log-posted protocol.

### 2026-05-17 · X · drafts posted
- Drafted by: unclear — not identified in original log
- Thread sourced: n/a — own posts
- Source draft: not identified
- Edited before posting: unknown — predates this schema
- Pillar: build-in-public / other
- Angle: not recorded
- URL: NOT CAPTURED — predates this schema
- Status: live (assumed)
- Metrics — 48h (2026-05-19): no traction · 1wk (—): —
- Notes: Original entry said only "X: drafts posted (count from drafts)" — no count, no
  URLs, no angle. Not diagnosable.

---

## 2026-05-19

### 2026-05-19 · X · thread (FULL THREAD)
- Drafted by: build-in-public-writer
- Thread sourced: n/a — own post
- Source draft: `docs/planning/marketing/build-in-public/2026-05-19.md` — X Thread section
- Edited before posting: unknown — not recorded
- Pillar: build-in-public
- Angle: Same-day newsjack — Google Health launched today at $9.99/mo on Gemini; fabricated a workout; Zealova runs same model 40% cheaper with no wearable required
- URL: https://x.com/chetwitt123/status/2056912801583542420?s=20
- Status: live
- Metrics — 48h (2026-05-21): — · 1wk (2026-05-26): —
- Notes: Posted without screenshots attached — agent now inlines [add image here: ...] markers in every draft to prevent repeat. Google I/O launch-day timing is peak relevance window.

### 2026-05-19 · Threads · thread (FULL THREAD)
- Drafted by: build-in-public-writer
- Thread sourced: n/a — own post
- Source draft: `docs/planning/marketing/build-in-public/2026-05-19.md` — Threads (Meta) Post section
- Edited before posting: unknown — not recorded
- Pillar: build-in-public
- Angle: Same-day newsjack — Google Health hallucination story; Zealova data pipeline contrast; price gap
- URL: https://www.threads.com/@chetangrandhe/post/DYiuHm3DT6k?xmt=AQG0obnU_OOJqao9oSpG14dxWM85sLSbGqDbRQfWyjoq8g
- Status: live
- Metrics — 48h (2026-05-21): — · 1wk (2026-05-26): —
- Notes: Posted without screenshots. Same lesson as X entry above.

### 2026-05-19 · LinkedIn · post (FULL THREAD)
- Drafted by: build-in-public-writer
- Thread sourced: n/a — own post
- Source draft: `docs/planning/marketing/build-in-public/2026-05-19.md` — LinkedIn Post section
- Edited before posting: unknown — not recorded
- Pillar: build-in-public
- Angle: Founder personal-brand — data pipeline design decision, not a model quality decision; generalized lesson for professional peers
- URL: https://www.linkedin.com/posts/activity-7462680116368809984-LkMe
- Status: live
- Metrics — 48h (2026-05-21): — · 1wk (2026-05-26): —
- Notes: Posted without image attached. Link in first comment (zealova.com) per LinkedIn algo best practice. No screenshots captured.
