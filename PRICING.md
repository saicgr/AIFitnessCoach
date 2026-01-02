<!-- We are transparent about being a premium-only app, and include this in our app images, app description, and website. We also surface this information in-app before the user ever gives us their email. Google Play displays all subscription apps that are not also pay-to-download as free in search, and this is not controlled by us. -->


# FitWiz - Pricing & Cost Analysis

## Executive Summary

**Total Estimated Monthly Cost for 1000 Users: $140 - $215/month**

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| OpenAI API | $40 - $115 | GPT-5 nano/mini hybrid |
| Render | $25 | Fixed backend hosting |
| Supabase Pro | $25 | Database + Auth |
| Chroma Cloud | $29 | Vector database (Starter) |
| Firebase FCM | $0 | Push notifications FREE |
| Resend | $20 | Email (50K emails/month) |
| AWS S3 | $0 | $300 credits available |
| **TOTAL** | **$140 - $215** | |

**Fixed Costs: $99/month** (Render + Supabase + Chroma + Resend)

---

## OpenAI Model Strategy

| Task | Model | Input/Output Cost | Why |
|------|-------|-------------------|-----|
| Intent extraction | GPT-5 nano | $0.05/$0.40 per 1M | Simple classification |
| Chat responses | GPT-5 nano | $0.05/$0.40 per 1M | Good enough for chat |
| Workout generation | GPT-5 mini | $0.25/$2.00 per 1M | Better creativity |
| Food image analysis | GPT-5 nano | $0.05/$0.40 per 1M | Vision + cheap |
| Onboarding | GPT-5 nano | $0.05/$0.40 per 1M | Simple Q&A |
| Embeddings | text-embedding-3-small | $0.02 per 1M | Already cheap |

---

## Pricing Structure

| Plan | Monthly | Yearly | One-time |
|------|---------|--------|----------|
| Free | $0 | - | - |
| Premium | $5.99 | $47.99 (33% off) | - |
| Ultra | $9.99 | $79.99 (33% off) | - |
| Lifetime (Ultra) | - | - | $99.99 |

### Competitor Comparison (Gravl)

| Plan | Your App | Gravl | Difference |
|------|----------|-------|------------|
| Monthly | $5.99 / $9.99 | $14.99 | 60-70% cheaper |
| Yearly | $47.99 / $79.99 | $89.99 | 10-45% cheaper |
| Lifetime | $99.99 | $199.00 | 50% cheaper |

**Strategy:** Undercut competitors to build user base, raise prices later once established.

---

## Tier Comparison

| Feature | Free | Premium ($5.99/mo) | Ultra ($9.99/mo) | Lifetime ($99.99) |
|---------|:----:|:------------------:|:----------------:|:-----------------:|
| **PRICING** | | | | |
| Monthly | $0 | $5.99 | $9.99 | - |
| Yearly | - | $47.99 | $79.99 | - |
| One-time | - | - | - | $99.99 |
| | | | | |
| **AI CHAT** | | | | |
| Messages/day | 5 | 30 | 100 | 100 |
| AI Model | GPT-5 nano | GPT-5 mini | GPT-5 mini | GPT-5 mini |
| Chat history | 7 days | 90 days | Forever | Forever |
| | | | | |
| **WORKOUTS** | | | | |
| Generations/week | 1 | Daily | Unlimited | Unlimited |
| Edit workouts | - | Yes | Yes | Yes |
| Save favorites | - | 5 | Unlimited | Unlimited |
| Save as template | - | - | Yes | Yes |
| Import workouts | - | Yes | Yes | Yes |
| Activity between rests | - | Yes | Yes | Yes |
| | | | | |
| **WORKOUT METRICS** | | | | |
| Basic stats (volume, duration) | Yes | Yes | Yes | Yes |
| 1RM calculator | - | Yes | Yes | Yes |
| PR tracking | - | Yes | Yes | Yes |
| Strength standards | - | - | Yes | Yes |
| Progressive overload suggestions | - | - | Yes | Yes |
| | | | | |
| **FOOD LOGGING** | | | | |
| Photo scans/day | 1 | 5 | 10 | 10 |
| Calories only | Yes | - | - | - |
| Full macros (C/P/F) | - | Yes | Yes | Yes |
| Portion estimates | - | Yes | Yes | Yes |
| Restaurant menu help | - | - | Yes | Yes |
| | | | | |
| **SOCIAL & SHARING** | | | | |
| Share to Instagram | - | Yes | Yes | Yes |
| Share accomplishments | - | Yes | Yes | Yes |
| Shareable workout links | - | - | Yes | Yes |
| Friends/following | - | - | Yes | Yes |
| Leaderboards | - | - | Yes | Yes |
| | | | | |
| **ACCESSIBILITY** | | | | |
| Senior Mode | Yes | Yes | Yes | Yes |
| | | | | |
| **PROGRESS** | | | | |
| Basic dashboard | Yes | Yes | Yes | Yes |
| Streak tracking | Yes | Yes | Yes | Yes |
| Weekly summary | - | Yes | Yes | Yes |
| Trend charts | - | Yes | Yes | Yes |
| Goal tracking | - | Yes | Yes | Yes |
| Export (CSV/PDF) | - | Yes | Yes | Yes |
| | | | | |
| **OTHER** | | | | |
| Ads | Yes | - | - | - |
| Email support | - | Yes | Yes | Yes |

