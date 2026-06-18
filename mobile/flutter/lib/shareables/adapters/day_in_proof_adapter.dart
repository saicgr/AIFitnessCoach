/// Adapter for **F3 — "Day in Proof"** share card.
///
/// Fetches the deterministic cross-domain payload from `GET /share/day-in-proof`
/// (`{has_data, top_pr, meal_grade, streak, insight_line}`) and folds it into a
/// [Shareable] the `dayInProof` card preset renders. Returns null when the day
/// has no proof (no PR, meal grade, or workout) — the caller shows an empty
/// state rather than a fabricated card (feedback_no_silent_fallbacks).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/user_provider.dart';
import '../../data/repositories/share_ai_repository.dart';
import '../shareable_data.dart';

class DayInProofAdapter {
  /// Builds the Day-in-Proof [Shareable] for [dateIso] (defaults to today).
  /// One network call to the deterministic backend endpoint. Returns null when
  /// the day carries no proof.
  static Future<Shareable?> fetch(WidgetRef ref, {String? dateIso}) async {
    final repo = ref.read(shareAiRepositoryProvider);
    final Map<String, dynamic> data = await repo.dayInProof(date: dateIso);

    final hasData = data['has_data'] == true;
    if (!hasData) return null;

    final pr = (data['top_pr'] as Map?)?.cast<String, dynamic>();
    final grade = (data['meal_grade'] as Map?)?.cast<String, dynamic>();
    final streak = (data['streak'] as num?)?.toInt() ?? 0;
    final line = (data['insight_line'] as String?)?.trim();
    final date = (data['date'] as String?) ?? dateIso;

    final user = ref.read(currentUserProvider).asData?.value;

    // PR → hero. Use the formatted string value when present.
    String heroUnit = '';
    String? heroPrefix;
    if (pr != null) {
      // pr['value'] is a formatted string like "225 lbs"; surface the exercise
      // as the unit-ish label and keep the numeric weight as the hero.
      final exercise = (pr['exercise'] as String?) ?? '';
      heroUnit = exercise;
      final valueStr = (pr['value'] as String?) ?? '';
      heroPrefix = valueStr.isNotEmpty ? valueStr : null;
    }

    // Meal grade score (1–10) drives the card's letter grade deterministically.
    final score = (grade?['score'] as num?)?.round();

    final highlights = <ShareableMetric>[
      if (pr != null)
        ShareableMetric(
          label: 'TOP PR',
          value: (pr['value'] as String?) ?? '—',
          icon: Icons.emoji_events_rounded,
        ),
      if (grade != null)
        ShareableMetric(
          label: 'MEAL GRADE',
          value: (grade['grade'] as String?) ?? '—',
          icon: Icons.restaurant_rounded,
        ),
      ShareableMetric(
        label: 'STREAK',
        value: '$streak',
        icon: Icons.local_fire_department_rounded,
      ),
    ];

    return Shareable(
      kind: ShareableKind.workoutComplete,
      title: 'Day in Proof',
      periodLabel: _prettyDate(date),
      heroPrefix: heroPrefix,
      heroUnitSingular: heroUnit,
      highlights: highlights,
      healthScore: score,
      currentStreak: streak,
      caption: (line != null && line.isNotEmpty) ? line : null,
      dateIso: date,
      userDisplayName: user?.name,
      accentColor: const Color(0xFFD8FF3A),
    );
  }

  static String _prettyDate(String? iso) {
    if (iso == null) return 'TODAY';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final today = DateTime.now();
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      return 'TODAY';
    }
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
