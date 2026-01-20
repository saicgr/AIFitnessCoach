# FitWiz Trophy & Achievement System Specification

## Overview

A comprehensive Battlefield-style achievement system with **390 trophies** across 12 categories, featuring:
- 4-tier progression (Bronze → Silver → Gold → Platinum)
- XP/Level system with prestige
- Real-world merch rewards for elite achievements
- **30 Competitive/Moveable "World Record" trophies** - only ONE user holds each!

---

## Table of Contents

1. [Tier System](#1-tier-system)
2. [Visual Design](#2-visual-design)
3. [XP & Level System](#3-xp--level-system)
4. [Trophy Visibility Rules](#4-trophy-visibility-rules)
5. [Merch Rewards](#5-merch-rewards)
6. [Trophy Room UI](#6-trophy-room-ui)
7. [Database Schema](#7-database-schema)
8. [COMPLETE TROPHY LIST (All 390)](#8-complete-trophy-list-all-390)
9. [Gifts & Rewards Retention System](#9-gifts--rewards-retention-system)
10. [Anti-Fraud & Validation System](#10-anti-fraud--validation-system)

---

## 1. Tier System

| Tier | Name | Color | Difficulty | XP Multiplier |
|------|------|-------|------------|---------------|
| I | Bronze | #CD7F32 | Entry level | 1x |
| II | Silver | #C0C0C0 | Intermediate | 2x |
| III | Gold | #FFD700 | Advanced | 4x |
| IV | Platinum | #E5E4E2 | Elite (<2% users) | 10x |

**Platinum Difficulty Principle**: Platinum trophies should take 2-5+ years of consistent dedication. Most users will NEVER earn Platinum - that's the point.

---

## 2. Visual Design

### Trophy Appearance by Tier

| Tier | Base Color | Shine Effect | Animation | Border |
|------|------------|--------------|-----------|--------|
| Bronze | #CD7F32 | Subtle metallic | None | 1px darker bronze |
| Silver | #C0C0C0 → #E8E8E8 | Shimmer gradient | Gentle pulse | 2px silver glow |
| Gold | #FFD700 → #FFA500 | Sparkle particles | Rotating shine | 3px golden glow + sparkles |
| Platinum | #E5E4E2 → #FFFFFF | Rainbow iridescent | Pulsing rainbow + particles | 4px prismatic glow |

### Gold Trophy Visual Details
- Gradient from deep gold (#FFD700) to orange gold (#FFA500)
- Animated sparkle particles around edges
- Rotating shine reflection effect
- Golden glow shadow (4px blur)
- "Ding" sound effect on unlock

### Platinum Trophy Visual Details
- Iridescent/holographic gradient (cycles through rainbow subtly)
- Premium particle effects (stars, sparkles)
- Pulsing glow animation
- Prismatic light reflection
- Screen shake + confetti on unlock
- Premium "achievement unlocked" sound

### Flutter Implementation Example
```dart
// Gold trophy with shimmer
ShaderMask(
  shaderCallback: (bounds) => LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
    stops: [0.0, 0.5, 1.0],
  ).createShader(bounds),
  child: trophyIcon,
).animate().shimmer(duration: 2.seconds);

// Platinum trophy with rainbow effect
Container(
  decoration: BoxDecoration(
    gradient: SweepGradient(
      colors: [Colors.red, Colors.orange, Colors.yellow,
               Colors.green, Colors.blue, Colors.purple, Colors.red],
    ),
  ),
).animate().rotate(duration: 3.seconds).shimmer();
```

---

## 3. XP & Level System

### XP Sources
| Action | XP Earned |
|--------|-----------|
| Complete workout | 100-500 XP (based on duration/intensity) |
| Set a PR | 200 XP |
| Earn achievement | Achievement points × 10 XP |
| Maintain streak | 50 XP/day |
| Complete challenge | 100-1000 XP |
| Log meal | 10 XP |
| Log weight | 25 XP |
| Take progress photo | 50 XP |

### Level Progression
| Level Range | XP Required | Title | Cumulative XP |
|-------------|-------------|-------|---------------|
| 1-10 | 1,000/level | Novice | 10,000 |
| 11-25 | 2,500/level | Apprentice | 47,500 |
| 26-50 | 7,500/level | Athlete | 235,000 |
| 51-75 | 15,000/level | Elite | 610,000 |
| 76-99 | 35,000/level | Master | 1,450,000 |
| 100 | 100,000 | Legend | 1,550,000 |
| 100+ (Prestige) | 150,000/level | Mythic | 1,700,000+ |

**Reality Check**: Level 100 requires ~1.5M XP = ~5,000+ workouts = ~10+ years of consistent training.

### Level Unlocks
- Level 5: Custom workout builder
- Level 10: Advanced analytics dashboard
- Level 25: Coach customization options
- Level 50: Special profile badge + frame
- Level 75: Elite badge + shaker bottle reward
- Level 100: Legendary status + full merch kit + lifetime premium

---

## 4. Trophy Visibility Rules

### Visibility Types
| Type | Before Earned | After Earned |
|------|---------------|--------------|
| Regular | Visible with progress bar | Fully visible |
| Secret | Shows as "???" with hint | Revealed |
| Hidden | Completely invisible | Appears as surprise |

### Database Fields
```sql
is_secret BOOLEAN DEFAULT FALSE  -- Show as "???" until earned
is_hidden BOOLEAN DEFAULT FALSE  -- Completely hidden until earned
hint_text TEXT                   -- Clue for secret achievements
```

### Visibility Matrix
| is_secret | is_hidden | Behavior |
|-----------|-----------|----------|
| FALSE | FALSE | Always visible with progress |
| TRUE | FALSE | Shows as "???" with hint, revealed when earned |
| FALSE | TRUE | Not shown until earned, then appears |
| TRUE | TRUE | Completely hidden, no hint, surprise reveal |

---

## 5. Merch Rewards

### Reward Tiers
| Achievement Level | Reward | How to Claim |
|-------------------|--------|--------------|
| Gold Tier | Digital Badge + Exclusive Profile Frame | Automatic |
| Platinum Tier | FREE FitWiz T-Shirt | Claim via app → enter shipping address |
| Diamond Tier | FREE FitWiz Hoodie + Shaker Bottle | Claim via app |
| Level 75 (Elite) | FREE Shaker Bottle | Claim via app |
| Level 100 (Legend) | Full Merch Kit + Lifetime Premium | Personal email from team |

### Merch-Eligible Achievements
- 💎 2,000 Workouts Completed → FREE T-Shirt
- 💎 5,000,000 lbs Lifted → FREE T-Shirt
- 💎 730-Day Streak → FREE T-Shirt
- 💎 Level 75 Reached → FREE Shaker Bottle
- 🏆 Level 100 Reached → Full Kit + Lifetime Premium

### Claim Flow
1. User earns Platinum/Diamond tier achievement
2. Unlock notification with "Claim Your Reward" button
3. User enters shipping address + size
4. Backend creates `merch_claims` record
5. Admin dashboard shows pending claims
6. Manual fulfillment → mark as shipped
7. User receives tracking notification

---

## 6. Trophy Room UI

### Screen Layout
```
┌─────────────────────────────────────────────┐
│  ← Back          🏆 Trophy Room              │
│─────────────────────────────────────────────│
│                                             │
│  Level 47 Athlete                           │
│  ████████████░░░░░ 12,450/15,000 XP        │
│                                             │
│  [All] [Earned] [In Progress] [Locked]     │
│                                             │
│  ──── 📊 YOUR STATS ─────────────────────  │
│  🏆 47 Earned  |  🔓 285 Locked  |  ❓ 40   │
│                                             │
│  ──── 🏋️ WORKOUT MASTERY ────────────────  │
│  ┌─────────────────────────────────────┐   │
│  │ 🥉 First Steps     ✓ EARNED         │   │
│  │ 10/10 workouts     +50 XP           │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │ 🥈 Getting Serious  ✓ EARNED        │   │
│  │ 100/100 workouts    +100 XP         │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │ 🥇 Dedicated        ░░░░░░ 68%      │   │
│  │ 340/500 workouts    +250 XP         │   │
│  │ [Golden shimmer animation]          │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │ 💎 LEGEND           🔒 LOCKED       │   │
│  │ 340/2000 workouts   +1000 XP        │   │
│  │ 🎁 Unlocks: FREE T-SHIRT            │   │
│  │ [Prismatic locked effect]           │   │
│  └─────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

### Trophy Card Animations
- **Bronze**: Static with subtle border glow
- **Silver**: Gentle shimmer animation (2s loop)
- **Gold**: Sparkle particles + rotating shine
- **Platinum**: Rainbow iridescent + particle burst
- **Locked**: Grayscale with lock icon overlay

---

## 7. Database Schema

### New Tables

#### `user_xp`
```sql
CREATE TABLE user_xp (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL UNIQUE,
  total_xp BIGINT DEFAULT 0,
  current_level INT DEFAULT 1,
  xp_to_next_level INT DEFAULT 1000,
  prestige_level INT DEFAULT 0,
  title TEXT DEFAULT 'Novice',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### `xp_transactions`
```sql
CREATE TABLE xp_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  xp_amount INT NOT NULL,
  source TEXT NOT NULL,
  source_id TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### `merch_claims`
```sql
CREATE TABLE merch_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  achievement_id UUID REFERENCES achievement_types(id),
  reward_type TEXT NOT NULL,
  size TEXT,
  shipping_address JSONB NOT NULL,
  status TEXT DEFAULT 'pending',
  tracking_number TEXT,
  claimed_at TIMESTAMPTZ DEFAULT NOW(),
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  notes TEXT
);
```

### Updated `achievement_types` Table
```sql
ALTER TABLE achievement_types
ADD COLUMN tier_level INT DEFAULT 1,
ADD COLUMN parent_achievement_id UUID REFERENCES achievement_types(id),
ADD COLUMN rarity TEXT DEFAULT 'common',
ADD COLUMN is_secret BOOLEAN DEFAULT FALSE,
ADD COLUMN is_hidden BOOLEAN DEFAULT FALSE,
ADD COLUMN hint_text TEXT,
ADD COLUMN xp_reward INT DEFAULT 0,
ADD COLUMN merch_reward TEXT,
ADD COLUMN unlock_animation TEXT DEFAULT 'standard';
```

---

## 8. COMPLETE TROPHY LIST (All 360)

### Category Summary
| Category | Count |
|----------|-------|
| A. Exercise Mastery | 48 |
| B. Volume | 20 |
| C. Time | 16 |
| D. Consistency | 24 |
| E. Personal Records | 32 |
| F. Social & Community | 48 |
| G. Body Composition, Measurements & Photos | 52 |
| H. Nutrition | 32 |
| I. Fasting | 20 |
| J. AI Coach Engagement | 28 |
| K. Special/Secret | 40 |
| **TOTAL** | **360** |

---

### A. EXERCISE MASTERY (48 trophies)

#### Chest Mastery (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 1 | Chest Beginner | 🥉 Bronze | Complete 25 chest exercises | 50 |
| 2 | Chest Builder | 🥈 Silver | Complete 100 chest exercises | 100 |
| 3 | Chest Champion | 🥇 Gold | Complete 500 chest exercises | 250 |
| 4 | Chest Legend | 💎 Platinum | Complete 2,000 chest exercises | 1000 |

#### Back Mastery (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 5 | Back Beginner | 🥉 Bronze | Complete 25 back exercises | 50 |
| 6 | Back Builder | 🥈 Silver | Complete 100 back exercises | 100 |
| 7 | Back Champion | 🥇 Gold | Complete 500 back exercises | 250 |
| 8 | Back Legend | 💎 Platinum | Complete 2,000 back exercises | 1000 |

#### Shoulders Mastery (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 9 | Shoulders Beginner | 🥉 Bronze | Complete 25 shoulder exercises | 50 |
| 10 | Shoulders Builder | 🥈 Silver | Complete 100 shoulder exercises | 100 |
| 11 | Shoulders Champion | 🥇 Gold | Complete 500 shoulder exercises | 250 |
| 12 | Shoulders Legend | 💎 Platinum | Complete 2,000 shoulder exercises | 1000 |

#### Biceps Mastery (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 13 | Biceps Beginner | 🥉 Bronze | Complete 25 bicep exercises | 50 |
| 14 | Biceps Builder | 🥈 Silver | Complete 100 bicep exercises | 100 |
| 15 | Biceps Champion | 🥇 Gold | Complete 500 bicep exercises | 250 |
| 16 | Biceps Legend | 💎 Platinum | Complete 2,000 bicep exercises | 1000 |

#### Triceps Mastery (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 17 | Triceps Beginner | 🥉 Bronze | Complete 25 tricep exercises | 50 |
| 18 | Triceps Builder | 🥈 Silver | Complete 100 tricep exercises | 100 |
| 19 | Triceps Champion | 🥇 Gold | Complete 500 tricep exercises | 250 |
| 20 | Triceps Legend | 💎 Platinum | Complete 2,000 tricep exercises | 1000 |

#### Legs Mastery (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 21 | Legs Beginner | 🥉 Bronze | Complete 25 leg exercises | 50 |
| 22 | Legs Builder | 🥈 Silver | Complete 100 leg exercises | 100 |
| 23 | Legs Champion | 🥇 Gold | Complete 500 leg exercises | 250 |
| 24 | Legs Legend | 💎 Platinum | Complete 2,000 leg exercises | 1000 |

#### Core Mastery (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 25 | Core Beginner | 🥉 Bronze | Complete 25 core exercises | 50 |
| 26 | Core Builder | 🥈 Silver | Complete 100 core exercises | 100 |
| 27 | Core Champion | 🥇 Gold | Complete 500 core exercises | 250 |
| 28 | Core Legend | 💎 Platinum | Complete 2,000 core exercises | 1000 |

#### Glutes Mastery (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 29 | Glutes Beginner | 🥉 Bronze | Complete 25 glute exercises | 50 |
| 30 | Glutes Builder | 🥈 Silver | Complete 100 glute exercises | 100 |
| 31 | Glutes Champion | 🥇 Gold | Complete 500 glute exercises | 250 |
| 32 | Glutes Legend | 💎 Platinum | Complete 2,000 glute exercises | 1000 |

#### Squat Specialist (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 33 | Squat Novice | 🥉 Bronze | Complete 50 squat sets | 50 |
| 34 | Squat Enthusiast | 🥈 Silver | Complete 250 squat sets | 100 |
| 35 | Squat Expert | 🥇 Gold | Complete 1,000 squat sets | 250 |
| 36 | Squat Master | 💎 Platinum | Complete 5,000 squat sets | 1000 |

#### Deadlift Specialist (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 37 | Deadlift Novice | 🥉 Bronze | Complete 50 deadlift sets | 50 |
| 38 | Deadlift Enthusiast | 🥈 Silver | Complete 250 deadlift sets | 100 |
| 39 | Deadlift Expert | 🥇 Gold | Complete 1,000 deadlift sets | 250 |
| 40 | Deadlift Master | 💎 Platinum | Complete 5,000 deadlift sets | 1000 |

#### Bench Press Specialist (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 41 | Bench Novice | 🥉 Bronze | Complete 50 bench press sets | 50 |
| 42 | Bench Enthusiast | 🥈 Silver | Complete 250 bench press sets | 100 |
| 43 | Bench Expert | 🥇 Gold | Complete 1,000 bench press sets | 250 |
| 44 | Bench Master | 💎 Platinum | Complete 5,000 bench press sets | 1000 |

#### Overhead Press Specialist (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 45 | OHP Novice | 🥉 Bronze | Complete 50 OHP sets | 50 |
| 46 | OHP Enthusiast | 🥈 Silver | Complete 250 OHP sets | 100 |
| 47 | OHP Expert | 🥇 Gold | Complete 1,000 OHP sets | 250 |
| 48 | OHP Master | 💎 Platinum | Complete 5,000 OHP sets | 1000 |

---

### B. VOLUME ACHIEVEMENTS (20 trophies)

#### Weight Lifted Lifetime (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 49 | Iron Starter | 🥉 Bronze | Lift 25,000 lbs total | 50 |
| 50 | Iron Mover | 🥈 Silver | Lift 250,000 lbs total | 100 |
| 51 | Million Pound Club | 🥇 Gold | Lift 1,000,000 lbs total | 500 |
| 52 | 5 Million Pound Club | 💎 Platinum | Lift 5,000,000 lbs total | 2000 |

#### Sets Completed (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 53 | Set Starter | 🥉 Bronze | Complete 500 sets | 50 |
| 54 | Set Builder | 🥈 Silver | Complete 5,000 sets | 100 |
| 55 | Set Machine | 🥇 Gold | Complete 25,000 sets | 250 |
| 56 | Set Legend | 💎 Platinum | Complete 100,000 sets | 1000 |

#### Reps Completed (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 57 | Rep Rookie | 🥉 Bronze | Complete 5,000 reps | 50 |
| 58 | Rep Regular | 🥈 Silver | Complete 50,000 reps | 100 |
| 59 | Rep Machine | 🥇 Gold | Complete 250,000 reps | 250 |
| 60 | Million Rep Club | 💎 Platinum | Complete 1,000,000 reps | 1000 |

#### Exercises Performed (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 61 | Exercise Explorer | 🥉 Bronze | Perform 500 exercises | 50 |
| 62 | Exercise Enthusiast | 🥈 Silver | Perform 2,500 exercises | 100 |
| 63 | Exercise Expert | 🥇 Gold | Perform 10,000 exercises | 250 |
| 64 | Exercise Encyclopedia | 💎 Platinum | Perform 50,000 exercises | 1000 |

#### Unique Exercises Tried (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 65 | Variety Seeker | 🥉 Bronze | Try 25 unique exercises | 50 |
| 66 | Variety Lover | 🥈 Silver | Try 75 unique exercises | 100 |
| 67 | Variety Master | 🥇 Gold | Try 150 unique exercises | 250 |
| 68 | Exercise Collector | 💎 Platinum | Try 300 unique exercises | 500 |

---

### C. TIME ACHIEVEMENTS (16 trophies)

#### Total Workout Time (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 69 | Time Starter | 🥉 Bronze | 10 hours total workout time | 50 |
| 70 | Time Investor | 🥈 Silver | 50 hours total workout time | 100 |
| 71 | Time Dedicated | 🥇 Gold | 250 hours total workout time | 250 |
| 72 | 1000 Hour Club | 💎 Platinum | 1,000 hours total workout time | 1000 |

#### Single Workout Duration (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 73 | Quick Session | 🥉 Bronze | Complete 30-min workout | 25 |
| 74 | Solid Session | 🥈 Silver | Complete 60-min workout | 50 |
| 75 | Extended Session | 🥇 Gold | Complete 90-min workout | 100 |
| 76 | Marathon Session | 💎 Platinum | Complete 2-hour workout | 200 |

#### Early Bird (Before 6 AM) (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 77 | Early Riser | 🥉 Bronze | 5 workouts before 6 AM | 50 |
| 78 | Dawn Patrol | 🥈 Silver | 25 workouts before 6 AM | 100 |
| 79 | Sunrise Warrior | 🥇 Gold | 100 workouts before 6 AM | 250 |
| 80 | Early Bird Legend | 💎 Platinum | 365 workouts before 6 AM | 1000 |

#### Night Owl (After 10 PM) (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 81 | Night Starter | 🥉 Bronze | 5 workouts after 10 PM | 50 |
| 82 | Night Regular | 🥈 Silver | 25 workouts after 10 PM | 100 |
| 83 | Night Warrior | 🥇 Gold | 100 workouts after 10 PM | 250 |
| 84 | Night Owl Legend | 💎 Platinum | 365 workouts after 10 PM | 1000 |

---

### D. CONSISTENCY ACHIEVEMENTS (24 trophies)

#### Daily Streak (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 85 | Week Warrior | 🥉 Bronze | 7-day streak | 50 |
| 86 | Month Master | 🥈 Silver | 30-day streak | 150 |
| 87 | Half Year Hero | 🥇 Gold | 180-day streak | 500 |
| 88 | Two Year Legend | 💎 Platinum | 730-day streak (2 years!) | 2000 |

#### Weekly Streak (3+/week) (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 89 | Monthly Momentum | 🥉 Bronze | 4 weeks at 3+/week | 50 |
| 90 | Quarterly Queen | 🥈 Silver | 26 weeks at 3+/week | 150 |
| 91 | Yearly Yield | 🥇 Gold | 52 weeks at 3+/week | 500 |
| 92 | Three Year Titan | 💎 Platinum | 156 weeks at 3+/week | 2000 |

#### Monthly Active (15+/month) (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 93 | Quarter Crusher | 🥉 Bronze | 3 months at 15+/month | 50 |
| 94 | Year Achiever | 🥈 Silver | 12 months at 15+/month | 200 |
| 95 | Two Year Achiever | 🥇 Gold | 24 months at 15+/month | 500 |
| 96 | Five Year Achiever | 💎 Platinum | 60 months at 15+/month | 2000 |

#### Perfect Week (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 97 | Perfect Month | 🥉 Bronze | 4 perfect weeks | 50 |
| 98 | Perfect Quarter | 🥈 Silver | 12 perfect weeks | 150 |
| 99 | Perfect Year | 🥇 Gold | 52 perfect weeks | 500 |
| 100 | Three Perfect Years | 💎 Platinum | 156 perfect weeks | 2000 |

#### Total Workouts (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 101 | First Steps | 🥉 Bronze | Complete 10 workouts | 25 |
| 102 | Getting Serious | 🥈 Silver | Complete 100 workouts | 100 |
| 103 | Dedicated | 🥇 Gold | Complete 500 workouts | 300 |
| 104 | Workout Legend | 💎 Platinum | Complete 2,000 workouts | 1500 |

#### Workouts This Year (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 105 | Year Starter | 🥉 Bronze | 50 workouts this year | 50 |
| 106 | Year Regular | 🥈 Silver | 150 workouts this year | 100 |
| 107 | Year Champion | 🥇 Gold | 300 workouts this year | 250 |
| 108 | Year Legend | 💎 Platinum | 500 workouts this year | 500 |

---

### E. PERSONAL RECORD ACHIEVEMENTS (32 trophies)

#### PR Count - Any Exercise (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 109 | PR Starter | 🥉 Bronze | Set 10 PRs | 50 |
| 110 | PR Hunter | 🥈 Silver | Set 50 PRs | 150 |
| 111 | PR Machine | 🥇 Gold | Set 200 PRs | 400 |
| 112 | PR Legend | 💎 Platinum | Set 500 PRs | 1000 |

#### PR Streak (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 113 | PR Streak Starter | 🥉 Bronze | 3 consecutive workouts with PR | 50 |
| 114 | PR Streak Builder | 🥈 Silver | 7 consecutive workouts with PR | 100 |
| 115 | PR Streak Master | 🥇 Gold | 14 consecutive workouts with PR | 250 |
| 116 | PR Streak Legend | 💎 Platinum | 30 consecutive workouts with PR | 750 |

#### Bench Press PRs (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 117 | Bench PR Beginner | 🥉 Bronze | Set 5 bench press PRs | 50 |
| 118 | Bench PR Regular | 🥈 Silver | Set 15 bench press PRs | 100 |
| 119 | Bench PR Expert | 🥇 Gold | Set 30 bench press PRs | 200 |
| 120 | Bench PR Master | 💎 Platinum | Set 50 bench press PRs | 500 |

#### Squat PRs (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 121 | Squat PR Beginner | 🥉 Bronze | Set 5 squat PRs | 50 |
| 122 | Squat PR Regular | 🥈 Silver | Set 15 squat PRs | 100 |
| 123 | Squat PR Expert | 🥇 Gold | Set 30 squat PRs | 200 |
| 124 | Squat PR Master | 💎 Platinum | Set 50 squat PRs | 500 |

#### Deadlift PRs (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 125 | Deadlift PR Beginner | 🥉 Bronze | Set 5 deadlift PRs | 50 |
| 126 | Deadlift PR Regular | 🥈 Silver | Set 15 deadlift PRs | 100 |
| 127 | Deadlift PR Expert | 🥇 Gold | Set 30 deadlift PRs | 200 |
| 128 | Deadlift PR Master | 💎 Platinum | Set 50 deadlift PRs | 500 |

#### OHP PRs (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 129 | OHP PR Beginner | 🥉 Bronze | Set 5 OHP PRs | 50 |
| 130 | OHP PR Regular | 🥈 Silver | Set 15 OHP PRs | 100 |
| 131 | OHP PR Expert | 🥇 Gold | Set 30 OHP PRs | 200 |
| 132 | OHP PR Master | 💎 Platinum | Set 50 OHP PRs | 500 |

#### Row PRs (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 133 | Row PR Beginner | 🥉 Bronze | Set 5 row PRs | 50 |
| 134 | Row PR Regular | 🥈 Silver | Set 15 row PRs | 100 |
| 135 | Row PR Expert | 🥇 Gold | Set 30 row PRs | 200 |
| 136 | Row PR Master | 💎 Platinum | Set 50 row PRs | 500 |

#### Pull-up PRs (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 137 | Pull-up PR Beginner | 🥉 Bronze | Set 5 pull-up PRs | 50 |
| 138 | Pull-up PR Regular | 🥈 Silver | Set 15 pull-up PRs | 100 |
| 139 | Pull-up PR Expert | 🥇 Gold | Set 30 pull-up PRs | 200 |
| 140 | Pull-up PR Master | 💎 Platinum | Set 50 pull-up PRs | 500 |

---

### F. SOCIAL & COMMUNITY ACHIEVEMENTS (48 trophies)

#### Posts Created (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 141 | First Post | 🥉 Bronze | Create 5 posts | 25 |
| 142 | Active Poster | 🥈 Silver | Create 50 posts | 100 |
| 143 | Content Creator | 🥇 Gold | Create 250 posts | 300 |
| 144 | Posting Legend | 💎 Platinum | Create 1,000 posts | 1000 |

#### Reactions Given (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 145 | Supporter | 🥉 Bronze | Give 25 reactions | 25 |
| 146 | Encourager | 🥈 Silver | Give 250 reactions | 75 |
| 147 | Motivator | 🥇 Gold | Give 1,000 reactions | 200 |
| 148 | Reaction King | 💎 Platinum | Give 10,000 reactions | 750 |

#### Reactions Received (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 149 | Getting Noticed | 🥉 Bronze | Receive 10 reactions | 25 |
| 150 | Rising Star | 🥈 Silver | Receive 100 reactions | 75 |
| 151 | Popular | 🥇 Gold | Receive 500 reactions | 200 |
| 152 | Influencer Status | 💎 Platinum | Receive 5,000 reactions | 1000 |

#### Comments Posted (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 153 | First Comment | 🥉 Bronze | Post 10 comments | 25 |
| 154 | Commenter | 🥈 Silver | Post 100 comments | 75 |
| 155 | Discussion Leader | 🥇 Gold | Post 500 comments | 200 |
| 156 | Comment Legend | 💎 Platinum | Post 2,500 comments | 750 |

#### Friends Made (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 157 | First Friends | 🥉 Bronze | Make 3 friends | 25 |
| 158 | Social Circle | 🥈 Silver | Make 25 friends | 75 |
| 159 | Popular | 🥇 Gold | Make 100 friends | 250 |
| 160 | Social Butterfly | 💎 Platinum | Make 500 friends | 1000 |

#### Challenges Joined (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 161 | Challenge Curious | 🥉 Bronze | Join 1 challenge | 25 |
| 162 | Challenge Regular | 🥈 Silver | Join 25 challenges | 100 |
| 163 | Challenge Enthusiast | 🥇 Gold | Join 100 challenges | 300 |
| 164 | Challenge Addict | 💎 Platinum | Join 500 challenges | 1000 |

#### Challenges Won (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 165 | First Win | 🥉 Bronze | Win 1 challenge | 50 |
| 166 | Winner | 🥈 Silver | Win 25 challenges | 150 |
| 167 | Champion | 🥇 Gold | Win 100 challenges | 400 |
| 168 | Challenge Legend | 💎 Platinum | Win 250 challenges | 1500 |

#### Workout Shares (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 169 | First Share | 🥉 Bronze | Share 5 workouts | 25 |
| 170 | Sharing Regular | 🥈 Silver | Share 50 workouts | 75 |
| 171 | Sharing Champion | 🥇 Gold | Share 250 workouts | 200 |
| 172 | Sharing Legend | 💎 Platinum | Share 1,000 workouts | 750 |

#### Shared Workouts with Friends (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 173 | Workout Buddy | 🥉 Bronze | 1 shared workout | 25 |
| 174 | Workout Crew | 🥈 Silver | 25 shared workouts | 100 |
| 175 | Workout Squad | 🥇 Gold | 100 shared workouts | 300 |
| 176 | Workout Family | 💎 Platinum | 500 shared workouts | 1000 |

#### Community Supporter (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 177 | Helpful | 🥉 Bronze | 10 helpful interactions | 25 |
| 178 | Supportive | 🥈 Silver | 100 helpful interactions | 100 |
| 179 | Pillar of Community | 🥇 Gold | 500 helpful interactions | 300 |
| 180 | Community Legend | 💎 Platinum | 2,500 helpful interactions | 1000 |

#### Leaderboard Top 10 (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 181 | Top 10 First | 🥉 Bronze | 1 top-10 finish | 50 |
| 182 | Top 10 Regular | 🥈 Silver | 10 top-10 finishes | 150 |
| 183 | Top 10 Champion | 🥇 Gold | 50 top-10 finishes | 400 |
| 184 | Top 10 Legend | 💎 Platinum | 200 top-10 finishes | 1500 |

#### Leaderboard #1 (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 185 | First Place First | 🥉 Bronze | 1 first place | 75 |
| 186 | First Place Regular | 🥈 Silver | 10 first places | 200 |
| 187 | First Place Champion | 🥇 Gold | 50 first places | 500 |
| 188 | First Place Legend | 💎 Platinum | 150 first places | 2000 |

---

### G. BODY COMPOSITION, MEASUREMENTS & PHOTOS (52 trophies)

#### Weight Loss (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 189 | Weight Loss Starter | 🥉 Bronze | Lose 5 lbs | 50 |
| 190 | Weight Loss Progress | 🥈 Silver | Lose 15 lbs | 150 |
| 191 | Weight Loss Champion | 🥇 Gold | Lose 30 lbs | 350 |
| 192 | Weight Loss Legend | 💎 Platinum | Lose 50 lbs | 1000 |

#### Weight Gain - Bulking (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 193 | Bulk Starter | 🥉 Bronze | Gain 5 lbs | 50 |
| 194 | Bulk Progress | 🥈 Silver | Gain 15 lbs | 150 |
| 195 | Bulk Champion | 🥇 Gold | Gain 25 lbs | 300 |
| 196 | Bulk Legend | 💎 Platinum | Gain 40 lbs | 750 |

#### Weight Logging Streak (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 197 | Weight Tracker | 🥉 Bronze | 7-day weight logging streak | 25 |
| 198 | Weight Watcher | 🥈 Silver | 30-day weight logging streak | 75 |
| 199 | Weight Dedicated | 🥇 Gold | 100-day weight logging streak | 200 |
| 200 | Weight Legend | 💎 Platinum | 365-day weight logging streak | 750 |

#### Total Weight Logs (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 201 | Log Starter | 🥉 Bronze | 25 weight entries | 25 |
| 202 | Log Regular | 🥈 Silver | 100 weight entries | 75 |
| 203 | Log Champion | 🥇 Gold | 365 weight entries | 200 |
| 204 | 3 Year Logger | 💎 Platinum | 1,095 weight entries | 750 |

#### Measurement Sessions (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 205 | Measurement Starter | 🥉 Bronze | 5 measurement sessions | 25 |
| 206 | Measurement Regular | 🥈 Silver | 25 measurement sessions | 75 |
| 207 | Measurement Dedicated | 🥇 Gold | 100 measurement sessions | 200 |
| 208 | Measurement Legend | 💎 Platinum | 365 measurement sessions | 750 |

#### Measurement Streak - Weekly (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 209 | Monthly Measurer | 🥉 Bronze | 4 consecutive weeks | 25 |
| 210 | Quarterly Measurer | 🥈 Silver | 12 consecutive weeks | 75 |
| 211 | Yearly Measurer | 🥇 Gold | 52 consecutive weeks | 250 |
| 212 | 3 Year Measurer | 💎 Platinum | 156 consecutive weeks | 1000 |

#### Body Parts Tracked (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 213 | Basic Tracker | 🥉 Bronze | Track 3 body parts | 25 |
| 214 | Thorough Tracker | 🥈 Silver | Track 6 body parts | 50 |
| 215 | Complete Tracker | 🥇 Gold | Track 10 body parts | 100 |
| 216 | Full Body Tracker | 💎 Platinum | Track 15+ body parts | 250 |

#### Waist Reduction (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 217 | Waist Trimmer | 🥉 Bronze | Lose 1 inch from waist | 50 |
| 218 | Waist Reducer | 🥈 Silver | Lose 3 inches from waist | 150 |
| 219 | Waist Champion | 🥇 Gold | Lose 6 inches from waist | 350 |
| 220 | Waist Legend | 💎 Platinum | Lose 10+ inches from waist | 1000 |

#### Chest/Bicep Growth (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 221 | Growth Starter | 🥉 Bronze | Gain 0.5 inch | 50 |
| 222 | Growth Progress | 🥈 Silver | Gain 1.5 inches | 150 |
| 223 | Growth Champion | 🥇 Gold | Gain 3 inches | 350 |
| 224 | Growth Legend | 💎 Platinum | Gain 5+ inches | 1000 |

#### Hip-to-Waist Ratio (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 225 | Ratio Improver | 🥉 Bronze | 2% improvement | 50 |
| 226 | Ratio Builder | 🥈 Silver | 5% improvement | 150 |
| 227 | Ratio Champion | 🥇 Gold | 10% improvement | 350 |
| 228 | Ratio Legend | 💎 Platinum | 15% improvement | 1000 |

#### Progress Photos Taken (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 229 | Photo Starter | 🥉 Bronze | Take 5 progress photos | 25 |
| 230 | Photo Regular | 🥈 Silver | Take 25 progress photos | 75 |
| 231 | Photo Dedicated | 🥇 Gold | Take 100 progress photos | 200 |
| 232 | Daily Photo Legend | 💎 Platinum | Take 365 progress photos | 750 |

#### Photo Streak - Weekly (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 233 | Monthly Photographer | 🥉 Bronze | 4 consecutive weeks | 25 |
| 234 | Quarterly Photographer | 🥈 Silver | 12 consecutive weeks | 75 |
| 235 | Yearly Photographer | 🥇 Gold | 52 consecutive weeks | 250 |
| 236 | 2 Year Photographer | 💎 Platinum | 104 consecutive weeks | 1000 |

#### Comparison Photos (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 237 | First Comparison | 🥉 Bronze | Create 1 comparison | 25 |
| 238 | Comparison Regular | 🥈 Silver | Create 10 comparisons | 75 |
| 239 | Comparison Champion | 🥇 Gold | Create 50 comparisons | 200 |
| 240 | Comparison Legend | 💎 Platinum | Create 200 comparisons | 750 |

---

### H. NUTRITION ACHIEVEMENTS (32 trophies)

#### Meals Logged (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 241 | Meal Logger | 🥉 Bronze | Log 25 meals | 25 |
| 242 | Meal Tracker | 🥈 Silver | Log 250 meals | 100 |
| 243 | Meal Master | 🥇 Gold | Log 1,000 meals | 300 |
| 244 | Meal Legend | 💎 Platinum | Log 5,000 meals | 1000 |

#### Calorie Tracking Days (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 245 | Calorie Starter | 🥉 Bronze | 7 days tracking calories | 25 |
| 246 | Calorie Regular | 🥈 Silver | 30 days tracking calories | 75 |
| 247 | Calorie Dedicated | 🥇 Gold | 180 days tracking calories | 250 |
| 248 | 2 Year Calorie Tracker | 💎 Platinum | 730 days tracking calories | 1000 |

#### Protein Goals Hit (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 249 | Protein Starter | 🥉 Bronze | Hit protein goal 10 days | 25 |
| 250 | Protein Regular | 🥈 Silver | Hit protein goal 50 days | 100 |
| 251 | Protein Champion | 🥇 Gold | Hit protein goal 200 days | 300 |
| 252 | Protein Legend | 💎 Platinum | Hit protein goal 730 days | 1000 |

#### Meal Prep Sessions (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 253 | Prep Beginner | 🥉 Bronze | 5 meal prep sessions | 25 |
| 254 | Prep Regular | 🥈 Silver | 50 meal prep sessions | 100 |
| 255 | Prep Master | 🥇 Gold | 200 meal prep sessions | 300 |
| 256 | Prep Legend | 💎 Platinum | 520 meal prep sessions | 1000 |

#### Water Goals Hit (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 257 | Hydration Starter | 🥉 Bronze | Hit water goal 7 days | 25 |
| 258 | Hydration Regular | 🥈 Silver | Hit water goal 30 days | 75 |
| 259 | Hydration Champion | 🥇 Gold | Hit water goal 180 days | 250 |
| 260 | Hydration Legend | 💎 Platinum | Hit water goal 730 days | 1000 |

#### Clean Eating Streak (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 261 | Clean Eater | 🥉 Bronze | 3-day clean eating streak | 25 |
| 262 | Clean Week | 🥈 Silver | 14-day clean eating streak | 100 |
| 263 | Clean Month | 🥇 Gold | 30-day clean eating streak | 300 |
| 264 | Clean Legend | 💎 Platinum | 100-day clean eating streak | 1000 |

#### Macro Balance Days (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 265 | Macro Aware | 🥉 Bronze | 7 balanced macro days | 25 |
| 266 | Macro Focused | 🥈 Silver | 30 balanced macro days | 100 |
| 267 | Macro Master | 🥇 Gold | 100 balanced macro days | 300 |
| 268 | Macro Legend | 💎 Platinum | 365 balanced macro days | 1000 |

#### Supplement Tracking (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 269 | Supplement Starter | 🥉 Bronze | Track supplements 10 times | 25 |
| 270 | Supplement Regular | 🥈 Silver | Track supplements 100 times | 75 |
| 271 | Supplement Dedicated | 🥇 Gold | Track supplements 500 times | 200 |
| 272 | Supplement Legend | 💎 Platinum | Track supplements 2,000 times | 750 |

---

### I. FASTING ACHIEVEMENTS (20 trophies)

#### Intermittent Fasts - 16:8 (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 273 | IF Beginner | 🥉 Bronze | Complete 5 IF sessions | 25 |
| 274 | IF Regular | 🥈 Silver | Complete 50 IF sessions | 100 |
| 275 | IF Dedicated | 🥇 Gold | Complete 200 IF sessions | 300 |
| 276 | 2 Year IF Legend | 💎 Platinum | Complete 730 IF sessions | 1000 |

#### Extended Fasts - 24h+ (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 277 | Extended Fast First | 🥉 Bronze | Complete 1 extended fast | 50 |
| 278 | Extended Fast Regular | 🥈 Silver | Complete 10 extended fasts | 150 |
| 279 | Extended Fast Champion | 🥇 Gold | Complete 50 extended fasts | 400 |
| 280 | Extended Fast Legend | 💎 Platinum | Complete 150 extended fasts | 1000 |

#### Longest Fast Duration (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 281 | 16 Hour Faster | 🥉 Bronze | Complete 16-hour fast | 25 |
| 282 | 24 Hour Faster | 🥈 Silver | Complete 24-hour fast | 100 |
| 283 | 48 Hour Faster | 🥇 Gold | Complete 48-hour fast | 300 |
| 284 | 72 Hour Faster | 💎 Platinum | Complete 72+ hour fast | 750 |

#### Fasting Streak (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 285 | Fasting Week | 🥉 Bronze | 7-day fasting streak | 25 |
| 286 | Fasting Month | 🥈 Silver | 30-day fasting streak | 100 |
| 287 | Fasting Century | 🥇 Gold | 100-day fasting streak | 350 |
| 288 | Fasting Year | 💎 Platinum | 365-day fasting streak | 1000 |

#### Total Fasting Hours (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 289 | 100 Hours Fasted | 🥉 Bronze | 100 total fasting hours | 25 |
| 290 | 500 Hours Fasted | 🥈 Silver | 500 total fasting hours | 100 |
| 291 | 2000 Hours Fasted | 🥇 Gold | 2,000 total fasting hours | 350 |
| 292 | 10000 Hours Fasted | 💎 Platinum | 10,000 total fasting hours | 1000 |

---

### J. AI COACH ENGAGEMENT (28 trophies)

#### Chat Messages Sent (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 293 | Chat Starter | 🥉 Bronze | Send 25 messages to coach | 25 |
| 294 | Chat Regular | 🥈 Silver | Send 250 messages to coach | 75 |
| 295 | Chat Champion | 🥇 Gold | Send 1,000 messages to coach | 200 |
| 296 | Chat Legend | 💎 Platinum | Send 5,000 messages to coach | 750 |

#### Coach Sessions (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 297 | Session Starter | 🥉 Bronze | 10 coach sessions | 25 |
| 298 | Session Regular | 🥈 Silver | 100 coach sessions | 100 |
| 299 | Session Champion | 🥇 Gold | 500 coach sessions | 300 |
| 300 | Session Legend | 💎 Platinum | 2,000 coach sessions | 1000 |

#### Questions Asked (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 301 | Curious | 🥉 Bronze | Ask 10 questions | 25 |
| 302 | Inquisitive | 🥈 Silver | Ask 100 questions | 75 |
| 303 | Knowledge Seeker | 🥇 Gold | Ask 500 questions | 200 |
| 304 | Question Master | 💎 Platinum | Ask 2,500 questions | 750 |

#### Advice Followed (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 305 | Advice Taker | 🥉 Bronze | Follow coach advice 5 times | 25 |
| 306 | Good Student | 🥈 Silver | Follow coach advice 50 times | 100 |
| 307 | Star Student | 🥇 Gold | Follow coach advice 250 times | 300 |
| 308 | Perfect Student | 💎 Platinum | Follow coach advice 1,000 times | 1000 |

#### Workout Modifications (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 309 | Modifier | 🥉 Bronze | Request 5 workout modifications | 25 |
| 310 | Customizer | 🥈 Silver | Request 50 workout modifications | 75 |
| 311 | Personalizer | 🥇 Gold | Request 200 workout modifications | 200 |
| 312 | Modification Master | 💎 Platinum | Request 1,000 workout modifications | 750 |

#### Form Check Requests (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 313 | Form Checker | 🥉 Bronze | Request 5 form checks | 25 |
| 314 | Form Focused | 🥈 Silver | Request 50 form checks | 75 |
| 315 | Form Perfectionist | 🥇 Gold | Request 200 form checks | 200 |
| 316 | Form Master | 💎 Platinum | Request 1,000 form checks | 750 |

#### Feedback Given (4 trophies)
| # | Trophy Name | Tier | Requirement | XP |
|---|-------------|------|-------------|-----|
| 317 | Feedback Giver | 🥉 Bronze | Give 10 feedback items | 25 |
| 318 | Feedback Regular | 🥈 Silver | Give 50 feedback items | 75 |
| 319 | Feedback Champion | 🥇 Gold | Give 200 feedback items | 200 |
| 320 | Feedback Legend | 💎 Platinum | Give 1,000 feedback items | 750 |

---

### K. SPECIAL & SECRET ACHIEVEMENTS (40 trophies)

#### Time-Based Secret (8 trophies)
| # | Trophy Name | Type | Requirement | XP |
|---|-------------|------|-------------|-----|
| 321 | 🌅 Dawn Warrior | Secret | Workout at sunrise (5-6 AM) | 75 |
| 322 | 🌙 Midnight Grinder | Secret | Workout after midnight | 75 |
| 323 | 🎆 New Year Crusher | Secret | Workout on January 1st | 100 |
| 324 | 🎃 Halloween Hustle | Secret | Workout on October 31st | 75 |
| 325 | 💪 Birthday Gains | Secret | Workout on your birthday | 100 |
| 326 | 🦃 Turkey Burner | Secret | Workout on Thanksgiving | 75 |
| 327 | 🎄 Christmas Crusher | Secret | Workout on December 25th | 100 |
| 328 | ❤️ Valentine Gains | Secret | Workout on February 14th | 75 |

#### Challenge-Based Secret (8 trophies)
| # | Trophy Name | Type | Requirement | XP |
|---|-------------|------|-------------|-----|
| 329 | 🔥 Fire Starter | Secret | 5 workouts in first week | 100 |
| 330 | 💎 Diamond Hands | Secret | Don't skip for 30 days | 150 |
| 331 | 🦾 Iron Will | Secret | Complete workout despite low energy | 75 |
| 332 | 🏔️ Summit Seeker | Secret | Complete hardest difficulty workout | 100 |
| 333 | 🌪️ Tornado | Secret | Complete 3 workouts in one day | 150 |
| 334 | 🎯 Sniper | Secret | Hit exact target weight on all sets | 100 |
| 335 | 🚀 Launch Pad | Secret | Complete 10 workouts in first month | 100 |
| 336 | 💯 Century | Secret | 100 workouts in a calendar year | 200 |

#### Social Secret (6 trophies)
| # | Trophy Name | Type | Requirement | XP |
|---|-------------|------|-------------|-----|
| 337 | 🤝 Social Butterfly | Secret | React to 100 posts in one week | 100 |
| 338 | 📣 Influencer | Secret | Get 1000 reactions on a single post | 250 |
| 339 | 🎪 Party Host | Secret | Create challenge with 50+ participants | 200 |
| 340 | 👥 Squad Goals | Secret | Workout with 5+ friends simultaneously | 150 |
| 341 | 💬 Conversationalist | Secret | 50+ comments in one week | 100 |
| 342 | 🌟 Rising Star | Secret | First to complete a new challenge | 150 |

#### Nutrition/Fasting Secret (4 trophies)
| # | Trophy Name | Type | Requirement | XP |
|---|-------------|------|-------------|-----|
| 343 | 🥗 Clean Machine | Secret | 30-day streak with no cheat meals | 150 |
| 344 | 🍳 Meal Master | Secret | Log perfect macros 7 consecutive days | 100 |
| 345 | ⏱️ Fasting Champion | Secret | Complete 72-hour fast | 200 |
| 346 | 💧 Hydration Hero | Secret | Hit water goal 100 consecutive days | 150 |

#### AI Coach Secret (4 trophies)
| # | Trophy Name | Type | Requirement | XP |
|---|-------------|------|-------------|-----|
| 347 | 🤖 Best Friends | Secret | 500+ messages with AI coach | 150 |
| 348 | 🧠 Knowledge Seeker | Secret | Ask coach 100 unique questions | 100 |
| 349 | 📝 Feedback Champion | Secret | Provide 50 workout feedback ratings | 100 |
| 350 | 🎓 Student of the Game | Secret | Follow coach advice 100 times | 150 |

#### Stats & Analytics Secret (2 trophies)
| # | Trophy Name | Type | Requirement | XP |
|---|-------------|------|-------------|-----|
| 351 | 📊 Data Nerd | Secret | View analytics 100 times in one month | 100 |
| 352 | 📈 Trend Watcher | Secret | Export 10 reports in one month | 75 |

#### Hidden - COMPLETELY INVISIBLE (8 trophies)
| # | Trophy Name | Type | Requirement | XP |
|---|-------------|------|-------------|-----|
| 353 | 🥚 Easter Egg | Hidden | Find the hidden feature | 100 |
| 354 | 🎯 Perfectionist | Hidden | 100% completion rate for 3 months | 500 |
| 355 | 🏆 Overachiever | Hidden | Exceed weekly goal by 300% | 200 |
| 356 | 👑 King of Consistency | Hidden | Complete 2,000 total workouts | 1500 |
| 357 | 🌌 Night Owl Legend | Hidden | 100 workouts after 10 PM | 300 |
| 358 | 🏋️ Iron Legend | Hidden | Lift 5 million lbs lifetime | 2000 |
| 359 | 📱 App Addict | Hidden | 365 consecutive days of app opens | 500 |
| 360 | 🔮 Oracle | Hidden | Perfect workout prediction (AI suggested, completed exactly) | 150 |

---

### L. COMPETITIVE/MOVEABLE TROPHIES - WORLD RECORDS (30 trophies)

**These are UNIQUE trophies - only ONE user holds each at a time!**

When someone beats the record, the trophy **MOVES** to the new holder.
Previous holder loses the trophy but earns a **"Former Champion"** badge permanently.

#### Visual Design
- Animated crown/champion effect
- Pulsing golden glow with "WORLD RECORD" banner
- Shows current holder's username on trophy
- "DEFEND YOUR TITLE" notification when someone gets close (within 10%)

#### Single Lift Records - Heaviest Weight (6 trophies)
| # | Trophy Name | Type | Requirement | XP While Held |
|---|-------------|------|-------------|---------------|
| 361 | 🏆 Bench Press World Record | Competitive | Heaviest bench press logged | 50/day |
| 362 | 🏆 Squat World Record | Competitive | Heaviest squat logged | 50/day |
| 363 | 🏆 Deadlift World Record | Competitive | Heaviest deadlift logged | 50/day |
| 364 | 🏆 Overhead Press World Record | Competitive | Heaviest OHP logged | 50/day |
| 365 | 🏆 Barbell Row World Record | Competitive | Heaviest row logged | 50/day |
| 366 | 🏆 Lat Pulldown World Record | Competitive | Heaviest lat pulldown logged | 50/day |

#### Rep Records - Most Reps in Single Set (6 trophies)
| # | Trophy Name | Type | Requirement | XP While Held |
|---|-------------|------|-------------|---------------|
| 367 | 🏆 Push-up King | Competitive | Most push-ups in one set | 50/day |
| 368 | 🏆 Pull-up King | Competitive | Most pull-ups in one set | 50/day |
| 369 | 🏆 Squat Rep King | Competitive | Most bodyweight squats in one set | 50/day |
| 370 | 🏆 Dip Champion | Competitive | Most dips in one set | 50/day |
| 371 | 🏆 Sit-up Superstar | Competitive | Most sit-ups in one set | 50/day |
| 372 | 🏆 Plank Master | Competitive | Longest plank hold | 50/day |

#### Volume Records (7 trophies)
| # | Trophy Name | Type | Requirement | XP While Held |
|---|-------------|------|-------------|---------------|
| 373 | 🏆 Volume King | Competitive | Highest total volume (weight × reps) in single workout | 50/day |
| 374 | 🏆 Rep Marathon Champion | Competitive | Most total reps in single workout | 50/day |
| 375 | 🏆 Set Crusher | Competitive | Most sets completed in single workout | 50/day |
| 376 | 🏆 Iron Man | Competitive | Longest single workout duration | 50/day |
| 377 | 🏆 Daily Destroyer | Competitive | Highest volume in 24 hours | 50/day |
| 378 | 🏆 Weekly Warrior | Competitive | Highest volume in 7 days | 50/day |
| 379 | 🏆 Monthly Monster | Competitive | Highest volume in 30 days | 50/day |

#### Streak Records (4 trophies)
| # | Trophy Name | Type | Requirement | XP While Held |
|---|-------------|------|-------------|---------------|
| 380 | 🏆 Streak Legend | Competitive | Longest active workout streak | 75/day |
| 381 | 🏆 Perfect Week Champion | Competitive | Most consecutive perfect weeks | 75/day |
| 382 | 🏆 Early Bird Champion | Competitive | Most 5AM workouts all-time | 50/day |
| 383 | 🏆 Night Owl Champion | Competitive | Most midnight workouts all-time | 50/day |

#### Social Records (4 trophies)
| # | Trophy Name | Type | Requirement | XP While Held |
|---|-------------|------|-------------|---------------|
| 384 | 🏆 Most Popular | Competitive | Most total reactions received | 50/day |
| 385 | 🏆 Social Champion | Competitive | Most friends in network | 50/day |
| 386 | 🏆 Challenge King | Competitive | Most challenge wins | 75/day |
| 387 | 🏆 Community MVP | Competitive | Most helpful interactions | 50/day |

#### Cumulative Records (3 trophies)
| # | Trophy Name | Type | Requirement | XP While Held |
|---|-------------|------|-------------|---------------|
| 388 | 🏆 Iron Legend | Competitive | Most lifetime weight lifted | 100/day |
| 389 | 🏆 Workout Warrior | Competitive | Most total workouts completed | 100/day |
| 390 | 🏆 XP Champion | Competitive | Highest XP level achieved | 100/day |

#### Record Holder Perks
- Special animated profile badge while holding record
- Name displayed on global leaderboard
- "World Record Holder" title option in profile
- Push notification when record is challenged (within 10%)
- Push notification when record is broken
- Daily XP bonus while holding the record

#### Former Champion System
When you lose a world record:
- Earn permanent "Former [Record Name] Champion" badge
- Badge shows dates you held the record
- Badge shows number of days you defended it
- Former Champions appear in record history

#### Database Schema for World Records
```sql
CREATE TABLE world_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  record_type TEXT NOT NULL UNIQUE,
  current_holder_id UUID REFERENCES auth.users NOT NULL,
  record_value DECIMAL NOT NULL,
  record_unit TEXT NOT NULL, -- 'lbs', 'kg', 'reps', 'seconds'
  exercise_id UUID REFERENCES exercises(id),
  achieved_at TIMESTAMPTZ NOT NULL,
  previous_holder_id UUID REFERENCES auth.users,
  previous_record DECIMAL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE world_record_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  record_type TEXT NOT NULL,
  holder_id UUID REFERENCES auth.users NOT NULL,
  record_value DECIMAL NOT NULL,
  held_from TIMESTAMPTZ NOT NULL,
  held_until TIMESTAMPTZ,
  days_held INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 9. Gifts & Rewards Retention System

### Gift Types & Tiers

| Gift Type | Value | Trigger | Eligibility |
|-----------|-------|---------|-------------|
| 🎁 Mini Gifts | $5-10 | Level milestones | Trust Level 2+ |
| 🎁 Medium Gifts | $15-25 | Major achievements | Trust Level 3 |
| 🎁 Premium Gifts | $50+ | Elite milestones | Verified users only |
| 👕 FitWiz Merch | $20-50 | Platinum trophies | Trust Level 3 |

### Level-Based Gift Schedule

| Level | Gift | Value | Fraud Protection |
|-------|------|-------|------------------|
| 10 | $5 Amazon Gift Card | $5 | 30+ days account age |
| 25 | $10 Amazon Gift Card | $10 | Trust Level 2 |
| 50 | $25 Amazon OR FitWiz T-Shirt | $25 | Trust Level 3 |
| 75 | $50 Amazon OR Supplement Sample Box | $50 | Health App verified |
| 100 | $100 Amazon + Hoodie + Lifetime Premium | $150+ | Manual review |

### Streak-Based Gifts

| Streak | Gift | Value |
|--------|------|-------|
| 30 days | $5 Starbucks Gift Card | $5 |
| 90 days | $15 Amazon Gift Card | $15 |
| 180 days | $25 Amazon + Protein Sample | $30 |
| 365 days | $50 Amazon + Merch Bundle | $75 |
| 730 days | $100 Amazon + Full Kit + Lifetime | $175 |

### Achievement-Based Gifts

| Achievement | Gift |
|-------------|------|
| First Platinum Trophy | $10 Amazon Gift Card |
| 5 Platinum Trophies | $25 Amazon Gift Card |
| 10 Platinum Trophies | $50 Amazon Gift Card |
| Million Pound Club | Exclusive T-Shirt |
| World Record Holder | $25 Amazon + Champion Merch |

### Referral Rewards

| Action | Referrer Gets | New User Gets |
|--------|---------------|---------------|
| Friend signs up | 500 XP | 500 XP |
| Friend completes 10 workouts | $5 Amazon | $5 Amazon |
| Friend reaches Level 25 | $10 Amazon | $10 Amazon |
| Friend subscribes to Premium | 1 month free | 1 month free |

**Max referral earnings: $100/month**

### Surprise Loot Drops (Non-Gambling)

- After every 10th workout: 10% chance of mini reward
- Possible: Discount codes, free month premium, $5 gift cards
- NO purchase required
- Capped at $20/month

### Gift Fraud Prevention

**Eligibility Requirements:**
- Account age: 30+ days for any gift
- Trust Level 2+ for gifts over $5
- Trust Level 3 for gifts over $25
- Health App verification for gifts over $50
- Manual review for gifts over $100

**Clawback Policy:**
- Fraud within 90 days: Gift revoked
- Account banned: Pending rewards cancelled
- Subscription chargeback: Rewards deducted

### Gift Database Schema

```sql
CREATE TABLE user_rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  reward_type TEXT NOT NULL, -- 'gift_card', 'merch', 'premium', 'discount'
  reward_value DECIMAL,
  reward_details JSONB, -- {brand, amount, code}
  trigger_type TEXT NOT NULL, -- 'level', 'streak', 'achievement', 'referral', 'loot'
  trigger_id TEXT,
  status TEXT DEFAULT 'available', -- 'available', 'claimed', 'delivered', 'expired'
  claimed_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  delivery_email TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE referral_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID REFERENCES auth.users NOT NULL,
  referred_id UUID REFERENCES auth.users NOT NULL,
  referral_code TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending', 'qualified', 'rewarded'
  workouts_completed INT DEFAULT 0,
  level_reached INT DEFAULT 1,
  referrer_reward_paid DECIMAL DEFAULT 0,
  referred_reward_paid DECIMAL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gift_budget_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  month DATE NOT NULL,
  total_gift_value DECIMAL DEFAULT 0,
  referral_earnings DECIMAL DEFAULT 0,
  UNIQUE(user_id, month)
);
```

---

## 10. Anti-Fraud & Validation System

### Multi-Layer Protection

| Layer | Purpose |
|-------|---------|
| 1. Input Validation | Max weights, reps, sets per exercise |
| 2. Behavioral Analysis | Pattern detection for bots/cheating |
| 3. Server-Side Validation | XP calculated server-side only |
| 4. World Record Verification | Manual review for top records |
| 5. Health App Integration | Apple Health/Google Fit verification |
| 6. Account Security | Device fingerprinting, rate limits |
| 7. Audit Logging | Full trail of all XP/rewards |

### Trust Score System

| Level | Requirement | Capabilities |
|-------|-------------|--------------|
| 1 | New user | Limited XP, no gifts |
| 2 | 10 legit workouts | Full XP, basic gifts |
| 3 | 50 legit workouts | All features, medium gifts |
| Verified | Health App connected | Premium gifts, world records |

### Realistic Limits

| Exercise | Max Weight | Max Reps | Max Sets |
|----------|------------|----------|----------|
| Bench Press | 800 lbs | 100 | 20 |
| Squat | 1000 lbs | 100 | 20 |
| Deadlift | 1100 lbs | 50 | 15 |
| OHP | 500 lbs | 100 | 20 |
| Bodyweight | N/A | 500 | 30 |

### Penalty System

| Offense | Penalty |
|---------|---------|
| First flag | Warning + reduced XP 7 days |
| Second flag | 30-day probation |
| Third flag | Permanent leaderboard ban |
| Confirmed cheating | Account suspension |

### Audit Log Schema

```sql
CREATE TABLE xp_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  action TEXT NOT NULL,
  amount INT,
  reason TEXT,
  source_workout_id UUID,
  flags TEXT[],
  trust_level INT,
  ip_address INET,
  device_fingerprint TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE record_challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  record_id UUID REFERENCES world_records(id),
  challenger_id UUID REFERENCES auth.users,
  reason TEXT NOT NULL,
  evidence TEXT,
  status TEXT DEFAULT 'pending',
  reviewed_by UUID,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## Platinum Threshold Summary

| Category | Platinum Requirement | Real-World Meaning |
|----------|---------------------|-------------------|
| Workouts | 2,000 | ~4 years @ 10/week |
| Streak | 730 days | 2 consecutive years! |
| Weight Lifted | 5,000,000 lbs | Elite lifter territory |
| Posts | 1,000 | Very active community member |
| Reactions | 10,000 | Extremely engaged |
| Friends | 500 | Influencer level |
| Meals | 5,000 | ~4.5 years of tracking |
| Fasts | 730 | 2 years daily IF |
| Coach Messages | 5,000 | Heavy AI engagement |
| Challenge Wins | 250 | Elite competitor |
| Progress Photos | 365 | Daily for a year |
| Calorie Tracking | 730 days | 2 years consistent |

**Platinum should feel like a LEGEND badge - most users will never get it. That's the point.**

---

## Files to Implement

### Backend
1. `backend/migrations/161_xp_system.sql` - XP tables
2. `backend/migrations/162_expanded_achievements.sql` - New achievements
3. `backend/migrations/163_merch_claims.sql` - Merch system
4. `backend/migrations/164_gifts_rewards.sql` - Gifts & referral tables
5. `backend/migrations/165_anti_fraud.sql` - Audit log & trust system
6. `backend/api/v1/achievements.py` - Update endpoints
7. `backend/api/v1/xp.py` - XP endpoints
8. `backend/api/v1/merch.py` - Merch claim endpoints
9. `backend/api/v1/rewards.py` - Gift card & rewards endpoints
10. `backend/api/v1/referrals.py` - Referral tracking endpoints
11. `backend/services/xp_service.py` - XP calculation
12. `backend/services/rewards_service.py` - Gift delivery integration
13. `backend/services/fraud_detection.py` - Trust score & validation

### Frontend
1. `lib/screens/achievements/trophy_room_screen.dart` - View All page
2. `lib/screens/achievements/achievement_detail_screen.dart` - Detail view
3. `lib/screens/rewards/rewards_screen.dart` - Gift claim page
4. `lib/screens/referrals/referral_screen.dart` - Referral sharing
5. `lib/widgets/trophy_card.dart` - Trophy card with animations
6. `lib/widgets/xp_progress_bar.dart` - XP display widget
7. `lib/widgets/gift_claim_sheet.dart` - Gift claim bottom sheet
8. `lib/data/models/achievement.dart` - Updated models
9. `lib/data/models/reward.dart` - Reward/gift models
10. `lib/data/repositories/achievements_repository.dart` - API calls
11. `lib/data/repositories/rewards_repository.dart` - Rewards API calls

---

*Document Version: 3.0*
*Last Updated: 2026-01-19*
*Total Achievements: 390 (360 standard + 30 competitive/world records)*
*Includes: Gifts & Rewards Retention System, Anti-Fraud Protection*
