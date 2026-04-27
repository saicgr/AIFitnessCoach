# Zealova — Merch as a Marketing Engine

> Inspired by GymBeat's "THINK YOU CAN BEAT MY REPS?" tee + the BeFIT Paltim mirror-selfie post. The pattern: **a shirt that's a callout becomes free distribution**. This doc treats merch not as revenue but as a paid acquisition channel that the user funds.

The single insight: **a worn shirt is a billboard the user pays you to wear**. Every other idea here orbits that. The cheapest possible CAC is "user buys a $35 tee, posts a mirror selfie, friend Shazams the brand, downloads the app."

---

## 1. The thesis

Apparel pulls a triple shift for Zealova:

| Job                 | What it does                                                                                          | KPI                                            |
| ------------------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| **Acquisition**     | Worn in public → impressions → installs                                                               | Installs attributed to QR / referral code      |
| **Retention**       | Tied to streaks/PRs → user can't quit because the shirt makes the receipts visible                    | D30 retention of buyers vs. non-buyers         |
| **Self-expression** | The thing the user wants is to flex their identity as a serious lifter; we just give them the canvas | Repeat purchase rate, UGC volume per buyer     |

Optimization target: **impressions per dollar of merch revenue**. Don't chase margin on the first tee — chase reach.

---

## 2. Print-on personalization — the core library

This is the priority. GymBeat's shirt works because the **back of a shirt is a billboard** and the user becomes the medium. Personalization makes it the user's billboard, not Zealova's, which is why they actually wear it.

### 2.1 Anatomy of a personalized print

Every Zealova tee has three print zones, addressable independently:

| Zone               | Purpose                | Lifetime                          |
| ------------------ | ---------------------- | --------------------------------- |
| **Front-chest**    | Brand wordmark / logo  | Static — same on every tee        |
| **Back-billboard** | The callout / data flex | Personalized at order time        |
| **Hem-tag inner**  | QR + NFC patch         | Personalized — links to user URL  |

The back is what other people read at the squat rack. The chest is what *the buyer* sees in the mirror (drives self-image). The hem-tag is the invisible conversion device.

### 2.2 Template families (the catalog)

Each template is a back-print pattern that pulls live user data at order time. Stored in `print_jobs.template_id` + `data_snapshot` JSON. New templates ship monthly to keep the catalog fresh.

#### Family A — The Callout (the GymBeat play, sharpened)

The buyer is challenging strangers. Friction-free virality because anyone reading it is incentivized to engage.

| Template               | Back print                                                          | Data source                                |
| ---------------------- | ------------------------------------------------------------------- | ------------------------------------------ |
| `BEAT_MY_SQUAT`        | "BEAT MY SQUAT? `{squat_max}` lb · `@{username}`"                  | `performance_logs.squat.1rm`               |
| `BEAT_MY_DEADLIFT`     | "PULL MORE THAN `{deadlift_max}` lb? PROVE IT — `@{username}`"     | `performance_logs.deadlift.1rm`            |
| `STREAK_FLEX`          | "`{streak_days}` DAYS. NO MISSED LIFTS. — `@{username}`"           | `streaks.current_count`                    |
| `WORKOUT_COUNT`        | "`{n}` WORKOUTS DEEP. `{n+1}` TOMORROW. — `@{username}`"           | `workouts.count(is_completed=true)`        |
| `RANKED_TOP`           | "TOP `{percentile}`% ON ZEALOVA · `{year}`"                         | Wrapped percentile                         |
| `VOLUME_FLEX`          | "MOVED `{tons_lifted_ytd}` TONS THIS YEAR"                          | Sum of weight × reps × sets YTD            |

Mechanic: every tee has a back QR that opens the user's public profile. Other gym-goers who Shazam-the-shirt land on `zealova.com/u/{username}` → "Try to beat them" CTA → install.

#### Family B — The Identity (self-image, less aggressive)

Some users won't wear a callout but will wear a label. These convert lurkers, not extroverts.

| Template          | Back print                                                  | Data source                              |
| ----------------- | ----------------------------------------------------------- | ---------------------------------------- |
| `COACHED_BY`      | "COACHED BY `{COACH_NAME.upper()}`"                         | `users.preferences.coach_id` (persona)   |
| `SPLIT_LABEL`     | "PUSH · PULL · LEGS · REPEAT"                               | `gym_profiles.training_split`            |
| `MWF_CREW`        | "MWF CREW — SINCE `{join_year}`"                            | `gym_profiles.workout_days`              |
| `EVERYDAY_LIFTER` | "7/7. EVERYDAY LIFTER."                                     | `gym_profiles.workout_days.length == 7`  |
| `HOME_GYM`        | "BUILT IN A `{floor_area}` GARAGE"                          | `gym_profiles.workout_environment=='home_gym'` |
| `GYM_NAME`        | "`{gym.name.upper()}` REGULAR — `{gym.city}`"              | `gym_profiles.address` + `city`          |

