/// F3.63 — App anniversary celebration card.
///
/// Surfaces on the N-year anniversary of the user's account creation. Self-
/// collapses when [show] is false (eligibility owned by the ranker).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/haptic_service.dart';

class AppAnniversaryCard extends ConsumerWidget {
  final bool show;
  final int? years;
  final int workoutsAllTime;

  const AppAnniversaryCard({
    super.key,
    this.show = true,
    this.years,
    this.workoutsAllTime = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();
    final c = ThemeColors.of(context);

    // Derive years-with-Zealova from the live user's createdAt.
    // Constructor override (if provided) wins; otherwise compute from auth.
    int resolvedYears = years ?? 0;
    if (years == null) {
      final user = ref.watch(currentUserProvider).valueOrNull;
      final createdAtStr = user?.createdAt;
      if (createdAtStr != null && createdAtStr.isNotEmpty) {
        final createdAt = DateTime.tryParse(createdAtStr);
        if (createdAt != null) {
          final now = DateTime.now();
          int y = now.year - createdAt.year;
          if (now.month < createdAt.month ||
              (now.month == createdAt.month && now.day < createdAt.day)) {
            y -= 1;
          }
          resolvedYears = y;
        }
      }
    }
    // Eligibility gate: only render on whole-year anniversaries (≥1).
    if (resolvedYears < 1) return const SizedBox.shrink();

    final yLabel = resolvedYears == 1 ? '1 year' : '$resolvedYears years';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticService.light();
          context.push('/profile?tab=stats&source=anniversary');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.accent.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              Text('🎉', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$yLabel with Zealova',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      workoutsAllTime > 0
                          ? '$workoutsAllTime workouts logged. Look back at your year.'
                          : 'Look back at how far you\'ve come.',
                      style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
