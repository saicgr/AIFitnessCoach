import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/neat_provider.dart' as real_neat;
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';

// ============================================
// NEAT Data Models
// ============================================

/// NEAT Score data model
class NeatScore {
  final int score; // 0-100
  final int steps;
  final int stepGoal;
  final int activeHours;
  final int activeHoursGoal;
  final List<HourlyActivity> hourlyActivity;
  final bool isProgressiveGoal;
  final String? aiTip;
  final DateTime date;

  const NeatScore({
    required this.score,
    required this.steps,
    required this.stepGoal,
    required this.activeHours,
    this.activeHoursGoal = 10,
    required this.hourlyActivity,
    this.isProgressiveGoal = false,
    this.aiTip,
    required this.date,
  });

  /// Get score color based on value
  Color get scoreColor {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.orange;
    return AppColors.error;
  }

  /// Progress towards step goal (0.0 - 1.0+)
  double get stepProgress => stepGoal > 0 ? steps / stepGoal : 0;

  /// Progress towards active hours goal (0.0 - 1.0+)
  double get activeHoursProgress =>
      activeHoursGoal > 0 ? activeHours / activeHoursGoal : 0;
}

/// Hourly activity data
class HourlyActivity {
  final int hour; // 0-23
  final int steps;
  final bool isActive; // 250+ steps = active

  const HourlyActivity({
    required this.hour,
    required this.steps,
  }) : isActive = steps >= 250;

  /// Check if this hour is sedentary
  bool get isSedentary => steps < 250 && steps > 0;
}

/// NEAT Streak data
class NeatStreak {
  final int currentStepStreak;
  final int currentActiveHoursStreak;
  final int currentNeatScoreStreak;
  final int longestStepStreak;
  final int longestActiveHoursStreak;
  final int longestNeatScoreStreak;

  const NeatStreak({
    this.currentStepStreak = 0,
    this.currentActiveHoursStreak = 0,
    this.currentNeatScoreStreak = 0,
    this.longestStepStreak = 0,
    this.longestActiveHoursStreak = 0,
    this.longestNeatScoreStreak = 0,
  });
}

/// NEAT Achievement
class NeatAchievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final double progress; // 0.0 - 1.0
  final DateTime? unlockedAt;
  final int points;

  const NeatAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedAt,
    this.points = 10,
  });
}

/// Movement reminder settings
class MovementReminderSettings {
  final bool isEnabled;
  final int intervalMinutes; // 30, 60, 90, 120
  final int stepsThreshold; // 100-500
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final bool workHoursOnly;

  const MovementReminderSettings({
    this.isEnabled = true,
    this.intervalMinutes = 60,
    this.stepsThreshold = 250,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
    this.workHoursOnly = false,
  });

  MovementReminderSettings copyWith({
    bool? isEnabled,
    int? intervalMinutes,
    int? stepsThreshold,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? workHoursOnly,
  }) {
    return MovementReminderSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      stepsThreshold: stepsThreshold ?? this.stepsThreshold,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      workHoursOnly: workHoursOnly ?? this.workHoursOnly,
    );
  }
}

// ============================================
// NEAT State & Provider
// ============================================

/// State for NEAT Dashboard
class NeatState {
  final NeatScore? score;
  final NeatStreak streaks;
  final List<NeatAchievement> achievements;
  final List<NeatAchievement> recentAchievements;
  final MovementReminderSettings reminderSettings;
  final bool isLoading;
  final bool isLoadingAchievements;
  final String? error;

  const NeatState({
    this.score,
    this.streaks = const NeatStreak(),
    this.achievements = const [],
    this.recentAchievements = const [],
    this.reminderSettings = const MovementReminderSettings(),
    this.isLoading = false,
    this.isLoadingAchievements = false,
    this.error,
  });

