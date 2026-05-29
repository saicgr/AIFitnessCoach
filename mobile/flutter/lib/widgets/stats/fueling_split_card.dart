import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/skeleton/skeleton_box.dart';
import '../../data/models/fueling_split.dart';
import 'big_stat.dart';
import 'stat_section_shell.dart';

/// Shared "Training vs rest day" fueling comparison card, used on BOTH the
/// Workout tab ("Training stats") and the Nutrition tab ("Nutrition stats").
///
/// The public signature is contractual — the nutrition agent imports this same
/// file and feeds it `ref.watch(fuelingSplitProvider)`. Do NOT change the
/// constructor shape without coordinating across both tabs.
///
/// Renders two big rows (avg protein g, avg calories) for training days vs rest
/// days plus a one-line, human-voiced takeaway picked from a variant pool by a
/// stable bucket of the protein delta. No fabricated numbers: a loading
/// [AsyncValue] shows a skeleton, a null/empty payload shows an explicit empty
/// state, and an error shows an inline error note.
class FuelingSplitCard extends StatelessWidget {
  /// The async fueling split. Supplied by `ref.watch(fuelingSplitProvider)`.
  final AsyncValue<FuelingSplit?> fueling;

  final bool isDark;

  /// Screen accent (e.g. `ref.colors(context).accent`).
  final Color accent;

  const FuelingSplitCard({
    required this.fueling,
    required this.isDark,
    required this.accent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StatCardShell(
      isDark: isDark,
      child: fueling.when(
        loading: () => const _FuelingSkeleton(),
        error: (_, __) => _FuelingEmpty(
          isDark: isDark,
          message: 'Fueling comparison is unavailable right now.',
        ),
        data: (split) {
          if (split == null ||
              (split.training.days == 0 && split.rest.days == 0)) {
            return _FuelingEmpty(
              isDark: isDark,
              message:
                  'Log food on a few training and rest days to compare how you fuel.',
            );
          }
          return _FuelingBody(split: split, isDark: isDark, accent: accent);
        },
      ),
    );
  }
}

class _FuelingBody extends StatelessWidget {
  final FuelingSplit split;
  final bool isDark;
  final Color accent;

  const _FuelingBody({
    required this.split,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final t = split.training;
    final r = split.rest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.restaurant_rounded, size: 18, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Training vs rest day fueling',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Protein row.
        _MetricRow(
          label: 'Protein',
          trainingValue: _gram(t.avgProteinG),
          restValue: _gram(r.avgProteinG),
          trainingHasData: t.days > 0,
          restHasData: r.days > 0,
          unit: 'g',
          accent: accent,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        // Calories row.
        _MetricRow(
          label: 'Calories',
          trainingValue: _round(t.avgCalories),
          restValue: _round(r.avgCalories),
          trainingHasData: t.days > 0,
          restHasData: r.days > 0,
          unit: 'kcal',
          accent: accent,
          isDark: isDark,
        ),
        const SizedBox(height: 14),
        Text(
          _takeaway(t, r),
          style: TextStyle(fontSize: 12.5, height: 1.35, color: textMuted),
        ),
      ],
    );
  }

  static String _gram(double v) => v.round().toString();
  static String _round(double v) => v.round().toString();

  /// Human-voiced takeaway picked by a stable bucket of the protein delta so
  /// the copy never reads robotic. Substitutes the real percentage. No em
  /// dashes per `feedback_no_em_dashes_marketing.md`.
  static String _takeaway(FuelingGroup training, FuelingGroup rest) {
    // Both day-types need real data for a comparison to be honest.
    if (training.days == 0 || rest.days == 0) {
      if (training.days > 0) {
        return 'You have logged ${training.days} training day${training.days == 1 ? '' : 's'} so far. Log a rest day to see the split.';
      }
      if (rest.days > 0) {
        return 'You have logged ${rest.days} rest day${rest.days == 1 ? '' : 's'} so far. Log a training day to see the split.';
      }
      return 'Keep logging on both training and rest days to unlock this comparison.';
    }

    final restProtein = rest.avgProteinG;
    final trainProtein = training.avgProteinG;

    if (restProtein < 1) {
      return 'You averaged ${trainProtein.round()}g of protein on training days.';
    }

    final pctDiff = ((trainProtein - restProtein) / restProtein) * 100;
    final magnitude = pctDiff.abs().round();

    // Roughly even (within ~5%): the win is consistency, not a swing.
    if (magnitude <= 5) {
      const even = <String>[
        'Your protein holds steady whether you train or rest. That consistency is exactly what muscle repair wants.',
        'Training and rest days look near identical on protein. Steady fueling like this is hard to beat.',
        'You keep protein level across the week, not just on lifting days. Smart, since recovery happens on rest days too.',
        'Barely a gap between training and rest day protein. Consistent intake beats a feast-or-famine pattern.',
      ];
      return even[magnitude % even.length];
    }

    if (pctDiff > 0) {
      // Eats more protein on training days.
      final more = <String>[
        'You eat $magnitude% more protein when you train. That extra fuel goes straight into the work you just did.',
        'Training days run $magnitude% higher on protein than rest days. You are matching intake to effort.',
        'On lifting days your protein climbs $magnitude%. Rest days still matter for recovery, so keep them solid too.',
        'You fuel training days with $magnitude% more protein. Worth carrying some of that into rest days for repair.',
      ];
      // Stable index from magnitude bucket so the same data always reads the same.
      return more[(magnitude ~/ 7) % more.length];
    }

    // Eats more protein on rest days (less when training).
    final less = <String>[
      'You actually eat $magnitude% less protein on training days. Try topping up around your sessions to support recovery.',
      'Protein dips $magnitude% on the days you train. A post-workout meal could close that gap.',
      'Training days come in $magnitude% lower on protein than rest days. Front-loading a meal before lifting may help.',
      'You under-fuel training days by $magnitude% on protein. Adding a shake on session days is an easy fix.',
    ];
    return less[(magnitude ~/ 7) % less.length];
  }
}

/// One labelled metric with a training-day big number and a rest-day big number
/// side by side. Uses [BigStat] so the values read large per the design brief.
class _MetricRow extends StatelessWidget {
  final String label;
  final String trainingValue;
  final String restValue;
  final bool trainingHasData;
  final bool restHasData;
  final String unit;
  final Color accent;
  final bool isDark;

  const _MetricRow({
    required this.label,
    required this.trainingValue,
    required this.restValue,
    required this.trainingHasData,
    required this.restHasData,
    required this.unit,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: BigStat(
            value: trainingHasData ? trainingValue : '--',
            unit: trainingHasData ? unit : null,
            label: 'Training days · $label',
            isDark: isDark,
            accent: accent,
            valueFontSize: 30,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 1,
          height: 54,
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: BigStat(
            value: restHasData ? restValue : '--',
            unit: restHasData ? unit : null,
            label: 'Rest days · $label',
            isDark: isDark,
            accent: textMuted,
            valueFontSize: 30,
          ),
        ),
      ],
    );
  }
}

class _FuelingEmpty extends StatelessWidget {
  final bool isDark;
  final String message;

  const _FuelingEmpty({required this.isDark, required this.message});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.restaurant_outlined, size: 22, color: textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, height: 1.35, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelingSkeleton extends StatelessWidget {
  const _FuelingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 180, height: 14),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 40)),
            SizedBox(width: 24),
            Expanded(child: SkeletonBox(height: 40)),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 40)),
            SizedBox(width: 24),
            Expanded(child: SkeletonBox(height: 40)),
          ],
        ),
        SizedBox(height: 14),
        SkeletonBox(height: 12),
      ],
    );
  }
}
