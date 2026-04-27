import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/providers/mood_history_provider.dart';
import '../../../widgets/app_loading.dart';
import '../../../widgets/mood_picker_sheet.dart';
import '../../mood/widgets/mood_weekly_chart.dart';
import '../../mood/widgets/mood_streak_card.dart';
import '../../mood/widgets/mood_analytics_card.dart';
import '../../mood/widgets/mood_calendar_heatmap.dart';

class MoodTab extends ConsumerStatefulWidget {
  const MoodTab({super.key});

  @override
  ConsumerState<MoodTab> createState() => _MoodTabState();
}

class _MoodTabState extends ConsumerState<MoodTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moodHistoryProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(moodHistoryProvider);
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    if (state.isLoading) {
      return AppLoading.fullScreen();
    }

    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weekly mood chart
              const MoodWeeklyChart(),
              const SizedBox(height: 16),

              // Mood streaks
              if (state.analytics != null)
                MoodStreakCard(streaks: state.analytics!.streaks),

              // Mood analytics summary
              if (state.analytics != null) ...[
                const SizedBox(height: 16),
                MoodAnalyticsCard(analytics: state.analytics!),
              ],

              const SizedBox(height: 16),

              // Calendar heatmap
              const MoodCalendarHeatmap(),

              // Link to full history
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/mood-history'),
                  child: Text('View Full History', style: TextStyle(color: teal)),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),

        // Floating Log Mood button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'mood_tab_quick_log_fab',
            onPressed: () => showMoodPickerSheet(context, ref),
            backgroundColor: accentColor,
            child: const Icon(Icons.sentiment_satisfied_alt, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
