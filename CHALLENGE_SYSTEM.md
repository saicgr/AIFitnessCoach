# Workout Challenge System - Complete Documentation

## Overview

A comprehensive friend-to-friend workout challenge system with psychological pressure mechanics, challenge history tracking, and automatic activity feed integration.

## User Flow

### 1. Creating a Challenge

**Method A: From Activity Feed (Public "BEAT THIS")**
1. User A completes a workout → workout appears in activity feed
2. User B sees the workout post and clicks **"BEAT THIS 💪"** button
3. Challenge is automatically created and accepted
4. User B starts the workout immediately with challenge context

**Method B: Direct Friend Challenge (From Workout Complete Screen)**
1. User A completes a workout → sees "Challenge Friends" button
2. User A clicks button → friend selection dialog appears
3. User A selects one or more friends and adds optional message
4. Challenges are created and sent to selected friends
5. Friends receive notifications and can accept/decline

### 2. During the Challenge

**Active Workout Screen**
- **Challenge Banner** displayed at top showing:
  - Challenger's name
  - Target stats to beat (duration, volume)
  - Real-time comparison as user progresses

**Attempting to Quit**
- User clicks quit button → **Psychological Pressure Dialog** appears:
  - 🐔 Chicken emoji header
  - **"CHICKENING OUT?"** provocative title
  - Warning: "They'll see your excuse if you quit!"
  - Embarrassing quick-reply options:
    - "Too hard for me 😓"
    - "Not feeling it today 😴"
    - "This is impossible 😭"
    - "I give up 🏳️"
    - "Maybe next time 😅"
    - "I'm not ready yet 🙈"
    - "Custom reason..."
  - Prominent **"KEEP GOING! 💪"** button (green, encouraging)

- If user quits:
  - Quit reason stored in database
  - Challenger notified
  - Stats captured up to quit point
  - Challenge marked as 'abandoned'

### 3. Completing the Challenge

**Automatic Completion**
1. User B finishes workout → stats automatically sent to backend
2. Backend compares stats:
   - **Victory**: time ≤ target AND volume ≥ target
   - **Attempt**: partial success or didn't beat both metrics
3. Backend auto-posts result to activity feed (configurable)
4. **Challenge Complete Dialog** appears (1.5s delay):
   - **Victory**: Gold trophy 🏆, confetti animation, "YOU BEAT IT!"
   - **Attempt**: "WORKOUT COMPLETE" with stats comparison
   - Shows time/volume differences
   - "View Feed" button to see public post

### 4. Challenge History

**Profile → Challenge History**
- **Stats Overview**: Won/Lost/Win Rate displayed prominently
- **5 Filter Tabs**:
  1. **All** - Complete challenge history
  2. **Won** - Victories only (green badges)
  3. **Lost** - Failed challenges (red badges)
  4. **Quit** - Abandoned challenges (yellow, shows quit reason with 🐔)
  5. **Pending** - Active/unanswered challenges

**Challenge Cards Show**:
- Direction indicator (↗️ Sent / ↙️ Received)
- Challenger/opponent name and avatar
- Workout name and target stats
- Result badge (VICTORY / Failed / QUIT / In Progress)
- Quit reason (if abandoned) with chicken emoji
- Stats comparison for completed challenges
- **Retry Button** (for received completed/abandoned challenges)

**Retrying Challenges**
- Click "Retry Challenge" → confirmation dialog
- "This will challenge [name] back with the same workout!"
- Creates new challenge in reverse direction with retry tracking
- Challenge marked as `is_retry = true` in database
- Links to original challenge via `retried_from_challenge_id`
- Original challenge's `retry_count` auto-increments
- ChromaDB logs retry event separately from new challenges
- Retry message: "Round 2! 💪"
- User can track retry win rate and most retried workouts

### 5. Retry Tracking & Analytics

**Retry Statistics (Profile)**
- **Total Retries**: Number of times user has retried challenges
- **Retries Won**: How many retry attempts resulted in victories
- **Retry Win Rate**: Percentage of retries that were successful
- **Most Retried Workout**: Which workout they retry most often
- **Retry Chains**: View full history of retry attempts

**Database Tracking**
- Every retry is linked to original challenge
- Retry count tracked on original challenge
- Recursive query to view full retry chains
- Statistics calculated via database function

**AI Insights (via ChromaDB)**
- "You usually win on your 2nd retry attempt!"
- "Leg workouts require 3x more retries on average"
- "Your persistence paid off - 5th retry was the charm!"
- "Friends are retrying your workouts more - you set tough benchmarks!"

## Technical Architecture

### Database Schema

