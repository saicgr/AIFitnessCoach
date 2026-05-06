# X (Twitter) — Claude Instructions

Read `marketing/CLAUDE.md` first. This file is X-specific tactics for 2026.

## Algorithm + format rules

- **280 char hard limit per tweet.** Always count emojis as 2. ALWAYS verify final char count before saving the draft.
- **Hook tweet decides everything.** Algo only shows tweets 2+ to people who engaged with tweet 1.
- **Threads beat single tweets** for build-in-public — 4–7 body tweets, one clear point each.
- **Numbering** ("1/", "2/") sets reader expectations and improves completion rate.
- **🧵 emoji at end of tweet 1** is the universal "this is a thread" signal. Without it, 30% lower thread-read-through.
- **Outbound links in main tweets** are de-prioritised. Drop `zealova.com` in a self-reply at the end of the thread.
- **Quote-tweeting your own tweet 1** ~2h after posting with one new line ("update: still waiting") doubles reach.
- **First-hour reply velocity** weighs heavier than LinkedIn. Reply to every comment within 5 minutes.
- **1–2 hashtags MAX.** Per current X data: 1–2 tags get +21% engagement vs. zero; 3+ tags drop −17%; 5+ drop −40%. Woven into a sentence (e.g., "built this with #LangGraph") gets +28% vs. bottom-tagged. **Re-verify these stats and choose the specific tags fresh every session** via WebSearch: `trending X hashtags [Month] [Year] indie hacker build in public AI fitness`. Tag landscape on X shifts faster than LinkedIn — never trust last week's set.

**Run a fresh WebSearch every drafting session** for current X algo + trending #buildinpublic / #indiedev / fitness threads to calibrate tone and topics.

## Hook templates (proven 2026)

1. **Specific result + timeframe** — "I spent $50k before figuring out what works. Here's the thread that saves you the same."
2. **Confession + lesson** — "A Google Play rule I missed cost me 14 days. Here's what I'd do differently."
3. **Contrarian** — "Everyone says you need 100 testers. I shipped with 15. Here's the math."
4. **Live moment** — "It's 2am. Production review just bounced me for the 3rd time. Walking through what they actually flag."

## Char-count discipline

Run this mental check on every tweet:
- Body chars (including spaces, punctuation)
- + 2 per emoji
- + 23 if there's a URL (X auto-shortens to 23 chars regardless of original length)
- = total

If any tweet is over 280, trim. If under 200, you're probably leaving impact on the table — pack more.

## Thread structure that ships

```
1/  Hook (≤280) — number + stakes + 🧵 + promise
2/  Tactic 1 (≤280) — single specific lesson with a number
3/  Tactic 2 (≤280) — second specific lesson, different angle
4/  Tactic 3 (≤280) — third lesson OR live status update
5/  CTA (≤280) — specific reply prompt + product mention + 1 hashtag
```

Five tweets is the sweet spot. Threads >7 tweets see drop-off after tweet 4.

## Posting plan template

```
**Status:** Drafted / Posted / Result
**Plan:**
- Day/time: Tue/Wed/Thu, 9–11am ET or 2–4pm ET
- Stagger 3–4 days from any LinkedIn post on same topic
- Pin tweet 1 to profile
- Self-reply with zealova.com link as final tweet (after CTA tweet)
- Quote-tweet tweet 1 ~2h after, fresh session, one new line
- Reply to every comment in first hour within 5 min
```

## Anti-patterns

- **Copy-pasting LinkedIn → X** without restructuring. LinkedIn is 1,500-char paragraphs; X is 5×280-char tweets. Different physics.
- **Markdown asterisks** (`*look*`) — X renders them as literal asterisks. Use ALL-CAPS or remove emphasis.
- **Emoji-stuffed hooks** — reads like spam. Max 1 emoji in tweet 1, the 🧵.
- **>2 hashtags** — same de-rank as LinkedIn.
- **CTAs that ask for vague engagement** — "thoughts?" gets ignored. "Reply 'checklist' and I'll DM" gets actioned.

## When the user asks for "another X post"

1. Read most recent threads in `posts.md` + extract past angles.
2. Run a parallel WebSearch batch (THIS SESSION):
   - `X Twitter algorithm [Month] [Year] thread reach hashtag count engagement`
   - `trending X hashtags [Month] [Year] indie hacker build in public AI fitness`
   - `viral X thread [Month] [Year] indie dev launch fitness app`
3. New angle from previous (story / technical / metric / demo).
4. Draft each tweet with explicit char count next to it (target ≤270 chars to leave breathing room).
5. Weave the 1–2 chosen hashtags into a body sentence in tweet 1 or the CTA tweet. Never tag every tweet in the thread.
6. Append to `posts.md` with date, research log, plan, all 4–5 tweets verbatim, char counts annotated.
