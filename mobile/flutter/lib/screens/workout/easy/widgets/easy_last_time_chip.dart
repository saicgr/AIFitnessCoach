// Easy tier — "Last time" chip.
//
// Compact row showing what the user did on THIS exercise in their most
// recent session:  ⏱  Last time: 25 lb × 12  ·  3 days ago
//
// Collapses to `SizedBox.shrink()` when there's no history (new exercise,
// first session). When [onCopy] is supplied the whole chip is tappable —
// "same as last time": one tap copies last session's weight × reps into the
// current set (a replay glyph signals the affordance). Without [onCopy] it
// stays a passive reference.

import 'package:flutter/material.dart';

import '../../../../data/services/haptic_service.dart';

class EasyLastTimeChip extends StatelessWidget {
  /// First-set weight from the most recent session, in user's display unit.
  final double? weight;
  final int? reps;
  final String unit; // 'kg' or 'lb'
  final DateTime? when;

  /// When non-null, the chip becomes a one-tap "use last time's numbers"
  /// control. Null → passive reference (legacy behavior).
  final VoidCallback? onCopy;

  const EasyLastTimeChip({
    super.key,
    required this.weight,
    required this.reps,
    required this.unit,
    required this.when,
    this.onCopy,
  });

  String _fmtWeight(double w) =>
      w % 1 == 0 ? w.toStringAsFixed(0) : w.toStringAsFixed(1);

  String _fmtAgo(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays >= 365) {
      final yrs = (diff.inDays / 365).floor();
      return '$yrs yr${yrs == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 30) {
      final mo = (diff.inDays / 30).floor();
      return '$mo mo${mo == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 7) {
      final wks = (diff.inDays / 7).floor();
      return '$wks wk${wks == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 1) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    if (weight == null || reps == null || weight! <= 0) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tappable = onCopy != null;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6);
    // A tappable chip reads slightly stronger so the copy affordance lands.
    final bg = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: tappable ? 0.06 : 0.04);
    final border = (isDark ? Colors.white : Colors.black)
        .withValues(alpha: tappable ? 0.12 : 0.08);

    final ago = when == null ? null : _fmtAgo(when!);

    final chip = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 14, color: muted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              ago == null
                  ? 'Last time: ${_fmtWeight(weight!)} $unit × $reps'
                  : 'Last time: ${_fmtWeight(weight!)} $unit × $reps · $ago',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 8),
            Icon(Icons.replay_rounded, size: 14, color: muted),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: tappable
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  HapticService.light();
                  onCopy!();
                },
                child: chip,
              ),
            )
          : chip,
    );
  }
}