#### `workout_challenges` Table
```sql
- id (UUID, PK)
- from_user_id (UUID, FK → users)
- to_user_id (UUID, FK → users)
- workout_log_id (UUID, FK → workout_logs)
- activity_id (UUID, FK → activity_feed)
- workout_name (VARCHAR)
- workout_data (JSONB) -- Target stats
- challenge_message (TEXT)
- status (VARCHAR) -- pending/accepted/declined/completed/expired/abandoned
- accepted_at (TIMESTAMP)
- declined_at (TIMESTAMP)
- completed_at (TIMESTAMP)
- abandoned_at (TIMESTAMP)
- challenger_stats (JSONB)
- challenged_stats (JSONB)
- did_beat (BOOLEAN)
- quit_reason (TEXT) -- Shown to challenger
- partial_stats (JSONB) -- Stats before quitting
- is_retry (BOOLEAN) -- Whether this is a retry challenge
- retried_from_challenge_id (UUID, FK → workout_challenges) -- Original challenge if retry
- retry_count (INTEGER) -- Number of times this challenge has been retried
- created_at (TIMESTAMP)
- expires_at (TIMESTAMP) -- Default: NOW() + 7 days
```

#### `challenge_notifications` Table
```sql
- id (UUID, PK)
- challenge_id (UUID, FK → workout_challenges)
- user_id (UUID, FK → users)
- notification_type (VARCHAR) -- challenge_received/accepted/completed/beaten/abandoned
- is_read (BOOLEAN)
- read_at (TIMESTAMP)
- created_at (TIMESTAMP)
```

#### Database Triggers
- `create_challenge_notification()` - Auto-notify on challenge creation
- `notify_challenge_accepted()` - Auto-notify when accepted
- `notify_challenge_abandoned()` - Auto-notify when user quits
- `increment_retry_count()` - Auto-increment retry_count when retry is created
- `expire_old_challenges()` - Auto-expire pending challenges after 7 days

#### Database Functions
- `get_user_retry_stats(p_user_id)` - Get retry statistics for a user
  - Returns: total_retries, retries_won, retry_win_rate, most_retried_workout, avg_retries_to_win
- `get_user_abandonment_stats(p_user_id)` - Get quit statistics for a user
  - Returns: total_abandoned, most_common_quit_reason, abandonment_rate

#### Views
- `pending_challenges_with_users` - Active challenges with user details
- `challenge_leaderboard` - Win/loss/abandonment/retry stats per user (includes retry counts and win rates)
- `challenge_retry_chains` - Recursive view showing full retry chains for challenges

### Backend API Endpoints

**Base Path**: `/api/v1/challenges`

#### Core Challenge Operations
```
POST   /create                    Create friend-to-friend challenge
GET    /list                      List user's challenges (sent/received)
GET    /{challenge_id}            Get challenge details
POST   /accept/{challenge_id}     Accept pending challenge
POST   /decline/{challenge_id}    Decline pending challenge
POST   /complete/{challenge_id}   Complete challenge (auto-called on workout finish)
POST   /abandon/{challenge_id}    Abandon challenge midway (quit with reason)
DELETE /{challenge_id}            Delete pending challenge (sender only)
```

#### Stats & Leaderboard
```
GET    /stats                     User's challenge statistics
GET    /leaderboard               Global challenge leaderboard
```

#### All Endpoints Include:
- ChromaDB logging for AI insights
- Auto-posting to activity feed (configurable)
- Notification creation via triggers
- Row Level Security (RLS) policies

### Frontend (Flutter)

#### Services
- **`ChallengesService`** (`lib/data/services/challenges_service.dart`)
  - API client wrapper for all challenge endpoints
  - Type-safe request/response handling
  - Error handling with user-friendly messages

#### Screens
- **`ChallengesScreen`** (`lib/screens/challenges/challenges_screen.dart`)
  - List all challenges (sent/received)
  - Accept/decline pending challenges
  - Navigate to active challenges

- **`ChallengeHistoryScreen`** (`lib/screens/profile/challenge_history_screen.dart`)
  - Complete challenge log with stats
  - 5 filter tabs (All/Won/Lost/Quit/Pending)
  - Retry functionality

- **`ActiveWorkoutScreen`** (updated with challenge support)
  - Challenge banner showing stats to beat
  - Challenge quit dialog integration
  - Pass challenge data to completion screen

- **`WorkoutCompleteScreen`** (updated with challenge support)
  - Auto-complete challenge on finish
  - Show victory/attempt dialog
  - "Challenge Friends" button

#### Widgets
- **`ChallengeFriendsDialog`** - Friend selector for creating challenges
- **`ChallengeCard`** - Display individual challenge in lists
- **`ChallengeCompleteDialog`** - Victory/attempt results with confetti
- **`ChallengeQuitDialog`** - Psychological pressure quit flow
- **`RetryConfirmationDialog`** - Confirm challenge retry

### Activity Feed Integration

#### New Activity Types
```dart
'challenge_victory'    // User beat the challenge
'challenge_completed'  // User attempted but didn't beat it
```

