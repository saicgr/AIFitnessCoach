import 'package:flutter/material.dart';

import '../../../core/models/chat_quick_action.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

class ChatFeaturesInfoSheet extends StatelessWidget {
  final void Function(ChatQuickAction action) onAction;

  const ChatFeaturesInfoSheet({super.key, required this.onAction});

  static const _sections = <String, List<String>>{
    'Form Analysis': ['check_form', 'compare_form'],
    'Nutrition': ['scan_food', 'analyze_menu', 'calorie_check'],
    'Workout': ['quick_workout', 'meal_prep'],
    'Recovery': ['recovery_tips', 'injury_help'],
  };

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    return GlassSheet(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'What can I do?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your AI coach can analyze media, generate workouts, give nutrition advice, and more.',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              for (final entry in _sections.entries) ...[
                _buildSectionLabel(entry.key, colors.textMuted),
                const SizedBox(height: 8),
                ...entry.value.map((id) {
                  final action = chatQuickActionRegistry[id];
                  if (action == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FeatureCard(
                      action: action,
                      isDark: isDark,
                      colors: colors,
                      onTap: () {
                        Navigator.pop(context);
                        HapticService.selection();
                        onAction(action);
                      },
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: colors.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Long-press action pills to customize your shortcuts',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, Color textMuted) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final ChatQuickAction action;
  final bool isDark;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.action,
    required this.isDark,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(action.icon, size: 18, color: action.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
