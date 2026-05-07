# X (Twitter) Posts

---

## 2026-05-05 — "14-day Google Play gate" (thread)

**Status:** Drafted, not yet posted

<details>
<summary>🔬 Research log + plan (click to expand)</summary>

**Research log (2026-05-05):**
- Algo finding: In Q1–Q2 2026, **replies are worth 150× likes** and **bookmarks carry a 5× multiplier**. Threads get 3× engagement vs single tweets, but distribution past tweet 1 is gated to engagers — tweet 1 must hook hard. **Text-first content outperforms video by 30%** on X right now. External links in main tweets are penalized; put `zealova.com` in a self-reply at the end.
- Hashtag finding: 1 tag total = optimal. `#buildinpublic` is the canonical evergreen tag for this lane (per AutoTweet + Sprout Social May 2026 guides). 3+ tags drop engagement -17%, 5+ drop -40%. Tag goes woven into the CTA tweet, never appended.
- Trend hook hijack: "AI fitness coach" is now a **mainstream category in 2026**. Indie founders are winning by **DMing testers directly** — one IH founder reported DM'ing 50 lifters → 10 beta users. The "12 active testers" angle plugs straight into that current trope, which is why the CTA asks for replies (high-multiplier signal).
- Source links:
  - https://socialbee.com/blog/twitter-algorithm/
  - https://hashtagtools.io/blog/x-twitter-hashtag-trending-guide
  - https://www.autotweet.io/blog/best-hashtags-for-x-twitter-2026
  - https://www.indiehackers.com/post/solo-founder-building-ai-fitness-coach-6-months-in-heres-what-i-learned-7917062563
  - https://posteverywhere.ai/blog/how-the-x-twitter-algorithm-works

