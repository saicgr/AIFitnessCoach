import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/superset_preferences_provider.dart';
import '../widgets/widgets.dart';

/// Simplified superset settings section with basic enable/disable controls.
///
/// Advanced superset algorithm tuning (compound sets, max supersets, rest times,
/// favorite pairs) lives in Beast Mode's SupersetAlgorithmCard.
class SupersetSettingsSection extends ConsumerWidget {
  const SupersetSettingsSection({super.key});

  static const List<Map<String, dynamic>> _supersetHelpItems = [
    {
      'icon': Icons.sync_alt,
      'title': 'What are Supersets?',
      'description': 'Supersets are pairs of exercises performed back-to-back with minimal rest. They save time and increase workout intensity.',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.compare_arrows,
      'title': 'Antagonist Pairs',
      'description': 'Exercises targeting opposing muscle groups (e.g., chest press + rows, bicep curls + tricep extensions). Allows one muscle to rest while the other works.',
      'color': AppColors.cyan,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supersetPrefs = ref.watch(supersetPreferencesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'SUPERSET SETTINGS',
          subtitle: 'Control how supersets are generated in your workouts',
          helpTitle: 'Superset Settings',
          helpItems: _supersetHelpItems,
        ),
        const SizedBox(height: 12),
        Material(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _SupersetToggleTile(
                icon: Icons.sync_alt,
                title: 'Auto-generate supersets',
                subtitle: 'Include superset pairs in AI-generated workouts',
                value: supersetPrefs.supersetsEnabled,
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  ref.read(supersetPreferencesProvider.notifier).setSupersetsEnabled(value);
                },
              ),
              if (supersetPrefs.supersetsEnabled) ...[
                Divider(height: 1, color: cardBorder, indent: 50),
                _SupersetToggleTile(
                  icon: Icons.compare_arrows,
                  title: 'Prefer antagonist pairs',
                  subtitle: 'Chest/back, biceps/triceps pairings',
                  value: supersetPrefs.preferAntagonistPairs,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    ref.read(supersetPreferencesProvider.notifier).setPreferAntagonistPairs(value);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Toggle tile for superset settings
class _SupersetToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SupersetToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }
}