The "GYM_NAME" tee is the sleeper hit: turns local gyms into co-marketing partners. They see their members wearing a tee that promotes both the gym and Zealova; some will stock it.

#### Family C — The Receipt (data dense, post-magnet)

The shirt is itself a piece of UGC. Designed to be photographed.

| Template          | Back print                                                                      | Notes                                  |
| ----------------- | ------------------------------------------------------------------------------- | -------------------------------------- |
| `WORKOUT_RECEIPT` | Receipt-style block: date · gym · exercises · reps · PRs · total tonnage        | Snapshot of one specific session       |
| `YEAR_RECEIPT`    | Wrapped condensed: workouts · PRs · streaks · volume · top exercise             | Year-end. Once-a-year drop.            |
| `PR_TICKET`       | Concert-ticket format: "ADMIT ONE · `{exercise}` · `{weight}` · `{date}`"      | Each PR can be turned into a ticket    |
| `PERIODIC_TABLE`  | Periodic-table cell: element symbol = exercise abbrev, atomic number = max rep | Nerdy, photographable, data-dense      |

Each of these is **photogenic by design** — meaning users post them without prompting. The Receipt template is also reusable as a digital share-gallery template (already planned for `lib/screens/share/templates/`), which means buyers see it pre-purchase as a digital share, decide they want it on a shirt, then buy.

#### Family D — The Achievement Drop (scarcity)

Designs locked behind milestones. You can't buy them — you earn the right to.

| Template            | Unlock condition                          | Visual                                          |
| ------------------- | ----------------------------------------- | ----------------------------------------------- |
| `CENTURY_CLUB`      | 100 lifetime workouts                     | "100" in monospace + workout dates as confetti  |
| `STREAK_DEMON_30`   | 30-day streak                              | Flame motif, day count                          |
| `STREAK_DEMON_100`  | 100-day streak                             | Black tee, gold print, tier badge               |
| `1RM_DOUBLED`       | Doubled any 1RM since join date            | Before / after numbers, arrow                   |
| `WRAPPED_1PCT`      | Top 1% of users by volume                  | Invite-only. Numbered (e.g. 0247/2026)         |
| `CHALLENGE_WINNER`  | Won a community challenge                  | Limited-edition, dated, signed-by-coach print   |

Scarcity is the marketing. A user has to post their Century Club tee — they earned it.

#### Family E — Coach-signed drops

Each AI coach persona gets one signature design per year. Switching your active coach in `preferences.coach_id` unlocks their drop.

| Coach          | Aesthetic                                         |
| -------------- | ------------------------------------------------- |
| Coach Mike     | Blue-collar, garage-gym, hand-painted block letters |
| Dr. Sarah      | Clinical, anatomical line drawings                |
| Sergeant Max   | Olive drab, military-stencil typography           |
| Zen Maya       | Watercolor, calligraphic Japanese-inspired        |
| Hype Danny     | Neon-on-black, rave / rave-energy                 |

Switching coach mid-year creates a wardrobe rotation. We're literally selling the user different identities and the data already supports it.

### 2.3 The data-snapshot contract

```jsonc
// print_jobs row
{
  "id": "uuid",
  "user_id": "uuid",
  "template_id": "BEAT_MY_DEADLIFT",
  "data_snapshot": {
    "deadlift_max": 455,
    "username": "chetang",
    "snapshot_at": "2026-04-27T14:00:00Z",
    "unit": "lb"
  },
  "fulfilment_provider": "printful",
  "fulfilment_status": "submitted",
  "fulfilment_id": "pf_abc123"
}
```

**Why a snapshot, not a live join**: shirts get printed once. If the user's max changes between order + ship, we don't reprint. The snapshot also gives us a clean "as of `{date}`" footer on every tee — which adds a temporal credibility layer ("this was true on the day I bought it").

### 2.4 Live preview before checkout

User picks a template → app pulls their data into a live mockup → they see exactly what the shirt will say → tweak (e.g. show kg vs lb, hide last name) → confirm. The preview is itself a screenshot they post to Instagram with "got my new tee coming, wait for it." Shipping the preview as a shareable card on its own is half the marketing.

### 2.5 Edge cases the personalization engine must handle

