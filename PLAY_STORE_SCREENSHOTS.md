# FitWiz Play Store Screenshots Guide

## Setup
- **Tool**: [theapplaunchpad.com](https://theapplaunchpad.com)
- **Size**: 1080x1920px (portrait, 9:16)
- **Format**: PNG (24-bit, no alpha) or JPEG
- **Max file size**: 8MB per image
- **App mode**: Dark mode ON
- **Device**: Android emulator (Pixel 7 or similar)

---

## Screenshot 1: AI Coach Chat

| Field | Value |
|-------|-------|
| **Caption** | **"Talk To Your Coach"** |
| **Subtitle** | Ask anything. It actually knows you. |
| **Route** | `/chat` |
| **Screen file** | `screens/chat/chat_screen.dart` |

**What to capture:**
- Active conversation with 2-3 message bubbles showing agent color coding
- User asks: *"I'm tired today, can I do something lighter?"*
- Coach responds with personalized answer referencing past workout (*"Based on your leg day yesterday..."*)
- Coach avatar visible on AI messages
- Quick action pills visible at bottom (scan_food, check_form, calorie_check)
- Input bar with camera/video/attach buttons

**How to get this state:**
1. Open Chat screen
2. Send a message about being tired
3. Wait for AI response (should reference your history)
4. Scroll so 2-3 bubbles + pills + input bar are all visible
5. Screenshot

---

## Screenshot 2: AI-Generated Workout

| Field | Value |
|-------|-------|
| **Caption** | **"It Builds. You Lift."** |
| **Subtitle** | AI creates your workout in seconds |
| **Route** | `/workout/:id` |
| **Screen file** | `screens/workout/workout_detail_screen.dart` |

**What to capture:**
- Full workout with exercise names, sets/reps visible
- Superset indicators (bordered container with "SUPERSET 1" header) linking paired exercises
- Warmup section collapsed or visible
- "More Info" section expanded → "WHY THESE EXERCISES?" AI reasoning visible
- Stats row (duration, exercise count, calories)

**How to get this state:**
1. Generate a workout from home screen (choose "Energized" mood for a good one)
2. Open the workout detail
3. Scroll to show 3-4 exercises with at least one superset pair
4. Expand "More Info" → expand "Why These Exercises?" to show AI reasoning
5. Make sure the "Let's Go" button is visible at bottom
6. Screenshot

---

## Screenshot 3: AI Food Parser (Text-to-Calories)

| Field | Value |
|-------|-------|
| **Caption** | **"Type It. AI Gets It."** |
| **Subtitle** | Say what you ate. Instant calories & macros. |
| **Route** | Nutrition tab → "+" button → Log Meal Sheet |
| **Screen file** | `screens/nutrition/log_meal_sheet.dart` |

**What to capture:**
- The parsed result state AFTER AI analysis
- User typed something like *"2 rotis with dal and rice"* or *"chicken biryani with raita"*
- AI broke it into 3-4 separate food items
- Each item shows: name, editable count (+/-), weight, calories, macros (P/C/F)
- Meal type selector visible (Breakfast/Lunch/Dinner/Snack)

**How to get this state:**
1. Go to Nutrition screen → tap "+" to log meal
2. Select "Lunch" as meal type
3. Type a complex meal: *"chicken biryani with raita and a mango lassi"*
4. Tap analyze and wait for AI to parse
5. Screenshot the result cards showing individual food items with macros
6. Make sure count/weight edit controls are visible

---

## Screenshot 4: Smart Personalization (Staples, Avoided, Queue)

| Field | Value |
|-------|-------|
| **Caption** | **"It Learns What You Love"** |
| **Subtitle** | Star staples. Ban hated. Queue what's next. |
| **Route** | `/settings` → Training Preferences → Favorites, avoided & queue |
| **Screen file** | `screens/settings/exercise_preferences/my_exercises_screen.dart` |

**What to capture:**
- Three visible sections:
  1. **Staple exercises** — star icons, exercises that ALWAYS appear (e.g. Bench Press, Squat, Deadlift)
  2. **Avoided exercises** — X/block icons, exercises NEVER included
  3. **Exercise queue** — queue icon, exercises queued for next workout
- Visual contrast: starred (gold/green), blocked (red), queued (blue)

**How to get this state:**
1. Go to Settings → Training Preferences → "Favorites, avoided & queue"
2. Add staple exercises: Bench Press, Squat, Deadlift (star them)
3. Add avoided exercises: Behind Neck Press, Smith Machine Squat
4. Queue 1-2 exercises: Cable Flyes, Face Pulls
5. Scroll to show all three sections in one view
6. Screenshot

---

## Screenshot 5: Progress Dashboard

| Field | Value |
|-------|-------|
| **Caption** | **"Watch Yourself Level Up"** |
| **Subtitle** | PRs, streaks, heatmaps — all yours |
| **Route** | `/stats` (Overview tab) |
| **Screen file** | `screens/stats/comprehensive_stats_screen.dart` |

**What to capture:**
- Overview tab selected (first of 6 tabs: Overview / Photos / Score / Measurements / Nutrition / Mood)
- GitHub-style **activity heatmap** with lots of green squares
- **Streak counter** showing a high number (e.g. "23 day streak")
- **PR highlights** showing recent personal records
- A strength or volume **chart** trending upward

**How to get this state:**
1. Need sufficient workout history (20+ workouts logged)
2. Navigate to Stats screen (Overview tab auto-selected)
3. Scroll to show heatmap + streak + PR section in frame
4. If heatmap looks sparse, log more workouts over time before capturing
5. Screenshot

---

## Screenshot 6: Nutrition Dashboard

| Field | Value |
|-------|-------|
| **Caption** | **"Macros. Micros. All Tracked."** |
| **Subtitle** | Barcode scan, recipe builder, 50+ nutrients |
| **Route** | `/nutrition` (Daily tab) |
| **Screen file** | `screens/nutrition/nutrition_screen.dart` |

**What to capture:**
- Daily tab selected
- **Macro circles/bars** — calories consumed vs target, protein/carbs/fat breakdown
- **Meal timeline** — logged meals for the day (breakfast, lunch, snack)
- **4 tab bar** visible at top (Daily / Nutrients / Water / Fasting)
- Macro progress ~70-80% complete (motivating, not empty or maxed out)

**How to get this state:**
1. Log 2-3 meals for the day (breakfast + lunch + snack)
2. Aim for ~1600-1800 cal of a 2200 cal target (looks like good progress)
3. Navigate to Nutrition screen (Daily tab)
4. Scroll to show macro summary + meal list + tab bar all visible
5. Screenshot

---

## Screenshot 7: Fitness Wrapped

| Field | Value |
|-------|-------|
| **Caption** | **"Your Gains, Wrapped"** |
| **Subtitle** | Like Spotify Wrapped, but for the gym |
| **Route** | `/wrapped/:periodKey` (e.g. `/wrapped/2026-02`) |
| **Screen file** | `screens/wrapped/wrapped_viewer_screen.dart` |

**What to capture:**
- The MOST vibrant story card — best options:
  1. **Personality type card** (card 7/8) — gym personality with fun label
  2. **Volume card** (card 2/8) — total weight lifted with huge number
  3. **Favorites card** (card 3/8) — top exercises with stats
- Progress dots at top showing it's a multi-card story
- Full-screen card with rich colors

**How to get this state:**
1. Need a completed month with workout data
2. Navigate to Wrapped (from profile or stats)
3. Open the most recent month's wrapped
4. Tap through to the most visually striking card (Personality or Volume)
5. Screenshot that single card (full screen, progress dots visible at top)

---

## Screenshot 8: Smart Adaptation (Mood, Comeback, Hell Mode, Injury)

| Field | Value |
|-------|-------|
| **Caption** | **"Tired? Fired Up? It Adapts."** |
| **Subtitle** | Mood workouts. Comeback mode. Hell mode. Injury-safe. |
| **Route** | Home screen (mood picker card) |
| **Screen file** | `screens/home/widgets/cards/mood_picker_card.dart` |

**What to capture:**
- Best option: **Home screen mood picker** showing 5 mood options:
  - Happy, Energized, Tired, Sore, Neutral (with emojis)
- "How are you feeling?" header visible
- Alt option: Chat conversation where user reports injury and AI adapts workout
- Alt option: Workout detail showing Hell Mode with max intensity badge

**How to get this state:**
1. Go to Home screen
2. Scroll to the mood picker card ("How are you feeling?")
3. DO NOT tap any mood yet — capture the selection state with all 5 options visible
4. Screenshot
5. Alternative: If mood picker doesn't look impactful enough, start a chat: *"I hurt my shoulder yesterday"* and capture the AI's response adapting the workout

---

## Story Arc

```
1. "Talk To Your Coach"           → Meet your AI coach
2. "It Builds. You Lift."         → See the AI create a workout
3. "Type It. AI Gets It."         → AI understands what you ate
4. "It Learns What You Love"      → It knows YOUR preferences
5. "Watch Yourself Level Up"      → See your results tracked
6. "Macros. Micros. All Tracked." → Complete nutrition tracking
7. "Your Gains, Wrapped"          → Delight moment, want to share
8. "Tired? Fired Up? It Adapts."  → The AI adapts to YOU (closer)
```

**Flow:** AI features (1-3) → Personalization (4) → Results (5-6) → Delight (7) → Emotional close (8)

---

## Pre-Capture Checklist

- [ ] Dark mode enabled in app settings
- [ ] Sufficient workout history (20+ workouts) for heatmap/stats
- [ ] 2-3 meals logged today for nutrition dashboard
- [ ] At least one superset workout generated
- [ ] Staple/avoided/queue exercises configured in settings
- [ ] At least one completed month for Wrapped
- [ ] No sensitive personal data visible (use display name, not real name)
- [ ] Status bar clean (good signal, battery, time)
- [ ] No debug banners or dev indicators showing

## AppLaunchpad Template Checklist

- [ ] Same template style used for all 8 screenshots (consistent brand)
- [ ] Captions readable at Play Store thumbnail size
- [ ] Each screenshot clearly shows a DIFFERENT feature
- [ ] Test on Play Console preview to check thumbnail crops
- [ ] Upload all 8 to Play Console in order listed above
