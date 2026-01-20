# Plan: XP Events System (Daily Login, Streaks, Double XP Weekends)

## Overview
Add a comprehensive XP bonus and event system inspired by Battlefield's progression mechanics. This includes:
- **First-time login bonus** (welcome XP)
- **Daily check-in XP** (login streaks)
- **Weekly/Monthly XP bonuses**
- **Double XP events** (weekends, holidays, special events)
- **User context logging** for personalization
- **FEATURES.md updates** documenting the new system

### User Preferences:
- **Event Control**: Manual toggle by admin (not automatic)
- **XP Multiplier**: 2x standard (Double XP)

---

## 1. XP Events Database Schema

### New Migration: `166_xp_events.sql`

```sql
-- =============================================================================
-- XP EVENTS SYSTEM (Battlefield-style progression bonuses)
-- =============================================================================

-- Daily Login Tracking
CREATE TABLE user_login_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL UNIQUE,
  current_streak INT DEFAULT 0,           -- Days in current streak
  longest_streak INT DEFAULT 0,           -- Personal best
  total_logins INT DEFAULT 0,             -- Lifetime logins
  last_login_date DATE,                   -- Last login (date only)
  streak_start_date DATE,                 -- When current streak started
  first_login_at TIMESTAMPTZ,             -- First ever login
  last_daily_bonus_claimed DATE,          -- Prevents double-claiming
  last_weekly_bonus_claimed DATE,         -- Weekly bonus tracker
  last_monthly_bonus_claimed DATE,        -- Monthly bonus tracker
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- XP Events (Double XP weekends, seasonal events, etc.)
CREATE TABLE xp_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  event_type TEXT NOT NULL,               -- 'weekend_bonus', 'holiday', 'seasonal', 'flash', 'milestone'
  description TEXT,
  xp_multiplier DECIMAL(3,2) DEFAULT 1.0, -- 2.0 = Double XP
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  applies_to TEXT[] DEFAULT ARRAY['all'], -- ['workout', 'achievement', 'streak'] or ['all']
  icon_name TEXT,                         -- For UI display
  banner_color TEXT,                      -- Hex color for event banner
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Event Participation (track who participated in each event)
CREATE TABLE user_event_participation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  event_id UUID REFERENCES xp_events NOT NULL,
  participated_at TIMESTAMPTZ DEFAULT NOW(),
  base_xp_earned INT DEFAULT 0,
  bonus_xp_earned INT DEFAULT 0,          -- Extra from multiplier
  source TEXT,                            -- What triggered the bonus
  UNIQUE(user_id, event_id, participated_at::DATE)
);

-- XP Bonus Templates (defines bonus amounts)
CREATE TABLE xp_bonus_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bonus_type TEXT NOT NULL UNIQUE,        -- 'first_login', 'daily_login', 'weekly_bonus', 'monthly_bonus'
  base_xp INT NOT NULL,
  description TEXT,
  streak_multiplier BOOLEAN DEFAULT false, -- If true, multiply by streak
  max_streak_multiplier INT DEFAULT 7,     -- Cap for streak multiplication
  is_active BOOLEAN DEFAULT true
);

-- Insert default bonus templates
INSERT INTO xp_bonus_templates (bonus_type, base_xp, description, streak_multiplier, max_streak_multiplier) VALUES
-- Login bonuses
('first_login', 500, 'Welcome bonus for new users', false, 1),
('daily_login', 25, 'Daily check-in bonus', true, 7),
('streak_milestone_7', 100, '7-day login streak bonus', false, 1),
('streak_milestone_30', 500, '30-day login streak bonus', false, 1),
('streak_milestone_100', 2000, '100-day login streak bonus', false, 1),
('streak_milestone_365', 10000, '365-day login streak bonus', false, 1),
-- Weekly checkpoints
('weekly_workouts', 200, 'Complete 3+ workouts this week', false, 1),
('weekly_perfect', 500, 'Hit ALL scheduled workouts', false, 1),
('weekly_protein', 150, 'Hit protein goal 5+ days', false, 1),
('weekly_calories', 150, 'Stay within calorie range 5+ days', false, 1),
('weekly_hydration', 100, 'Hit water goal 5+ days', false, 1),
('weekly_weight_log', 75, 'Log weight 3+ times', false, 1),
('weekly_habits', 100, 'Complete 70%+ of habits', false, 1),
('weekly_streak', 100, 'Maintain 7+ day workout streak', false, 1),
-- Monthly checkpoints
('monthly_dedication', 500, '20+ active days this month', false, 1),
('monthly_goal_met', 1000, 'Hit your primary fitness goal', false, 1),
('monthly_nutrition', 500, 'Hit macros 20+ days', false, 1),
('monthly_consistency', 750, 'No missed scheduled workouts', false, 1),
('monthly_hydration', 300, 'Hit water goal 25+ days', false, 1),
('monthly_weight', 400, 'On track with weight goal', false, 1),
('monthly_habits', 400, '80%+ habit completion', false, 1),
('monthly_prs', 500, 'Set 3+ personal records', false, 1);

-- Weekly/Monthly checkpoint tracking
CREATE TABLE user_checkpoint_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  checkpoint_type TEXT NOT NULL,           -- 'weekly' or 'monthly'
  period_start DATE NOT NULL,              -- Monday for weekly, 1st for monthly
  period_end DATE NOT NULL,
  checkpoints_earned TEXT[] DEFAULT '{}',  -- Array of earned checkpoint types
  total_xp_earned INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, checkpoint_type, period_start)
);

CREATE INDEX idx_checkpoint_progress_user ON user_checkpoint_progress(user_id);
CREATE INDEX idx_checkpoint_progress_period ON user_checkpoint_progress(period_start, period_end);

-- Indexes
CREATE INDEX idx_login_streaks_user ON user_login_streaks(user_id);
CREATE INDEX idx_login_streaks_last_date ON user_login_streaks(last_login_date);
CREATE INDEX idx_xp_events_active ON xp_events(is_active, start_at, end_at);
CREATE INDEX idx_event_participation_user ON user_event_participation(user_id);
CREATE INDEX idx_event_participation_event ON user_event_participation(event_id);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Check and process daily login
CREATE OR REPLACE FUNCTION process_daily_login(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_streak_record user_login_streaks%ROWTYPE;
  v_today DATE := CURRENT_DATE;
  v_yesterday DATE := CURRENT_DATE - 1;
  v_is_first_login BOOLEAN := false;
  v_streak_broken BOOLEAN := false;
  v_daily_bonus INT := 0;
  v_streak_bonus INT := 0;
  v_first_login_bonus INT := 0;
  v_active_events JSON;
  v_total_multiplier DECIMAL := 1.0;
BEGIN
  -- Get or create streak record
  SELECT * INTO v_streak_record FROM user_login_streaks WHERE user_id = p_user_id;

  IF NOT FOUND THEN
    -- First ever login
    v_is_first_login := true;
    INSERT INTO user_login_streaks (user_id, current_streak, longest_streak, total_logins,
                                     last_login_date, streak_start_date, first_login_at,
                                     last_daily_bonus_claimed)
    VALUES (p_user_id, 1, 1, 1, v_today, v_today, NOW(), v_today)
    RETURNING * INTO v_streak_record;

    -- Award first login bonus
    SELECT base_xp INTO v_first_login_bonus FROM xp_bonus_templates WHERE bonus_type = 'first_login';

  ELSIF v_streak_record.last_login_date = v_today THEN
    -- Already logged in today, no bonus
    RETURN json_build_object(
      'already_claimed', true,
      'current_streak', v_streak_record.current_streak,
      'xp_awarded', 0
    );

  ELSIF v_streak_record.last_login_date = v_yesterday THEN
    -- Continuing streak
    UPDATE user_login_streaks SET
      current_streak = current_streak + 1,
      longest_streak = GREATEST(longest_streak, current_streak + 1),
      total_logins = total_logins + 1,
      last_login_date = v_today,
      last_daily_bonus_claimed = v_today,
      updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;

  ELSE
    -- Streak broken
    v_streak_broken := true;
    UPDATE user_login_streaks SET
      current_streak = 1,
      total_logins = total_logins + 1,
      last_login_date = v_today,
      streak_start_date = v_today,
      last_daily_bonus_claimed = v_today,
      updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_streak_record;
  END IF;

  -- Calculate daily bonus (with streak multiplier)
  SELECT base_xp,
         CASE WHEN streak_multiplier THEN LEAST(v_streak_record.current_streak, max_streak_multiplier) ELSE 1 END
  INTO v_daily_bonus
  FROM xp_bonus_templates WHERE bonus_type = 'daily_login';

  v_daily_bonus := v_daily_bonus * LEAST(v_streak_record.current_streak, 7);

  -- Check for streak milestone bonuses
  IF v_streak_record.current_streak = 7 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_7';
  ELSIF v_streak_record.current_streak = 30 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_30';
  ELSIF v_streak_record.current_streak = 100 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_100';
  ELSIF v_streak_record.current_streak = 365 THEN
    SELECT base_xp INTO v_streak_bonus FROM xp_bonus_templates WHERE bonus_type = 'streak_milestone_365';
  END IF;

  -- Get active XP events and calculate multiplier
  SELECT json_agg(e.*), COALESCE(MAX(e.xp_multiplier), 1.0)
  INTO v_active_events, v_total_multiplier
  FROM xp_events e
  WHERE e.is_active = true
    AND NOW() BETWEEN e.start_at AND e.end_at
    AND ('all' = ANY(e.applies_to) OR 'daily_login' = ANY(e.applies_to));

  -- Apply multiplier
  v_daily_bonus := FLOOR(v_daily_bonus * v_total_multiplier);
  v_first_login_bonus := FLOOR(v_first_login_bonus * v_total_multiplier);

  -- Award XP
  IF v_first_login_bonus > 0 THEN
    PERFORM award_xp(p_user_id, v_first_login_bonus, 'first_login', NULL, 'Welcome to FitWiz!');
  END IF;

  IF v_daily_bonus > 0 THEN
    PERFORM award_xp(p_user_id, v_daily_bonus, 'daily_checkin', NULL,
                     'Day ' || v_streak_record.current_streak || ' streak bonus');
  END IF;

  IF v_streak_bonus > 0 THEN
    PERFORM award_xp(p_user_id, v_streak_bonus, 'streak', NULL,
                     v_streak_record.current_streak || '-day streak milestone!');
  END IF;

  RETURN json_build_object(
    'is_first_login', v_is_first_login,
    'streak_broken', v_streak_broken,
    'current_streak', v_streak_record.current_streak,
    'longest_streak', v_streak_record.longest_streak,
    'daily_xp', v_daily_bonus,
    'first_login_xp', v_first_login_bonus,
    'streak_milestone_xp', v_streak_bonus,
    'total_xp_awarded', v_daily_bonus + v_first_login_bonus + v_streak_bonus,
    'active_events', v_active_events,
    'multiplier', v_total_multiplier
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get active XP events
CREATE OR REPLACE FUNCTION get_active_xp_events()
RETURNS SETOF xp_events AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM xp_events
  WHERE is_active = true
    AND NOW() BETWEEN start_at AND end_at
  ORDER BY xp_multiplier DESC;
END;
$$ LANGUAGE plpgsql;

-- Enable weekend double XP (call via cron or manually)
CREATE OR REPLACE FUNCTION enable_weekend_double_xp()
RETURNS UUID AS $$
DECLARE
  v_event_id UUID;
  v_start TIMESTAMPTZ;
  v_end TIMESTAMPTZ;
BEGIN
  -- Calculate this weekend (Saturday 00:00 to Sunday 23:59)
  v_start := date_trunc('week', NOW()) + INTERVAL '5 days'; -- Saturday
  v_end := date_trunc('week', NOW()) + INTERVAL '7 days' - INTERVAL '1 second'; -- Sunday 23:59:59

  INSERT INTO xp_events (event_name, event_type, description, xp_multiplier, start_at, end_at, applies_to, icon_name, banner_color)
  VALUES (
    'Double XP Weekend',
    'weekend_bonus',
    'Earn 2x XP on all activities this weekend!',
    2.0,
    v_start,
    v_end,
    ARRAY['all'],
    'bolt',
    '#FFD700'
  )
  RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE user_login_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_event_participation ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_bonus_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see own streaks" ON user_login_streaks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service manages streaks" ON user_login_streaks FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Anyone sees active events" ON xp_events FOR SELECT USING (is_active = true);
CREATE POLICY "Service manages events" ON xp_events FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Users see own participation" ON user_event_participation FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Service manages participation" ON user_event_participation FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Anyone sees bonus templates" ON xp_bonus_templates FOR SELECT USING (true);
```