- **Empty data** — user has no PRs yet. Fallback: show "Day 1." with the join date. Never print zero or "null".
- **Insulting numbers** — a 95 lb deadlift might embarrass the user. Add a "minimum threshold" gate per template (`BEAT_MY_DEADLIFT` only purchasable if 1RM ≥ 225 lb) so we never sell shirts that hurt the buyer.
- **Unit preference** — respect `users.preferred_workout_weight_unit` (per memory: lbs default for this user). Don't print the wrong unit.
- **Profanity in username** — moderate `data_snapshot.username` against a blocklist before submitting to print provider.
- **Privacy** — user can opt to print *only initials* instead of full username. Default to full to maximize discoverability.
- **Weight loss / cut context** — `STREAK_DEMON` template assumes pride in continuity, but a user in a cutting phase might have lost streak. Conditional copy: if `streak_days < user_lifetime_max_streak`, show the lifetime max instead. Never shame the buyer.

---

## 3. Earned vs. paid merch mechanics

Paid-only merch is a store. Earn-only merch is a loyalty program. We want both, in tension.

### 3.1 The unlock ladder

```
Day 0       → ZEALOVA logo tee (paid, $30, anyone)
Workout #1  → "Day 1" sticker pack (free with first order)
Workout #10 → Coupon: 15% off any Identity tee
Streak 7    → Coupon: 20% off any Callout tee
Streak 30   → STREAK_DEMON_30 unlocks (paid, $40, gated)
PR doubled  → 1RM_DOUBLED unlocks (paid, $40, gated)
Workout #100 → CENTURY_CLUB unlocks (paid, $45, gated)
Top 5%      → WRAPPED 5% drop (paid, $50, gated, numbered)
Top 1%      → WRAPPED 1% drop (FREE, invite-only, numbered)
Challenge W → CHALLENGE_WINNER drop (FREE, custom-printed with their name)
```

The ladder solves the "why pay for advertising" question: *the shirt itself is the reward*. Users grind to unlock the next design. The grind is also the workout. Loop closes.

### 3.2 Wear-to-earn

The shirt earns XP when worn. Honor system, lightly verified.

| Action                              | XP    | Cap        |
| ----------------------------------- | ----- | ---------- |
| Toggle "wearing my Zealova tee" on workout start | 25    | 3 / week   |
| Post a mirror selfie tagged `#ZealovaFit`        | 50    | 1 / day    |
| Vision-detected tee in any uploaded photo        | 25    | 5 / week   |
| Wear during a streak save-day                    | +2× streak token | unlimited |
| Tee detected in a friend's post (group selfie)   | 75 each | 2 / week  |

The cap matters — without it, users grind XP via fake selfies. With it, the constraint creates posting density without spam.

### 3.3 Streak-saver via merch

Existing feature: streak savers (tokens that revive a missed day). Make them earnable through merch:

- Posting 3 mirror selfies in a week earns 1 token.
- Wearing the tee during a workout that the user posts earns 0.5 token.
- Tapping the NFC patch in the hem before midnight on a missed-workout day = 1 token (only triggers if the day would have broken streak).

This is the masterstroke: **the shirt is literally insurance against losing what makes the user proud**. Once a user has spent $40 on a streak-tied tee, churn drops materially.

---

## 4. Distribution / activation loops

Merch only matters if it's seen. Each loop below is a place where a worn shirt converts a stranger.

### 4.1 In-app loops

- **"Shirt spotted" auto-tag**: Re-use `VisionService.classify_media_content` on uploaded workout/progress photos. Add `apparel_brand: 'zealova'` detection. When detected: stamp the post with a 🏷️ Zealova badge, +25 XP, post lands in the new "Spotted in the wild" social tab.
- **Outfit of the Day**: Daily Explore section showing 6 user posts where the tee was detected. Tap to vote. Top vote each day → free tee credit next month. Drives daily app opens (already a top-funnel goal).
- **Dressed for it**: Pre-workout screen prompts "Wearing your Zealova tee today? 👕" with a photo button. Photo posts to feed automatically with the workout summary. This couples the shirt to the workout itself, not just to social.

### 4.2 Out-of-app loops

