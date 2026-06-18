import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/user_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/repositories/share_growth_repository.dart';
import '../../shareables/shareable_catalog.dart' show ShareableTemplate;
import '../../shareables/shareable_data.dart';
import '../../shareables/shareable_sheet.dart';

/// F16 — "A year ago today". Fetches `/share/on-this-day` and lists workouts /
/// meals logged on this calendar day in prior years. Each memory offers a
/// one-tap share that opens the editor on the `milestoneCard` preset (a
/// "look how far I've come" card). Deterministic — no AI.
class OnThisDaySheet {
  const OnThisDaySheet._();

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    Map<String, dynamic>? payload;
    try {
      payload = await ref.read(shareGrowthRepositoryProvider).onThisDay();
    } catch (_) {
      payload = null;
    }
    if (!context.mounted) return;

    final hasData = payload != null && payload['has_data'] == true;
    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing logged on this day in past years — yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final workouts = ((payload['workouts'] as List?) ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    final meals = ((payload['meals'] as List?) ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OnThisDayBody(workouts: workouts, meals: meals),
    );
  }
}

class _OnThisDayBody extends ConsumerWidget {
  final List<Map<String, dynamic>> workouts;
  final List<Map<String, dynamic>> meals;

  const _OnThisDayBody({required this.workouts, required this.meals});

  String _yearsAgo(Map<String, dynamic> m) {
    final ya = (m['years_ago'] as num?)?.toInt() ?? 1;
    return ya == 1 ? '1 year ago' : '$ya years ago';
  }

  Future<void> _shareWorkout(
      BuildContext context, WidgetRef ref, Map<String, dynamic> w) async {
    final name = ref.read(currentUserProvider).asData?.value?.name;
    final shareable = Shareable(
      kind: ShareableKind.milestones,
      title: (w['name'] as String?) ?? 'Workout',
      periodLabel: _yearsAgo(w).toUpperCase(),
      heroValue: (w['duration_minutes'] as num?)?.toInt(),
      heroUnitSingular: 'min',
      highlights: [
        ShareableMetric(label: 'BACK THEN', value: _yearsAgo(w)),
        const ShareableMetric(label: 'STILL HERE', value: 'Today'),
      ],
      userDisplayName: name,
      accentColor: const Color(0xFFD8FF3A),
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await ShareableSheet.show(
      context,
      data: shareable,
      initialTemplate: ShareableTemplate.milestoneCard,
    );
  }

  Future<void> _shareMeal(
      BuildContext context, WidgetRef ref, Map<String, dynamic> m) async {
    final name = ref.read(currentUserProvider).asData?.value?.name;
    final shareable = Shareable(
      kind: ShareableKind.milestones,
      title: (m['food_name'] as String?) ?? 'Meal',
      periodLabel: _yearsAgo(m).toUpperCase(),
      heroValue: (m['total_calories'] as num?)?.toInt(),
      heroUnitSingular: 'kcal',
      highlights: [
        ShareableMetric(label: 'BACK THEN', value: _yearsAgo(m)),
        const ShareableMetric(label: 'STILL LOGGING', value: 'Today'),
      ],
      healthScore: (m['health_score'] as num?)?.round(),
      userDisplayName: name,
      accentColor: const Color(0xFFD8FF3A),
    );
    if (!context.mounted) return;
    Navigator.of(context).pop();
    await ShareableSheet.show(
      context,
      data: shareable,
      initialTemplate: ShareableTemplate.milestoneCard,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);
    final accent = c.accent;
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.8),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('A year ago today',
                style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Tap a memory to share how far you have come.',
                style: TextStyle(color: c.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            for (final w in workouts)
              _memoryTile(
                c,
                accent,
                Icons.fitness_center_rounded,
                (w['name'] as String?) ?? 'Workout',
                _yearsAgo(w),
                () => _shareWorkout(context, ref, w),
              ),
            for (final m in meals)
              _memoryTile(
                c,
                accent,
                Icons.restaurant_rounded,
                (m['food_name'] as String?) ?? 'Meal',
                _yearsAgo(m),
                () => _shareMeal(context, ref, m),
              ),
          ],
        ),
      ),
    );
  }

  Widget _memoryTile(ThemeColors c, Color accent, IconData icon, String title,
      String subtitle, VoidCallback onShare) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: c.textMuted, fontSize: 13)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onShare();
              },
              icon: const Icon(Icons.ios_share_rounded, size: 16),
              label: const Text('Share'),
              style: TextButton.styleFrom(foregroundColor: accent),
            ),
          ],
        ),
      ),
    );
  }
}