---

## 2. Backend API Changes

### File: `backend/api/v1/xp.py` (NEW)

```python
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import date, datetime
from typing import Optional, List

router = APIRouter(prefix="/xp", tags=["XP & Progression"])

class DailyLoginResponse(BaseModel):
    is_first_login: bool
    streak_broken: bool
    current_streak: int
    longest_streak: int
    daily_xp: int
    first_login_xp: int
    streak_milestone_xp: int
    total_xp_awarded: int
    active_events: Optional[List[dict]]
    multiplier: float

class XPEvent(BaseModel):
    id: str
    event_name: str
    event_type: str
    description: Optional[str]
    xp_multiplier: float
    start_at: datetime
    end_at: datetime
    icon_name: Optional[str]
    banner_color: Optional[str]

class LoginStreakInfo(BaseModel):
    current_streak: int
    longest_streak: int
    total_logins: int
    last_login_date: Optional[date]
    first_login_at: Optional[datetime]

@router.post("/daily-login", response_model=DailyLoginResponse)
async def process_daily_login(user_id: str, supabase=Depends(get_supabase)):
    """Process daily login and award XP bonuses."""
    result = supabase.rpc("process_daily_login", {"p_user_id": user_id}).execute()
    return result.data

@router.get("/login-streak/{user_id}", response_model=LoginStreakInfo)
async def get_login_streak(user_id: str, supabase=Depends(get_supabase)):
    """Get user's login streak information."""
    result = supabase.table("user_login_streaks").select("*").eq("user_id", user_id).single().execute()
    return result.data

@router.get("/active-events", response_model=List[XPEvent])
async def get_active_events(supabase=Depends(get_supabase)):
    """Get all currently active XP events."""
    result = supabase.rpc("get_active_xp_events").execute()
    return result.data

@router.post("/enable-weekend-double-xp")
async def enable_weekend_double_xp(supabase=Depends(get_supabase)):
    """Enable double XP for the upcoming weekend (admin only)."""
    result = supabase.rpc("enable_weekend_double_xp").execute()
    return {"event_id": result.data, "message": "Weekend Double XP enabled"}
```

