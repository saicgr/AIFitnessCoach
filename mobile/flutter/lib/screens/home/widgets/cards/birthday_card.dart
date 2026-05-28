/// F3.82 — Birthday card.
///
/// Surfaces only on the user's birthday (date_of_birth match on month+day).
/// A warm one-line greeting and a celebratory CTA — does NOT push a workout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/haptic_service.dart';

class BirthdayCard extends ConsumerWidget {
  const BirthdayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? firstName;
    DateTime? dob;
    try {
      final user = ref.watch(authStateProvider).user;
      final fullName = (user?.name ?? '').trim();
      if (fullName.isNotEmpty) {
        firstName = fullName.split(RegExp(r'\s+')).first;
      }
      final dobRaw = user?.dateOfBirth;
      if (dobRaw != null && dobRaw.isNotEmpty) {
        dob = DateTime.tryParse(dobRaw);
      }
    } catch (_) {
      return const SizedBox.shrink();
    }
    if (dob == null) return const SizedBox.shrink();

    final now = DateTime.now();
    if (dob.month != now.month || dob.day != now.day) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final name = (firstName ?? '').trim();
    final greeting =
        name.isEmpty ? 'Happy birthday!' : 'Happy birthday, $name!';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.cake_rounded, size: 22, color: c.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Whatever you do today, do it because you want to. No streak guilt — promise.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.celebration_rounded, color: c.accent, size: 22),
            onPressed: () => HapticService.success(),
          ),
        ],
      ),
    );
  }
}
