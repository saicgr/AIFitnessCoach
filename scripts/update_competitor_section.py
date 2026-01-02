#!/usr/bin/env python3
"""
Script to update competitor analysis with FitWiz details and fasting apps
"""

INPUT_FILE = '/Users/saichetangrandhe/AIFitnessCoach/FEATURES.md'

# FitWiz detailed entry to add after Market Landscape Overview
FITWIZ_ENTRY = '''
### FitWiz - Our App

| Aspect | Details |
|--------|---------|
| **Category** | AI-Powered Personal Fitness Coach |
| **Core Features** | AI workout generation, conversational AI coach, 1,722+ exercises with HD videos, 12 branded programs, dynamic warmups/cooldowns, progress tracking, nutrition guidance, NEAT tracking |
| **AI Capabilities** | Full Gemini AI integration - generates personalized workouts, learns from feedback, adapts to user progress, remembers conversation context, age-based safety adjustments |
| **Unique Differentiators** | See detailed comparison below |
| **Platforms** | iOS, Android |
| **Pricing** | Free (generous trial), $5.99/mo, $47.99/yr, $99.99 Lifetime |

**What Makes Us Different from Every Competitor:**

| Differentiator | How We're Unique |
|----------------|------------------|
| **Conversational AI Coach** | Full chat interface with context memory - ask questions, get advice, modify workouts mid-conversation. No competitor offers this. |
| **Age-Based Safety System** | Automatic intensity caps for 60+ and 75+ users. Reduces injury risk that competitors ignore. |
| **Comeback Detection** | Detects breaks (7-42+ days) and auto-adjusts difficulty. Competitors restart at same level, causing injury. |
| **Leverage-First Progression** | Progress to harder exercise variants (wall → incline → standard push-ups) instead of just adding reps. |
| **Skill Progression Chains** | 7 chains with 52 exercises total (wall push-up → one-arm push-up journey). |
| **Dynamic Warmups** | AI generates muscle-specific warmups with variety tracking - never the same warmup twice. |
| **Pre-Paywall Preview** | See YOUR complete 4-week personalized plan before paying. Fitbod/Gravl hide plans until after payment. |
| **Demo Day** | 24-hour full access without account. Try everything before committing. |
| **Unlimited Exercise Swaps** | Skip/swap any exercise with AI alternatives. Competitors limit to 3 skips. |
| **Difficulty Ceiling** | Beginners NEVER see advanced exercises. Competitors show pull-ups to people who can't do push-ups. |
| **100+ Equipment Types** | Supports specialty equipment: gada, jori, Indian clubs, tires, sandbags, kettlebells, and more. |
| **Custom Sound Effects** | Choose countdown/completion sounds. No annoying applause sounds. |
| **Calibration Workouts** | Optional strength test to validate self-reported fitness level and set accurate baselines. |
| **NEAT Tracking** | Non-exercise activity thermogenesis with step goals, hourly activity, movement reminders. |
| **Nutrition Integration** | Meal logging, macro tracking, AI-generated meal suggestions based on goals. |

---

'''