---

## 3. Flutter Frontend Changes

### 3.1 New Models: `lib/data/models/xp_event.dart`

```dart
import 'package:json_annotation/json_annotation.dart';
part 'xp_event.g.dart';

@JsonSerializable()
class XPEvent {
  final String id;
  @JsonKey(name: 'event_name')
  final String eventName;
  @JsonKey(name: 'event_type')
  final String eventType;
  final String? description;
  @JsonKey(name: 'xp_multiplier')
  final double xpMultiplier;
  @JsonKey(name: 'start_at')
  final DateTime startAt;
  @JsonKey(name: 'end_at')
  final DateTime endAt;
  @JsonKey(name: 'icon_name')
  final String? iconName;
  @JsonKey(name: 'banner_color')
  final String? bannerColor;

  bool get isDoubleXP => xpMultiplier >= 2.0;
  Duration get timeRemaining => endAt.difference(DateTime.now());
}

@JsonSerializable()
class LoginStreakInfo {
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'total_logins')
  final int totalLogins;
  @JsonKey(name: 'last_login_date')
  final String? lastLoginDate;
  @JsonKey(name: 'first_login_at')
  final DateTime? firstLoginAt;
}

@JsonSerializable()
class DailyLoginResult {
  @JsonKey(name: 'is_first_login')
  final bool isFirstLogin;
  @JsonKey(name: 'streak_broken')
  final bool streakBroken;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  @JsonKey(name: 'daily_xp')
  final int dailyXp;
  @JsonKey(name: 'first_login_xp')
  final int firstLoginXp;
  @JsonKey(name: 'streak_milestone_xp')
  final int streakMilestoneXp;
  @JsonKey(name: 'total_xp_awarded')
  final int totalXpAwarded;
  @JsonKey(name: 'active_events')
  final List<XPEvent>? activeEvents;
  final double multiplier;
}
```

