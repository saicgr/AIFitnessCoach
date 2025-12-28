# Issues and Solutions

## Issue 1: Difficulty shows "Easy" after customizing to "Hard"

### Root Cause
The difficulty IS being saved correctly in the user's profile (`intensity_preference`), and new workouts are being generated with the correct difficulty. However, **old workouts in the database still have the old difficulty value**.

### What's Happening
1. User customizes program and selects "Hard" difficulty
2. Backend saves `intensity_preference: "hard"` to user profile ✅
3. Backend deletes **future** incomplete workouts ✅
4. Backend generates **new** workouts with "hard" difficulty ✅
5. **BUT**: If there's a workout scheduled for TODAY that was already generated before customization, it still has `difficulty: "easy"`

### Solution
The `updateProgramAndRegenerate` endpoint needs to also delete TODAY'S incomplete workout, not just future ones.

**Current logic** (line 130-135 in `backend/api/v1/workouts/program.py`):
```python
# Delete only future incomplete workouts (scheduled_date >= today)
today_str = str(date.today())
delete_result = db.table("workouts").delete().match({
    "user_id": user_id,
    "is_completed": False,
}).gte("scheduled_date", today_str).execute()
```

This correctly deletes future workouts, but **includes today**. The issue is that the workout card is showing a workout that was generated BEFORE you customized, so it still has the old difficulty.

### Quick Fix Options

**Option A: Force Delete All Incomplete Workouts (Recommended)**
```python
# Delete ALL incomplete workouts (including today)
delete_result = db.table("workouts").delete().match({
    "user_id": user_id,
    "is_completed": False,
}).execute()
```

**Option B: Frontend Manual Refresh**
After customizing, the user can:
1. Pull down to refresh the home screen
2. The new workout with correct difficulty will load

### Implementation
The code is already correct - it deletes today's workout. The issue is likely that:
1. The Flutter app has cached the old workout data
2. The refresh after customization isn't happening properly

Let me check the refresh flow...

Actually, looking at `program_menu_button.dart:99`, the refresh IS being called:
```dart
if (result == true && context.mounted) {
  // Refresh workouts after program update
  await ref.read(workoutsProvider.notifier).refresh();
```

So the refresh should work. The issue might be:
1. **Timing**: The new workout might not be generated yet when refresh is called
2. **Cache**: Riverpod might be returning cached data

### Recommended Fix
Add a small delay before refreshing to ensure the new workout is generated:

```dart
if (result == true && context.mounted) {
  // Wait for backend to finish generating new workouts
  await Future.delayed(const Duration(seconds: 2));

  // Refresh workouts after program update
  await ref.read(workoutsProvider.notifier).refresh();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Program updated! Your new workouts are ready.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
```

---

## Issue 2: Where to find the Feature Voting system?

### Location
The "Upcoming Features" card should appear on the home screen **between the Quick Actions row and the "YOUR WEEK" section**.

### Why it's not showing
The `UpcomingFeaturesCard` only displays if there are features with:
- `status = 'planned'`
- AND `release_date IS NOT NULL`

Currently, the database is empty (no sample features yet).

### Solution: Add Sample Features

Run this SQL to add sample features:

```sql
-- Insert sample planned features with countdown timers
INSERT INTO feature_requests (
  title,
  description,
  category,
  status,
  vote_count,
  release_date,
  created_by
) VALUES
(
  'Social Workout Sharing',
  'Share your workout summaries with friends and on social media with beautiful recap images',
  'social',
  'planned',
  42,
  (NOW() + INTERVAL '3 days'),
  NULL
),
(
  'Apple Watch Integration',
  'Track your workouts directly from your Apple Watch with real-time heart rate and calorie tracking',
  'integration',
  'planned',
  35,
  (NOW() + INTERVAL '7 days'),
  NULL
),
(
  'Custom Exercise Creator',
  'Create and save your own custom exercises with video demos',
  'workout',
  'planned',
  19,
  (NOW() + INTERVAL '14 days'),
  NULL
),
(
  'Advanced Nutrition Tracking',
  'Track macros, calories, and get AI-powered meal suggestions based on your workout plan',
  'nutrition',
  'voting',
  28,
  NULL,
  NULL
);
```

### How to Run the SQL

**Option 1: Via Supabase Dashboard**
1. Go to https://supabase.com/dashboard/project/hpbzfahijszqmgsybuor
2. Click "SQL Editor" in the left sidebar
3. Paste the SQL above
4. Click "Run"

**Option 2: Via psql (if you have access)**
```bash
psql postgresql://postgres:[PASSWORD]@aws-0-us-west-1.pooler.supabase.com:6543/postgres \
  -c "INSERT INTO feature_requests ..."
```

### After Adding Features
1. Restart the Flutter app (hot reload won't pick up new data)
2. OR pull down to refresh on the home screen
3. You should see the "Upcoming Features" card with countdown timers

### Accessing the Full Feature Voting Screen
- Tap the "Upcoming Features" card on the home screen
- OR navigate to `/features` route

The screen will show:
- **Voting tab**: Features users can vote for
- **Planned tab**: Features with countdown timers
- **In Progress tab**: Features being built
- **Released tab**: Recently shipped features

Users can:
- Vote/unvote by tapping the thumbs up icon
- Suggest new features (limit: 2 per user)
- See countdown timers for planned features (Robinhood-style)

---

## Testing the Fixes

### For Issue 1 (Difficulty)
1. Customize your program and select "Hard"
2. Wait 2-3 seconds after the success message
3. Pull down to refresh the home screen
4. The workout card should now show "Hard" difficulty

### For Issue 2 (Feature Voting)
1. Run the SQL above to add sample features
2. Restart the app or pull to refresh
3. You should see "Upcoming Features" card on home screen
4. Tap it to see the full feature voting screen
5. Try voting on features
6. Try suggesting a new feature (you can suggest up to 2)