# Fasting Apps Section to add before Pricing Comparison
FASTING_APPS_SECTION = '''### Fasting Apps Comparison

FitWiz doesn't currently offer fasting features, but here's how the market looks for users who want both:

#### 9. Zero - Top Fasting App

| Aspect | Details |
|--------|---------|
| **Category** | Intermittent Fasting Tracker |
| **Core Features** | Fasting timer, 16:8/18:6/OMAD/custom schedules, mood logging, water tracking, educational content |
| **AI Capabilities** | Basic recommendations, no AI generation |
| **Integrations** | Apple Health, Fitbit, Oura |
| **Pricing** | Free (full-featured basic), Zero Plus $69.99/yr |

**Gap We Could Fill:** Zero has no workout integration. Users need two apps.

---

#### 10. Fastic - Holistic Fasting

| Aspect | Details |
|--------|---------|
| **Category** | Fasting + Wellness |
| **Core Features** | Fasting timer, AI food scanner, hydration reminders, step tracking, recipes, meal planning |
| **AI Capabilities** | AI food scanner for nutrition info |
| **Social Features** | Active community, challenges |
| **Pricing** | Free (basic), Fastic PLUS ~$16/mo or $60/yr |

**Gap We Could Fill:** No strength training or personalized workouts.

---

#### 11. Life Fasting Tracker - Social Fasting

| Aspect | Details |
|--------|---------|
| **Category** | Social Fasting Tracker |
| **Core Features** | Fasting timer, fasting circles (group fasting), bio-indicator tracking, Apple Watch |
| **Unique Features** | Fasting circles for accountability with friends/family |
| **Pricing** | Free (basic), Premium varies by region |

**Gap We Could Fill:** No workout generation or exercise tracking.

---

#### 12. Simple - AI Fasting Coach

| Aspect | Details |
|--------|---------|
| **Category** | AI-Powered Fasting |
| **Core Features** | Fasting timer, weight tracking, water logging, educational content |
| **AI Capabilities** | AI coaching for fasting guidance |
| **Pricing** | Free (very limited), Premium $29.99/mo |

**Note:** Expensive for fasting-only features. No workout integration.

---

#### 13. DoFasting - Subscription Fasting

| Aspect | Details |
|--------|---------|
| **Category** | Fasting + Weight Loss |
| **Core Features** | Fasting timer, calorie tracker, workout suggestions (basic), progress tracking |
| **AI Capabilities** | Basic meal suggestions |
| **Pricing** | Subscription only: $11-20/mo depending on plan length |

**Gap We Could Fill:** Their workout suggestions are generic templates, not AI-personalized.

---

### Fasting App Pricing

| App | Monthly | Yearly | Free Tier |
|-----|---------|--------|-----------|
| Zero | N/A | $69.99 | Excellent |
| Fastic | ~$16 | ~$60 | Basic |
| Life | Varies | Varies | Good |
| Simple | $29.99 | N/A | Very Limited |
| DoFasting | $11-20 | ~$100 | None |

**Opportunity:** Fasting apps lack proper workout integration. A future FitWiz + Fasting integration would be unique in the market.

---

'''

# Updated pricing comparison including fasting apps
UPDATED_PRICING = '''### Pricing Comparison

#### Workout & Fitness Apps

| App | Monthly | Yearly | Lifetime | Free Tier | AI Coach Chat |
|-----|---------|--------|----------|-----------|---------------|
| **FitWiz** | **$5.99** | **$47.99** | **$99.99** | **Generous** | **Yes** |
| Hevy | $9.99 | $79.99 | $149.99 | Limited | No |
| Gravl | $14.99 | $89.99 | $199.00 | Very Limited | No |
| Strong | $9.99 | $79.99 | $149.99 | Limited | No |
| JEFIT | $12.99 | $69.99 | $159.99 | Ad-heavy | No |
| Fitbod | $12.99 | $79.99 | None | Poor | No |
| NTC | Free | Free | N/A | Excellent | No |
| Gymshark | $9.99 | $59.99 | None | Limited | No |
| Peloton | $12.99 | N/A | None | Trial only | No |

#### Fasting Apps (For Reference)

| App | Monthly | Yearly | Free Tier | Workout Integration |
|-----|---------|--------|-----------|---------------------|
| Zero | N/A | $69.99 | Excellent | None |
| Fastic | ~$16 | ~$60 | Basic | None |
| Simple | $29.99 | N/A | Very Limited | None |
| DoFasting | $11-20 | ~$100 | None | Basic Templates |

**FitWiz is 40-70% cheaper than most competitors while offering the ONLY conversational AI coach in the market.**

'''

def main():
    print(f"Reading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Add FitWiz entry after "---" following Market Landscape Overview
    marker1 = "**FitWiz bridges ALL three** with AI generation + conversational coaching + personalization - a unique combination in the market.\n\n---\n\n### Competitor Deep Dive"
    if marker1 in content:
        content = content.replace(
            marker1,
            "**FitWiz bridges ALL three** with AI generation + conversational coaching + personalization - a unique combination in the market.\n\n---" + FITWIZ_ENTRY + "### Competitor Deep Dive"
        )
        print("Added FitWiz detailed entry")
    else:
        print("WARNING: Could not find marker for FitWiz entry")

    # 2. Add fasting apps section before Pricing Comparison
    marker2 = "---\n\n### Pricing Comparison\n\n| App | Monthly | Yearly | Lifetime | Free Tier |"
    if marker2 in content:
        content = content.replace(
            marker2,
            "---\n\n" + FASTING_APPS_SECTION + UPDATED_PRICING
        )
        print("Added fasting apps section and updated pricing table")
    else:
        print("WARNING: Could not find pricing comparison marker")

    print(f"Writing updated content to {INPUT_FILE}...")
    with open(INPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

    print("Done!")


if __name__ == '__main__':
    main()
