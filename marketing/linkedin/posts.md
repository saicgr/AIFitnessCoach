# LinkedIn Posts

---

## 2026-04-28 — "Zealova product overview"

**Result:** 289 views, 0 likes, 0 comments (with 6K connections)

Most people quit fitness within three weeks due to inadequate tools, such as random YouTube workouts, guessing portions in MyFitnessPal, or building DIY programs in ChatGPT or Claude Code that require manual tracking in a spreadsheet/Notion. Additionally, many people lack guidance on issues such as knee pain and proper form. Those who persist often invest $200 or more per month in a trainer and a nutritionist, which isn't feasible for most.

To address this, I developed Zealova — an AI fitness and nutrition coach that offers both services at a much lower cost. It includes:

Workouts
- Personalized plans with progressive overloads, RIRs, and RPEs.
- Instant exercise swaps for injuries or missing equipment
- Rest timers, voice cues
- Bluetooth heart-rate monitor support
- Apple Health / Google Fit sync

Nutrition
- Snap a photo of your plate to auto-log calories and macros
- Scan restaurant menus for goal-oriented recommendations
- Barcode scanner for packaged food
- Hydration tracking

AI Coach
- 24/7 chat for exercise swaps, injuries, nutrition logging, hydration, and motivation
- Multi-agent system with specialist agents routed by Gemini Vision when uploading images or videos

📊 Progress
- Body measurements with an anatomical body atlas
- Progress photos, comparisons, sleep, and step tracking
- Streaks, XP, trophies, and a year-end Wrapped

🛠️ Stack
- Built using Claude Code, Flutter, FastAPI (Python async), Supabase (Postgres + Auth), Google Gemini, ChromaDB for exercise RAG, LangGraph for the agent swarm, RevenueCat, Sentry, and Firebase, hosted on Render, Vercel.

Challenges I hit along the way
- Building an exercise and nutrition database that's actually usable — sourcing, cleaning, tagging muscle groups, equipment, and difficulty for thousands of movements before the AI could even reason about them
- Getting Gemini's safety filters to stop blocking ordinary fitness content
- Routing chat correctly across 5 specialist agents without misfires
- Passing Google Play's new 14-day closed-testing gate as a solo dev

🔧 What's still being improved
- AI accuracy — better food recognition for mixed plates, fewer hallucinated calories, tighter macro estimates
- Form-check from videos (in development, not shipped yet)
- Smarter long-horizon program design that respects deload weeks and lifestyle constraints
- Expanding the exercise library and food database with more international cuisines.

📅 What's coming next
Full roadmap: zealova.com/roadmap

🥳 I just cleared Google Play's production access review, which took about 15 testers and 14 days, so the public Android launch is coming soon, followed by iOS.

If you want the link as soon as it's live, drop a comment and I'll DM you.

#BuildInPublic #IndieDev #AI

**Postmortem:**
- Heavy bullet/emoji formatting — algorithm de-ranks
- Outbound link (`zealova.com/roadmap`) in body — suppresses reach
- Reads like a press release, no story hook
- First two lines are generic, no "see more" click
- Distribution capped at ~5% of network after zero engagement in first hour

---

## 2026-05-05 — "14-day Google Play gate"

**Status:** Drafted, not yet posted

<details>
<summary>🔬 Research log + plan (click to expand)</summary>

**Research log (2026-05-05):**
- Algo finding: LinkedIn 360Brew AI weighs **dwell time + saves** above likes/shares in 2026. First 200 chars must hook before the "see more" cutoff. Hashtags removed as a discovery surface in late 2024 — they're now categorization signals only.
- Hashtag finding: 3–5 PascalCase tags on the last line. `#BuildInPublic` (large, evergreen) + `#IndieDev` (mid) + `#SoloFounder` (mid) + `#AIBuilder` (mid, growing) chosen as the build-in-public story set.
- Trend hook hijack: "Confession + lesson" is currently the top-performing LinkedIn hook structure for solo founders — owning a knowledge gap reads more authentic than a victory lap.
- Source links:
  - https://www.dataslayer.ai/blog/linkedin-algorithm-february-2026-whats-working-now
  - https://sproutsocial.com/insights/linkedin-hashtags/
  - https://socialrails.com/blog/best-linkedin-hashtags

**Plan:**
- Day/time: Tue–Thu, 8:30am CT (LinkedIn B2B/work-hours peak)
- Pre-post warmup: 15 min of substantive comments on 5–8 indie-dev / AI / fitness posts beforehand
- First comment: `https://zealova.com` + Play Console screenshot, pin it
- First-hour: reply to first 3 comments within 5 min
- 48h moratorium: no other LinkedIn posts after this one

</details>

### 📝 POST CONTENT BELOW — copy-paste this

