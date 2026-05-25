import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../core/theme/theme_colors.dart';
import '../../data/providers/fasting_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/glass_back_button.dart';
import 'widgets/fasting_stage_model.dart';

/// Full-screen "Body Status" — a live vertical journey through all 7
/// metabolic [FastingStage]s for the user's current fast.
///
/// Each row shows the stage icon, name, hour mark and the CALCULATED
/// device-local clock time it is reached (`fastStart + startHour`). Rows are
/// done / current / upcoming. Tapping a stage expands its description plus
/// within-stage milestones, each with its own calculated clock time.
///
/// With no active fast the screen drops to preview mode — relative hours
/// only, no clock times.
///
/// Route: `/fasting/body-status`.
class FastingBodyStatusScreen extends ConsumerStatefulWidget {
  const FastingBodyStatusScreen({super.key});

  @override
  ConsumerState<FastingBodyStatusScreen> createState() =>
      _FastingBodyStatusScreenState();
}

class _FastingBodyStatusScreenState
    extends ConsumerState<FastingBodyStatusScreen> {
  /// Index of the stage the user manually expanded. Null → the current stage
  /// stays expanded automatically (live) or nothing (preview).
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final fastingState = ref.watch(fastingProvider);
    final activeFast = fastingState.activeFast;

    // Live elapsed seconds (drives done/now/upcoming + the pulse).
    final elapsedSeconds = ref.watch(fastingTimerProvider).value ?? 0;
    final bool isLive = activeFast != null;
    final double elapsedHours = isLive ? elapsedSeconds / 3600.0 : 0.0;

    final DateTime? fastStart = activeFast?.startTime;
    // Goal in hours — used to flag stages "beyond your goal".
    final double? goalHours =
        activeFast != null ? activeFast.goalDurationMinutes / 60.0 : null;

    final FastingStage currentStage =
        isLive ? FastingStage.forElapsedHours(elapsedHours) : FastingStage.fed;

    final stages = FastingStage.values;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _header(colors, isLive, currentStage, elapsedHours),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final stage = stages[i];
                        return AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 420),
                          child: SlideAnimation(
                            verticalOffset: 28,
                            child: FadeInAnimation(
                              child: _StageRow(
                                stage: stage,
                                isFirst: i == 0,
                                isLast: i == stages.length - 1,
                                isLive: isLive,
                                elapsedHours: elapsedHours,
                                fastStart: fastStart,
                                goalHours: goalHours,
                                expanded: _isExpanded(i, stage, currentStage,
                                    isLive),
                                onTap: () => _toggle(i),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: stages.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating glass back button — matches every other detail screen.
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: const GlassBackButton(),
          ),
        ],
      ),
    );
  }

  bool _isExpanded(
      int i, FastingStage stage, FastingStage currentStage, bool isLive) {
    if (_expandedIndex != null) return _expandedIndex == i;
    // Default: the current stage is expanded when a fast is live.
    return isLive && stage == currentStage;
  }

  void _toggle(int i) {
    setState(() {
      _expandedIndex = _expandedIndex == i ? -1 : i;
    });
  }

  Widget _header(ThemeColors colors, bool isLive, FastingStage currentStage,
      double elapsedHours) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fastingBodyStatusBodyStatus,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isLive
                ? l10n.fastingBodyStatusLiveSubtitle(_formatElapsed(elapsedHours))
                : l10n.fastingBodyStatusPreviewSubtitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: colors.textSecondary,
            ),
          ),
          if (!isLive) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: colors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: colors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.fastingBodyStatusStartFastHint,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatElapsed(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

/// One stage row in the vertical timeline, with a left connector line.
class _StageRow extends StatelessWidget {
  final FastingStage stage;
  final bool isFirst;
  final bool isLast;
  final bool isLive;
  final double elapsedHours;
  final DateTime? fastStart;
  final double? goalHours;
  final bool expanded;
  final VoidCallback onTap;

  const _StageRow({
    required this.stage,
    required this.isFirst,
    required this.isLast,
    required this.isLive,
    required this.elapsedHours,
    required this.fastStart,
    required this.goalHours,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final stageColor = stage.color;

    // done / current / upcoming.
    final bool isDone = isLive && elapsedHours >= stage.endHour;
    final bool isCurrent = isLive &&
        elapsedHours >= stage.startHour &&
        elapsedHours < stage.endHour;
    final bool isUpcoming = !isDone && !isCurrent;

    // A stage whose start lies beyond the user's goal — flagged so the user
    // knows their planned fast won't reach it.
    final bool beyondGoal =
        isLive && goalHours != null && stage.startHour >= goalHours!;

    final double opacity = isUpcoming ? (beyondGoal ? 0.5 : 0.7) : 1.0;

    return Opacity(
      opacity: opacity,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left connector + node ────────────────────────────────
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  _connector(colors, !isFirst, isDone, stageColor),
                  _node(colors, stageColor, isDone, isCurrent),
                  Expanded(
                    child: _connector(
                        colors, !isLast, isDone, stageColor,
                        flexible: true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Stage card ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _StageCard(
                  stage: stage,
                  stageColor: stageColor,
                  isDone: isDone,
                  isCurrent: isCurrent,
                  beyondGoal: beyondGoal,
                  isLive: isLive,
                  elapsedHours: elapsedHours,
                  fastStart: fastStart,
                  expanded: expanded,
                  onTap: onTap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connector(
      ThemeColors colors, bool visible, bool isDone, Color stageColor,
      {bool flexible = false}) {
    final line = Container(
      width: 2.5,
      height: flexible ? null : 14,
      color: visible
          ? (isDone
              ? stageColor.withValues(alpha: 0.5)
              : colors.cardBorder)
          : Colors.transparent,
    );
    return flexible ? Expanded(child: line) : line;
  }

  Widget _node(
      ThemeColors colors, Color stageColor, bool isDone, bool isCurrent) {
    if (isCurrent) {
      // Pulsing current-stage node.
      return _PulsingNode(color: stageColor, icon: stage.icon);
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? stageColor.withValues(alpha: 0.2)
            : colors.surface,
        border: Border.all(
          color: isDone ? stageColor : colors.cardBorder,
          width: 2,
        ),
      ),
      child: Icon(
        isDone ? Icons.check_rounded : stage.icon,
        size: 17,
        color: isDone ? stageColor : colors.textMuted,
      ),
    );
  }
}

/// The pulsing node used for the current stage.
class _PulsingNode extends StatefulWidget {
  final Color color;
  final IconData icon;

  const _PulsingNode({required this.color, required this.icon});

  @override
  State<_PulsingNode> createState() => _PulsingNodeState();
}

class _PulsingNodeState extends State<_PulsingNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    // Respect reduced-motion: only loop the pulse when animations are on.
    if (!WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
        .disableAnimations) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.25 + t * 0.35),
                    blurRadius: 8 + t * 12,
                    spreadRadius: t * 4,
                  ),
                ],
              ),
              child: Icon(widget.icon, size: 17, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

/// The expandable card body for a stage.
class _StageCard extends StatelessWidget {
  final FastingStage stage;
  final Color stageColor;
  final bool isDone;
  final bool isCurrent;
  final bool beyondGoal;
  final bool isLive;
  final double elapsedHours;
  final DateTime? fastStart;
  final bool expanded;
  final VoidCallback onTap;

  const _StageCard({
    required this.stage,
    required this.stageColor,
    required this.isDone,
    required this.isCurrent,
    required this.beyondGoal,
    required this.isLive,
    required this.elapsedHours,
    required this.fastStart,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isCurrent
              ? stageColor.withValues(alpha: colors.isDark ? 0.16 : 0.10)
              : colors.surface,
          border: Border.all(
            color: isCurrent
                ? stageColor.withValues(alpha: 0.5)
                : colors.cardBorder,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.name,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? stageColor : colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stage.tagline,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _hourMark(stage),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: stageColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLive && fastStart != null
                          ? _clockTime(fastStart!, stage.startHour)
                          : 'at ${stage.startHour}h',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.expand_more_rounded,
                      size: 20, color: colors.textMuted),
                ),
              ],
            ),
            if (isCurrent || beyondGoal) ...[
              const SizedBox(height: 8),
              _badge(context, colors),
            ],
            // Animated expand: description + milestones.
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: expanded ? 1 : 0,
                child: expanded
                    ? _expandedBody(context, colors)
                    : const SizedBox(width: double.infinity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    final bool current = isCurrent;
    final color = current ? stageColor : colors.warning;
    final text = current ? l10n.fastingBodyStatusYouAreHere : l10n.fastingBodyStatusBeyondGoal;
    final icon =
        current ? Icons.my_location_rounded : Icons.flag_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expandedBody(BuildContext context, ThemeColors colors) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage.description,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          if (stage.milestones.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              l10n.fastingBodyStatusKeyMoments,
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: colors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in stage.milestones)
              _MilestoneRow(
                milestone: m,
                stageColor: stageColor,
                isLive: isLive,
                elapsedHours: elapsedHours,
                fastStart: fastStart,
              ),
          ],
        ],
      ),
    );
  }

  String _hourMark(FastingStage stage) {
    if (stage == FastingStage.values.last) return '${stage.startHour}h+';
    return '${stage.startHour}–${stage.endHour}h';
  }
}

