#!/usr/bin/env python3
"""
Script to update the Key Differentiators vs Competitors table with more apps and pricing
"""

INPUT_FILE = '/Users/saichetangrandhe/AIFitnessCoach/FEATURES.md'

# The new comprehensive table
NEW_TABLE = '''### Key Differentiators vs Competitors

#### Pricing Overview

| App | Category | Monthly | Yearly | Lifetime | Best For |
|-----|----------|---------|--------|----------|----------|
| **FitWiz** | AI Workout + Nutrition | **$5.99** | **$47.99** | **$99.99** | All-in-one AI fitness |
| Hevy | Workout Logger | $9.99 | $79.99 | $149.99 | Manual gym tracking |
| Gravl | AI Workouts | $14.99 | $89.99 | $199.00 | Basic AI generation |
| Strong | Workout Logger | $9.99 | $79.99 | $149.99 | Simple logging |
| JEFIT | Community Planner | $12.99 | $69.99 | $159.99 | Social workouts |
| Fitbod | ML Workouts | $12.99 | $79.99 | None | Recovery-based ML |
| MacroFactor | Nutrition | $11.99 | $71.99 | None | Macro tracking |
| MyFitnessPal | Calorie Counter | $19.99 | $79.99 | None | Food database |
| Zero | Fasting | N/A | $69.99 | None | Intermittent fasting |
| Fastic | Fasting + Wellness | ~$16 | ~$60 | None | Holistic fasting |
| Nike Training Club | Video Workouts | Free | Free | N/A | Free guided videos |
| Peloton | Connected Fitness | $12.99 | N/A | None | Live classes |

**FitWiz offers the lowest price point while being the ONLY app with conversational AI coaching.**

---

#### Feature Comparison Matrix

| Feature | FitWiz | Hevy | Gravl | Strong | Fitbod | MacroFactor | MyFitnessPal | Zero | Fastic |
|---------|------------------|------|-------|--------|--------|-------------|--------------|------|--------|
| **WORKOUT FEATURES** |||||||||
| AI Workout Generation | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Conversational AI Coach | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Exercise Video Library | ✅ 1,722 | ✅ 1,300 | ✅ 400 | ✅ 300 | ✅ 600 | ❌ | ❌ | ❌ | ❌ |
| Custom Exercise Creation | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Workout Templates | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Supersets/Dropsets | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Rest Timer | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Dynamic Warmups | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Cooldown Stretches | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **AI & PERSONALIZATION** |||||||||
| Learns from Feedback | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Age-Based Safety Caps | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Comeback Detection | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Difficulty Ceiling | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Skill Progressions | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Unlimited Exercise Swaps | ✅ | ❌ | ❌ (3 max) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Equipment-Aware Generation | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| **NUTRITION FEATURES** |||||||||
| Calorie Tracking | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| Macro Tracking | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| AI Photo Food Logging | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| Voice Food Logging | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Recipe Builder | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| AI Meal Suggestions | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **FASTING FEATURES** |||||||||
| Fasting Timer | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Multiple Fasting Protocols | ✅ 10 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ 6+ | ✅ 8+ |
| Fasting + Workout Integration | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **TRACKING & PROGRESS** |||||||||
| Progress Photos | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Body Measurements | ✅ 15pts | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| 1RM Calculator | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Progress Graphs | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| NEAT Tracking | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **SOCIAL FEATURES** |||||||||
| Social Feed | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Leaderboards | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Workout Sharing | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |
| Fasting Circles | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **USER EXPERIENCE** |||||||||
| Apple Watch Support | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Free Trial (Full Access) | ✅ 24hr | ❌ | ❌ | ❌ | 3 workouts | 14 days | ❌ | ✅ | ❌ |
| Pre-Paywall Plan Preview | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Lifetime Purchase Option | ✅ $99.99 | ✅ $149.99 | ✅ $199 | ✅ $149.99 | ❌ | ❌ | ❌ | ❌ | ❌ |
| Offline Mode | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| Custom Sounds | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Voice Guidance | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Split Screen Support | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| In-App Support | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

---

#### What Each Competitor Does Better (And How We Compare)

| Competitor | What They Do Well | Our Response |
|------------|-------------------|--------------|
| **Hevy** | Social features (feed, leaderboards, sharing), large exercise library | We focus on AI personalization over social. Our AI coach is your accountability partner. |
| **Gravl** | Simple AI generation interface | Our AI is more sophisticated with feedback learning, age safety, and conversational coaching. |
| **Strong** | Clean, minimal UI for logging | We offer similar simplicity PLUS AI generation. Logging is just as easy. |
| **JEFIT** | Large community, workout challenges | We prioritize personalization over community features. Quality over quantity. |
| **Fitbod** | ML-based recovery tracking | We match this + add conversational AI, age safety, skill progressions, and lifetime pricing. |
| **MacroFactor** | Advanced macro algorithms | We integrate nutrition WITH workouts. One app does both. They have no workout features. |
| **MyFitnessPal** | Massive food database | We have AI food scanning + meal suggestions. Less manual entry needed. |
| **Zero** | Best-in-class fasting UI | We integrate fasting WITH workouts. They have zero workout features. |
| **Fastic** | Holistic wellness approach | We match their holistic view + add AI workout generation. |
| **Nike Training Club** | Free, high-quality videos | We offer personalization. NTC is one-size-fits-all content. |
| **Peloton** | Live class energy | We're 60% cheaper with no equipment lock-in. AI adapts to YOU, not a class schedule. |

---

#### Unique to FitWiz (No Competitor Has These)

| Exclusive Feature | What It Does | Why It Matters |
|-------------------|--------------|----------------|
| **Conversational AI Coach** | Full chat with memory, context, and personality | Get real-time advice, modify workouts mid-conversation, ask questions anytime |
| **Age-Based Safety Caps** | Auto-limits for 60+ and 75+ users | Prevents injury from inappropriate intensity - competitors ignore senior safety |
| **Comeback Detection** | Detects 7-42+ day breaks, auto-adjusts | Prevents injury when returning - competitors restart at previous intensity |
| **Leverage-First Progression** | Progress via exercise variants, not just reps | Wall → Incline → Standard push-ups is better than 50 wall push-ups |
| **7 Skill Progression Chains** | 52 exercises in mastery paths | Clear journey from beginner to advanced (no competitor tracks this) |
| **Pre-Paywall Plan Preview** | See YOUR 4-week plan before paying | Know exactly what you're getting - competitors hide plans until after payment |
| **Demo Day (24hr Full Access)** | Try everything, no account needed | Full app experience before any commitment |
| **100+ Equipment Types** | Gada, jori, Indian clubs, sandbags, etc. | Support for specialty equipment no one else recognizes |
| **Fasting + Workout Integration** | Combined in one app | No switching between apps - unique in the market |
| **NEAT Improvement System** | Steps, hourly activity, movement reminders | Non-exercise activity tracking with gamification |
| **Calibration Workouts** | Test actual vs reported fitness level | Validates self-assessment for accurate personalization |

---

'''

def main():
    print(f"Reading {INPUT_FILE}...")
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the old table section
    start_marker = "### Key Differentiators vs Competitors\n"
    end_marker = "\n---\n\n*Last Updated:"

    start_idx = content.find(start_marker)
    if start_idx == -1:
        print("ERROR: Could not find start marker")
        return

    end_idx = content.find(end_marker, start_idx)
    if end_idx == -1:
        print("ERROR: Could not find end marker")
        return

    # Replace the section
    new_content = content[:start_idx] + NEW_TABLE + content[end_idx+5:]  # +5 to keep the "---\n\n"

    print(f"Writing updated content to {INPUT_FILE}...")
    with open(INPUT_FILE, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print("Done! Updated Key Differentiators table with:")
    print("- Pricing Overview table (12 apps)")
    print("- Feature Comparison Matrix (9 competitors)")
    print("- What Each Competitor Does Better section")
    print("- Unique to FitWiz section")


if __name__ == '__main__':
    main()