- **QR on hem-tag**: Anyone who flips the tag → `zealova.com/u/{username}` → "Try to beat their `{deadlift_max}` lb deadlift" → install CTA. Track installs by referrer username for attribution + reward (each install attributed to a user = 100 XP for them).
- **NFC patch (Pro tier)**: Tap-to-follow. Tap → opens the wearer's public profile + offers a "Follow" CTA on whatever fitness app the tapper has. If they don't have Zealova, App Store deep link.
- **Mirror QR**: Print a small QR on the front-bottom hem so a mirror selfie naturally captures it. The QR encodes a **share-aware deep link** that opens to a "Compare your stats" overlay. Mirror selfies stop being passive — they become recruitment.
- **Gym poster bundle**: Local gyms get a poster bundle free (12 posters, A2) showing 6 of their members in Zealova tees. We pull post photos that opted in via a "let your gym use this" toggle. Free physical advertising in every partner gym.

### 4.3 The viral mirror-selfie quest

Daily quest: "Post a mirror selfie in your Zealova tee today." +50 XP + 1 raffle entry for a $100 gym credit weekly draw. Quests are streak-eligible — miss a day, lose the daily-quest streak (separate from workout streak). Posting the tee becomes a habit, not a one-time act.

---

## 5. Referral via merch

Referrals + apparel multiply because the act of referring is itself wearing the shirt.

### 5.1 Bring-a-Friend bundle

- Buy 2 tees → 30% off both.
- Tee #2 only ships when the friend signs up + completes onboarding.
- Both users get a paired badge: "Lifting partners since `{date}`" in their public profile.
- Both users' tees print "REC'D BY `@{partner_username}`" as small-print on the side seam — receipt of the partnership.

The partnership badge gives the gift social value beyond the shirt.

### 5.2 Sponsor-a-lifter

- Pro user spends 5,000 XP → ships a tee + 1 month of Zealova Pro to a friend.
- Friend's onboarding screen: "`{sponsor_name}` got you started — accept their challenge"
- Sponsor gets a "Sponsor" trophy after 3 successful sponsorships.
- The sponsored tee prints "SPONSORED BY `@{sponsor_username}`" — receipt.

This is functionally a referral program where the shirt is the incentive, not the cash. Way better unit economics than a $20 referral credit.

### 5.3 Squad merch

- Group of 4+ users join a "squad" → unlock matching squad tees with a custom 3-letter squad name on the back.
- Squad tees are the only way to get matching designs. Drives squad creation, which drives retention via social accountability.
- Each squad's tee back also prints squad rank ("RANK #14 GLOBALLY") — competitive pressure.

---

## 6. Influencer / ambassador

Don't pay creators. Recruit them with merch.

### 6.1 The ambassador tier

- 1,000+ followers anywhere + 30+ workouts logged → eligible for ambassador tier.
- Ambassadors get: 4 free tees per year, custom QR routing (their handle), 20% off code for their audience, priority on new drops.
- In return: post 1 mirror selfie + 1 workout-summary share per month, attribute via custom QR.
- Ambassadors with the highest install attribution unlock signature designs (their handle on the back of a tee they helped design).

### 6.2 Coach co-design

Real-world coaches (PTs, S&C coaches) co-design tees. Their face/handle on the tag, their cut of revenue, Zealova brand on the chest. Their clients buy them. The coach is incentivized to push the app to their roster because every install adds to their cut.

### 6.3 Local-gym partnership tee

A specific gym (e.g. "BeFIT Paltim" from the screenshot) co-designs a tee with their logo. Zealova prints + fulfils. Gym gets 30% revenue share. Gym posts about it on their socials. Members buy. Gym's owner is now incentivized to keep promoting Zealova.

This is the long tail — 50 small gym partnerships > 1 big sponsorship.

---

## 7. Community-generated merch

Users submit designs. We print + sell. Original designer gets royalties.

- **Design contests**: Monthly theme ("Leg Day", "AM Crew", "Garage Gym"). Submissions voted on by community. Winner's design printed for 30 days, designer gets 20% of revenue.
- **Quote contests**: "Submit the line that goes on the back of next month's Callout tee." Lowest friction — no design skill needed, just wit. Best submission becomes the next BEAT_MY_REPS variant.
- **Squad-designed tees**: Squads with 50+ members can submit their own back-print, fulfilled by Zealova. Squads pay nothing; we get the design + the squad's wear-and-post.

Each user-generated tee comes with a "DESIGN BY `@{designer}`" credit on the inside hem — receipts that the designer flexes too.

---

## 8. Tech stack to ship it

The mechanics above need infrastructure. Order of build, cheapest first:

