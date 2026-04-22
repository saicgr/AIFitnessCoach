// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// 4-chip "how did that set feel?" picker. Replaces raw RIR numbers with
// emoji + label pairs — keeps beginners out of RPE/RIR math while still
// writing RIR 4/3/1/0 under the hood so existing analytics/progressions
// keep working unchanged.
//
// Chip height: 44 pt labeled (40 pt emoji-only compact). Dismissible —
// tapping the currently-selected chip returns null so a user can unset
// before logging.

import 'package:flutter/material.dart';

import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';

/// 4 felt buckets mapped to RIR. Order matches the plan spec:
/// Easy → 4, Good → 3, Hard → 1, V.Hard → 0.
enum FeltBucket {
  easy(rir: 4, emoji: '😌', label: 'Easy'),
  good(rir: 3, emoji: '🙂', label: 'Good'),
  hard(rir: 1, emoji: '😮‍💨', label: 'Hard'),
  veryHard(rir: 0, emoji: '🥵', label: 'V.Hard');

  final int rir;
  final String emoji;
  final String label;

  const FeltBucket({required this.rir, required this.emoji, required this.label});

  /// Map an RIR integer back to its bucket. Returns null if no exact match —
  /// higher Advanced-tier RIR values (2, 5+) aren't expressible in this
  /// picker and should render nothing selected rather than lying.
  static FeltBucket? fromRir(int? rir) {
    if (rir == null) return null;
    for (final b in FeltBucket.values) {
      if (b.rir == rir) return b;
    }
    return null;
  }
}

class FeltPicker extends StatelessWidget {
  /// Current RIR. When null or unmapped, no chip is visually selected.
  final int? currentRir;

  /// Emit `null` when the caller should clear the selection (user tapped
  /// the currently-selected chip), or a new RIR int otherwise.
  final ValueChanged<int?> onChanged;

  /// Compact mode drops the text label — used when focal-card vertical
  /// budget is tight (per the responsive-compaction table in the plan).
  final bool compact;

  const FeltPicker({
    super.key,
    required this.currentRir,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final current = FeltBucket.fromRir(currentRir);
    final height = compact ? 40.0 : 44.0;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (final bucket in FeltBucket.values) ...[
            Expanded(
              child: _FeltChip(
                bucket: bucket,
                selected: current == bucket,
                compact: compact,
                accent: accent,
                isDark: isDark,
                onTap: () {
                  HapticService.instance.tap();
                  if (current == bucket) {
                    // Dismiss — tapping the selected chip clears the value so
                    // users aren't trapped into logging a felt-score.
                    onChanged(null);
                  } else {
                    onChanged(bucket.rir);
                  }
                },
              ),
            ),
            if (bucket != FeltBucket.veryHard) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _FeltChip extends StatelessWidget {
  final FeltBucket bucket;
  final bool selected;
  final bool compact;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _FeltChip({
    required this.bucket,
    required this.selected,
    required this.compact,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.82);
    final bg = selected
        ? accent
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04);
    final borderColor = selected
        ? accent
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10);

    return Semantics(
      button: true,
      selected: selected,
      label: '${bucket.label}, ${selected ? 'selected' : 'not selected'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bucket.emoji,
                style: TextStyle(fontSize: compact ? 18 : 16),
              ),
              if (!compact) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    bucket.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
