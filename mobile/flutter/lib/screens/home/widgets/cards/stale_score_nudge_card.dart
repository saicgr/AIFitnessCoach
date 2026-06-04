/// Home nudge: when one or more muscle-group strength scores have gone STALE
/// (no recent training data), gently suggest training that muscle this week.
///
/// Data source: `GET /api/v1/scores/stale-muscles` — deterministic, no LLM.
/// The backend already excludes muscles the user opted out of
/// (`preferences.excluded_muscles`), so this only ever names muscles worth
/// nudging. Renders ONLY when `stale_count > 0`; otherwise self-collapses to
/// `SizedBox.shrink()` (consistent with every other contextual home card).
///
/// Dismissible: a tap on the close button hides it for the rest of the day
/// (per-day SharedPreferences key) so it can resurface tomorrow if still stale.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../data/services/api_client.dart';

/// Result of the stale-muscles fetch.
class _StaleScoreResult {
  final List<String> staleMuscles;
  final int staleCount;
  const _StaleScoreResult({required this.staleMuscles, required this.staleCount});
}

/// Today's dismissal key — resets each calendar day so a still-stale muscle
/// can nudge again tomorrow.
String _todayDismissKey() {
  final now = DateTime.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return 'stale_score_nudge_dismissed_$y$m$d';
}

final _staleScoreProvider =
    FutureProvider.autoDispose<_StaleScoreResult>((ref) async {
  final api = ref.read(apiClientProvider);
  // NOTE: path is `/scores/...` NOT `/api/v1/scores/...` — apiClient.baseUrl
  // already carries `/api/v1`.
  final res = await api.get<Map<String, dynamic>>('/scores/stale-muscles');
  final data = res.data ?? const {};
  final rawList = data['stale_muscles'];
  final muscles = <String>[];
  if (rawList is List) {
    for (final e in rawList) {
      // Each entry is {muscle_group, days_stale, ...} per the backend.
      if (e is Map && e['muscle_group'] != null) {
        muscles.add(e['muscle_group'].toString());
      } else if (e is String) {
        muscles.add(e);
      }
    }
  }
  final count = (data['stale_count'] as num?)?.toInt() ?? muscles.length;
  return _StaleScoreResult(staleMuscles: muscles, staleCount: count);
});

String _displayMuscle(String key) {
  final k = key.trim().toLowerCase();
  switch (k) {
    case 'quads':
      return 'quads';
    case 'hamstrings':
      return 'hamstrings';
    case 'glutes':
      return 'glutes';
    case 'calves':
      return 'calves';
    case 'core':
      return 'core';
    case 'traps':
      return 'traps';
    default:
      return k;
  }
}

class StaleScoreNudgeCard extends ConsumerStatefulWidget {
  const StaleScoreNudgeCard({super.key});

  @override
  ConsumerState<StaleScoreNudgeCard> createState() =>
      _StaleScoreNudgeCardState();
}

class _StaleScoreNudgeCardState extends ConsumerState<StaleScoreNudgeCard> {
  bool _dismissedToday = false;
  bool _checkedDismissal = false;

  @override
  void initState() {
    super.initState();
    _loadDismissal();
  }

  Future<void> _loadDismissal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_todayDismissKey()) ?? false;
      if (mounted) {
        setState(() {
          _dismissedToday = dismissed;
          _checkedDismissal = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkedDismissal = true);
    }
  }

  Future<void> _dismiss() async {
    HapticFeedback.lightImpact();
    setState(() => _dismissedToday = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_todayDismissKey(), true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Wait for the dismissal read before deciding — avoids a flash-then-hide.
    if (!_checkedDismissal || _dismissedToday) {
      return const SizedBox.shrink();
    }

    final result = ref.watch(_staleScoreProvider).valueOrNull;
    if (result == null || result.staleCount <= 0) {
      return const SizedBox.shrink();
    }

    final c = ThemeColors.of(context);
    final muscle = result.staleMuscles.isNotEmpty
        ? _displayMuscle(result.staleMuscles.first)
        : 'a muscle';
    final extra = result.staleCount - 1;
    final message = extra > 0
        ? 'Your $muscle strength score is going stale — train it this week. '
            '$extra other group${extra == 1 ? '' : 's'} could use attention too.'
        : 'Your $muscle strength score is going stale — train it this week.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              color: c.warning.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.hourglass_bottom_rounded,
                size: 18, color: c.warning),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Score going stale',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close_rounded,
                  size: 18, color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
