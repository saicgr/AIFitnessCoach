# Zealova — 30-Reviews Push Plan (7 days)

**Status:** Day 0 — Android shipped 2026-05-10. iOS in waitlist.
**Target:** 30 honest Play Store reviews at 4.0+ avg by 2026-05-17.

## Why 30

The Play Store algorithm suppresses apps with under ~30 reviews — they don't surface in keyword searches, "similar apps" rails, or recommendation feeds. Above 30 (at 4.0+), organic surfacing turns on. This is the hardest threshold of the entire launch.

## What's allowed (and what isn't)

✅ **OK**
- Asking friends / family / coworkers to download and leave an honest review
- Sending the install link directly via DM, text, email
- Asking for written feedback alongside stars
- One follow-up nudge if they didn't respond
- Replying to every review in the Play Console (5-star OR 1-star — both signal active dev)

🚫 **NOT OK — listing pull / dev account ban risk**
- Offering anything in exchange for a review (gift card, free year, swag, even *implied* favors)
- Asking only people who liked the app to review (review-gating)
- Reviewing your own app from your own / alt accounts (Google detects via device fingerprint + IP + payment method + account age — even from "different" emails)
- Buying reviews / using review farms
- Bulk reviews from the same IP / device / network in a tight time window

The line: *"Would you try my app and leave an honest review?"* is fine. *"Leave a review and I'll Venmo you $5"* is not.

## The list — 30 names

Build a Notion / Sheets table with:

| Name | Channel | Closeness (1-3) | Variant | Sent | Downloaded | Reviewed | Notes |
|------|---------|-----------------|---------|------|------------|----------|-------|

Sources to mine:
- [ ] iMessage thread history (last 90 days)
- [ ] WhatsApp + Telegram top contacts
- [ ] LinkedIn 1st-degree connections in fitness/tech
- [ ] Instagram followers you actually know
- [ ] Discord servers you're active in
- [ ] Old college / coworker email threads
- [ ] Family group chats (parents, siblings, cousins, in-laws)
- [ ] Gym buddies with Android phones

Closeness rating:
- **1 = close friend / family** (use Variant A)
- **2 = acquaintance / coworker** (use Variant B)
- **3 = light contact / public ask** (use Variant C — LinkedIn / Twitter / IG)

Aim: 12 × Variant A, 12 × Variant B, 6 × Variant C.

## The three message variants

### Variant A — close friends / family (12 people)

```
Hey [name] — I just shipped my app on the Play Store today after building it for [X] months solo. It's an AI fitness coach that handles both workouts and meal logging in one app. I'm at the cold-start phase where I genuinely need ~30 honest reviews to break out of the algorithm dead zone. Would you mind taking 2 min to download it and leave whatever review feels honest — even 3 stars is fine if that's where you land?

Link: https://play.google.com/store/apps/details?id=com.aifitnesscoach.app

If anything breaks, hit Settings → Send feedback and I'll fix it the same day. Means a lot 🙏
```

### Variant B — acquaintances / coworkers (12 people)

```
Hey [name] — quick favor. Just shipped my fitness app on the Play Store today (built solo, took 8+ months). The Play Store algorithm hides apps with under 30 reviews, so I'm trying to break out of cold-start. If you're an Android user and have 5 minutes today, would you download it and leave an honest review?

https://play.google.com/store/apps/details?id=com.aifitnesscoach.app

Free 7-day trial, no card needed. Even a quick "tried it, looks clean" 4-star is gold right now.
```

### Variant C — light contacts / public ask (6 people, or 1 LinkedIn / Twitter / IG post)

```
Just shipped Zealova on the Play Store after 8 months of solo building — AI coach that handles workouts AND nutrition in one app. Cold-start is brutal: under 30 reviews and the algorithm hides you.

If you're an Android user and want to help an indie dev, link in comments / DM. Free 7-day trial, no card. Brutally honest reviews wanted.
```

