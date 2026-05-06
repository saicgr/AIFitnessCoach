# Reddit — Claude Instructions

Read `marketing/CLAUDE.md` first. Reddit is the platform most likely to ban you for self-promotion done wrong — read this entire file before drafting.

## Reddit reality (2026)

- **Each subreddit has its own rules.** Read the sidebar + last 30 days of top posts BEFORE drafting. A draft that fits r/IndieHackers will get nuked in r/Fitness within 5 minutes.
- **No copy-paste cross-posting.** Mods detect identical content across subs and shadowban the account. Reshape every post for each sub.
- **Karma threshold gate.** Most useful subs require ~50–500 comment karma before allowing posts. Spend a week commenting genuinely before posting.
- **No links in the post body** for first-time accounts. Put `zealova.com` in a top comment if rules allow, or in your profile.
- **Title is 80% of the post.** Sort the sub by Top → Past Month, read 2–3 pages of titles, draft 15–20 variations of yours before picking one.
- **Specifics > hype.** Real numbers, real screenshots, real tradeoffs win. "How I built X" > "Check out my new app".
- **6–8am ET on weekdays** is the global posting peak (Europe awake, US waking up).

**ALWAYS run a WebSearch for the target sub's name + "rules 2026"** before drafting — sub rules and karma thresholds change.

## Subs that fit Zealova (priority order)

| Sub | What works | What gets banned |
|---|---|---|
| r/IndieHackers | Build-in-public revenue/tactics posts. MRR screenshots. | Vague "check out my app" |
| r/SideProject | Launch posts with specific tech stack details. | Re-launch spam |
| r/flutterdev | Technical posts about Flutter+Riverpod+Drift patterns. | Pure marketing |
| r/Python | Backend technical posts (FastAPI, async patterns). | Anything promotional |
| r/learnpython | Tutorial-shape posts. Never promotional. | Showcase / launch |
| r/Fitness | DO NOT POST product launches. They will ban you. Only contribute to discussions. | Any app promo |
| r/loseit | Same as r/Fitness — strict no-promo. | Any app promo |
| r/MachineLearning | RAG / agent / Gemini deep-dives. Has to be technically meaty. | Surface-level AI hype |
| r/Entrepreneur | Story posts about the business side, lessons learned. | Hard sell |

If unsure: post in r/IndieHackers or r/SideProject first, never in fitness subs.

## Title templates that work in 2026

- "I tested A vs B vs C for [job]. Here's what surprised me." — comparison
- "We hit [problem] at [scale]. Here's the fix and the tradeoffs." — war story
- "Shipped v1 in 30 days. Here are 7 mistakes I won't repeat." — confession
- "[Specific number] + [unexpected outcome]" — e.g., "289 views from 6K connections — what I got wrong on LinkedIn"

## Body structure

```
[1–2 sentence context: who I am, what I built, why this post]

[The actual content — story / lesson / numbers / screenshots]

[Tradeoffs / what didn't work — Reddit rewards honesty about failures]

[Specific question to readers OR offer to share more]
```

Length: 400–1500 words for IndieHackers/SideProject. 200–500 for flutterdev/Python.

Include: 1–3 screenshots or a short GIF where possible. Imgur links are fine; native Reddit upload is preferred.

## Anti-patterns that will kill your account

- Posting to fitness subs about Zealova → instant ban.
- Posting the same content to multiple subs same day → shadowban.
- New account with <50 karma posting → auto-removed by Automoderator.
- Editing the post within first hour → mods see "edit" tag and review more aggressively.
- Replying defensively to negative comments → tanks karma + visibility. Take the L, ask follow-ups.
- "Check out my app" titles with no value → downvoted to oblivion within 10 minutes.

## Posting plan template

```
**Status:** Drafted / Posted / Result
**Sub:** r/IndieHackers (verified rules + karma threshold met)
**Title variants:** 15 drafted, top 3 picked
**Plan:**
- Day/time: Tue/Wed/Thu, 7am ET
- Body: 600 words, 2 screenshots, 1 GIF
- Link placement: zealova.com in OP only if sub rules allow; else top comment
- First-hour: respond to first 3 comments within 5 min
- Cross-post: NO. Wait 7+ days, reshape, post to next sub.
```

## When the user asks for "a Reddit post"

1. ASK which subreddit (do not guess — wrong sub = ban).
2. Read sub rules via WebSearch + check user's karma.
3. Read top 30 posts in that sub from past month.
4. Draft 15 title variants, recommend top 3.
5. Body: story-first, numbers-rich, no hype.
6. Append to `posts.md` with date + sub + plan + body.
