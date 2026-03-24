# FitWiz Play Store Screenshots Guide

## Competitive Context

Top fitness apps (Fitbod, Hevy, MyFitnessPal, Nike Training, Peloton, Freeletics) all use 6-8 screenshots and lead with nearly identical visuals: workout lists, exercise libraries, progress charts. FitWiz breaks this pattern with 6 screenshots -- every single one earns its slot. No filler.

## Setup
- **Tool**: [theapplaunchpad.com](https://theapplaunchpad.com)
- **Size**: 1080x1920px (portrait, 9:16)
- **Format**: PNG (24-bit, no alpha) or JPEG
- **Max file size**: 8MB per image
- **App mode**: Dark mode ON
- **Device**: Android emulator (Pixel 7 or similar)

---

## The Story

The 6 screenshots tell one continuous story: **a user discovers FitWiz and realizes it's different.**

Each screenshot answers the question the previous one creates:

```
"What is this app?"          --> 1. Meet your AI coach
"What can it do?"            --> 2. It understands what you eat
"Does it make workouts too?" --> 3. Yes, and it explains why
"Is it worth sticking with?" --> 4. Look at your progress
"Is there a fun payoff?"     --> 5. Your month, wrapped
"Does it really know me?"    --> 6. It learns what you love
```

The first 3 are visible without scrolling. All three are AI-unique features no competitor can match.

---

## Master Table

| # | Caption | UI Path | Screen | Why This Screenshot | Why This Position |
|---|---------|---------|--------|--------------------|--------------------|
| 1 | **"Your AI Coach. Ask Anything."** | Bottom nav "Chat" tab | Chat screen -- active conversation with agent-colored bubbles, quick action pills, input bar | No fitness app shows a real AI conversation. Instant "this is different" signal. | Position 1 = first thing users see. Must break the pattern of every competitor showing a workout list. A chat UI is visually unexpected for a fitness app. |
| 2 | **"Type Any Meal. Instant Nutrition."** | Bottom nav "Nutrition" tab > tap "+" FAB > Log Meal sheet | Log Meal sheet -- AI-parsed food items with per-item calories/macros after typing "chicken biryani with raita" | MyFitnessPal makes you search item by item. This shows magic -- type a sentence, get a breakdown. | Position 2 = still in the "no scroll" zone. After seeing the coach, the user thinks "what can it do?" -- this is the most visually impressive AI demo. Food cards with macros are information-dense and eye-catching. |
| 3 | **"Every Exercise. Chosen For You."** | Bottom nav "Home" tab > tap today's workout card > Workout Detail | Workout detail -- exercise list with superset borders, "WHY THESE EXERCISES?" reasoning expanded, stats row | No competitor shows AI reasoning behind exercise selection. Proves personalization is real, not marketing. | Position 3 = last "no scroll" screenshot. Completes the AI trifecta: coach + food + workouts. The user now knows this app thinks, understands food, AND builds workouts. |
| 4 | **"Track Every Rep. See Every Gain."** | Bottom nav "Profile" tab > scroll to Stats section > tap "Overview" | Stats overview -- GitHub-style heatmap, streak counter, PR highlights, volume chart trending up | Heatmaps and streaks are visually compelling and emotionally motivating. Shows the app rewards consistency. | Position 4 = narrative pivot from "what AI can do" to "what YOU achieve." After seeing AI build your workout (#3), you see the results stack up. Heatmap green squares are instantly recognizable. |
| 5 | **"Your Gains. Wrapped."** | Bottom nav "Profile" tab > scroll to "MY WRAPPED" section > tap a month pill (e.g. "Feb") | Fitness Wrapped -- full-screen vibrant story card (personality type or volume card), progress dots at top | Zero fitness apps have this. Spotify Wrapped is universally understood. Triggers shareability and delight. | Position 5 = the delight moment. After seeing progress (#4), you get a reward: a beautiful, shareable summary. Visually the most vibrant -- breaks the dark UI pattern with bold colors. The "I want this app just for this" screenshot. |
| 6 | **"It Learns What You Love."** | Profile tab > Settings (gear icon) > Workout Settings > "My Exercises" (Favorites, avoided & queue) | Exercise preferences -- staple exercises (gold stars), avoided exercises (red X), queued exercises (blue queue icon) in 3 colored sections | No competitor shows this level of exercise customization. Closes with the strongest emotional message. | Position 6 = the closer. The final screenshot must leave a lasting impression. "It learns what you love" is personal -- it says this app isn't generic, it's YOURS. Three colored sections (gold/red/blue) are visually distinctive. |

---

## Narrative Flow

```
#1 "Your AI Coach"           You open the app. There's a coach who actually talks to you.
        |
        v  "What else can it do?"
#2 "Type Any Meal"           You tell it what you ate. It instantly breaks it down.
        |
        v  "Does it make workouts too?"
#3 "Every Exercise Chosen"   Yes -- and it tells you WHY it picked each exercise.
        |
        v  "Is it worth sticking with?"
#4 "Track Every Rep"         Your heatmap fills up. Streaks grow. PRs get logged.
        |
        v  "Is there a fun payoff?"
#5 "Your Gains. Wrapped."    Your month, beautifully wrapped. Share it. Feel proud.
        |
        v  "Does it really know ME?"
#6 "It Learns What You Love" It knows your staples. It avoids what you hate. It's yours.
```

---

## Screenshot Details

### Screenshot 1: AI Coach Chat

**Caption**: "Your AI Coach. Ask Anything."
**Screen**: `lib/screens/chat/chat_screen.dart`

**What to capture:**
- Active conversation with 2-3 message bubbles showing agent color coding
- Coach avatar visible on AI messages
- Quick action pills visible at bottom (scan_food, check_form, calorie_check)
- Input bar with camera/video/attach buttons

**What to send to AI (pick ONE -- whichever gives the best-looking response):**

| Option | Message to Send | Why This Works | Expected Response Style |
|--------|----------------|----------------|------------------------|
| A (recommended) | *"I'm tired today, can I do something lighter?"* | Shows the AI adapts to how you feel. Response should reference yesterday's workout and suggest a lighter session. | Short, empathetic, personalized -- mentions your recent history. |
| B | *"What should I focus on this week?"* | Shows the AI knows your training plan and weak points. Response should mention muscle groups, recovery, and goals. | Structured advice with bullet points -- looks information-rich at thumbnail size. |
| C | *"I hit a new PR on bench press today! 225 for 3 reps"* | Shows the AI celebrates with you. Response should congratulate and suggest next steps. | Enthusiastic, motivating, with progression advice. |
| D | *"My shoulder has been hurting after overhead press"* | Shows injury awareness. Response should suggest modifications and alternatives. | Careful, specific, shows medical-awareness (injury agent routes). |

**Best for screenshot:** Option A or C. Option A shows adaptation (emotional intelligence). Option C shows celebration (positive energy). Both produce short, visually clean responses that fit in 2-3 bubbles.

**Avoid sending:** Long or complex questions -- the AI response will be too long and won't fit in a screenshot. Keep the user message short (under 15 words) so the response is also concise.

**Pre-conditions for a good response:**
- Have at least 5-10 past workouts logged so the AI has history to reference
- Have a workout from yesterday or today so the AI can say "Based on your leg day yesterday..."
- If the response is too long or generic, try again -- AI responses vary

**How to get this state:**
1. Open Chat screen
2. Send one of the messages above
3. Wait for AI response
4. If the response is too long, try a different option
5. Scroll so user message + AI response + pills + input bar are all visible
6. Screenshot

---

### Screenshot 2: AI Food Parser

**Caption**: "Type Any Meal. Instant Nutrition."
**Screen**: `lib/screens/nutrition/log_meal_sheet.dart`

**What to capture:**
- The parsed result state AFTER AI analysis
- User typed *"chicken biryani with raita and a mango lassi"*
- AI broke it into 3-4 separate food items
- Each item shows: name, editable count (+/-), weight, calories, macros (P/C/F)
- Meal type selector visible (Lunch selected)

**How to get this state:**
1. Go to Nutrition screen --> tap "+" to log meal
2. Select "Lunch" as meal type
3. Type: *"chicken biryani with raita and a mango lassi"*
4. Tap analyze and wait for AI to parse
5. Screenshot the result cards showing individual food items with macros

---

### Screenshot 3: AI-Generated Workout with Reasoning

**Caption**: "Every Exercise. Chosen For You."
**Screen**: `lib/screens/workout/workout_detail_screen.dart`

**What to capture:**
- Full workout with exercise names, sets/reps visible
- Superset indicators (bordered container with "SUPERSET 1" header)
- "More Info" section expanded --> "WHY THESE EXERCISES?" AI reasoning visible
- Stats row (duration, exercise count, calories)
- "Let's Go" button visible at bottom

**How to get this state:**
1. Generate a workout from home screen (choose "Energized" mood)
2. Open the workout detail
3. Scroll to show 3-4 exercises with at least one superset pair
4. Expand "More Info" --> expand "Why These Exercises?"
5. Screenshot

---

### Screenshot 4: Progress Dashboard

**Caption**: "Track Every Rep. See Every Gain."
**Screen**: `lib/screens/stats/comprehensive_stats_screen.dart`

**What to capture:**
- Overview tab selected
- GitHub-style **activity heatmap** with lots of green squares
- **Streak counter** showing a high number (e.g. "23 day streak")
- **PR highlights** showing recent personal records
- A strength or volume **chart** trending upward

**How to get this state:**
1. Need sufficient workout history (20+ workouts logged)
2. Navigate to Stats screen (Overview tab)
3. Scroll to show heatmap + streak + PR section in frame
4. Screenshot

---

### Screenshot 5: Fitness Wrapped

**Caption**: "Your Gains. Wrapped."
**Screen**: `lib/screens/wrapped/wrapped_viewer_screen.dart`
**Best cards**: `lib/screens/wrapped/cards/personality_card.dart`, `lib/screens/wrapped/cards/volume_card.dart`

**What to capture:**
- The MOST vibrant story card -- best options:
  1. **Personality type card** (card 7/8) -- gym personality with fun label
  2. **Volume card** (card 2/8) -- total weight lifted with huge number
- Progress dots at top showing it's a multi-card story
- Full-screen card with rich colors

**How to get this state:**
1. Need a completed month with workout data
2. Navigate to Wrapped (from profile or stats)
3. Tap through to the most visually striking card
4. Screenshot that single card (full screen, progress dots visible at top)

---

### Screenshot 6: Exercise Preferences

**Caption**: "It Learns What You Love."
**Screen**: `lib/screens/settings/exercise_preferences/my_exercises_screen.dart`

**What to capture:**
- Three visible sections:
  1. **Staple exercises** -- gold star icons (Bench Press, Squat, Deadlift)
  2. **Avoided exercises** -- red X/block icons (Behind Neck Press, Smith Machine Squat)
  3. **Exercise queue** -- blue queue icons (Cable Flyes, Face Pulls)
- Clear visual contrast between the three colored sections

**How to get this state:**
1. Go to Settings --> Training Preferences --> "Favorites, avoided & queue"
2. Add staple exercises: Bench Press, Squat, Deadlift
3. Add avoided exercises: Behind Neck Press, Smith Machine Squat
4. Queue: Cable Flyes, Face Pulls
5. Scroll to show all three sections in one view
6. Screenshot

---

## Visual Distinctness Check

| # | Caption | Dominant Visual | Layout |
|---|---------|----------------|--------|
| 1 | "Your AI Coach" | Chat bubbles + input bar | Conversation |
| 2 | "Type Any Meal" | Parsed food item cards with macros | Bottom sheet + cards |
| 3 | "Every Exercise Chosen" | Exercise list + superset borders + reasoning | Detail list |
| 4 | "Track Every Rep" | Green heatmap + line charts + streak | Charts + grid |
| 5 | "Your Gains. Wrapped." | Bold full-screen vibrant card + story dots | Full-bleed card |
| 6 | "It Learns What You Love" | Star/block/queue icons in 3 colored sections | Icon list |

All 6 have different layouts, color patterns, and information shapes. No two look similar at thumbnail size.

---

## Reserve Screenshots (Add Later If Needed)

If conversion needs a boost, add these back (slots 4 and 6, shifting others down):

| Caption | UI Path | Screen | Screen File | When to Add |
|---------|---------|--------|-------------|-------------|
| "Now Crush It." | Bottom nav "Home" tab > tap today's workout card > tap "Let's Go" | Active workout -- timer, set logging, superset grouping, rest countdown | `lib/screens/workout/active_workout_screen_refactored.dart` | If users ask "but can I track workouts?" in reviews |
| "Macros. Micros. All Tracked." | Bottom nav "Nutrition" tab (Daily tab auto-selected) | Nutrition daily tab -- macro circles, meal timeline, 4-tab bar | `lib/screens/nutrition/nutrition_screen.dart` | If users don't realize the app has full nutrition tracking |

---

## Pre-Capture Checklist

- [ ] Dark mode enabled in app settings
- [ ] Sufficient workout history (20+ workouts) for heatmap/stats
- [ ] At least one superset workout generated
- [ ] Staple/avoided/queue exercises configured in settings
- [ ] At least one completed month for Wrapped
- [ ] No sensitive personal data visible (use display name, not real name)
- [ ] Status bar clean (good signal, battery, time)
- [ ] No debug banners or dev indicators showing

## AppLaunchpad Template Checklist

- [ ] Same template style used for all 6 screenshots (consistent brand)
- [ ] Captions readable at Play Store thumbnail size
- [ ] Each screenshot clearly shows a DIFFERENT feature
- [ ] Test on Play Console preview to check thumbnail crops
- [ ] Upload all 6 to Play Console in order listed above