#### Auto-Posted Data
```json
{
  "workout_name": "Beast Mode Legs",
  "challenger_name": "John Doe",
  "challenger_id": "uuid",
  "challenge_id": "uuid",
  "did_beat": true,
  "your_duration": 28,
  "your_volume": 12500,
  "their_duration": 35,
  "their_volume": 10000,
  "time_difference": 7,      // Minutes faster
  "volume_difference": 2500   // More weight lifted
}
```

#### Feed Display
- **Victory Posts**: Gold trophy header, green stats, celebratory copy
- **Attempt Posts**: Standard header, comparison stats, encouraging copy
- **Interactive**: "View Challenge" button to see full details

## Psychological Pressure Mechanics

### Design Philosophy
The quit dialog uses **loss aversion** and **social pressure** to discourage abandonment:

1. **Provocative Language**: "CHICKENING OUT?" with chicken emoji
2. **Social Consequence**: "They'll see your excuse if you quit!"
3. **Embarrassing Options**: Each reason is designed to be slightly humiliating
4. **Asymmetric Buttons**:
   - Quit options are small, red, pill-shaped
   - Continue button is large, green, prominent
5. **Public Shame**: Quit reasons are visible to challenger and in history

### Quit Reason Storage
- Stored in `workout_challenges.quit_reason`
- Displayed in challenge history with 🐔 emoji
- Shown in notifications to challenger
- Logged to ChromaDB for AI pattern analysis
  - "Why do users quit?"
  - "Which workouts have highest abandonment?"
  - "Personalized encouragement based on quit patterns"

## Winner Determination Logic

```python
def determine_winner(challenger_stats, challenged_stats):
    """
    User must beat BOTH time AND volume to win.

    Time: Finish in same or less time (≤)
    Volume: Lift same or more weight (≥)
    """
    time_beat = challenged_stats['duration_minutes'] <= challenger_stats['duration_minutes']
    volume_beat = challenged_stats['total_volume'] >= challenger_stats['total_volume']

    return time_beat and volume_beat
```

**Examples**:
- ✅ **Victory**: 25 min, 12000 lbs vs target 30 min, 10000 lbs (faster AND heavier)
- ❌ **Attempt**: 20 min, 8000 lbs vs target 30 min, 10000 lbs (faster but lighter)
- ❌ **Attempt**: 35 min, 12000 lbs vs target 30 min, 10000 lbs (heavier but slower)

## ChromaDB Integration

All challenge events are logged to ChromaDB for AI insights:

### Logged Events
```python
# Challenge creation
"John challenged Sarah to 'Beast Mode Legs' (35 min, 10000 lbs)"

# Challenge retry
"Sarah RETRIED challenge against John for 'Beast Mode Legs' (not giving up!)"

# Challenge completion
"Sarah beat John's 'Beast Mode Legs' challenge (28 min vs 35 min, 12500 lbs vs 10000 lbs)"

# Challenge abandonment
"Mike abandoned challenge from Lisa for 'Arm Destroyer' with reason: Too hard for me 😓"

# Challenge patterns
"Users tend to abandon leg workouts 3x more than upper body"
"Most users win challenges on their 2nd retry attempt"
```

### AI Use Cases
- **Personalized Encouragement**: "You've quit the last 2 leg challenges at the halfway point. Let's push through this one together!"
- **Smart Challenge Recommendations**: "Based on your history, you have an 80% win rate on upper body challenges"
- **Workout Difficulty Calibration**: "This workout has a 65% abandonment rate - it's tough but you can do it!"
- **Social Insights**: "Your friends challenge you to leg workouts 2x more - they think it's your weakness!"
- **Retry Insights**: "You usually win on your 2nd retry attempt - keep going!"
- **Persistence Recognition**: "This is your 5th retry for this workout - your determination is inspiring!"
- **Workout Analysis**: "Leg workouts require 3x more retries on average - you're not alone!"

## Migrations

### Migration 030: Core Challenge System
**File**: `backend/migrations/030_workout_challenges.sql`
- Creates `workout_challenges` table
- Creates `challenge_notifications` table
- Adds RLS policies
- Creates triggers for auto-notifications
- Creates views for leaderboard and pending challenges

### Migration 031: Abandonment Support
**File**: `backend/migrations/031_challenge_abandonment.sql`
- Adds `abandoned_at`, `quit_reason`, `partial_stats` columns
- Updates status constraint to include 'abandoned'
- Adds `notify_challenge_abandoned()` trigger
- Updates leaderboard view with abandonment stats
- Adds `get_user_abandonment_stats()` function

