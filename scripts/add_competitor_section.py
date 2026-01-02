#!/usr/bin/env python3
"""
Script to add comprehensive competitor analysis to FEATURES.md
"""

import re

INPUT_FILE = '/Users/saichetangrandhe/AIFitnessCoach/FEATURES.md'

# The new competitor analysis section
NEW_SECTION = '''---

## Comprehensive Competitor Analysis

This section provides detailed competitive intelligence on major fitness apps in the market, highlighting how FitWiz differentiates and the strategic advantages we offer.

### Market Landscape Overview

The fitness app market is fragmented into three categories:
1. **Workout Trackers** (Hevy, Strong) - Manual logging, no AI generation
2. **AI Generators** (Fitbod, Gravl) - ML-based workout creation, limited coaching
3. **Video Platforms** (Nike Training Club, Peloton, Gymshark) - Pre-recorded content, no personalization

**FitWiz bridges ALL three** with AI generation + conversational coaching + personalization - a unique combination in the market.

---

### Competitor Deep Dive

#### 1. Hevy - Popular Workout Tracker

| Aspect | Details |
|--------|---------|
| **Category** | Manual Workout Logger |
| **Core Features** | Manual workout logging, 1300+ exercises, superset/dropset support, rest timer, workout templates, progress graphs, 1RM calculator |
| **AI Capabilities** | None - purely manual logging |
| **Social Features** | Friend following, activity feed, workout sharing, leaderboards |
| **Platforms** | iOS, Android, Apple Watch |
| **Pricing** | Free (3 routines), Pro $9.99/mo, $79.99/yr, Lifetime $149.99 |

**Where We Win:** Full AI generation, video demos, dynamic warmups, beginner-friendly

---

#### 2. Gravitus (Gravl) - AI Strength Training

| Aspect | Details |
|--------|---------|
| **Category** | AI Workout Generator |
| **Core Features** | AI workout generation, workout logging, 400+ exercises, progress tracking |
| **AI Capabilities** | Basic AI generation - limited personalization, doesn't learn from feedback |
| **Platforms** | iOS, Android |
| **Pricing** | Free (very limited), Pro $14.99/mo, $89.99/yr, Lifetime $199 |

**User Complaints:** "Exercises way too difficult for beginners", "Warmups stay exactly the same", "AI doesn't learn"

**Where We Win:** Adaptive AI that learns, dynamic warmups, age-based safety, leverage progressions, 60-70% cheaper

---

#### 3. Strong - Premium Workout Logger

| Aspect | Details |
|--------|---------|
| **Category** | Manual Workout Tracker |
| **Core Features** | Workout logging, 300+ exercises, custom exercises, workout templates, Apple Watch |
| **AI Capabilities** | None - manual logging only |
| **Social Features** | None (privacy-focused) |
| **Pricing** | Free (3 workouts), Pro $9.99/mo, $79.99/yr, Lifetime $149.99 |

**Where We Win:** AI generation, conversational coaching, video demonstrations, beginner guidance

---

#### 4. JEFIT - Workout Planner + Community

| Aspect | Details |
|--------|---------|
| **Category** | Workout Planner with Community |
| **Core Features** | Exercise database (1300+), workout plans, logging, HD exercise videos |
| **AI Capabilities** | "Smart Planner" (basic rule-based, not true AI) |
| **Social Features** | Large community, forums, challenges |
| **Pricing** | Free (ads), Elite $12.99/mo, $69.99/yr, Lifetime $159.99 |

**Where We Win:** Modern AI personalization, clean UI, true adaptive learning, conversational coaching

---

#### 5. Fitbod - ML Workout Generator

| Aspect | Details |
|--------|---------|
| **Category** | AI Workout Generator |
| **Core Features** | ML workout generation, muscle recovery tracking, 600+ exercises with videos, Apple Watch |
| **AI Capabilities** | True ML-based generation, adapts to recovery, considers workout history |
| **Platforms** | iOS, Android, Apple Watch |
| **Pricing** | Free (3 workouts), $12.99/mo, $79.99/yr, No Lifetime |

**User Complaints:** "After giving all personal info, requires subscription to see plan", "No lifetime option", "No coach chat"

**Where We Win:** Conversational AI coach, pre-paywall plan preview, lifetime option, age-based safety, set adjustment during workout

---

#### 6. Nike Training Club (NTC) - Free Video Workouts

| Aspect | Details |
|--------|---------|
| **Category** | Video-Guided Workouts |
| **Core Features** | 200+ guided workout videos, celebrity trainers, multi-week programs |
| **AI Capabilities** | None - curated content only |
| **Pricing** | 100% Free (since 2022) |

**Where We Win:** AI personalization, workout tracking, strength progression, equipment-aware generation

---

#### 7. Gymshark Training - Brand-Focused App

| Aspect | Details |
|--------|---------|
| **Category** | Video-Guided Workouts |
| **Core Features** | Workout videos, training programs, Gymshark athlete content |
| **Pricing** | Free (limited), Pro $9.99/mo, $59.99/yr |

**Where We Win:** True AI personalization, beginner-friendly, progression tracking

---

#### 8. Peloton - Premium Connected Fitness

| Aspect | Details |
|--------|---------|
| **Category** | Premium Connected Fitness |
| **Core Features** | Live and on-demand classes, world-class instructors, leaderboards |
| **AI Capabilities** | Basic recommendations, no true AI generation |
| **Pricing** | App Only $12.99/mo, All-Access $44/mo |

**Where We Win:** AI-generated personalized workouts, strength tracking, much cheaper, no equipment lock-in

---

### Pricing Comparison

| App | Monthly | Yearly | Lifetime | Free Tier |
|-----|---------|--------|----------|-----------|
| **FitWiz** | **$5.99** | **$47.99** | **$99.99** | Generous |
| Hevy | $9.99 | $79.99 | $149.99 | Limited |
| Gravl | $14.99 | $89.99 | $199.00 | Very Limited |
| Strong | $9.99 | $79.99 | $149.99 | Limited |
| JEFIT | $12.99 | $69.99 | $159.99 | Ad-heavy |
| Fitbod | $12.99 | $79.99 | None | Poor |
| NTC | Free | Free | N/A | Excellent |
| Gymshark | $9.99 | $59.99 | None | Limited |
| Peloton | $12.99 | N/A | None | Trial only |

**FitWiz is 40-70% cheaper than most competitors while offering more features.**

---

### Unique Features Only FitWiz Offers

| Feature | Description |
|---------|-------------|
| **Conversational AI Coach** | Full chat with context awareness and memory |
| **Age-Based Safety Caps** | Automatic rep/intensity limits for seniors (60+, 75+) |
| **Comeback Detection** | Auto-detect breaks (7-42+ days), gradual rebuild |
| **Leverage-First Progression** | Progress to harder variants, not more reps |
| **7 Skill Progression Chains** | 52 exercises (wall pushups to one-arm pushups) |
| **Dynamic Warmup Generation** | Muscle-specific, variety-tracked, safety-ordered |
| **HIIT Safety System** | No static holds in interval workouts |
| **Pre-Paywall Plan Preview** | See YOUR complete 4-week plan free |
| **Demo Day (24hr Full Access)** | No account required, full app experience |
| **Sound Customization** | Custom countdown/completion sounds (no applause!) |
| **100+ Equipment Types** | Including specialty equipment (gada, jori, tires) |

---

## Competitor Complaint Response: Why We're Different

The following section addresses specific user complaints from competitor app reviews and how FitWiz solves each one.

'''

# Pattern to find and replace
OLD_PATTERN = r'---\n\n## Competitor Comparison: Why We\'re Different\n\n### Complaint:'
NEW_REPLACEMENT = NEW_SECTION + '### Complaint:'

def main():
    print(f"Reading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find and replace the old section
    old_text = '---\n\n## Competitor Comparison: Why We\'re Different\n\n### Complaint:'
    if old_text in content:
        content = content.replace(old_text, NEW_SECTION + '### Complaint:')
        print("Found and replaced competitor section")
    else:
        print("Could not find exact match, trying regex...")
        # Try with regex for more flexible matching
        pattern = r'---\n+## Competitor Comparison: Why We\'re Different\n+### Complaint:'
        if re.search(pattern, content):
            content = re.sub(pattern, NEW_SECTION + '### Complaint:', content)
            print("Replaced using regex")
        else:
            print("WARNING: Could not find competitor section to replace!")
            return

    print(f"Writing updated content to {INPUT_FILE}...")
    with open(INPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

    print("Done!")


if __name__ == '__main__':
    main()