/// A single within-stage milestone row with a state dot + calculated time.
class _MilestoneRow extends StatelessWidget {
  final FastingMilestone milestone;
  final Color stageColor;
  final bool isLive;
  final double elapsedHours;
  final DateTime? fastStart;

  const _MilestoneRow({
    required this.milestone,
    required this.stageColor,
    required this.isLive,
    required this.elapsedHours,
    required this.fastStart,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);

    final bool done = isLive && elapsedHours >= milestone.hourOffset;
    // "Now" if elapsed is within the hour preceding the milestone.
    final bool now = isLive &&
        !done &&
        elapsedHours >= milestone.hourOffset - 1;

    final Color dotColor =
        done ? stageColor : (now ? colors.warning : colors.textMuted);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MilestoneDot(color: dotColor, done: done, now: now),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.text,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  isLive && fastStart != null
                      ? '${milestone.hourOffset}h · '
                          '${_clockTime(fastStart!, milestone.hourOffset)}'
                      : 'at ${milestone.hourOffset}h',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: done
                        ? stageColor
                        : (now ? colors.warning : colors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated milestone dot — fills in / scales when done.
class _MilestoneDot extends StatelessWidget {
  final Color color;
  final bool done;
  final bool now;

  const _MilestoneDot(
      {required this.color, required this.done, required this.now});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(top: 2),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
      child: done
          ? const Icon(Icons.check_rounded, size: 9, color: Colors.white)
          : (now
              ? Center(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                  ),
                )
              : null),
    );
  }
}

/// Format `fastStart + offsetHours` as a device-local Today/Tomorrow h:mm a.
String _clockTime(DateTime fastStart, int offsetHours) {
  final target = fastStart.add(Duration(hours: offsetHours));
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final targetDay = DateTime(target.year, target.month, target.day);
  final dayDiff = targetDay.difference(today).inDays;

  int hour12 = target.hour % 12;
  if (hour12 == 0) hour12 = 12;
  final minute = target.minute.toString().padLeft(2, '0');
  final period = target.hour < 12 ? 'AM' : 'PM';
  final time = '$hour12:$minute $period';

  if (dayDiff == 0) return 'Today $time';
  if (dayDiff == 1) return 'Tomorrow $time';
  if (dayDiff == -1) return 'Yesterday $time';
  if (dayDiff > 1) return 'In $dayDiff days, $time';
  return time;
}
