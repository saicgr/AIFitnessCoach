import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/skill_progression.dart';
import '../../data/providers/skill_progression_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/design_system/zealova.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/progression_step_card.dart';
import 'widgets/practice_attempt_sheet.dart';

import '../../l10n/generated/app_localizations.dart';
/// Detailed view of a progression chain with skill tree visualization
class ChainDetailScreen extends ConsumerStatefulWidget {
  final String chainId;

  const ChainDetailScreen({
    super.key,
    required this.chainId,
  });

  @override
  ConsumerState<ChainDetailScreen> createState() => _ChainDetailScreenState();
}

class _ChainDetailScreenState extends ConsumerState<ChainDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    // Non-blocking: defer the network load until after the first frame so the
    // skeleton paints instantly instead of `initState` awaiting a round-trip.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadChainDetail();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChainDetail() async {
    final userId = ref.read(authStateProvider).user?.id;
    await ref.read(skillProgressionProvider.notifier).loadChainDetail(
          widget.chainId,
          userId: userId,
        );
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final state = ref.watch(skillProgressionProvider);

    final chain = state.selectedChain;
    final progress = state.selectedChainProgress;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: chain == null
          ? _buildLoadingState(isDark)
          : _buildContent(context, chain, progress, isDark),
    );
  }

  /// Layout-matched skeleton shown while the chain detail loads on a cold
  /// open. Mirrors the real content: header, an info card, then a vertical
  /// stack of progression-step rows — so the skeleton -> content swap is
  /// reflow-free instead of a centered blocking spinner.
  Widget _buildLoadingState(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, null, isDark),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: const [
                // Chain info card placeholder.
                SkeletonBox(height: 180, radius: 20),
                SizedBox(height: 24),
                // "Progression Path" section header placeholder.
                SkeletonBox(width: 180, height: 20),
                SizedBox(height: 16),
                // Progression-step row placeholders.
                SkeletonList(itemCount: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProgressionChain chain,
    UserSkillProgress? progress,
    bool isDark,
  ) {
    final tc = ThemeColors.of(context);
    final cyan = tc.accent;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final isStarted = progress != null;
    final steps = chain.steps ?? [];
    final currentStep = progress?.currentStepOrder ?? 0;

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(context, chain, isDark),

          // Content
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Chain info card
                SliverToBoxAdapter(
                  child: _buildChainInfoCard(
                    context,
                    chain,
                    progress,
                    isDark,
                  ),
                ),

                // Start button if not started
                if (!isStarted)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ZealovaButton(
                        label: AppLocalizations.of(context).chainDetailStartThisProgression,
                        trailingIcon: Icons.play_arrow_rounded,
                        height: 56,
                        onTap: () => _startChain(chain.id),
                      ),
                    ),
                  ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.route_rounded,
                          size: 18,
                          color: cyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).chainDetailProgressionPath.toUpperCase(),
                          style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 1.6),
                        ),
                        const Spacer(),
                        Text(
                          '${steps.length} steps'.toUpperCase(),
                          style: ZType.lbl(11, color: textSecondary, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),

                // Steps list with connecting line
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final step = steps[index];
                        final isUnlocked = isStarted &&
                            progress.isStepUnlocked(step.stepOrder);
                        final isCurrent =
                            isStarted && step.stepOrder == currentStep;
                        final isCompleted =
                            isStarted && step.stepOrder < currentStep;
                        final isLast = index == steps.length - 1;

                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.1;
                            final animValue = Curves.easeOutBack.transform(
                              ((_animationController.value - delay) / (1 - delay))
                                  .clamp(0.0, 1.0),
                            );

                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - animValue)),
                              child: Opacity(
                                opacity: animValue,
                                child: child,
                              ),
                            );
                          },
                          child: _buildStepWithLine(
                            context: context,
                            step: step,
                            isUnlocked: isUnlocked,
                            isCurrent: isCurrent,
                            isCompleted: isCompleted,
                            isLast: isLast,
                            isStarted: isStarted,
                            isDark: isDark,
                          ),
                        );
                      },
                      childCount: steps.length,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProgressionChain? chain,
    bool isDark,
  ) {
    final tc = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GlassBackButton(
            onTap: () {
              HapticService.light();
              ref.read(skillProgressionProvider.notifier).clearSelectedChain();
              context.pop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (chain?.name ?? AppLocalizations.of(context).weekProgressStripLoading)
                  .toUpperCase(),
              style: ZType.disp(22, color: tc.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChainInfoCard(
    BuildContext context,
    ProgressionChain chain,
    UserSkillProgress? progress,
    bool isDark,
  ) {
    final tc = ThemeColors.of(context);
    final cyan = tc.accent;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final isStarted = progress != null;
    final progressPercent = isStarted
        ? progress.getProgressPercentage(chain.steps?.length ?? 1)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ZealovaCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              chain.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textSecondary,
                  ),
            ),
            const SizedBox(height: 16),

            // Metadata row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetaBadge(
                  Icons.category_rounded,
                  chain.category,
                  tc.textMuted,
                ),
                _buildMetaBadge(
                  Icons.stairs_rounded,
                  '${chain.steps?.length ?? "?"} steps',
                  tc.textMuted,
                ),
                _buildMetaBadge(
                  Icons.speed_rounded,
                  'Lvl ${chain.difficultyStart}-${chain.difficultyEnd}',
                  tc.textMuted,
                ),
                if (chain.estimatedWeeks != null)
                  _buildMetaBadge(
                    Icons.schedule_rounded,
                    '~${chain.estimatedWeeks} weeks',
                    tc.textMuted,
                  ),
              ],
            ),

            // Progress section
            if (isStarted) ...[
              const SizedBox(height: 20),
              const ZealovaRule(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).skillProgressSummaryYourProgress.toUpperCase(),
                          style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 1.4),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: AppColors.hairlineStrong,
                            color: cyan,
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: ZType.disp(26, color: cyan),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.fitness_center_rounded,
                    size: 13,
                    color: tc.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${progress.attemptsAtCurrent} attempts at current step'.toUpperCase(),
                    style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
                  ),
                  if (progress.bestRepsAtCurrent > 0) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 13,
                      color: tc.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Best: ${progress.bestRepsAtCurrent} reps'.toUpperCase(),
                      style: ZType.lbl(10, color: tc.textMuted, letterSpacing: 0.8),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaBadge(
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: ZType.lbl(10, color: color, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStepWithLine({
    required BuildContext context,
    required ProgressionStep step,
    required bool isUnlocked,
    required bool isCurrent,
    required bool isCompleted,
    required bool isLast,
    required bool isStarted,
    required bool isDark,
  }) {
    final tc = ThemeColors.of(context);
    final cyan = tc.accent;
    final green = tc.success;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Circle indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? green
                        : isCurrent
                            ? cyan
                            : tc.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? green
                          : isCurrent
                              ? cyan
                              : AppColors.hairlineStrong,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            color: tc.accentContrast,
                            size: 18,
                          )
                        : Text(
                            '${step.stepOrder}',
                            style: ZType.data(
                              13,
                              color: isCurrent
                                  ? tc.accentContrast
                                  : isUnlocked
                                      ? cyan
                                      : tc.textMuted,
                            ),
                          ),
                  ),
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted ? green : AppColors.hairlineStrong,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Step card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: ProgressionStepCard(
                step: step,
                isUnlocked: isUnlocked,
                isCurrent: isCurrent,
                isCompleted: isCompleted,
                onPractice: isCurrent
                    ? () => _showPracticeSheet(step)
                    : null,
                onTap: isUnlocked ? () => _showStepDetail(step) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startChain(String chainId) async {
    HapticService.medium();
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) return;

    final result = await ref.read(skillProgressionProvider.notifier).startChain(
          chainId,
          userId: userId,
        );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).chainDetailProgressionStartedGoodLuck),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPracticeSheet(ProgressionStep step) {
    HapticService.light();
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: PracticeAttemptSheet(
          step: step,
          chainId: widget.chainId,
          onAttemptLogged: (attempt) {
            // Reload data after attempt
            _loadChainDetail();
          },
        ),
      ),
    );
  }

  void _showStepDetail(ProgressionStep step) {
    HapticService.light();
    // Show detailed view of the step (could navigate to exercise detail or show a sheet)
    showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => GlassSheet(
        child: _StepDetailSheet(step: step),
      ),
    );
  }
}