  NeatState copyWith({
    NeatScore? score,
    NeatStreak? streaks,
    List<NeatAchievement>? achievements,
    List<NeatAchievement>? recentAchievements,
    MovementReminderSettings? reminderSettings,
    bool? isLoading,
    bool? isLoadingAchievements,
    String? error,
    bool clearError = false,
  }) {
    return NeatState(
      score: score ?? this.score,
      streaks: streaks ?? this.streaks,
      achievements: achievements ?? this.achievements,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingAchievements:
          isLoadingAchievements ?? this.isLoadingAchievements,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// NEAT State Notifier - wired to real API providers
class NeatNotifier extends StateNotifier<NeatState> {
  final Ref _ref;

  NeatNotifier(this._ref) : super(const NeatState());

  /// Load NEAT data from the real API providers
  Future<void> loadNeatData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get user ID and trigger real API loading
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'Not logged in');
        return;
      }

      final realNotifier = _ref.read(real_neat.neatProvider.notifier);
      realNotifier.setUserId(userId);
      await realNotifier.loadDashboard();

      final realState = _ref.read(real_neat.neatProvider);
      final dashboard = realState.dashboard;
      final now = DateTime.now();

      // Map hourly activity from real provider
      List<HourlyActivity> hourlyActivity;
      if (dashboard?.hourlyBreakdown != null) {
        final breakdown = dashboard!.hourlyBreakdown!;
        hourlyActivity = List.generate(24, (hour) {
          final activity = breakdown.getHourActivity(hour);
          return HourlyActivity(
            hour: hour,
            steps: activity?.steps ?? 0,
          );
        });
      } else {
        // Default empty hours
        hourlyActivity = List.generate(24, (hour) {
          return HourlyActivity(hour: hour, steps: 0);
        });
      }

      // Calculate totals from hourly data
      final totalSteps = realState.currentSteps;
      final activeHours = hourlyActivity.where((h) => h.isActive).length;
      final stepGoal = realState.stepGoal;
      final neatScoreValue = realState.todayScoreValue;

      final score = NeatScore(
        score: neatScoreValue.clamp(0, 100),
        steps: totalSteps,
        stepGoal: stepGoal,
        activeHours: activeHours,
        activeHoursGoal: 10,
        hourlyActivity: hourlyActivity,
        isProgressiveGoal: dashboard?.stepGoal?.isProgressive ?? false,
        aiTip: dashboard?.suggestions.isNotEmpty == true ? dashboard!.suggestions.first : null,
        date: now,
      );

      // Map streaks from real provider
      final stepStreak = dashboard?.stepStreak;
      final allGoalsStreak = dashboard?.allGoalsStreak;
      final streaks = NeatStreak(
        currentStepStreak: stepStreak?.currentStreak ?? 0,
        currentActiveHoursStreak: 0, // No separate active hours streak in the real model
        currentNeatScoreStreak: allGoalsStreak?.currentStreak ?? 0,
        longestStepStreak: stepStreak?.longestStreak ?? 0,
        longestActiveHoursStreak: 0,
        longestNeatScoreStreak: allGoalsStreak?.longestStreak ?? 0,
      );

      state = state.copyWith(
        score: score,
        streaks: streaks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load NEAT data: $e',
      );
    }
  }

  /// Load achievements from real API
  Future<void> loadAchievements() async {
    state = state.copyWith(isLoadingAchievements: true);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      if (userId == null) {
        state = state.copyWith(isLoadingAchievements: false);
        return;
      }

      final realNotifier = _ref.read(real_neat.neatProvider.notifier);
      await realNotifier.loadAchievements(userId: userId);

      final realState = _ref.read(real_neat.neatProvider);
      final realAchievements = realState.achievements;

      // Map real achievements to local UI models
      final achievements = realAchievements.map((a) {
        return NeatAchievement(
          id: a.id,
          title: a.name,
          description: a.description,
          icon: a.iconName ?? a.name.substring(0, 2).toUpperCase(),
          isUnlocked: a.isEarned,
          progress: a.progressPercentage / 100.0,
          unlockedAt: a.earnedAtDate,
          points: a.points,
        );
      }).toList();

      final recentAchievements =
          achievements.where((a) => a.isUnlocked).take(2).toList();

      state = state.copyWith(
        achievements: achievements,
        recentAchievements: recentAchievements,
        isLoadingAchievements: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingAchievements: false);
    }
  }

  /// Update reminder settings
  void updateReminderSettings(MovementReminderSettings settings) {
    state = state.copyWith(reminderSettings: settings);
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadNeatData();
    await loadAchievements();
  }
}