| Phase | Component                                                                | Stack                                                                |
| ----- | ------------------------------------------------------------------------ | -------------------------------------------------------------------- |
| 1     | `print_jobs` table + Printful/Printify API integration                   | New backend module `services/merch_service.py` + webhook for status  |
| 1     | Live template preview (back print) in-app                                 | New screen `lib/screens/merch/template_preview_screen.dart`         |
| 1     | Checkout via Stripe (existing) → Printful order create on payment success | Stripe webhook → `merch_service.fulfil()`                           |
| 2     | Vision detection of Zealova tees in uploaded photos                      | Extend `VisionService.classify_media_content` w/ apparel branch      |
| 2     | NFC patch encoding + tap handler                                         | Universal Link `zealova.com/nfc/{tee_id}` → backend resolve         |
| 2     | XP integration for wear-to-earn                                          | New event types in existing XP service: `MERCH_WORN`, `SELFIE_POSTED` |
| 3     | Achievement-locked drops UI (locked tile w/ unlock progress)              | New widgets in existing trophies module                              |
| 3     | "Spotted in the wild" social tab                                          | New tab in `lib/screens/social/`                                     |
| 3     | Outfit of the Day vote                                                    | New endpoint `GET /api/v1/merch/ootd` + voting                       |
| 4     | Squad merch + custom design submission                                    | New `merch_designs` table + moderation queue                         |
| 4     | Ambassador dashboard                                                      | New role flag in `users.role`, new `/ambassador` portal              |

### 8.1 Print provider choice

| Provider  | Pro                                                  | Con                                          |
| --------- | ---------------------------------------------------- | -------------------------------------------- |
| Printful  | Best API, garment quality, US warehouses             | Higher unit cost                             |
| Printify  | Cheap, multi-vendor                                  | Quality variance, more rejected prints       |
| Custom Ink | Best for bulk gym partnerships                       | No per-item personalization API              |

Recommendation: **Printful for personalized, Custom Ink for bulk partner orders.** Hide the provider behind a `MerchProvider` interface so we can swap.

### 8.2 The "is this our shirt" classifier

Reuse `VisionService` with a new prompt: "Is the person in this photo wearing a tee with a Zealova logo or text? Respond JSON: `{detected: bool, confidence: float, region: 'front'|'back'|'unknown'}`." Cost ≈ $0.0001/call. Run on every post to the social feed asynchronously.

False positives are fine here — we're not gating money on it, just stamping a badge + giving 25 XP. False negatives cost us a free engagement, not a chargeback.

### 8.3 Pricing math

- Tee unit cost (Printful, personalized DTG): $14
- Shipping: $5
- Stripe fee: ~$1.50 on a $35 sale
- Margin: ~$14.50 per tee

If each tee creates 1 install via QR/NFC and our LTV/install is $30, every shirt sold is **net +$44.50**. Even at 0.3 installs per tee we break even on acquisition. The point is **not the margin** — it's the impressions and the install attribution.

---

## 9. Creative campaigns (launch-day fuel)

### 9.1 "The Receipt Drop" (launch)

- Every user with 30+ workouts gets a free Year-Receipt tee with their stats on the back.
- Shipped during Wrapped week.
- Embargo lifts on a single day. Synchronized social bomb: thousands of users post the same template on the same day with their own data.
- The launch *is* the marketing.

### 9.2 "Beat Mine" (sustained)

- Every Sunday, the leaderboard generates a Callout tee for the top 100 users by weekly volume.
- Discount code in their inbox. Print arrives Friday — they wear it the next week.
- Permanent loop tied to the weekly reset.

### 9.3 "Ghost of Lifts Past" (Halloween)

- Limited-edition glow-in-the-dark tee. Back print: a chart of the user's workout history with missed days as ghost icons.
- Shame is a powerful motivator. Done with humor, not cruelty.

### 9.4 "365" (year-end)

- Tee printed with a 365-day calendar where each day is filled in if the user worked out.
- Ships Jan 1. Tracks the previous year.
- Becomes a permanent collectible — different each year.

### 9.5 "First 100" (city campaigns)

- The first 100 users in any city to hit 100 workouts get a city-specific tee.
- "FIRST 100 · CHICAGO · 2026"
- Numbered. Hyper-local. Drives early adoption in new markets where Zealova's brand isn't established yet.

### 9.6 "Quest Drops" (recurring)

- Monthly fitness challenge → completion = drop entry.
- Challenge is hard enough that completion is itself braggable.
- Tee acts as the trophy. (Cheaper than digital trophies feel — physical trophy that you literally wear.)

---

## 10. Launch sequence