---

## Cost Scaling (with 15% App Store Commission)

| Users | Fixed | Variable | Total Cost | Gross Revenue | Commission (15%) | Net Revenue | Profit |
|-------|-------|----------|------------|---------------|------------------|-------------|--------|
| 10 | $25 | $2 | $27 | $24 | $4 | $20 | -$7 |
| 100 | $99 | $15 | $114 | $255 | $38 | $217 | $103 |
| 1000 | $99 | $90 | $189 | $2,547 | $382 | $2,165 | $1,976 |
| 5000 | $150 | $450 | $600 | $12,735 | $1,910 | $10,825 | $10,225 |

**Break-even: ~8 paying users**

---

## Profitability by Plan Type

| Plan | Price | After App Store (15%) | Your Cost | Profit | Notes |
|------|-------|----------------------|-----------|--------|-------|
| Premium Monthly | $5.99 | $5.09 | ~$0.15 | **$4.94** | Per month user stays |
| Premium Yearly | $47.99 | $40.79 | ~$1.80 | **$38.99** | Locked in for year |
| Ultra Monthly | $9.99 | $8.49 | ~$0.20 | **$8.29** | Per month user stays |
| Ultra Yearly | $79.99 | $67.99 | ~$2.40 | **$65.59** | Locked in for year |
| Lifetime | $99.99 | $84.99 | ~$6 (2yr) | **$79** | One-time |

### Monthly vs Yearly: The Churn Factor

| Scenario | Monthly Revenue | After 12 Months |
|----------|-----------------|-----------------|
| User pays **yearly** upfront | $79.99 | $79.99 (guaranteed) |
| User pays **monthly**, stays 12mo | $9.99 x 12 | $119.88 (better!) |
| User pays **monthly**, churns at 3mo | $9.99 x 3 | $29.97 (worse) |
| User pays **monthly**, churns at 6mo | $9.99 x 6 | $59.94 (worse) |

**Average fitness app retention: 6-8 months**

Monthly is profitable (~$5-8/user/month), but yearly/lifetime reduce churn risk.

---

## Lifetime Subscription Economics

| Metric | Value |
|--------|-------|
| Price | $99.99 |
| After App Store (15%) | $85 |
| Your cost (2 years) | ~$6 |
| **Profit per lifetime user** | **~$79** |
| Break-even vs monthly | 10 months |

Lifetime is profitable if average user retention < 10 months (typical for fitness apps: 6-8 months).

---

## Cost Optimization Tips

1. **Use GPT-5 nano by default** - 80-90% savings vs GPT-4
2. **Cache common responses** - Reduce redundant API calls
3. **Batch embeddings** - Already implemented
4. **Rate limiting** - Prevent abuse with daily caps
5. **Prompt caching** - GPT-5 nano: $0.005/1M cached input (90% off)
6. **Compress chat history** - Summarize old messages
7. **Lazy RAG queries** - Only query ChromaDB when needed
8. **Image compression** - Resize before sending to API

---

## Future Feature Ideas

### High Value (Low Effort)
| Feature | Description |
|---------|-------------|
| Barcode food scanner | Scan packaged food for instant macros |
| Voice commands | "Start workout", "Next exercise" hands-free |
| Exercise alternatives | "Gym crowded, what else targets same muscle?" |
| Plate calculator | "How to load 185lbs on bar" visual guide |

### Medium Value
| Feature | Description |
|---------|-------------|
| AI form check | Upload video, AI analyzes form |
| Workout challenges | 30-day abs challenge, etc. |
| Superset builder | AI creates supersets |
| Travel workouts | "Hotel gym with only dumbbells" |
| Energy-based workouts | "I'm tired today" -> lighter workout |

### Social/Viral
| Feature | Description |
|---------|-------------|
| Workout recap video | Auto-generate shareable summary |
| Challenge friends | "Beat my 5K time" |
| Before/after generator | Side-by-side progress photos |

### Revenue Boosters
| Feature | Description |
|---------|-------------|
| Affiliate equipment links | Amazon affiliate revenue |
| Gym partnerships | B2B discounts |
| Personal trainer marketplace | Commission-based |

---

## Existing Features (Already Implemented)
- Time crunch mode (duration_minutes parameter)
- Injury-aware AI
- Senior Mode (in progress)
- Shareable workouts/accomplishments
- Import workouts
- Activity between rests
- Workout metrics (1RM, etc.)

---

*Last Updated: December 2024*
