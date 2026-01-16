# FitWiz - Complete Feature List
<!-- you are in control of equipment mix and availability. -->
> **Total Features: 1072+** across 27 user-facing categories and 7 technical categories (includes Break Detection/Comeback, Age-Based Safety Caps, Skill Progressions, Cardio/Endurance with HR Zones & Session Logging, Flexibility/Mobility Assessment, AI Consistency, Voice Guidance, Adaptive Difficulty, Dynamic Set Management, Pre-Auth Previews, Email Preferences, Leverage-Based Progressions, Rep Range Preferences, Rep Accuracy Tracking, User-Customizable Sets/Reps Limits, Compound Exercise Muscle Mapping, History-Based Workout Generation, Background Music/Audio Session Management, Warmup Exercise Ordering, Customizable Sound Effects, Exercise Swap Tracking, HIIT/Interval Workout Safety, **Full Plan Preview Before Paywall**, **Try One Workout Free**, **Pre-Signup Pricing Transparency**, **Subscription Journey AI Context**, **Quick Start Today Widget**, **Visual Progress Charts**, **Subjective Results Tracking**, **Consistency Insights Dashboard**, **Smart Rescheduling**, **Progress Milestones & ROI**, **Split Screen/Multi-Window Support**, **Branded Workout Programs**, **Responsive Window Mode Detection**, **Lifetime Member Tiers & Benefits**, **Subscription Pause/Resume**, **Retention Offers System**, **NEAT Improvement System with Progressive Step Goals, Hourly Movement Reminders, Gamification & 35+ Achievements**, **Strength Calibration/Test Workout System with AI Analysis**, **Gradual Cardio Progression (Couch-to-5K)**, **Strain/Overuse Injury Prevention with 10% Rule**, **Injury Tracking & Body Part Exclusion**, **User-Controlled Progression Pace Settings**, **Senior-Aware Recovery Scaling**, **Enhanced Nutrition with Cooked Food Converter, Frequent Foods, Barcode Fuzzy Fallback**, **Per-Exercise Workout History & Muscle Analytics with Body Heatmap, Balance Analysis, Training Frequency**, **Hormonal Health Tracking with Testosterone/Estrogen Optimization, Menstrual Cycle Phase Tracking, Cycle-Aware Workout Intensity**, **Kegel/Pelvic Floor Exercises with 16 Gender-Specific Exercises, Warmup/Cooldown Integration, Streak Tracking**, **Hormonal Diet Recommendations with 50+ Foods for Testosterone, Estrogen, PCOS, Menopause, Fertility, Postpartum**, **AI-Powered Food Inflammation Analysis with Color-Coded Ingredient Display, Inflammation Score, Scan History & Favorites**, **Simple Habit Tracking with Templates, Streaks, AI Suggestions, Positive/Negative Habits, Category Organization**, **MacroFactor-Style Adaptive TDEE with EMA Smoothing, Confidence Intervals, Metabolic Adaptation Detection, Adherence Tracking, Sustainability Scores, Multi-Option Recommendations**, and **WearOS Companion App with Workout Tracking, Voice Food Logging via Gemini, Fasting Timer, Heart Rate Monitoring, and Hybrid Phone/Direct Sync**)

---

## Subscription Tiers & Feature Availability

> **Note:** Guest Mode (try without account) - Coming Soon based on user feedback

### Tier Pricing
| Tier | Monthly | Yearly | One-Time |
|------|---------|--------|----------|
| **Free** | $0 | - | - |
| **Premium** | $5.99 | $47.99 (33% off) | - |
| **Premium Plus** | $9.99 | $79.99 (33% off) | - |
| **Lifetime** | - | - | $99.99 |

### Feature Availability by Tier

| Feature Category | Free | Premium | Premium Plus | Lifetime |
|------------------|:----:|:-------:|:------------:|:--------:|
| **Workout Generation** | 4/month | Daily | Unlimited | Unlimited |
| **Edit Workouts** | - | Yes | Yes | Yes |
| **Save Favorites** | - | 5 | Unlimited | Unlimited |
| **Custom Templates** | - | - | Yes | Yes |
| **Food Photo Scans** | - | 5/day | 10/day | 10/day |
| **Full Macro Tracking** | - | Yes | Yes | Yes |
| **Exercise Library** | 50 | Unlimited | Unlimited | Unlimited |
| **Progress Tracking** | 7 days | Full | Full | Full |
| **Fasting Tracker** | Yes | Yes | Yes | Yes |
| **Streak Tracking** | Yes | Yes | Yes | Yes |
| **1RM Calculator** | - | Yes | Yes | Yes |
| **PR Tracking** | - | Yes | Yes | Yes |
| **Strength Standards** | - | - | Yes | Yes |
| **Social Sharing** | - | Yes | Yes | Yes |
| **Friends/Leaderboards** | - | - | Yes | Yes |
| **Export (CSV/PDF)** | - | Yes | Yes | Yes |
| **Priority Support** | - | - | Yes | Yes |
| **Ads** | Yes | No | No | No |

### Tier Badges Used in This Document
- `[FREE]` - Available to all users including free tier
- `[PREMIUM]` - Requires Premium subscription or higher
- `[PREMIUM PLUS]` - Requires Premium Plus or Lifetime subscription

> **Note:** Most features are available to all tiers with quantity/time limits. See section-specific tier tables for details on limits per feature category. Features without limits are generally FREE to all users.

---

## Implementation Status Legend

> **Added January 2026** - Each feature table now includes implementation audit columns.

### Column Key

| Column | Description |
|--------|-------------|
| **Impl** | Implementation Status: ✅ Fully Built, 🔄 Partial, ❌ Not Built, ⚠️ Claimed but Missing Code |
| **Comp** | Competitors with feature: **MF**=MacroFactor, **Fb**=Fitbod, **Hv**=Hevy, **Gr**=Gravl |
| **BE Loc** | Backend file:line in `/backend/` (— if frontend-only) |
| **FE Loc** | Frontend file:line in `/mobile/flutter/lib/` (— if backend-only) |

> **Detailed Audit**: See [FEATURES_AUDIT.md](FEATURES_AUDIT.md) for complete implementation locations with file paths and line numbers for all 1,070+ features.

### Competitor Feature Matrix (Quick Reference)

| Feature Category | MF | Fb | Hv | Gr | FitWiz |
|-----------------|:--:|:--:|:--:|:--:|:------:|
| AI Workout Generation | ❌ | ✅ | ❌ | ✅ | ✅ |
| Conversational AI Coach | ❌ | ❌ | ❌ | ❌ | ✅ |
| Exercise Videos | ✅ | ✅ | ✅ | ✅ | ✅ |
| Nutrition Tracking | ✅ | ❌ | ❌ | ❌ | ✅ |
| Fasting Timer | ❌ | ❌ | ❌ | ❌ | ✅ |
| Progress Photos | ✅ | ❌ | ✅ | ✅ | ✅ |
| Social Feed | ❌ | ❌ | ✅ | ✅ | ✅ |
| Adaptive TDEE | ✅ | ❌ | ❌ | ❌ | ✅ |
| Apple Watch | ❌ | ✅ | ✅ | ✅ | ❌ |
| WearOS | ❌ | ❌ | ❌ | ❌ | ✅ |
| Senior Mode | ❌ | ❌ | ❌ | ❌ | ✅ |
| Injury Tracking | ❌ | ❌ | ❌ | ❌ | ✅ |
| Cardio Progression | ❌ | ✅ | ❌ | ❌ | ✅ |

---

## Addressing Common Fitness App Complaints

This app specifically addresses issues commonly reported in competitor apps:

### 1. "Lack of proper workout plans for full gym equipment"
✅ **SOLVED**: We support 23+ equipment types including commercial gym machines (leg press, hack squat, cable machines, Smith machine), free weights, and specialty equipment. Users can specify exact weights available.

### 2. "Warm-up exercises stay exactly the same when you change targeted muscle group"
✅ **SOLVED**: Dynamic warmup generator creates muscle-specific warmups based on the target workout. Leg day gets leg swings and lunges, chest day gets arm circles and chest openers. 7-day variety tracking ensures no repetition.

### 2b. "Warm-ups should have static holds early, not intermixed with kinetic moves"
✅ **SOLVED**: Warmup exercise ordering system that places static holds (planks, wall sits, dead hangs) at the BEGINNING of warmups, followed by dynamic movements (jumping jacks, arm circles, leg swings). This allows users to gradually increase their heart rate through movement after completing static activation exercises. The `order_warmup_exercises()` function automatically classifies and orders all warmup exercises.

### 2c. "Intervals shouldn't have any static holds - dangerous for the heart"
✅ **SOLVED**: HIIT/interval workout safety system that PREVENTS static holds from appearing in high-intensity interval workouts. Going from burpee box jumps to planks is dangerous for cardiovascular health. The system:
- Classifies exercises as 'static' or 'dynamic' using movement type detection
- Filters out static holds (planks, wall sits, isometrics) from interval/HIIT workouts
- Database validation function `validate_hiit_no_static_holds()` ensures safety
- HIIT templates (Tabata, EMOM, AMRAP) only include dynamic exercises

### 3. "Coach doesn't adjust the plan based on actual weights I'm using"
✅ **SOLVED**: All workout generation endpoints apply user's stored 1RM data to calculate personalized working weights. Historical weight data from completed workouts is used for recommendations.

### 4. "Tried to automatically put me in a more expensive tier"
✅ **SOLVED**: Plan change confirmation dialog shows clear price comparison (old vs new plan, price difference). Full subscription history visible to users. Upcoming renewal notifications 5 days and 1 day before charges.

### 5. "Generic reply that didn't address my concern"
✅ **SOLVED**: Full support ticket system with tracking IDs, status updates, and conversation threads. Users can create, track, and follow up on support tickets directly in-app.

### 6. "No refund option"
✅ **SOLVED**: In-app refund request flow with tracking ID. Users can request refunds with reason selection and get confirmation. Full audit trail of subscription changes.

### 7. "Time-based workouts lose seconds during transitions - need countdown between exercises"
✅ **SOLVED**: 5-10 second transition countdown between exercises with animated "GET READY" display, next exercise preview (name, sets, reps, thumbnail), skip button, and haptic feedback. Countdown turns orange in final 3 seconds with pulse animation.

### 8. "App should speak out the name of the next workout"
✅ **SOLVED**: Text-to-speech voice announcements available. When enabled, app announces "Get ready for [exercise name]" during transitions and "Congratulations! Workout complete!" at the end. Abbreviations are expanded (DB→dumbbell, BB→barbell) for clearer speech. Includes rest period countdown notifications and configurable voice guidance. Toggle in Settings > Voice Announcements.

### 8b. "Countdown timer sux plus cheesy applause smh. sounds should be customizable"
✅ **SOLVED**: Complete sound customization with 4 distinct sound categories and NO applause option:

**Sound Categories:**
1. **Countdown (3, 2, 1)**: Beep, Chime, Voice, Tick, or None - plays at 3, 2, 1 seconds before rest ends
2. **Rest Timer End**: Beep, Chime, Gong, or None - plays when rest period completes
3. **Exercise Complete**: Chime, Bell, Ding, Pop, Whoosh, or None - plays when all sets of an exercise are done
4. **Workout Complete**: Chime, Bell, Success, Fanfare, or None (NO applause!) - plays when entire workout finishes

**User Flow:**
1. Navigate to Settings > Sound Effects
2. Toggle each sound category on/off independently
3. Select preferred sound type from selection chips (with preview on tap)
4. Adjust master volume with slider (0-100%)
5. Preferences sync to cloud automatically

**Technical Implementation:**
- **Flutter Package**: `audioplayers ^6.1.0`
- **Audio Session**: Ducks Spotify/Apple Music during playback
- **Preloaded Sounds**: Instant playback with no delay
- **Backend API**: `GET/PUT /api/v1/sound-preferences`
- **Database**: `sound_preferences` table with exercise_completion fields (migration 093, 145)
- **Local Caching**: SharedPreferences for offline access

**Sound Triggers:**
- Countdown: 3, 2, 1 seconds before rest ends (active_workout_screen.dart)
- Rest End: When rest timer reaches 0 (active_workout_screen.dart)
- Exercise Complete: When user finishes all sets of an exercise (active_workout_screen.dart)
- Workout Complete: When all exercises in workout are done (workout_complete_screen.dart)

**Files:**
- Migration: `backend/migrations/093_sound_preferences.sql`, `145_exercise_completion_sounds.sql`
- Backend API: `backend/api/v1/sound_preferences.py`
- Flutter Service: `lib/data/services/sound_service.dart`
- Flutter Provider: `lib/core/providers/sound_preferences_provider.dart`
- Settings UI: `lib/screens/settings/sections/sound_settings_section.dart`
- Audio Assets: `assets/audio/countdown/`, `assets/audio/exercise_complete/`, `assets/audio/workout_complete/`, `assets/audio/rest_end/`

### 9. "Can't reset or change week's settings after starting"
✅ **SOLVED**: Program menu with "Regenerate This Week" option allows one-tap workout regeneration with current settings. "Customize Program" opens full wizard to change days, equipment, or difficulty. Edit Program Sheet now includes info tooltip explaining that changes regenerate workouts.

### 10. "Need extra advanced skill progressions like dragon squats, handstand pushups"
✅ **SOLVED**: Complete skill progression system with 7 progression chains (52 exercises total):
- **Pushup Mastery** (10 steps): Wall pushups → One-arm pushups
- **Pullup Journey** (8 steps): Dead hang → One-arm pullups
- **Squat Progressions** (8 steps): Assisted squats → Dragon squats, Pistol squats
- **Handstand Journey** (8 steps): Wall plank → Freestanding handstand pushups
- **Muscle-Up Mastery** (6 steps): High pullups → Strict muscle-ups
- **Front Lever Progressions** (6 steps): Hanging raises → Full front lever
- **Planche Progressions** (6 steps): Planche lean → Full planche

Each step includes difficulty rating (1-10), unlock criteria, tips, and video. Users track progress, log attempts, and unlock next levels.

### 11. "Too intense after a break - cruel to non-athletes, especially seniors"
✅ **SOLVED**: Comprehensive break detection and comeback system:
- **Auto-detection**: Detects breaks of 7, 14, 28, and 42+ days automatically
- **Comeback mode**: Reduced intensity workouts that gradually build back up over 1-4 weeks
- **Age-aware adjustments**: Additional intensity reduction for users 50+ (up to 25% extra reduction for 80+)
- **Example**: 70-year-old returning after 5 weeks gets ~55-60% volume reduction, 50% intensity reduction, +60-75s rest, max 4 exercises, no explosive movements
- **Rep capping**: Absolute maximums enforced (seniors 60+ max 12 reps, elderly 75+ max 10 reps) regardless of what AI generates
- **Rest time scaling**: Automatic 1.5x-2x rest for seniors

### 34. "I progressed too quickly with running and strained my calf - AI should make cardio more gradual"
✅ **SOLVED**: Comprehensive gradual cardio progression system (Couch-to-5K style):
- **Progressive Running Programs**: Structured 9-12 week programs with run/walk intervals that gradually increase
- **Multiple Pace Options**:
  - **Very Slow (12 weeks)**: 15s jog → 30min continuous, ideal for seniors and injury recovery
  - **Gradual (9 weeks)**: Standard C25K progression, safe for beginners
  - **Moderate (6 weeks)**: For those with base fitness
  - **Aggressive (4 weeks)**: For experienced athletes only
- **Age-Aware Auto-Adjustment**: Users 60+ automatically get "very_slow" pace, 50+ get pace downgrade
- **Strain Detection & Response**: Reporting strain automatically pauses progression and repeats current week
- **Perceived Difficulty Monitoring**: High difficulty (8+/10) triggers week extension before advancing
- **Session Tracking**: Each cardio session tracks run/walk intervals, duration, distance, heart rate, and strain status
- **API Endpoints**:
  - `POST /cardio-progressions/` - Create new program
  - `GET /cardio-progressions/{program_id}/next-session` - Get next session details
  - `POST /cardio-progressions/{program_id}/report-strain` - Report strain with automatic adjustment
- **Database Tables**: `cardio_progression_programs`, `cardio_progression_sessions` with full RLS

### 35. "I strained my calf from overuse - app should prevent injury from too much volume"
✅ **SOLVED**: Complete strain/overuse injury prevention system:
- **The 10% Rule**: System enforces the proven training principle that weekly volume should not increase more than 10%
- **Weekly Volume Tracking**: Tracks total sets, reps, and volume (sets × reps × weight) per muscle group per week
- **Risk Level Detection**:
  - **Warning (10-15% increase)**: Caution message, monitor for fatigue
  - **Danger (15-20% increase)**: Reduce sets this week
  - **Critical (20%+ increase)**: Immediately reduce volume by 30%
- **Strain History Learning**: System learns from past strains to auto-adjust volume caps for vulnerable areas
- **Volume Alerts**: Proactive notifications when approaching dangerous volume increases
- **Automatic Workout Adjustment**: When risk is detected, exercises are auto-modified with reduced sets
- **Muscle-Specific Caps**: Personalized maximum weekly sets per muscle group based on history
- **API Endpoints**:
  - `GET /strain-prevention/{user_id}/risk-assessment` - Current strain risk by muscle
  - `POST /strain-prevention/record-strain` - Record strain incident (auto-reduces volume cap)
  - `POST /strain-prevention/adjust-workout` - Auto-adjust workout for safety
- **Database Tables**: `weekly_volume_tracking`, `volume_increase_alerts`, `strain_history`, `muscle_volume_caps`

### 36. "I trained with an adapted program removing lower leg activities after injury"
✅ **SOLVED**: Complete injury management and body part exclusion system:
- **Injury Reporting REST API**: Direct HTTP endpoints for injury tracking (not just chat-based)
  - `POST /injuries/{user_id}/report` - Report new injury with body part, severity, pain level
  - `GET /injuries/{user_id}/active` - List all active injuries
  - `POST /injuries/{injury_id}/update` - Log recovery check-in (pain level, mobility rating)
  - `DELETE /injuries/{injury_id}` - Mark injury as healed
- **Automatic Workout Modifications**:
  - Injured body parts auto-add exercises to avoided list
  - Expected recovery dates calculated by severity (mild=7d, moderate=14d, severe=35d)
  - Recovery phase tracking: acute → subacute → recovery → healed
- **Quick Body Part Exclusion During Workout**:
  - "Exclude Body Parts" button in active workout screen
  - Select areas to avoid (calves, lower leg, knee, back, shoulders, etc.)
  - Exercises targeting those areas immediately removed or replaced
- **Rehab Exercise Assignment**: Appropriate rehabilitation exercises auto-assigned per injury type:
  - Calf: Eccentric calf raises, standing calf stretch, ankle circles
  - Knee: Quad sets, straight leg raises, wall sits, heel slides
  - Back: Cat-cow stretch, bird dog, pelvic tilts
- **Contraindication System**: Comprehensive mapping of which exercises stress which body parts
- **Database Tables**: `user_injuries`, `injury_updates`, `injury_rehab_exercises` with helper functions
- **Flutter UI**: Injury reporting screen, active injuries screen, recovery progress cards, rehab exercise cards

### 37. "I should have made the AI make the progression more gradual - need control over pace"
✅ **SOLVED**: User-controlled progression pace settings:
- **Pace Selection**: Users can choose their progression speed in Settings > Training Preferences:
  - **Extra Cautious (very_slow)**: 4+ successful sessions before any increase, 2.5% weight increments
  - **Gradual (slow)**: 3 successful sessions, 5% increments - recommended for beginners
  - **Balanced (moderate)**: 2 successful sessions, 7.5% increments - standard progression
  - **Aggressive (fast)**: Progress immediately when ready, 10% increments - athletes only
- **Category-Specific Pacing**: Different pace for strength vs cardio vs flexibility
  - Cardio defaults to "slow" for injury prevention
- **AI-Powered Recommendations**: System analyzes user profile (age, fitness level, injury history, strain patterns) to recommend appropriate pace
- **Safety Limits**:
  - Max weekly volume increase % (default 10%)
  - Max weight increase % (default 10%)
  - Min sessions before progression (configurable 1-10)
  - Completion requirement % (must complete X% of prescribed before progressing)
- **Auto-Deload**: Configurable automatic deload weeks (every 3-8 weeks)
- **Feedback Integration**: System learns from "too hard" feedback to slow progression
- **API Endpoints**:
  - `GET /progression-settings/{user_id}` - Get current preferences
  - `PUT /progression-settings/{user_id}` - Update preferences
  - `GET /progression-settings/{user_id}/recommendation` - Get AI-recommended pace
  - `POST /progression-settings/{user_id}/apply-recommendation` - Apply recommended settings
- **Database Tables**: `user_progression_preferences`, `progression_pace_definitions`

### 38. "Older person trying to get moving - need age-appropriate workout scaling"
✅ **SOLVED**: Comprehensive senior/recovery-aware workout scaling:
- **Age-Based Auto-Settings**: When user is 60+, senior settings auto-applied:
  - 60-64: 1.25x recovery, 80% max intensity, 8min extended warmup
  - 65-69: 1.5x recovery, 75% max intensity, 10min extended warmup
  - 70-74: 1.75x recovery, 70% max intensity, 12min extended warmup
  - 75+: 2x recovery, 65% max intensity, 15min extended warmup
- **Low-Impact Alternatives**: Automatic substitution of high-impact exercises:
  - Running → Walking
  - Jump Squats → Bodyweight Squats
  - Burpees → Step-Back Burpees
  - Box Jumps → Step-Ups
  - Jumping Lunges → Stationary Lunges
- **Recovery Status Check**: Before each workout, system checks if user has had enough rest since last workout
  - Minimum 2 rest days between strength workouts for seniors
  - Warnings if attempting workout too soon
- **Session Limits**:
  - Max 6 exercises per session
  - Max 3 sets per exercise
  - Max 12 reps per exercise
  - Extended rest periods (auto-multiplied by age factor)
- **Mandatory Mobility**: Mobility exercises auto-added to beginning of each workout (2+ exercises)
- **Workout Modifications Applied Automatically**:
  - Weight reduced by intensity factor
  - Sets/reps capped
  - Rest periods extended
  - High-impact exercises swapped
- **API Endpoints**:
  - `GET /senior-fitness/{user_id}/settings` - Get senior settings
  - `PUT /senior-fitness/{user_id}/settings` - Update settings
  - `GET /senior-fitness/{user_id}/recovery-status` - Check recovery readiness
  - `POST /senior-fitness/apply-workout-modifications` - Apply modifications to workout
- **Database Tables**: `senior_recovery_settings` with auto-trigger on user age change

### 12. "Given 90 squats when I selected 'easier' - no rep limits"
✅ **SOLVED**: Post-generation validation caps all exercises:
- **Fitness level caps**: Beginners max 12 reps/3 sets, Intermediate max 15 reps/4 sets, Advanced max 20 reps/5 sets
- **Age caps**: 60-74 max 12 reps, 75+ max 10 reps (overrides fitness level)
- **Absolute maximums**: Never more than 30 reps or 6 sets for anyone
- **Comeback reduction**: Additional 30% rep reduction for users returning from breaks
- **Warning logs**: System logs when excessive values are capped for monitoring

### 26. "Needs to give more control over sets and reps - 6 sets of 30+ reps is way too many"
✅ **SOLVED**: Complete user-customizable sets and reps control:
- **Max Sets Per Exercise**: User-configurable limit (2-8 sets) in Settings > Training Preferences > Rep Preferences
- **Min Sets Per Exercise**: User-configurable minimum (1-4 sets) to ensure adequate volume
- **Enforce Rep Ceiling Toggle**: Strictly enforce maximum rep limit when enabled
- **Quick Presets**: "Minimal (1-2)", "Standard (2-4)", "High Volume (3-6)" one-tap selection
- **Volume Description**: Dynamic display showing "Low Volume", "Standard Volume", or "High Volume" based on settings
- **Workout Summary**: Shows combined limits like "Your workouts will have 2-4 sets of 8-12 reps per exercise"
- **Post-Generation Enforcement**: Even if AI exceeds limits, validation function caps values to user preferences
- **API Integration**: `PUT /api/v1/exercise-preferences/sets-limits` endpoint for updating preferences
- **Database Schema**: `user_rep_range_preferences` table extended with `max_sets_per_exercise`, `min_sets_per_exercise`, `enforce_rep_ceiling`

### 27. "Totally out of progression with what I have been doing - ignores my history"
✅ **SOLVED**: History-based workout generation with pattern tracking:
- **Workout Patterns Table**: Tracks average sets/reps/weight per exercise across all sessions
- **Historical Context in Prompts**: Gemini receives user's actual performance data: "For Bench Press, user typically completes 3 sets of 10 reps at 60kg"
- **Adjustment Pattern Detection**: System identifies if user "often reduces sets" or "increases weight" and adjusts generation accordingly
- **Pre-Generation Context**: `get_user_workout_patterns()` fetches user's historical exercise data before generating workouts
- **Personalized Baselines**: For exercises user has done before, system uses their historical averages instead of generic defaults
- **Clear AI Instructions**: Prompts include "NEVER prescribe more than X sets per exercise" and "NEVER prescribe more than Y reps per set"
- **Post-Generation Validation**: `enforce_set_rep_limits()` function ensures user preferences are ALWAYS respected even if AI exceeds them

### 28. "Doesn't know what some exercises involve - dumbbell squat thrusters include shoulders, not just squats"
✅ **SOLVED**: Comprehensive compound exercise muscle mapping:
- **Exercise Muscle Mappings Table**: Stores all muscles worked by each exercise with involvement percentages
- **Multi-Muscle Tracking**: "Dumbbell Squat Thruster" correctly maps to Quadriceps (35%), Glutes (25%), Shoulders (20%), Triceps (10%), Core (10%)
- **Secondary Muscle Filtering**: When user avoids a muscle (e.g., shoulder injury), exercises are filtered if that muscle has >20% involvement
- **Helper Functions**:
  - `get_exercise_muscles(exercise_name)` - Returns all muscles for an exercise with percentages
  - `exercise_involves_muscle(exercise_name, muscle, min_involvement)` - Checks if exercise targets a muscle
  - `get_exercises_for_muscle(muscle, min_involvement, primary_only)` - Find exercises for a muscle group
- **Exercise Swap Awareness**: When swapping exercises, system compares muscle profiles and warns if swap significantly changes targeted muscles
- **Muscle Profile Comparison**: Shows similarity score, missing muscles, and new muscles when swapping
- **Pre-Seeded Data**: 15+ common compound exercises pre-populated with accurate muscle mappings (Squat, Deadlift, Bench Press, Clean and Press, Burpees, Pull-ups, etc.)
- **RAG Service Integration**: Muscle filtering now checks both primary AND secondary muscles when applying injury/avoid preferences

### 29. "Spotify stops every 30 seconds while using the app"
✅ **SOLVED**: Complete audio session management for seamless music app integration:
- **Background Music Support**: App properly configures audio sessions to mix with other apps instead of interrupting them
- **Audio Ducking**: Temporarily lowers background music volume during voice announcements, then restores it
- **Platform-Specific Handling**:
  - iOS: AVAudioSessionCategory.playback with mixWithOthers and duckOthers options
  - Android: AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK for non-interruptive audio focus
- **User Preferences**: Full control in Settings > Audio Settings:
  - "Allow Background Music" toggle to keep Spotify/Apple Music playing
  - "Voice Announcement Volume" slider (0-100%)
  - "Audio Ducking" toggle to lower music during announcements
  - "Ducking Level" slider to control how much music is lowered
  - "Mute Voice During Videos" toggle for exercise demo videos
- **Proper Audio Focus Management**: Requests transient focus before TTS, abandons focus after completion
- **Backend Persistence**: User audio preferences synced to database with full API support
- **User Context Logging**: Tracks when users enable/disable background music for analytics

### 13. "Warmups are too long/short for my preference"
✅ **SOLVED**: Customizable warmup and stretch durations (1-15 minutes each). Users can set their preferred warmup length and post-workout stretch length in Settings > Training Preferences > Warmup Settings. The AI generates warmup routines tailored to the specified duration.

### 14. "Workouts don't adjust based on my feedback"
✅ **SOLVED**: Adaptive difficulty system learns from your exercise ratings (too easy / just right / too hard). The system tracks feedback patterns and automatically adjusts future workout difficulty. Consistent "too easy" ratings trigger progressive difficulty increases, while "too hard" feedback causes appropriate regression. Feedback importance is explained on the workout completion screen.

### 15. "Confusing UI - don't know what buttons do"
✅ **SOLVED**: Improved UI clarity throughout the app:
- Home screen edit mode includes tooltips explaining functionality
- Settings sections include descriptive headers explaining each category
- Workout completion screen explains the importance of exercise feedback
- Clearer navigation hints and contextual help throughout

### 14. "Exercise feedback doesn't seem to do anything"
✅ **SOLVED**: Exercise feedback now actively adjusts future workouts. The system uses a weighted algorithm considering recency, consistency, and feedback type to determine appropriate difficulty adjustments. Users receive visual confirmation that their feedback is being used.

### 16. "Can't adjust the amount of sets - stuck trying to complete 5 sets with nothing left"
✅ **SOLVED**: Complete set management system during active workouts:
- **Remove Sets**: Tap the minus button to reduce planned sets when fatigued
- **Skip Remaining Sets**: "I'm done with this exercise" option to end an exercise early
- **Edit Completed Sets**: Tap any completed set to modify reps or weight
- **Delete Sets**: Swipe to remove a logged set if entered incorrectly
- **Reason Tracking**: Optional reason selection (fatigue, time, pain, equipment) for analytics
- **Fatigue Detection**: AI monitors rep decline and RPE patterns, suggests reducing sets when appropriate
- **Visual Feedback**: Shows adjusted set count (e.g., "3/5 sets - reduced") with distinct styling
- **Smart Suggestions**: Based on performance decline, app proactively asks "Would you like to end this exercise early?"

This addresses the common frustration of being locked into a set count that doesn't match your energy level on a given day.

### 21. "Told me to do 50 crunches but I could only do 30 - no way to input actual reps"
✅ **SOLVED**: Complete rep accuracy tracking system:
- **Actual Rep Input**: Enter exactly how many reps you completed, not just accept the planned number
- **Target vs Actual Display**: UI shows "Target: 50" above input field, displays "Planned: 50 → Actual: 30" after completion
- **Accuracy Tracking**: Each set stores both planned and actual reps for accurate workout history
- **Visual Feedback**: Completed sets show accuracy percentage (e.g., "60%") with color coding (green=met target, orange=under target)
- **Quick Adjustment Buttons**: -5, -2 buttons for fast rep reduction from target
- **Modification Reasons**: Optional reason tracking (fatigue, pain, time) when reps differ from planned
- **AI Learning**: Rep accuracy data feeds into AI to automatically adjust future workout targets
- **Analytics View**: See your rep accuracy patterns per exercise over time
- **Database Tracking**: `set_rep_accuracy` table stores planned vs actual for every set

This addresses the frustration of workout logs showing incorrect data when you couldn't complete the planned reps.

### 17. "No way to trial the app first before subscribing"
✅ **SOLVED**: Multiple ways to experience the app before committing:
- **Demo Day (24-Hour Full Access)**: First-time users get 24 hours of FULL app access on first install - no account required, Demo Day banner shows remaining time
- **Extended Guest Preview (1 Hour)**: "Continue as Guest" provides 60-minute preview (was 10 minutes) with warning at 55 min, Demo Day users get unlimited sessions
- **See Your Personalized Plan BEFORE Paywall**: Complete fitness quiz to see YOUR actual workout plan with real exercises matched to your equipment/goals
- **Try This Workout**: Let users do one workout before signing up, shows 4-week program structure with weekly themes
- **Demo Workout Preview**: 4 sample workouts (Beginner Full Body, Quick HIIT, Upper Body Strength, Lower Body Power) with full exercise details - no account required
- **Expanded Exercise Library Preview**: 50+ exercises viewable in guest mode (was 20) with full filtering by muscle, equipment, difficulty
- **7-Day Free Trial**: Now available on ALL plans (was yearly-only), "Nothing due today" messaging, full access during trial
- **Demo Backend APIs**: `/api/v1/demo/generate-preview-plan` (personalized plan without auth), `/api/v1/demo/sample-workouts`, `/api/v1/demo/session/start`, `/api/v1/demo/interaction`
- **Interactive App Tour**: Animated step-by-step walkthrough of app features for new users, accessible anytime from Settings
- **Tour Tracking APIs**: `/api/v1/demo/tour/start`, `/api/v1/demo/tour/step-completed`, `/api/v1/demo/tour/completed`, `/api/v1/demo/tour/status/{id}`
- **Conversion Analytics**: `demo_sessions`, `demo_interactions`, `app_tour_sessions`, `app_tour_step_events` tables, `demo_conversion_funnel`, `app_tour_analytics` views for insights

### 33. "Need a demo or guide to understand how the app works"
✅ **SOLVED**: Comprehensive Interactive App Tour and Demo System:
- **App Tour Screen**: Animated step-by-step walkthrough covering all key features:
  - Welcome screen with app value proposition
  - AI Workout Generation explanation with "Try Demo" button
  - Chat with AI Coach feature showcase
  - Exercise Library preview (1700+ exercises)
  - Progress Tracking demonstration
  - Get Started call-to-action
- **Animated Feature Cards**: Each step has:
  - Large animated icon with gradient glow effect
  - Title, subtitle, and description
  - Feature bullet points with checkmarks
  - Optional deep link buttons to explore features
  - Demo workout button on relevant steps
- **Tour Navigation**:
  - Progress indicator showing current step
  - Back/Next navigation buttons
  - Skip button with confirmation dialog
  - "Get Started" final step with rocket icon
- **Settings Access**: Restart tour anytime from Settings > About & Support > App Tour & Demo
  - "Restart App Tour" - Re-show the full walkthrough
  - "Try Demo Workout" - Quick access to sample workouts
  - "Preview Sample Plan" - See 4-week plan structure
- **Tour Tracking**:
  - `app_tour_sessions` table tracks tour starts, completions, skips
  - `app_tour_step_events` table tracks individual step interactions
  - `app_tour_analytics` view for completion rates and drop-off analysis
  - User context logging for AI personalization
- **Sources Tracked**: new_user (first launch), settings (manual restart), deep_link (external)
- **Backend APIs**:
  - `POST /api/v1/demo/tour/start` - Start tour session
  - `POST /api/v1/demo/tour/step-completed` - Log step completion
  - `POST /api/v1/demo/tour/completed` - Mark tour finished
  - `GET /api/v1/demo/tour/status/{id}` - Check completion status
  - `GET /api/v1/demo/tour/analytics` - Get tour analytics

### 30. "After giving all personal information, it requires subscription to see the personal plan"
✅ **SOLVED**: Comprehensive "value before paywall" experience:
- **Full 4-Week Plan Preview Screen**: New dedicated screen (`/plan-preview`) shows your COMPLETE personalized workout plan BEFORE any paywall
  - Week-by-week view with all workout days visible
  - Each day shows workout type, exercises, sets, reps, and target muscles
  - Progressive difficulty milestones displayed ("Week 1: Foundation", "Week 4: Peak Performance")
  - Users can browse all 4 weeks freely before being asked to subscribe
- **"Your Plan is Ready!" Paywall Banner**: Paywall screen leads with "Your Personalized Plan is Ready!" and prominent "Preview Your Plan Free" button
- **Try One Workout Free**: Button on paywall lets users complete ONE full workout from their plan before subscribing
  - Generates a try-token with 1-hour expiry
  - Up to 2 try workouts per session
  - Full exercise details with instructions, warmup, and cooldown
  - Completion tracking with motivational messages
- **What You Get Free Section**: Clear checklist showing free features (plan preview, 1 workout, 1700+ exercises, weekly schedule)
- **More Visible "Continue Free" Button**: Larger, green-outlined button with "No card needed" badge - no hidden free option
- **Free Features First Philosophy**: Free tier always accessible, users see value before any payment request
- **Backend APIs**:
  - `GET /api/v1/demo/preview-workout/{day}` - Get specific day's workout without auth
  - `POST /api/v1/demo/try-workout` - Start a try workout with token
  - `POST /api/v1/demo/try-workout/complete` - Complete try workout and track conversion
  - `GET /api/v1/demo/exercises-previewed/{session_id}` - Track what was previewed
- **Trial on ALL Plans**: 7-day free trial now available on monthly AND yearly plans (was yearly-only)
  - `GET /api/v1/subscriptions/trial-eligibility/{user_id}` - Check trial availability
  - `POST /api/v1/subscriptions/start-trial/{user_id}` - Start trial without payment
- **Conversion Tracking**: Full funnel analytics with `plan_previews`, `try_workout_sessions`, and `conversion_triggers` tables
  - `trial_conversion_funnel` view for daily metrics
  - Attribution tracking for what convinced users to convert
  - User context logging for all trial interactions

### 31. "Have to go through the sign up process before they hit you with the subscription screen"
✅ **SOLVED**: Complete subscription transparency before account creation:
- **Pre-Signup Pricing Card**: Welcome screen shows pricing overview BEFORE any signup - "FREE FOREVER" badge, Free Plan ($0), Premium (from $4/month), 7-day trial prominently displayed
- **No Credit Card Required Badge**: Clear "No credit card needed" messaging on welcome screen
- **Demo Day Banner Widget**: Animated countdown banner with shimmer effects showing 24-hour full access remaining time
- **See Full Pricing Details Button**: Prominent button navigates to `/pricing-preview` before any account creation
- **Try Sample Workout Button**: Users can try a full workout before signing up
- **Continue as Guest Button**: 60-minute guest preview with feature chips explaining what's included
- **Free Tier Transparency**: Clear display of free tier limits (4 workouts/month, 50 exercises)
- **Subscription Transparency API**: Full event tracking for pricing views, trial starts, guest sessions
  - `POST /api/v1/subscription-transparency/event` - Log transparency events
  - `GET /api/v1/subscription-transparency/trial-status/{user_id}` - Get trial status with days remaining
  - `POST /api/v1/subscription-transparency/trial/start` - Start trial
  - `GET /api/v1/subscription-transparency/pricing-shown` - Verify pricing was shown before signup
  - `POST /api/v1/subscription-transparency/conversion-trigger` - Log what convinced user to convert
- **AI Context for Subscription Journey**: Subscription events logged for AI personalization
  - `POST /api/v1/subscription-context/{user_id}/pricing-viewed` - Log pricing view for AI
  - `POST /api/v1/subscription-context/{user_id}/trial-started` - Log trial start for AI
  - `POST /api/v1/subscription-context/{user_id}/free-plan-selected` - Log free plan selection for AI
  - `POST /api/v1/subscription-context/{user_id}/feature-limit-hit` - Log limit hits for AI
  - `GET /api/v1/subscription-context/{user_id}/context` - Get full subscription context for AI
- **Free Tier Provider**: Flutter provider tracking daily/monthly usage limits with automatic reset
- **Database Tables**: `subscription_transparency_events`, `user_trial_status`, `plan_previews`, `try_workout_sessions`, `conversion_triggers`
- **Analytics Views**: `trial_conversion_funnel`, `plan_preview_analytics`, `try_workout_analytics`, `conversion_trigger_effectiveness`

### 32. "Nowhere in the app store does it mention that the app is subscription only"
✅ **SOLVED**: Comprehensive App Store metadata guidance and transparency:
- **App Store Metadata Documentation**: Created APP_STORE_METADATA.md with:
  - Description templates clearly stating "FREE forever tier available"
  - Pricing disclosure sections for App Store and Play Store listings
  - Screenshot recommendations showing pricing before signup
  - IAP descriptions for all subscription tiers
  - Keyword suggestions including "free fitness app", "no subscription required"
- **Prominent Free Tier Messaging**: App store descriptions lead with "Start FREE - no subscription required"
- **Pricing in Screenshots**: Recommendation to include screenshot showing pricing transparency screen
- **Review Response Templates**: Suggested responses to pricing-related reviews
- **Compliance Checklists**: Verification steps for both App Store and Play Store requirements

### 18. "Strength journeys are too focused on high reps rather than progressions and leverage"
✅ **SOLVED**: Comprehensive leverage-based progression system that prioritizes exercise difficulty over rep increases:
- **Leverage Progressions**: 8 progression chains with 52+ variants (Push-up → Diamond → Archer → One-arm; Pull-up → Wide → Archer → One-arm; Squat → Bulgarian → Pistol)
- **Exercise Mastery Tracking**: System tracks consecutive "too easy" sessions per exercise
- **Automatic Suggestions**: After 2+ "too easy" ratings, app suggests harder variant instead of adding reps
- **Progression Cards**: Workout completion shows "Ready to Level Up?" cards with side-by-side difficulty comparison
- **Chain Types**: Supports leverage, load, stability, range-of-motion, and tempo progressions
- **Equipment-Aware**: Suggestions respect user's available equipment

### 19. "When exercise is too easy, app just adds reps which makes workouts boring"
✅ **SOLVED**: Smart progression philosophy embedded in AI generation:
- **Leverage-First Approach**: Gemini prompts explicitly instruct: "When exercise becomes easy, progress to HARDER VARIANT instead of adding more reps"
- **Rep Ceiling Enforcement**: AI instructed to never exceed user's preferred max reps
- **Mastery Context**: AI receives list of mastered exercises with suggested progressions
- **Example**: If user masters push-ups (15+ reps easily), next workout suggests Diamond Push-ups at lower rep range instead of 20 push-ups

### 20. "Takes too long to introduce pull-ups despite being able to do them"
✅ **SOLVED**: Exercise mastery fast-tracks progression:
- **Performance Detection**: If user completes 12+ reps on 70%+ of sets, exercise flagged as "ready for progression"
- **Manual Override**: Users can mark exercises as mastered to skip beginner variants
- **Prerequisite Skipping**: Users with demonstrated ability aren't forced through beginner progressions
- **Pull-up Chain**: Dead Hang → Scapular Pulls → Assisted → Negative → Full → Wide → L-Sit → Archer → One-arm (skip steps based on ability)

### 21. "Introduces high-rep muscle-ups without progression or starting with low rep range"
✅ **SOLVED**: Rep range preferences and progression validation:
- **Training Focus Settings**: Users choose Strength (4-6 reps), Hypertrophy (8-12), Endurance (12-15+), or Power (1-5)
- **Rep Range Slider**: Custom min/max rep preferences in Settings > Training Preferences
- **"Avoid Boring High-Rep Sets" Toggle**: When enabled, caps all exercises at 12 reps maximum
- **Progression Style**: Choose "Leverage First" (harder variants), "Load First" (more weight), or "Balanced"
- **Muscle-Up Mastery**: Proper 6-step progression: High Pullups → Explosive Pullups → Chest-to-Bar → Kipping → Slow → Strict

### 22. "Exercises and reps are repetitive and boring"
✅ **SOLVED**: Multi-layered variety enforcement:
- **Deduplication Logic**: 80%+ word overlap detection prevents similar exercises
- **7-14 Day Variety Tracking**: Avoids repeating exact exercises within window
- **Progression Variety**: When mastered, suggests lateral moves (Diamond Push-ups OR Decline Push-ups)
- **Training Focus Variation**: Gemini instructed to include variety and avoid same movement patterns
- **Chain Diversity**: 8 different progression chains covering all major movement patterns
- **Rep Range Variation**: Even within preferred range, varies rep targets (e.g., 8, 10, 12 across exercises)
- **Free Tier Access**: Users can skip paywall entirely and access core features free forever

### 18. "Info in store didn't say how much - had to download to get pricing"
✅ **SOLVED**: Complete pricing transparency before account creation:
- **Pre-Auth Pricing Preview**: "See Pricing" button on welcome screen shows all tiers and prices before sign-in:
  - Free: $0 (no credit card required)
  - Premium: $4.00/mo yearly ($47.99/yr) or $5.99/mo monthly
  - Premium Plus: $6.67/mo yearly ($79.99/yr) or $9.99/mo monthly
  - Lifetime: $99.99 one-time
- **App Store Pricing Info**: Info tooltip in paywall confirms prices match App Store/Play Store
- **7-day Trial Badge**: Prominent display of free trial availability on yearly plans
- **Cancel Anytime Note**: Clear messaging that cancellation is available via device settings

### 19. "Can't open or use the app without creating an account and subscribing"
✅ **SOLVED**: No account required for initial exploration:
- **Guest Preview Mode**: 10-minute preview session with limited features
- **Demo Workouts**: View sample workouts with full exercise details
- **Exercise Library Preview**: Browse 20 sample exercises before sign-up
- **Pricing Preview**: See all subscription options before creating account
- **Paywall Skip**: "Start with Free Plan" button allows full access without payment

### 20. "Had to give out email and can't find anywhere to unsubscribe"
✅ **SOLVED**: Complete email preference management in Settings:
- **Email Preferences Section**: Settings > Connections & Data > Email Preferences
- **5 Toggle Categories**:
  - Workout Reminders (daily reminders)
  - Weekly Summary (progress reports)
  - Coach Tips (AI motivation messages)
  - Product Updates (new features)
  - Promotional (offers/discounts - opt-in only by default)
- **Quick Unsubscribe**: "Unsubscribe from All Marketing" one-tap button
- **Confirmation Dialog**: Prevents accidental unsubscribe
- **Backend Support**: Full email_preferences table with RLS policies

### 23. "No option to annotate that a run was done on a treadmill"
✅ **SOLVED**: Complete cardio session logging with location tracking:
- **Location Options**: Indoor, Outdoor, Treadmill, Track, Trail, Pool, Gym
- **Cardio Types**: Running, Cycling, Swimming, Rowing, Elliptical, Walking, Hiking, Jump Rope
- **Session Details**: Duration, distance, pace, heart rate, calories burned
- **Weather Tracking**: For outdoor sessions, log conditions (sunny, cloudy, rainy, etc.)
- **Statistics**: Aggregate stats by cardio type and location with trend analysis
- **AI Integration**: User's cardio patterns inform workout recommendations

### 24. "Cardio days should have option to select indoor/outdoor and automatically adjust"
✅ **SOLVED**: Environment-aware cardio tracking:
- **Smart Location Selection**: Prominent location selector when logging cardio (Indoor vs Outdoor vs Treadmill)
- **Weather Context**: Outdoor sessions can include weather conditions for performance context
- **AI Adjustments**: User context service tracks outdoor vs indoor preferences to inform workout generation
- **Pattern Detection**: System identifies if user is outdoor enthusiast (>60% outdoor) or treadmill user (>40% treadmill)
- **Cardio-Strength Balance**: Tracks ratio and suggests balance adjustments

### 25. "Wish there were more CrossFit equipment like sandbags, medicine balls, slam balls, battle ropes"
✅ **SOLVED**: Comprehensive unconventional/CrossFit equipment support:
- **Battle Ropes**: Fully supported with 9+ dedicated exercises
- **Sandbags**: Fully supported with 20+ exercises (cleans, carries, squats, get-ups)
- **Medicine Balls**: In common equipment list with exercises
- **Slam Balls**: Added to equipment list with 2.0kg increments
- **Tires**: 14+ exercises including flips, jumps, sledgehammer slams
- **Hay Bales**: Farm equipment with 6+ exercises
- **100+ Equipment Types**: Searchable during onboarding including Indian/traditional equipment (gada, jori, nal)
- **Custom Equipment**: Users can add any equipment not in the list

### 31. "You can only choose a maximum of five days per week - terrible UX requiring repeated settings changes"
✅ **SOLVED**: Full 1-7 day flexibility with quick day change feature:
- **No 5-Day Limit**: App supports 1-7 workout days per week from onboarding through the entire experience
- **Quick Day Change in Settings**: Settings > Training > Workout Days allows instant day changes without regenerating workouts
- **Smart Workout Rescheduling**: When days change, existing workouts are intelligently moved to new days (Mon→Tue, Wed→Thu, Fri→Sat) without deletion
- **One-Tap Updates**: No 4-step wizard required - just tap days and save
- **Automatic Preference Sync**: Both `days_per_week` and `workout_days` array updated in user preferences
- **API Support**: `PATCH /api/v1/workouts/quick-day-change` endpoint handles day changes with smart rescheduling
- **Activity Logging**: Day changes tracked in `user_activity_log` and `workout_day_change_history` for analytics
- **No Workout Loss**: Unlike regeneration, quick day change preserves all workout content and just adjusts dates

This directly addresses the competitor complaint: changing days is now a 2-tap operation, not a repeated settings change nightmare.

### 33. "Need simpler one-tap start for workouts - don't want to think"
✅ **SOLVED**: Quick Start Today Widget
- **Quick Start Card**: Prominent card on home screen with large "START TODAY'S WORKOUT" button
- **Today's Summary**: Shows workout name, estimated duration, exercise count, and primary muscle focus at a glance
- **One-Tap Launch**: Single tap takes user directly into active workout - no navigation required
- **Rest Day Handling**: On rest days, card shows "Rest Day" with preview of next scheduled workout
- **Next Workout Preview**: When today is complete or rest day, shows upcoming workout details
- **Smart Status Detection**: Automatically detects if workout is pending, in progress, or completed
- Backend: `GET /api/v1/workouts/today` - Returns today's workout with summary metadata

### 34. "Can't see my progress over time - no charts"
✅ **SOLVED**: Visual Progress Charts Dashboard
- **Strength Progression Line Chart**: Track weight increases by muscle group over time
- **Weekly Volume Bar Chart**: Visualize total training volume (sets x reps x weight) per week
- **Summary Cards**: At-a-glance stats showing total workouts, personal records (PRs), and volume change percentage
- **Time Range Selector**: Toggle between 4 weeks, 8 weeks, 12 weeks, and all time views
- **Muscle Group Filter**: Filter charts by specific muscle groups (chest, back, legs, etc.)
- **Trend Indicators**: Color-coded arrows showing improvement or decline vs previous period
- **PR Celebrations**: Highlight new personal records with badges and animations
- Backend: `GET /api/v1/progress/strength-over-time`, `GET /api/v1/progress/volume-over-time`, `GET /api/v1/progress/summary`

### 35. "No way to track how I feel - just numbers"
✅ **SOLVED**: Subjective Results Tracking
- **Pre-Workout Check-In**: Quick mood, energy level, and sleep quality rating (5 seconds, skippable)
- **Post-Workout Feedback**: Rate mood, energy, confidence, and "feeling stronger" after workout
- **Feel Results Screen**: Dedicated view showing mood before vs after workout charts
- **Trend Insights**: AI-generated insights like "Your mood improved 23% since starting" and "Best workouts when sleep > 7 hours"
- **Energy Correlation**: Track how sleep and pre-workout energy correlate with performance
- **Confidence Tracking**: Monitor how workouts impact your fitness confidence over time
- **Weekly Mood Summary**: Email/notification with weekly emotional and energy trends
- Backend: `POST /api/v1/subjective-feedback/pre-workout`, `POST /api/v1/subjective-feedback/post-workout`, `GET /api/v1/subjective-feedback/trends`, `GET /api/v1/subjective-feedback/insights`

### 36. "Don't know my consistency patterns - when do I skip workouts?"
✅ **SOLVED**: Consistency Insights Dashboard
- **Current Streak**: Prominent display with fire animation showing consecutive workout days
- **Longest Streak Badge**: Achievement badge showing all-time best streak
- **Calendar Heatmap**: Visual calendar with green (completed), red (missed), and gray (rest) days
- **Best/Worst Day Analysis**: Data-driven insights like "Your best day: Monday 95%" and "Most missed: Friday 62%"
- **Monthly Statistics**: "12 of 16 scheduled workouts completed (75%)"
- **Time-of-Day Patterns**: Identify when you're most likely to complete workouts (morning vs evening)
- **Streak Recovery Encouragement**: Motivational messages when starting a new streak after a break
- **Completion Rate Trends**: Weekly/monthly completion percentage over time
- Backend: `GET /api/v1/consistency/streaks`, `GET /api/v1/consistency/calendar`, `GET /api/v1/consistency/patterns`, `GET /api/v1/consistency/stats`

**Stats Date Range Filter:**
- **Preset Time Ranges**: Quick filter buttons for 1 Week, 1 Month, 3 Months, 6 Months, 1 Year
- **Custom Date Range**: "Custom" button triggers Flutter's `showDateRangePicker` for precise date selection
- **Visual Date Display**: Selected range shown in format "Oct 13, 2025 - Jan 13, 2026"
- **Filter Applies to All Stats**: Activity heatmap and all stats data update to show selected date range
- **User Flow**: Tap calendar icon in stats screen → Select preset or custom → View filtered stats
- **Backend API**: `GET /api/v1/consistency/calendar?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` (or use `weeks` param for presets)
- **Database**: No new tables - uses existing consistency and workout data with date filtering
- **Migration**: No new migration needed - API enhancement only
- **Frontend**: `DateRangeFilterSheet` bottom sheet, `customStatsDateRangeProvider` for state management

**Stats Sharing to Social Feed:**
- **3 Shareable Templates**: Overview (activity heatmap + key stats), Achievements (badges + milestones), PRs (personal records summary)
- **Template Carousel**: Swipe between templates with page indicator dots
- **Watermark Toggle**: Optional FitWiz watermark can be enabled/disabled
- **4 Share Destinations**:
  1. **Instagram Stories** - Deep link to Instagram's story composer
  2. **System Share** - Share via any installed app (Messages, WhatsApp, etc.)
  3. **Post to Feed** - Share to app's social feed for friends to see and react
  4. **Save to Gallery** - Save image to device's photo library
- **Stats Gallery Backend**: Images stored with stats snapshot data for feed display
- **User Flow**: Tap share icon → Swipe through templates → Choose share destination
- **Backend API**:
  - `POST /api/v1/stats-gallery/upload` - Upload stats image with metadata
  - `GET /api/v1/stats-gallery/{user_id}` - List user's stats gallery images
  - `POST /api/v1/stats-gallery/{image_id}/share-to-feed` - Create activity feed entry
  - `PUT /api/v1/stats-gallery/{image_id}/track-external-share` - Track Instagram/system shares
  - `DELETE /api/v1/stats-gallery/{image_id}` - Soft delete stats image
- **Database**: `stats_gallery` table with RLS policies for user data isolation
- **Migration**: `153_stats_gallery.sql`
- **Frontend**: `ShareStatsSheet`, `StatsOverviewTemplate`, `StatsAchievementsTemplate`, `StatsPRsTemplate`, `StatsGalleryService`

**Stats Export (Multi-Format):**
- **3 Export Formats**: CSV/ZIP, PDF Report, and Text Summary
- **CSV/ZIP Export**: Full data export with all workouts, PRs, body measurements, achievements - reuses existing export dialog
- **PDF Report**: Styled PDF with FitWiz branding, summary stats (total workouts, streaks), weekly progress bar, PRs table, achievements list
- **Text Summary**: Quick shareable text format with key stats, perfect for copy-paste or messaging
- **Export Sheet UI**: Clean bottom sheet with 3 tappable option cards showing icon, title, and description
- **User Flow**: Tap export icon in stats screen → Select format → Export/share file
- **PDF Generation**: Uses `pdf` package (v3.11.1) for client-side PDF creation
- **Frontend**: `ExportStatsSheet`, `PdfExportService`

### 37. "Missed workouts disappear - no way to reschedule"
✅ **SOLVED**: Smart Rescheduling System
- **Missed Workout Banner**: Prominent banner on home screen when a workout was missed
- **Quick Actions**: "Do Today" to merge with today's workout or "Skip It" with reason tracking
- **Skip Reason Picker**: Options include "Too busy", "Feeling unwell", "Need rest", "Gym closed", "Other"
- **Reschedule to Future Date**: Calendar picker to move missed workout to any future date
- **Swap with Scheduled**: Option to swap missed workout with an upcoming scheduled workout
- **AI Rescheduling Suggestions**: Smart recommendations for optimal rescheduling based on your patterns
- **Missed Workout History**: Track all missed workouts and their eventual disposition
- **No Lost Workouts**: Missed workouts remain accessible for 14 days for rescheduling
- Backend: `GET /api/v1/scheduling/missed`, `POST /api/v1/scheduling/reschedule`, `POST /api/v1/scheduling/skip`, `POST /api/v1/scheduling/swap`, `GET /api/v1/scheduling/suggestions`

### 38. "Don't see the value of my consistency - no ROI"
✅ **SOLVED**: Progress Milestones and ROI Communication
- **30+ Achievement Badges**: Milestones across workout count, streaks, strength gains, volume, and time invested
- **Tier System**: Bronze (10), Silver (25), Gold (50), Platinum (100), Diamond (250) for each category
- **ROI Summary Card**: At-a-glance view of total workouts, hours invested, estimated calories burned
- **Strength Improvement Stats**: "You're 15% stronger since you started!" with muscle-by-muscle breakdown
- **Full-Screen Milestone Celebrations**: Confetti animation and achievement unlocked screen for major milestones
- **Social Sharing**: Share achievements to social media with custom branded graphics
- **Progress Timeline**: Visual journey showing all milestones unlocked with dates
- **Projected Goals**: "At your current pace, you'll hit Gold in 3 weeks"
- **Weekly/Monthly Summaries**: Email digests highlighting ROI and progress milestones
- Backend: `GET /api/v1/progress/milestones`, `GET /api/v1/progress/milestones/next`, `POST /api/v1/progress/milestones/{id}/share`, `GET /api/v1/progress/roi`, `GET /api/v1/progress/roi/breakdown`

### 39. "Really amazing app, just as easy to use - comparing to competitors"
✅ **ENHANCED**: Based on positive competitor reviews highlighting ease-of-use and fuss-free experience, we've implemented:

**Quick Start / Today's Workout Feature:**
- **One-Tap Quick Start**: Prominent "Today's Workout" card on home screen showing current workout status
- **Smart Status Detection**: Automatically shows if today is a workout day, rest day, or needs generation
- **Instant Access**: Single tap to start today's workout without navigation
- **Next Workout Preview**: When it's a rest day, shows what's coming up and days until next workout
- **Contextual Messages**: Friendly rest day messages like "Rest day today. Your next workout is tomorrow!"
- **Backend API**: `GET /api/v1/workouts/today` returns workout summary with status (ready/rest_day/needs_generation)
- **Analytics Tracking**: `POST /api/v1/workouts/today/start` logs quick start usage for engagement insights

**Quick Workout (5-15 Minutes):**
- **Time-Constrained Workouts**: For busy users who want effective 5, 10, or 15-minute sessions
- **Focus Selection**: Choose cardio, strength, stretch, or full_body focus
- **AI-Optimized**: Gemini generates efficient workouts that fit exactly within time constraints
- **Preference Learning**: System remembers user's preferred duration and focus for faster subsequent requests
- **Backend API**: `POST /api/v1/workouts/quick` generates tailored quick workouts
- **Database Table**: `quick_workout_preferences` tracks usage patterns for personalization
- **Migration**: `101_quick_workouts.sql` with RLS security and analytics views

**Quick Workout via AI Coach Chat:**
- **Natural Language Requests**: Ask the AI Coach "give me a quick 15-minute workout" and get an actual generated workout
- **Intelligent Intent Detection**: System recognizes workout creation requests like:
  - "create a quick workout"
  - "give me a 10-minute cardio workout"
  - "make me a short upper body workout"
  - "I need a quick workout"
  - "new workout please"
- **Go to Workout Button**: After generating, chat shows a prominent "Go to Workout" button to start immediately
- **Full Workout Generation**: Uses Exercise RAG to select appropriate exercises based on:
  - User's equipment availability
  - Fitness level (with safety caps for intensity)
  - Goals and preferences
  - Injury avoidance
  - Historical performance data
- **Adaptive Parameters**: Sets, reps, and rest times calculated using AdaptiveWorkoutService
- **Workout Types Supported**: full_body, upper, lower, cardio, core, boxing, hyrox, crossfit, hiit, strength, chest, back, shoulders, arms, legs
- **Intensity Options**: light, moderate, intense (capped at user's actual fitness level for safety)
- **Backend Implementation**:
  - `GENERATE_QUICK_WORKOUT` intent in CoachIntent enum
  - Intent extraction prompt updated to detect workout creation requests
  - LangGraph routing directs to WorkoutAgent (not CoachAgent)
  - `generate_quick_workout` tool creates real workouts in database
  - action_data returned with workout_id for "Go to Workout" button
- **User Context Logging**: All chat workout requests tracked via:
  - `QUICK_WORKOUT_CHAT_REQUEST` - when user asks for a workout
  - `QUICK_WORKOUT_CHAT_GENERATED` - when workout is successfully created
  - `QUICK_WORKOUT_CHAT_FAILED` - when generation fails (for debugging)
  - Analytics methods for usage patterns by workout type and duration
- **Analytics View**: `quick_workout_source_analytics` shows button vs chat usage patterns
- **Files**:
  - Backend: `models/chat.py`, `services/gemini_service.py`, `services/langgraph_service.py`
  - Tools: `services/langgraph_agents/tools/workout_tools.py` (generate_quick_workout)
  - Flutter: `chat_repository.dart`, `chat_screen.dart`, `chat_message.dart`

**User-Friendly Difficulty Labels:**
- **Welcoming Names**: Changed internal difficulty display from (easy/medium/hard/hell) to (Beginner/Moderate/Challenging/Elite)
- **Descriptions**: Hover/long-press shows helpful descriptions:
  - Beginner: "Perfect for starting out or recovery days"
  - Moderate: "A balanced workout for consistent progress"
  - Challenging: "Push your limits and build serious strength"
  - Elite: "Maximum intensity for experienced athletes"
- **Backward Compatible**: Internal values unchanged for database/API compatibility
- **Utility Class**: `DifficultyUtils` provides `getDisplayName()`, `getDescription()`, `getColor()`, `getIcon()`

**Fuss-Free Experience Principles:**
- **No Ads**: Zero advertisements in the app - subscription-supported model
- **No Clutter**: Clean Material 3 design with 8px grid spacing
- **Minimal Steps**: Maximum 2 taps to start any workout
- **Smart Defaults**: Preferences remembered and applied automatically
- **Progressive Disclosure**: Advanced options available but not overwhelming

### 40. "I love the app and would love it if it supports split screens so I could also play music apps"
✅ **SOLVED**: Complete split-screen/multi-window support for seamless multitasking:

**Android Split Screen Support:**
- **Resizable Activity**: `android:resizeableActivity="true"` enables multi-window mode
- **Picture-in-Picture**: `android:supportsPictureInPicture="true"` for floating window mode
- **Freeform Window Support**: Works with Samsung DeX, desktop modes, and freeform launchers
- **Configuration Change Handling**: Proper handling of `screenSize|smallestScreenSize|screenLayout` changes

**iOS Multi-Scene Support:**
- **Split View on iPad**: `UISupportsMultipleScenes = true` enables iPad Split View
- **Slide Over**: App works in Slide Over mode alongside other apps
- **Stage Manager**: Compatible with iPadOS Stage Manager for multi-window workflows
- **Full Screen Not Required**: `UIRequiresFullScreen = false` allows flexible windowing

**Music App Integration:**
- **Background Audio**: Proper audio session configuration allows Spotify, Apple Music, YouTube Music to play
- **Audio Ducking**: Voice announcements briefly lower music volume, then restore
- **No Audio Interruption**: App doesn't steal audio focus from other apps
- **Settings**: Audio > "Allow Background Music" toggle for explicit control

**Split Screen Usage Analytics:**
- **Event Logging**: `split_screen_entered` and `split_screen_exited` events tracked
- **Duration Tracking**: Time spent in split screen mode recorded
- **Feature Usage**: Which features used during split screen (workout, chat, videos)
- **Device Context**: Screen dimensions, split ratio, device type logged
- **User Patterns**: Analytics views show split screen adoption and behavior patterns

**Technical Implementation:**
- **WindowModeProvider**: Riverpod provider that detects window size changes and provides `isInSplitScreen`, `isCompactMode`, `windowWidth`, `windowHeight`
- **ResponsiveLayout Widget**: Auto-selects between compact, medium, expanded layouts based on window width
- **Breakpoints**: Compact (<600dp), Medium (600-840dp), Expanded (>840dp)
- **ResponsiveMixin**: Mixin for ConsumerStatefulWidget with responsive helpers
- **Context Logging**: All split screen events logged to `window_mode_logs` table with full context
- **Backend API**: `POST /api/v1/window-mode/{user_id}/log`, `GET /api/v1/window-mode/{user_id}/stats`
- **Analytics Views**: `window_mode_analytics` for aggregated statistics

**Responsive UI Adjustments:**
- **Home Screen**: Half-width tiles render as full-width in narrow layouts, reduced padding, smaller fonts
- **Active Workout**: Compact mode stacks controls vertically, hides non-essential UI, adjusts button sizes
- **All Screens**: Use `ResponsiveContainer` for adaptive padding, `ResponsiveGrid` for column adjustment

**Files:**
- Android: `android/app/src/main/AndroidManifest.xml` (resizeableActivity, supportsPictureInPicture)
- iOS: `ios/Runner/Info.plist` (UIRequiresFullScreen, UISupportsMultipleScenes)
- Flutter Provider: `lib/core/providers/window_mode_provider.dart`
- Flutter Widget: `lib/widgets/responsive_layout.dart`
- Backend API: `api/v1/window_mode.py`
- Migration: `migrations/104_window_mode_logs.sql`
- Tests: `tests/test_window_mode.py`

### 41. "I really like the Ultimate Strength program" - Branded Workout Programs
✅ **IMPLEMENTED**: Named, branded workout programs that users can follow and personalize:

**Ultimate Strength Builder Program:**
The definitive 12-week strength building program combining powerlifting fundamentals, progressive overload, and periodization:
- **4 Distinct Phases**: Foundation (weeks 1-3, 70-75% intensity), Volume (weeks 4-6, 75-80%), Intensity (weeks 7-9, 80-87%), Peak (weeks 10-12, 87-95%)
- **4-Day Weekly Structure**:
  - Day 1 - Squat Focus: Barbell Back Squat, Pause Squat, Leg Press, Romanian Deadlift, Plank
  - Day 2 - Bench Focus: Barbell Bench Press, Close-Grip Bench, Incline DB Press, Dips, Tricep Pushdown
  - Day 3 - Deadlift Focus: Conventional Deadlift, Deficit Deadlift, Barbell Row, Pull-ups, Barbell Curl
  - Day 4 - Accessories: Overhead Press, Push Press, Farmer Walks, Face Pulls, Hanging Leg Raise, Ab Wheel
- **Variants Available**: Easy (3 days/week, Beginner), Hard (5 days/week, Advanced), 4-week, 8-week, 12-week
- **Files**: Migration `103_ultimate_strength_program.sql`, Definition in `program_definitions.py`

**12+ Pre-Built Branded Programs:**
| Program | Focus | Duration | Level | Description |
|---------|-------|----------|-------|-------------|
| **Ultimate Strength Builder** | Strength | 12 weeks | Intermediate | 4-phase periodized strength mastery with the big 3 lifts |
| **Lean Machine** | Fat Loss | 8 weeks | Intermediate | Burn fat while maintaining muscle |
| **Power Builder** | Powerbuilding | 8 weeks | Advanced | Hybrid strength + hypertrophy |
| **Beach Body Ready** | Aesthetic | 12 weeks | Intermediate | Sculpt a balanced, defined physique |
| **Functional Athlete** | Athletic | 8 weeks | Intermediate | Sports performance and agility |
| **Beginner's Journey** | General | 4 weeks | Beginner | Safe introduction to strength training |
| **Home Warrior** | Bodyweight | 8 weeks | All Levels | No gym required |
| **Iron Will** | Muscle Building | 16 weeks | Advanced | Maximum hypertrophy |
| **Quick Fit** | Time-Efficient | 4 weeks | All Levels | 30-minute effective workouts |
| **Endurance Engine** | Cardio + Strength | 8 weeks | Intermediate | Build lasting stamina |
| **Core Crusher** | Core | 6 weeks | Intermediate | Strong, stable midsection |
| **Strength Foundations** | Barbell Basics | 8 weeks | Beginner | Master fundamental lifts |

**Custom Program Naming:**
- **Personal Names**: Rename any program (e.g., "My Summer Shred 2025")
- **Custom Programs**: Create your own named program without selecting a template
- **Program History**: Track all programs you've completed with dates

**Program Selection UI:**
- **Browse Programs**: Dedicated `/programs` screen with grid layout
- **Featured Section**: Highlighted programs at the top
- **Category Filters**: Filter by strength, hypertrophy, fat loss, athletic, etc.
- **Difficulty Filter**: Beginner, Intermediate, Advanced, All Levels
- **Program Details Sheet**: Full description, goals, duration, sessions per week
- **Start Program**: One-tap to begin with optional custom name

**Progress Tracking:**
- **Current Week Display**: "Week 3 of 12" shown on home screen
- **Workouts Completed**: X/Y workouts completed in program
- **Progress Percentage**: Visual progress bar
- **Program Completion**: Celebrate completing full programs

**Backend API Endpoints:**
- `GET /api/v1/programs/branded` - List all branded programs with filters
- `GET /api/v1/programs/featured` - Featured, popular, and new releases
- `GET /api/v1/programs/branded/{id}` - Single program details
- `POST /api/v1/programs/assign/{user_id}` - Start a program
- `GET /api/v1/programs/user/{user_id}/current` - Current active program
- `PATCH /api/v1/programs/user/{user_id}/rename` - Rename program
- `PATCH /api/v1/programs/user/{user_id}/complete` - Mark completed
- `GET /api/v1/programs/user/{user_id}/history` - Program history

**Database Tables:**
- `branded_programs` - Program definitions with name, category, difficulty, goals, theming
- `user_program_assignments` - User-program relationships with progress tracking

**Home Screen Integration:**
- Current program name displayed prominently
- "Browse Programs" option in program menu
- Week number and progress shown

**Files:**
- Migration: `migrations/101_branded_programs.sql`
- Backend API: `api/v1/programs.py`
- Flutter Model: `lib/data/models/branded_program.dart`
- Repository: `lib/data/repositories/branded_program_repository.dart`
- Provider: `lib/data/providers/branded_program_provider.dart`
- UI: `lib/screens/programs/program_selection_screen.dart`
- Details: `lib/screens/programs/widgets/program_details_sheet.dart`
- Tests: `tests/test_branded_programs.py`

### 42. "I've been a lifetime member" - Lifetime Membership Recognition
✅ **IMPLEMENTED**: Comprehensive lifetime member recognition and benefits system:

**Lifetime Member Tier System:**
| Tier | Days as Member | Badge | Description |
|------|----------------|-------|-------------|
| **Veteran** | 365+ days | 🏆 Gold | Highly loyal, long-term dedication |
| **Loyal** | 180-364 days | 🥈 Silver | Consistent commitment |
| **Established** | 90-179 days | 🥉 Bronze | Building solid foundation |
| **New** | 0-89 days | 💎 Cyan | Recently joined |

**Lifetime Member Benefits:**
- **Never Expires**: Database triggers prevent lifetime subscriptions from expiring (`current_period_end = NULL`)
- **No Renewal Reminders**: Billing notifications automatically skipped for lifetime members
- **All Features Unlocked**: Full Premium Plus feature access for life
- **Progress to Next Tier**: Shows days remaining until next tier level
- **Estimated Value Display**: Shows value received based on months of membership (e.g., "$150 value after 15 months")
- **Value Multiplier**: 1.5x lifetime purchase price after first year

**Lifetime Member Badge Widget:**
- **Compact Mode**: Small badge with tier icon and "Lifetime" label for settings/profile
- **Expanded Mode**: Full card with tier, duration, estimated value, and progress to next tier
- **LifetimeMemberChip**: Inline badge for usernames/lists

**AI Personalization:**
AI receives lifetime membership context for personalized responses:
- "This user is a Veteran lifetime member (426 days). Treat them as a highly valued long-term customer."
- AI acknowledges their commitment and loyalty in responses

**Backend API Endpoints:**
- `GET /api/v1/subscriptions/{user_id}/lifetime-status` - Full lifetime status with tier and benefits
- `GET /api/v1/subscriptions/{user_id}/lifetime-benefits` - Detailed benefits and perks
- `POST /api/v1/subscriptions/{user_id}/convert-to-lifetime` - Convert to lifetime membership

**Database Implementation:**
- Columns: `is_lifetime`, `lifetime_purchase_date`, `lifetime_original_price`, `lifetime_member_tier`
- View: `lifetime_member_benefits` with calculated tier and value
- Functions: `is_lifetime_member()`, `get_lifetime_member_tier()`, `get_lifetime_member_context()`
- Triggers: Prevent expiration, auto-set lifetime fields on RevenueCat webhook

**Files:**
- Migration: `migrations/102_lifetime_membership_tracking.sql`
- Backend: `api/v1/subscriptions.py` (lifetime endpoints)
- User Context: `services/user_context_service.py` (AI context)
- Flutter Provider: `core/providers/subscription_provider.dart`
- Badge Widget: `screens/settings/widgets/lifetime_member_badge.dart`
- Tests: `tests/test_lifetime_membership.py`

### 43. "Need to manage my subscription without going to app store" - Subscription Management UI
✅ **IMPLEMENTED**: Complete in-app subscription management with pause, resume, and retention:

**Subscription Management Screen:**
- Current subscription status, tier, and billing information
- Next billing date and amount (or "Never expires" for lifetime)
- Pause, resume, and cancel actions based on subscription state
- Quick links to App Store/Play Store subscription settings
- Lifetime members see special "Lifetime Member" status card

**Pause Subscription:**
- **Duration Options**: 1 week, 2 weeks, 1 month, 2 months, 3 months
- **Resume Date Preview**: Shows exactly when subscription will resume
- **Feature Explanation**: Clear info about what happens during pause
- **Auto-Resume**: System automatically resumes on scheduled date

**Cancel Confirmation Flow:**
Two-step cancellation with retention:
1. **Step 1 - Reason Selection**: Why are you canceling? (too_expensive, not_using, missing_features, found_alternative, other)
2. **Step 2 - Retention Offers**: Personalized offers based on reason:
   - **50% Discount for 3 Months**: For price-sensitive users
   - **Free Month**: For users who need more time
   - **Pause Option**: For temporarily busy users
   - **Downgrade**: For users who don't need all features

**Backend API Endpoints:**
- `POST /api/v1/subscriptions/{user_id}/pause` - Pause subscription with duration
- `POST /api/v1/subscriptions/{user_id}/resume` - Resume paused subscription
- `GET /api/v1/subscriptions/{user_id}/retention-offers` - Get personalized offers
- `POST /api/v1/subscriptions/{user_id}/accept-offer` - Accept a retention offer

**Database Implementation:**
- `subscription_pauses` table: Track pause events with resume dates
- `retention_offers_accepted` table: Track which offers users accept
- `subscription_discounts` table: Pending discounts for billing
- `cancellation_feedback` table: Analytics for cancellation reasons

**Files:**
- Migration: `migrations/106_subscription_management.sql`
- Backend: `api/v1/subscriptions.py` (pause/resume/retention endpoints)
- Subscription Screen: `screens/settings/subscription/subscription_management_screen.dart`
- Cancel Sheet: `screens/settings/subscription/cancel_confirmation_sheet.dart`
- Pause Sheet: `screens/settings/subscription/pause_subscription_sheet.dart`
- Settings Section: `screens/settings/sections/subscription_section.dart`
- Tests: `tests/test_subscription_management.py`

### 44. "Only doing 500 steps a day - need help increasing daily activity" - NEAT Improvement System
✅ **IMPLEMENTED**: Comprehensive NEAT (Non-Exercise Activity Thermogenesis) improvement system to help sedentary users increase daily activity:

**The Problem:**
Many users only walk ~500 steps per day, which is extremely sedentary. Research shows that NEAT (all daily activity outside formal exercise) can add 300-500+ extra calories burned per day. The 10,000 steps goal is overwhelming for sedentary users and leads to disengagement.

**Our Solution - Progressive & Gamified:**

**1. Progressive Step Goals (Not One-Size-Fits-All)**
- **Personalized Starting Point**: New users start at their 7-day baseline average + 500 steps (not arbitrary 10,000)
- **Weekly Progression**: Goals automatically increase by 500-1000 steps/week when consistently achieved (80%+ achievement rate)
- **Smart Adjustments**: If struggling, system keeps goal stable or reduces slightly (never demotivates)
- **Goal Types**: Steps, active hours, and overall NEAT score tracking
- **Maximum Cap**: Goals capped at 15,000 steps to prevent overtraining

**2. Hourly Movement Reminders (Research-Backed)**
Based on Fitbit research showing 250 steps/hour threshold:
- **Sedentary Detection**: Hours with <250 steps flagged as sedentary
- **Smart Reminders**: Notification if sedentary for 1+ hours during allowed times
- **Quiet Hours**: Configurable (default 10PM-7AM) - no reminders during sleep
- **Work Hours Option**: Only remind during work hours (9AM-5PM)
- **Varied Messages**: 8+ different reminder templates to avoid notification fatigue:
  - "Time to move! 🚶 You've only taken {steps} steps this hour."
  - "Stand up and stretch! Your body will thank you."
  - "Quick walk? Just 2 minutes can boost your energy!"

**3. NEAT Score (0-100)**
Daily score calculated from multiple factors:
- Steps vs goal (0-40 points)
- Active hours (0-35 points)
- Consistency/distribution (0-25 points with sedentary penalties)
- **Rating Levels**: Excellent (90+), Good (75-89), Fair (50-74), Needs Improvement (<50)
- **Trend Tracking**: Shows improving/stable/declining over time

**4. Comprehensive Streak System**
Four independent streak types:
- **Step Goal Streak**: Consecutive days meeting step goal
- **Active Hours Streak**: Consecutive days with 8+ active hours
- **NEAT Score Streak**: Consecutive days with score >= 70
- **Movement Breaks Streak**: Consecutive days avoiding 2+ hour sedentary periods
- **Milestone Celebrations**: Badges at 7, 14, 30, 60, 100 day milestones

**5. Gamification & Achievements (35+ Badges)**
Tiered achievement system:
| Tier | Examples |
|------|----------|
| **Bronze** | First 5K Steps, 3-Day Streak, 8 Active Hours |
| **Silver** | 10K Steps, 7-Day Streak, Active Week, First 75 NEAT |
| **Gold** | 15K Steps, Monthly Master, Active Month, Perfect NEAT |
| **Platinum** | 20K Steps, 60-Day Streak, Consistency Champion |
| **Diamond** | 25K Steps, Century Walker (100-day streak), Step Olympian |

**6. NEAT Dashboard UI**
Dedicated screen showing:
- Large NEAT score display with color coding
- Step progress with animated circular indicator
- 24-hour activity timeline (bar chart, sedentary hours in red)
- Active hours card with visual grid
- Streak badges with fire animations
- Recent and available achievements
- Movement reminder settings
- AI-personalized tips based on patterns

**7. Home Screen Integration**
- **NEAT Activity Card**: Shows steps, NEAT score, active hours, and streak at a glance
- **Tap to Expand**: Opens full NEAT dashboard
- **Progress Animation**: Steps count up animation on load
- **Goal Achieved Badge**: Green checkmark when daily goal met

**8. AI Coach Integration**
NEAT context provided to Gemini for personalized advice:
- Current goal and progress percentage
- 7-day trend (improving/stable/declining)
- Sedentary patterns (e.g., "Most sedentary 2-4pm on weekdays")
- Achievement progress
- Personalized recommendations

**Backend API Endpoints:**
```
GET  /api/v1/neat/goals/{user_id}                    - Get current goals
PUT  /api/v1/neat/goals/{user_id}                    - Update step goal
POST /api/v1/neat/goals/{user_id}/calculate-progressive - Calculate progressive goal
POST /api/v1/neat/hourly/{user_id}                   - Record hourly activity
GET  /api/v1/neat/hourly/{user_id}/{date}            - Get hourly breakdown
GET  /api/v1/neat/score/{user_id}/today              - Get today's score
GET  /api/v1/neat/score/{user_id}/history            - Get score history
GET  /api/v1/neat/streaks/{user_id}                  - Get all streaks
GET  /api/v1/neat/achievements/{user_id}             - Get earned achievements
GET  /api/v1/neat/achievements/{user_id}/available   - Get available with progress
GET  /api/v1/neat/reminders/{user_id}/preferences    - Get reminder settings
PUT  /api/v1/neat/reminders/{user_id}/preferences    - Update reminder settings
GET  /api/v1/neat/dashboard/{user_id}                - Combined dashboard data
POST /api/v1/neat/scheduler/send-movement-reminders  - Hourly cron for reminders
POST /api/v1/neat/scheduler/calculate-daily-scores   - End-of-day score calculation
POST /api/v1/neat/scheduler/adjust-weekly-goals      - Weekly goal adjustment
```

**Database Tables:**
- `neat_goals` - User step goals with progressive targeting
- `neat_hourly_activity` - Steps per hour for sedentary detection
- `neat_daily_scores` - Daily NEAT score aggregation
- `neat_streaks` - Consecutive day tracking (4 types)
- `neat_achievements` - 35 pre-seeded achievement definitions
- `user_neat_achievements` - Earned achievements junction table
- `neat_reminder_preferences` - Movement reminder settings
- `neat_weekly_summaries` - Weekly trend aggregation

**Files:**
- Migration: `backend/migrations/107_neat_improvement_system.sql`
- Backend Service: `backend/services/neat_service.py`
- Backend API: `backend/api/v1/neat.py`
- Backend Models: `backend/models/neat.py`
- Backend Tests: `backend/tests/test_neat_system.py`
- Flutter Models: `lib/data/models/neat.dart`, `neat_goal.dart`, `neat_score.dart`, etc.
- Flutter Repository: `lib/data/repositories/neat_repository.dart`
- Flutter Provider: `lib/data/providers/neat_provider.dart`
- Flutter Dashboard: `lib/screens/neat/neat_dashboard_screen.dart`
- Flutter Widgets: `lib/screens/neat/widgets/` (step_goal_card, hourly_chart, streak_badges, etc.)
- Home Card: `lib/screens/home/widgets/cards/neat_activity_card.dart`
- Notification Service: Updated `notification_service.dart` and `neat_reminder_service.dart`

**Research Sources:**
- Fitbit internal research: 70% of sedentary users moved more within 2 weeks of enabling reminders
- 250 steps/hour threshold based on evidence that 2-min walking per hour lowers mortality risk
- Gamification increases daily steps by ~1,850 on average (JMIR mHealth study)
- Progressive goal setting prevents disengagement from unrealistic targets

### 45. "Library always nothing, populate it properly"
✅ **FIXED**: Complete Library with 1,722 exercises and 12 branded programs:

**Root Cause Identified & Fixed:**
- **Programs Tab Bug**: Was querying non-existent `programs` table - now correctly queries `branded_programs` with 12 seeded workout programs
- **Silent Error Handling**: Netflix carousel was swallowing errors silently, showing empty state without retry button - now properly throws errors so users can retry
- **Dead Code Removed**: Cleaned up unused `library.py` backend file that caused confusion

**What Users Now See:**
- **1,722 Exercises**: Full database with HD videos, categorized by body part, equipment, goals
- **12 Branded Programs**: Ultimate Strength, Lean Machine, Power Builder, Beach Body Ready, Functional Athlete, Beginner's Journey, Home Warrior, Iron Will, Quick Fit, Endurance Engine, Core Crusher, Strength Foundations
- **Netflix-Style Browsing**: Horizontal carousels by body part (Chest, Back, Shoulders, Arms, Legs, Core)
- **Advanced Filtering**: Body parts, equipment, exercise types, goals, suitability, conditions to avoid
- **Clear Error States**: Network errors, timeouts, and API errors show specific messages with retry buttons

**AI Learning from Library Usage:**
- Exercise views logged for preference learning
- Program views logged for recommendation improvement
- Search queries logged (debounced) to understand user intent
- Filter usage logged to understand equipment/muscle preferences

**Backend Improvements:**
- Comprehensive test suite: `backend/tests/test_library.py`
- Differentiated error handling: Network, timeout, API, and parse errors
- User context logging: `POST /api/v1/library/log/exercise-view`, `POST /api/v1/library/log/program-view`, etc.

### 46. "How does AI know my actual strength level vs what I said in onboarding?" - Calibration/Test Workout System
✅ **IMPLEMENTED**: Complete strength calibration workout system to validate user-reported fitness levels:

**The Problem:**
Users often misjudge their fitness level during onboarding. Someone might select "intermediate" but actually be advanced, or vice versa. Without real data, the AI generates workouts that are either too easy or too hard, leading to frustration and poor workout personalization.

**Our Solution - Post-Subscription Calibration:**

**1. Calibration Workout (Optional, ~15-20 minutes)**
- **Triggered After Subscription**: Users see calibration intro after paywall purchase (can skip)
- **Quick Assessment**: 3-5 basic exercises testing major movement patterns
- **Exercise Types**:
  - Upper Push: Push-ups or Bench Press (based on equipment)
  - Upper Pull: Pull-ups or Dumbbell Rows
  - Lower Body: Squats or Bodyweight Squats
  - Shoulders: Shoulder Press (if equipment available)
  - Core: Plank (timed)
- **Max Rep Tests**: Users perform each exercise to their max ability

**2. AI Analysis with Gemini**
After completing calibration:
- **Performance Analysis**: AI reviews reps completed, weights used, and perceived difficulty
- **Strength Level Assessment**: Determines actual strength level (beginner/intermediate/advanced)
- **Comparison**: Compares actual performance vs self-reported fitness level
- **Recommendations**: Provides personalized recommendations for training

**3. Suggested Adjustments**
If calibration reveals a mismatch:
- **Fitness Level Adjustment**: "Based on your performance, we recommend changing your fitness level from 'beginner' to 'intermediate'"
- **Accept/Decline**: Users can accept the suggestion or keep original settings
- **Confidence Score**: Shows how confident the AI is in its assessment

**4. Strength Baselines**
From calibration results, the system calculates:
- **Estimated 1RM**: Uses Brzycki formula (1RM = weight × 36 / (37 - reps))
- **Working Weight Suggestions**: Baseline weights for future workouts
- **Muscle Group Baselines**: Strength levels per muscle group

**5. Recalibration**
- **30-Day Cool Down**: Can recalibrate after 30 days
- **Settings Access**: Available in Settings > Workout & Training > Calibration
- **Track Progress**: See how strength baselines change over time

**User Flow:**
```
Onboarding → Paywall → Calibration Intro → Start/Skip
                              ↓ (if start)
                       Calibration Workout
                              ↓
                       Complete Workout (log performance)
                              ↓
                       AI Analysis & Results
                              ↓
                   Accept/Decline Adjustments
                              ↓
                            Home
```

**Backend API Endpoints:**
- `GET /api/v1/calibration/status/{user_id}` - Check calibration status (pending/completed/skipped)
- `POST /api/v1/calibration/generate/{user_id}` - Generate calibration workout
- `POST /api/v1/calibration/start/{calibration_id}` - Start calibration workout
- `POST /api/v1/calibration/complete/{calibration_id}` - Complete with exercise results
- `POST /api/v1/calibration/accept-adjustments/{calibration_id}` - Accept suggested changes
- `POST /api/v1/calibration/decline-adjustments/{calibration_id}` - Decline changes
- `POST /api/v1/calibration/skip/{user_id}` - Skip calibration
- `GET /api/v1/calibration/results/{calibration_id}` - Get calibration results
- `GET /api/v1/calibration/baselines/{user_id}` - Get strength baselines

**Database Schema (migration: 107_calibration_workouts.sql):**
| Table | Purpose |
|-------|---------|
| `calibration_workouts` | Stores calibration workout sessions with exercises, status, results, AI analysis |
| `strength_baselines` | Per-exercise/muscle-group strength baselines with estimated 1RM |

**User Table Additions:**
- `calibration_completed` (boolean): Whether user completed calibration
- `calibration_skipped` (boolean): Whether user skipped calibration
- `calibration_workout_id` (uuid): Reference to latest calibration
- `original_fitness_level` (text): Level before calibration
- `fitness_level_adjusted_by_calibration` (boolean): Whether calibration changed level
- `last_calibration_date` (timestamp): When last calibrated

**Flutter Implementation:**
| File | Purpose |
|------|---------|
| `lib/screens/calibration/calibration_intro_screen.dart` | Explains calibration with "Start" and "Skip" options |
| `lib/screens/calibration/calibration_workout_screen.dart` | Active workout with exercise cards, difficulty rating |
| `lib/screens/calibration/calibration_results_screen.dart` | Shows AI analysis and suggested adjustments |
| `lib/screens/settings/sections/calibration_section.dart` | Settings section for recalibration |
| `lib/data/providers/calibration_provider.dart` | State management for calibration workflow |
| `lib/data/repositories/calibration_repository.dart` | API calls for calibration endpoints |
| `lib/data/models/calibration.dart` | Flutter models for calibration data |

**Backend Implementation:**
| File | Purpose |
|------|---------|
| `backend/api/v1/calibration.py` | All calibration API endpoints |
| `backend/models/calibration.py` | Pydantic models for validation |
| `backend/tests/test_calibration.py` | Comprehensive test suite |

**Key Features:**
- **Equipment-Aware**: Generates exercises based on user's available equipment
- **Bodyweight Fallback**: Users without equipment get bodyweight-only exercises
- **Context Logging**: All calibration events logged for AI learning
- **RLS Security**: Row-level security ensures users only see their own data
- **Skip Option**: Users can skip and do it later from settings

### 46b. Workout Settings - Training Configuration System
✅ **FULLY IMPLEMENTED**: Complete workout settings system allowing users to customize their training experience:

**Settings Overview:**
All workout configuration options are accessible from Settings > Workout Settings, providing users full control over their training parameters.

**1. My 1RMs (One Rep Max Storage)**
Store and manage your one-rep max values for personalized weight recommendations:

| Feature | Description |
|---------|-------------|
| **Add/Edit/Delete** | Manually enter 1RM values for any exercise |
| **Auto-Populate** | Calculate 1RMs from your workout history (90 days lookback) |
| **Source Tracking** | Track whether 1RM is manual, calculated, or tested |
| **Confidence Score** | 0.0-1.0 score for calculated estimates |
| **Last Tested Date** | Track when you last tested your max |

**User Flow - My 1RMs:**
```
Settings → Workout Settings → My 1RMs
                    ↓
    ┌────────────────────────────────┐
    │   No 1RMs Recorded             │
    │   [Auto-populate from history] │
    │   [+ Add 1RM]                  │
    └────────────────────────────────┘
                    ↓ (tap Add)
    ┌────────────────────────────────┐
    │   Add 1RM                      │
    │   Exercise: [Bench Press    ]  │
    │   Weight (kg): [100         ]  │
    │   Source: ○ Manual ○ Tested    │
    │   [Save]                       │
    └────────────────────────────────┘
```

**2. Training Intensity (Percentage-Based Training)**
Set your global training intensity as a percentage of your 1RM:

| Intensity % | Description | Best For |
|-------------|-------------|----------|
| 50-60% | Light / Recovery | Deload weeks, active recovery |
| 61-70% | Moderate / Endurance | Endurance building, warmups |
| 71-80% | Working Weight / Hypertrophy | Muscle building, default training |
| 81-90% | Heavy / Strength | Strength phases, powerlifting |
| 91-100% | Near Max / Peaking | Competition prep, 1RM testing |

**User Flow - Training Intensity:**
```
Settings → Workout Settings → Training Intensity
                    ↓
    ┌────────────────────────────────┐
    │   Training Intensity: 75%      │
    │   ━━━━━━━━━●━━━━━━             │
    │   50%            100%          │
    │                                │
    │   "Working Weight/Hypertrophy" │
    │   Build muscle at moderate load│
    └────────────────────────────────┘
```

**3. Per-Exercise Intensity Overrides**
Set different intensities for specific exercises:
- Override global intensity for exercises where you want more/less intensity
- Example: Train deadlifts at 85% but bench press at 70%

**4. Progression Pace**
Control how quickly the AI increases your weights:

| Pace | Weight Increase | Best For |
|------|-----------------|----------|
| Slow | Every 3-4 weeks | Injury recovery, perfecting form |
| Medium | Every 1-2 weeks | Steady, sustainable progress |
| Fast | Every session | Beginners with rapid newbie gains |

**5. Workout Type Preference**
Select your primary training style:

| Type | Description |
|------|-------------|
| Strength | Weight training focus, progressive overload |
| Cardio | Running, cycling, HIIT |
| Mixed | Combination of strength + cardio days |
| Mobility | Stretching, yoga, flexibility work |
| Recovery | Light movement, active rest |

**6. Training Split**
Choose your weekly workout structure:

| Split | Days | Description |
|-------|------|-------------|
| Full Body | 3 | All muscle groups each workout |
| Upper/Lower | 4 | Alternating upper and lower body |
| Push/Pull/Legs | 5-6 | Classic PPL split |
| Body Part Split | 5-6 | One muscle group per day |
| PHUL | 4 | Power Hypertrophy Upper Lower |
| Arnold Split | 6 | Chest/Back, Shoulders/Arms, Legs |
| HYROX | 4-5 | Hybrid running + functional |
| Let AI Decide | Auto | Based on your schedule and goals |

**7. Workout Days**
Select which days you train:
- Multi-select any combination (Mon-Sun)
- AI schedules workouts on selected days
- Rest days automatically assigned to unselected days

**Backend API Endpoints:**

*1RM Management:*
- `POST /api/v1/training/1rm` - Set/update a 1RM
- `GET /api/v1/training/1rm/{user_id}` - Get all 1RMs
- `GET /api/v1/training/1rm/{user_id}/{exercise}` - Get specific 1RM
- `DELETE /api/v1/training/1rm/{user_id}/{exercise}` - Delete 1RM
- `POST /api/v1/training/auto-populate/{user_id}` - Auto-calculate from history

*Training Intensity:*
- `POST /api/v1/training/intensity` - Set global intensity
- `GET /api/v1/training/intensity/{user_id}` - Get intensity settings
- `POST /api/v1/training/intensity/exercise` - Set per-exercise override
- `DELETE /api/v1/training/intensity/exercise/{user_id}/{exercise}` - Remove override

*Weight Calculation:*
- `POST /api/v1/training/calculate-weight` - Calculate working weight from 1RM + intensity
- `POST /api/v1/training/workout-weights` - Calculate weights for entire workout

**Database Schema (migration: 064_percentage_training.sql):**

| Table | Purpose |
|-------|---------|
| `user_exercise_1rms` | Stores user 1RM values with source, confidence, and timestamps |
| `exercise_intensity_overrides` | Per-exercise intensity settings |
| `users.training_intensity_percent` | Global intensity preference (50-100) |
| `users.preferences` (JSONB) | Stores progression_pace, workout_type, training_split |

**Flutter Implementation:**

| File | Purpose |
|------|---------|
| `lib/screens/settings/training/my_1rms_screen.dart` | My 1RMs screen with add/edit/delete |
| `lib/screens/settings/widgets/settings_card.dart` | Settings card with all preference selectors |
| `lib/core/providers/training_intensity_provider.dart` | State management for 1RMs and intensity |
| `lib/core/providers/training_preferences_provider.dart` | State for progression, type, split |
| `lib/data/repositories/training_intensity_repository.dart` | API client for training endpoints |
| `lib/data/models/training_intensity.dart` | Flutter models for training data |

**Backend Implementation:**

| File | Purpose |
|------|---------|
| `backend/api/v1/training_intensity.py` | All training settings API endpoints |
| `backend/services/percentage_training_service.py` | Business logic for calculations |
| `backend/tests/test_percentage_training.py` | Comprehensive test suite (18 tests) |

**User Context Logging (Database + ChromaDB):**
All training settings changes are logged to both Supabase (for debugging) and ChromaDB (for AI context):

*Database Logging (user_activity_log table):*
- `set_1rm` - When user adds/updates a 1RM value
- `delete_1rm` - When user removes a 1RM
- `set_training_intensity` - When global intensity changes
- `set_exercise_intensity_override` - When per-exercise override set
- `delete_exercise_intensity_override` - When override removed
- `auto_populate_1rms` - When auto-calculation is triggered

*ChromaDB Indexing (for AI coach context):*
Training settings are embedded and stored in ChromaDB so the AI coach can reference:
- "Based on your 100kg bench press 1RM at 75% intensity, try 75kg..."
- "Since you prefer slow progression, I'll keep weights steady..."
- "Your Push/Pull/Legs split means today is a push day..."

**Key Features:**
- **Equipment-Aware Rounding**: Working weights rounded to equipment increments (barbell 2.5kg, dumbbell 2kg, machine 5kg, kettlebell 4kg)
- **Brzycki Formula**: 1RM calculated using scientifically validated formula
- **Fuzzy Matching**: Exercise names matched even with variations
- **RLS Security**: Row-level security ensures data isolation
- **Offline Support**: Settings cached locally for offline access
- **AI Context Integration**: All settings indexed to ChromaDB for personalized AI coaching

**8. Exercise Consistency**
Control whether workouts use varied or consistent exercises:

| Mode | Description |
|------|-------------|
| Consistent | Same core exercises each week (stability for progress tracking) |
| Varied | Different exercises each week (prevents boredom, hits muscles from angles) |

**Features:**
- **Favorite Exercises**: Mark exercises you love - AI prioritizes these
- **Staple Exercises**: Core lifts (Squat, Bench, Deadlift) that NEVER rotate out
- Stored in `favorite_exercises` and `staple_exercises` tables

**Backend Endpoints:**
- `GET /api/v1/consistency/insights` - Get consistency insights
- `GET /api/v1/consistency/patterns` - Time/day workout patterns
- `GET /api/v1/consistency/calendar` - Calendar heatmap data

**Flutter Implementation:**
- `lib/core/providers/consistency_mode_provider.dart`
- `lib/data/repositories/exercise_preferences_repository.dart`

**9. Weekly Variety**
Control how much exercise variety appears week-to-week:

| Setting | Behavior |
|---------|----------|
| 0% | Same exercises every week |
| 30% (default) | 70% same exercises, 30% rotate |
| 100% | All new exercises each week |

**Database:**
- Column: `users.variation_percentage` (0-100, default 30%)
- Works with staple exercises (these never rotate regardless of setting)

**Migration:** `backend/migrations/063_staple_exercises.sql`

**10. Progress Charts**
Visual progress tracking over time (Settings > Workout Settings > Progress Charts):

| Chart Type | Description |
|------------|-------------|
| Strength Progression | Line chart showing weight increases by muscle group |
| Volume Chart | Bar chart showing total volume (sets × reps × weight) per week |

**Features:**
- Time range selector: 4, 8, 12 weeks, or all-time
- Muscle group filter: Focus on specific body parts
- Summary cards: Total workouts, PRs, volume change %

**Backend Endpoints:**
- `GET /api/v1/progress/strength-over-time` - Strength by muscle group
- `GET /api/v1/progress/volume-over-time` - Weekly volume
- `GET /api/v1/progress/exercise/{name}` - Per-exercise progression
- `GET /api/v1/progress/summary` - Progress statistics

**Flutter Implementation:**
- `lib/screens/progress/charts/progress_charts_screen.dart`
- `lib/data/providers/progress_charts_provider.dart`
- `lib/data/repositories/progress_charts_repository.dart`

**Database Migration:** `backend/migrations/096_progress_analytics.sql`

**11. Linked Exercises (Garmin-Style 1RM Sharing)**
Share 1RM values across related exercises - set one benchmark exercise and derive working weights for all linked variants.

**The Problem Solved:**
Users had to manually enter 1RMs for every single exercise variation. With 50+ chest exercises (bench press, incline, decline, dumbbell, cable, etc.), this was tedious and often resulted in missing 1RMs for most exercises.

**How It Works:**
1. Set a 1RM for a "benchmark" exercise (e.g., Barbell Bench Press = 100kg)
2. Link related exercises with strength multipliers (e.g., Incline Dumbbell Press at 85%)
3. System automatically calculates working weights for all linked exercises
4. Fallback chain: Direct 1RM → Explicit Link → Muscle Group Fallback

**User Flow:**
1. Navigate to **Settings → Workout Settings → My 1RMs**
2. Set a 1RM for a primary exercise (e.g., "Barbell Bench Press" = 100kg)
3. Tap the exercise card to expand linked exercises section
4. Tap "Link Exercise" to add related exercises
5. Select from suggestions (filtered by same muscle group) or search
6. Adjust the strength multiplier (default 85%) and relationship type
7. Save - linked exercises now derive their working weights automatically

**Relationship Types:**
| Type | Description | Typical Multiplier |
|------|-------------|-------------------|
| Variant | Same movement, different variation (e.g., Incline vs Flat) | 80-90% |
| Angle | Same exercise, different angle (e.g., 30° vs 45° incline) | 90-95% |
| Equipment Swap | Same movement, different equipment (e.g., Barbell vs Dumbbell) | 80-90% |
| Progression | Progressive exercise (e.g., Push-up vs Weighted Push-up) | 70-85% |

**Equipment Multipliers (Automatic):**
When deriving weights from muscle group fallback, equipment type is considered:

| Equipment | Multiplier | Reason |
|-----------|------------|--------|
| Barbell | 1.00 | Reference standard |
| Smith Machine | 0.95 | Fixed path reduces stabilization |
| EZ Bar | 0.95 | Slightly less leverage |
| Trap Bar | 1.00 | Similar mechanics to barbell |
| Machine | 0.90 | Fixed path, less stabilization |
| Dumbbell | 0.85 | Each arm works independently |
| Cable | 0.80 | Constant tension, less stable |
| Kettlebell | 0.75 | Different grip mechanics |
| Bodyweight | 0.70 | Different mechanics entirely |
| Resistance Band | 0.60 | Variable resistance throughout ROM |

**3-Level Fallback Chain:**
When calculating working weight for an exercise:
1. **Direct 1RM**: Use exact 1RM if stored for this exercise
2. **Explicit Link**: Check if linked to another exercise with stored 1RM
3. **Muscle Group Fallback**: Find highest-confidence 1RM for same primary muscle, apply equipment multiplier

**Backend Endpoints:**
*Linked Exercises CRUD:*
- `POST /api/v1/training/linked-exercises` - Create exercise link
- `GET /api/v1/training/linked-exercises/{user_id}` - Get all linked exercises
- `PUT /api/v1/training/linked-exercises/{link_id}` - Update link (multiplier, type)
- `DELETE /api/v1/training/linked-exercises/{link_id}` - Remove link
- `GET /api/v1/training/linked-exercises/{user_id}/suggestions/{exercise}` - Get linking suggestions

**Database Schema (migration: 154_exercise_relationships.sql):**

| Table | Purpose |
|-------|---------|
| `exercise_relationships` | Stores user-defined exercise links with multipliers |
| Columns: `user_id`, `primary_exercise_name`, `linked_exercise_name`, `strength_multiplier`, `relationship_type`, `notes` |

**Flutter Implementation:**
| File | Purpose |
|------|---------|
| `lib/screens/settings/training/my_1rms_screen.dart` | Linked exercises UI in 1RM cards |
| `lib/core/providers/training_intensity_provider.dart` | LinkedExercisesNotifier, state management |
| `lib/data/repositories/training_intensity_repository.dart` | API client for linked exercises |
| `lib/data/models/training_intensity.dart` | LinkedExercise, ExerciseLinkSuggestion models |

**Backend Implementation:**
| File | Purpose |
|------|---------|
| `backend/api/v1/training_intensity.py` | Linked exercises API endpoints |
| `backend/services/percentage_training_service.py` | Fallback logic, equipment multipliers, link resolution |
| `backend/tests/test_percentage_training.py` | Tests for linked exercises and equipment scaling |

**Key Features:**
- **Smart Suggestions**: Filtered by same primary muscle group
- **Adjustable Multipliers**: 50-100% range with 5% increments
- **Visual Feedback**: Derived weights show source exercise (e.g., "Based on Bench Press")
- **Badge Counts**: 1RM cards show number of linked exercises
- **RLS Security**: Row-level security ensures data isolation
- **ChromaDB Integration**: AI coach knows about linked exercises for personalized advice

**Example Scenario:**
1. User sets Barbell Bench Press = 100kg (1RM)
2. Links Incline Dumbbell Press at 85% multiplier
3. Workout includes Incline Dumbbell Press at 75% intensity
4. System calculates: 100kg × 0.85 (link) × 0.75 (intensity) = 63.75kg → rounded to 64kg
5. UI shows: "64 kg (based on Barbell Bench Press 1RM)"

### 47. "Falls short for its library and ability to input cooked grains - barcode scanner shows 'Item not found' for well-known drinks"
✅ **SOLVED**: Complete nutrition tracking enhancement addressing four major pain points:

**The Problem (from competitor review):**
Users complained about: (1) Limited food database requiring constant manual additions, (2) No ability to input cooked grains (only raw weights), (3) Barcode scanner showing "Item not found" for well-known products that appear in manual search, (4) Premium subscription not worth it due to these limitations.

**Our Solutions:**

**1. Enhanced Barcode Scanner with Fuzzy Search Fallback**
When a barcode lookup fails in Open Food Facts:
- **Automatic Fuzzy Search**: If barcode not found, system immediately searches by product name/brand hints
- **Alternative Product Suggestions**: Shows up to 5 similar products with similarity scores (60%+ threshold)
- **Manual Match**: Users can select an alternative and system remembers this match for future scans
- **Barcode Cache**: 24-hour caching of lookup results to avoid repeated API calls
- **Missing Barcode Reporting**: Users can report missing barcodes for future improvement
- **Match Reasons**: Shows why each alternative was suggested (similar_name, same_brand, category_match)

**2. Cooked/Prepared Food Weight Converter**
Solves the "cooked grains" problem with comprehensive raw↔cooked conversions:
- **55+ Food Conversion Factors**: Covering grains, legumes, meats, poultry, seafood, vegetables, eggs
- **Bidirectional Conversion**: Input raw weight → get cooked weight, OR input cooked weight → get raw weight
- **Cooking Method Awareness**: Different factors for grilling vs boiling vs baking (e.g., chicken breast: 0.75 grilled, 0.80 poached)
- **Nutritional Adjustment**: Automatically adjusts calories/protein/carbs per 100g based on water absorption/loss
- **Example Conversions**:
  - 100g raw white rice → 250g cooked (2.5x, absorbs water)
  - 100g raw chicken breast → 75g grilled (0.75x, loses moisture)
  - 100g raw pasta → 200g cooked (2.0x, absorbs water)
  - 100g raw spinach → 10g sautéed (0.10x, wilts dramatically)
- **Food Categories**: GRAINS (rice, pasta, oats, quinoa), LEGUMES (lentils, beans, chickpeas), MEATS (beef, pork, lamb), POULTRY (chicken, turkey), SEAFOOD (salmon, tuna, shrimp), VEGETABLES (spinach, mushrooms, potatoes), EGGS

**3. Recent/Frequent Foods Quick Re-Logging**
Addresses "constantly having to add" complaint:
- **Frequency Tracking**: Automatic tracking of how often each food is logged (via database trigger)
- **Recent Foods List**: Last 20 logged foods for quick re-logging
- **Smart Suggestions**: Time-of-day aware suggestions (breakfast foods in morning, dinner foods at night)
- **One-Tap Re-Log**: Previously logged foods can be re-logged with single tap
- **Meal Pattern Learning**: System learns user's eating patterns for better suggestions
- **Database Tables**: `user_food_frequency`, `recent_food_logs` with RLS security

**4. Improved Food Database Coverage**
- **Open Food Facts Integration**: Primary source with 2.5M+ products
- **Product Search**: Full-text search by product name when barcode fails
- **Cached Lookups**: Frequently scanned products cached locally for instant access
- **Alternative Products**: When exact match not found, similar products suggested

**Backend Implementation:**
| File | Purpose |
|------|---------|
| `backend/services/food_database_service.py` | Enhanced with fuzzy search, barcode caching, alternative suggestions |
| `backend/services/cooking_conversion_service.py` | Raw↔cooked weight conversions with 55+ factors |
| `backend/migrations/115_frequent_foods.sql` | Frequent foods tracking tables with triggers |
| `backend/migrations/116_barcode_cache.sql` | Barcode lookup caching and missing reports |

**API Endpoints:**
- `GET /api/v1/nutrition/barcode/{barcode}/with-fallback` - Enhanced lookup with alternatives
- `POST /api/v1/nutrition/barcode/report-missing` - Report missing barcode
- `POST /api/v1/nutrition/barcode/manual-match` - Match barcode to alternative
- `GET /api/v1/nutrition/cooking-conversions` - Get all conversion factors
- `POST /api/v1/nutrition/convert-weight` - Convert raw↔cooked weight
- `GET /api/v1/nutrition/frequent-foods/{user_id}` - Get user's frequent foods
- `GET /api/v1/nutrition/recent-foods/{user_id}` - Get recent logged foods
- `GET /api/v1/nutrition/smart-suggestions/{user_id}` - Time-aware food suggestions

**Flutter Implementation:**
| File | Purpose |
|------|---------|
| `lib/data/models/frequent_food.dart` | Models for FrequentFood, CookingConversion, BarcodeSearchResult |
| `lib/data/repositories/nutrition_repository.dart` | API calls for nutrition features |
| `lib/screens/nutrition/widgets/barcode_fallback_sheet.dart` | Shows alternatives when barcode not found |
| `lib/screens/nutrition/widgets/cooking_converter.dart` | Raw↔cooked weight converter UI |
| `lib/screens/nutrition/widgets/frequent_foods_sheet.dart` | Quick re-logging from frequent foods |

### 48. "Can't see workout history per exercise or per muscle - only aggregate charts"
✅ **SOLVED**: Complete Per-Exercise History and Muscle-Level Analytics System

**The Problem:**
Users want to track progression for specific exercises (e.g., "How has my bench press progressed over time?") and see which muscle groups are being trained most/least frequently. Existing progress screens only show aggregate data by muscle group, not drill-down per-exercise analytics or muscle balance insights.

**Solution Overview:**

**1. Per-Exercise Workout History**
- **Exercise Detail View**: Tap any exercise in the library to see complete workout history
- **Session Details**: Date, workout name, sets completed, total reps, total volume, max weight, estimated 1RM, average RPE
- **Time Range Filtering**: 4 weeks, 8 weeks, 12 weeks, 6 months, 1 year, or all time
- **Pagination**: 20 records per page for exercises with extensive history
- **Summary Stats**: Total sessions, average reps, PR count at a glance
- **API Endpoint**: `GET /api/v1/exercise-history/{exercise_name}?user_id=X&time_range=12_weeks&page=1&limit=20`

**2. Exercise Progression Charts**
- **Line Charts**: Max weight, estimated 1RM, and total volume trends over time
- **Trend Analysis**: Automatic detection of improving/stable/declining trends with percentage change
- **Data Points**: Each workout session plotted chronologically
- **Visual Indicators**: Color-coded trend arrows (green improving, red declining)
- **API Endpoint**: `GET /api/v1/exercise-history/{exercise_name}/chart?user_id=X`

**3. Exercise Personal Records (PRs)**
- **PR Types Tracked**: Max weight, best estimated 1RM, max single-session volume, max reps in a set
- **Achievement Details**: When achieved, which workout, reps/weight at record
- **Historical PRs**: Full history of PR progression for each exercise
- **Celebration Moments**: PR badges displayed on exercise cards
- **API Endpoint**: `GET /api/v1/exercise-history/{exercise_name}/prs?user_id=X`

**4. Muscle Heatmap Visualization**
- **Body Diagram**: Interactive body outline showing all major muscle groups
- **Intensity Scores**: 0-100 intensity based on training frequency and volume
- **Color Coding**: Untrained (gray) → Light (green) → Moderate (yellow) → Heavy (red)
- **Tap to Explore**: Tap any muscle to see exercises that target it
- **Time Range**: Configurable view period (1 week, 4 weeks, 12 weeks)
- **API Endpoint**: `GET /api/v1/muscle-analytics/heatmap?user_id=X&time_range_days=28`

**5. Muscle Training Frequency**
- **Per-Muscle Breakdown**: How many times each muscle was trained
- **Volume Data**: Total sets and total volume (kg) per muscle group
- **Last Trained**: When each muscle was last worked
- **Frequency Goals**: Compare against recommended training frequency
- **API Endpoint**: `GET /api/v1/muscle-analytics/frequency?user_id=X`

**6. Muscle Balance Analysis**
- **Push/Pull Ratio**: Balance between pushing and pulling movements (ideal: 1.0)
- **Upper/Lower Ratio**: Balance between upper and lower body training
- **Balance Score**: 0-100 overall balance assessment
- **Category Labels**: Balanced, slightly imbalanced, imbalanced with recommendations
- **AI Integration**: Context logged for AI coach to provide balance improvement suggestions
- **API Endpoint**: `GET /api/v1/muscle-analytics/balance?user_id=X`

**7. Exercises by Muscle Group**
- **Muscle Drill-Down**: From heatmap, tap a muscle to see all exercises targeting it
- **Performance Context**: Which exercises user has done most for each muscle
- **Discovery**: Find new exercises for undertrained muscles
- **API Endpoint**: `GET /api/v1/muscle-analytics/muscle/{muscle_group}/exercises?user_id=X`

**8. Muscle Volume History**
- **Weekly Trends**: Volume per muscle group over time
- **Growth Tracking**: See if training volume is increasing appropriately
- **Periodization Insights**: Identify peaks and valleys in muscle training
- **API Endpoint**: `GET /api/v1/muscle-analytics/muscle/{muscle_group}/history?user_id=X`

**Database Schema:**
- `exercise_workout_history` view: Aggregated per-exercise session data with 1RM calculations
- `exercise_personal_records` table: PR tracking with achievement timestamps
- `muscle_training_frequency` view: Per-muscle workout stats
- `muscle_balance_analysis` view: Push/pull and upper/lower ratios
- `exercise_history_logs` table: Analytics tracking for user engagement
- `muscle_analytics_logs` table: Heatmap and balance view tracking
- PostgreSQL functions: `analyze_exercise_progression()`, `get_muscle_heatmap_data()`, `get_exercises_for_muscle()`
- Full RLS security on all tables

**API Endpoints Summary:**
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/exercise-history/{exercise_name}` | GET | Paginated exercise workout history |
| `/api/v1/exercise-history/{exercise_name}/chart` | GET | Chart data with trend analysis |
| `/api/v1/exercise-history/{exercise_name}/prs` | GET | Personal records for exercise |
| `/api/v1/exercise-history/most-performed` | GET | Most frequently performed exercises |
| `/api/v1/exercise-history/log-view` | POST | Log user view for analytics |
| `/api/v1/muscle-analytics/heatmap` | GET | Muscle intensity heatmap data |
| `/api/v1/muscle-analytics/frequency` | GET | Training frequency per muscle |
| `/api/v1/muscle-analytics/balance` | GET | Push/pull, upper/lower balance |
| `/api/v1/muscle-analytics/muscle/{muscle}/exercises` | GET | Exercises targeting muscle |
| `/api/v1/muscle-analytics/muscle/{muscle}/history` | GET | Volume history for muscle |
| `/api/v1/muscle-analytics/log-view` | POST | Log heatmap/balance view |

**Migration Files:**
- `115_exercise_history_analytics.sql` - Exercise history views, PR tables, progression functions
- `116_muscle_analytics.sql` - Muscle heatmap, frequency, balance views and functions

**Backend Tests:**
- `test_exercise_history_api.py` - 15+ tests for history, charts, PRs, pagination
- `test_muscle_analytics_api.py` - 12+ tests for heatmap, frequency, balance, muscle drill-down

**Flutter UI Implementation:**
- **Exercise History Screen** (`/progress/exercise-history`): Searchable list of most performed exercises with session counts, navigation to per-exercise details
- **Exercise Progress Detail Screen** (`/progress/exercise-history/:exerciseName`): Two tabs - Progress (line charts, PRs) and History (paginated session list with pagination)
- **Muscle Analytics Screen** (`/progress/muscle-analytics`): Three tabs - Heatmap (body muscle visualization), Frequency (horizontal bar chart), Balance (push/pull & upper/lower bars)
- **Muscle Detail Screen** (`/progress/muscle-analytics/:muscleGroup`): Volume trend bar chart, exercises for muscle with contribution percentages
- **Navigation Entry Points**: "Detailed Analytics" section on Progress screen with two cards linking to Exercise History and Muscle Analytics
- **Widgets**: `MuscleHeatmapWidget`, `MuscleFrequencyChart`, `MuscleBalanceChart` for visualizations
- **Repositories**: `ExerciseHistoryRepository`, `MuscleAnalyticsRepository` for API calls
- **Providers**: Riverpod providers with time range filtering, pagination, and caching
- **User Context Logging**: View duration tracked and logged to backend for AI personalization

### 49. "Too slow and convoluted to track meals - useless AI food tips after each meal logged"
✅ **SOLVED**: Complete nutrition tracking UX overhaul addressing speed, simplicity, and user control:

**The Problem (from competitor review):**
Users complained: "Too slow and convoluted to track meals. Need a way to disable the useless (and incorrect) AI food tips after each meal logged. Between that, the lag when searching for foods, and the various submenus for foods/meals/recipes, it's too much. Even saving common foods as a meal and selecting that every morning feels slower than other apps."

**Our Solutions:**

**1. Toggle to Disable AI Food Tips**
- **New Setting**: "Disable AI Food Tips" toggle in Settings > Nutrition Settings
- **Immediate Effect**: When enabled, no AI suggestions/warnings shown after logging meals
- **User Control**: Users can re-enable anytime if they want feedback back
- **Additional Settings**: Quick log mode, compact tracker view, show macros on log toggles
- **Database**: `user_nutrition_preferences` table stores all UI preferences

**2. Quick Add Button - Minimal-Tap Meal Logging**
- **Floating Action Button**: Quick Add FAB appears on nutrition screen (when enabled)
- **2-Tap Maximum**: Open sheet → tap food → logged (no confirmation needed)
- **Quick Add Sheet Contents**:
  - **Favorites Section**: Top 8 most-logged foods as tappable chips
  - **Recent Section**: Last 5 logged meals with meal type, time, calories
  - **Recipes Section**: User's meal templates for one-tap logging
  - **Manual Entry**: "Log something else" opens full sheet only when needed
- **Auto Meal Type**: Detects time of day (breakfast 5-11am, lunch 11am-3pm, snack 3-6pm, dinner 6pm+)
- **Instant Feedback**: Brief snackbar "Logged: Coffee - 5 cal" then auto-closes

**3. Instant Food Search with Debouncing & Caching**
- **300ms Debounce**: Prevents API spam while typing
- **LRU Memory Cache**: 50 items, 5-minute TTL for instant repeat searches
- **Server-Side Cache**: `food_search_cache` table with 7-day TTL
- **Parallel Search**: Searches saved foods, recent logs, and database simultaneously
- **Performance**: First keystroke to results < 500ms for cached queries
- **Search States**: Loading, results (categorized), error, initial states
- **Material 3 Search Bar**: Animated focus, filter chips (All/Saved/Recent)

**4. Unified Food Library (Single View for All Foods)**
- **Consolidated Screen**: Foods, saved foods, and recipes in one tabbed view
- **Three Tabs**: All | Saved | Recipes with counts
- **Unified Search**: Search bar searches across all categories
- **Sort Options**: By name, frequency (most used), or date added
- **Quick Actions**:
  - Tap: View nutrition details
  - "Log" button: Quick log with meal type selector
  - Swipe left: Delete with confirmation
- **Empty States**: Helpful messages when sections are empty
- **Pull to Refresh**: Update data without leaving screen

**5. One-Tap Re-Log for Saved Meals (Bypass AI)**
- **POST `/api/v1/nutrition/quick-log`**: Logs saved food without AI analysis
- **Servings Multiplier**: Optional servings parameter (default 1.0)
- **Pre-Calculated Nutrition**: Uses stored values, no API call to Gemini
- **Quick Log History**: `quick_log_history` table tracks frequency for smart suggestions
- **Time-of-Day Buckets**: morning/afternoon/evening/night for better suggestions

**6. Redesigned Tracker Layout (Meals at Top)**
- **Previous Layout Issues**: 11+ components, meals buried at bottom (#11)
- **New Compact Energy Header**: Calories eaten | progress bar | remaining (single row)
- **Meals Moved to Top**: Immediately after energy header
- **Collapsible Analytics**: All analytics cards grouped under "View Analytics" section
- **Compact Mode**: When enabled, analytics collapsed by default
- **Quick Favorites**: Inline with meals section for easy access

**7. Meal Templates (Breakfast/Lunch/Dinner Presets)**
- **Create Templates**: Save common meals as templates with all nutrition data
- **Template Properties**: Name, meal type, food items array, calculated totals
- **System Templates**: Pre-made templates available to all users
- **Usage Tracking**: `use_count` and `last_used_at` for smart sorting
- **One-Tap Log**: POST `/api/v1/nutrition/templates/{id}/log` with optional servings
- **CRUD Operations**: Create, read, update, delete endpoints

**Database Migrations:**
| File | Purpose |
|------|---------|
| `117_user_nutrition_preferences.sql` | UI preferences (disable_ai_tips, quick_log_mode, compact_view) |
| `118_meal_templates.sql` | Meal templates with food items, totals, usage tracking |
| `119_food_search_cache.sql` | Search result caching with 7-day TTL |
| `120_quick_log_history.sql` | Quick log frequency tracking for suggestions |

**Backend API Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/nutrition/preferences` | GET/PUT | Get/update nutrition UI preferences |
| `/api/v1/nutrition/preferences/reset` | POST | Reset to default preferences |
| `/api/v1/nutrition/quick-log` | POST | Quick log saved food (bypasses AI) |
| `/api/v1/nutrition/quick-suggestions` | GET | Time-aware personalized suggestions |
| `/api/v1/nutrition/templates` | GET/POST | List/create meal templates |
| `/api/v1/nutrition/templates/{id}` | PUT/DELETE | Update/delete template |
| `/api/v1/nutrition/templates/{id}/log` | POST | Log template as food entry |
| `/api/v1/nutrition/search` | GET | Fast food search with caching |

**Flutter Implementation:**
| File | Purpose |
|------|---------|
| `lib/data/models/nutrition_preferences.dart` | NutritionUIPreferences, MealTemplate, QuickSuggestion models |
| `lib/data/repositories/nutrition_preferences_repository.dart` | API calls for preferences, templates, quick log |
| `lib/data/providers/nutrition_preferences_provider.dart` | State management for nutrition UI settings |
| `lib/screens/nutrition/widgets/quick_add_fab.dart` | Floating action button for quick add |
| `lib/screens/nutrition/widgets/quick_add_sheet.dart` | Bottom sheet with favorites, recent, recipes |
| `lib/data/services/food_search_service.dart` | Debounced search with LRU cache |
| `lib/screens/nutrition/widgets/food_search_bar.dart` | Material 3 search bar with filters |
| `lib/screens/nutrition/widgets/food_search_results.dart` | Categorized results display |
| `lib/screens/nutrition/food_library_screen.dart` | Unified food/recipe library |
| `lib/screens/nutrition/nutrition_screen.dart` | Redesigned layout with meals at top |
| `lib/screens/nutrition/nutrition_settings_screen.dart` | AI tips toggle, quick log mode settings |

**User Context Logging:**
All nutrition actions are logged for analytics:
- `nutrition_preferences_updated` - Settings changes
- `quick_log_used` - Quick log with food name, calories
- `meal_template_created/logged/deleted` - Template actions
- `food_search_performed` - Search queries with cache hit status
- `ai_tips_disabled/enabled` - Toggle tracking
- `compact_view_enabled/disabled` - Layout preference

**Backend Tests:**
- `test_nutrition_preferences.py` - 71 tests covering preferences, quick log, templates, search

---

### 50. "Need a holistic plan that coordinates workouts, nutrition, and fasting together"
✅ **IMPLEMENTED**: Full Weekly Plan feature that tightly integrates workouts, nutrition targets, and fasting windows into a unified planning system.

**The Problem:**
Users with multiple fitness goals (strength training + fasting + nutrition tracking) had to manually coordinate between different app sections. There was no unified view showing how workout days affect nutrition needs or how fasting windows should align with training times. This led to:
- Same calorie targets on training and rest days (inefficient)
- Fasted training without warnings or supplementation guidance
- Meal timing that didn't account for eating windows
- No AI-generated meal suggestions to hit macro targets

**Our Solution - Holistic Weekly Planning:**

**1. Workout-Aware Nutrition Adjustments**
Automatic daily calorie and macro adjustments based on training:
| Day Type | Calorie Adjustment | Protein Adjustment | Carbs Adjustment |
|----------|-------------------|-------------------|------------------|
| **High Intensity Training** | +350 cal | +30g | +50g |
| **Moderate Training** | +250 cal | +20g | +30g |
| **Light Training/Active Recovery** | +150 cal | +15g | +20g |
| **Rest Day** | Base targets | Base targets | Base targets |
| **Cutting Phase Rest** | -200 cal | Base protein | Reduced carbs |

**2. Fasting-Workout Coordination**
Smart coordination warnings and scheduling:
- **Optimal Timing Detection**: Identifies when workout fits within eating window
- **Fasted Training Warnings**: Alerts with BCAA recommendations for morning workouts during 16:8 fasting
- **Extended Fast Detection**: Extra warnings for workouts during 18:6, 20:4, or OMAD protocols
- **Post-Workout Window**: Ensures time for post-workout nutrition before fast begins
- **Automatic Window Adjustments**: Optional adjustment of eating window to match workout schedule

**3. AI-Generated Meal Suggestions**
Each day includes meal suggestions tailored to targets and timing:
- **Training Day Meals**: Include pre-workout (2-3h before) and post-workout (within 2h) meals
- **Macro Matching**: Total daily suggestions match calorie/protein targets
- **Eating Window Compliance**: All meals fit within fasting eating window
- **Food Preferences**: Respects dietary restrictions and cuisine preferences
- **One-Tap Logging**: "Log this meal" button for quick tracking

**4. Weekly Plan View**
Unified calendar view showing the complete picture:
- **7-Day Overview**: Training days, rest days, at a glance
- **Daily Breakdown**: Tap any day to see full details
- **Nutrition Progress**: Macro rings for each day
- **Fasting Timeline**: Visual eating/fasting windows
- **Coordination Notes**: Warnings and tips per day

**5. Daily Plan Detail Sheet**
Comprehensive daily view with:
- **Workout Card**: Quick access to start today's workout
- **Nutrition Targets**: Daily calories/protein/carbs/fat/fiber
- **Fasting Window**: Visual timeline showing eating hours
- **Meal Suggestions**: AI-generated meals with foods and macros
- **Coordination Notes**: Tips for optimal timing

**6. Home Screen Integration**
New Weekly Plan home tile showing:
- **Today's Summary**: Training vs rest, calories, fasting
- **Mini Calendar**: 7-day view with workout indicators
- **Quick Actions**: View full plan, start workout

**7. Plan Agent (LangGraph)**
Dedicated AI agent for plan-related conversations:
- Intent routing for: generate_weekly_plan, adjust_plan, explain_plan
- Understands natural language: "Create a plan for next week", "What should I eat on leg day?"
- Integrates with existing nutrition/workout agents for seamless experience

**Backend API Endpoints:**
```
POST /api/v1/weekly-plans/generate         - Generate AI weekly plan
GET  /api/v1/weekly-plans/current          - Get current week's plan
GET  /api/v1/weekly-plans/{week_start}     - Get specific week's plan
PUT  /api/v1/weekly-plans/{id}             - Update plan settings
DELETE /api/v1/weekly-plans/{id}           - Archive a plan
GET  /api/v1/weekly-plans/{id}/daily/{date} - Get daily plan details
PUT  /api/v1/weekly-plans/{id}/daily/{date} - Update daily entry
POST /api/v1/meal-plans/generate           - Generate meal suggestions
POST /api/v1/meal-plans/regenerate-meal    - Regenerate single meal
```

**Database Tables:**
- `weekly_plans` - Weekly plan metadata with workout days, fasting protocol, nutrition strategy
- `daily_plan_entries` - Daily targets, workout reference, fasting windows, meal suggestions
- `meal_plan_templates` - Saved meal templates for quick reuse

**Flutter Implementation:**
- **Models**: `WeeklyPlan`, `DailyPlanEntry`, `MealSuggestion`, `CoordinationNote`, `NutritionStrategy`
- **Repository**: `WeeklyPlanRepository` with full CRUD operations
- **Provider**: `weeklyPlanProvider` with `todayPlanEntryProvider` for quick access
- **Screens**: `WeeklyPlanScreen`, `DailyPlanDetailSheet`, `GeneratePlanSheet`
- **Home Tile**: `WeeklyPlanCard` for home screen integration

**User Context Events:**
- `weekly_plan_generated` - Track plan generation
- `weekly_plan_viewed` - Track plan views
- `daily_plan_viewed` - Track daily detail views
- `meal_suggestion_logged` - Track meal logging from suggestions
- `meal_suggestion_regenerated` - Track meal regeneration requests
- `plan_coordination_warning_viewed` - Track coordination note interactions

**Backend Tests:**
- `test_weekly_plans.py` - Comprehensive tests for plan generation, nutrition adjustments, fasting coordination, meal suggestions validation

---

## Comprehensive Competitor Analysis

This section provides detailed competitive intelligence on major fitness apps in the market, highlighting how FitWiz differentiates and the strategic advantages we offer.

### Market Landscape Overview

The fitness app market is fragmented into three categories:
1. **Workout Trackers** (Hevy, Strong) - Manual logging, no AI generation
2. **AI Generators** (Fitbod, Gravl) - ML-based workout creation, limited coaching
3. **Video Platforms** (Nike Training Club, Peloton, Gymshark) - Pre-recorded content, no personalization

**FitWiz bridges ALL three** with AI generation + conversational coaching + personalization - a unique combination in the market.

---
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

### Fasting Apps Comparison

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

### Pricing Comparison

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

### Complaint: "Definitely not for beginners - exercises way too difficult, can only skip 3, settings don't help"

A user reviewed a competitor app saying: *"The problem isn't the number of reps—it's the exercises themselves, which are way too difficult for someone who's never trained before. Sure, you can skip a few of the hardest ones, but only three. Changing settings or recreating workouts doesn't lower the difficulty at all. If you're a complete beginner like me, it's absolutely useless."*

**Our Comprehensive Beginner Support System:**

| Issue | Competitor | FitWiz Solution |
|-------|------------|--------------------------|
| **Exercises too difficult** | Advanced exercises given to beginners | **Difficulty Ceiling System**: Beginners only see exercises rated 1-3 (out of 10). Pull-ups, muscle-ups, pistol squats are filtered out. |
| **Limited skips (only 3)** | Can only skip 3 exercises | **Unlimited Skips + Swaps**: Skip any exercise, get AI-suggested alternatives, no limits. |
| **Settings don't help** | Changing settings has no effect | **Fitness-Level-Aware Generation**: All workout parameters respect fitness level during generation. |
| **Recreating doesn't lower difficulty** | Regeneration ignores user level | **Smart Regeneration**: Uses difficulty ceiling + fitness level caps + feedback adjustments. |

**Technical Implementation:**

1. **Difficulty Ceiling System** (`services/exercise_rag/service.py`):
   - Beginners: Only easy exercises (difficulty 1-3 out of 10)
   - Intermediates: Easy-medium (1-6 out of 10)
   - Advanced: All exercises allowed (1-10)

2. **Beginner Parameter Caps** (`services/adaptive_workout_service.py`):
   - **Max 3 sets** (not 4-5 like intermediates)
   - **6-12 reps** (focused on form, not endurance)
   - **+30 seconds extra rest** between sets
   - **Reduced exercise count** per workout

3. **Unlimited Exercise Management**:
   - Skip any exercise during workout (no 3-skip limit)
   - Swap for AI-suggested alternatives targeting same muscles
   - Add exercises if desired
   - Remove sets when fatigued

4. **Adaptive Difficulty from Feedback**:
   - Rate exercises as "too easy", "just right", or "too hard"
   - System adjusts difficulty ceiling by ±2 based on feedback patterns
   - Consistent "too hard" ratings → regression to easier exercises
   - Tracked in `difficulty_adjustments` table for transparency

5. **Leverage-Based Progressions** (not just rep increases):
   - Wall Push-ups → Incline → Knee → Standard → Diamond → Archer
   - Assisted Squats → Bodyweight → Goblet → Barbell → Pistol
   - Dead Hang → Scapular Pulls → Assisted Pull-ups → Negatives → Full

**Database Tables Supporting Beginners:**
- `exercise_feedback` - Tracks difficulty ratings per exercise
- `difficulty_adjustments` - Logs feedback-based ceiling changes
- `user_rep_range_preferences` - User's preferred rep limits
- `avoided_exercises` - Exercises user wants to skip permanently

**Tests Validating Beginner Safety:**
- `test_beginner_workout_parameters.py` - Verifies caps are enforced
- `test_exercise_difficulty_filter.py` - Ensures advanced exercises filtered
- `test_feedback_adjustment.py` - Validates adaptive difficulty works

---

### Complaint: "No option to extract workout logs in text format + Navigation requires multiple clicks"

A user reviewed a competitor app saying: *"Missing features: There is no option to extract workout logs in a text format. The navigation is not so good (multiple clicks can be reduced to single click at number of places). The way images show up is also not smooth, one needs to click 2-3 times."*

**Our Solutions:**

#### 1. Text Export - IMPLEMENTED

| Feature | Implementation |
|---------|----------------|
| **Plain Text Export** | New `/api/v1/users/{user_id}/export-text` endpoint returns formatted workout logs |
| **Format Toggle** | Export dialog offers "CSV/ZIP" or "Plain Text" format selection |
| **Date Range Filter** | Optional start_date/end_date parameters for filtering |
| **Readable Format** | Structured text with workout headers, exercise lists, sets/reps/weight/RPE |

**Example Output:**
```
====================================================================
AI FITNESS COACH - WORKOUT LOG EXPORT
Generated: 2025-12-30
Period: 2025-01-01 to 2025-12-30
====================================================================

--------------------------------------------------------------------
WORKOUT: Upper Body Strength
Date: Monday, December 30, 2025
Duration: 45 minutes | Total Sets: 12 | Total Reps: 96 | Total Volume: 1440.0 kg
--------------------------------------------------------------------

1. Bench Press
   Set 1: 60 kg x 10 reps (RPE 7)
   Set 2: 60 kg x 8 reps (RPE 8)

2. Barbell Row
   Set 1: 50 kg x 12 reps
...
```

**Files:**
- Backend service: `services/data_export.py` - `export_workout_logs_text()` function
- API endpoint: `api/v1/users.py` - GET `/export-text`
- Flutter UI: `screens/settings/dialogs/export_dialog.dart` - Format selector
- Tests: `tests/test_text_export.py` - 27 test cases

#### 2. Reduced Navigation Clicks - IMPLEMENTED

| Issue | Before | After |
|-------|--------|-------|
| **Exercise video viewing** | 2-3 clicks (open sheet → tap video → tap play) | 1 click (open sheet → auto-plays) |
| **Video loading feedback** | No indicator, abrupt appearance | Smooth fade-in with loading animation |
| **Accessibility** | No consideration | Respects reduced motion settings |

**Technical Implementation:**
- **Auto-play on open**: Videos start automatically when `ExerciseDetailSheet` opens
- **Delayed start**: 300ms delay after sheet animation completes
- **Video caching**: First checks local cache, uses `VideoPlayerController.file()` for faster loading
- **Smooth fade-in**: `FadeTransition` animation when video is ready
- **Enhanced loading indicator**: Dual-ring animation with "Will auto-play when ready" text
- **Retry button**: For failed loads, users can tap to retry

**Files:**
- `screens/library/components/exercise_detail_sheet.dart` - Auto-play + fade-in
- `screens/library/widgets/netflix_exercise_carousel.dart` - Consistent behavior
- Uses `video_cache_provider.dart` for cached video support

---

A user review of a competitor fitness app highlighted these specific complaints. Here's how FitWiz addresses each one:

### Complaint: "Coach randomly assigns same 15 exercises regardless of what equipment you select"
**Our Solution**:
- **1,722+ exercises** in our database with detailed equipment requirements
- **23+ equipment types** supported with quantities and weight specifications
- **Equipment-aware filtering**: Exercises are filtered at RAG query time to only return exercises matching user's equipment
- **Backend validation**: `equipment_available` list is cross-referenced during workout generation
- **Settings integration**: Users can update equipment anytime in Settings > Training Preferences > My Equipment

### Complaint: "Equipment you choose has no effect on workouts"
**Our Solution**:
- Equipment flows through the entire generation pipeline:
  1. **Onboarding**: Users select environment + detailed equipment with quantities
  2. **RAG Service**: `services/exercise_rag/service.py` filters by `equipment_available`
  3. **LangGraph Agent**: Exercise suggestion nodes validate equipment compatibility
  4. **Generation**: `workouts/generation.py` includes equipment in Gemini prompts
  5. **Fallback**: If AI suggests unavailable equipment, validation catches and substitutes
- **Equipment persistence**: Stored in `users` table and passed to every workout generation call

### Complaint: "Indicating workout was too easy/too hard doesn't change anything"
**Our Solution**:
- **Difficulty feedback system**: -2 to +2 scale (Way Too Easy → Way Too Hard)
- **Feedback persistence**: Stored in `exercise_feedback` table with timestamps
- **Weighted algorithm**: `feedback_analysis_service.py` considers recency and consistency
- **Automatic adjustments**: Consistent "too easy" ratings trigger progressive increases
- **Visual confirmation**: Workout completion screen explains feedback importance
- **ChromaDB integration**: Exercise feedback stored in RAG for personalized suggestions

### Complaint: "Warmup is ALWAYS the same regardless of what muscle group you're working"
**Our Solution**:
- **Dynamic warmup generation**: `warmup_stretch_service.py` generates muscle-specific warmups
- **Target muscle extraction**: Warmups analyze workout exercises to identify primary muscles
- **7-day variety tracking**: `warmup_stretch_tracking` table prevents repetition
- **Muscle-specific movements**:
  - Leg day → leg swings, hip circles, lunges
  - Chest day → arm circles, chest openers, shoulder rotations
  - Back day → cat-cow, thoracic rotations
- **Migration 078**: `warmup_stretch_target_muscles` adds muscle targeting to database

### Complaint: "No option to select push/pull/legs or a specific muscle group"
**Our Solution**:
- **8 training splits** supported:
  - `push_pull_legs` - Classic 6-day split
  - `upper_lower` - 4-day upper/lower rotation
  - `full_body` - 3x/week total body
  - `body_part` - Bro split (chest, back, shoulders, arms, legs)
  - `phul` - Power Hypertrophy Upper Lower
  - `arnold_split` - Chest/Back, Shoulders/Arms, Legs
  - `hyrox` - Hybrid functional training
  - `dont_know` - AI selects optimal split
- **Settings access**: Training Split selector in Settings > Training Preferences
- **Focus area targeting**: `/generate-now` endpoint accepts specific muscle groups
- **Mood-based generation**: Quick workout card allows muscle group selection

### Complaint: "You cannot edit any exercise in the predetermined routine"
**Our Solution**:
- **AI-powered exercise swap**: `ExerciseSwapSheet` in active workout screen
- **Smart suggestions**: LangGraph agent provides alternatives targeting same muscles
- **Multiple options**: 3+ AI-suggested replacements plus manual search
- **Equipment-aware**: Suggestions respect user's available equipment
- **Persistence**: Swaps saved to backend and reflected in workout history
- **Inline editing**: Tap any exercise during workout to access swap sheet
- **Add exercises**: "Add Exercise" button to include additional movements

### Complaint: "Doesn't let you create custom workouts, forces programs, limits to 5 days - made for beginners only"

A user reviewed a competitor app saying: *"This app is abysmal for anybody that has any real training experience. Despite containing a lot of exercises, it doesn't let you create and update your own custom workouts. It forces you to use their own programs, which is brain dead if you are anything but a complete beginner. Despite being a workout app, it doesn't let you set more than 5 days of training per week, so my six day split can say bye. Let's be honest, this app is made for people who don't really know anything about fitness."*

**Our Comprehensive Response:**

| Issue | Competitor | FitWiz Solution |
|-------|------------|--------------------------|
| **No custom workouts** | Can't create own workouts | **Full Custom Workout Builder**: Create from scratch with exercise search, drag-reorder, custom sets/reps/weight |
| **Can't update workouts** | Can't modify created workouts | **Complete CRUD**: Create, Read, Update, Delete custom workouts via API |
| **Forces programs** | Must use predefined programs | **8 splits + Custom option**: Describe ANY goal in text, AI generates personalized program |
| **5-day limit** | Max 5 training days | **1-7 days supported**: Select any combination including 6-day or 7-day splits |
| **"For beginners only"** | Limited advanced features | **Skill progressions, 1,681 exercises, composite exercises, advanced splits** |

**Technical Implementation:**

#### 1. Custom Workout Builder
- **Screen**: `screens/workout/custom_workout_builder_screen.dart`
- **Route**: `/workout/build`
- **Features**:
  - Exercise search with library of 1,681 exercises
  - Drag-to-reorder exercises
  - Per-exercise configuration: sets (1-10), reps (1-30), weight (0-200kg), rest time
  - Equipment type, muscle group, notes per exercise
  - Duration estimation (~5 min per exercise)
  - Real-time validation

#### 2. Custom Workout CRUD (Backend)
```
POST   /api/v1/workouts/           - Create custom workout
PUT    /api/v1/workouts/{id}       - Update custom workout
DELETE /api/v1/workouts/{id}       - Delete custom workout
GET    /api/v1/workouts/{user_id}  - List all workouts
```
- **Repository method**: `createCustomWorkout()` in `workout_repository.dart`
- **Generation method**: `manual` with `generation_source: custom_builder`

#### 3. Training Days (1-7 Days Supported)
- **Backend validation**: `days_per_week: int = Field(default=4, ge=1, le=7)` in `models/user.py`
- **UI**: `workout_days_sheet.dart` shows all 7 days as selectable buttons
- **No artificial limit**: Users can select Mon-Sat (6 days) or all 7 days
- **Smart presets**: Detects "Weekdays", "Weekends", "Every day" patterns

#### 4. Program Flexibility (Not Forced Programs)
- **8 built-in splits**: Full Body, Upper/Lower, Push/Pull/Legs, PHUL, Arnold, HYROX, Bro Split
- **Custom option**: Free-text description of training goal
- **Examples**: "Train for HYROX competition", "Build explosive power for basketball"
- **Stored in**: `custom_program_description` field in user preferences

#### 5. Advanced User Features
- **Custom Exercises**: Create simple or composite (supersets, giant sets, complexes)
- **Skill Progressions**: 7 chains including Dragon Squats, Handstand Pushups, One-arm Pullups, Front Lever, Planche
- **1,681 exercises**: Comprehensive library with video/image assets
- **Composite exercises**: Build supersets, compound sets, giant sets, complexes, hybrids
- **Saved workouts**: Save, schedule, and reuse workouts from social feed
- **Program history**: Restore any previous program configuration

**Files:**
- `screens/workout/custom_workout_builder_screen.dart` - Custom workout UI
- `screens/custom_exercises/custom_exercises_screen.dart` - Custom exercise management
- `screens/settings/widgets/workout_days_sheet.dart` - 7-day selector
- `screens/home/widgets/edit_program_sheet.dart` - 4-step program customization
- `backend/api/v1/workouts/crud.py` - Workout CRUD endpoints
- `backend/models/user.py` - days_per_week validation (1-7)

**Tests:**
- `test_customize_program.py` - Program customization validation
- `test_custom_exercises.py` - Custom exercise CRUD tests

---

## User-Facing Features

### 1. Authentication & Onboarding (28 Features)

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| Google/Apple Sign-In | Yes | Yes | Yes |
| Onboarding Flow | Yes | Yes | Yes |
| Coach Selection | Yes | Yes | Yes |
| Custom Coach Creator | Yes | Yes | Yes |
| Pre-Auth Quiz | Yes | Yes | Yes |

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Google Sign-In | OAuth authentication with Google | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | App Launch → Sign In → Google Sign-In |
| 2 | Apple Sign-In | Coming soon | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | App Launch → Sign In → Apple Sign-In |
| 3 | Language Selection | English, Telugu (coming soon) | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Settings → Language |
| 4 | 6-Step Onboarding | Personal Info, Body Metrics, Fitness Background, Schedule, Preferences, Health | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | Partially Implemented | User | First Launch → Onboarding Flow |
| 5 | Pre-Auth Quiz | 9-screen comprehensive quiz collecting goals, fitness level, activity level, body metrics with 2-step weight goal (direction + amount), schedule, equipment, training preferences, sleep quality, obstacles, nutrition goals, dietary restrictions, fasting interest, and motivations | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | App Launch → Get Started → Quiz |
| 6 | Mode Selection | Standard vs Senior mode | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Age Check → Mode Selection |
| 7 | Timezone Auto-Detect | Automatic timezone detection and sync | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | Dev | Automatic on app start |
| 8 | User Profile Creation | Goals, equipment, injuries configuration | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Onboarding → Profile Setup |
| 9 | Animated Stats Carousel | Welcome screen with app statistics | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Welcome Screen → Stats Display |
| 10 | Auto-Scrolling Carousel | Pause-on-interaction feature | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Welcome Screen → Auto-scroll |
| 11 | Step Progress Indicators | Visual step tracking during onboarding | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Onboarding → Progress Bar |
| 12 | Exit Confirmation | Dialog to confirm leaving onboarding | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Active Workout → Back → Confirm Exit |
| 13 | Coach Selection Screen | Swipeable horizontal PageView with 5 predefined AI coach personas (Coach Mike, Dr. Sarah, Sergeant Max, Zen Maya, Hype Danny) showing sample messages and personality traits. Direct navigation to home after selection (skips conversational onboarding) | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Coach Selection → Home |
| 14 | Custom Coach Creator | Build your own coach with name, avatar, style, personality traits | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Coach Selection → Create Custom |
| 15 | Coach Personas | Alex (Motivator), Sam (Scientist), Jordan (Drill Sergeant), Taylor (Yogi), Morgan (Buddy) | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Coach Selection → Persona Cards |
| 16 | Coaching Styles | Encouraging, Scientific, Tough Love, Mindful, Casual | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Coach Selection → Style Selection |
| 17 | Personality Traits | Multi-select: Patient, Challenging, Detail-oriented, Flexible, etc. | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Coach Selection → Traits Selection |
| 18 | Communication Tones | Formal, Friendly, Casual, Motivational, Professional | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Coach Selection → Tone Selection |
| 19 | Paywall Features Screen | 3-screen flow highlighting premium benefits | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Post-Onboarding → Paywall Features |
| 20 | Paywall Pricing Screen | Monthly/yearly toggle with RevenueCat integration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Paywall Features → Pricing |
| 21 | Personalized Preview | AI-generated workout preview based on onboarding answers | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Quiz Complete → Plan Preview |
| 22 | Onboarding Flow Tracking | coach_selected, paywall_completed, onboarding_completed flags | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend tracking |
| 23 | Conversational AI Onboarding | Chat-based fitness assessment (DEPRECATED - now uses enhanced pre-auth quiz that collects all data upfront) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Deprecated | User | Onboarding → AI Chat Flow |
| 24 | Quick Reply Detection | Smart detection of user quick reply selections | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Onboarding → Chat → Quick Replies |
| 25 | Language Provider System | Multi-language support with provider pattern | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | Dev | Backend system |
| 26 | Senior Onboarding Mode | Larger UI and simpler flow for seniors | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Onboarding → Senior Mode |
| 27 | Equipment Selection with Details | Pick equipment with quantities and weights during onboarding | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Onboarding → Equipment Selection |
| 28 | Environment Selection | Choose workout environment (gym, home, outdoor, etc.) | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Environment Selection |
| 29 | Two-Step Weight Goal | User selects direction (Lose/Gain/Maintain) then amount in kg/lbs with automatic goal weight calculation | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Quiz → Body Metrics → Weight Goal |
| 30 | Weight Projection Screen | Visual timeline showing weekly weight milestones leading to goal, with maintain mode showing benefits instead of projection chart | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Quiz → Weight Projection |
| 31 | Activity Level Selection | Sedentary/Light/Moderate/Very Active levels for TDEE calculation in fitness level screen | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Quiz → Fitness Level → Activity Level |
| 32 | Sleep Quality Selection | Poor/Fair/Good/Excellent sleep quality tracking for recovery-aware recommendations | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Quiz → Training Preferences → Sleep |
| 33 | Obstacles Selection | Multi-select up to 3 obstacles (Time/Energy/Motivation/Knowledge/Diet/Access) for targeted AI tips | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Quiz → Training Preferences → Obstacles |
| 34 | Dietary Restrictions | Multi-select dietary restrictions (Vegetarian/Vegan/Gluten-free/Dairy-free/Keto/etc.) for meal planning | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Quiz → Nutrition Goals → Dietary |
| 35 | Coach Profile Cards | Enhanced coach cards with gradient headers, sample messages showing communication style, personality trait chips, and selection badges | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Coach Selection → Swipe Cards |
| 36 | Streamlined Onboarding Flow | Pre-Auth Quiz → Weight Projection → Preview → Sign In → Coach Selection → Home (skips conversational onboarding) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Full onboarding journey |
| 37 | Preferences API Endpoint | POST endpoint to save all quiz data to backend after coach selection (fire-and-forget for fast navigation) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend API |

### 2. Home Screen (43 Features)

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| Home Dashboard | Yes | Yes | Yes |
| Streak Badge | Yes | Yes | Yes |
| Quick Actions | Yes | Yes | Yes |
| Layout Editor | Yes | Yes | Yes |
| All 26 Tile Types | Yes | Yes | Yes |

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Time-Based Greeting | Good morning/afternoon/evening | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Home → Greeting Header |
| 2 | Streak Badge | Fire icon with current streak count | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Streak Counter |
| 3 | Quick Access Buttons | Log workout, meal, measurement, view challenges | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Quick Actions Row |
| 4 | Next Workout Card | Preview of upcoming workout | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Next Workout Tile |
| 5 | Weekly Progress | Visualization of weekly completion | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Weekly Progress Tile |
| 6 | Weekly Goals | Goals and milestones tracking | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Weekly Goals Tile |
| 7 | Upcoming Workouts | List of next 3 workouts | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Upcoming Workouts Tile |
| 8 | Generation Banner | AI workout generation progress | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Generation Status Banner |
| 9 | Pull-to-Refresh | Refresh content by pulling down | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Pull Down |
| 10 | Program Menu | Modify current program settings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Program Button → Menu |
| 11 | Library Quick Access | Chip button to exercise library | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Home → Library Chip |
| 12 | Notification Bell | Badge with unread count | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | User | Home → Top Right → Bell Icon |
| 13 | Daily Activity Status | Rest day vs Active day indicator | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Activity Status Tile |
| 14 | Empty State | CTA to generate workouts when none exist | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → No Workouts State |
| 15 | Senior Home Variant | Larger UI for accessibility | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | User | Home (Senior Mode) |
| 16 | Mood Picker Card | Quick mood check-in with 4 options (Great/Good/Tired/Stressed) for instant workout generation | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Mood Picker Tile |
| 17 | Fitness Score Card | Compact card showing overall/strength/nutrition scores with tap to view details | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Fitness Score Tile |
| 18 | Context Logging | Track user interactions (mood selections, score views) for AI personalization | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 19 | My Space Button | Opens layout editor to customize home screen tiles (replaces Edit button) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Top Right → My Space Icon |
| 20 | Layout Editor Screen | Drag-and-drop reordering of home screen tiles with visibility toggles | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → My Space → Editor |
| 21 | Multiple Layouts | Save different layouts (Morning Focus, Full Dashboard, etc.) and switch between them | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → My Space → Layouts List |
| 22 | Layout Templates | Pre-built templates (Minimalist, Performance, Wellness, Social) users can apply | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → My Space → Templates |
| 23 | Tile Size Options | Full, Half, or Compact size for each tile with 2-column grid for half-width | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → My Space → Tile Settings |
| 24 | Tile Picker Sheet | Bottom sheet to add new tiles organized by category (Workout, Progress, Nutrition, Social, etc.) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → My Space → Add Tile |
| 25 | Template Picker Sheet | Browse and apply system templates with preview cards | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → My Space → Apply Template |
| 26 | Dynamic Tile Rendering | TileFactory builds widgets based on TileType with Consumer patterns for data | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Home → Tile Display |
| 27 | Layout Sharing | Generate preview images of layouts and share to Instagram Stories/System Share/Gallery | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → My Space → Share Layout |
| 28 | 34 Tile Types | nextWorkout, fitnessScore, moodPicker, dailyActivity, quickActions, weeklyProgress, weeklyGoals, weekChanges, upcomingFeatures, upcomingWorkouts, streakCounter, personalRecords, aiCoachTip, challengeProgress, caloriesSummary, macroRings, bodyWeight, progressPhoto, socialFeed, leaderboardRank, fasting, weeklyCalendar, muscleHeatmap, sleepScore, restDayTip, myJourney, progressCharts, roiSummary, weeklyPlan, **weightTrend**, **dailyStats**, **achievements**, **heroSection**, **quickLogWeight**, **quickLogMeasurements**, **habits** | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Home → Various Tiles |
| 29 | Layout Activity Logging | Track layout creates, updates, activations, deletes for user analytics | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 30 | Default Layout Migration | Automatic creation of default layout when no layouts exist for user | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 31 | My Journey Card | Fitness journey progress tile showing milestones (Getting Started → Legend), progress bars, streak, and weekly stats | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → My Journey Tile |
| 32 | Journey Milestones | 8-level progression system: Getting Started (0), Beginner (5), Building Habit (15), Consistent (30), Dedicated (50), Athlete (100), Champion (200), Legend (500) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → My Journey → Milestones |
| 33 | Journey Half-Size Tile | Compact My Journey card variant for half-width grid display | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → My Journey (Compact) |
| 34 | Weight Trend Tile | Shows weekly weight change with trend arrow (green down for fat loss, red up for gain) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Weight Trend Tile |
| 35 | Daily Stats Tile | Shows steps from HealthKit/Google Fit and calorie deficit/surplus calculation | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Daily Stats Tile |
| 36 | Achievements Tile | Shows recent achievement earned and progress to next milestone with tier colors | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Achievements Tile |
| 37 | Quick Log Weight Tile | Inline weight logging with last weight display and one-tap log button | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Quick Log Weight Tile |
| 38 | Quick Log Measurements Tile | Shows waist, chest, hips measurements with last update and quick update button | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Quick Measurements Tile |
| 39 | Habits Tile | Today's habits checklist with quick toggle completion and progress indicator (X/Y done) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Habits Tile |
| 40 | Swipeable Hero Section | Main focus card that swipes between workout/nutrition/fasting modes with rest day improvements | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Hero Section |
| 41 | Rest Day Improvements | Motivational messages, activity suggestions (stretch/walk/yoga), and quick action buttons on rest days | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Rest Day Card |
| 42 | Edit Button in Header | Quick access to layout edit mode from home screen header | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Header → Edit Icon |
| 43 | Settings Customize Home | Customize Home option in settings that navigates to edit mode | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings → Customize Home |

### 3. Workout Generation & Management (69 Features)

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| Workout Generation | 4/month | Daily | Unlimited |
| Edit Workouts | - | Yes | Yes |
| Save as Template | - | - | Yes |
| Import Workouts | - | Yes | Yes |
| Save Favorites | - | 5 max | Unlimited |

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Monthly Program Generation | AI-powered 4-week workout plans | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Home → Generate Program |
| 2 | Weekly Scheduling | Automatic workout distribution | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | Dev | Home → Program → Schedule |
| 3 | On-Demand Generation | Single workout generation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Home → Quick Workout |
| 4 | Progressive Overload | Automatic difficulty progression | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | Dev | Automatic in generation |
| 5 | Holiday Naming | Creative themed workout names | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Automatic in generation |
| 6 | Equipment Filtering | Filter exercises by available equipment with quantities and weights | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Settings → Training → My Equipment |
| 7 | Injury-Aware Selection | Avoid exercises based on injuries | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Settings → Training → Muscles to Avoid |
| 7b | Fitness-Level Exercise Filter | Filter exercises by difficulty ceiling (beginners get easy exercises only, intermediates get easy-medium, advanced get all) | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 7c | Fitness-Level Workout Parameters | Scale sets/reps for fitness level: beginners get max 3 sets, 6-12 reps with extra rest; intermediates get up to 5 sets, 4-15 reps; advanced get no limits | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 7d | Fitness-Level Edge Case Handling | Validates fitness levels (None/empty/typos default to intermediate), caps quick workout intensity at user level, workout modifier respects ceilings, fallback exercises use level-appropriate params | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 7e | Fitness-Level Derived Difficulty | Derives workout difficulty from fitness level when intensity_preference not set: beginners get 'easy' (not 'medium'), intermediate gets 'medium', advanced gets 'hard'. Sent to Gemini API for appropriate workout generation | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 8 | Goal-Based Customization | Workouts tailored to user goals | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Onboarding → Goals / Settings |
| 9 | Focus Area Targeting | Target specific muscle groups with strict enforcement | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Home → Program Menu → Edit |
| 10 | Difficulty Adjustment | Beginner/Intermediate/Advanced | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Program Menu → Edit → Difficulty |
| 11 | Program Duration | 4, 8, or 12 week programs | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Partially Implemented | User | Home → Program Menu → Edit → Duration |
| 12 | Workout Regeneration | Regenerate workouts with new preferences | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Home → Program Menu → Regenerate |
| 13 | Drag-and-Drop Rescheduling | Move workouts between days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | User | Schedule → Drag Workout |
| 14 | Calendar View - Agenda | List view of scheduled workouts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Schedule → Agenda View |
| 15 | Calendar View - Week | 7-day grid view | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Schedule → Week View |
| 16 | Edit Program Sheet | Modify preferences mid-program (days, equipment, difficulty) with info tooltip explaining regeneration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Program Menu → Edit Program |
| 16a | Program Menu Button | Home screen "Program" button with dropdown menu for quick access to program options | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Program Button |
| 16b | Quick Regenerate | One-tap regeneration of workouts using current settings, skips the 4-step wizard | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Program Menu → Quick Regenerate |
| 16c | Program Reset Analytics | Backend logging of program resets for analytics (activity_type: program_quick_reset) | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 17 | Exercise Swap | Replace exercises in a workout | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | User | Active Workout → Exercise → Swap |
| 18 | Workout Preview | View workout before starting | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Workout Card → View Details |
| 19 | Exercise Count | Number of exercises displayed | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Workout Preview → Exercise Count |
| 20 | Duration Estimate | Estimated workout time | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Partially Implemented | User | Workout Preview → Duration |
| 21 | Calorie Estimate | Estimated calories burned | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Partially Implemented | User | Workout Preview → Calories |
| 22 | Environment-Aware Generation | AI uses workout environment context for exercise selection | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 23 | Detailed Equipment Integration | AI uses equipment quantities and weight ranges for recommendations | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 24 | Training Split Enforcement | PPL, Upper/Lower, Full Body, PHUL, Bro Split - strictly followed by AI | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Settings → Training → Training Split |
| 25 | Balanced Muscle Distribution | Automatic rotation of focus areas prevents over-training any muscle group | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 26 | Superset Support | Back-to-back exercises with no rest (antagonist, compound, pre-exhaust) with visual grouping and easy manual pairing | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Supersets |
| 26a | Easy Superset Creation | Create supersets from exercise menu with "Create Superset" and "Pair with Next Exercise" options | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Exercise Menu → Create Superset |
| 26b | Superset Preferences | Enable/disable supersets, prefer antagonist pairs, set max pairs per workout, configure rest times | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Training → Supersets |
| 26c | Favorite Superset Pairs | Save and reuse favorite exercise pairings with pairing type and notes | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Training → Supersets → Favorites |
| 26d | Superset Suggestions | AI-powered superset suggestions based on workout structure and antagonist muscle pairing | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Superset Suggestions |
| 26e | Superset History Tracking | Track completed supersets with duration, pairing type, and time savings | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 26f | Superset Context Logging | Log superset events (created, completed, removed, preferences changed) for AI learning | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 26g | Superset Analytics | View superset stats: total completed, favorite pairs, most used pairing type, time saved | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Training → Supersets → Stats |
| 26h | Remove from Superset | Option to ungroup exercises from a superset during active workout | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Exercise Menu → Remove from Superset |
| 27 | AMRAP Finishers | "As Many Reps As Possible" finisher sets with timer | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Partially Implemented | User | Active Workout → AMRAP Sets |
| 28 | Set Type Tracking | Working, warmup, failure, AMRAP set types | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Set Types |
| 29 | Drop Sets | Reduce weight and continue without rest with visual badges and weight calculation | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Drop Set |
| 30 | Giant Sets | 3+ exercises performed consecutively | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Giant Sets |
| 31 | Rest-Pause Sets | Brief rest mid-set to extend volume | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Rest-Pause |
| 32 | Compound Sets | Two exercises for same muscle group back-to-back | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Compound Sets |
| 33 | Dynamic Warmup Generator | AI-generated warmup based on workout and injuries | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Workout Start → Warmup |
| 34 | Injury-Aware Warmups | Modified warmup routines for users with injuries | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | Dev | Workout Start → Warmup |
| 35 | Cooldown Stretch Generator | AI-generated stretches based on muscles worked | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Workout End → Stretches |
| 36 | RPE-Based Difficulty | Rate of Perceived Exertion targeting (6-10 scale) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → RPE Input |
| 37 | 1RM Calculation | One-rep max calculation using Brzycki formula | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Active Workout → 1RM Calculator |
| 38 | Estimated 1RM Display | Show calculated 1RM during logging | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → 1RM Display |
| 39 | Percentage-Based Training | Train at a percentage of 1RM (50-100%) with global/per-exercise settings | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Training → Intensity |
| 40 | My 1RMs Screen | View, add, edit, delete stored 1RMs grouped by muscle | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Training → My 1RMs |
| 41 | Training Intensity Selector | Slider to set global intensity (50-100%) with visual descriptions | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Training → Intensity Slider |
| 42 | Auto-Populate 1RMs | Calculate 1RMs from workout history using Brzycki formula | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Training → My 1RMs → Auto-Calculate |
| 43 | Per-Exercise Intensity Override | Set different intensity percentages for specific exercises | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Training → My 1RMs → Override |
| 44 | Equipment-Aware Weight Rounding | Round working weights to equipment increments (barbell 2.5kg, dumbbell 2kg, machine 5kg) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 45 | RPE to Percentage Conversion | Convert Rate of Perceived Exertion (6-10) to 1RM percentage | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 46 | Fitness Glossary | 40+ fitness terms with definitions | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Settings → Glossary |
| 40 | Workout Sharing Templates | 4 templates: social, text, detailed, minimal | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Workout Complete → Share |
| 41 | Exercise Notes | Add personal notes to exercises during workout | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Exercise → Notes |
| 42 | Failure Set Tracking | Track sets to muscular failure | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Mark Failure |
| 43 | Hydration During Workout | Log water intake mid-workout | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | User | Active Workout → Hydration Button |
| 44 | Adaptive Rest Periods | Rest times adjusted based on exercise type and intensity | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Active Workout → Rest Timer |
| 45 | Workout Difficulty Rating | Post-workout difficulty feedback (1-5 scale) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → Rating |
| 46 | Mobility Workout Type | Dedicated stretching, yoga, and flexibility workouts | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Home → Quick Workout → Mobility |
| 47 | Recovery Workout Type | Low-intensity active rest workouts for deload/recovery days | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Home → Quick Workout → Recovery |
| 48 | Hold Seconds Display | Shows static hold duration for stretches (e.g., "45s hold") | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Hold Timer |
| 49 | Unilateral Exercise Support | Single-arm/single-leg exercises with "Each side" indicator | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Each Side Indicator |
| 50 | Yoga Pose Generation | AI generates yoga-style poses for mobility workouts | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Mobility Workout → Yoga Poses |
| 51 | Dynamic Mobility Drills | AI generates dynamic stretches like leg swings, arm circles | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Mobility Workout → Dynamic Stretches |
| 52 | Body Area Flexibility Tracking | Track progress by body area (hips, shoulders, spine, etc.) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Flexibility |
| 53 | Unilateral Progress Analytics | Track single-side exercise sessions and variety | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Unilateral Stats |
| 54 | Workout Type Selection UI | Choose workout type (strength, cardio, mixed, mobility, recovery) - now affects RAG exercise selection | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Home → Program Menu → Edit → Type |
| 55 | Mood-Based Workout Generation | AI generates 15-30 min workouts tailored to user mood (Great→High intensity, Tired→Recovery) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Mood Picker → Generate |
| 56 | Mood-to-Workout Mapping | Great→High/HIIT, Good→Mixed, Tired→Recovery/Mobility, Stressed→Cardio/Flowing | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Home → Mood Picker → Generate |
| 57 | SSE Streaming Generation | Server-Sent Events for real-time workout generation progress feedback | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Backend system |
| 58 | Mood Check-in Logging | Track mood selections and correlate with workout completions for pattern analysis | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Home → Mood Picker → Log |
| 59 | Mood History Screen | View full history of mood check-ins with workout info, grouped by date | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Mood Picker → View History |
| 60 | Mood Analytics Dashboard | Summary stats, mood distribution, streaks, and AI recommendations | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Mood Picker → Analytics |
| 61 | Mood Pattern Analysis | Track mood by time-of-day and day-of-week with dominant mood detection | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Home → Mood Picker → Patterns |
| 62 | Mood Streak Tracking | Current and longest mood check-in streaks with visual display | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Mood Picker → Streak |
| 63 | Mood-Based Recommendations | AI-generated suggestions based on mood patterns (fatigue, stress levels) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Mood Picker → Recommendations |
| 64 | Today's Mood Check-in | API to get user's mood for today via database view | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Home → Mood Picker |
| 65 | Mood Workout Completion | Mark mood-generated workouts as completed from history | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Mood History → Complete |
| 66 | Preference Enforcement in Generation | Avoided exercises, avoided muscles, and staple exercises are fetched and passed to Gemini with explicit constraint instructions | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 67 | Post-Generation Preference Validation | Secondary filtering of AI-generated exercises to remove any that match avoided exercises or muscles (case-insensitive) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 68 | Extend Workout / Do More | Add 1-6 additional AI-generated exercises to completed workout, respecting same muscle focus and user preferences | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → Do More |
| 69 | Custom Workout Builder | Create workout from scratch with exercise search, drag-and-drop reordering, and set/rep/weight configuration | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | User | Home → Create Workout |
| 70 | Universal 1RM Weight Application | All workout generation endpoints (single, streaming, mood, weekly, monthly) apply user's stored 1RM data to calculate personalized working weights | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 71 | Historical Weight Integration | Generated workouts use actual weights from completed workouts and imported history for exercise-specific recommendations | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 72 | Target Muscle Warmup Logging | Warmups/stretches store target muscles for debugging and visibility (target_muscles JSONB column) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 73 | Equipment-Specific Weight Rounding | Working weights are rounded to realistic plate increments per equipment type (barbell 2.5kg, dumbbell 2kg, machine 5kg, kettlebell 4kg) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 74 | Fuzzy Exercise Name Matching | 1RM data matches exercises even with variations (e.g., "Bench Press" matches "Barbell Bench Press") | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 75 | Full Gym Equipment Support | 23+ equipment types including machines (leg press, hack squat, cable machines), free weights, and specialty equipment | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Settings → Training → Equipment |
| 76 | Detailed Equipment Weights | Users can specify exact weights available for each equipment type for precise workout recommendations | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Training → Equipment → Weights |
| 77 | Readiness Score Integration | Readiness score affects workout generation - lower readiness suggests recovery/mobility, higher readiness enables HIIT/strength | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | In Progress | Dev | Backend system |
| 78 | Mood-Aware Workout Recommendations | AI adjusts exercise intensity, type, and volume based on user's mood selection (Great/Good/Tired/Stressed) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | In Progress | Dev | Backend system |
| 79 | Injury-to-Muscle Mapping | Automatic detection and exclusion of exercises targeting injured muscles during generation | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 80 | User Context Logging for AI | Track user inputs (mood, readiness, preferences) and generation outcomes for continuous AI improvement | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | In Progress | Dev | Backend system |
| 81 | Adaptive Difficulty from Feedback | Exercise ratings (too easy/just right/too hard) actively adjust future workout difficulty | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → Feedback |
| 82 | Feedback Pattern Analysis | System tracks feedback patterns over time to determine appropriate difficulty adjustments | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 83 | Progressive Difficulty Increase | Consistent "too easy" ratings trigger automatic difficulty progression in future workouts | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 84 | Difficulty Regression | Consistent "too hard" ratings cause appropriate regression to prevent overtraining | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 85 | Customizable Warmup Duration | Set preferred warmup length (1-15 minutes) for AI-generated warmup routines | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Warmup & Cooldown → Duration |
| 86 | Customizable Stretch Duration | Set preferred cooldown/stretch length (1-15 minutes) for post-workout stretches | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Warmup & Cooldown → Stretch |

### 3b. Cardio/Endurance Workouts (25 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Cardio Workout Generation | AI generates cardio/HIIT workouts with intervals, intensity, and duration specifications | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | In Progress | User | Home → Cardio Workout |
| 2 | Heart Rate Training Zones (Karvonen) | Calculate HR zones using Karvonen method with heart rate reserve: Target HR = ((Max HR - Resting HR) x %Intensity) + Resting HR | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Cardio → HR Zones |
| 3 | Heart Rate Training Zones (Percentage) | Calculate HR zones using percentage of max HR with Tanaka formula (208 - 0.7 x age): Zone 1-5 ranges | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Cardio → HR Zones |
| 4 | VO2 Max Estimation | Estimate VO2 max using Uth-Sorensen formula: VO2 max = 15.3 x (Max HR / Resting HR) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Cardio → VO2 Max |
| 5 | Fitness Age Calculation | Calculate cardiovascular fitness age based on VO2 max using HUNT Fitness Study methodology | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Cardio → Fitness Age |
| 6 | HR Zones Card Widget | Visual HR zone card with color-coded zones, current zone indicator, zone benefits, and max HR display | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → HR Zones Tile |
| 7 | HR Zones Visualization | Display HR training zones with color-coded bands (Zone 1-5) on charts and during cardio tracking | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Cardio → Zone Display |
| 8 | Cardio Metrics Table | Track cardio workouts with average HR, max HR, duration, distance, calories, zone distribution | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | In Progress | User | Cardio → Metrics |
| 9 | HIIT Workout Type | High-intensity interval training with configurable work/rest intervals and rounds | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Home → Quick Workout → HIIT |
| 10 | Steady-State Cardio | Long, steady-paced cardio workouts with target HR zone maintenance | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Home → Quick Workout → Cardio |
| 11 | Cardio Rest Suggestions | AI suggests optimal rest periods between HIIT rounds based on intensity and recovery HR trends | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | Planned | Dev | Cardio Workout → Rest Suggestions |
| 12 | Cardio Progression Tracking | Track improvement in cardio endurance (VO2 max trends, HR recovery rate, max HR in zone) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | In Progress | User | Progress → Cardio |
| 13 | HR Variability (HRV) Tracking | Read HRV from health devices and use for recovery/readiness assessment | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Health → HRV |
| 14 | Cardio Metrics API | REST API endpoints for HR zones calculation, cardio metrics storage, and history retrieval | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 15 | Custom Max HR Setting | Allow users to set measured max HR instead of calculated (for more accurate zones) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Cardio → Max HR |
| 16 | Cardio Metrics History | Track and display historical cardio fitness data (resting HR trends, VO2 max improvements) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Cardio → History |
| 17 | Real-time Zone Detection | Determine current training zone from live heart rate data during workouts | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | User | Active Cardio → Zone Indicator |
| 18 | Zone Benefit Descriptions | Display training benefits for each HR zone (Recovery, Aerobic Base, Tempo, Threshold, VO2 Max) | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Cardio → Zone Info |
| 19 | Cardio Session Logging | Log cardio sessions with type (running, cycling, swimming, rowing, elliptical, walking), duration, distance, pace, heart rate, and calories | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Home → Log Cardio |
| 20 | Indoor/Outdoor Location Tracking | Track cardio location: Indoor, Outdoor, Treadmill, Track, Trail, Pool, Gym - enables differentiated training analysis | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Log Cardio → Location |
| 21 | Treadmill Run Annotation | Specifically annotate runs as treadmill vs outdoor for accurate training log and pace adjustments | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Log Cardio → Location → Treadmill |
| 22 | Weather Conditions Tracking | Log weather for outdoor cardio (sunny, cloudy, rainy, windy, hot, cold, humid) for performance context | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Log Cardio → Weather |
| 23 | Cardio Session Statistics | Aggregate stats by cardio type and location: total distance, duration, average pace, best performances | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Cardio → Stats |
| 24 | Cardio Patterns in User Context | AI receives user's cardio patterns (preferred locations, outdoor vs treadmill tendencies) for personalized recommendations | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 25 | Cardio-Strength Balance Tracking | Track ratio of cardio to strength workouts with AI suggestions for workout balance | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |

### 3c. Flexibility/Mobility Assessment (18 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Flexibility Assessment System | 10 comprehensive tests (sit-and-reach, shoulder, hip flexor, hamstring, ankle, thoracic, groin, quads, calf, neck) with guided instructions | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Flexibility → Assessment |
| 2 | Age/Gender-Adjusted Norms | Flexibility ratings based on age groups (18-29, 30-39, 40-49, 50-59, 60+) and gender with percentile calculations | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Flexibility → Norms |
| 3 | Assessment Score Calculation | Calculate overall flexibility score (0-100) and per-body-area ratings from assessment results | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Flexibility → Score |
| 4 | Flexibility Progress Tracking | Track flexibility improvements over time with historical comparisons, trend analysis, and rating improvements | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Progress → Flexibility |
| 5 | Flexibility Gap Analysis | Identify areas needing improvement (poor/fair ratings) with prioritized improvement list | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Flexibility → Gap Analysis |
| 6 | Personalized Stretch Recommendations | Rating-specific stretch protocols (poor gets beginner stretches, excellent gets maintenance) with sets, duration, and notes | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Flexibility → Recommendations |
| 7 | Flexibility Progress Charts | Visual line/area charts showing measurement trends, rating changes, and percentile improvements | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Progress → Flexibility Charts |
| 8 | Test Detail Screen | Comprehensive test view with instructions, tips, common mistakes, equipment needed, and recent history | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Flexibility → Test Details |
| 9 | Assessment History Screen | Filterable history view with all past assessments, improvement indicators, and delete functionality | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Flexibility → History |
| 10 | Record Assessment Sheet | Bottom sheet for recording new measurements with quick instructions, validation, and instant feedback | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Flexibility → Record |
| 11 | Higher/Lower Is Better Logic | Tests correctly handle whether higher values (hamstring angle) or lower values (shoulder gap) indicate better flexibility | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 12 | Test Categories by Muscle | Tests organized by target muscle groups (hamstrings, shoulders, hips, calves, neck, thoracic spine) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Flexibility → Categories |
| 13 | Percentile Calculation | Calculate approximate percentile ranking (1-99) based on age/gender norms | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 14 | Improvement Messages | Personalized improvement tips based on current rating (focus areas, expected timeline) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | User | Flexibility → Tips |
| 15 | Flexibility Score Card Widget | Overall score visualization with circular progress, category breakdown, and focus areas | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Flexibility Tile |
| 16 | Assessment Reminders | Periodic reminders (monthly/quarterly) to re-assess flexibility progress | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Planned | User | Notifications → Flexibility |
| 17 | Flexibility-Based Warmup Integration | Use flexibility assessment results to adjust dynamically generated warmup routines | ❌ | ✅ | ✅ | ✅ | ✅ | ❌ | Planned | Dev | Backend system |
| 18 | Stretch Plan Management | View and manage personalized stretch plans generated from assessment results | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Flexibility → Stretch Plan |

### 4. Active Workout Experience (51 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | 3-Phase Structure | Warmup → Active → Stretch | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Active Workout → Phases |
| 2 | Warmup Exercises | 5 standard warmup exercises with timers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Active Workout → Warmup Phase |
| 3 | Set Tracking | Real-time tracking of completed sets | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Set Counter |
| 4 | Reps/Weight Logging | Log reps and weight per set | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Log Input |
| 5 | Rest Timer Overlay | Countdown between sets | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Rest Timer |
| 6 | Skip Set/Rest | Skip current set or rest period | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Skip Button |
| 7 | Previous Performance | View past performance data | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → History Button |
| 8 | Exercise Video | Autoplay exercise demonstration | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Video Display |
| 9 | Exercise Detail Sheet | Swipe up for form cues | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Swipe Up → Details |
| 10 | Mid-Workout Swap | Replace exercise during workout | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Active Workout → Exercise → Swap |
| 11 | Pause/Resume | Pause and resume workout | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | User | Active Workout → Pause Button |
| 12 | Exit Confirmation | Confirm before quitting workout | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Back → Confirm Exit |
| 13 | Elapsed Timer | Total workout time display | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Timer Display |
| 14 | Set Progress Visual | Circles/boxes showing set completion | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Active Workout → Set Circles |
| 15 | 1RM Logging | Log one-rep max on demand | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Log 1RM |
| 16 | 1RM Percentage Display | Show target % of 1RM and actual % during sets | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Weight → %1RM |
| 17 | On-Target Indicator | Color-coded indicator showing if lifting within 5% of target intensity | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Weight → Indicator |
| 18 | Alternating Hands | Support for unilateral exercises (is_unilateral + alternating_hands) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Side Indicator |
| 17 | Challenge Stats | Opponent stats during challenges | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | User | Active Workout → Challenge Mode |
| 18 | Feedback Modal | Post-workout rating and feedback | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → Feedback |
| 19 | PR Detection | Automatic personal record detection | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → PR Badge |
| 20 | Volume Calculation | Total reps × weight | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Workout Complete → Volume Stats |
| 21 | Completion Screen | Stats summary after workout | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete |
| 21a | Performance Comparison | Show improvements/setbacks vs previous sessions for each exercise and overall workout (volume, weight, reps, time) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → Comparison |
| 22 | Social Share | Share workout to social | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | User | Workout Complete → Share |
| 23 | RPE Tracking | Rate of Perceived Exertion (6-10) logging per set | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → RPE Input |
| 24 | RIR Tracking | Reps in Reserve (0-5) logging per set with colored pills (Green/Yellow/Orange/Red) and "X in tank" labels | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → RIR Input |
| 24a | Quick RIR Selector | Post-set 3-option feedback: "Could do more" (RIR 3+), "Just right" (RIR 1-2), "Struggled" (RIR 0) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Complete Set → RIR Sheet |
| 24b | RIR-Based Auto-Weight | Automatic weight adjustment for next set based on logged RIR vs target RIR (±5-15% based on effort) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Complete Set → Weight Adjust |
| 24c | AI-Generated RIR Targets | Backend generates per-set RIR targets based on exercise type (compound vs isolation), fitness level, and progressive fatigue | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | Dev | Backend RAG → set_targets |
| 25 | RPE/RIR Help System | Educational tooltips explaining intensity scales with "in tank" concept explanation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → RPE/RIR → Help |
| 26 | AI Weight Suggestion | Real-time AI-powered weight recommendations during rest | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Rest → Suggestion |
| 27 | Weight Suggestion Loading | Visual loading state during AI processing | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Rest → Loading |
| 28 | Rule-Based Fallback | Fallback weight suggestions when AI unavailable | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 29 | Equipment-Aware Increments | Weight suggestions aligned to real gym equipment | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 30 | Accept/Reject Suggestions | One-tap weight adjustment from AI suggestion | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Rest → Accept/Reject |
| 31 | Timed Exercise Pause | Pause/resume button for timed exercises (planks, wall sits, holds) with timer freezing | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Timed → Pause |
| 32 | Timed Exercise Resume | Resume paused timer from exact pause point with visual feedback | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Timed → Resume |
| 33 | Exercise Transition Countdown | 5-10 second countdown between exercises with "Get Ready" display, next exercise preview, and skip button | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Transition Overlay |
| 34 | Transition Haptic Feedback | Haptic feedback during transition countdown (stronger in last 3 seconds) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Transition → Haptics |
| 35 | Voice Exercise Announcements | Text-to-speech announces "Get ready for [exercise name]" during transitions (user-configurable) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → TTS |
| 36 | Voice Workout Completion | TTS announces "Congratulations! Workout complete!" at end of workout | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → TTS |
| 37 | Exercise Name Expansion | TTS expands abbreviations (DB→dumbbell, BB→barbell, KB→kettlebell, RDL→Romanian deadlift) for clearer speech | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Backend system |
| 38 | Exercise Skip During Workout | Skip any exercise mid-workout without affecting the rest of the session | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Skip Exercise |
| 39 | Per-Exercise Difficulty Rating | Rate each exercise as "too easy", "just right", or "too hard" on workout completion | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → Rate Exercises |
| 40 | Feedback Importance Explanation | Workout completion screen explains how feedback improves future workouts | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Workout Complete → Feedback Info |
| 41 | Voice Rest Period Countdown | TTS announces countdown during rest periods (10, 5, 3, 2, 1 seconds remaining) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Rest → TTS |
| 42 | Dynamic Set Reduction | Remove planned sets mid-workout when fatigued via minus button | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Minus Button |
| 43 | Skip Remaining Sets | "I'm done with this exercise" option to end exercise early with fewer sets | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → End Exercise Early |
| 44 | Edit Completed Sets | Tap completed set to modify reps or weight after logging | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Tap Set → Edit |
| 45 | Delete Completed Sets | Swipe or long-press to remove incorrectly logged sets | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Swipe Set → Delete |
| 46 | Set Adjustment Reasons | Track why sets were reduced (fatigue, time, pain, equipment, other) for analytics | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Active Workout → Reduce → Reason |
| 47 | Fatigue Detection | AI monitors rep decline and RPE patterns to detect workout fatigue | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 48 | Smart Set Suggestions | Proactive suggestion to reduce sets when fatigue detected (>20% rep decline or high RPE) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout → Fatigue Alert |
| 49 | Adjusted Sets Visual | Shows adjusted set count with visual indicator (e.g., "3/5 sets - reduced") | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Set Count Display |
| 50 | Set Adjustment History | Track and display user's set adjustment patterns per exercise | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 51 | Set Adjustment Sheet | Bottom sheet for selecting adjustment reason with optional notes | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout → Reduce → Sheet |

### 5. Exercise Library (34 Features)

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| Exercise Count | 50 | 1,722 | 1,722 |
| HD Videos | Yes | Yes | Yes |
| Search & Filter | Yes | Yes | Yes |
| Favorites | - | Yes | Yes |

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Exercise Database | 1,722 exercises with HD videos | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | User | Library → Exercises |
| 2 | Netflix Carousels | Horizontal scrolling by category with proper error propagation | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Category Carousels |
| 3 | Search Bar | Real-time filtering with debounced context logging | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | User | Library → Search |
| 4 | Multi-Filter System | Body part, equipment, type, goals with usage logging | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | User | Library → Filters |
| 5 | Active Filter Chips | Display selected filters | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Library → Filter Chips |
| 6 | Clear All Filters | Reset all filters at once | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Library → Clear Filters |
| 7 | Exercise Cards | Thumbnails with key info | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Exercise Card |
| 8 | Exercise Detail View | Full exercise information with view logging for AI | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Exercise → Details |
| 9 | Form Cues | Instructions for proper form | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Exercise → Form Tips |
| 10 | Equipment Display | Required equipment shown | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Exercise → Equipment |
| 11 | Difficulty Indicators | Beginner/Intermediate/Advanced | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Exercise → Difficulty |
| 12 | Secondary Muscles | Additional muscles worked | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Exercise → Muscles |
| 13 | Safe Minimum Weight | Recommended starting weight | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Library → Exercise → Min Weight |
| 14 | Exercise History | Past performance tracking | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Exercise → History |
| 15 | Custom Exercises Screen | Dedicated screen to manage user-created exercises | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Custom Content → My Exercises |
| 16 | Create Simple Exercise | Create custom single-movement exercises with name, muscle group, equipment | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Custom Exercises → Create → Simple |
| 17 | Create Combo Exercise | Create composite exercises combining multiple movements (e.g., "Bench Press & Chest Fly") | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Custom Exercises → Create → Combo |
| 18 | Combo Types | Support for superset, compound_set, giant_set, complex, and hybrid combo types | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Custom Exercises → Create → Combo → Type |
| 19 | Component Management | Add/remove/reorder component exercises within combos with per-component reps | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Custom Exercises → Combo → Components |
| 20 | Exercise Search in Creator | Search library exercises when building combos with real-time filtering | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | User | Custom Exercises → Create → Search |
| 21 | Custom Exercise Usage Tracking | Track how often custom exercises are used in workouts | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 22 | Custom Exercise Stats | View total exercises, simple count, combo count, total uses | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Custom Exercises → Stats |
| 23 | Custom Exercise Deletion | Delete custom exercises with confirmation dialog | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Custom Exercises → Delete |
| 24 | Custom Exercise Context Logging | Track creation, usage, and deletion events for analytics | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 25 | Exercise Video Download | Download exercise videos for offline viewing with progress indicator | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Library → Exercise → Download |
| 26 | Video Download Progress | Real-time download progress bar with byte count | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Library → Exercise → Downloading |
| 27 | Cancel Video Download | Cancel in-progress video downloads | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Library → Exercise → Cancel Download |
| 28 | Offline Video Playback | Play cached videos without internet connection | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Library → Exercise → Play Offline |
| 29 | Library Context Logging | Log exercise views, program views, search queries, filter usage for AI learning | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 30 | Differentiated Error Messages | Network, timeout, and API errors show specific helpful messages | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Library → Error States |
| 31 | Error Retry Button | Retry button appears on error states with proper error propagation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Library → Error → Retry |
| 32 | Programs Tab Integration | Browse 12 branded programs in Library → Programs tab | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Programs |
| 33 | Program View Logging | Log program views for AI preference learning | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 34 | Search Query Logging | Debounced search query logging (500ms) for AI learning | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |

**Library Improvements (December 2024):**

**Bug Fixes:**
- Fixed Programs tab to query `branded_programs` table (was incorrectly querying non-existent `programs` table)
- Fixed Netflix carousel silent error handling - now properly throws errors so UI can display retry button
- Removed dead code (`library.py` backend file that was never used/registered)

**Enhanced Error Handling:**
- Network errors show: "Check your internet connection"
- Timeout errors show: "Request timed out. Please try again."
- API errors include HTTP status code for debugging
- All error states now display retry button for user recovery

**User Context Logging for AI Personalization:**
- Exercise views logged when users open exercise detail sheets (helps AI learn preferences)
- Program views logged when users browse programs
- Search queries logged with 500ms debounce to avoid spam
- Filter usage logged to understand user equipment/muscle preferences

### 5b. Skill Progressions (15 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Progression Chains System | 7 skill progression chains with 52 total exercises from beginner to elite | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills |
| 2 | Pushup Mastery Chain | 10-step progression from wall pushups to one-arm pushups | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Pushup Mastery |
| 3 | Pullup Journey Chain | 8-step progression from dead hang to one-arm pullups | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Pullup Journey |
| 4 | Squat Progressions Chain | 8-step progression including dragon squats and pistol squats | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Squat Progressions |
| 5 | Handstand Journey Chain | 8-step progression to freestanding handstand pushups | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Handstand Journey |
| 6 | Muscle-Up Mastery Chain | 6-step progression from high pullups to strict muscle-ups | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Muscle-Up Mastery |
| 7 | Front Lever Chain | 6-step progression from tuck to full front lever | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Front Lever |
| 8 | Planche Chain | 6-step progression from planche lean to full planche | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Planche |
| 9 | Skill Progress Tracking | Track current level, attempts, and best performance per chain | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Progress |
| 10 | Unlock Criteria System | Each step has specific rep/hold/session requirements to unlock next | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Library → Skills → Unlock Criteria |
| 11 | Practice Attempt Logging | Log attempts with reps, sets, hold time, and success status | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Log Attempt |
| 12 | Skills Screen | Browse all progression chains with progress visualization | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills Tab |
| 13 | Chain Detail Screen | Visual skill tree showing locked/unlocked steps with tips | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Chain Details |
| 14 | Category Filtering | Filter progressions by category (pushup, pullup, squat, etc.) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | User | Library → Skills → Filter |
| 15 | Library Integration | Skills tab added to exercise library for easy access | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Library → Skills Tab |

### 5c. Leverage-Based Exercise Progressions (16 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Exercise Variant Chains | 8 progression chains with 52+ leverage-based variants | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Skills → Progressions |
| 2 | User Exercise Mastery Tracking | Track max reps, consecutive "too easy" sessions, mastery status | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 3 | Automatic Progression Suggestions | Suggest harder variants after 2+ "too easy" ratings | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → Level Up Card |
| 4 | Progression Suggestion Cards | Visual cards on workout complete with current vs suggested exercise | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | User | Workout Complete → Suggestions |
| 5 | Accept/Decline Progression | User can accept "Level Up" or decline with cooldown | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → Accept/Decline |
| 6 | Progression History Audit | Track all progression decisions with reasons and timestamps | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 7 | Rep Range Preferences | Users set preferred training focus (Strength 4-6, Hypertrophy 8-12, etc.) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Training → Rep Preferences |
| 8 | Rep Range Slider | Custom min/max rep preferences with quick presets | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Training → Rep Range Slider |
| 9 | "Avoid High-Rep Sets" Toggle | When enabled, caps all exercises at 12 reps maximum | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Training → Avoid High Reps |
| 10 | Progression Style Selector | Choose Leverage First, Load First, or Balanced progression | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Training → Progression Style |
| 11 | Gemini Progression Context | AI receives mastery context and suggests harder variants | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 12 | Leverage-First Prompting | Gemini instructed to prefer exercise difficulty over rep increases | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 13 | Feedback-Mastery Integration | "Too easy" feedback automatically updates mastery tracking | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 14 | Equipment-Aware Suggestions | Progression suggestions respect user's available equipment | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 15 | Mastery Score Calculation | Weighted score based on reps, consistency, and feedback | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 16 | User Context Logging | All progression events logged for analytics and AI learning | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |

### 5d. Weekly Personal Goals / Challenges of the Week (21 Features)

A comprehensive feature allowing users to set weekly challenges like "How many push-ups can I do?" or "500 push-ups this week", track progress, and beat personal records over time.

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Goal Type: single_max | Max reps in one set (e.g., "How many push-ups can I do?") | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 2 | Goal Type: weekly_volume | Total reps throughout the week (e.g., "500 push-ups this week") | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 3 | Goal Creation | Create weekly goals with exercise name, type, and target value | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 4 | Record Attempts | Log max rep attempts for single_max goals with optional notes | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 5 | Add Volume | Add reps to weekly_volume goals manually | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 6 | Workout Auto-Sync | Automatically sync workout reps to matching weekly_volume goals | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Active Workout |
| 7 | Personal Records Tracking | All-time PRs per exercise/goal_type combination | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Profile → PRs |
| 8 | PR Detection | Automatically detect when user beats their personal record | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → PR Badge |
| 9 | Goal History | View historical performance across weeks with progress chart | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 10 | Progress Chart | Line chart showing progress over time with PR markers | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Progress → Flexibility Charts |
| 11 | AI Goal Suggestions | AI-generated suggestions organized by category | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat |
| 12 | Beat Your Records Category | Suggestions based on personal history to improve | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 13 | Popular with Friends Category | Goals that friends are currently doing | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 14 | New Challenges Category | Variety suggestions for new exercises | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Social → Challenges |
| 15 | Goals Screen | Main screen for viewing/managing weekly goals and records | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 16 | Home Screen Card | WeeklyGoalsCard showing active goals count and PRs | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home |
| 17 | Goal Leaderboard | Compare with friends on the same goals | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 18 | Goal Visibility | Private, friends, or public visibility settings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 19 | ISO Week Boundaries | Proper Monday-Sunday week tracking with automatic resets | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 20 | Goal Complete/Abandon | Mark goals as completed or abandoned | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 21 | User Context Logging | Log goal activities for AI coaching context | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |

### 6. Pre-Built Programs (8 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Program Library | Browse 12 branded workout programs from branded_programs table | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Programs |
| 2 | Category Filters | Filter programs by type (strength, cardio) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Programs → Filter |
| 3 | Program Search | Search programs by name | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Programs → Search |
| 4 | Program Cards | Name, duration, difficulty preview with themed gradients | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Programs → Card |
| 5 | Celebrity Programs | Programs from famous athletes | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Library → Programs → Celebrity |
| 6 | Session Duration | Estimated time per session (30-60 min) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Programs → Duration |
| 7 | Start Program | Begin a pre-built program | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Programs → Start |
| 8 | Program Detail | Full program information with goals, duration, difficulty | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Programs → Details |

**12 Branded Programs Available:**
| Program | Category | Difficulty | Description |
|---------|----------|------------|-------------|
| Ultimate Strength | strength | advanced | Heavy compound focus for maximum gains |
| Lean Machine | fat_loss | intermediate | High-intensity cutting program |
| Power Builder | strength | intermediate | Progressive overload strength building |
| Beach Body Ready | fat_loss | intermediate | Summer-ready physique program |
| Functional Athlete | functional | intermediate | Athletic performance training |
| Beginner's Journey | general | beginner | 4-week starter program |
| Home Warrior | home | intermediate | No-gym-required workouts |
| Iron Will | strength | advanced | Mental toughness through lifting |
| Quick Fit | quick | beginner | 20-minute efficient workouts |
| Endurance Engine | cardio | intermediate | Cardio and stamina focus |
| Core Crusher | core | intermediate | Ab and core specialization |
| Strength Foundations | strength | beginner | Foundational strength patterns |

**Programs Tab Bug Fix:**
- Fixed Programs tab to query `branded_programs` table (was incorrectly querying non-existent `programs` table)
- Programs now load correctly in Library → Programs tab

### 7. AI Coach Chat (30 Features)

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| Messages per Day | 10 | 30 | 100 |
| AI Model | GPT-5 nano | GPT-5 mini | GPT-5 mini |
| Chat History | 7 days | 90 days | Forever |
| All AI Agents | Yes | Yes | Yes |
| Voice Input | Yes | Yes | Yes |

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Floating Chat Bubble | Access AI coach from any screen | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Any Screen → Chat Bubble |
| 2 | Full-Screen Chat | Expanded chat interface | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Chat Bubble → Expand |
| 3 | Coach Agent | General fitness coaching | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Chat → @coach |
| 4 | Nutrition Agent | Food and diet advice | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Chat → @nutrition |
| 5 | Workout Agent | Exercise modifications | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Chat → @workout |
| 6 | Injury Agent | Recovery recommendations | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Chat → @injury |
| 7 | Hydration Agent | Water intake tracking | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat → @hydration |
| 8 | @Mention Routing | Direct messages to specific agent | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | Chat → @mention |
| 9 | Intent Auto-Routing | Automatic agent selection via LangGraph | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Chat → Auto-routing |
| 10 | Conversation History | Persistent chat history | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Chat → History |
| 11 | Suggestion Buttons | Common query shortcuts | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | Chat → Suggestions |
| 12 | Typing Indicator | Animated dots while AI responds | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Chat → Typing... |
| 13 | Markdown Support | Rich text formatting | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings → Support |
| 14 | Workout Actions | "Go to Workout" buttons in chat | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | Active Workout |
| 15 | Clear History | Delete chat history | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 16 | Agent Color Coding | Visual distinction per agent | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 17 | RAG Responses | Context-aware responses from history | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | Dev | — |
| 18 | Profile Context | Personalized based on user data | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Profile |
| 19 | Food Image Analysis | Gemini Vision analyzes food photos | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 20 | Quick Reply Suggestions | Contextual reply buttons | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | Fully Implemented | User | — |
| 21 | Similar Questions via RAG | Find related questions from history | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | Fully Implemented | Dev | — |
| 22 | AI Persona Selection | Choose coach personality | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 23 | Quick Workout from Chat | Generate workout from chat | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Active Workout |
| 24 | Unified Context Integration | AI aware of fasting/nutrition/workout | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | Dev | — |
| 25 | Router Graph | LangGraph multi-agent routing | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 26 | Streaming Responses | Real-time token streaming | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 27 | Chat-to-Action | Execute app actions from chat | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | Chat |
| 28 | Exercise Lookup | Search exercise library from chat | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Library → Exercises |
| 29 | Workout Modification | Modify today's workout via chat | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Active Workout |
| 30 | Nutrition Logging via Chat | Log meals by describing in chat | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Backend system |

### 8. Nutrition Tracking (99 Features)

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| Manual Food Logging | - | Yes | Yes |
| Photo Scans per Day | - | 5 | 10 |
| Barcode Scanning | - | Yes | Yes |
| Full Macro Tracking | - | Yes | Yes |
| Micronutrients (40+) | - | Yes | Yes |
| Meal History | - | Yes | Yes |

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Calorie Tracking | Daily calorie count with targets | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 2 | Macro Breakdown | Protein, carbs, fats progress bars | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 3 | Micronutrient Tracking | 40+ vitamins, minerals, fatty acids | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 4 | Three-Tier Nutrient Goals | Floor/Target/Ceiling per nutrient | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 5 | Text Food Logging | Describe meal in natural language | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 6 | Photo Food Logging | AI analyzes food photos with S3 storage and USDA nutrition enhancement | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Backend system |
| 7 | Voice Food Logging | Speech-to-text meal logging | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 8 | Barcode Scanning | Scan packaged foods with fuzzy fallback | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Scan |
| 9 | Meal Types | Breakfast, lunch, dinner, snack | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 10 | AI Health Score | 1-10 rating per meal | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 11 | Goal Alignment | Percentage aligned with goals | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 12 | AI Feedback | Personalized nutrition suggestions | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | Chat |
| 13 | Food Swaps | Healthier alternative recommendations | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | Nutrition |
| 14 | Encouragements | Positive feedback bullets | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 15 | Warnings | Cautionary feedback for concerns | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 16 | Saved Foods | Favorite foods for quick logging | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 17 | Recipe Builder | Create custom recipes | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Recipes → Create |
| 18 | Recipe Sharing | Share recipes publicly | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 19 | Per-Serving Calculations | Auto nutrition per serving | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 20 | Cooking Weight Converter | Raw vs cooked adjustments with 55+ foods | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Log Food |
| 21 | Batch Portioning | Divide recipes into servings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 22 | Daily Summary | Overview of daily intake | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 23 | Weekly Averaging | Average calories across days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 24 | Nutrient Explorer | Deep dive into all micronutrients | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 25 | Pinned Nutrients | Customize tracked nutrients | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 26 | Nutrient Contributors | Foods providing each nutrient | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 27 | Date Navigation | Browse nutrition by date | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 28 | Status Indicators | Low/optimal/high status | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 29 | Confidence Scores | AI estimate confidence | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 30 | Restaurant Mode | Min/mid/max calorie estimates | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 31 | Calm Mode | Hide calories, show quality | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 32 | Food-Mood Tracking | Log mood with meals | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 33 | Nutrition Streaks | Track logging consistency | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 34 | Weekly Goals | Log 5 of 7 days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Weekly Goals Tile |
| 35 | AI Feedback Toggle | Disable post-meal AI tips | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 36 | Nutrition Onboarding | 6-step guided setup | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding Flow |
| 37 | BMR Calculation | Mifflin-St Jeor formula | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 38 | TDEE Calculation | Total Daily Energy Expenditure | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 39 | Adaptive TDEE | Weekly recalculation | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 40 | Weekly Recommendations | AI target adjustments | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 41 | Disliked Foods Tracking | Mark foods to avoid | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 42 | Dietary Restrictions | FDA Big 9 + diet types | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 43 | Diet Type Selection | 12 diet types including vegetarian, vegan, keto, flexitarian, pescatarian, lacto-ovo, part-time veg | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 44 | Diet Info Dialogs | Info (ⓘ) buttons explaining each diet type | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 45 | Flexible Diet Patterns | Custom text input for part-time veg, flexitarian schedules | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 46 | Meal Pattern Selection | 10 patterns: 3 meals, OMAD, IF 16:8/18:6/20:4, religious fasting, custom | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition |
| 47 | Custom Meal Schedule | Text input for custom/religious fasting descriptions | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 48 | Cooking Skill Setting | Beginner to Advanced | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Library → Skills |
| 49 | Budget Preference | Budget-friendly options | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 50 | Cooking Time Preference | Filter by prep time | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 51 | Recipe Import from URL | Import recipes from web | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 52 | AI-Generated Recipes | Generate recipes with AI | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 53 | Training Day Calories | Higher targets on workout days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 54 | Fasting Day Calories | Reduced targets on fasting days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Fasting |
| 55 | AI Recipe Suggestions | Generate personalized recipes based on body type, culture, and diet | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat |
| 56 | Body Type Selection | Ectomorph, Mesomorph, Endomorph, Balanced for metabolic optimization | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 57 | Cuisine Preferences | 20 cuisines (Indian, Italian, Mexican, Japanese, etc.) for recipe suggestions | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 58 | Spice Tolerance | None/Mild/Medium/Hot/Extreme for recipe filtering | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 59 | Recipe Match Scoring | Goal alignment, cuisine match, diet compliance scores (0-100%) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 60 | Meal Type Filtering | Filter recipes by breakfast, lunch, dinner, snack, or any meal | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition |
| 61 | Recipe Save & Rate | Save favorite recipes and rate with 1-5 stars | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 62 | Mark as Cooked | Track which recipes you've actually made | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 63 | Recipe Preferences Sheet | Bottom sheet to configure body type, cuisines, spice tolerance | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 64 | Recipe Suggestion Reasons | AI explains why each recipe matches your preferences | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 65 | Frequent Foods Quick Log | One-tap re-logging of most-used foods | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Log Food |
| 66 | Recent Foods List | Last 20 logged foods for quick access | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Log Food |
| 67 | Smart Food Suggestions | Time-of-day aware meal suggestions | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Log Food |
| 68 | Barcode Fuzzy Fallback | Alternative products when barcode not found | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Scan |
| 69 | Barcode Cache | 24-hour caching of barcode lookups | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | — |
| 70 | Missing Barcode Report | User reports of unavailable barcodes | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Scan |
| 71 | Manual Barcode Match | Match scanned barcode to alternative | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Scan |
| 72 | Ingredient Inflammation Analysis | AI-powered barcode ingredient analysis for inflammatory properties | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Scan |
| 73 | Color-Coded Inflammation Display | RED inflammatory, GREEN anti-inflammatory ingredient highlighting | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Scan |
| 74 | Inflammation Score | Overall product inflammation score (1=healthy, 10=inflammatory) | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Scan |
| 75 | Inflammation Scan History | Track user's barcode scan history with inflammation data | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → History |
| 76 | Inflammation Scan Favorites | Favorite/unfavorite scanned products | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → History |
| 77 | Inflammation Scan Notes | Add personal notes to scanned products | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → History |
| 78 | Inflammation Statistics | User's aggregated inflammation scan stats | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Stats |
| 79 | Barcode Inflammation Cache | 90-day caching of barcode inflammation analyses | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | — |
| 80 | AI Inflammation Recommendations | Personalized recommendations based on product ingredients | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Scan |
| 81 | Goals Visibility - Header | Compact macro targets (P/C/F) in nutrition screen header | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 82 | Goals Visibility - Card | Dedicated NutritionGoalsCard with circular progress rings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 83 | Portion Size Editing | Quick presets (½, ¾, 1x, 1¼, 1½, 2x) + custom % input | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Nutrition → Log Food |
| 84 | Real-time Nutrition Preview | Live calorie/macro calculation as portion is adjusted | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Nutrition → Log Food |
| 85 | Weekly Check-in Reminders | Toggle for weekly target review prompt with auto-trigger | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Settings |
| 86 | Food Image S3 Storage | Store food photos in S3 with parallel upload (no user delay) | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 87 | Image Portion Editing | Weight/count fields (weight_g, unit, count, weight_per_unit_g) for image-based portion adjustment | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Nutrition → Log Food |
| 88 | USDA Nutrition Enhancement | Parallel USDA FoodData Central API lookup for accurate nutrition data | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 89 | MacroFactor-Style TDEE | EMA-smoothed weight trends with confidence intervals (±X cal) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 90 | TDEE Confidence Display | Shows "2,150 ±120 cal" format with data quality indicator | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 91 | Metabolic Adaptation Detection | Detects TDEE drops >10% indicating metabolic slowdown | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 92 | Plateau Detection | Detects <0.2kg change over 3+ weeks despite deficit | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 93 | Adherence Tracking | Per-macro adherence % (Calories 40%, Protein 35%, Carbs 15%, Fat 10%) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 94 | Sustainability Score | Overall sustainability rating (High/Medium/Low) based on adherence + consistency | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 95 | Multi-Option Recommendations | Choose between Aggressive/Moderate/Conservative target options | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 96 | Diet Break Suggestions | Auto-suggests 1-2 week maintenance phase when adaptation detected | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 97 | Refeed Day Suggestions | Auto-suggests high-carb refeed days for moderate adaptation | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 98 | Weight Trend Analysis | EMA-smoothed weight direction (losing/gaining/stable) with weekly rate | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition → Weekly Check-in |
| 99 | Adaptive TDEE Context Logging | Full event tracking for analytics and AI personalization | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |

### 9. Hydration Tracking (8 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Daily Water Goal | Default 2500ml target | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Hydration |
| 2 | Quick Add Buttons | 8oz, 16oz, custom amounts | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 3 | Drink Types | Water, protein shake, coffee | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 4 | Progress Bar | Visual progress display | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Progress |
| 5 | Goal Percentage | Percentage of goal reached | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 6 | History View | Browse by date | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 7 | Workout-Linked | Associate with workouts | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Active Workout |
| 8 | Entry Notes | Add notes per entry | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |

### 9B. Simple Habit Tracking (35 Features) - NEW

Track daily habits beyond workouts - like "no DoorDash," "eat healthy," "walk 10k steps." Build and break habits with streak tracking, templates, and AI suggestions.

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Habit Dashboard | Main screen showing today's habits with progress | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Habits |
| 2 | Positive Habits | Track habits to build (drink water, meditate, exercise) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits → Add |
| 3 | Negative Habits | Track habits to break (no DoorDash, no sugar, no alcohol) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits → Add |
| 4 | Daily Frequency | Habits tracked every day | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 5 | Weekly Frequency | Habits tracked X times per week | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 6 | Specific Days | Habits for specific days (M/W/F only) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 7 | Quantitative Habits | Habits with targets (8 glasses, 10000 steps) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | One-Tap Completion | Quick toggle to mark habit complete/incomplete | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits |
| 9 | Current Streak | Track consecutive days completed | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 10 | Best Streak | Track longest streak ever | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 11 | Auto Streak Reset | Streak resets on missed day | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 12 | Category Organization | Organize by Nutrition, Activity, Health, Lifestyle | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 13 | Category Filter | Filter habits by category | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Habits |
| 14 | Habit Templates | 16+ pre-built habits (water, steps, meditate, no sugar) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits → Templates |
| 15 | Quick Template Add | Create habit from template with one tap | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 16 | Custom Habit Creation | Create habits with name, icon, color, target | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits → Create |
| 17 | Custom Icons | 20+ icons (water, run, meditate, book, etc.) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 18 | Custom Colors | 15+ color options for habits | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 19 | Habit Reminders | Set reminder time for each habit | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 20 | Swipe to Archive | Swipe left to archive habit | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits |
| 21 | Swipe to Delete | Swipe right to permanently delete | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits |
| 22 | Edit Habit | Modify habit details after creation | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits → Tap → Edit |
| 23 | Habit Reordering | Drag to reorder habits | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits |
| 24 | Weekly Summary View | 7-day completion breakdown per habit | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits → Summary |
| 25 | Completion Rate | 7-day completion percentage | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 26 | Home Screen Card | Compact widget showing today's habits | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home |
| 27 | Quick Toggle from Home | Toggle habits directly from home card | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home |
| 28 | All Complete Celebration | Visual feedback when all habits completed | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 29 | Streak Highlight | Display longest current streak on home | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home |
| 30 | Progress Indicator | Circular progress showing today's completion | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 31 | AI Habit Suggestions | Gemini suggests habits based on goals | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | In Development | User | Habits → AI Suggest |
| 32 | AI Insights | Weekly AI-generated habit insights | ❌ | ✅ | ✅ | ❌ | ✅ | ❌ | In Development | User | Habits → Insights |
| 33 | User Context Logging | Log habit activities for AI coaching | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | In Development | Dev | Backend system |
| 34 | Habit History | View past completions calendar | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits → Tap → History |
| 35 | Archived Habits | View and restore archived habits | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Habits → Archived |

### 10. Intermittent Fasting (65 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Fasting Timer | Start/stop button centered in circular dial | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting → Timer |
| 2 | 12:12 Protocol | Beginner 12 hours fasting, 12 eating | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 3 | 14:10 Protocol | Beginner-friendly 14:10 split | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 4 | 16:8 Protocol | 16 hours fasting, 8 eating | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 5 | 18:6 Protocol | 18 hours fasting, 6 eating | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 6 | 20:4 Warrior Diet | Advanced 20-hour fast | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 7 | OMAD (23:1) | One meal a day protocol | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 8 | 5:2 Diet | 5 normal + 2 fasting days | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 9 | ADF Protocol | Alternate Day Fasting with 25% TDEE | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 10 | 24h Water Fast | Full day water-only fast with warnings | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Hydration |
| 11 | 48h Water Fast | Extended fast requiring medical supervision | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Hydration |
| 12 | 72h Water Fast | 3-day fast with danger warnings | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Hydration |
| 13 | 7-Day Water Fast | Week-long fast requiring strict supervision | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Hydration |
| 14 | Custom Protocols | User-defined fasting/eating windows | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 15 | Dangerous Protocol Warnings | Popup warnings for extended fasts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 16 | Metabolic Zone Tracking | Fed → Fat Burning → Ketosis → Deep Ketosis | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 17 | Zone Visualization | Color-coded fasting stages | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 18 | Zone Notifications | Alerts when entering new zone | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings → Notifications |
| 19 | Fasting Streaks | Track consecutive fasts | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting |
| 20 | Streak Freeze | Forgiveness for missed fasts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 21 | Eating Window Timer | Countdown to window close | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 22 | Smart Meal Detection | Auto-end fast when logging food | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Nutrition |
| 23 | Fasting Day Calories | Reduced targets for 5:2/ADF | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Fasting |
| 24 | Weekly Calorie Averaging | Average across fasting days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 25 | Safety Screening | 6 health questions with risk assessment | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 26 | Colored Yes/No Buttons | Visual safety question responses | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 27 | Safety Warning Popups | Detailed risk explanations with potential side effects | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 28 | Continue After Warning | Allow users to proceed after acknowledging risks | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 29 | Refeeding Guidelines | Breaking fast recommendations | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 30 | Workout Integration | Fasted training warnings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout |
| 31 | Fasting History | View past fasts with % | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting → History |
| 32 | Fasting Statistics | Total hours, avg duration | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting |
| 33 | Mood Tracking | Pre/post fast mood logging | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 34 | AI Coach Integration | Fasting-aware coaching with context | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Chat |
| 35 | User Context Logging | Log fasting activities for AI coaching | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 36 | Extended Fast Safety | Warnings and requirements for 24h+ fasts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 37 | Weekly Goal Mode | 5 of 7 days goal | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 38 | Keto-Adapted Mode | Faster zone transitions | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 39 | Fasting Records List | Paginated history | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Fasting |
| 40 | Partial Fast Credit | >80% = streak maintained | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 41 | Energy Level Tracking | 1-5 scale energy logging | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 42 | Skip Onboarding Option | Skip setup with default 16:8 | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding Flow |
| 43 | Meal Reminders | Notifications for lunch/dinner during eating window | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 44 | Lunch Reminder Time | Configurable lunch reminder hour | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 45 | Dinner Reminder Time | Configurable dinner reminder hour | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 46 | Background Timer | Notifications when closed | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 47 | Centered Start Button | Start fast button in center of timer dial | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 48 | Protocol Difficulty Badges | Visual difficulty indicators (Beginner/Intermediate/Advanced/Expert) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 49 | Fasting Impact Analysis | Analyze how fasting affects goals, weight, and performance | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting → Impact |
| 50 | Weight-Fasting Correlation | Log weight with automatic fasting day detection | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting → Impact → Weight |
| 51 | Fasting Calendar View | Calendar showing fasting days, weight logs, workouts per day | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Fasting → Impact → Calendar |
| 52 | Goal Impact Comparison | Compare goal achievement on fasting vs non-fasting days | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting → Impact |
| 53 | Workout Performance Comparison | Compare workout performance on fasting vs non-fasting days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Fasting → Impact |
| 54 | Correlation Score | Calculate statistical correlation between fasting and goals (-1 to 1) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 55 | AI Fasting Insights | Gemini-generated personalized insights about fasting impact | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Fasting → Impact → Insights |
| 56 | Period Selector | Analyze impact over week/month/3 months | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Fasting → Impact |
| 57 | Weight Trend Chart | Line chart showing weight trend with fasting days highlighted | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Fasting → Impact → Charts |
| 58 | Fasting Impact Cards | Visual comparison cards for fasting vs non-fasting metrics | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Fasting → Impact |
| 59 | Impact Context Logging | Log fasting impact analysis views for AI personalization | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 60 | Weight Logging Sheet | Bottom sheet UI to log weight with fasting correlation | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting → Impact → Log Weight |
| 61 | Mark Historical Fasting Days | Retroactively mark past days as fasting days | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Fasting → Calendar → Tap Day |
| 62 | Weight-Fasting Auto-Detection | Automatically detect if weight log is on a fasting day | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 63 | Fasting Impact API Integration | Real API calls replacing mock data for impact analysis | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 64 | Weight Trend Moving Average | 7-day moving average for weight trend analysis | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 65 | Fasting-Weight Correlation Calculator | Statistical Pearson correlation between fasting and weight changes | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |

### 11. Progress Photos & Body Tracking (35 Features)

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| Progress Tracking | 7 days | Full | Full |
| Progress Photos | - | Yes | Yes |
| Body Measurements | - | Yes | Yes |
| 1RM Calculator | - | Yes | Yes |
| PR Tracking | - | Yes | Yes |
| Strength Standards | - | - | Yes |

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Progress Photo Capture | Take photos from app | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Photos → Capture |
| 2 | View Types | Front, side, back views | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 3 | Photo Timeline | Chronological photo history | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 4 | Before/After Comparison | Side-by-side photo pairs | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 5 | Photo Comparisons | Create and save comparison sets | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Photos → Compare |
| 6 | Weight at Photo | Link body weight to each photo | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 7 | Measurement Links | Associate photos with measurements | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | Photo Statistics | Total photos, view types captured | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 9 | Latest Photos View | Most recent photo per view | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 10 | Body Measurements | 15 measurement points | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Measurements |
| 11 | Weight Tracking | Log weight with trend smoothing | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Weight |
| 12 | Weight Trend Analysis | Calculate rate of change | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 13 | Body Fat Percentage | Track body composition | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 14 | Measurement Comparison | Compare measurements over time | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 15 | Photo Privacy Controls | Private/shared/public visibility | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 16 | Photo Editor | Edit photos with cropping | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 17 | Image Cropping | Crop photos to perfect frame | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 18 | FitWiz Logo Overlay | Add moveable FitWiz branding | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 19 | Explicit Save Button | Clear save action confirmation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 20 | Upload Error Feedback | Error dialogs with retry | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 21 | Measurement Change Calculation | Auto +/- change from previous | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 22 | Measurement Graphs | Visual charts of trends | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 23 | Unit Conversion | Toggle cm/inches, kg/lbs | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 24 | Health Connect Sync | Sync with Android Health | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 25 | Apple HealthKit Sync | Sync with Apple Health | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Health → Apple Health |
| 26 | Quick Measurement Entry | Tap to add single measurement | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 27 | Full Measurement Form | Log all 15 at once | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 28 | Measurement History | Browse by date | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 29 | Body Measurement Guide | Visual guide for accuracy | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 30 | Comparison Period Selector | Compare any two dates | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 31 | Photo Thumbnail Generation | Auto thumbnails for speed | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Chat |
| 32 | Photo Storage Key | S3/Supabase storage | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 33 | Photo Notes | Add notes to each photo | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 34 | Photo Comparison Title | Name comparison sets | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Photos → Compare |
| 35 | Days Between Calculation | Auto-calculate days between | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |

### 12. Social & Community (44 Features)

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| Activity Feed | - | Yes | Yes |
| Share Workouts | - | Yes | Yes |
| Friends | - | Basic | Full |
| Leaderboards | - | - | Yes |
| Challenges | - | - | Yes |

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Activity Feed | Posts from friends | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 2 | Friend Search | Find and add friends | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 3 | Friend Requests | Send/accept/reject | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 4 | Friend List | View friends with stats | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 5 | Challenge Creation | Create fitness challenges | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 6 | Challenge Types | Volume, reps, workouts types | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 7 | Progress Tracking | Track challenge progress | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Flexibility |
| 8 | Challenge Leaderboard | Rankings within challenge | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 9 | Completion Dialog | Results when challenge ends | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 10 | Global Leaderboard | All users ranking | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 11 | Friends Leaderboard | Friends-only ranking | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 12 | Locked State | Premium feature indicator | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 13 | Post Workouts | Share completions to feed | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout |
| 14 | Like/Comment | Interact with posts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Social → Post → Like/Comment |
| 15 | Send Challenge | Challenge specific friend | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 16 | Senior Social | Simplified social for seniors | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Social |
| 17 | User Profiles | Bio, avatar, fitness level | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Profile |
| 18 | Follow/Unfollow System | Follow without mutual | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Social → Profile → Follow |
| 19 | Connection Types | FOLLOWING, FRIEND, FAMILY | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 20 | Emoji Reactions | 5 reaction types on posts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 21 | Threaded Comments | Comments with reply support | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 22 | Challenge Retry System | Retry failed challenges | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 23 | Challenge Abandonment | Track abandoned with reason | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 24 | Async "Beat Their Best" | Challenge past performance | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 25 | Leaderboard Types | Weekly, Monthly, All-time | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 26 | Feature Voting System | Upvote feature requests | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 27 | Feature Suggestions | Users suggest new features | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 28 | Admin Feature Response | Official feature responses | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 29 | Reaction Counts | Total counts per type | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 30 | Follower/Following Counts | Profile social stats | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 31 | Challenge Rematch | Quick rematch option | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 32 | Challenge Notifications | Real-time challenge updates | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 33 | Workout Sharing | Share workout to feed | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Workout Complete → Share |
| 34 | Milestone Celebrations | Auto-post achievements | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 35 | Privacy Controls | Control who sees activity | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 36 | Block/Report Users | Block inappropriate users | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 37 | Direct Messages | Send private messages to friends | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Social → Messages |
| 38 | Conversations List | View all message conversations | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Social → Messages Tab |
| 39 | Unread Message Count | Badge showing unread messages | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Social → Messages |
| 40 | FitWiz Support Chat | Auto-friend support@fitwiz.us | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Social → Messages |
| 41 | Welcome Message | Auto welcome from FitWiz Support | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Social → Messages |
| 42 | Message Read Receipts | Mark messages as read | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Social → Messages |
| 43 | Support User Badge | Verified badge for support | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Social → Messages |
| 44 | Notification Bell | Home screen notification icon | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Header |

#### Direct Messages Feature Details

**User Flow:**
1. **New User Signup**:
   - User creates account (Google or Email)
   - FitWiz Support (support@fitwiz.us) automatically added as friend
   - Welcome message sent from FitWiz Support appears in Messages tab

2. **Accessing Messages**:
   - Navigate to Social screen (bottom nav bar)
   - Tap "Messages" tab (second tab)
   - View list of conversations with unread counts

3. **Reading Messages**:
   - Tap on any conversation card
   - View full message history
   - Messages automatically marked as read

4. **Sending Messages**:
   - Open conversation with a friend
   - Type message and send
   - Message appears instantly in conversation

**Technical Implementation:**

| Component | File | Description |
|-----------|------|-------------|
| Migration | `backend/migrations/152_direct_messages.sql` | Creates conversations, conversation_participants, direct_messages tables with RLS |
| Backend API | `backend/api/v1/social/messages.py` | REST endpoints for conversations and messages |
| Models | `backend/models/social.py` | DirectMessage, Conversation, ConversationParticipant Pydantic models |
| Admin Service | `backend/services/admin_service.py` | send_welcome_message_to_user() method |
| Flutter Tab | `lib/screens/social/tabs/messages_tab.dart` | MessagesTab UI with conversation list |
| Flutter Service | `lib/data/services/social_service.dart` | getConversations(), getMessages(), sendMessage() |
| Provider | `lib/data/providers/social_provider.dart` | conversationsProvider |
| Tests | `backend/tests/test_messages_api.py` | API endpoint tests |

**API Endpoints:**
- `GET /api/v1/social/messages/conversations` - List user's conversations
- `GET /api/v1/social/messages/conversations/{id}` - Get messages in conversation
- `POST /api/v1/social/messages/send` - Send a message
- `POST /api/v1/social/messages/conversations/{id}/read` - Mark as read
- `GET /api/v1/social/messages/with/{user_id}` - Get/create conversation with user

**Database Tables:**
- `conversations` - Stores conversation metadata
- `conversation_participants` - Links users to conversations
- `direct_messages` - Stores individual messages

### 13. Achievements & Gamification (12 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Achievement Badges | Unlockable badges | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Profile → Achievements |
| 2 | Categories & Tiers | Organized achievement groups | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 3 | Point System | Points per achievement | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 4 | Repeatable Achievements | Can earn multiple times | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 5 | Personal Records | Track PRs | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Profile → PRs |
| 6 | Streak Tracking | Workout consistency streaks | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Streak |
| 7 | Longest Streak | All-time record | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | Notifications | Alert when earned | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Settings → Notifications |
| 9 | Badges Tab | View all badges | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 10 | PRs Tab | View all personal records | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 11 | Summary Tab | Overview with totals | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 12 | Rarity Indicators | How rare each badge is | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |

### 14. Profile & Stats (15 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Profile Picture | Avatar/photo upload | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Profile |
| 2 | Personal Info | Name, email editable | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 3 | Fitness Stats | Workouts, calories, PRs cards | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 4 | Goal Banner | Primary goal with progress | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 5 | Workout Gallery | Saved workout photos | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Active Workout |
| 6 | Challenge History | Past challenges | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 7 | Fitness Profile | Age, height, weight | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Profile |
| 8 | Equipment List | Equipment with quantities | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 9 | Workout Preferences | Days, times, types with edit button to modify and regenerate workouts | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout |
| 10 | Focus Areas | Target muscle groups | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 11 | Experience Level | Training experience | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 12 | Environment | 8 workout environments | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Environment Selection |
| 13 | Editable Cards | In-place editing | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 14 | Quick Access Cards | Navigation shortcuts | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 15 | Account Links | Settings navigation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |

### 15. Schedule & Calendar (8 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Weekly Calendar | 7-day grid view | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Schedule → Week View |
| 2 | Agenda View | List of upcoming workouts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 3 | View Toggle | Switch between views | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 4 | Week Navigation | Previous/next week | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 5 | Go to Today | Jump to current day | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 6 | Day Indicators | Rest vs workout day | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 7 | Completion Status | Completed vs upcoming | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | Drag-and-Drop | Reschedule workouts | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Schedule → Drag Workout |

### 16. Metrics & Analytics (38 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Stats Dashboard | Comprehensive statistics | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 2 | Progress Charts | Visual progress over time | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Flexibility Charts |
| 3 | Body Composition | Track body changes | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 4 | Strength Progression | Weight lifted over time | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Charts → Strength |
| 5 | Volume Tracking | Total volume per workout | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 6 | Weekly Summary | End-of-week recap | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 7 | Week Comparison | Compare to previous week | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | PRs Display | Personal records achieved | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 9 | Streak Visual | Streak status | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 10 | Export Data | Download your data | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | — |
| 11 | Overall Fitness Score | Combined score (0-100) from strength, consistency, nutrition, readiness | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 12 | Strength Score | Score based on workout performance and progressive overload | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 13 | Nutrition Score | Weekly nutrition adherence score (logging, calories, protein, health score) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 14 | Consistency Score | Workout completion rate percentage | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 15 | Readiness Score | Recovery/readiness indicator | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 16 | Fitness Level Classification | Beginner, Developing, Fit, Athletic, Elite based on overall score | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 17 | Nutrition Level Classification | Needs Work, Fair, Good, Excellent based on nutrition score | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 18 | Scoring Screen | Full-screen detailed breakdown of all fitness scores | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 19 | Score Trend Display | Show score improvement/decline over time | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 20 | Score Weight Explanation | Educational section explaining how scores are calculated | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 21 | Nutrition Adherence Breakdown | Logging, calorie, and protein adherence percentages | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Nutrition |
| 22 | Consistency Tips | Dynamic tips based on consistency score level | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 23 | Per-Exercise Workout History | View every workout session for a specific exercise with date, sets, reps, weight, volume, and estimated 1RM | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Exercise → History |
| 24 | Exercise Progression Charts | Line charts showing max weight, volume, and estimated 1RM trends over time for each exercise | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Exercise → Chart |
| 25 | Exercise Personal Records | Track max weight, best 1RM, max volume, and max reps for each exercise with achievement dates | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Exercise → PRs |
| 26 | Most Performed Exercises | Ranked list of user's most frequently performed exercises with total volume and last performed date | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Progress → Most Performed |
| 27 | Exercise History Time Ranges | Filter exercise history by 4 weeks, 8 weeks, 12 weeks, 6 months, 1 year, or all time | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Exercise → History Filter |
| 28 | Exercise Trend Analysis | AI-analyzed trends showing improving, stable, declining, or no data status with percentage change | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Exercise → Chart → Trend |
| 29 | Muscle Heatmap | Body diagram showing training intensity (0-100) for each muscle group with color-coded visualization | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Progress → Muscle Heatmap |
| 30 | Muscle Training Frequency | Per-muscle breakdown showing weekly workout count, total sets, total volume, and last trained date | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Progress → Muscle Frequency |
| 31 | Muscle Balance Analysis | Push/pull ratio, upper/lower ratio, and overall balance score with category (balanced/imbalanced) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Progress → Muscle Balance |
| 32 | Exercises by Muscle Group | Browse all exercises that target a specific muscle group for targeted training | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Muscle Heatmap → Tap Muscle |
| 33 | Muscle Volume History | Weekly volume trends for each muscle group over time to track development | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Progress → Muscle → History |
| 34 | Exercise View Analytics Logging | Track user engagement with exercise history screens for AI context awareness | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 35 | Muscle Analytics Logging | Track muscle heatmap and balance screen views for AI personalization | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 36 | Estimated 1RM Calculation | Automatic calculation of estimated one-rep max using Epley formula (weight × (1 + reps/30)) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Exercise History → 1RM |
| 37 | Exercise History Pagination | Paginated results for exercises with many history entries (20 per page) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Library → Exercise → History |
| 38 | Muscle Imbalance Recommendations | Context logging for AI coach to provide muscle balance improvement suggestions | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | AI Coach → Context |

### 17. Measurements & Body Tracking (6 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Body Measurements | Chest, waist, arms, legs, etc. | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Measurements |
| 2 | Weight Logging | Track weight over time | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Log Input |
| 3 | Body Fat | Track body fat percentage | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress → Body Fat |
| 4 | Progress Graphs | Visual trends | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress |
| 5 | Date History | Browse measurements by date | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 6 | Comparison | Compare over time periods | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Workout Complete → Comparison |

### 18. Notifications (14 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Firebase FCM | Push notification service | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 2 | Workout Reminders | Scheduled workout alerts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications → Workout |
| 3 | Nutrition Reminders | Breakfast, lunch, dinner | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 4 | Hydration Reminders | Water intake alerts | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Settings → Notifications → Hydration |
| 5 | Streak Alerts | Don't break your streak | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 6 | Weekly Summary | Weekly progress push | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 7 | Achievement Alerts | New achievement earned | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User | Settings → Notifications → Achievements |
| 8 | Social Notifications | Friend activity | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications → Social |
| 9 | Challenge Notifications | Challenge updates | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 10 | Quiet Hours | Do not disturb period | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 11 | Type Toggles | Enable/disable per type | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 12 | Custom Channels | Android notification channels | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 13 | Mark as Read | Clear notifications | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 14 | Preferences Screen | Manage all settings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |

### 19. Settings (104 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Theme Selector | Light/Dark/Auto | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 2 | Language | Language preference | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Language |
| 3 | Date Format | Date display format | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 4 | Haptic Feedback | Enable/disable vibration | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout → Transition → Haptics |
| 5 | Haptic Intensity | Light/Medium/Strong | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 6 | Senior Mode | Accessibility mode | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 7 | Text Size | Adjust text size | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | High Contrast | Improved visibility | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Accessibility → Contrast |
| 9 | Reduced Motion | Fewer animations | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Accessibility → Reduced Motion |
| 10 | Apple Health | HealthKit integration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Health → Apple Health |
| 11 | Health Connect | Android health integration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 12 | Sync Status | Data sync indicator | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 13 | Export Data | CSV/JSON export | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 14 | Import Data | Import from backup | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 15 | Clear Cache | Clear local storage | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 16 | Delete Account | Remove account permanently | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Danger Zone → Delete |
| 17 | Reset Data | Clear all user data | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 18 | Logout | Sign out | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings → Logout |
| 19 | App Version | Version and build info | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 20 | Licenses | Open source licenses | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 21 | Send Feedback | Email feedback | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 22 | FAQ | Frequently asked questions | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings → Help → FAQ |
| 23 | Contact Support | Support contact | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings → Support → Contact |
| 24 | Privacy Settings | Profile visibility | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Privacy |
| 25 | Block User | Block other users | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 26 | Environment List Screen | View all 8 environments | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 27 | Environment Detail Screen | View/edit equipment | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 28 | Equipment Quantities | Set quantity per equipment | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 29 | Equipment Weight Ranges | Set available weights | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 30 | Equipment Notes | Add notes per equipment | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 31 | Progression Pace | Slow/Medium/Fast progression - affects sets/reps/rest in RAG | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Progress |
| 32 | Workout Type Preference | Strength/Cardio/Mixed/Mobility/Recovery - affects exercise selection in RAG | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Active Workout |
| 33 | Custom Equipment | Add custom equipment | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 34 | Custom Exercises | Create custom exercises | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Custom Content → My Exercises |
| 35 | AI Settings Screen | Dedicated AI configuration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings |
| 36 | Coaching Style | Encouraging/Scientific/etc. | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Onboarding → Coach Selection → Style Selection |
| 37 | Tone Setting | Formal/Friendly/Casual | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 38 | Encouragement Level | Low/Medium/High frequency | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 39 | Detail Level | Brief/Standard/Detailed | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 40 | Focus Areas | Form, Recovery, Nutrition | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 41 | AI Agents Toggle | Enable/disable agents | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 42 | Custom System Prompt | Customize AI behavior | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 43 | Notification Settings Screen | Granular notification controls | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 44 | Workout Reminder Toggle | Enable/disable reminders | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 45 | Nutrition Reminder Toggle | Meal logging reminders | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 46 | Hydration Reminder Toggle | Water intake reminders | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 47 | Streak Alert Toggle | Streak maintenance alerts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 48 | Social Notifications Toggle | Friend activity notifications | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications → Social |
| 49 | Challenge Notifications Toggle | Challenge updates | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 50 | Quiet Hours | Do not disturb time range | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 51 | Reminder Times | Set specific reminder times | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 52 | Nutrition Settings Screen | Nutrition-specific preferences | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings |
| 53 | Show AI Feedback Toggle | Show/hide post-meal AI tips | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 54 | Calm Mode Toggle | Hide calorie numbers | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 55 | Weekly View Toggle | Weekly averages vs daily | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 56 | Positive-Only Feedback | Only positive AI feedback | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 57 | Training Day Adjustment | Auto-adjust on workout days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 58 | Rest Day Adjustment | Reduce calories on rest days | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 59 | Social & Privacy Settings | Control visibility/sharing | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Privacy |
| 60 | Profile Visibility | Public/Friends/Private | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Profile |
| 61 | Activity Sharing | Share workouts to feed | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 62 | Progress Photos Visibility | Who can see photos | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Progress |
| 63 | Training Preferences | Workout customization | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Chat |
| 64 | Preferred Workout Duration | 30/45/60/90 minute workouts | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout |
| 65 | Rest Time Preference | Short/Medium/Long rest | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 66 | Warmup Preference | Always/Sometimes/Never | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 67 | Cooldown Preference | Always/Sometimes/Never | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 68 | Custom Content Management | Manage custom content | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 69 | AI-Powered Settings Search | Search settings with NLP | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings |
| 70 | Settings Categories | Organized categories | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings |
| 71 | Favorite Exercises | Mark favorites for AI boost | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Library → Exercises |
| 72 | Exercise Queue | Queue exercises for next workout | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Library → Exercises |
| 73 | Exercise Consistency Mode | Vary vs Consistent exercises | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | User | Library → Exercises |
| 74 | Staple Exercises | Core lifts that NEVER rotate out (Squat, Bench, Deadlift) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | Library → Exercises |
| 75 | Weekly Variation Slider | Control exercise variety 0-100% (default 30%) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Fully Implemented | User | — |
| 76 | Week-over-Week Comparison | View which exercises changed this week vs last | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 77 | Exercise Rotation Tracking | Track and log exercise swaps for transparency | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 77b | Exercise Swap Analytics | Full tracking of exercise swaps with reason, source (AI/library), workout phase, and timestamp. `exercise_swaps` table stores all swap events. Views: `user_swap_patterns` and `frequently_swapped_exercises` help AI learn user preferences | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Active Workout → Exercise → Swap |
| 78 | Workout History Import | Import past workouts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout |
| 79 | Bulk Workout Import | Bulk import from spreadsheet | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Active Workout |
| 80 | Strength Summary View | View AI's strength data | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 81 | Weight Source Indicator | Historical vs Estimated | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 82 | Fuzzy Exercise Matching | Smart name matching | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | Fully Implemented | Dev | Library → Exercises |
| 83 | Queue Exclusion Reasons | Why exercise was excluded | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 84 | Preference Impact Log | Track preference effects | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 85 | Exercises to Avoid | Skip specific exercises from workouts | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | User | Library → Exercises |
| 86 | Muscles to Avoid | Skip or reduce exercises targeting specific muscles | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | User | — |
| 87 | Temporary Avoidance | Set end date for temporary exercise/muscle avoidances | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 88 | Avoidance Severity | Choose between "avoid completely" or "reduce priority" for muscles | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | User | — |
| 89 | Safe Substitute Suggestions | View injury-safe alternatives when avoiding an exercise (e.g., knee-friendly leg exercises) | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | Fully Implemented | User | — |
| 90 | Injury-Based Exercise Mapping | Curated lists of exercises to avoid for common injuries (knee, back, shoulder, wrist, hip, ankle, neck) | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Library → Exercises |
| 91 | Auto-Substitute on Generation | Automatically replace filtered exercises with safe alternatives during workout generation | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ | Fully Implemented | Dev | — |
| 92 | Swap Suggestions Filtering | Exercise swap/add suggestions exclude user's avoided exercises | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | Fully Implemented | Dev | — |
| 93 | Injury Type Detection | Automatic detection of injury type from free-text reason (e.g., "knee injury" → knee-safe exercises) | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | — |
| 94 | Downloaded Videos Manager | View and manage offline exercise video cache with storage usage display | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 95 | Video Cache Storage | 500MB LRU cache with automatic oldest-first eviction | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 96 | Bulk Video Clear | Clear all downloaded videos at once | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 97 | Individual Video Delete | Delete specific cached videos | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 98 | Voice Announcements Toggle | Enable/disable TTS exercise announcements during workouts | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 99 | Voice Test Button | Test voice announcement in settings before enabling | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 100 | Quick Regenerate Workouts | One-tap regeneration of workouts using current settings (skips wizard) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Program Menu → Quick Regenerate |
| 101 | Program Menu Dropdown | "Program" button with dropdown for Regenerate or Customize options | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Program Button → Menu |
| 102 | Program Reset Analytics | Backend logging of program resets with user activity tracking | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 103 | Warmup Duration Setting | Set preferred warmup length (1-15 minutes) in Training Preferences | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 104 | Stretch Duration Setting | Set preferred post-workout stretch length (1-15 minutes) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Flexibility |
| 105 | Voice Rest Period Alerts | Voice announcements for rest period countdown (10, 5, 3, 2, 1 seconds) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 106 | Voice Transition Announcements | TTS announces next exercise during transitions between exercises | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 107 | Settings Section Descriptions | Descriptive headers explaining each settings category for clarity | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings |
| 108 | Home Edit Mode Tooltips | Contextual tooltips explaining home screen edit functionality | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home |
| 109 | Background Music Support | Allow Spotify/Apple Music to keep playing during workouts | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Support |
| 110 | Audio Ducking | Temporarily lower background music during voice announcements | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 111 | Audio Session Management | Proper iOS/Android audio focus handling for mixing with music apps | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 112 | TTS Volume Control | Slider to adjust voice announcement volume (0-100%) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 113 | Ducking Level Control | Slider to control how much background music is lowered | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 114 | Mute Voice During Videos | Option to silence TTS during exercise demo videos | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 115 | Audio Preferences API | Backend API for storing and retrieving audio settings | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 116 | Audio Settings Section | Dedicated settings section for all audio controls | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings |
| 117 | Weight Increments Customization | Equipment-specific weight increments (dumbbell, barbell, machine, kettlebell, cable) with kg/lbs toggle. Accessible from Settings, Exercise Preferences, and Active Workout | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Preferences → Weight Increments |
| 118 | Weight Increments API | Backend API for storing and retrieving equipment-specific weight increments per user | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |

### 20. Accessibility (8 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Senior Mode | Larger UI elements | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 2 | Large Touch Targets | Easier to tap | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 3 | High Contrast | Better visibility | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Accessibility → Contrast |
| 4 | Text Size | Adjustable text | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 5 | Reduced Motion | Fewer animations | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Accessibility → Reduced Motion |
| 6 | Voice Over | Screen reader support | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Partially Implemented | User | — |
| 7 | Haptic Customization | Vibration preferences | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | Simplified Navigation | Easier to navigate | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |

### 21. Health Device Integration (15 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Apple HealthKit | iOS health integration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Health → Apple Health |
| 2 | Health Connect | Android health integration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 3 | Read Steps | Daily step count | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 4 | Read Distance | Distance traveled | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 5 | Read Calories | Calories burned | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 6 | Read Heart Rate | Heart rate and HRV | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Cardio |
| 7 | Read Body Metrics | Weight, body fat, BMI | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | Read Vitals | Blood oxygen, blood pressure | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | User | — |
| 9 | Read Blood Glucose | Blood sugar for diabetics | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard |
| 10 | Read Insulin | Insulin delivery for Type 1 | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard |
| 11 | Glucose-Meal Correlation | Blood sugar impact of meals | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Analytics |
| 12 | Health Metrics Dashboard | Unified view of health data | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 13 | Write Data | Sync workouts back | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 14 | Auto-Sync | Automatic background sync | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 15 | CGM Integration | Continuous glucose monitor | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Sync |

### 21B. Diabetes Tracking (32 Features) - NEW

Comprehensive diabetes management for Type 1, Type 2, and other diabetes types. Includes blood glucose tracking, insulin management, A1C tracking, carbohydrate counting, and AI-powered diabetes coaching.

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Diabetes Profile | User diabetes type, diagnosis date, targets | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Settings |
| 2 | Glucose Target Ranges | Customizable target ranges (fasting, pre-meal, post-meal, bedtime) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Settings |
| 3 | A1C Goal | Target A1C setting | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Settings |
| 4 | CGM Device Setup | Configure CGM device (Dexcom, Libre, Medtronic) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Settings |
| 5 | Insulin Pump Setup | Configure insulin pump device | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Settings |
| 6 | Log Glucose Reading | Manual blood glucose entry with meal context | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Log Glucose |
| 7 | Glucose Status | Color-coded status (low/normal/high/very high) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | User | Diabetes Dashboard |
| 8 | Glucose History | Paginated list of past readings with filters | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → View All |
| 9 | Glucose Chart | Visual chart of readings over time | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Diabetes Dashboard |
| 10 | Log Insulin Dose | Log rapid/long-acting insulin with dose type | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Log Insulin |
| 11 | Daily Insulin Total | Today's total insulin (rapid + long) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard |
| 12 | Insulin History | History of insulin doses | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Insulin Log |
| 13 | Log A1C Result | Record lab A1C results | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → A1C |
| 14 | Estimated A1C | Calculate eA1C from glucose readings | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard |
| 15 | A1C Trend | Show improving/stable/worsening A1C trend | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → A1C |
| 16 | A1C History | Historical A1C values with chart | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → A1C |
| 17 | Add Medication | Track diabetes medications (oral, injectable) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Medications |
| 18 | Medication List | View active medications | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Medications |
| 19 | Log Carbs | Track carbohydrate intake with meal type | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Log Carbs |
| 20 | Daily Carb Total | Total carbs by meal | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard |
| 21 | Carb-Glucose Correlation | Analyze glucose rise per 10g carbs | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Analytics |
| 22 | Low Glucose Alert | Configurable hypoglycemia alert | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Alerts |
| 23 | High Glucose Alert | Configurable hyperglycemia alert | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Alerts |
| 24 | Time In Range | Calculate % in range, below, above | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard |
| 25 | Glucose Variability | Coefficient of variation, GMI | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Analytics |
| 26 | Dawn Phenomenon Detection | Detect elevated morning glucose pattern | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Patterns |
| 27 | Pre-Workout Glucose Check | Assess glucose safety before exercise | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout → Pre-Workout |
| 28 | Exercise Glucose Impact | Analyze how workouts affect glucose | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Analytics |
| 29 | Health Connect Sync | Sync glucose/insulin from Health Connect | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Diabetes Dashboard → Sync |
| 30 | Diabetes AI Coach | AI coaching with diabetes-aware recommendations | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat → AI Coach |
| 31 | Diabetes Context Logging | Track diabetes events for AI personalization | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 32 | Diabetes Dashboard | Unified view of glucose, insulin, A1C | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home → Diabetes |

### 22. Paywall & Subscriptions (36 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | RevenueCat | Subscription management integration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 2 | Subscription Tiers | Free, Premium, Premium Plus, Lifetime with clear pricing | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Subscription |
| 3 | Pricing Toggle | Monthly vs yearly billing with savings display | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 4 | Free Trial | 7-day trial on yearly plans | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 5 | Feature Comparison | Compare tier features side-by-side | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 6 | Restore Purchases | Restore previous purchases from app stores | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings → Subscription → Restore |
| 7 | Access Checking | Verify feature access by subscription tier | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 8 | Usage Tracking | Track feature usage for analytics | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 9 | Plan Change Confirmation | Dialog showing old vs new plan with price difference before changing | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 10 | Subscription History Screen | Timeline view of all subscription changes, upgrades, downgrades | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Subscription |
| 11 | Upcoming Renewal Display | Shows next billing date and amount prominently | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 12 | Renewal Reminder Notifications | Push notifications 5 days and 1 day before renewal | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Notifications |
| 13 | Home Screen Renewal Banner | Reminder banner on home screen before upcoming charges | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Home |
| 14 | In-App Refund Request | Submit refund request with reason selection and tracking ID | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 15 | Refund Request Tracking | View status of submitted refund requests | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Backend system |
| 16 | Subscription Change Logging | Full audit trail of all subscription events | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 17 | Cancel Subscription Link | Direct link to platform cancellation (App Store/Play Store) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Settings → Subscription → Cancel |
| 18 | Price Transparency | Clear display of all prices including taxes before purchase | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 19 | Billing Notification Preferences | Toggle billing reminders on/off in settings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Notifications |
| 20 | Pre-Auth Pricing Preview | "See Pricing" button shows all tiers and prices before account creation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 21 | Demo Workout Preview | "Try a Sample Workout" shows 3 full workouts without account | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home → Workout Card → View Details |
| 22 | Guest Preview Mode | 10-minute guest session with limited home screen, 20 exercises, sample workouts | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 23 | App Store Pricing Info | Info tooltip confirms prices match App Store/Play Store with cancel anytime note | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 24 | Start with Free Plan | Prominent button to skip paywall and access free tier immediately | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 25 | Email Preferences | 5-category email subscription management (workout, weekly, tips, updates, promo) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat |
| 26 | Quick Unsubscribe Marketing | One-tap unsubscribe from all marketing emails with confirmation | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 27 | Guest-to-Signup Conversion Analytics | Track demo views, guest sessions, and conversion to sign-up | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 28 | Subscription Management Screen | Dedicated screen for managing subscription (view status, pause, cancel) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Subscription |
| 29 | Pause Subscription | Pause subscription for 1 week to 3 months with resume date preview | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Subscription |
| 30 | Resume Subscription | Resume paused subscription before scheduled resume date | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Subscription |
| 31 | Cancel Confirmation Flow | Two-step cancellation with reason collection and retention offers | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 32 | Retention Offers | Personalized retention offers (50% discount, free month, pause option) based on cancellation reason | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 33 | Lifetime Member Badge | Tier badge (Veteran/Loyal/Established/New) with days as member display | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 34 | Lifetime Status API | GET endpoint for lifetime membership status with benefits and tier | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Backend system |
| 35 | Lifetime Never Expires | Database triggers prevent lifetime subscriptions from expiring | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | — |
| 36 | Lifetime AI Context | AI receives lifetime membership context for personalized responses | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Chat |

### 23. Customer Support (28 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Support Ticket System | Create, view, and track support tickets with unique IDs | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Support |
| 2 | Ticket Categories | Billing, Technical, Account, Feature Request, Other | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Support |
| 3 | Priority Levels | Low, Medium, High, Urgent priority selection | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Profile → Level |
| 4 | Ticket Status Tracking | Open, In Progress, Waiting, Resolved, Closed states | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Backend system |
| 5 | Conversation Threads | Reply to tickets with full conversation history | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 6 | Ticket List Screen | View all tickets with status badges and filters | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Support |
| 7 | Create Ticket Screen | Form with subject, category, priority, description | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Support → Create Ticket |
| 8 | Ticket Detail Screen | Full conversation view with reply capability | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Support |
| 9 | Close Ticket | User can close resolved tickets | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Support |
| 10 | Ticket Timestamps | Created at, updated at, resolved at tracking | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Settings → Support |
| 11 | **In-Chat Message Reporting** | Long-press AI messages to report problems directly from chat | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat → Long-press message |
| 12 | Report Categories | Wrong advice, Inappropriate, Unhelpful, Outdated info, Other | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat → Report Sheet |
| 13 | AI Report Analysis | Gemini analyzes why reported response was problematic | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Background task |
| 14 | Report Status Tracking | Pending, Reviewed, Resolved, Dismissed statuses | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 15 | User Report History | View all submitted chat message reports | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Settings → Support |
| 16 | Quick Report from Menu | "Report a Problem" option in chat 3-dot menu | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Chat → Menu |
| 17 | **Live Chat Support** | Real-time chat with human support agents in-app | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat → Talk to Human |
| 18 | Talk to Human Option | "Talk to Human Support" option in AI chat menu with category selection | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Chat → Menu |
| 19 | AI-to-Human Handoff | Escalate from AI coach to human support with conversation context | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat → Escalate |
| 20 | Queue Position Display | Shows queue position and estimated wait time while waiting | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Live Chat Screen |
| 21 | Real-Time Messaging | Instant message delivery via Supabase Realtime subscriptions | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Live Chat Screen |
| 22 | Typing Indicators | Shows when agent or user is typing | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Live Chat Screen |
| 23 | Read Receipts | Messages show read status with timestamps | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Live Chat Screen |
| 24 | Push Notifications | FCM alerts when agent sends message (app in background) | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | User | System notification |
| 25 | Slack/Discord Webhooks | Instant alerts to support team when user starts chat or sends message | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend webhook |
| 26 | Admin Dashboard (Web) | React admin panel for support staff to view and reply to chats | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Admin | /admin/chats |
| 27 | Admin Authentication | Email/password login with role-based access (admin/super_admin) | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Admin | /admin/login |
| 28 | Agent Presence Tracking | Track which support agents are online for queue routing | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Admin | Admin Dashboard |

### 24. Home Screen Widgets (11 Widgets, 33 Sizes) -- Needs more implementation and testing

> All widgets are **resizable** (Small 2×2, Medium 4×2, Large 4×4) with glassmorphic design

| # | Widget | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus |
|---|--------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|
| 1 | Today's Workout | Quick workout access | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User |
| 2 | Streak & Motivation | Streak counter with animation | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| 3 | Quick Water Log | One-tap water logging | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| 4 | Quick Food Log | Smart meal detection | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| 5 | Stats Dashboard | Key metrics display | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| 6 | Quick Social Post | Share workout quickly | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| 7 | Active Challenges | Challenge status display | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| 8 | Achievements | Recent achievements display | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| 9 | Personal Goals | Goal progress display | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User |
| 10 | Weekly Calendar | Calendar widget | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| 11 | AI Coach Chat | Chat widget with prompts | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |

#### Widget Features

| Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus |
|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|
| Glassmorphic Design | Blur + transparency + gradients | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| Deep Link Actions | Tap to open app screens | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | Dev |
| Real-Time Data Sync | SharedPreferences sync | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | Dev |
| iOS WidgetKit | Native SwiftUI widgets | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | Dev |
| Android App Widgets | Native Kotlin widgets | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | Dev |
| Smart Meal Detection | Auto-select meal by time | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | Dev |
| Quick Prompts | 3 contextual prompts | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |
| Agent Shortcuts | Quick agent access | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | User |

#### Deep Link Routes

| Deep Link | Action |
|-----------|--------|
| `fitwiz://workout/{id}` | Open workout detail |
| `fitwiz://workout/start/{id}` | Start workout immediately |
| `fitwiz://hydration/add?amount={ml}` | Quick add water |
| `fitwiz://nutrition/log?meal={type}&mode={input}` | Log food (text/photo/barcode/saved) |
| `fitwiz://chat?prompt={text}` | Open chat with pre-filled prompt |
| `fitwiz://chat?agent={type}` | Open chat with specific agent |
| `fitwiz://challenges` | Open challenges screen |
| `fitwiz://achievements` | Open achievements screen |
| `fitwiz://goals` | Open personal goals |
| `fitwiz://schedule` | Open calendar |
| `fitwiz://stats` | Open stats dashboard |

### 25. Weekly Personal Goals / Challenges of the Week (17 Features)

> A comprehensive feature allowing users to set weekly challenges like "How many push-ups can I do?" (single_max) or "500 push-ups this week" (weekly_volume), track attempts and progress throughout the week, beat their personal records over time, and get AI-powered goal suggestions.

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Goal Types (single_max, weekly_volume) | Two goal types for max reps or weekly total | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 2 | Weekly Goal Creation | Create goals with exercise name, type, target | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 3 | Record Attempts (single_max) | Log max rep attempts with optional notes | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 4 | Add Volume (weekly_volume) | Add reps to weekly total | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 5 | Personal Records Tracking | All-time PRs per exercise/goal_type | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Profile → PRs |
| 6 | PR Detection | Auto-detect when user beats their record | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Workout Complete → PR Badge |
| 7 | Goal History | View past weeks' performance | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 8 | AI Goal Suggestions | AI-generated suggestions by category | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Chat |
| 9 | Beat Your Records Category | Suggestions based on personal history | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 10 | Popular with Friends Category | Goals friends are doing | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 11 | New Challenges Category | Variety suggestions | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Social → Challenges |
| 12 | Goals Screen | Main screen for viewing/managing goals | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | — |
| 13 | Home Screen Card | WeeklyGoalsCard showing active goals | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Home |
| 14 | Goal Leaderboard | Compare with friends on same goals | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | — |
| 15 | Goal Visibility | Private, friends, public settings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 16 | ISO Week Boundaries | Proper Monday-Sunday week tracking | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 17 | User Context Logging | Log goal activities for AI coaching | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |

#### Goal Types Explained

| Type | Description | Example | Tracking |
|------|-------------|---------|----------|
| `single_max` | Beat your maximum in one attempt | "How many push-ups can I do?" | Log individual attempts, track best |
| `weekly_volume` | Accumulate total reps over the week | "500 push-ups this week" | Add reps throughout week, track progress to target |

#### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/weekly-goals` | GET | List user's weekly goals for current week |
| `/api/v1/weekly-goals` | POST | Create a new weekly goal |
| `/api/v1/weekly-goals/{id}` | GET | Get specific goal details |
| `/api/v1/weekly-goals/{id}` | DELETE | Delete a goal |
| `/api/v1/weekly-goals/{id}/attempts` | POST | Record attempt (single_max) |
| `/api/v1/weekly-goals/{id}/volume` | POST | Add volume (weekly_volume) |
| `/api/v1/weekly-goals/personal-records` | GET | Get all-time PRs |
| `/api/v1/weekly-goals/suggestions` | GET | Get AI goal suggestions by category |
| `/api/v1/weekly-goals/history` | GET | Get past weeks' goal history |
| `/api/v1/weekly-goals/leaderboard/{goal_id}` | GET | Get leaderboard for a goal |

#### Database Tables

| Table | Purpose |
|-------|---------|
| `weekly_goals` | Stores goal definitions (exercise, type, target, week) |
| `weekly_goal_attempts` | Individual attempts for single_max goals |
| `weekly_goal_volume_logs` | Volume additions for weekly_volume goals |
| `personal_records` | All-time PRs per exercise and goal type |
| `goal_suggestions` | Cached AI-generated suggestions |

---

### 27. Wear OS Companion App (15 Features) — 🚧 COMING SOON

> **⏳ COMING SOON:** The WearOS companion app is currently under development. All features listed below are built and tested but not yet released to the Play Store. Stay tuned for updates!

**Tier Availability:**
| Feature | Free | Premium | Premium Plus/Lifetime |
|---------|:----:|:-------:|:--------------:|
| All WearOS Features | Yes | Yes | Yes |

> **Note:** WearOS companion app will be FREE for all tiers - helps users track workouts from their wrist.

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Today's Workout on Wrist | View current workout directly from watch | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Watch → Home → Today's Workout |
| 2 | Set Logging | Log reps, weight, RPE with crown navigation | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Watch → Workout → Log Set |
| 3 | Voice Food Logging | Say "log 2 eggs for breakfast" - Gemini analyzes nutrition | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | Fully Implemented | User | Watch → Nutrition → Voice Log |
| 4 | Fasting Timer | Start/stop fasting sessions with watch complications | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Watch → Fasting → Start/Stop |
| 5 | Passive Step Tracking | Real-time steps with Health Connect integration | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Watch → Home → Steps |
| 6 | Heart Rate Monitoring | Continuous HR during workouts with sample storage | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Watch → Workout → Heart Rate |
| 7 | Phone-Watch Sync | Automatic credential and workout sync via Data Layer API | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Automatic on login |
| 8 | Direct Backend Sync | Fallback sync via WiFi when phone unavailable | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Automatic |
| 9 | Batch Sync Endpoint | Single API call syncs all pending watch data | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | POST /watch-sync/sync |
| 10 | Activity Goals Display | Show steps, active minutes, calories goals on watch | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | User | Watch → Home → Goals |
| 11 | Workout Tile | Quick access tile for today's workout | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Watch → Tiles → Workout |
| 12 | Calories Tile | Today's calorie intake at a glance | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Watch → Tiles → Calories |
| 13 | Fasting Tile | Current fast status and elapsed time | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | User | Watch → Tiles → Fasting |
| 14 | Device Source Tracking | All watch data tagged with device_source='watch' | ❌ | ✅ | ❌ | ❌ | ✅ | ✅ | Fully Implemented | Dev | Automatic |
| 15 | AI Context Integration | Watch activity included in AI coaching context | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Automatic |

#### User Flow

1. **Setup**
   - Install FitWiz WearOS from Play Store
   - Login on phone app - credentials automatically sync to watch
   - Watch receives today's workout and nutrition summary

2. **Daily Workout Use**
   - Open watch app → See today's workout
   - Start workout → Log each set with crown/touch
   - Complete workout → Data syncs to phone and backend

3. **Nutrition Logging**
   - Open nutrition screen on watch
   - Tap microphone → Say "log 400 calories chicken salad"
   - Gemini AI analyzes and logs nutrition

4. **Fasting**
   - Start fast from watch → Timer runs with complication
   - End fast → Duration logged to backend

5. **Sync Architecture**
   - **Connected to phone**: Data syncs via Google Data Layer API
   - **Phone unavailable**: Watch syncs directly to backend via WiFi
   - All data includes device_source='watch' for analytics

#### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/watch-sync/sync` | POST | Batch sync all pending watch data |
| `/api/v1/watch-sync/goals/{user_id}` | GET | Get user's activity goals for watch display |

#### Database Tables

| Table | Purpose |
|-------|---------|
| `wearos_sync_events` | Tracks sync events from watch |
| `workout_completions` | Workout completion records with heart rate |
| `heart_rate_samples` | HR readings from watch sensors |
| `workout_logs.device_source` | Column to track data origin (watch/phone) |
| `food_logs.device_source` | Column to track data origin |
| `fasting_sessions.device_source` | Column to track data origin |

---

## Technical Features

### Backend Architecture (15 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | FastAPI | Python web framework | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | Fully Implemented | Dev | Backend system |
| 2 | AWS Lambda | Serverless deployment | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 3 | Supabase | PostgreSQL database | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 4 | ChromaDB | Vector database for RAG | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | Fully Implemented | Dev | — |
| 5 | Rate Limiting | Request throttling | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 6 | Security Headers | HTTP security | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 7 | CORS | Cross-origin configuration | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 8 | Job Queue | Background task processing | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 9 | Connection Pooling | Database optimization | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 10 | Pool Pre-Ping | Cold start handling | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 11 | Auth Timeout | 10-second reliability timeout | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 12 | Async/Await | Non-blocking operations | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Chat |
| 13 | Structured Logging | Consistent log format | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Backend system |
| 14 | Error Handling | Stack traces and recovery | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 15 | Health Checks | Endpoint monitoring | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |

### Backend Services (25 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Background Job Queue | Persistent job queue | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 2 | Job Types | workout, notification, email, analytics | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 3 | Job Retry Logic | Exponential backoff | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 4 | Job Priority Levels | high, normal, low queues | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Profile → Level |
| 5 | Webhook Error Alerting | Alerts on job failures | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 6 | User Activity Logging | Track screen views, actions | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 7 | Screen Time Analytics | Time spent per screen | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 8 | Firebase FCM Push | Push notifications | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 9 | Multi-Platform FCM | iOS and Android support | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 10 | Notification Templates | Predefined notification types | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Settings → Notifications |
| 11 | Batch Notifications | Send to multiple users | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | Settings → Notifications |
| 12 | Email Service | Transactional emails via Resend | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Chat |
| 13 | Email Templates | Welcome, reset, summary | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Chat |
| 14 | Feature Voting System | Feature upvoting | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 15 | Feature Request API | Submit and track requests | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Backend system |
| 16 | Admin Feature Response | Official responses | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 17 | Data Export Service | Export user data (GDPR) | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | Settings → Data → Export |
| 18 | Data Import Service | Import from other apps | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | User | — |
| 19 | Analytics Aggregation | Daily/weekly/monthly stats | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 20 | Subscription Management | RevenueCat integration | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | Dev | Settings → Subscription |
| 21 | Webhook Handlers | Process RevenueCat webhooks | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | Dev | — |
| 22 | Entitlement Checking | Verify premium access | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Partially Implemented | Dev | — |
| 23 | Cron Jobs | Scheduled tasks | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 24 | Database Migrations | Version-controlled schema | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 25 | RLS Policies | Row-level security | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |

### AI & Machine Learning (12 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Gemini 2.5 Flash | Google's fast AI model | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 2 | Text Embedding | text-embedding-004 model | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | Fully Implemented | Dev | — |
| 3 | LangGraph | Agent orchestration | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 4 | Intent Extraction | Understand user intent | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 5 | RAG | Retrieval Augmented Generation | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | Fully Implemented | Dev | Schedule → Drag Workout |
| 6 | Semantic Search | Find similar content | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | Fully Implemented | Dev | — |
| 7 | Exercise Similarity | Match similar exercises | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | Fully Implemented | Dev | Library → Exercises |
| 8 | Vision API | Food image analysis | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Backend system |
| 9 | Streaming | Real-time response streaming | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Backend system |
| 10 | JSON Extraction | Robust parsing with fallbacks | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 11 | Retry Logic | Handle parsing failures | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 12 | Safety Settings | Fitness content filtering | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Settings |

### RAG System (8 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Chat History | Store past conversations | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Chat |
| 2 | Workout History | Index completed workouts | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Active Workout |
| 3 | Nutrition History | Track meal patterns | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Nutrition |
| 4 | Preferences Tracking | Remember user preferences | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 5 | Change Tracking | Track workout modifications | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Backend system |
| 6 | Context Retrieval | Get relevant user context | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | Fully Implemented | Dev | — |
| 7 | Similar Meals | Find similar past meals | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Nutrition |
| 8 | Exercise Detection | Find similar exercises | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev | Library → Exercises |

### API Endpoints (6 Categories)

| Category | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus |
|----------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|
| Chat | send, history, RAG search | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | Dev |
| Workouts | CRUD, generate, suggest | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | Fully Implemented | Dev |
| Nutrition | analyze, parse, log, history | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| Users | register, login, profile | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| Activity | sync, history | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| Social | feed, friends, challenges | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |

### Mobile Architecture (10 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | Flutter | Cross-platform framework | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 2 | Riverpod | State management | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 3 | Freezed | JSON serialization | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 4 | Dio | HTTP client | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Home → Cardio Workout |
| 5 | Secure Storage | Encrypted token storage | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 6 | SharedPreferences | Local settings | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Social |
| 7 | Pull-to-Refresh | Content refresh pattern | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | Home → Pull Down |
| 8 | Infinite Scroll | Pagination pattern | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 9 | Image Caching | Cached exercise images | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 10 | Deep Linking | URL-based navigation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |

### Data Models (28 Key Models)

| Model | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus |
|-------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|
| User | Profile, preferences, goals | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| Workout | Exercises, schedule | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| WorkoutExercise | Sets, reps, weight | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| LibraryExercise | 1,722 exercise database | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev |
| ChatMessage | Conversation messages | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | Fully Implemented | Dev |
| FoodLog | Meals with macros | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| HydrationLog | Drink entries | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | Dev |
| Achievement | Badges and points | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Not Implemented | Dev |
| PersonalRecord | PRs | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| UserStreak | Consistency tracking | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| WeeklySummary | Weekly progress | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| MicronutrientData | Vitamins, minerals | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| Recipe | User-created recipes | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| RecipeIngredient | Individual ingredients | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| FastingRecord | Fasting session with zones | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| FastingPreferences | Protocol, schedule | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| ProgressPhoto | Progress photos | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| PhotoComparison | Before/after pairs | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| BodyMeasurement | 15 measurement points | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| NutrientRDA | Floor/target/ceiling goals | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| CoachPersona | AI coach personality | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| NutritionPreferences | Diet, allergies, settings | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| FeatureRequest | Suggestions and votes | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| UserConnection | Social connections | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| WorkoutChallenge | Fitness challenges | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| WorkoutHistoryImports | Manual past workouts | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| PreferenceImpactLog | Preference effects | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |
| MobilityExerciseTracking | Flexibility, yoga, stretch tracking | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev |

### Security (6 Features)

| # | Feature | Description | Frontend | Backend | Gemini AI | RAG | DB Tables | Tests | Status | Focus | Navigation |
|---|---------|-------------|----------|---------|-----------|-----|-----------|-------|--------|-------|-------|
| 1 | JWT Auth | Token-based authentication | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |
| 2 | Secure Storage | Encrypted credentials | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 3 | HTTPS | Encrypted transport | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 4 | Input Sanitization | Prevent injection | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 5 | Rate Limiting | Prevent abuse | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | Fully Implemented | Dev | — |
| 6 | RLS | Row-level security | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | Fully Implemented | Dev | — |

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| **Total Features** | 760+ |
| **User-Facing Categories** | 26 |
| **Technical Categories** | 7 |
| **Home Screen Widgets** | 11 (33 sizes) |
| **Workout Environments** | 8 |
| **Exercise Library Size** | 1,722 |
| **Micronutrients Tracked** | 40+ |
| **Fasting Protocols** | 10 |
| **AI Agents** | 5 |
| **AI Coach Personas** | 5 + Custom |
| **Data Models** | 27 |
| **Voice Guidance Options** | 4 (transitions, rest, completion, countdown) |
| **Warmup/Stretch Customization** | 1-15 minutes each |
| **Settings Options** | 80+ |
| **Subscription Tiers** | 4 |
| **Platforms** | iOS, Android |

---

### Key Differentiators vs Competitors

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
|---------|--------|------|-------|--------|--------|-------------|--------------|------|--------|
| **WORKOUT FEATURES** |||||||||
| AI Workout Generation | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Conversational AI Coach | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| AI Coach Personas (5+) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Exercise Video Library | ✅ 1,722 | ✅ 1,300 | ✅ 400 | ✅ 300 | ✅ 600 | ❌ | ❌ | ❌ | ❌ |
| Custom Exercise Creation | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Workout Templates | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Branded Programs (12+) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Supersets/Dropsets/Giant Sets | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| AMRAP Finishers | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Rest Timer | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Dynamic Warmups | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Cooldown Stretches | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Yoga Pose Generation | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Mobility/Flexibility Workouts | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Recovery Workout Type | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **AI & PERSONALIZATION** |||||||||
| Learns from Feedback | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Age-Based Safety Caps | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Comeback Detection | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Difficulty Ceiling by Level | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Skill Progressions (7 chains) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Unlimited Exercise Swaps | ✅ | ❌ | ❌ (3 max) | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Equipment-Aware (100+ types) | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Environment-Aware (Gym/Home) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Injury-Aware Selection | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Focus Area Targeting | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Calibration Workouts | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **NUTRITION FEATURES** |||||||||
| Calorie Tracking | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| Macro Tracking | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| AI Photo Food Logging | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| Voice Food Logging | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Recipe Builder | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| AI Meal Suggestions | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Weekly Calorie Averaging | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Hydration Tracking | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| **FASTING FEATURES** |||||||||
| Fasting Timer | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Multiple Fasting Protocols | ✅ 10 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ 6+ | ✅ 8+ |
| Fasting + Workout Integration | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **TRACKING & PROGRESS** |||||||||
| Progress Photos | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Body Measurements (15 pts) | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ |
| 1RM Calculator/Auto-Populate | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Progress Graphs | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Week-over-Week Comparison | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Volume Tracking | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| NEAT Tracking | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Milestones/Achievements | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| Workout History Import | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Apple Health Sync | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **SOCIAL FEATURES** |||||||||
| Social Feed | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Leaderboards | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Workout Sharing | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |
| Challenges | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ |
| Feature Voting | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Instagram Stories Share | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Workout Sharing Templates (4) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **SCHEDULING & PLANNING** |||||||||
| Calendar View (Week/Agenda) | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Drag-and-Drop Rescheduling | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Workout Reminders | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Weekly Goals | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ |
| Personal Goals System | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **USER EXPERIENCE** |||||||||
| Apple Watch Support | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Free Trial (Full Access) | ✅ 24hr | ❌ | ❌ | ❌ | 3 workouts | 14 days | ❌ | ✅ | ❌ |
| Pre-Paywall Plan Preview | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Lifetime Purchase Option | ✅ $99.99 | ✅ $149.99 | ✅ $199 | ✅ $149.99 | ❌ | ❌ | ❌ | ❌ | ❌ |
| Offline Mode | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ |
| Custom Sounds | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Voice Guidance/TTS | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Split Screen/Multi-Window | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| In-App Support Tickets | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Dark Mode | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Multi-Language Support | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| Customizable Home Screen (26 tiles) | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| App Tour/Onboarding | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Conversational Onboarding | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

**Feature Count Summary:**

| App | Total ✅ Features |
|-----|-------------------|
| **FitWiz** | **77** |
| Hevy | 26 |
| Gravl | 14 |
| Strong | 22 |
| Fitbod | 24 |
| MacroFactor | 18 |
| MyFitnessPal | 22 |
| Zero | 14 |
| Fastic | 17 |

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
| **Hormonal Health Tracking** | Testosterone, estrogen, cycle phase tracking | Gender-specific workout optimization based on hormones |
| **Kegel/Pelvic Floor Exercises** | 16 exercises with warmup/cooldown integration | Pelvic floor health for both men and women |
| **Cycle-Aware Workouts** | Menstrual phase detection, intensity adjustment | Auto-adjusts workout intensity based on cycle phase |
| **Hormonal Diet Recommendations** | Foods for testosterone, estrogen, PCOS, menopause | AI-powered nutrition for hormonal balance |

---

### 40. "App doesn't consider my hormones or menstrual cycle"
✅ **SOLVED**: Comprehensive hormonal health tracking system:
- **Hormonal Profile**: Set goals like testosterone optimization, estrogen balance, PCOS management, menopause support, fertility support, postpartum recovery
- **Menstrual Cycle Tracking**: Log period start dates, automatic cycle phase calculation (menstrual, follicular, ovulation, luteal)
- **Cycle-Aware Workouts**: AI automatically adjusts workout intensity based on cycle phase:
  - **Menstrual phase (Days 1-5)**: Lower intensity, focus on recovery and gentle movement
  - **Follicular phase (Days 6-13)**: Rising energy, good for strength building
  - **Ovulation phase (Days 14-16)**: Peak energy and strength, great for PRs
  - **Luteal phase (Days 17-28)**: Decreasing energy, moderate intensity recommended
- **Symptom Tracking**: Log fatigue, cramps, mood swings, bloating, headaches - AI adjusts recommendations
- **Hormone Logs**: Track energy levels, mood, sleep quality, symptoms daily
- **Gender-Specific Recommendations**: Different advice for testosterone optimization (men) vs estrogen balance (women)
- **API Endpoints**:
  - `GET/PUT /hormonal-health/profile/{user_id}` - Get or update hormonal profile
  - `POST /hormonal-health/logs/{user_id}` - Add hormone log entry
  - `GET /hormonal-health/cycle-phase/{user_id}` - Get current cycle phase with recommendations
  - `POST /hormonal-health/log-period/{user_id}` - Log period start date
  - `GET /hormonal-health/insights/{user_id}` - Get comprehensive hormonal insights

### 41. "No kegel exercises or pelvic floor training"
✅ **SOLVED**: Complete kegel/pelvic floor exercise system:
- **16 Kegel Exercises** in library with proper instructions:
  - **General exercises**: Quick flicks, slow holds, elevator holds, endurance holds, reverse kegels
  - **Male-specific**: Prostate holds, post-urination squeeze, PC muscle isolation
  - **Female-specific**: Progressive holds, post-birth recovery, core connection breathwork
- **Preferences System**:
  - Enable/disable kegels globally
  - Include in warmup and/or cooldown
  - Set daily session target (default 3)
  - Choose difficulty level (beginner, intermediate, advanced)
  - Select focus area (general, male-specific, female-specific, postpartum, prostate health)
- **Session Tracking**:
  - Log duration, reps completed, hold duration
  - Track when performed (warmup, cooldown, standalone, daily routine)
  - Rate difficulty for adaptation
- **Stats & Streaks**:
  - Daily goal progress
  - Current and longest streaks
  - Total sessions and duration
  - Weekly session count
- **Workout Integration**:
  - Automatically include in warmup/cooldown when enabled
  - Log sessions directly from workout completion
- **API Endpoints**:
  - `GET/PUT /kegel/preferences/{user_id}` - Get or update kegel preferences
  - `POST /kegel/sessions/{user_id}` - Log kegel session
  - `GET /kegel/stats/{user_id}` - Get comprehensive kegel statistics
  - `GET /kegel/daily-goal/{user_id}` - Check daily goal progress
  - `GET /kegel/exercises` - Get all kegel exercises with filtering
  - `POST /kegel/log-from-workout/{user_id}` - Log kegel from warmup/cooldown

### 42. "No diet recommendations for hormone balance"
✅ **SOLVED**: Comprehensive hormonal diet recommendation system:
- **Foods by Hormonal Goal**:
  - **Testosterone Optimization**: Oysters, beef, eggs, pomegranate, garlic, olive oil, cruciferous vegetables
  - **Estrogen Balance**: Flaxseeds, soy, berries, citrus fruits, fatty fish, leafy greens
  - **PCOS Management**: Anti-inflammatory foods, cinnamon, spearmint tea, low glycemic options
  - **Menopause Support**: Phytoestrogen-rich foods, calcium, vitamin D sources
  - **Fertility Support**: Folate-rich foods, zinc, omega-3s, antioxidants
  - **Postpartum Recovery**: Iron-rich foods, protein, galactagogues for milk production
- **Cycle Phase Nutrition**:
  - **Menstrual phase**: Iron-rich foods (red meat, spinach, lentils), anti-inflammatory foods
  - **Follicular phase**: Lean proteins, light grains, fermented foods, fresh vegetables
  - **Ovulation phase**: High-fiber foods, antioxidant-rich fruits, anti-inflammatory omega-3s
  - **Luteal phase**: Complex carbs for serotonin, magnesium-rich foods, B-vitamin foods
- **AI Meal Plan Generation**: Gemini-powered personalized meal plans based on hormonal goals, dietary restrictions, and current cycle phase
- **Foods Database**: 50+ hormone-supportive foods with nutritional benefits and usage tips
- **API Endpoints**:
  - `GET /hormonal-health/foods` - Get hormone-supportive foods with filtering
  - `GET /hormonal-health/foods?goal=testosterone_optimization` - Filter by hormonal goal
  - `GET /hormonal-health/foods?cycle_phase=luteal` - Get phase-specific recommendations

---

### 43. "The app doesn't help me pick weights or rest times during workouts"
✅ **SOLVED**: Complete AI-Powered Real-Time Workout Intelligence system

---

## AI-Powered Real-Time Workout Intelligence

> **The AI coach that learns and adapts during your workout in real-time.**

FitWiz includes a sophisticated AI system that provides intelligent suggestions throughout your workout. Unlike static workout plans, this system adapts to your actual performance, detecting fatigue, suggesting optimal weights, and recommending rest times based on how you're actually performing.

---

### Feature 1: Smart Weight Auto-Fill

**What it does:** Automatically suggests the optimal weight before each set based on your strength data.

#### How It Works
```
┌─────────────────────────────────────────────────────────────┐
│  BENCH PRESS - SET 1 OF 3                     💡 AI        │
│  ─────────────────────────────────────────────────────────  │
│                                                             │
│  Weight: [  45.0 kg  ]  ← Auto-filled                      │
│                                                             │
│  📊 Based on your 60kg 1RM at 75% intensity                │
│  📈 Last session: 42.5kg × 10 @ RPE 6 (you crushed it!)    │
│                                                             │
│  [ - ]  [ + ]                    [Complete Set]            │
└─────────────────────────────────────────────────────────────┘
```

#### Calculation Formula
```
suggested_weight = 1RM × target_intensity% × performance_modifier
```

Where:
- **1RM**: Your one-rep max for this exercise (from strength records)
- **Target Intensity**: Based on training goal:
  | Goal | Intensity Range | Typical Reps |
  |------|-----------------|--------------|
  | Strength | 85-95% | 1-5 reps |
  | Hypertrophy | 65-80% | 8-12 reps |
  | Endurance | 50-65% | 15-20+ reps |
  | Power | 70-85% | 3-6 reps |
- **Performance Modifier**: Adjusts based on last session
  - Crushed it (RPE 6-7 with target reps): +5%
  - Normal (RPE 8): No change
  - Struggled (RPE 9-10 or missed reps): -5%

#### Equipment-Aware Rounding
| Equipment Type | Increment | Example |
|---------------|-----------|---------|
| Dumbbells | 2.5 kg | 23.7 → 22.5 or 25.0 |
| Barbells | 2.5 kg | 61.3 → 60.0 or 62.5 |
| Machines | 5.0 kg | 42.0 → 40.0 or 45.0 |
| Cables | 5.0 kg | 33.0 → 35.0 |

#### First-Time User Flow
For new users without 1RM data:
1. **No 1RM stored** → Use conservative starting weights based on:
   - User's fitness level (beginner/intermediate/advanced from onboarding)
   - Body weight (for bodyweight-relative exercises)
   - Exercise difficulty rating
2. **After first workout** → System calculates estimated 1RM from performance
3. **Subsequent workouts** → Full AI suggestions with increasing accuracy

---

### Feature 2: AI Rest Time Suggestions

**What it does:** Recommends optimal rest duration after each set based on how hard it was.

#### How It Works
```
┌─────────────────────────────────────────────────────────────┐
│  🕐 AI REST COACH                                [AI]      │
│  ─────────────────────────────────────────────────────────  │
│  Standard Rest                                              │
│                                                             │
│         2:30              │           1:30                 │
│       SUGGESTED           │           QUICK                │
│                                                             │
│  💡 "That was a hard set (RPE 9). Heavy compound           │
│      exercises need full recovery for optimal gains."      │
│                                                             │
│  ┌─────────────────┐      ┌─────────────────────────────┐  │
│  │ Quick Rest      │      │ ✓ Use Suggested (2:30)     │  │
│  │ Save 1:00       │      │                             │  │
│  └─────────────────┘      └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

#### Rest Time Categories
| Category | Duration | When Used | Exercise Types |
|----------|----------|-----------|----------------|
| **Short** | 30-60s | RPE 6-7, light work | Isolation, accessories |
| **Moderate** | 90-120s | RPE 7-8, standard work | Most exercises |
| **Long** | 150-180s | RPE 8-9, heavy work | Compound lifts |
| **Extended** | 180-300s | RPE 9-10, max effort | Strength/power sets |

#### Factors Considered
1. **RPE of completed set** (primary factor)
2. **Exercise type** (compound vs isolation)
3. **Set number** (later sets need more rest due to fatigue)
4. **Remaining sets** (conserve energy if many left)
5. **User's training goal** (strength needs more rest than endurance)

#### Fatigue Multiplier
| Set Number | Multiplier | Effect |
|------------|------------|--------|
| Set 1-2 | 1.0x | Baseline rest |
| Set 3 | 1.05x | +5% rest time |
| Set 4 | 1.10x | +10% rest time |
| Set 5+ | 1.15x | +15% rest time |

---

### Feature 3: Predictive Fatigue Alerts

**What it does:** Warns you when your performance is declining and suggests adjustments before you fail.

#### How It Works
```
┌─────────────────────────────────────────────────────────────┐
│  ⚠️ FATIGUE DETECTED                              [85%]    │
│  ─────────────────────────────────────────────────────────  │
│  MODERATE Alert                                             │
│                                                             │
│  Lat Pulldown                                               │
│                                                             │
│  "Your last 2 sets showed 25% performance decline.         │
│   Consider reducing weight to maintain form and volume."   │
│                                                             │
│  DETECTED ISSUES:                                           │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ 📉 Rep Drop  │  │ ⚡ RPE Spike │                        │
│  └──────────────┘  └──────────────┘                        │
│                                                             │
│  ════════════════════════════════════════════════════════  │
│  SUGGESTED ADJUSTMENT                                       │
│                                                             │
│       60.0 kg   →   51.0 kg                                │
│       ───────       ───────                                │
│       current       suggested (-15%)                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │               ✓ Accept Suggestion                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │               Continue as Planned                    │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

#### Fatigue Detection Triggers
| Indicator | Threshold | Description |
|-----------|-----------|-------------|
| **Rep Decline** | ≥20% drop | Fewer reps than first set (12 → 9) |
| **Severe Rep Decline** | ≥35% drop | Significant performance loss |
| **RPE Spike** | +2 points | Effort increased significantly (7 → 9) |
| **Sustained High RPE** | RPE 9+ for 2+ sets | Working too hard |
| **Failed Set** | 0 reps or marked failed | Complete failure |
| **Weight Reduced** | User reduced weight | Self-correcting fatigue |

#### Severity Levels & Recommendations
| Severity | Color | Weight Reduction | Action |
|----------|-------|------------------|--------|
| **None** | Green | 0% | Continue normally |
| **Low** | Yellow | 5% | Consider slight adjustment |
| **Moderate** | Orange | 10% | Reduce weight recommended |
| **High** | Red | 15% | Strong recommendation to reduce |
| **Critical** | Dark Red | 20% | Option to stop exercise |

---

### Feature 4: Next Set Preview

**What it does:** Shows AI-recommended weight and reps for your upcoming set during rest periods.

#### How It Works
```
┌─────────────────────────────────────────────────────────────┐
│  🌟 AI RECOMMENDATION                            [87%]     │
│  ─────────────────────────────────────────────────────────  │
│  Set 3 of 4                                                 │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                       │   │
│  │      47.5 kg           │          10 reps           │   │
│  │      ────────          │         ────────           │   │
│  │       +2.5 ↑           │       75% intensity        │   │
│  │                                                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  💡 "Progressing well. Slight weight increase based on     │
│      your strong Set 2 performance (RPE 7, all reps)."     │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    ✓ Use This                        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

#### Weight Delta Display
| Change | Color | Icon | Example |
|--------|-------|------|---------|
| Increase | Green | ↑ | +2.5 kg |
| Same | Gray | = | 0 kg |
| Decrease | Orange | ↓ | -5.0 kg |

#### Preview Data Includes
- **Recommended Weight**: Based on 1RM, intensity, and current performance
- **Target Reps**: From workout plan
- **Intensity %**: Percentage of estimated 1RM
- **Confidence %**: How sure the AI is (higher with more data)
- **Reasoning**: Personalized explanation

---

### Feature 5: Auto-RPE Estimation

**What it does:** Estimates your RPE when you skip entering it manually.

#### How It Works
When user doesn't input RPE, the system estimates it using:

```
Estimated RPE = f(weight_used, reps_completed, estimated_1RM)
```

Based on the Tuchscherer/Helms RPE-Reps-Percentage tables:

| Reps | @RPE 6 | @RPE 7 | @RPE 8 | @RPE 9 | @RPE 10 |
|------|--------|--------|--------|--------|---------|
| 1 | 85% | 89% | 92% | 96% | 100% |
| 3 | 79% | 82% | 85% | 89% | 92% |
| 5 | 74% | 77% | 80% | 84% | 87% |
| 8 | 67% | 70% | 73% | 77% | 80% |
| 10 | 62% | 65% | 68% | 72% | 75% |
| 12 | 57% | 60% | 63% | 67% | 70% |

**Example**: User lifts 45kg for 8 reps, 1RM is 60kg
- 45/60 = 75% of 1RM
- At 8 reps, 75% falls between RPE 8-9
- System displays: "Estimated RPE: 8.5"

---

### Feature 6: RIR-Based Intensity & Auto-Weight Adjustment

**What it does:** Displays AI-generated RIR (Reps in Reserve) targets for each set using colored pills, then auto-adjusts weight for the next set based on your actual effort feedback.

#### RIR Display (Colored Pills)

The "Auto" column in the set tracking table shows target weight, reps, AND RIR using intuitive colored pills:

```
┌──────────────────────────────────────────────────────┐
│ Set │  Auto                    │  kg  │ Reps │ ✓    │
├──────────────────────────────────────────────────────┤
│  1  │ 40 × 8  [2 in tank](?) │ [  ] │ [  ] │ ☐    │
│  2  │ 40 × 8  [1 in tank](?) │ [  ] │ [  ] │ ☐    │
│  3  │ 40 × 8  [MAX](?)       │ [  ] │ [  ] │ ☐    │
└──────────────────────────────────────────────────────┘
```

**RIR Pill Colors:**
| RIR | Color | Label | Meaning |
|-----|-------|-------|---------|
| 3+ | 🟢 Green | "3+ in tank" | Easy/warmup - stop with 3+ reps left |
| 2 | 🟡 Yellow | "2 in tank" | Moderate - stop with 2 reps left |
| 1 | 🟠 Orange | "1 in tank" | Challenging - stop with 1 rep left |
| 0 | 🔴 Red | "MAX" | Max effort - go to failure |

**Info Icon (?):** Always visible next to each pill. Tapping shows explanation:
> "In tank" means how many more reps you could do after finishing the set.
> • MAX = Go to failure, give everything
> • 1 in tank = Stop when you could do 1 more
> • 2 in tank = Stop when you could do 2 more
> • 3+ in tank = Easy effort, lots left

#### AI-Generated RIR Targets (Backend)

The backend generates per-set RIR targets based on:

1. **Exercise Type:**
   - Compound exercises (squats, bench, deadlift): Higher RIR (2-3) for safety
   - Isolation exercises (curls, tricep extensions): Lower RIR (1-2) - can push harder

2. **Fitness Level:**
   - Beginner: Base RIR 3 (conservative, learn form)
   - Intermediate: Base RIR 2 (moderate intensity)
   - Advanced: Base RIR 2, can go to failure on last set

3. **Progressive Fatigue Model:**
   - Set 1: Base RIR
   - Set 2: Base RIR - 0.5 (slightly harder)
   - Set 3+: Base RIR - 1.0 (push harder on later sets)

#### Quick RIR Selector (Post-Set Feedback)

After completing a set, a simple 3-option bottom sheet appears:

```
┌─────────────────────────────────────────────┐
│  How'd it feel?                      Skip   │
├─────────────────────────────────────────────┤
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │   🟢     │ │   🟡     │ │   🔴     │    │
│  │ Could do │ │  Just    │ │ Struggled│    │
│  │   more   │ │  right   │ │          │    │
│  │ 3+ tank  │ │ 1-2 tank │ │   MAX    │    │
│  └──────────┘ └──────────┘ └──────────┘    │
└─────────────────────────────────────────────┘
```

- **Could do more** → RIR 3+ (weight was too light)
- **Just right** → RIR 1-2 (perfect intensity)
- **Struggled** → RIR 0 (weight was too heavy or max effort)
- **Skip** → Dismiss without logging RIR

#### Auto-Weight Adjustment Logic

When user logs their actual RIR, the system compares it to the target RIR and adjusts:

| Logged RIR vs Target | Weight Change | Reason |
|---------------------|---------------|--------|
| RIR diff ≤ -2 | -15% | Much harder than expected |
| RIR diff = -1 | -7.5% | Slightly harder |
| RIR diff = 0 | No change | Perfect! |
| RIR diff = +1 | +5% | Slightly easier |
| RIR diff ≥ +2 | +10% | Much easier |

**Example:**
- Target RIR: 2 ("2 in tank")
- User logs: "Struggled" (RIR 0)
- Difference: 0 - 2 = -2
- Action: Reduce weight by 15%
- 40kg → 34kg (rounded to 35kg for equipment increment)
- SnackBar: "Weight adjusted: 40.0 → 35.0 kg"

#### User Flow (Complete)

```
1. START SET
   └─> See target: "40 × 8 [2 in tank](?)"
   └─> Understand: Stop when I could do 2 more reps

2. PERFORM SET
   └─> User completes 8 reps at 40kg
   └─> Taps checkmark to complete

3. RIR FEEDBACK
   └─> Quick selector appears
   └─> User selects "Struggled" (was harder than expected)

4. AUTO-ADJUST
   └─> System detects: Target RIR 2, Actual RIR 0
   └─> Calculates: -15% adjustment
   └─> Updates weight controller: 40 → 35kg
   └─> Shows SnackBar: "Weight adjusted: 40.0 → 35.0 kg"

5. NEXT SET
   └─> Weight field pre-filled with 35kg
   └─> Target still shows: "35 × 8 [1 in tank]"
   └─> User can accept or manually adjust
```

#### Data Persistence

All RIR data is saved to the database for:
- **Performance logs:** `rir` field in `performance_logs` table
- **User context:** Events logged for AI personalization:
  - `SET_RIR_FEEDBACK`: Tracks target vs actual RIR
  - `WEIGHT_AUTO_ADJUSTED`: Tracks weight adjustments made

---

## First-Time User Experience

### Workout 1: Cold Start (No Data)

For a brand new user with no workout history:

```
Day 1 User Flow:
────────────────

1. USER STARTS WORKOUT
   └─> App generates workout based on onboarding answers
       (fitness level, equipment, goals)

2. EXERCISE BEGINS (e.g., Dumbbell Bench Press)
   └─> No 1RM data exists
   └─> System uses conservative defaults:
       • Beginner: Light weight (body weight × 0.3)
       • Intermediate: Moderate (body weight × 0.5)
       • Advanced: Higher (body weight × 0.7)
   └─> Shows: "Starting weight: 15 kg (adjust as needed)"
   └─> NO "AI" badge shown (no data to base it on)

3. USER COMPLETES SET 1
   └─> Logs: 15 kg × 10 reps @ RPE 7
   └─> System calculates: Estimated 1RM ≈ 20 kg
   └─> REST SUGGESTION: Uses rule-based logic
       (RPE 7 + compound = 90-120 sec)
   └─> NO AI badge (building data)

4. SET 2 BEGINS
   └─> System now has 1 data point
   └─> Suggests: "Try 15 kg again or 17.5 kg if easy"
   └─> Shows faint "Learning..." indicator

5. USER COMPLETES SET 2
   └─> Logs: 17.5 kg × 9 reps @ RPE 8
   └─> 1RM estimate refined: ~24 kg
   └─> FATIGUE CHECK: Compares Set 1 vs Set 2
       (9 reps vs 10 = 10% drop, below threshold)
       No alert shown

6. SET 3 BEGINS
   └─> System has 2 data points
   └─> Suggests: "17.5 kg recommended"
   └─> Shows: "AI" badge (enough data)

7. WORKOUT ENDS
   └─> All performance data saved
   └─> 1RM estimates stored for each exercise
   └─> Ready for smarter suggestions next time
```

### Workout 2+: AI-Powered Experience

```
Day 2+ User Flow:
─────────────────

1. USER STARTS WORKOUT
   └─> App has historical data

2. EXERCISE BEGINS (Dumbbell Bench Press)
   └─> System fetches:
       • Last session: 17.5 kg × 9 @ RPE 8
       • Stored 1RM: 24 kg
       • Target intensity: 75% (hypertrophy)
   └─> Calculates: 24 × 0.75 = 18 kg
   └─> Applies performance modifier: +2.5% (good last session)
   └─> Rounds to equipment: 17.5 kg (nearest 2.5)
   └─> Shows: "17.5 kg" with "AI" badge
   └─> Reasoning: "Based on your 24kg 1RM at 75% intensity"

3. USER COMPLETES SET 1
   └─> Logs: 17.5 kg × 10 reps @ RPE 7
   └─> REST TIMER starts
   └─> AI REST COACH appears:
       "RPE 7 + compound = 90 sec suggested"
       Quick option: 60 sec
   └─> NEXT SET PREVIEW appears:
       "Set 2: 17.5 kg × 10 (same weight, you're doing great)"

4. USER ACCEPTS REST SUGGESTION
   └─> Timer set to 90 seconds
   └─> Suggestion logged: {type: "rest", accepted: true}

5. SET 2 BEGINS
   └─> Weight pre-filled: 17.5 kg
   └─> User increases to 20 kg (feels strong)

6. USER COMPLETES SET 2
   └─> Logs: 20 kg × 8 reps @ RPE 8
   └─> FATIGUE CHECK: 8 vs 10 reps = 20% drop
   └─> ⚠️ FATIGUE ALERT triggered (threshold met)
   └─> Modal shows:
       "Rep count dropped 20%. Suggested: 17.5 kg for remaining sets"
   └─> User chooses: "Continue as Planned"
   └─> Choice logged for AI learning

7. SET 3 BEGINS
   └─> NEXT SET PREVIEW showed during rest:
       "Consider 17.5 kg based on fatigue indicators"
   └─> User sees warning but continues at 20 kg

8. USER COMPLETES SET 3
   └─> Logs: 20 kg × 6 reps @ RPE 9
   └─> FATIGUE CHECK: 6 vs 10 = 40% drop
   └─> ⚠️ HIGH FATIGUE ALERT
   └─> Modal shows severity: HIGH
   └─> Suggested: 17.5 kg (-12.5%)
   └─> User accepts suggestion

9. SET 4 (Final Set)
   └─> Weight pre-filled: 17.5 kg (from accepted suggestion)
   └─> User completes: 17.5 kg × 10 @ RPE 8
   └─> 1RM updated based on all set data

10. WORKOUT ENDS
    └─> Summary shows:
        • AI suggestions: 4 shown, 2 accepted
        • Fatigue alerts: 2 triggered
        • 1RM updated: Bench Press → 26 kg (+2 kg)
    └─> Data feeds into next workout's suggestions
```

---

## Data Flow Architecture

```
                    ┌─────────────────────────────────────┐
                    │         USER STARTS SET             │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │     Smart Weight API Called          │
                    │  GET /workouts/smart-weight/{id}    │
                    └──────────────┬──────────────────────┘
                                   │
              ┌────────────────────┴────────────────────┐
              │                                         │
   ┌──────────▼──────────┐               ┌─────────────▼─────────────┐
   │  Has 1RM Data?      │               │  No 1RM Data              │
   │  YES                │               │  Use defaults             │
   └──────────┬──────────┘               └─────────────┬─────────────┘
              │                                         │
   ┌──────────▼──────────────────────────────┐         │
   │  Calculate:                              │         │
   │  weight = 1RM × intensity% × modifier    │         │
   │  Apply equipment rounding                │         │
   │  Generate reasoning                      │         │
   └──────────┬───────────────────────────────┘         │
              │                                         │
              └────────────────┬────────────────────────┘
                               │
                    ┌──────────▼──────────────────────┐
                    │   Display Weight in Set Card     │
                    │   Show "AI" badge if data-backed │
                    └──────────┬──────────────────────┘
                               │
                    ┌──────────▼──────────────────────┐
                    │      USER COMPLETES SET          │
                    │   Logs: weight, reps, RPE        │
                    └──────────┬──────────────────────┘
                               │
              ┌────────────────┴────────────────────┐
              │                                      │
   ┌──────────▼──────────┐            ┌─────────────▼─────────────┐
   │  Fatigue Check API   │            │  Rest Suggestion API      │
   │  POST /fatigue-check │            │  POST /rest-suggestion    │
   └──────────┬───────────┘            └─────────────┬─────────────┘
              │                                       │
   ┌──────────▼──────────────────────┐  ┌────────────▼────────────┐
   │  Analyze:                        │  │  Calculate rest time:    │
   │  - Rep decline vs first set      │  │  - Base rest by RPE      │
   │  - RPE change between sets       │  │  - Fatigue multiplier    │
   │  - Failed sets                   │  │  - Exercise type factor  │
   │  - Weight reductions             │  │  - Gemini reasoning      │
   └──────────┬───────────────────────┘  └────────────┬────────────┘
              │                                        │
   ┌──────────▼─────────────┐             ┌───────────▼────────────┐
   │  Fatigue Detected?      │             │  Show Rest Coach Card   │
   │  Show Alert Modal       │             │  Suggested + Quick opt  │
   └──────────┬──────────────┘             └───────────┬────────────┘
              │                                         │
              └────────────────┬────────────────────────┘
                               │
                    ┌──────────▼──────────────────────┐
                    │   Next Set Preview API           │
                    │   POST /next-set-preview         │
                    └──────────┬──────────────────────┘
                               │
                    ┌──────────▼──────────────────────┐
                    │   Show Next Set Preview Card     │
                    │   During rest period             │
                    └──────────┬──────────────────────┘
                               │
                    ┌──────────▼──────────────────────┐
                    │   Log All Suggestions to DB      │
                    │   ai_workout_suggestions table   │
                    │   Track: accepted/dismissed      │
                    └─────────────────────────────────┘
```

---

## API Reference

### Smart Weight Endpoint
```http
GET /workouts/smart-weight/{user_id}/{exercise_id}
Query Parameters:
  - target_reps: int (default: 10)
  - goal: enum (strength, hypertrophy, endurance, power)
  - equipment: string (dumbbell, barbell, machine, cable)

Response:
{
  "suggested_weight": 45.0,
  "reasoning": "Based on your 60kg 1RM at 75% intensity",
  "confidence": 0.87,
  "one_rm_kg": 60.0,
  "target_intensity": 0.75,
  "equipment_increment": 2.5,
  "performance_modifier": 1.05,
  "last_session": {
    "weight_kg": 42.5,
    "reps": 10,
    "rpe": 6
  }
}
```

### Rest Suggestion Endpoint
```http
POST /workouts/rest-suggestion
Body:
{
  "rpe": 8,
  "exercise_name": "Bench Press",
  "exercise_type": "compound",
  "set_number": 3,
  "total_sets": 4,
  "user_goal": "hypertrophy"
}

Response:
{
  "suggested_seconds": 120,
  "reasoning": "Moderate RPE on compound lift. Standard rest recommended.",
  "quick_option_seconds": 90,
  "rest_category": "moderate",
  "ai_powered": true
}
```

### Fatigue Check Endpoint
```http
POST /workouts/fatigue-check
Body:
{
  "exercise_name": "Lat Pulldown",
  "current_weight": 60.0,
  "sets": [
    {"reps": 10, "weight": 60.0, "rpe": 7},
    {"reps": 8, "weight": 60.0, "rpe": 8},
    {"reps": 6, "weight": 60.0, "rpe": 9}
  ]
}

Response:
{
  "fatigue_detected": true,
  "severity": "moderate",
  "suggested_weight_reduction": 15,
  "suggested_weight_kg": 51.0,
  "reasoning": "Rep count dropped 40% over 3 sets with rising RPE.",
  "indicators": ["rep_decline", "rpe_spike"],
  "confidence": 0.85
}
```

### Next Set Preview Endpoint
```http
POST /workouts/next-set-preview
Body:
{
  "exercise_name": "Squat",
  "user_id": "uuid",
  "current_set": 2,
  "total_sets": 4,
  "current_weight": 80.0,
  "last_set_reps": 8,
  "last_set_rpe": 7
}

Response:
{
  "recommended_weight": 82.5,
  "recommended_reps": 8,
  "intensity_percentage": 77.5,
  "reasoning": "Strong performance on Set 2. Slight progression recommended.",
  "confidence": 0.82,
  "is_final_set": false
}
```

---

## Database Schema

### ai_workout_suggestions Table
```sql
CREATE TABLE ai_workout_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  workout_log_id UUID REFERENCES workout_logs(id),
  exercise_id UUID REFERENCES exercises(id),
  exercise_name TEXT,

  suggestion_type TEXT NOT NULL,  -- 'weight', 'rest', 'fatigue', 'next_set'
  suggested_value JSONB NOT NULL,
  reasoning TEXT,
  confidence REAL DEFAULT 0.5,

  user_action TEXT,  -- 'accepted', 'dismissed', 'modified'
  user_modified_value JSONB,
  action_timestamp TIMESTAMPTZ,

  set_number INTEGER,
  current_rpe REAL,
  current_reps INTEGER,
  current_weight_kg REAL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  source TEXT DEFAULT 'auto'  -- 'auto', 'requested', 'chat'
);
```

### user_exercise_1rm Table
```sql
CREATE TABLE user_exercise_1rm (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  exercise_id UUID REFERENCES exercises(id),
  exercise_name TEXT NOT NULL,

  estimated_1rm REAL NOT NULL,
  formula_used TEXT DEFAULT 'brzycki',
  confidence REAL DEFAULT 0.5,

  based_on_weight REAL,
  based_on_reps INTEGER,
  based_on_rpe REAL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## UI Components

| Component | File | Purpose |
|-----------|------|---------|
| `FuturisticSetCard` | `futuristic_set_card.dart` | Glassmorphic set logging with AI badge |
| `RestSuggestionCard` | `rest_suggestion_card.dart` | Rest time suggestion with quick option |
| `NextSetPreviewCard` | `next_set_preview_card.dart` | Next set AI preview during rest |
| `FatigueAlertModal` | `fatigue_alert_modal.dart` | Full-screen fatigue warning |
| `ExerciseThumbnailStrip` | `exercise_thumbnail_strip.dart` | 80px exercise navigation |
| `NumberStepper` | `number_stepper.dart` | Weight/rep adjustment with long-press |
| `GlowButton` | `glow_button.dart` | Animated button with haptic feedback |
| `GlassCard` | `glass_card.dart` | Glassmorphic container |

---

## Learning & Improvement

The AI system continuously improves by tracking:

1. **Acceptance Rate**: % of suggestions user accepts
   - Weight suggestions: Target >70%
   - Rest suggestions: Target >60%
   - Fatigue alerts: Track response patterns

2. **Modification Patterns**: When users modify suggestions
   - If users consistently add +5kg, increase base suggestions
   - If users consistently reduce rest, shorten recommendations

3. **Performance Correlation**: Does following AI improve results?
   - Track PRs after accepting vs rejecting suggestions
   - Adjust confidence scores based on outcomes

### Analytics Views
```sql
-- Suggestion acceptance rates per user
CREATE VIEW ai_suggestion_acceptance_rates AS
SELECT
  user_id,
  suggestion_type,
  COUNT(*) as total_suggestions,
  COUNT(*) FILTER (WHERE user_action = 'accepted') as accepted,
  ROUND(100.0 * COUNT(*) FILTER (WHERE user_action = 'accepted') / COUNT(*), 1) as acceptance_rate
FROM ai_workout_suggestions
WHERE user_action IS NOT NULL
GROUP BY user_id, suggestion_type;
```

---

## AI-Powered Home Screen Insights

### Overview

The home screen now features AI-powered insights that provide personalized coaching tips, weight trend analysis, and habit recommendations. All AI features are powered by Gemini and cached to minimize API calls.

### Features

#### 1. AI Daily Tips (Coach Tip Card)

**What it does**: Displays a personalized coaching tip based on user's workout history, goals, and time of day.

**Location**: Home screen → Coach Tip tile

**User Flow**:
```
1. User opens home screen
2. Card shows loading state: "Getting your personalized tip..."
3. Backend checks cache (24h TTL)
4. If cache miss → Gathers user context → Calls Gemini
5. Personalized tip appears
6. User can tap "Ask coach for more" → Opens AI chat
```

**Context Used for Personalization**:
- User's fitness goals
- Last workout type (legs, push, pull, etc.)
- Days since last workout
- Current workout streak
- Most trained muscle groups
- Time of day (morning/afternoon/evening)

**Example Tips**:
- Morning after leg day: "Great leg session yesterday! Focus on upper body mobility today to stay balanced."
- Evening with 5-day streak: "Five days strong! Consider active recovery tomorrow - a 20-min walk does wonders."
- 3 days since last workout: "It's been a few days since your last workout. Even a 20-minute session helps maintain momentum!"

**API Endpoint**: `GET /insights/{user_id}/daily-tip`

---

#### 2. AI Weight Insights

**What it does**: Analyzes the user's weight trend over 7-14 days and provides personalized feedback and actionable tips.

**Location**: Can be added to Weight Trend tile or Progress screen

**User Flow**:
```
1. User has logged weight at least 2 times in the past 14 days
2. Backend calculates weekly change and direction (losing/gaining/maintaining)
3. Gemini generates insight based on:
   - Weight data points
   - User's primary goal
   - Target weight (if set)
   - Current trend direction
4. Insight displayed with actionable tip
```

**Example Insights**:
- Fat loss goal, down 2 lbs: "You're down 2.1 lbs this week! Your consistency is paying off. Try adding an extra serving of protein to maximize muscle retention."
- Maintaining, muscle building goal: "Your weight is stable this week. To continue building muscle, consider increasing calories by 100-200 on training days."
- Gaining on fat loss goal: "You've gained 1.2 lbs. Review your weekend eating patterns - that's often where extra calories sneak in."

**API Endpoint**: `GET /insights/{user_id}/weight-insight`

---

#### 3. AI Habit Suggestions

**What it does**: Suggests 2-3 personalized habits based on user's goals and current habits.

**User Flow**:
```
1. User views habits section (or first time setting up habits)
2. Backend checks current active habits
3. Gemini suggests NEW habits not already tracked
4. Each suggestion includes:
   - Habit name
   - Brief reason why it helps their goal
5. User can tap to add suggested habit
```

**Available Habit Templates**:
- No DoorDash today
- No eating out
- No sugary drinks
- No late-night snacking
- Cook at home
- No alcohol
- Drink 8 glasses water
- 10k steps
- Stretch for 10 minutes
- Sleep by 11pm
- No processed foods
- Meal prep Sunday
- Track all meals
- Take vitamins

**Example Response**:
```json
[
  {"name": "No late-night snacking", "reason": "Helps control daily calorie intake for fat loss"},
  {"name": "10k steps daily", "reason": "Boosts NEAT and increases calorie burn by 200-300 cals"},
  {"name": "Meal prep Sunday", "reason": "Reduces reliance on takeout during busy weekdays"}
]
```

**API Endpoint**: `GET /insights/{user_id}/habit-suggestions`

---

### Caching Strategy

All AI insights are cached to minimize Gemini API calls and improve response times:

| Insight Type | Cache Duration | Cache Key |
|-------------|----------------|-----------|
| Daily Tip | 24 hours | `daily_tip_{user_id}_{date}` |
| Weight Insight | 24 hours | `weight_insight_{user_id}` |
| Habit Suggestions | 1 week (168 hours) | `habit_suggestions_{user_id}` |

**Cache Table**: `ai_insight_cache`
```sql
CREATE TABLE ai_insight_cache (
    id UUID PRIMARY KEY,
    cache_key VARCHAR(255) UNIQUE,
    insight TEXT,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);
```

### Fallback Behavior

If Gemini API fails, the system provides fallback responses:

| Insight Type | Fallback Logic |
|-------------|----------------|
| Daily Tip | Time-based tips (morning/afternoon/evening) |
| Weight Insight | Direction-based message (losing/gaining/maintaining) |
| Habit Suggestions | 3 default habits (water, no snacking, sleep) |

---

## Customizable Home Screen Tiles

### New Tile Types Added

| Tile | Description | Sizes |
|------|-------------|-------|
| `weightTrend` | Weekly weight change with trend arrow | compact, half, full |
| `dailyStats` | Steps + calorie deficit/surplus | compact, half, full |
| `achievements` | Recent badge + next milestone | compact, half, full |
| `quickLogWeight` | Inline weight input with one-tap log | half, full |
| `quickLogMeasurements` | Quick body measurements update | half, full |
| `habits` | Today's habits with checkboxes | half, full |
| `heroSection` | Main swipeable hero area | full |

### Tile Features

#### Weight Trend Tile
- Shows weekly weight change (e.g., "Down 2.3 lbs this week!")
- Green arrow = losing (good for fat loss)
- Red arrow = gaining
- Orange = maintaining
- Taps through to Progress screen

#### Daily Stats Tile
- Shows steps from HealthKit/Google Fit
- Shows calorie deficit (target - consumed + burned)
- Green = in deficit, Red = surplus
- Progress bar for 10k step goal

#### Quick Log Weight Tile
- Shows last logged weight with date
- Inline number input field
- One-tap "Log" button
- Shows weekly trend info (full size)

#### Habits Tile
- Shows today's habits with checkboxes
- Quick toggle to mark done/undone
- Progress indicator (e.g., "3/5 done")
- Streak display per habit
- "View All" opens full Habits screen

### Small Screen Optimization

All tiles are optimized for small screens (iPhone SE, older Androids):

| File | Fix Applied |
|------|-------------|
| `weight_trend_card.dart` | Wrapped text in `Flexible` with overflow ellipsis |
| `quick_log_weight_card.dart` | Used `FittedBox` for weight display, `Expanded` for trend text |
| `daily_stats_card.dart` | Wrapped both texts in `Flexible` |
| `habits_tile_card.dart` | Wrapped streak display in `Flexible` |

---

## First-Time User Experience: Home Screen AI

### Day 1: New User

```
1. USER COMPLETES ONBOARDING
   └─> Goals set (e.g., fat loss)
   └─> Fitness level assessed
   └─> Home screen loads

2. HOME SCREEN DISPLAYS
   └─> Coach Tip card shows:
       "Getting your personalized tip..."
   └─> Backend has limited data
   └─> Gemini generates generic tip based on goals + time of day
   └─> Shows: "Welcome! Start your day with 10 minutes of stretching..."

3. WEIGHT TREND TILE
   └─> No weight logs yet
   └─> Shows: "Log your weight to see trends"
   └─> Tap opens weight logging sheet

4. USER LOGS FIRST WEIGHT
   └─> Weight saved to database
   └─> Tile updates: "185.0 lbs" with "Today" badge
   └─> No trend shown (need 2+ data points)

5. HABITS TILE
   └─> No habits set up yet
   └─> Shows: "Build healthy habits" + "Add Habit" button
   └─> OR: Backend suggests 3 AI habits based on goals
```

### Day 3+: Returning User with Data

```
1. USER OPENS APP
   └─> Home screen loads
   └─> Coach Tip fetches from cache (if <24h old)
   └─> If cache miss → Gemini generates personalized tip

2. COACH TIP DISPLAYS
   └─> Context: User did legs yesterday, 3-day streak
   └─> Gemini returns: "Nice leg session! Give them a rest today.
       Focus on upper body or mobility work."
   └─> Shows "AI" badge to indicate personalization

3. WEIGHT TREND TILE
   └─> User has 3 weight logs
   └─> Shows: "Down 1.2 lbs this week!"
   └─> Green trending down arrow
   └─> Tapping → Progress screen with weight insight

4. DAILY STATS TILE
   └─> Steps from HealthKit: 4,521
   └─> Calorie deficit calculated: -312 cal
   └─> Shows progress toward 10k step goal

5. HABITS TILE
   └─> User has 5 habits
   └─> Shows 3 incomplete ones first
   └─> Quick toggle to mark as done
   └─> Shows: "2/5 done"

6. USER REQUESTS AI HABIT SUGGESTIONS
   └─> Taps "Get AI Suggestions" in habits screen
   └─> Backend returns 3 suggestions not already tracked
   └─> User can tap to add any suggestion
```

### Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                        HOME SCREEN                                │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  💡 Coach Tip                                        [AI]   │ │
│  │                                                              │ │
│  │  "Focus on progressive overload today. Try adding 2.5kg    │ │
│  │   to your main compound lifts."                             │ │
│  │                                                              │ │
│  │  Ask coach for more →                                       │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────────────┐  ┌──────────────────────┐             │
│  │  📉 Weight Trend     │  │  📊 Daily Stats      │             │
│  │  Down 2.3 lbs!       │  │  4,521 steps         │             │
│  │  View →              │  │  -312 cal deficit    │             │
│  └──────────────────────┘  └──────────────────────┘             │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │  ✅ Today's Habits                              2/5 done    │ │
│  │  [ ] No DoorDash today                                      │ │
│  │  [ ] Drink 8 glasses water                                  │ │
│  │  [x] No late-night snacking                          🔥 3   │ │
│  │  +2 more →                                                   │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Active Workout Screen UX Improvements (January 2026)

### Implemented Features

1. **Skip Exercise Button** - Prominent orange outlined button with icon (was underlined text)
2. **Direct Unit Toggle** - Tap the "KG" or "LBS" label to toggle units instantly (shows swap icon)
3. **Add Set Button** - [+] circle button after completed sets to add more sets on-the-fly
4. **Larger Input Controls** - 56px buttons (was 48px), 40sp font size (was 32sp) for easier logging
5. **Next Exercise Preview** - Shows "NEXT: [Exercise Name] • X sets" at bottom of set card
6. **Full-Screen Background Video** - Exercise video/GIF now shows as full-screen background instead of corner PiP
7. **Tap-to-Minimize Set Card** - Tap outside the set card to hide it and see the exercise video clearly
8. **"Tap to Log Set" Indicator** - Floating pill button appears when card is minimized

### Coming Soon

- **Floating Music Mini Player** - Draggable, transparent music controls to play/pause/skip tracks from Spotify, Apple Music, or YouTube Music during workouts. Requires `audio_service` package integration for cross-platform media control.

---

## MacroFactor-Style Adaptive TDEE System (January 2026)

### Overview

FitWiz now includes a sophisticated metabolic adaptation detection and algorithm-driven recommendation system, matching the industry-leading approach used by MacroFactor. This system provides:

- **EMA-smoothed weight trends** for noise reduction
- **TDEE with confidence intervals** (e.g., "2,150 ±120 cal")
- **Metabolic adaptation detection** (plateau + TDEE drop alerts)
- **Adherence tracking** with sustainability scores
- **Multi-option recommendations** (aggressive/moderate/conservative)

### How It Works

#### Weight Trend Smoothing (EMA)
```
Raw Weight Data:     85.2 → 86.0 → 84.8 → 85.5 → 84.9 → 85.1
                     (daily fluctuations from water, food, etc.)

EMA Smoothed:        85.2 → 85.32 → 85.24 → 85.28 → 85.22 → 85.20
                     (alpha = 0.15, filters noise)

Result: -0.02 kg net change (stable, not the wild swings raw data shows)
```

#### TDEE Calculation with Confidence
```
Energy Balance Equation:
TDEE = Calories In - (Weight Change × Caloric Content)

Where:
- Caloric Content = 75% fat (7700 kcal/kg) + 25% lean (1800 kcal/kg)
- Weight Change = EMA-smoothed end weight - EMA-smoothed start weight

Confidence Interval:
- Base uncertainty: ±300 cal
- Adjusted by data quality: more logs = tighter confidence
- Example: 2,150 ±120 cal (high data quality)
```

### User Flow

#### Weekly Check-In Trigger

```
1. USER OPENS NUTRITION SCREEN
   └─> System checks days since last check-in
   └─> If ≥7 days → Auto-prompt for weekly check-in

2. OR: MANUAL TRIGGER
   └─> Nutrition → Settings → "Run Weekly Check-In"
   └─> Nutrition → Action Menu → "Weekly Check-In"
```

#### Weekly Check-In Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  📊 WEEKLY CHECK-IN                                     [X]    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  🔥 YOUR CALCULATED TDEE                                  │  │
│  │                                                           │  │
│  │       2,150 cal/day          ±120 cal                    │  │
│  │       ═══════════════        ─────────                   │  │
│  │         calculated           uncertainty                  │  │
│  │                                                           │  │
│  │  Range: 2,030 - 2,270 cal   Data Quality: ████████░░ 80%  │  │
│  │                                                           │  │
│  │  📉 Weight Trend: -0.45 kg/week (Losing)                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  ⚠️ METABOLIC ADAPTATION ALERT                     [!]    │  │
│  │                                                           │  │
│  │  Your TDEE has dropped 12% over the past 4 weeks.        │  │
│  │  This may indicate metabolic adaptation.                  │  │
│  │                                                           │  │
│  │  Suggested Action: Consider a 1-2 week diet break        │  │
│  │  at maintenance calories to restore metabolic rate.       │  │
│  │                                                           │  │
│  │  [Learn More]                    [Acknowledge]            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  📈 ADHERENCE & SUSTAINABILITY                            │  │
│  │                                                           │  │
│  │    ┌─────────────┐        ┌─────────────┐                │  │
│  │    │   72%       │        │   0.68      │                │  │
│  │    │  Adherence  │        │ Sustainability│               │  │
│  │    │   ○○○○○     │        │     HIGH     │                │  │
│  │    └─────────────┘        └─────────────┘                │  │
│  │                                                           │  │
│  │  4 weeks analyzed | Consistency: 0.75 | Logging: 0.85    │  │
│  │                                                           │  │
│  │  💡 "Your adherence is good. Keep up the consistent      │  │
│  │      tracking for better TDEE accuracy."                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  🎯 RECOMMENDATION OPTIONS                                │  │
│  │                                                           │  │
│  │  Choose your target intensity:                            │  │
│  │                                                           │  │
│  │  ○ 🔥 AGGRESSIVE         -0.68 kg/week                   │  │
│  │    1,400 cal | P: 140g C: 100g F: 47g                    │  │
│  │    "Faster results, requires strict adherence"            │  │
│  │    Sustainability: LOW                                    │  │
│  │                                                           │  │
│  │  ◉ ⚖️ MODERATE (Recommended)    -0.45 kg/week            │  │
│  │    1,650 cal | P: 155g C: 140g F: 55g                    │  │
│  │    "Balanced approach for sustainable progress"           │  │
│  │    Sustainability: MEDIUM                                 │  │
│  │                                                           │  │
│  │  ○ 🐢 CONSERVATIVE       -0.23 kg/week                   │  │
│  │    1,900 cal | P: 165g C: 180g F: 63g                    │  │
│  │    "Slower but more sustainable"                          │  │
│  │    Sustainability: HIGH                                   │  │
│  │                                                           │  │
│  │  [─────────────── Apply Selected ───────────────]         │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Adherence Calculation

Adherence is calculated per-macro with weighted importance:

| Macro | Weight | Rationale |
|-------|--------|-----------|
| Calories | 40% | Most important for weight goals |
| Protein | 35% | Critical for body composition |
| Carbs | 15% | Energy and performance |
| Fat | 10% | Hormone function and satiety |

```
Per-Macro Adherence:
- Within ±5% of target: 100% adherence
- Beyond tolerance: Linear decrease to 0% at 2x deviation

Overall Adherence = (Cal × 0.40) + (Pro × 0.35) + (Carb × 0.15) + (Fat × 0.10)
```

### Sustainability Score

Sustainability Score = (Adherence × 0.60) + (Consistency × 0.25) + (Logging × 0.15)

| Score | Rating | Meaning |
|-------|--------|---------|
| ≥0.70 | HIGH | User can maintain current targets long-term |
| 0.50-0.69 | MEDIUM | Some adjustments may help |
| <0.50 | LOW | Targets may be too aggressive |

### Metabolic Adaptation Detection

#### Plateau Detection
```
Trigger: <0.2 kg total change over 3+ weeks despite 300+ cal deficit

Action: Suggest diet break (1-2 weeks at maintenance)
```

#### TDEE Drop Detection
```
Moderate (10-15% drop): Suggest refeed days (2-3 high carb days)
Severe (15-20% drop): Suggest reducing deficit
Critical (>20% drop): Suggest diet break
```

### Technical Implementation

#### Backend Services
- [adaptive_tdee_service.py](backend/services/adaptive_tdee_service.py) - EMA smoothing, TDEE calculation, confidence intervals
- [metabolic_adaptation_service.py](backend/services/metabolic_adaptation_service.py) - Plateau and adaptation detection
- [adherence_tracking_service.py](backend/services/adherence_tracking_service.py) - Adherence and sustainability calculations

#### Database Tables
- `tdee_calculation_history` - Historical TDEE calculations with confidence metrics
- `metabolic_adaptation_events` - Detected adaptation/plateau events
- `daily_adherence_logs` - Per-day adherence metrics
- `sustainability_scores` - Periodic sustainability assessments
- `weekly_adherence_summary` (view) - Pre-aggregated weekly adherence data

#### API Endpoints
- `GET /nutrition/tdee/{user_id}/detailed` - TDEE with confidence intervals
- `GET /nutrition/adherence/{user_id}/summary` - Adherence summary with sustainability
- `GET /nutrition/recommendations/{user_id}/options` - Multi-option recommendations
- `POST /nutrition/recommendations/{user_id}/select` - Apply selected option

#### Event Logging
Full context logging for analytics and AI personalization:
- `weekly_checkin_started/completed/dismissed`
- `detailed_tdee_viewed`
- `adherence_summary_viewed`
- `metabolic_adaptation_detected/acknowledged`
- `recommendation_options_viewed/selected`
- `sustainability_score_calculated`
- `weight_trend_analyzed`
- `plateau_detected`
- `diet_break_suggested`
- `refeed_suggested`

---

*Last Updated: January 2026*