/// Bottom sheet showing step details
class _StepDetailSheet extends StatelessWidget {
  final ProgressionStep step;

  const _StepDetailSheet({required this.step});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tc = ThemeColors.of(context);
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = tc.accent;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tc.surface.withValues(alpha: 0.5),
                        border: Border.all(color: cardBorder),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: cyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.exerciseName.toUpperCase(),
                            style: ZType.disp(20, color: tc.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Step ${step.stepOrder} - ${step.difficultyLabel}'.toUpperCase(),
                            style: ZType.lbl(10, color: textSecondary, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Unlock criteria
                if (step.unlockCriteria != null) ...[
                  _buildSection(
                    'Unlock Criteria',
                    step.unlockCriteriaText,
                    Icons.lock_open_rounded,
                    cyan,
                    tc.textMuted,
                    tc.textPrimary,
                  ),
                  const SizedBox(height: 16),
                ],

                // Tips
                if (step.tips != null && step.tips!.isNotEmpty) ...[
                  _buildSection(
                    'Tips',
                    step.tips!,
                    Icons.lightbulb_outline_rounded,
                    tc.textSecondary,
                    tc.textMuted,
                    tc.textPrimary,
                  ),
                  const SizedBox(height: 16),
                ],

                // Prerequisites
                if (step.prerequisites != null &&
                    step.prerequisites!.isNotEmpty) ...[
                  _buildSection(
                    'Prerequisites',
                    step.prerequisites!,
                    Icons.checklist_rounded,
                    tc.textSecondary,
                    tc.textMuted,
                    tc.textPrimary,
                  ),
                ],

                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).commonClose.toUpperCase(),
                      style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    Color iconColor,
    Color labelColor,
    Color contentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: ZType.lbl(11, color: labelColor, letterSpacing: 1.4),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 15, color: contentColor),
        ),
      ],
    );
  }
}
