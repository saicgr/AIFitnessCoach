import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/skill_progression.dart';
import '../../data/providers/skill_progression_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/progression_step_card.dart';
import 'widgets/practice_attempt_sheet.dart';

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
    _loadChainDetail();
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

  Widget _buildLoadingState(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, null, isDark),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
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
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

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
                      child: FilledButton.icon(
                        onPressed: () => _startChain(chain.id),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start This Progression'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cyan,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                        ),
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
                          size: 20,
                          color: cyan,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Progression Path',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Spacer(),
                        Text(
                          '${steps.length} steps',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 14,
                          ),
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
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

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
              chain?.name ?? 'Loading...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final isStarted = progress != null;
    final progressPercent = isStarted
        ? progress.getProgressPercentage(chain.steps?.length ?? 1)
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
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
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetaBadge(
                Icons.category_rounded,
                chain.category,
                textSecondary,
                isDark,
              ),
              _buildMetaBadge(
                Icons.stairs_rounded,
                '${chain.steps?.length ?? "?"} steps',
                textSecondary,
                isDark,
              ),
              _buildMetaBadge(
                Icons.speed_rounded,
                'Lvl ${chain.difficultyStart}-${chain.difficultyEnd}',
                textSecondary,
                isDark,
              ),
              if (chain.estimatedWeeks != null)
                _buildMetaBadge(
                  Icons.schedule_rounded,
                  '~${chain.estimatedWeeks} weeks',
                  textSecondary,
                  isDark,
                ),
            ],
          ),

          // Progress section
          if (isStarted) ...[
            const SizedBox(height: 20),
            Divider(color: cardBorder),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Progress',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: cardBorder,
                          color: cyan,
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(progressPercent * 100).toInt()}%',
                    style: TextStyle(
                      color: cyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  size: 14,
                  color: textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${progress.attemptsAtCurrent} attempts at current step',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (progress.bestRepsAtCurrent > 0) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: AppColors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Best: ${progress.bestRepsAtCurrent} reps',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaBadge(
    IconData icon,
    String text,
    Color color,
    bool isDark,
  ) {
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
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
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final green = isDark ? AppColors.green : AppColorsLight.green;

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
                            : isUnlocked
                                ? cyan.withOpacity(0.2)
                                : cardBorder,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? green
                          : isCurrent
                              ? cyan
                              : cardBorder,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${step.stepOrder}',
                            style: TextStyle(
                              color: isCurrent || isCompleted
                                  ? Colors.white
                                  : isUnlocked
                                      ? cyan
                                      : isDark
                                          ? AppColors.textMuted
                                          : AppColorsLight.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                        color: isCompleted ? green : cardBorder,
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
        const SnackBar(
          content: Text('Progression started! Good luck!'),
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
    final backgroundColor =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: cyan,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.exerciseName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Step ${step.stepOrder} - ${step.difficultyLabel}',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
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
                    textSecondary,
                  ),
                  const SizedBox(height: 16),
                ],

                // Tips
                if (step.tips != null && step.tips!.isNotEmpty) ...[
                  _buildSection(
                    'Tips',
                    step.tips!,
                    Icons.lightbulb_outline_rounded,
                    AppColors.orange,
                    textSecondary,
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
                    AppColors.purple,
                    textSecondary,
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
                    ),
                    child: const Text('Close'),
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
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}
