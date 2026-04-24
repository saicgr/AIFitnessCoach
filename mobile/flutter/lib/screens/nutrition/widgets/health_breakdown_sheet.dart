import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/menu_item.dart';
import '../../../widgets/glass_sheet.dart';
import 'score_explain_sheet.dart';

/// Full-item health breakdown — opens from the "Full breakdown →" pill at
/// the end of a dish card's Health Strip.
///
/// Shows every signal in one glass sheet so users who want the complete
/// picture don't have to open five separate ScoreExplainSheets one by one.
/// Each row is itself tappable to drill into that signal's dedicated sheet
/// for the full educational content.
///
/// Design choices:
///   • Vertical list (not horizontal) because here we prioritise
///     comprehensiveness over compactness — users opt into this sheet.
///   • Each row mirrors the Health Strip pill: emoji + label + value pill,
///     colored by severity. Missing signals render a faint "Not computed"
///     row rather than being hidden — users shouldn't wonder whether we
///     forgot to compute them.
///   • Inflammation row shows its triggers inline as chip-badges (same
///     widget treatment as ScoreExplainSheet) so the biggest "why?" is
///     answered without a second tap.
///   • FODMAP shows its trigger reason text inline; added sugar shows a
///     `X g · Y% of WHO daily limit` hint; ultra-processed adds a NOVA-4
///     shorthand when applicable.
class HealthBreakdownSheet extends StatelessWidget {
  final MenuItem item;
  const HealthBreakdownSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, {required MenuItem item}) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        maxHeightFraction: 0.85,
        child: HealthBreakdownSheet(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: AppColors.orange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Health breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InflammationRow(
              item: item,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
            _BloodSugarRow(
              item: item,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
            _FodmapRow(
              item: item,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
            _AddedSugarRow(
              item: item,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
            _UltraProcessedRow(
              item: item,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              'Tap any row for the full explanation, scale, and education.',
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── row widgets ───────────────────────

/// Shared scaffold for every signal row.
class _SignalRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String valueText;
  final String? hint;
  final Widget? extra; // e.g. trigger chips
  final Color accent;
  final String? severityLabel;
  final VoidCallback? onTap;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _SignalRow({
    required this.emoji,
    required this.label,
    required this.valueText,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    this.hint,
    this.extra,
    this.severityLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        valueText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: accent,
                        ),
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 18, color: accent.withValues(alpha: 0.7)),
                    ],
                  ],
                ),
                if (severityLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    severityLabel!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
                if (hint != null && hint!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    hint!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                if (extra != null) ...[
                  const SizedBox(height: 8),
                  extra!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InflammationRow extends StatelessWidget {
  final MenuItem item;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  const _InflammationRow({
    required this.item,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final s = item.inflammationScore;
    if (s == null) {
      return _SignalRow(
        emoji: '🔥',
        label: 'Inflammation',
        valueText: '—',
        accent: textMuted,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        hint: 'Not computed for this dish.',
      );
    }
    final accent = s >= 7
        ? AppColors.error
        : s >= 4
            ? AppColors.orange
            : AppColors.success;
    final severityLabel = s <= 3
        ? 'ANTI-INFLAMMATORY'
        : s <= 6
            ? 'NEUTRAL / MILD'
            : 'HIGHLY INFLAMMATORY';
    final triggers = item.inflammationTriggers ?? const <String>[];

    return _SignalRow(
      emoji: '🔥',
      label: 'Inflammation',
      valueText: '$s/10',
      accent: accent,
      severityLabel: severityLabel,
      hint: triggers.isEmpty
          ? 'Chronic low-grade inflammation affects joint comfort, energy, and recovery.'
          : 'Key drivers in this dish:',
      extra: triggers.isEmpty
          ? null
          : _TriggerChipRow(triggers: triggers, accent: accent),
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      onTap: () => ScoreExplainSheet.show(
        context,
        kind: ScoreKind.inflammation,
        value: s,
        triggers: triggers,
      ),
    );
  }
}

class _BloodSugarRow extends StatelessWidget {
  final MenuItem item;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  const _BloodSugarRow({
    required this.item,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final gl = item.glycemicLoad;
    if (gl == null) {
      return _SignalRow(
        emoji: '🩸',
        label: 'Blood sugar',
        valueText: '—',
        accent: textMuted,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        hint: 'No glycemic load computed (likely a carb-free dish).',
      );
    }
    final accent = gl >= 20
        ? AppColors.error
        : gl >= 10
            ? AppColors.orange
            : AppColors.success;
    final severityLabel = gl < 10
        ? 'LOW IMPACT'
        : gl < 20
            ? 'MEDIUM'
            : 'HIGH IMPACT';
    return _SignalRow(
      emoji: '🩸',
      label: 'Blood sugar',
      valueText: 'GL $gl',
      accent: accent,
      severityLabel: severityLabel,
      hint:
          'Glycemic Load = GI × carbs ÷ 100. Lower = steadier energy and fewer spikes.',
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      onTap: () => ScoreExplainSheet.show(
        context,
        kind: ScoreKind.glycemicLoad,
        value: gl,
      ),
    );
  }
}

class _FodmapRow extends StatelessWidget {
  final MenuItem item;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  const _FodmapRow({
    required this.item,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final r = item.fodmapRating;
    if (r == null) {
      return _SignalRow(
        emoji: '🧡',
        label: 'FODMAP',
        valueText: '—',
        accent: textMuted,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        hint: 'Not classified for this dish.',
      );
    }
    final accent = r == 'high'
        ? AppColors.error
        : r == 'medium'
            ? AppColors.orange
            : AppColors.success;
    final label = r == 'high'
        ? 'HIGH TRIGGERS'
        : r == 'medium'
            ? 'SOME TRIGGERS'
            : 'GUT-FRIENDLY';
    return _SignalRow(
      emoji: '🧡',
      label: 'FODMAP',
      valueText: _titleCase(r),
      accent: accent,
      severityLabel: label,
      hint: item.fodmapReason?.isNotEmpty == true
          ? 'Triggers: ${item.fodmapReason}'
          : 'FODMAPs can trigger bloating, gas, or IBS flare-ups.',
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      onTap: () => ScoreExplainSheet.show(
        context,
        kind: ScoreKind.fodmap,
        value: r,
        reason: item.fodmapReason,
      ),
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));
}

class _AddedSugarRow extends StatelessWidget {
  final MenuItem item;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  const _AddedSugarRow({
    required this.item,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final g = item.addedSugarG;
    if (g == null) {
      return _SignalRow(
        emoji: '🍬',
        label: 'Added sugar',
        valueText: '—',
        accent: textMuted,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        hint: 'Not computed — likely no added sugar in this dish.',
      );
    }
    final accent = g >= 15
        ? AppColors.error
        : g >= 5
            ? AppColors.orange
            : AppColors.success;
    final severityLabel = g < 5
        ? 'LOW'
        : g < 15
            ? 'MODERATE'
            : 'HIGH';
    final pct = ((g / 25.0) * 100).round();
    final hint = g < 0.5
        ? 'No added sugar — just what\'s naturally in the ingredients.'
        : 'About $pct% of WHO\'s 25 g daily limit for adults.';
    return _SignalRow(
      emoji: '🍬',
      label: 'Added sugar',
      valueText: _fmt(g),
      accent: accent,
      severityLabel: severityLabel,
      hint: hint,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      onTap: () => ScoreExplainSheet.show(
        context,
        kind: ScoreKind.addedSugar,
        value: g,
      ),
    );
  }

  static String _fmt(double g) {
    if ((g - g.roundToDouble()).abs() < 0.05) return '${g.round()} g';
    return '${g.toStringAsFixed(1)} g';
  }
}

class _UltraProcessedRow extends StatelessWidget {
  final MenuItem item;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  const _UltraProcessedRow({
    required this.item,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final v = item.isUltraProcessed;
    if (v == null) {
      return _SignalRow(
        emoji: '🏭',
        label: 'Ultra-processed',
        valueText: '—',
        accent: textMuted,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        hint: 'Not classified for this dish.',
      );
    }
    final accent = v ? AppColors.error : AppColors.success;
    return _SignalRow(
      emoji: '🏭',
      label: 'Ultra-processed',
      valueText: v ? 'Yes' : 'No',
      accent: accent,
      severityLabel: v ? 'NOVA 4' : 'WHOLE / MINIMALLY PROCESSED',
      hint: v
          ? 'NOVA Group 4 — industrial recipes with emulsifiers, HFCS, artificial sweeteners, etc.'
          : 'Built from raw or basic-cooked ingredients.',
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      onTap: () => ScoreExplainSheet.show(
        context,
        kind: ScoreKind.ultraProcessed,
        value: v,
      ),
    );
  }
}

/// Chip row for inflammation trigger tags. Green chips = anti-inflammatory
/// drivers; red chips = inflammatory drivers. Matches ScoreExplainSheet's
/// treatment so the breakdown sheet feels visually consistent.
class _TriggerChipRow extends StatelessWidget {
  final List<String> triggers;
  final Color accent;
  const _TriggerChipRow({required this.triggers, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in triggers)
          _Chip(
            label: InflammationTriggers.label(tag),
            positive: InflammationTriggers.isPositive(tag),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool positive;
  const _Chip({required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    final c = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.arrow_downward : Icons.arrow_upward,
              size: 10, color: c),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
