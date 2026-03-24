import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/tts_provider.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/services/notification_service.dart';
import '../../ai_settings/ai_settings_screen.dart';
import '../widgets/widgets.dart';

/// Test section for verifying all notification types work.
class TestNotificationsSection extends StatelessWidget {
  const TestNotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'TEST'),
        SizedBox(height: 12),
        _TestCard(),
      ],
    );
  }
}

class _TestCard extends ConsumerWidget {
  const _TestCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final notificationService = ref.read(notificationServiceProvider);
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;

    final testItems = [
      _TestItem(coach.name, "Your squat form improved 15% this week. Let's push for a new PR!", Icons.smart_toy, AppColors.cyan, 'ai_coach'),
      _TestItem('Missed Workout', "Hey! You haven't trained today. Your streak is on the line!", Icons.alarm, AppColors.error, 'workout_reminder'),
      _TestItem('Meal Reminder', 'Time to refuel! Grab some protein within 30 min.', Icons.restaurant, AppColors.teal, 'nutrition_reminder'),
      _TestItem('Habit Check-in', "Don't forget to log your habits before bed tonight!", Icons.checklist, AppColors.purple, 'ai_coach_accountability'),
      _TestItem('Streak Milestone', 'Amazing! You hit a 7-day streak!', Icons.celebration, AppColors.warning, 'streak_alert'),
      _TestItem('Workout Reminder', "It's leg day! Time to hit the gym.", Icons.fitness_center, AppColors.cyan, 'workout_reminder'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Voice test (TTS, not push)
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () {
              ref.read(voiceAnnouncementsProvider.notifier)
                  .announceIfEnabled('Next exercise: Barbell Squat, 4 sets of 8 to 12 reps');
              _showSnack(context, 'Voice Announcement');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.record_voice_over, color: AppColors.info, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Voice Announcement', style: TextStyle(fontSize: 14)),
                        Text('Test TTS during workout', style: TextStyle(fontSize: 11, color: textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.play_circle_outline, color: AppColors.info, size: 20),
                ],
              ),
            ),
          ),

          // Push notification tests
          ...testItems.map((item) {
            final isLast = item == testItems.last;
            return Column(
              children: [
                Divider(height: 1, color: cardBorder, indent: 50),
                InkWell(
                  borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : null,
                  onTap: () {
                    notificationService.showTestNotificationWithContent(
                      title: item.title,
                      body: item.body,
                      notificationType: item.type,
                    );
                    _showSnack(context, item.title);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(item.icon, color: item.color, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontSize: 14)),
                              Text(item.body, style: TextStyle(fontSize: 11, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Icon(Icons.send, color: textMuted, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title sent!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _TestItem {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String type;
  const _TestItem(this.title, this.body, this.icon, this.color, this.type);
}