14 days. 15 testers. One Google Play gate that almost killed my launch.

If you're a solo dev shipping Android in 2026, here's the part nobody warns you about:

Turns out Google has required this since late 2023, and I just didn't know: 14 consecutive days of closed testing with 12+ *active* testers before they'll even review your production submission. "Active" means actually opening the app, not just installing. As a solo founder, finding 12 people who'll do that every day is harder than writing the app.

Three things I'd do differently:

1. Start recruiting testers the day you start coding. Not the day you finish. I lost 9 days because I assumed friends and family counted as "active" — they don't. Google measures opens, not installs.

2. The Data Safety form is a trap. Every permission in your manifest has to map to a declared data type, and the wording has to match Google's exact taxonomy. I got bounced once for saying "fitness data" instead of "health and fitness."

3. The App Access field — the one most devs leave blank — is where reviewers create a test account to poke at gated features. Leave it blank and they'll reject you on day 13 instead of day 1.

Submitted to production review this week. Now I'm in the part nobody talks about: refreshing Play Console every two hours waiting for Google to greenlight the full app for public listing.

Public Android launch as soon as they greenlight it. iOS right after.

If you're stuck on the same gate, comment "checklist" and I'll DM you the full list of what worked.

#BuildInPublic #IndieDev #SoloFounder #AIBuilder

### 📝 END POST CONTENT

---

## 2026-07-07 — "I gave Claude and ChatGPT a key to my app"

**Status:** Drafted, not yet posted

<details>
<summary>🔬 Research log + plan (click to expand)</summary>

**Research log (2026-07-07):**
- Algo finding: Dwell time is the dominant 2026 ranking signal (0-3s dwell = 1.2% engagement vs 61s+ = 15.6%, a 13x gap). Document/carousel posts are the single highest-engagement native format on LinkedIn right now, and outbound links in the body still cost roughly 60% of reach. Confirms the carousel default over a text-only post for this one.
- Hashtag finding: 3-5 highly specific tags outperform broad/volume ones in 2026; keyword-rich body text now matters as much as the tags themselves. Chose #BuildInPublic (evergreen, matches prior posts), #MCP (exact-match category tag for this story), #AIAgents (growing 2026 category), #IndieDev (audience tag) — 4 tags, all directly on-topic rather than generic (dropped #AI as too broad per this session's research).
- Trend hook hijack: none borrowed from a single viral post. Loosely riding the live "MCP is becoming shared infrastructure, not just an Anthropic format" moment (the Linux Foundation donation), used as real background context, not a hijacked headline.
- Dev-context source: this is grounded in yesterday's actual git history, not a generic feature-launch framing — commits `bab364ef` (one-command OAuth setup), `9c882f75` (program/fasting tools), `dc866e7d` (Settings surface), `029cacb2`/`4d5a94e9` (consent-page repairs), `63d231b0` (`/mcp/docs` page), `a97ee51e` (default scope grant + dead button fix), all dated 2026-07-06.
- Source links:
  - https://www.dataslayer.ai/blog/linkedin-algorithm-february-2026-whats-working-now
  - https://growleads.io/blog/linkedin-algorithm-2026-text-vs-video-reach/
  - https://sproutsocial.com/insights/linkedin-hashtags/
  - https://www.anthropic.com/news/donating-the-model-context-protocol-and-establishing-of-the-agentic-ai-foundation
  - https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation
  - https://github.com/rdmgator12/awesome-claude-connectors (directory snapshot, last updated 2026-07-02)

**Claim → proof map (facts asserted inside the draft):**
- "Anthropic donated MCP to the Linux Foundation's new Agentic AI Foundation, backed by OpenAI, Google, Microsoft, and AWS" → https://www.anthropic.com/news/donating-the-model-context-protocol-and-establishing-of-the-agentic-ai-foundation + https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation, verified 2026-07-07
- "Claude's own connector directory already tracks 554 MCP integrations across 30 categories, including Strava for activity logging and Alma for nutrition coaching" → https://github.com/rdmgator12/awesome-claude-connectors, page states "Last Updated: July 2, 2026," verified live 2026-07-07. (Note: I originally planned to claim "no fitness coach is in the directory yet" — checked it directly first and found Strava + Alma already listed, so the claim was rewritten to the honest, narrower gap: nothing that also *generates* workouts and coaches day to day, which matches Zealova's actual wedge vs. tracker/nutrition-only apps per `_ZEALOVA_FACTS.md` §4.)
- All product-mechanics claims (OAuth 2.1 + PKCE + DCR, PAT flow, tool scopes, rate limiting, audit log, anomaly detection, confirmation-before-write, yearly-subscriber gate, the one-day build timeline, the consent-page bugs) → verified directly against this session's git log/diff and the task's ground truth, not external sources; these are first-person claims about Zealova's own shipped code.