### 3.2 Update XP Provider

Add to `xp_provider.dart`:
- `activeEvents` state
- `loginStreak` state
- `loadActiveEvents()` method
- `processDailyLogin()` method
- `loginStreakProvider` convenience provider

### 3.3 New Widget: `lib/widgets/double_xp_banner.dart`

A banner that appears when Double XP events are active, showing:
- Event name & multiplier
- Countdown timer
- Animated pulsing glow effect

### 3.4 Update Home Screen

- Call `processDailyLogin()` on app startup/resume
- Show celebration for first login bonus
- Show streak continuation/broken notification
- Display Double XP banner when active

---

## 4. User Context Logging Enhancement

### Update Migration: `059_user_context_logs.sql`

Add new event types:
```sql
-- Add XP-related event types
-- 'daily_login' - User logged in (for streak tracking)
-- 'xp_earned' - XP was awarded
-- 'level_up' - User leveled up
-- 'trophy_earned' - Achievement unlocked
-- 'event_participation' - User participated in XP event
```

### Log Context on Login

When user opens app, log:
```json
{
  "event_type": "daily_login",
  "event_data": {
    "streak_day": 5,
    "xp_earned": 125,
    "active_events": ["double_xp_weekend"]
  },
  "context": {
    "time_of_day": "morning",
    "day_of_week": "saturday",
    "is_weekend": true
  }
}
```

