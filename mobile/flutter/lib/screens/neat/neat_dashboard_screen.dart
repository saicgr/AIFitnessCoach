import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/neat_provider.dart' as real_neat;
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/pill_app_bar.dart';

part 'neat_dashboard_screen_part_neat_score_card.dart';
part 'neat_dashboard_screen_part_streaks_card.dart';


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
      appBar: PillAppBar(
        title: 'Daily Activity',
        actions: [
          PillAppBarAction(icon: Icons.refresh, onTap: () {
            HapticService.light();
            _loadData();
          }),
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
