// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Internal pill + overflow chip widgets for `set_rail.dart`. Split purely so
// set_rail.dart stays ≤ 250 lines per project convention.

import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';
import 'set_rail.dart';

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
        final w = summary.weightLabel ?? _formatWeight(summary.weight);
        final r = summary.reps?.toString() ?? '-';
        return '$prefix✓$w×$r';
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

  String _a11yLabel() {
    switch (summary.status) {
      case RailSetStatus.done:
        return 'Set ${summary.displayIndex}, completed, tap to edit';
      case RailSetStatus.warmup:
        return 'Warm-up set, completed, tap to edit';
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
      label: '$count more sets',
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
            '+$count',
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