| Wave | Duration | Ships                                                            |
| ---- | -------- | ---------------------------------------------------------------- |
| **W1** | 2 wk    | Print-on personalization + 6 Callout templates + live preview + Stripe checkout |
| **W2** | 2 wk    | Identity + Receipt families + Wear-to-earn XP + mirror-selfie quest |
| **W3** | 2 wk    | Vision "shirt spotted" detector + Spotted-in-the-wild tab + OOTD vote |
| **W4** | 2 wk    | Achievement-locked drops + Streak Demon + Century Club           |
| **W5** | 2 wk    | NFC + hem-tag QR + sponsor-a-lifter + paired badges              |
| **W6** | 2 wk    | Squad merch + community design contests                          |
| **W7** | 2 wk    | Ambassador tier + local-gym partnership poster bundle            |
| **W8** | ongoing | Receipt Drop launch (synchronized Wrapped tie-in) → "Beat Mine" weekly loop |

The W1 ship alone is sellable. Everything after compounds.

---

## 11. KPIs

Track per cohort of buyers. Compare vs. matched non-buyer cohort.

### 11.1 Acquisition

- Installs attributed to QR/NFC per shirt sold (target: ≥ 0.5)
- Mirror-selfie posts per shirt sold (target: ≥ 2)
- Shirts visible in feed posts per week (target: 5%+ of all posts after W3)
- Cost per attributed install via merch vs. paid social

### 11.2 Retention

- D30 retention of buyers vs non-buyers (target: +15pp lift)
- Streak length distribution buyers vs non-buyers
- Repeat purchase rate within 90 days (target: ≥ 25%)

### 11.3 Engagement

- Wear-to-earn toggles per user per week
- "Shirt spotted" badges issued per week
- OOTD vote participation rate

### 11.4 Revenue

- Revenue per tee (target ≥ $14 net contribution)
- Subscription conversion rate among tee buyers vs non-buyers
- Sponsor-a-lifter activations per month
- Ambassador-attributed installs per month

---

## 12. Risks + edge cases

| Risk                                                              | Mitigation                                                                                        |
| ----------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| Personalized data on shirt becomes embarrassing (e.g. lost streak) | Snapshot freezes at order time. Templates have minimum-threshold gates. Conditional fallback copy. |
| Username changes after print                                      | Snapshot. The shirt is "as of `{date}`" — a feature, not a bug.                                     |
| Profanity in username                                             | Blocklist + manual review on flagged. Default-strict rules for printed text.                       |
| Print provider misprints                                          | `print_jobs.fulfilment_status` machine + reprint workflow + auto-refund if 2nd attempt fails.       |
| Shirt exposes user location (GYM_NAME tee)                        | Opt-in only. Default to city, not address. Privacy doc updated.                                     |
| User asks for full data deletion (DSAR)                          | `print_jobs.data_snapshot` is part of the user's data. Already covered by the existing DSAR flow.    |
| Trademark / IP on community designs                              | Submission terms-of-service + automated logo-detection on uploads + manual review.                  |
| Shipping returns / sizing complaints                              | Standard Printful return policy. Don't accept returns on personalized items (industry-standard).    |
| Counterfeits                                                       | Hem-tag NFC chip per shirt is unique + signed. Resells without working chip = obvious fake.         |
| Shipping cost killing the value prop in non-US markets            | Printful EU + UK warehouses for parity. Roll out US-first; expand W6+.                              |

---

## 13. The single point of leverage

If we ship one thing this quarter, it's **the personalized Callout tee with QR routing to a public profile**.

The reason: it stacks five mechanics into one $35 transaction —

1. The user pays us to wear our brand (acquisition).
2. The shirt content is a flex of their progress (retention via identity).
3. The QR converts strangers (paid acquisition channel funded by the user).
4. The mirror-selfie makes it social (organic reach).
5. The personalization makes it impossible to copy or counterfeit (defensibility).

Everything else in this doc is iteration on top of that core unit. Ship that first, measure impressions per dollar, scale what works.

---

**Last updated:** 2026-04-27
**Owner:** Growth + Merch
**Linked tables:** `print_jobs` (new), `trophies`, `gym_profiles`, `users`, `performance_logs`, `streaks`

---

## 14. Founder solo-cast — 4 shirts that *use the social app*

The earlier solo-cast section (Daily Driver / Receipt / Founder Tee / Loud One) was safe. Below is the creative version, tightened around one insight:

> **Zealova has a social feed. The shirts shouldn't compete with social — they should *trigger* social.**

A "BEAT MY REPS" tee on a stranger is a dead end (where do they go? what do they do?). A Zealova tee is different: there's a place to actually beat your reps — inside the app, on your public profile, on the feed. Each shirt below has a **social hook that closes the loop**: read shirt → scan QR → land somewhere in-app where the challenge can actually be answered.

The four shirts function as **four different funnels into four different parts of the social product**.

