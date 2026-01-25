# Coming Soon UI Implementation Guide

**Approach:** Handle "coming soon" status purely in Flutter UI, no database changes needed.

## Overview

All programs are shown in the app with a "Coming Soon" overlay. When users tap, show what they can expect from the program.

## Implementation

### 1. Query Programs (Use Existing View)

```dart
// Use program_exercises_with_media view
final response = await supabase
    .from('program_exercises_with_media')
    .select('''
      variant_id,
      program_name,
      sub_program_name,
      duration_weeks,
      sessions_per_week,
      priority,
      week_status,
      weeks_ingested
    ''')
    .eq('week_status', 'complete')  // Only show programs with complete weeks
    .order('priority')
    .order('program_name');

// Get unique programs (deduplicate variants)
final programs = _deduplicatePrograms(response);
```

### 2. Program Card with Overlay

```dart
class ProgramCard extends StatelessWidget {
  final Program program;
  final bool isComingSoon;  // Set to true for all programs initially

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleProgramTap(context),
      child: Stack(
        children: [
          // Program thumbnail/card
          _buildProgramCard(),

          // Coming Soon overlay
          if (isComingSoon)
            _buildComingSoonOverlay(),
        ],
      ),
    );
  }

  Widget _buildProgramCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _getPriorityColors(program.priority),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            program.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${program.durationWeeks} weeks • ${program.sessionsPerWeek}x/week',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (program.priority != null)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                program.priority!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComingSoonOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                color: Colors.white,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'COMING SOON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Tap to learn more',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getPriorityColors(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return [Colors.orange.shade600, Colors.deepOrange.shade700];
      case 'med':
        return [Colors.blue.shade600, Colors.indigo.shade700];
      case 'low':
        return [Colors.teal.shade600, Colors.cyan.shade700];
      default:
        return [Colors.grey.shade600, Colors.grey.shade800];
    }
  }

  void _handleProgramTap(BuildContext context) {
    if (isComingSoon) {
      _showComingSoonModal(context);
    } else {
      // Navigate to program details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgramDetailsScreen(program: program),
        ),
      );
    }
  }

  void _showComingSoonModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComingSoonBottomSheet(program: program),
    );
  }
}
```

### 3. Coming Soon Bottom Sheet

```dart
class ComingSoonBottomSheet extends StatelessWidget {
  final Program program;

  const ComingSoonBottomSheet({required this.program});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 24),

          // Icon
          Center(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.orange.shade700,
              ),
            ),
          ),
          SizedBox(height: 24),

          // Program name
          Center(
            child: Text(
              program.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 8),

          // Duration info
          Center(
            child: Text(
              '${program.durationWeeks} weeks • ${program.sessionsPerWeek} sessions per week',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 32),

          // Coming soon message
          Text(
            'This program is coming soon! 🎉',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),

          // What to expect
          Text(
            'What you can expect:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),

          _buildFeatureItem(
            icon: Icons.calendar_today,
            text: 'Complete ${program.durationWeeks}-week structured program',
          ),
          _buildFeatureItem(
            icon: Icons.video_library,
            text: 'Professional exercise demonstration videos',
          ),
          _buildFeatureItem(
            icon: Icons.description,
            text: 'Detailed form cues and instructions',
          ),
          _buildFeatureItem(
            icon: Icons.trending_up,
            text: 'Progress tracking and workout history',
          ),
          _buildFeatureItem(
            icon: Icons.timer,
            text: 'Built-in rest timer and exercise timer',
          ),

          SizedBox(height: 32),

          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Got it!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: 8),

          // Notify me button (optional)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // TODO: Implement notification signup
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('We\'ll notify you when this program launches!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Notify me when available'),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange.shade700),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 4. Programs List Screen

```dart
class ProgramsListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Programs'),
      ),
      body: FutureBuilder<List<Program>>(
        future: _fetchPrograms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading programs'));
          }

          final programs = snapshot.data ?? [];

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: programs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: ProgramCard(
                  program: programs[index],
                  isComingSoon: true,  // Set to true for all programs
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Program>> _fetchPrograms() async {
    // Query your database using program_exercises_with_media
    // Get distinct programs
    // Return list of Program objects
  }
}
```

## When to Show Programs as Available

Later, when you want to make specific programs available:

```dart
class ProgramCard extends StatelessWidget {
  final Program program;

  bool get isComingSoon {
    // Option 1: Hardcode available programs
    const availablePrograms = [
      'Leg Development',
      '5/3/1 Progression',
      // ... other ready programs
    ];
    return !availablePrograms.contains(program.name);

    // Option 2: Check media coverage from database
    // return program.mediaCoveragePct < 100;

    // Option 3: Use a remote config flag
    // return !RemoteConfig.instance.getAvailablePrograms().contains(program.id);
  }

  // ... rest of implementation
}
```

## Benefits of This Approach

1. **No database changes** - Keep your schema clean
2. **Flexible messaging** - Change "coming soon" text anytime
3. **A/B testing ready** - Can test different messages
4. **Gradual rollout** - Easy to make programs available one by one
5. **Better UX** - Users can see what's coming
6. **No migrations** - No schema changes to deploy

## Database Query to Use

```dart
// Get all programs with complete weeks
final programs = await supabase
    .from('program_exercises_with_media')
    .select('''
      variant_id,
      program_name,
      sub_program_name,
      duration_weeks,
      sessions_per_week,
      priority,
      weeks_ingested,
      week_status
    ''')
    .eq('week_status', 'complete')
    .order('priority')
    .order('program_name');

// Deduplicate to get unique programs
// (since program_exercises_with_media has one row per exercise)
```

---

**Summary:** Show all programs with overlay, handle "coming soon" in UI, no database changes needed.