**Plan:**
- Stagger 3–4 days after the LinkedIn version of the same story (no same-day cross-post — looks like a content mill).
- Day/time: Tue/Wed/Thu, 9–11am ET or 2–4pm ET.
- Pin tweet 1 to profile after posting.
- After tweet 4, reply to your own thread with `https://zealova.com` + Play Console screenshot (de-prioritized in main tweets, fine in self-replies).
- 2 hours later: quote-tweet tweet 1 from a fresh session with one new line ("update: still waiting on Google") — doubles reach.
- First-hour: reply to every comment within 5 min. Bookmark-bait the thread by making tweet 2 saveable (it's the actionable lesson).
- Hashtag: 1 tag total — `#buildinpublic` woven into tweet 4's closing sentence.

</details>

### 📝 POST CONTENT BELOW — copy-paste this

**1/** (232 chars)
A Google Play rule I didn't know about blocked my Android launch for 14 days:

12+ active testers. 14 consecutive days. Before Google will even look at your production submission.

"Active" = opens the app. Not installs. Opens. 🧵

---

**2/** (218 chars)
What I'd do differently as a solo dev:

Recruit testers the day you start coding, not the day you finish.

I lost 9 days because I assumed friends + family counted. Google measures opens, and most of my "testers" installed once and forgot.

---

**3/** (240 chars)
Two more traps:

→ Data Safety form: every permission has to map to Google's exact taxonomy. "fitness data" got me bounced. "health and fitness" passed.

→ App Access field: leave it blank and reviewers reject on day 13 instead of day 1.

---

**4/** (236 chars)
Submitted to production review this week. Now refreshing Play Console every 2 hours waiting for the greenlight.

Public Android launch soon. iOS right after.

Stuck on the same gate? Reply "checklist" and I'll DM what worked.

Building Zealova — AI fitness coach. #buildinpublic

---

**Self-reply (after tweet 4 is posted):**
Try it: https://zealova.com — Android public link drops as soon as Google approves. iOS waitlist there too.

---

**Quote-tweet tweet 1 ~2h later (separate session):**
update: still waiting on Google. day 3 of refreshing the console. will post the moment it greenlights.

### 📝 END POST CONTENT

---

## 2026-05-07 — "never trust an LLM to count its own chars"

**Status:** Drafted, not yet posted

<details>
<summary>🔬 Research log + plan (click to expand)</summary>

**Research log (2026-05-07):**
- Algo finding: Replies are worth 150× likes and bookmarks carry a 5× multiplier (confirmed May 2026). Threads get 3× engagement vs single tweets but distribution past tweet 1 is gated on tweet-1 engagement — hook must convert. Text-first outperforms video by 30%. External links penalised; product link goes in self-reply only.
- Hashtag finding: 1 tag total is optimal on X in 2026 — `#buildinpublic` is the evergreen indie-hacker tag. Woven into a sentence in the final CTA tweet, not appended. 3+ tags = −17% engagement, per AutoTweet + Sprout Social May 2026 guides.
- Trend hook hijack: "LLM can't count its own characters" is a live frustration in the indie-dev + AI tooling community — anchored to commit dee5c43 (May 6 2026) which tightened the publisher cap from 275 → 225 after a real miscounting incident. No fabricated facts: the 266 vs 285 gap and the cap numbers are directly from the commit diff.
- Source links:
  - https://posteverywhere.ai/blog/how-the-x-twitter-algorithm-works
  - https://www.autotweet.io/blog/best-hashtags-for-x-twitter-2026
  - https://socialbee.com/blog/twitter-algorithm/
  - https://opentweet.io/blog/how-twitter-x-algorithm-works-2026
  - https://www.teract.ai/resources/twitter-strategy-indie-hackers-2026

**Plan:**
- Anchored commit: `dee5c43` — "fix(x-publisher): tighten per-tweet cap from 275 to 225 chars"
- Day/time: Thu May 8, 9–11am ET or 2–4pm ET. ⚠️ Last post was May 5 — hold until May 8 (72h gap) to avoid algorithmic suppression.
- Stagger 3–4 days from any LinkedIn post on same topic
- Pin tweet 1 after posting
- Self-reply after tweet 5: drop zealova.com link + Render/FastAPI/Supabase stack mention
- Quote-tweet tweet 1 ~2h later: "update: the Telegram gate worked — publisher live, first post approved"
- First-hour: reply to every comment within 5 min; the "Reply how and I'll DM" CTA drives high-multiplier reply signals
- Hashtag: `#buildinpublic` woven into tweet 5 (final CTA), 1 tag total

</details>

### 📝 POST CONTENT BELOW — copy-paste this

**1/** (177 chars)
Never trust an LLM to count its own characters. 🧵

My publisher reported tweet 5 as 266 chars.
Python len() said 285.

That's a 20-char gap — and it slipped past the safety cap.

---

**2/** (197 chars)
Why it happens:

LLMs estimate. Python counts exactly.

Newlines, emoji, long words — all add up differently than the model thinks.

My old cap was 275. The tweet landed at 285. It slipped through.

---

**3/** (210 chars)
The fix: lower the publisher cap to 225.

That's a 55-char margin under X's 280 limit. Big enough that no LLM miscounting can sneak through.

Now: the agent verifies with Python len() BEFORE posting. Not after.

---

**4/** (219 chars)
The publisher works like this:

Claude drafts the thread → POSTs to my FastAPI backend → Supabase stores the draft → Telegram bot sends it to me with 🚀 / ❌ buttons.

Tap 🚀: it posts the reply-chain to X. Tap ❌: skipped.

---

**5/** (203 chars)
Building Zealova — AI fitness app with LangGraph multi-agent chat.

The publisher: 420 lines of Python. Ship → Telegram review → X thread posted.

Reply "how" and I'll DM the architecture. #buildinpublic

---

**Self-reply (after tweet 5 is posted):**
Stack: FastAPI on Render, Supabase (asyncpg pooler compat), Telegram bot, OAuth 2.0 PKCE refresh-token rotation. All 420 lines: https://zealova.com

---

**Quote-tweet tweet 1 ~2h later (separate session):**
update: Telegram gate worked — first draft approved and posted. the Python len() check held.

### 📝 END POST CONTENT