### 14.1 Shirt #1 — **The Open Challenge** (funnel → public profile + Beat Mode)

The shirt that earns the right to say "Think you can beat my reps?" — because Zealova ships the rails to actually do it.

**Front-chest:** small wordmark + a printed lift number that updates per shirt batch (`SQUAT // {date}`). Quietly resets like a leaderboard.

**Back (large, monospace, deliberate):**
```
   THINK YOU CAN
   BEAT MY {LIFT}?

   PROVE IT IN
   THE APP.

   {QR}
   zealova.com/u/chetang/beat
```

**The /beat route is new and important.** It's not just a profile view — it's a **Beat Mode** screen that:
- Shows your current PR for the named lift, with the date.
- Has a "Beat it" CTA that creates a head-to-head challenge: app schedules a workout that ends in a 1-rep test of the same lift, due within 30 days.
- If they beat it, they get a "Dethroned `@chetang`" badge in their public profile **and** a 50% off code for their own version of this exact shirt with their numbers on it.
- Top 5 people who beat the founder this month get featured on the Zealova feed Sunday morning ("Founder dethroned this week — meet the lifters who did it").

**Why this is creative:** the shirt isn't a brag, it's a **wager**. The social product gives strangers a place to settle the wager. And losing the wager is *good for Zealova* — every "dethroning" is a UGC post, a feed feature, and a viral hook.

### 14.2 Shirt #2 — **The Live Profile** (funnel → real-time Spotify-style "now lifting" widget)

Spotify popularized the idea that a person's identity is *what they're doing right now*, not what they did once. Apply it to lifting.

**Front-chest:** small Zealova wordmark + handle.

**Back (clean, Apple-Music-receipt aesthetic):**
```
   NOW LIFTING

   ─────────────
   @chetang is at
   {gym_name}
   moving {tons_lifted_today} lb
   today.
   ─────────────

   LIVE → {QR}
```

**The "now lifting" page is a real live page** — `zealova.com/u/chetang/live` — that pulls:
- Current gym profile (the active one we just built).
- Today's workout in progress (set count, tonnage, time elapsed).
- A "Cheer" button that sends a haptic + sound to the wearer's phone mid-workout (think Strava kudos but during the actual set).
- A "Join Today" button that adds the same workout to the visitor's queue if they're a Zealova user, or opens onboarding into that workout if they're not.

**Why this is creative:** the shirt becomes a **live tracker for whoever is reading it**. They scan it during your warm-up; 40 minutes later their phone shows you finished, with your tonnage. That's a stickier first-touch than any landing page. It also turns the gym into shared theater — your set has spectators who can react in-app while you're still under the bar.

The shirt is *most interesting when you're actually lifting*, which is exactly when people see it. Perfect alignment between context and content.

### 14.3 Shirt #3 — **The Bounty** (funnel → community challenge with a real prize)

A shirt that makes the wearer the prize. The social app already supports challenges between users — wire one to a piece of physical apparel.

**Front-chest:** the word `BOUNTY` in stencil with `0` next to it. The 0 is updated each batch — this is the **bounty number**, the count of people who've beaten you so far.

**Back (sparse, high-contrast, evocative):**
```
   BOUNTY:

   FIRST 10 PEOPLE
   TO HIT MY 1RM
   GET THIS SHIRT
   FREE.

   CLAIM AT
   {QR}
```

**The /bounty page** is a community challenge with:
- Live counter (`3 / 10 claimed`).
- Leaderboard of attempters with their current best.
- The QR routes to a challenge-acceptance flow: user opts in, app schedules a 1RM test workout, claim is verified by AI form-checking the lift video (re-using the form-video infrastructure we already have).
- First 10 verified claims get a free personalized version of *this exact shirt* shipped to them, with their own bounty number on the back ("BOUNTY CLAIMED · #03").

**Why this is creative:** it makes the shirt a **physical artifact of competition**. The bounty winners proudly wear shirts that say they beat the founder. Every claimer becomes a walking testimonial for the brand. And the cost of fulfillment is capped (you give away 10 shirts, you've spent $140 in cogs to get 10 verified-strong ambassadors who chose to chase a Zealova bounty — that's better targeting than any Meta lookalike).

The bounty model also creates **scarcity-driven buying** for non-claimants. People who didn't claim still want the artifact, so they'll buy a non-bounty version of the design at full price.

### 14.4 Shirt #4 — **The Mirror Hack** (funnel → the social feed via a vanity mirror moment)

Most gym selfies are taken in a mirror. The mirror flips the image. Use that.

