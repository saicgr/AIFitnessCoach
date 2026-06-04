import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/excluded_muscles_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/pill_app_bar.dart';

/// Multi-select chip group for the muscle groups the AI should NEVER train.
///
/// Writes `preferences.excluded_muscles` (a lowercased JSONB list). The backend
/// already honors this list during workout generation AND suppresses stale-score
/// nudges for excluded groups — see `excluded_muscles_provider.dart`.
///
/// This is distinct from "Muscles to Avoid" (the body-diagram avoided-muscles
/// flow, which supports a softer 'reduce' severity + injury reasons). Exclusion
/// is a hard, permanent "don't program this at all" preference.
class ExcludedMusclesScreen extends ConsumerWidget {
  const ExcludedMusclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final state = ref.watch(excludedMusclesProvider);
    final selected = state.muscles;

    return Scaffold(
      backgroundColor: c.background,
      appBar: PillAppBar(
        title: 'Excluded Muscles',
        actions: [
          PillAppBarAction(
            icon: Icons.clear_all_rounded,
            visible: selected.isNotEmpty,
            onTap: () {
              HapticService.light();
              ref.read(excludedMusclesProvider.notifier).setMuscles({});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro / explainer glass card.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.block_rounded,
                          size: 18, color: c.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Muscles to never train',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The AI will skip these muscle groups entirely when '
                            'building your workouts, and we will stop nudging you '
                            'about their strength scores.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Muscle groups',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (selected.isNotEmpty)
                    Text(
                      '${selected.length} excluded',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kExcludableMuscleGroups.map((muscle) {
                  final isSelected = selected.contains(muscle);
                  return _MuscleChip(
                    label: excludedMuscleDisplayName(muscle),
                    selected: isSelected,
                    accent: c.accent,
                    surface: c.surface,
                    border: c.cardBorder,
                    textPrimary: c.textPrimary,
                    textSecondary: c.textSecondary,
                    onTap: () {
                      HapticService.light();
                      ref
                          .read(excludedMusclesProvider.notifier)
                          .toggle(muscle);
                    },
                  );
                }).toList(),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Could not save — tap a chip to retry.',
                  style: TextStyle(fontSize: 12.5, color: c.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _MuscleChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent.withValues(alpha: 0.55) : border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: selected
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('on'), size: 16, color: accent)
                  : Icon(Icons.add_circle_outline_rounded,
                      key: const ValueKey('off'),
                      size: 16,
                      color: textSecondary),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? textPrimary : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