### Migration 032: Retry Tracking
**File**: `backend/migrations/032_challenge_retry_tracking.sql`
- Adds `is_retry`, `retried_from_challenge_id`, `retry_count` columns
- Creates `increment_retry_count()` trigger (auto-increments when retry created)
- Updates `challenge_leaderboard` view with retry statistics
- Adds `get_user_retry_stats()` function (total retries, retry win rate, most retried workout)
- Creates `challenge_retry_chains` recursive view for visualizing retry chains
- Adds indexes for retry queries

## Configuration Options

### Backend
```python
# challenges.py
auto_post_to_feed: bool = True  # Auto-post challenge results to feed
```

### Frontend
```dart
// Can be configured in app settings
final showChallengeBanner = true;  // Show challenge banner during workout
final allowChallengeQuit = true;   // Allow quitting challenges
final quitDialogDelay = 500;       // ms delay before showing quit dialog
```

## Testing Checklist

- [ ] Create challenge from workout complete screen
- [ ] Create challenge from activity feed "BEAT THIS"
- [ ] Accept/decline pending challenges
- [ ] View challenge banner during active workout
- [ ] Attempt to quit challenge (should show psychological dialog)
- [ ] Complete challenge successfully (victory flow)
- [ ] Complete challenge without beating (attempt flow)
- [ ] View victory post in activity feed
- [ ] View challenge history (all tabs)
- [ ] Retry a failed challenge
- [ ] View leaderboard stats
- [ ] Receive notifications for challenge events
- [ ] ChromaDB logs created for all events

## Future Enhancements

### Potential Features
1. **Challenge Streaks**: Win 5 in a row for special badge
2. **Team Challenges**: Multiple users vs multiple users
3. **Ranked Challenges**: Win/loss affects ranking points
4. **Challenge Modifiers**: "Double the weight" or "Half the time"
5. **Spectator Mode**: Friends can watch live workout progress
6. **Challenge Chat**: Trash talk before/during/after
7. **Rewards**: Unlock achievements for challenge milestones
8. **AI Coach Integration**: "This challenge is perfectly suited to your strengths!"
9. **Challenge Templates**: Save favorite challenge formats
10. **Rematch**: Instant rematch button after completion

### Analytics Opportunities
- Most challenged workouts
- Average challenge completion rate
- Peak challenge hours (when are people most competitive?)
- Friend pairs with most challenges
- Quit reason trends over time
- Challenge difficulty calibration (auto-adjust targets)

## Files Modified/Created

### Backend
```
backend/
├── migrations/
│   ├── 030_workout_challenges.sql          (NEW)
│   └── 031_challenge_abandonment.sql       (NEW)
├── models/
│   └── workout_challenges.py               (NEW)
└── api/v1/
    ├── challenges.py                       (NEW)
    └── __init__.py                         (UPDATED - registered challenges router)
```

### Frontend
```
mobile/flutter/lib/
├── data/services/
│   └── challenges_service.dart             (NEW)
├── screens/
│   ├── challenges/
│   │   ├── challenges_screen.dart          (NEW)
│   │   └── widgets/
│   │       ├── challenge_card.dart         (NEW)
│   │       ├── challenge_friends_dialog.dart (NEW)
│   │       ├── challenge_complete_dialog.dart (NEW)
│   │       └── challenge_quit_dialog.dart  (NEW)
│   ├── profile/
│   │   └── challenge_history_screen.dart   (NEW)
│   ├── workout/
│   │   ├── active_workout_screen.dart      (UPDATED - challenge support)
│   │   └── workout_complete_screen.dart    (UPDATED - challenge completion)
│   └── social/
│       └── widgets/
│           └── activity_card.dart          (UPDATED - challenge victory posts)
```

## Key Design Decisions

1. **Two Challenge Types**:
   - Public "BEAT THIS" (from feed, auto-accepted)
   - Direct friend challenges (requires acceptance)

2. **Dual Metrics**: Must beat BOTH time AND volume to win (prevents gaming)

3. **Psychological Pressure**: Quit dialog designed to discourage abandonment through social consequences

4. **Auto-Posting**: Challenge results automatically posted to feed for viral engagement

5. **7-Day Expiration**: Pending challenges auto-expire to prevent stale notifications

6. **Retry Functionality**: Lost challenges can be retried with one click

7. **ChromaDB Integration**: All events logged for AI-powered insights and recommendations

8. **No Rematch Spam Protection**: Each challenge is independent, no auto-rematch loops

## Security & Privacy

- **RLS Policies**: Users can only view/modify their own challenges
- **Friend Verification**: Challenges only allowed between connected friends
- **No Self-Challenges**: Database constraint prevents challenging yourself
- **Workout Data Privacy**: Only challenged stats shared, not full workout details
- **Quit Reason Visibility**: Only challenger sees quit reason (not public)
- **Activity Feed Control**: Challenge results posted with "friends" visibility

---

**Version**: 1.0
**Last Updated**: 2025-12-24
**Status**: ✅ Fully Implemented and Deployed