/// NEAT Provider - wired to real API
final neatProvider = StateNotifierProvider<NeatNotifier, NeatState>((ref) {
  return NeatNotifier(ref);
});

// ============================================
// NEAT Dashboard Screen
// ============================================

/// Comprehensive NEAT Dashboard showing daily activity metrics
class NeatDashboardScreen extends ConsumerStatefulWidget {
  const NeatDashboardScreen({super.key});

  @override
  ConsumerState<NeatDashboardScreen> createState() =>
      _NeatDashboardScreenState();
}

class _NeatDashboardScreenState extends ConsumerState<NeatDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _scoreAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scoreAnimation = CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await ref.read(neatProvider.notifier).refresh();
    _scoreAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final neatState = ref.watch(neatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Daily Activity',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textMuted),
            onPressed: () {
              HapticService.light();
              _loadData();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.cyan,
        backgroundColor: elevatedColor,
        child: neatState.isLoading && neatState.score == null
            ? _buildLoadingState(textMuted)
            : neatState.error != null && neatState.score == null
                ? _buildErrorState(neatState.error!, textPrimary, textSecondary)
                : _buildContent(
                    context,
                    neatState,
                    isDark,
                    elevatedColor,
                    textPrimary,
                    textSecondary,
                    textMuted,
                    cardBorder,
                  ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.cyan),
          const SizedBox(height: 16),
          Text(
            'Loading activity data...',
            style: TextStyle(color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      String error, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NeatState neatState,
    bool isDark,
    Color elevatedColor,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color cardBorder,
  ) {
    final score = neatState.score!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // NEAT Score Header Card
          _NeatScoreCard(
            score: score,
            animation: _scoreAnimation,
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 16),

          // Step Goal Progress Card
          _StepGoalCard(
            steps: score.steps,
            goal: score.stepGoal,
            isProgressiveGoal: score.isProgressiveGoal,
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 16),

          // Hourly Activity Timeline
          _HourlyActivityCard(
            hourlyActivity: score.hourlyActivity,
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 16),

          // Active Hours Card
          _ActiveHoursCard(
            activeHours: score.activeHours,
            goal: score.activeHoursGoal,
            hourlyActivity: score.hourlyActivity,
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 16),

          // Streaks Section
          _StreaksCard(
            streaks: neatState.streaks,
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 16),

          // Achievements Section
          _AchievementsCard(
            achievements: neatState.achievements,
            recentAchievements: neatState.recentAchievements,
            isLoading: neatState.isLoadingAchievements,
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
            onSeeAll: () {
              // Navigate to achievements screen
              HapticService.light();
            },
          ),

          const SizedBox(height: 16),

          // Movement Reminder Settings
          _MovementReminderCard(
            settings: neatState.reminderSettings,
            onSettingsChanged: (settings) {
              ref.read(neatProvider.notifier).updateReminderSettings(settings);
            },
            isDark: isDark,
            elevatedColor: elevatedColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textMuted: textMuted,
            cardBorder: cardBorder,
          ),

          const SizedBox(height: 16),

          // AI Tips Card
          if (score.aiTip != null)
            _AiTipsCard(
              tip: score.aiTip!,
              isDark: isDark,
              elevatedColor: elevatedColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              cardBorder: cardBorder,
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ============================================
// NEAT Score Card Widget
// ============================================

class _NeatScoreCard extends StatelessWidget {
  final NeatScore score;
  final Animation<double> animation;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _NeatScoreCard({
    required this.score,
    required this.animation,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: score.scoreColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: score.scoreColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights,
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'NEAT Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: score.scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getScoreLabel(score.score),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: score.scoreColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Large Circular Score
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return _CircularScoreIndicator(
                score: (score.score * animation.value).round(),
                maxScore: 100,
                scoreColor: score.scoreColor,
                size: 140,
                strokeWidth: 12,
                textPrimary: textPrimary,
                textMuted: textMuted,
              );
            },
          ),

          const SizedBox(height: 20),

          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickStat(
                icon: Icons.directions_walk,
                value: _formatNumber(score.steps),
                label: 'Steps',
                color: AppColors.cyan,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              Container(
                height: 40,
                width: 1,
                color: cardBorder,
              ),
              _QuickStat(
                icon: Icons.schedule,
                value: '${score.activeHours}',
                label: 'Active Hours',
                color: AppColors.success,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
              Container(
                height: 40,
                width: 1,
                color: cardBorder,
              ),
              _QuickStat(
                icon: Icons.local_fire_department,
                value: '${((score.steps * 0.04).round())}',
                label: 'Calories',
                color: AppColors.orange,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'EXCELLENT';
    if (score >= 75) return 'GREAT';
    if (score >= 50) return 'GOOD';
    if (score >= 25) return 'FAIR';
    return 'LOW';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

// ============================================
// Circular Score Indicator
// ============================================

class _CircularScoreIndicator extends StatelessWidget {
  final int score;
  final int maxScore;
  final Color scoreColor;
  final double size;
  final double strokeWidth;
  final Color textPrimary;
  final Color textMuted;

  const _CircularScoreIndicator({
    required this.score,
    required this.maxScore,
    required this.scoreColor,
    required this.size,
    required this.strokeWidth,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final progress = score / maxScore;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(textMuted.withOpacity(0.2)),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(scoreColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Text(
                'of $maxScore',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// Quick Stat Widget
// ============================================

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

// ============================================
// Step Goal Card
// ============================================

class _StepGoalCard extends StatelessWidget {
  final int steps;
  final int goal;
  final bool isProgressiveGoal;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _StepGoalCard({
    required this.steps,
    required this.goal,
    required this.isProgressiveGoal,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).round();
    final isComplete = steps >= goal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.flag,
                color: isComplete ? AppColors.success : AppColors.cyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Step Goal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              if (isProgressiveGoal) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PROGRESSIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'COMPLETE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Steps display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatNumber(steps),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '/ ${_formatNumber(goal)} steps',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: textMuted.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                isComplete ? AppColors.success : AppColors.cyan,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Percentage and motivation
          Row(
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? AppColors.success : AppColors.cyan,
                ),
              ),
              const Spacer(),
              Text(
                _getMotivationalMessage(percentage),
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _getMotivationalMessage(int percentage) {
    if (percentage >= 100) return 'Goal achieved! Amazing!';
    if (percentage >= 75) return 'Almost there! Keep going!';
    if (percentage >= 50) return 'Halfway there!';
    if (percentage >= 25) return 'Great start!';
    return 'Let\'s get moving!';
  }
}

// ============================================
// Hourly Activity Card
// ============================================

class _HourlyActivityCard extends StatelessWidget {
  final List<HourlyActivity> hourlyActivity;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _HourlyActivityCard({
    required this.hourlyActivity,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final currentHour = DateTime.now().hour;
    final maxSteps = hourlyActivity.fold(
        1, (max, h) => h.steps > max ? h.steps : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: AppColors.purple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hourly Activity',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(
                    color: AppColors.success,
                    label: '250+',
                    textMuted: textMuted,
                  ),
                  const SizedBox(width: 12),
                  _LegendItem(
                    color: AppColors.error,
                    label: '<250',
                    textMuted: textMuted,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Horizontal scrollable bar chart
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: hourlyActivity.map((activity) {
                  final barHeight = maxSteps > 0
                      ? (activity.steps / maxSteps * 70).clamp(4.0, 70.0)
                      : 4.0;
                  final isCurrentHour = activity.hour == currentHour;
                  final isActive = activity.isActive;
                  final isSedentary = activity.isSedentary;

                  Color barColor;
                  if (activity.steps == 0) {
                    barColor = textMuted.withOpacity(0.3);
                  } else if (isActive) {
                    barColor = AppColors.success;
                  } else if (isSedentary) {
                    barColor = AppColors.error;
                  } else {
                    barColor = textMuted.withOpacity(0.5);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Current hour indicator
                        if (isCurrentHour)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cyan,
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(height: 10),

                        // Bar
                        Container(
                          width: 12,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(4),
                            border: isCurrentHour
                                ? Border.all(color: AppColors.cyan, width: 2)
                                : null,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Hour label
                        Text(
                          _formatHour(activity.hour),
                          style: TextStyle(
                            fontSize: 9,
                            color:
                                isCurrentHour ? AppColors.cyan : textMuted,
                            fontWeight: isCurrentHour
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12a';
    if (hour == 12) return '12p';
    if (hour < 12) return '${hour}a';
    return '${hour - 12}p';
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textMuted;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

// ============================================
// Active Hours Card
// ============================================

class _ActiveHoursCard extends StatelessWidget {
  final int activeHours;
  final int goal;
  final List<HourlyActivity> hourlyActivity;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _ActiveHoursCard({
    required this.activeHours,
    required this.goal,
    required this.hourlyActivity,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isGoalMet = activeHours >= goal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGoalMet
              ? AppColors.success.withOpacity(0.3)
              : cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Active Hours',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Goal: $goal+',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Large active hours display
          Row(
            children: [
              Text(
                '$activeHours',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: isGoalMet ? AppColors.success : textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Active Hours\nToday',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.3,
                ),
              ),
              const Spacer(),
              // Hour dots visualization
              SizedBox(
                width: 140,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(24, (hour) {
                    final activity = hourlyActivity.firstWhere(
                      (h) => h.hour == hour,
                      orElse: () => HourlyActivity(hour: hour, steps: 0),
                    );
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: activity.isActive
                            ? AppColors.success
                            : activity.steps > 0
                                ? textMuted.withOpacity(0.3)
                                : textMuted.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isGoalMet ? AppColors.success : AppColors.info)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isGoalMet ? Icons.check_circle : Icons.info_outline,
                  color: isGoalMet ? AppColors.success : AppColors.info,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isGoalMet
                        ? 'Great job! You\'ve met your active hours goal today.'
                        : 'Try to move at least 250 steps every hour for better health.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
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
}

// ============================================
// Streaks Card
// ============================================

class _StreaksCard extends StatelessWidget {
  final NeatStreak streaks;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _StreaksCard({
    required this.streaks,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Streaks',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current streaks row
          Row(
            children: [
              Expanded(
                child: _StreakItem(
                  icon: Icons.directions_walk,
                  label: 'Steps',
                  current: streaks.currentStepStreak,
                  longest: streaks.longestStepStreak,
                  color: AppColors.cyan,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Container(
                height: 60,
                width: 1,
                color: cardBorder,
              ),
              Expanded(
                child: _StreakItem(
                  icon: Icons.schedule,
                  label: 'Active',
                  current: streaks.currentActiveHoursStreak,
                  longest: streaks.longestActiveHoursStreak,
                  color: AppColors.success,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
              Container(
                height: 60,
                width: 1,
                color: cardBorder,
              ),
              Expanded(
                child: _StreakItem(
                  icon: Icons.insights,
                  label: 'NEAT',
                  current: streaks.currentNeatScoreStreak,
                  longest: streaks.longestNeatScoreStreak,
                  color: AppColors.purple,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Longest streak highlight
          if (streaks.longestNeatScoreStreak > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.orange.withOpacity(0.15),
                    AppColors.purple.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: AppColors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Longest NEAT Streak',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          '${streaks.longestNeatScoreStreak} days',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
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

class _StreakItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int current;
  final int longest;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _StreakItem({
    required this.icon,
    required this.label,
    required this.current,
    required this.longest,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department,
              color: current > 0 ? AppColors.orange : textMuted,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$current',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: current > 0 ? textPrimary : textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================
// Achievements Card
// ============================================

class _AchievementsCard extends StatelessWidget {
  final List<NeatAchievement> achievements;
  final List<NeatAchievement> recentAchievements;
  final bool isLoading;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;
  final VoidCallback onSeeAll;

  const _AchievementsCard({
    required this.achievements,
    required this.recentAchievements,
    required this.isLoading,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    // Get next achievements (not yet unlocked, sorted by progress)
    final nextAchievements = achievements
        .where((a) => !a.isUnlocked)
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppColors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            ],
          ),

          if (isLoading) ...[
            const SizedBox(height: 20),
            Center(
              child: CircularProgressIndicator(
                color: AppColors.orange,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Recent achievements
            if (recentAchievements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recent',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...recentAchievements.map((achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AchievementItem(
                      achievement: achievement,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                    ),
                  )),
            ],

            // Next achievements
            if (nextAchievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Up Next',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 8),
              ...nextAchievements.take(2).map((achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _AchievementProgressItem(
                      achievement: achievement,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      textMuted: textMuted,
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }
}

class _AchievementItem extends StatelessWidget {
  final NeatAchievement achievement;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _AchievementItem({
    required this.achievement,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                color: AppColors.success,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                '+${achievement.points}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AchievementProgressItem extends StatelessWidget {
  final NeatAchievement achievement;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const _AchievementProgressItem({
    required this.achievement,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: textMuted.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: achievement.progress,
                  minHeight: 6,
                  backgroundColor: textMuted.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(AppColors.cyan),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(achievement.progress * 100).round()}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.cyan,
          ),
        ),
      ],
    );
  }
}

// ============================================
// Movement Reminder Card
// ============================================

class _MovementReminderCard extends StatelessWidget {
  final MovementReminderSettings settings;
  final Function(MovementReminderSettings) onSettingsChanged;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;

  const _MovementReminderCard({
    required this.settings,
    required this.onSettingsChanged,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: settings.isEnabled ? AppColors.cyan : textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Movement Reminders',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              Switch(
                value: settings.isEnabled,
                onChanged: (value) {
                  HapticService.light();
                  onSettingsChanged(settings.copyWith(isEnabled: value));
                },
                activeThumbColor: AppColors.cyan,
              ),
            ],
          ),

          if (settings.isEnabled) ...[
            const SizedBox(height: 16),

            // Interval selector
            Text(
              'Remind every',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [30, 60, 90, 120].map((minutes) {
                  final isSelected = settings.intervalMinutes == minutes;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${minutes}min'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          HapticService.light();
                          onSettingsChanged(
                            settings.copyWith(intervalMinutes: minutes),
                          );
                        }
                      },
                      selectedColor: AppColors.cyan.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.cyan : textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Steps threshold slider
            Row(
              children: [
                Text(
                  'If below',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${settings.stepsThreshold} steps',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
            Slider(
              value: settings.stepsThreshold.toDouble(),
              min: 100,
              max: 500,
              divisions: 8,
              activeColor: AppColors.cyan,
              inactiveColor: textMuted.withOpacity(0.3),
              onChanged: (value) {
                onSettingsChanged(
                  settings.copyWith(stepsThreshold: value.round()),
                );
              },
            ),

            const SizedBox(height: 8),

            // Work hours only toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Work hours only (9am - 5pm)',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ),
                Switch(
                  value: settings.workHoursOnly,
                  onChanged: (value) {
                    HapticService.light();
                    onSettingsChanged(settings.copyWith(workHoursOnly: value));
                  },
                  activeThumbColor: AppColors.cyan,
                ),
              ],
            ),

            // Quiet hours
            if (!settings.workHoursOnly)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Quiet hours: ${_formatTime(settings.quietHoursStart)} - ${_formatTime(settings.quietHoursEnd)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showQuietHoursPicker(context),
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _showQuietHoursPicker(BuildContext context) {
    // TODO: Implement time range picker
    HapticService.light();
  }
}

// ============================================
// AI Tips Card
// ============================================

class _AiTipsCard extends StatelessWidget {
  final String tip;
  final bool isDark;
  final Color elevatedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBorder;

  const _AiTipsCard({
    required this.tip,
    required this.isDark,
    required this.elevatedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withOpacity(0.15),
            AppColors.cyan.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Coach Tip',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              color: textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
