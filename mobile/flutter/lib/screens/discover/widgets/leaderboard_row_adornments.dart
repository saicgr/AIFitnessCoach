import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/leaderboard_tier_color.dart';

/// Shared row decorations for every Discover leaderboard row.
///
/// These are intentionally stateless and tight-layout so the inline row
/// width budget on 360dp phones doesn't blow up. Overlays (PR, peak crown,
/// activity pulse) paint on top of the avatar via Stack so they cost zero
/// inline pixels.
///
/// Everything uses semantic labels + haptic-free taps. The Discover row's
/// parent Material/InkWell handles tap feedback.

// ─── Rank-delta chip ────────────────────────────────────────────────────────

/// Compact "↑3" / "·" / "↓2" chip next to the rank number. No background,
/// color-coded (green up, red down, neutral gray unchanged).
///
/// `null` delta means "no prev-week archive row yet" — common during the
/// first week the leaderboard system runs, or for brand-new users who just
/// entered the board this week. We render a subtle gray "NEW" pill so the
/// slot is never empty and the user understands there's no history yet.
class RankDeltaChip extends StatelessWidget {
  final int? delta;
  final bool compact;  // true on <340dp — drops the number, keeps color/arrow only

  const RankDeltaChip({
    super.key,
    required this.delta,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final d = delta;
    if (d == null) {
      // No previous-week data → render a muted em-dash so the slot isn't
      // empty but doesn't shout "NEW" (which wraps to two lines on narrow
      // 30dp widths and reads as broken layout). Arrows start appearing
      // once the weekly archive has at least one prior week of data.
      return Semantics(
        label: 'No previous rank data yet',
        child: SizedBox(
          width: 30,
          child: Text(
            '—',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    final color = d > 0
        ? const Color(0xFF39C96B)   // green — rank improved (smaller number)
        : d < 0
            ? const Color(0xFFE05A5A) // red — rank worsened
            : Colors.grey;

    final arrow = d > 0 ? '↑' : (d < 0 ? '↓' : '·');
    final absStr = d == 0 ? '' : d.abs().toString();

    return Semantics(
      label: d == 0
          ? 'Rank unchanged'
          : (d > 0 ? 'Up $absStr places' : 'Down $absStr places'),
      child: SizedBox(
        width: 30,
        child: Text(
          compact ? arrow : '$arrow$absStr',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// ─── Streak flame ───────────────────────────────────────────────────────────

/// 🔥 + streak day count. Hides entirely when `streak <= 0`. Tap target for
/// a tooltip-style detail is not included here — keep it small & silent.
class StreakFlame extends StatelessWidget {
  final int streak;
  final Color? textColor;
  final bool compact;  // true → just 🔥 without the number

  const StreakFlame({
    super.key,
    required this.streak,
    this.textColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();
    return Semantics(
      label: 'Streak $streak days',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department, size: 13, color: Color(0xFFFF8A3D)),
          if (!compact) ...[
            const SizedBox(width: 1),
            Text(
              '$streak',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor ?? const Color(0xFFFF8A3D),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Peak-tier crown ────────────────────────────────────────────────────────

/// Small crown overlay — renders only if user has ever hit top5 or top1.
/// Designed as a Stack child on the avatar, so it costs zero inline width.
class PeakCrown extends StatelessWidget {
  final String? peakTier;
  const PeakCrown({super.key, required this.peakTier});

  @override
  Widget build(BuildContext context) {
    if (peakTier != 'top1' && peakTier != 'top5' && peakTier != 'legendary' && peakTier != 'top') {
      return const SizedBox.shrink();
    }
    final gold = peakTier == 'top1' || peakTier == 'legendary';
    return Positioned(
      top: -2,
      right: -2,
      child: Container(
        width: 14, height: 14,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          gold ? '👑' : '💎',
          style: const TextStyle(fontSize: 9),
        ),
      ),
    );
  }
}

// ─── PR this week dot ───────────────────────────────────────────────────────

/// Small 💪 badge overlay on the avatar if user hit a PR this week.
class PrDot extends StatelessWidget {
  final bool hit;
  const PrDot({super.key, required this.hit});

  @override
  Widget build(BuildContext context) {
    if (!hit) return const SizedBox.shrink();
    return Positioned(
      bottom: -1,
      right: -1,
      child: Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text('💪', style: TextStyle(fontSize: 8)),
      ),
    );
  }
}

// ─── Country flag ───────────────────────────────────────────────────────────

/// Wraps a flag emoji in a consistent text style. Returns empty SizedBox
/// when iso2 is null/invalid so the row layout doesn't wobble.
class FlagText extends StatelessWidget {
  final String? flagEmoji;  // already converted via country_flag.flagFor
  const FlagText({super.key, required this.flagEmoji});

  @override
  Widget build(BuildContext context) {
    final f = flagEmoji;
    if (f == null || f.isEmpty) return const SizedBox.shrink();
    return Text(
      f,
      style: const TextStyle(fontSize: 12, height: 1.0),
    );
  }
}

// ─── Activity pulse ─────────────────────────────────────────────────────────

/// Green 6dp dot overlay on the avatar indicating "active in last 24h".
class ActivityPulse extends StatelessWidget {
  final bool active;
  const ActivityPulse({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF39C96B),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─── Gap chip ───────────────────────────────────────────────────────────────

/// Placed between adjacent Near-You rows when the current user is on one
/// side of the divider — shows the XP delta either as "+N ahead" or "−N
/// behind" so the user knows exactly how close the chase is.
class GapChip extends StatelessWidget {
  final double delta;        // neighbor metric − my metric (signed)
  final String metricLabel;  // 'XP' | 'min' | 'days'
  final Color accent;

  const GapChip({
    super.key,
    required this.delta,
    required this.metricLabel,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    if (delta == 0) return const SizedBox.shrink();
    final sign = delta > 0 ? '+' : '−';
    final label = '$sign${delta.abs().toStringAsFixed(0)} $metricLabel';
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: accent,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// ─── Tier-ring avatar (replaces _Avatar when tier data available) ──────────

/// Circular avatar with a tier-colored ring + overlay slots for:
///   - PeakCrown (top-right)
///   - PrDot (bottom-right)
///   - ActivityPulse (top-left)
/// Falls back to initial letter when `url` is null or fails to load.
class TierRingAvatar extends StatelessWidget {
  final String? url;
  final String fallback;
  final double radius;
  final Color accent;       // base accent (used for default ring if no tier)
  final String? tier;       // current week tier for ring color
  final String? peakTier;
  final bool isDark;
  final bool prHit;
  final bool activeNow;
  final double ringWidth;

  const TierRingAvatar({
    super.key,
    required this.url,
    required this.fallback,
    required this.radius,
    required this.accent,
    required this.isDark,
    this.tier,
    this.peakTier,
    this.prHit = false,
    this.activeNow = false,
    this.ringWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final ring = tier == null || tier == 'starter' || tier == 'active'
        ? accent.withValues(alpha: 0.35)
        : tierRing(tier, isDark);
    final diameter = radius * 2;

    final initial = (fallback.isNotEmpty ? fallback[0] : '?').toUpperCase();
    final bgFill = accent.withValues(alpha: 0.2);
    final fontSize = radius * 0.85;

    Widget imageOrInitial;
    if (url == null || url!.isEmpty) {
      imageOrInitial = CircleAvatar(
        radius: radius - ringWidth,
        backgroundColor: bgFill,
        child: Text(initial,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: fontSize)),
      );
    } else {
      imageOrInitial = ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          width: diameter - ringWidth * 2,
          height: diameter - ringWidth * 2,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: diameter - ringWidth * 2,
            height: diameter - ringWidth * 2,
            color: bgFill,
          ),
          errorWidget: (_, __, ___) => CircleAvatar(
            radius: radius - ringWidth,
            backgroundColor: bgFill,
            child: Text(initial,
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize)),
          ),
        ),
      );
    }

    return SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: ringWidth),
            ),
            padding: EdgeInsets.all(ringWidth),
            child: imageOrInitial,
          ),
          PeakCrown(peakTier: peakTier),
          PrDot(hit: prHit),
          ActivityPulse(active: activeNow),
        ],
      ),
    );
  }
}