**Front-chest:** mirrored Zealova wordmark — looks scrambled in real life, **reads correctly in a mirror selfie**.

**Back (printed mirror-reversed on purpose — render with `transform: scale(-1, 1)` in the spec):**

When read directly: looks like backwards gibberish.
When read in a mirror selfie: reads perfectly as —
```
   YOUR
   MIRROR
   KNOWS THE
   TRUTH.

   POST IT.
   #ZealovaFit
   {QR}
```

The QR is also mirror-printed so it scans correctly *only* from the mirror image (i.e., from a selfie). Scanning the physical shirt directly fails — which is the joke and the mechanic.

**The /mirror route** — what the QR opens — does three things:
- Auto-detects the user is arriving from a mirror selfie context (the QR carries a `?src=mirror` param).
- Opens a **selfie-share template** in the app: pre-formatted with the user's stats, ready to post to the Zealova feed in two taps.
- Issues a one-time `MIRROR_HACK` badge on first use, so each tee-wearer gets credit for "discovering" the gimmick.

**Why this is creative:** it weaponizes the most-photographed surface in any gym (the mirror) as a **deliberate marketing canvas**. The shirt looks weird in person — which is itself a conversation starter ("why is your shirt backwards?" → wearer shows them in the mirror → reveal moment). Reveals are sticky in a way that slogans aren't. People film the reveal. The film of the reveal is the post that goes on TikTok. The TikTok is the install funnel.

It's also the first shirt in fitness apparel I'm aware of that's literally **only readable in a selfie**. That's the kind of design choice that gets press coverage on its own ("This fitness startup made a shirt you can only read in a mirror"). One Hacker News post or one Reddit /r/gym thread about the mechanic and you're spending zero on press for a week.

### 14.5 The four shirts as a single product story

Each shirt funnels into a different part of the social product. Read together they tell a story: **Zealova is the place where the things people brag about on shirts are actually verifiable, beatable, and shareable.**

| Shirt           | Social hook                  | New page / feature           | What the visitor does     |
| --------------- | ---------------------------- | ---------------------------- | ------------------------- |
| Open Challenge  | Beat Mode head-to-head        | `/u/{handle}/beat`           | Accept the wager          |
| Live Profile    | "Now lifting" Spotify-style   | `/u/{handle}/live`           | Cheer mid-set             |
| Bounty          | First-N-to-beat-me prize     | `/u/{handle}/bounty`         | Claim the bounty          |
| Mirror Hack     | Mirror-only readability     | `/m?src=mirror`              | Post pre-templated selfie |

These four pages are a **product surface area worth building anyway**, even without the shirts — they're new social mechanics. The shirts are the distribution. The pages are the substance. Apparel without the pages is decoration. Pages without the apparel are an empty room. Together they're a flywheel.

### 14.6 What to ship first

Order of build, ranked by impact-to-effort:

1. **`/u/{handle}/beat` page + Beat Mode workout flow** — biggest unlock, reuses existing PR + workout-scheduling infrastructure. 3-4 days of work.
2. **Print Open Challenge tee with personalized SQUAT/DEAD/BENCH numbers** — one Printful template + the `print_jobs` data-snapshot work covered in §2.3. 2 days.
3. **`/u/{handle}/live` Now Lifting widget** — read-only first; "Cheer" button can ship in v2. Reuses today.py + workout-in-progress data. 2-3 days.
4. **Mirror Hack tee + `/m?src=mirror` post-template** — the `/m` route is mostly an existing share-template. Mirror-printed art is a Printful design upload, no engineering. 1 day of design + 1 day of QR routing.
5. **Bounty page + verification flow** — biggest engineering scope (depends on form-video AI). Cut for v2, run a manual-verified beta version meanwhile (you watch the videos yourself and award the shirts).

You can wear all four within 6 weeks. Habit-build during the build cycle. By the time the social pages are live, you've already done 60+ gym sessions in the shirts and have a personal narrative to attach to the launch ("here's what 60 days of being my own customer looked like").

### 14.7 The thing that makes this not generic

Every gym apparel brand has a "callout" tee. Gymshark has them. GymBeat has them. Bo+Tee has them. **None of them have a place to actually answer the callout.**

Zealova does — it's the social feed, the public profile, the head-to-head challenge primitive. The shirts above are not just merch with QR codes; they're **physical entry points into a software product that turns shit-talking into measurable competition**. That's the moat. That's why these designs only make sense for Zealova, not as generic streetwear.

Tagline for the eventual brand campaign: **"Bring receipts."** Every shirt is a receipt for a claim. Every claim is testable in the app. Every test produces another receipt. Loop.
