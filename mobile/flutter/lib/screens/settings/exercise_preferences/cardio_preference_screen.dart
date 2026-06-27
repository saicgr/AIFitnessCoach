import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/training_preferences_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/pill_app_bar.dart';

/// Cardio-in-split preference: have the AI automatically add a short conditioning
/// block before or after your lifting sessions — set once, applied to every
/// generated workout (mirrors Hevy's "cardio before or after your session").
///
/// Persists `preferences.cardio_preference = {cadence, placement}` via
/// trainingPreferencesProvider.setCardioPreference. Backend honors it in
/// today.py auto-generation (deterministic bodyweight finisher).
class CardioPreferenceScreen extends ConsumerWidget {
  const CardioPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final prefs = ref.watch(trainingPreferencesProvider);
    final notifier = ref.read(trainingPreferencesProvider.notifier);
    final cadence = prefs.cardioCadence;
    final placement = prefs.cardioPlacement;
    final cardioOn = cadence != 'off';

    return Scaffold(
      backgroundColor: c.background,
      appBar: const PillAppBar(title: 'Cardio'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
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
                  Icon(Icons.directions_run, size: 18, color: c.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add a short conditioning block to your lifting workouts '
                      'automatically — no need to toggle it each time.',
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Cardio', style: _label(c)),
            const SizedBox(height: 8),
            _ChoiceRow(
              label: 'Off',
              subtitle: 'No automatic cardio',
              selected: cadence == 'off',
              onTap: () {
                HapticService.light();
                notifier.setCardioPreference(
                    cadence: 'off', placement: placement);
              },
            ),
            _ChoiceRow(
              label: 'Every session',
              subtitle: 'Add conditioning to each lifting workout',
              selected: cadence == 'every_session',
              onTap: () {
                HapticService.light();
                notifier.setCardioPreference(
                    cadence: 'every_session', placement: placement);
              },
            ),
            if (cardioOn) ...[
              const SizedBox(height: 20),
              Text('When', style: _label(c)),
              const SizedBox(height: 8),
              _ChoiceRow(
                label: 'After lifting',
                subtitle: 'Cardio as a finisher',
                selected: placement == 'after',
                onTap: () {
                  HapticService.light();
                  notifier.setCardioPreference(
                      cadence: cadence, placement: 'after');
                },
              ),
              _ChoiceRow(
                label: 'Before lifting',
                subtitle: 'Cardio as a warm-up opener',
                selected: placement == 'before',
                onTap: () {
                  HapticService.light();
                  notifier.setCardioPreference(
                      cadence: cadence, placement: 'before');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle _label(ThemeColors c) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: c.textMuted,
      );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.12) : c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? c.accent : c.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: c.textMuted)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: c.accent, size: 22),
          ],
        ),
      ),
    );
  }
}
