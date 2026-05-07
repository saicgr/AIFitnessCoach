# LinkedIn — Claude Instructions

Read `marketing/CLAUDE.md` first for cross-platform rules. This file is LinkedIn-specific tactics for 2026.

## Required reading before drafting any LinkedIn post

**Read `marketing/linkedin/research/linkedin-algorithm-study-2026.md`** — Metricool's 2026 study (673,658 posts analyzed, 65,000 accounts) extracted to markdown. The PDF is alongside it for reference but the markdown is what the agent reads. This is internal-source data and treats existing-conversation "I know LinkedIn's algorithm" claims as stale; the study supersedes intuition.

## Headline 2026 numbers from the study (verify against the markdown for full context)

- **Carousels get 11× more interactions than single images.** This is the single biggest format lever — default to carousel (multi-page PDF "Document" post) for any post where the message can be split into 5-10 slides.
- **Posts with a question get +77% more comments** vs. statement-only posts. End every post with a specific question, not just a CTA.
- **Personal Profiles outperform Company Pages by +51% engagement** on accounts >10K followers. Post from `@chetwitt123` / personal handle, never the Zealova company page, until the company page passes 10K.
- **Posts with links get +63% more impressions on Company Pages** but suppress reach on Personal Profiles. So the cross-platform rule (link in first comment, not body) still holds for personal posts — only the Company Page exception flips.
- **First 48 hours = 50% of a post's lifetime impressions.** First 60-90 min = ~70% of those. The "golden hour" reply discipline is non-optional.
- **Personal Profiles drove +5% more clicks per post than Company Pages.** Reinforces "post personal until 10K."

These are the headline numbers — the markdown file has the full breakdown by industry, post format, account size, and time-of-day. Re-read it any time you draft a post that touches a niche the headline numbers don't cover (carousel vs polls, video vs single image, B2B SaaS vs creator content, etc.).

## Algorithm in 2026 (verify with WebSearch before drafting)

- **Golden hour**: first 60–90 min decide ~70% of total reach. 5 comments in first 10 min ≫ 50 comments after 24h.
- **See-more cutoff**: first ~200 chars must hook. After that the post is truncated and most readers never expand.
- **Dwell time** is the dominant ranking signal. Saves > shares > comments > likes.
- **NLP de-rank** triggers on engagement-bait phrases: "comment YES", "like if you agree", "drop a 🔥". Avoid.
- **Outbound links in body** suppress distribution. Always put `zealova.com` in first comment.
- **Carousel PDFs** and short native video outperform text+image 2–3×.
- **3–5 hashtags** placed on a separate line at the very bottom of the post, in PascalCase (verify the exact count rule still holds with a fresh WebSearch each session — LinkedIn changed this in 2024 and may again). Hashtags are categorization signals for LinkedIn's 360Brew AI now, not a discovery surface. **Pick the specific tags fresh every session** via WebSearch: `best LinkedIn hashtags [Month] [Year] AI fitness indie founder build in public`. Never reuse last session's set without re-verifying volume + relevance.
- **Edits within first hour** reset distribution. Proof-read before posting, never after.

**ALWAYS run a fresh WebSearch for current algorithm rules + trending hooks the morning of drafting** — the algorithm shifts quarterly and rules from 6 months ago are stale.

## Hook frameworks (pick one per post, never mix)

1. **Number + stakes** — "14 days. 15 testers. One rule that almost killed my launch."
2. **Confession** — "I lost 9 days to a Google Play rule I didn't know existed."
3. **Contrarian** — "Everyone says X. After shipping 3 apps, I think X is wrong."
4. **Specific moment** — "Yesterday at 11pm, my AI suggested a workout that nearly hurt a beta tester. Here's what I learned."

## Format rules

- 1,200–1,500 chars total is the sweet spot for dwell time.
- Paragraphs > bullets in story posts. Bullets only if you're shipping a 3-tip carousel-style post.
- Line breaks every 1–2 sentences. Walls of text kill dwell time on mobile.
- No emoji at the start of any line — looks like a press release, suppresses reach.
- One closing CTA per post: a specific verb ("comment 'checklist'", "DM me 'launch'"), never a vanity ask.
- Tag at most 2 specific people who would genuinely care. Never tag for visibility.

## Posting plan template (every draft must include this)

```
**Status:** Drafted / Posted / Result
**Plan:**
- Day/time: Tue–Thu, 8:30am CT (LinkedIn's B2B/work-hours peak)
- Pre-post warmup: 15 min of substantive comments on 5–8 relevant posts (indie devs / AI builders / fitness creators)
- First comment: zealova.com link + Play Console screenshot, pin it
- First-hour: reply to first 3 comments within 5 minutes
- 48h moratorium: no other LinkedIn posts after this one
```

## Anti-patterns we've already paid for

- **2026-04-28 product overview**: 289 views, 0 engagement on 6K connections. Cause: bullet-heavy, outbound link in body, no story hook, generic first 2 lines. Don't repeat.
- **Posting "v2" of a flopped post within a week**: algo treats as duplicate, suppresses harder. Always change the angle.
- **Self-deletion of a flopped post**: mild negative account signal. Just leave it and move on.

## When the user asks for "another LinkedIn post"

1. Read `marketing/linkedin/research/linkedin-algorithm-study-2026.md` — the Metricool 2026 study. Anchor the format choice (carousel vs single image vs text-only vs video) to the data, not memory.
2. Read the most recent 2 posts in `posts.md` to know what's already been said + which angles to avoid.
3. Run a parallel WebSearch batch (THIS SESSION, no caching):
   - `LinkedIn algorithm [Month] [Year] reach hooks dwell time`
   - `best LinkedIn hashtags [Month] [Year] AI fitness indie founder build in public`
   - `viral LinkedIn post [Month] [Year] solo founder app launch`
4. Pick a NEW angle (story / technical / demo / metric) — never recycle the previous angle.
5. Pick the format using the study's data: carousel (11× engagement) is the default unless the post is a tight 1,200-char story with a strong hook. If carousel, draft 6–10 slides with title/key-line per slide AND prepare it for the carousel-PDF helper (see "Carousel automation" below).
6. End the post with a specific QUESTION (not a vanity CTA). Question-ending posts get +77% more comments per the study.
7. Check the previous post's status — if posted <72h ago, push back and suggest waiting.
8. Draft. Place the chosen hashtag set (3–5 PascalCase, picked from this session's research) as the very last line, on its own line, separated from the body by one blank line.
9. Append to `posts.md` with date + research log + plan + body verbatim. Never overwrite.

## Carousel automation (the 11× format)

When the post is a carousel, the agent must ALSO produce a slide deck spec — one slide per markdown block — that downstream tooling can render as a multi-page PDF for upload to LinkedIn as a Document post. Format inside `posts.md`:

```markdown
### 🎴 CAROUSEL SLIDES

**Slide 1 (cover):**
Title: <8-12 words, scroll-stop>
Subtitle: <1 line>

**Slide 2:**
Headline: <6-10 words>
Body: <1-2 short sentences, large type>

... (slides 3-9)

**Slide N (CTA):**
Headline: Save this for your next launch
Body: Follow @chetwitt123 for daily build-in-public lessons
Action: comment "<one word>" — I'll DM the longer write-up
```

The renderer (Python + reportlab, see `backend/scripts/render_linkedin_carousel.py` once built) takes this spec and produces `marketing/linkedin/carousels/YYYY-MM-DD-<angle>.pdf`. Until that script lands, output the slide spec anyway so it's ready to render OR copy-paste into a Canva template.