**Plan:**
- Format: Carousel (Document post) — per the Metricool 2026 study's 11x-interactions-over-single-images finding and this session's dwell-time research; also the natural format for a "here's what actually shipped" technical explainer.
- Day/time: Wed 2026-07-08, 8:30am CT (LinkedIn's B2B/work-hours peak; today's post is 2 months after the last draft so no cadence conflict, but same-day posting skips warmup time)
- Hashtags: #BuildInPublic #MCP #AIAgents #IndieDev
- Pre-post warmup: 15 min of substantive comments on 5-8 indie-dev / AI-agent / fitness-builder posts the same morning
- First comment: pin `zealova.com/mcp/docs` (the actual public setup page, live per commit `63d231b0`) — never in the body
- First-hour: reply to the first 3 comments within 5 minutes; anyone who comments "connect" gets the setup-guide DM promised in the post
- 48h moratorium: no other LinkedIn posts after this one

</details>

### 📝 POST CONTENT BELOW — copy-paste this

Yesterday I gave Claude and ChatGPT a key to Zealova, the AI fitness coach I'm building. Scoped. Audited. Revocable any time.

For the last year the only way to touch your Zealova data was inside my app. That changed yesterday. Zealova now runs its own MCP server. If you live inside Claude, ChatGPT, or Cursor, your AI assistant can read and write your real workouts, meals, fasting, and body stats. Authenticated as you. Scoped to whatever you allow.

Instead of opening five screens in my own app, I ask Claude what my strength progression looked like this month. It pulls the real report straight from my account.

The part that took longer than the fun part was the guardrails. Rate limiting, a full audit log of every tool call, anomaly detection, and a confirmation step before any write. Yearly subscribers only, for now.

Handing an AI write access to real fitness data with no guardrails is asking for trouble. That's how you end up on the front page of Hacker News.

Built the whole thing in one day, bugs included. Swipe through for what shipped, including the consent screen I broke and fixed in the same afternoon.

Would you actually want your AI reading and writing your own fitness data, or does that feel like one step too far? Comment "connect" and I'll send you the setup guide.

#BuildInPublic #MCP #AIAgents #IndieDev

### 📝 END POST CONTENT

### 🎴 CAROUSEL SLIDES

**Slide 1 (cover):**
Title: I gave Claude and ChatGPT a key to Zealova
Subtitle: Built in one day. Scoped. Audited. Revocable.

**Slide 2:**
Headline: What MCP actually is
Body: A protocol that lets an AI assistant call real tools, not just chat about them. Anthropic donated it to the Linux Foundation's new Agentic AI Foundation this year, backed by OpenAI, Google, Microsoft, and AWS. It's not just Anthropic's format anymore.

**Slide 3:**
Headline: Two ways in
Body: A Personal Access Token flow, live today: go to Settings, create a connection, paste one JSON config into Claude or ChatGPT. And a full OAuth 2.1 + PKCE + Dynamic Client Registration flow, built for future listings like Claude's connector directory or the ChatGPT Apps directory.

**Slide 4:**
Headline: Where to find it
Body: Settings → AI Integrations → Create Connection. Copy the config it gives you, paste it into your AI client, and it connects authenticated as you.

**Slide 5:**
Headline: What your AI can actually touch
Body: Workouts, nutrition, body stats, fasting, curated programs, coach chat, and full data exports. Scoped to whatever permissions you grant.

**Slide 6:**
Headline: Plus a report generator
Body: Ask for a workout-adherence report, a nutrition deep dive, or a strength-progression summary. It hands back a real PDF, HTML, or Markdown doc, not a chat summary.

**Slide 7:**
Headline: The unglamorous half of the build
Body: Rate limiting. An audit log of every single tool call. Anomaly detection middleware. A confirmation step before any write action. Locked to yearly subscribers only.

**Slide 8:**
Headline: One day, start to finish
Body: Core OAuth server and tool registration in the morning. Program and fasting tools by afternoon. A public docs page at zealova.com/mcp/docs. Then hours fixing the consent screen I'd just broken: dead buttons, a stuck loading state, broken CSS.

**Slide 9:**
Headline: Why bother with this now
Body: Claude's own connector directory already tracks 554 integrations, including Strava for activity logging and Alma for nutrition coaching. Nothing yet that also generates your workouts and coaches you day to day. That's the gap this is aimed at.

**Slide 10 (CTA):**
Headline: Would you hand an AI write access to your own fitness data?
Body: Comment "connect" and I'll send you the setup guide for linking Claude, ChatGPT, or Cursor to your own Zealova account.
Action: Follow for the real build, bugs included.
