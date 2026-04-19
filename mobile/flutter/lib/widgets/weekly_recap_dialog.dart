import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../core/utils/leaderboard_tier_color.dart';
import '../data/models/weekly_recap.dart';
import '../data/providers/weekly_recap_provider.dart';
import '../data/services/haptic_service.dart';

/// Monday-morning celebration modal. Shown on first foreground open after
/// Monday 06:00 device-local time, if the user has a meaningful recap from
/// last week. Dismissing via the CTA or the SKIP button both write an ack
/// to SharedPreferences so the modal can't re-fire the same week.
///
/// Modeled on level_up_dialog.dart's layered confetti + animation sequence,
/// but purposely self-contained — the two dialogs will diverge over time.
Future<void> showWeeklyRecapDialog({
  required BuildContext context,
  required WeeklyRecap recap,
  required WidgetRef ref,
}) async {
  HapticService.medium();
  await showGeneralDialog(
    context: context,
    barrierLabel: 'Weekly Recap',
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.88),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, _, __) => _WeeklyRecapDialog(recap: recap),
    transitionBuilder: (ctx, anim, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
  );

  // Mark this week acked regardless of dismissal route.
  final weekKey = isoWeekKey(DateTime.now());
  await ref.read(weeklyRecapAckProvider.notifier).ack(weekKey);
}

class _WeeklyRecapDialog extends ConsumerStatefulWidget {
  final WeeklyRecap recap;
  const _WeeklyRecapDialog({required this.recap});

  @override
  ConsumerState<_WeeklyRecapDialog> createState() => _WeeklyRecapDialogState();
}