## Rules of execution

1. **No more than 7 messages/day.** More than that and you sound desperate; replies get rushed.
2. **Personalize each message** by hand — at minimum the name + one sentence of context ("you said you wanted a workout app last fall"). Pasted templates underperform 10x.
3. **Wait 72h before nudging.** The nudge: *"hey, no pressure if you didn't get to it — bumping in case it got buried."* Send the nudge ONCE. After that, drop it.
4. **Track in your sheet.** Knowing your conversion rate (e.g. "30 sent → 18 downloaded → 11 reviewed") tells you when to stop.
5. **Reply to every review** in the Play Console within 24h, even 5-star ones. Active-developer signal to the algorithm + courtesy to reviewers.
6. **Don't ask for 5 stars.** Ask for honest. People who feel coerced into 5 stars become 1-star reviewers later when something annoys them.

## Day-by-day cadence

| Day | Date | Action | Target |
|-----|------|--------|--------|
| 0 | 2026-05-10 | Build the 30-name list | List ready |
| 1 | 2026-05-11 | Send 5 to closest friends (Variant A) | 5 sent |
| 2 | 2026-05-12 | Send 7 to acquaintances (Variant B) | 12 sent |
| 3 | 2026-05-13 | Send 7 more (Variant B) | 19 sent |
| 4 | 2026-05-14 | Public LinkedIn / Twitter / IG ask (Variant C) | 25 sent |
| 5 | 2026-05-15 | Send remaining 5 (mix A/B) | 30 sent |
| 6 | 2026-05-16 | Nudge Day 1-2 non-responders (1x only) | — |
| 7 | 2026-05-17 | Nudge Day 3-4 stragglers, count reviews | Goal: ≥30 |

## If you're under 20 reviews by Day 7

Don't double down on personal network — diminishing returns. Pivot to:

- **Reddit r/sideproject "I made this"** post (no link to Play Store in body — Reddit auto-filters; link in comment)
- **Indie Hackers product launch** (free, takes 30 min to set up)
- **Product Hunt scheduled launch** (Tuesday or Thursday, US timezone, with a hunter who has followers)
- **Hacker News Show HN** (skeptical audience but high-quality eyes)

Each of those plays out as its own week-long playbook. Bookmark for v2.

## Anti-patterns (don't do these)

- **Don't review from your own 8 email accounts.** Google's fraud detection catches this via device fingerprint + IP + payment method correlation. The penalty is account ban — permanent. You just launched; don't trade an 8-month build for 8 reviews.
- **Don't ask "did you leave a 5 star yet?"** Coerced reviews become 1-star reviews later.
- **Don't post the link in /r/AppHookup, /r/androidapps without reading their rules.** Most subs ban self-promotion outright.
- **Don't run a "free year for the first 50 reviewers" promo.** Direct violation of Play policy 4.6.
- **Don't reply to negative reviews defensively.** Reply with: *"Thanks for the honest feedback — I'm shipping a fix this week. Hit Settings → Send feedback if you want to chat."* Then actually ship the fix.

## Replying to reviews — templates

5★ generic:
> Thanks [name] — really appreciate it 🙏 hit Settings → Send feedback if you want any feature added.

3-4★ ("good but X annoyed me"):
> Hey [name] — totally fair. [Specific feature mention] is on the roadmap, hoping to ship it within [timeframe]. Will you let me ping you when it's live?

1-2★ ("buggy / X didn't work"):
> [Name] — I'm sorry that happened. Can you hit Settings → Send feedback with what you saw? I read every report and want to fix this for you. Will reply in <24h.

## Done when

- [ ] 30+ reviews on Play Store
- [ ] Average rating ≥ 4.0
- [ ] Replied to every review
- [ ] Sheet shows conversion rate (sent → downloaded → reviewed)
- [ ] Day-7 retro: which channel converted best, what to repeat for iOS launch
