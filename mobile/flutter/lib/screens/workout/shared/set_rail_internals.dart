// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Internal pill + overflow chip widgets for `set_rail.dart`. Split purely so
// set_rail.dart stays ≤ 250 lines per project convention.

import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/utils/exercise_tracking_metric.dart';
import 'set_rail.dart';
import '../../../l10n/generated/app_localizations.dart';

/// One pill in the rail. Visual style switches on `summary.status`.
class RailPill extends StatelessWidget {
  final RailSetSummary summary;
  final bool isCurrent;
  final VoidCallback onTap;

  const RailPill({
    super.key,
    required this.summary,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = isDark ? Colors.white : Colors.black;

    final _PillStyle s = _styleFor(summary.status, accent, onSurface, isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Under 56 pt wide, collapse to icon-only so the 48 pt minimum width
        // still accommodates a legible label.
        final compact = constraints.maxWidth < 56;
        final label = _label(compact);

        return Semantics(
          button: true,
          label: _a11yLabel(),
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(minWidth: 48),
              padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: s.border,
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  fontWeight: s.weight,
                  color: s.fg,
                  height: 1.0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _label(bool compact) {
    final prefix = summary.status == RailSetStatus.warmup
        ? 'W'
        : summary.displayIndex.toString();
    switch (summary.status) {
      case RailSetStatus.done:
      case RailSetStatus.warmup:
        if (compact) return '$prefix✓';
        // Multi-metric sets (distance / time / box-height …) render their full
        // metric set joined by " · "; ordinary weight×reps lifts keep the exact
        // legacy "W×r" token so nothing regresses.
        final hasDistance =
            summary.distanceMeters != null && summary.distanceMeters! > 0;
        final hasTime =
            summary.durationSeconds != null && summary.durationSeconds! > 0;
        final hasExtra =
            summary.extraMetrics != null && summary.extraMetrics!.isNotEmpty;
        if (!hasDistance && !hasTime && !hasExtra) {
          final r = summary.reps?.toString() ?? '-';
          // "BW" token for bodyweight so the pill never reads "✓×12" (tick+X);
          // spaces around the ✓ separate it from the × glyph for weighted sets.
          final w = summary.isBodyweight
              ? 'BW'
              : (summary.weightLabel ?? _formatWeight(summary.weight));
          return '$prefix ✓ $w×$r';
        }
        final tokens = _metricTokens();
        return tokens.isEmpty ? '$prefix✓' : '$prefix ✓ ${tokens.join(' · ')}';
      case RailSetStatus.current:
        return compact ? '●$prefix' : '● $prefix';
      case RailSetStatus.upcoming:
        return compact ? '◌$prefix' : '◌ $prefix';
    }
  }

  String _formatWeight(double? w) {
    if (w == null) return '-';
    if (w == w.roundToDouble()) return w.toStringAsFixed(0);
    return w.toStringAsFixed(1);
  }

  /// Ordered, compact tokens for a multi-metric completed set, e.g.
  /// ["60kg", "20m"] (loaded sled) · ["0:45"] (plank) · ["10", "60cm"] (box jump).
  /// Canonical order: weight → reps → distance → time → extra metrics.
  List<String> _metricTokens() {
    final tokens = <String>[];
    if (!summary.isBodyweight &&
        summary.weight != null &&
        summary.weight! > 0) {
      // weightLabel already carries the unit ("60 kg" / "65 lb"); strip the
      // inner space so the tight pill reads "60kg".
      tokens.add(summary.weightLabel?.replaceAll(' ', '') ??
          _formatWeight(summary.weight));
    }
    if (summary.reps != null && summary.reps! > 0) {
      tokens.add(summary.reps.toString());
    }
    if (summary.distanceMeters != null && summary.distanceMeters! > 0) {
      tokens.add(_formatDistance(summary.distanceMeters!));
    }
    if (summary.durationSeconds != null && summary.durationSeconds! > 0) {
      tokens.add(_formatTime(summary.durationSeconds!));
    }
    final extra = summary.extraMetrics;
    if (extra != null) {
      extra.forEach((bagKey, value) {
        tokens.add(_formatMetric(bagKey, value));
      });
    }
    return tokens;
  }

  /// "20m" under 1 km; "1.5km" / "1km" at/above 1 km.
  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      final s = km == km.roundToDouble()
          ? km.toStringAsFixed(0)
          : km.toStringAsFixed(1);
      return '${s}km';
    }
    return '${meters.round()}m';
  }

  /// m:ss (minutes may be 0, e.g. 45s → "0:45").
  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// A catalog extra metric ("box_height_cm": 60 → "60cm"), unit from the
  /// registry; falls back to a bare value when the bagKey is unknown.
  String _formatMetric(String bagKey, num value) {
    final v = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
    final def = _metricDefForBagKey(bagKey);
    return def != null ? '$v${def.canonicalUnit}' : v;
  }

  MetricDef? _metricDefForBagKey(String bagKey) {
    for (final def in kMetricCatalog.values) {
      if (def.bagKey == bagKey) return def;
    }
    return null;
  }

  String _a11yLabel() {
    switch (summary.status) {
      case RailSetStatus.done:
      case RailSetStatus.warmup:
        final isWarmup = summary.status == RailSetStatus.warmup;
        final reps = summary.reps;
        final hasLoad = !summary.isBodyweight &&
            summary.weight != null &&
            summary.weight! > 0;
        final loadPart = summary.isBodyweight
            ? 'bodyweight'
            : (hasLoad
                ? (summary.weightLabel ?? _formatWeight(summary.weight))
                : null);
        final detail = [
          if (loadPart != null) loadPart,
          if (reps != null && reps > 0) '$reps reps',
          if (summary.distanceMeters != null && summary.distanceMeters! > 0)
            _formatDistance(summary.distanceMeters!),
          if (summary.durationSeconds != null && summary.durationSeconds! > 0)
            _formatTime(summary.durationSeconds!),
          if (summary.extraMetrics != null)
            ...summary.extraMetrics!.entries
                .map((e) => _formatMetric(e.key, e.value)),
        ].join(', ');
        final head = isWarmup
            ? 'Warm-up set, completed'
            : 'Set ${summary.displayIndex}, completed';
        return detail.isEmpty
            ? '$head, tap to edit'
            : '$head, $detail, tap to edit';
      case RailSetStatus.current:
        return 'Set ${summary.displayIndex}, current';
      case RailSetStatus.upcoming:
        return 'Set ${summary.displayIndex}, upcoming, tap to edit';
    }
  }
}

class _PillStyle {
  final Color bg;
  final Color border;
  final Color fg;
  final FontWeight weight;
  const _PillStyle(this.bg, this.border, this.fg, this.weight);
}

_PillStyle _styleFor(
  RailSetStatus status,
  Color accent,
  Color onSurface,
  bool isDark,
) {
  switch (status) {
    case RailSetStatus.done:
      return _PillStyle(
        accent.withValues(alpha: isDark ? 0.18 : 0.12),
        accent.withValues(alpha: 0.45),
        isDark ? Colors.white : Colors.black,
        FontWeight.w600,
      );
    case RailSetStatus.warmup:
      return _PillStyle(
        onSurface.withValues(alpha: 0.05),
        onSurface.withValues(alpha: 0.18),
        onSurface.withValues(alpha: 0.75),
        FontWeight.w600,
      );
    case RailSetStatus.current:
      return _PillStyle(
        Colors.transparent,
        accent,
        accent,
        FontWeight.w700,
      );
    case RailSetStatus.upcoming:
      return _PillStyle(
        onSurface.withValues(alpha: 0.03),
        onSurface.withValues(alpha: 0.12),
        onSurface.withValues(alpha: 0.45),
        FontWeight.w500,
      );
  }
}

/// "+N more" chip at the right edge of the rail when ≥ 12 sets exist.
class RailOverflowChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const RailOverflowChip({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Semantics(
      button: true,
      label: AppLocalizations.of(context)!.setRailInternalsMoreSets(count),
      child: GestureDetector(
        onTap: () {
          HapticService.instance.tick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Text(
            AppLocalizations.of(context)!.setRailInternalsValue(count),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