class _WeeklyRecapDialogState extends ConsumerState<_WeeklyRecapDialog>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _xpCounter;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 1400));
    _xpCounter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confetti.play();
      _xpCounter.forward();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    _xpCounter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recap = widget.recap;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final border = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    final tierHeroColor = tierColor(recap.tierCurrent, isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Confetti burst
          ConfettiWidget(
            confettiController: _confetti,
            blastDirection: math.pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 40,
            maxBlastForce: 28,
            minBlastForce: 12,
            gravity: 0.2,
            shouldLoop: false,
            colors: [tierHeroColor, accent, AppColors.cyan, Colors.white],
          ),
          // SKIP button
          Positioned(
            top: 16 + MediaQuery.of(context).padding.top,
            right: 12,
            child: TextButton(
              onPressed: () {
                HapticService.light();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: textMuted),
              child: const Text('SKIP'),
            ),
          ),
          // Main card
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20, right: 20,
                top: 32 + MediaQuery.of(context).padding.top,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: tierHeroColor.withValues(alpha: 0.18),
                        blurRadius: 38,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderChip(tierColor: tierHeroColor),
                      const SizedBox(height: 14),
                      _BigRankRow(
                        recap: recap,
                        textColor: textColor,
                        textMuted: textMuted,
                      ),
                      const SizedBox(height: 8),
                      _XpEarnedRow(
                        recap: recap,
                        accent: accent,
                        counter: _xpCounter,
                        textColor: textColor,
                        textMuted: textMuted,
                      ),
                      if (recap.consecutiveWeeksInTier >= 1) ...[
                        const SizedBox(height: 14),
                        _TierStreakStripe(
                          recap: recap,
                          tierColor: tierHeroColor,
                          textColor: textColor,
                          textMuted: textMuted,
                        ),
                      ],
                      if (recap.awardsUnlocked.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _AwardsList(
                          awards: recap.awardsUnlocked,
                          accent: accent,
                          textColor: textColor,
                          textMuted: textMuted,
                          border: border,
                        ),
                      ],
                      if (recap.shieldsUsed > 0) ...[
                        const SizedBox(height: 12),
                        _ShieldRow(
                          count: recap.shieldsUsed,
                          textColor: textColor,
                          textMuted: textMuted,
                        ),
                      ],
                      if (recap.passes.isNotEmpty ||
                          recap.overtakenBy.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _MovementRow(
                          passes: recap.passes.length,
                          overtaken: recap.overtakenBy.length,
                          textColor: textColor,
                          textMuted: textMuted,
                          accent: accent,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _CtaButton(
                        onTap: () {
                          HapticService.medium();
                          Navigator.of(context).pop();
                        },
                        accent: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final Color tierColor;
  const _HeaderChip({required this.tierColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: tierColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tierColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          'LAST WEEK',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: tierColor,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _BigRankRow extends StatelessWidget {
  final WeeklyRecap recap;
  final Color textColor, textMuted;
  const _BigRankRow({
    required this.recap,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final rank = recap.rankCurrent;
    final delta = recap.rankDelta;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          rank != null ? '#$rank' : '—',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -1,
            height: 1.0,
          ),
        ),
        if (delta != null && delta != 0) ...[
          const SizedBox(width: 10),
          _DeltaBadge(delta: delta),
        ],
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final int delta;
  const _DeltaBadge({required this.delta});

  @override
  Widget build(BuildContext context) {
    final up = delta > 0;
    final color = up ? const Color(0xFF39C96B) : const Color(0xFFE05A5A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14, color: color),
          const SizedBox(width: 3),
          Text(
            '${delta.abs()}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpEarnedRow extends StatelessWidget {
  final WeeklyRecap recap;
  final Color accent, textColor, textMuted;
  final AnimationController counter;
  const _XpEarnedRow({
    required this.recap,
    required this.accent,
    required this.counter,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final target = recap.xpEarnedThisWeek;
    return AnimatedBuilder(
      animation: counter,
      builder: (ctx, _) {
        final shown = (target * counter.value).round();
        return Column(
          children: [
            Text(
              '+$shown XP',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: accent,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'earned last week',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        );
      },
    );
  }
}

class _TierStreakStripe extends StatelessWidget {
  final WeeklyRecap recap;
  final Color tierColor;
  final Color textColor, textMuted;
  const _TierStreakStripe({
    required this.recap,
    required this.tierColor,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = recap.consecutiveWeeksInTier;
    final tierLabel = tierDisplayName(recap.tierCurrent);
    if (tierLabel.isEmpty) return const SizedBox.shrink();

    String? subtitle;
    if (recap.nextMilestoneWeeks != null && recap.nextMilestoneXp != null) {
      final remaining = recap.nextMilestoneWeeks! - weeks;
      subtitle = '$remaining more for +${recap.nextMilestoneXp} XP';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text('🔥',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week $weeks in $tierLabel',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardsList extends StatelessWidget {
  final List<RecapReward> awards;
  final Color accent, textColor, textMuted, border;
  const _AwardsList({
    required this.awards,
    required this.accent,
    required this.textColor,
    required this.textMuted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'REWARDS UNLOCKED',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: textMuted,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        for (final a in awards) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Text(
                  a.badgeIcon?.isNotEmpty == true ? a.badgeIcon! : '✨',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.badgeName ?? _kindDisplay(a.kind),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      if (a.tier != null && a.consecutiveWeeks != null)
                        Text(
                          '${tierDisplayName(a.tier)} · ${a.consecutiveWeeks}w streak',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        )
                      else
                        Text(
                          _kindSubtitle(a.kind),
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                    ],
                  ),
                ),
                if (a.xp > 0)
                  Text(
                    '+${a.xp} XP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _kindDisplay(String kind) {
    switch (kind) {
      case 'tier_persistence':
        return 'Tier Persistence';
      case 'first_time_tier':
        return 'New Tier Unlocked';
      case 'cumulative_weeks':
        return 'Consistency Milestone';
      case 'peak_rank':
        return 'Personal Best Rank';
      case 'rising_star':
        return 'Rising Star';
      case 'phoenix_rising':
        return 'Phoenix Rising';
      case 'shield_save':
        return 'Rank Shield Activated';
      default:
        return 'Reward';
    }
  }

  String _kindSubtitle(String kind) {
    switch (kind) {
      case 'peak_rank':
        return 'Personal best';
      case 'rising_star':
        return '↑5+ ranks from last week';
      case 'phoenix_rising':
        return 'Back on the board';
      case 'shield_save':
        return 'Streak preserved';
      default:
        return '';
    }
  }
}

class _ShieldRow extends StatelessWidget {
  final int count;
  final Color textColor, textMuted;
  const _ShieldRow({
    required this.count,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('🛡️', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            count == 1
                ? 'Rank Shield activated — streak preserved'
                : '$count Rank Shields activated',
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  final int passes;
  final int overtaken;
  final Color textColor, textMuted, accent;
  const _MovementRow({
    required this.passes,
    required this.overtaken,
    required this.textColor,
    required this.textMuted,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (passes > 0)
          Expanded(
            child: _StatPill(
              icon: Icons.arrow_upward,
              label: 'Passed',
              value: passes,
              color: const Color(0xFF39C96B),
              textColor: textColor,
              textMuted: textMuted,
            ),
          ),
        if (passes > 0 && overtaken > 0) const SizedBox(width: 8),
        if (overtaken > 0)
          Expanded(
            child: _StatPill(
              icon: Icons.arrow_downward,
              label: 'Passed by',
              value: overtaken,
              color: const Color(0xFFE05A5A),
              textColor: textColor,
              textMuted: textMuted,
            ),
          ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color, textColor, textMuted;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              )),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 11, color: textMuted)),
        ],
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accent;
  const _CtaButton({required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    // NOTE: styling the child Text directly (rather than passing `textStyle`
    // to ElevatedButton.styleFrom) avoids a Flutter TextStyle interpolation
    // warning — the button's MaterialStateTextStyle has inherit:false while
    // a raw TextStyle has inherit:true, and animating between them throws
    // "Failed to interpolate TextStyles with different inherit values".
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'START THIS WEEK →',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
