# Issues and Solutions

## Issue 1: Difficulty shows "Easy" after customizing to "Hard" ✅ FIXED

### Root Cause
The difficulty WAS being saved correctly and new workouts were being generated with the correct difficulty. However, there was a **race condition** where the Flutter app would refresh the workout list before the database transaction had fully committed the new workout data.

### What Was Happening
1. User customizes program and selects "Hard" difficulty
2. Backend saves `intensity_preference: "hard"` to user profile ✅
3. Backend deletes incomplete workouts ✅
4. Backend generates new workouts with "hard" difficulty ✅
5. Sheet closes and triggers refresh
6. **Race condition**: Refresh happens before DB transaction commits
7. Old workout data is still returned from the database

### Solution ✅ FIXED
Added a 500ms delay before refreshing to ensure the database transaction completes.

**Fix applied in** `mobile/flutter/lib/screens/home/widgets/components/program_menu_button.dart:99`:

```dart
if (result == true && context.mounted) {
  // Small delay to ensure database transaction completes
  await Future.delayed(const Duration(milliseconds: 500));

  // Refresh workouts after program update - new workouts should be ready
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

### Result
✅ Difficulty now updates automatically after customization
✅ No manual refresh needed
✅ Better UX - users see the correct difficulty immediately

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
