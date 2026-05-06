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