---

## 5. FEATURES.md Updates

Add new section after XP System:

```markdown
## XP Events & Daily Bonuses (Battlefield-Style Progression)

### Daily Login System
| Feature | Description | XP Reward |
|---------|-------------|-----------|
| First Login Bonus | Welcome XP for new users | 500 XP |
| Daily Check-in | Login each day for bonus XP | 25 × streak (max 175) |
| 7-Day Streak | Complete a week of logins | +100 XP |
| 30-Day Streak | One month dedication | +500 XP |
| 100-Day Streak | Century club | +2,000 XP |
| 365-Day Streak | Full year commitment | +10,000 XP |

### Double XP Events (Admin-Controlled)
| Event Type | Multiplier | Duration | Trigger |
|------------|------------|----------|---------|
| Weekend Warrior | 2x | Sat-Sun | Manual admin toggle |
| Holiday Special | 2x | 24-72 hours | Manual admin toggle |
| Flash Event | 2x | 2-6 hours | Manual admin toggle |
| Milestone Event | 2x | 24 hours | Manual admin toggle |

> **Note**: All events are manually enabled via admin API or dashboard. No automatic scheduling.

### Weekly Checkpoint Rewards
| Checkpoint | Requirement | XP |
|------------|-------------|-----|
| Weekly Workouts | Complete 3+ workouts | 200 XP |
| Perfect Week | Hit ALL scheduled workouts | 500 XP |
| Weekly Protein Goal | Hit protein goal 5+ days | 150 XP |
| Weekly Calorie Target | Stay within calorie range 5+ days | 150 XP |
| Weekly Hydration | Hit water goal 5+ days | 100 XP |
| Weekly Weight Log | Log weight 3+ times | 75 XP |
| Weekly Habits | Complete 70%+ of habits | 100 XP |
| Weekly Streak Bonus | Maintain 7+ day workout streak | 100 XP |

### Monthly Checkpoint Rewards
| Checkpoint | Requirement | XP |
|------------|-------------|-----|
| Monthly Dedication | 20+ active days | 500 XP |
| Monthly Goal Met | Hit your primary fitness goal | 1,000 XP |
| Monthly Nutrition Master | Hit macros 20+ days | 500 XP |
| Monthly Consistency | No missed scheduled workouts | 750 XP |
| Monthly Hydration Champ | Hit water goal 25+ days | 300 XP |
| Monthly Weight Progress | On track with weight goal | 400 XP |
| Monthly Habit Master | 80%+ habit completion | 400 XP |
| Monthly PR Hunter | Set 3+ personal records | 500 XP |
```

---

## 6. Files to Create/Modify

### New Files:
1. `backend/migrations/166_xp_events.sql` - Database schema
2. `backend/api/v1/xp.py` - API endpoints
3. `mobile/flutter/lib/data/models/xp_event.dart` - Event models
4. `mobile/flutter/lib/widgets/double_xp_banner.dart` - Event banner UI

### Modified Files:
1. `mobile/flutter/lib/data/providers/xp_provider.dart` - Add event state
2. `mobile/flutter/lib/data/repositories/xp_repository.dart` - Add API calls
3. `mobile/flutter/lib/screens/home/home_screen.dart` - Trigger daily login
4. `mobile/flutter/lib/widgets/xp_progress_card.dart` - Show multiplier badge
5. `FEATURES.md` - Document new features
6. `backend/api/v1/__init__.py` - Register new router

---

## 7. Verification

1. **Database**: Run migration, verify tables and functions created
2. **First Login**: New user gets 500 XP welcome bonus
3. **Daily Streak**:
   - Day 1: 25 XP
   - Day 2: 50 XP
   - Day 7: 175 XP + 100 XP milestone = 275 XP
4. **Double XP Weekend**:
   - Enable via API/cron
   - Verify 2x multiplier applies
   - Banner shows in UI
5. **Streak Break**: Miss a day → streak resets to 1
6. **Context Logging**: Login events recorded with streak info

---

## Summary

This plan adds a Battlefield-inspired XP event system with:
- **500 XP first login bonus**
- **Daily check-in XP** scaling with streak (25-175 XP)
- **Streak milestone bonuses** (7, 30, 100, 365 days)
- **Double XP weekends** (toggleable by admin)
- **Event banner UI** with countdown
- **Weekly/monthly activity bonuses**
- **Full user context logging** for personalization

The system incentivizes daily engagement while the Double XP events create excitement and FOMO (like Battlefield's limited-time events).
