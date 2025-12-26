import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/api_client.dart';
import '../../data/services/personal_goals_service.dart';
import '../../data/providers/goal_suggestions_provider.dart';
import 'widgets/goal_card.dart';
import 'widgets/suggestion_carousel.dart';
import 'widgets/suggestion_card.dart';
import 'widgets/goal_leaderboard_sheet.dart';
import 'create_goal_sheet.dart';
import 'record_attempt_dialog.dart';

/// Main screen for viewing and managing personal weekly goals
class PersonalGoalsScreen extends ConsumerStatefulWidget {
  const PersonalGoalsScreen({super.key});

  @override
  ConsumerState<PersonalGoalsScreen> createState() => _PersonalGoalsScreenState();
}

class _PersonalGoalsScreenState extends ConsumerState<PersonalGoalsScreen> {
  late PersonalGoalsService _goalsService;
  String? _userId;

  Map<String, dynamic>? _goalsData;
  Map<String, dynamic>? _recordsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final apiClient = ref.read(apiClientProvider);
    _goalsService = PersonalGoalsService(apiClient);
    _userId = await apiClient.getUserId();

    if (_userId != null) {
      _loadData();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'User not logged in';
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final goals = await _goalsService.getCurrentGoals(userId: _userId!);
      final records = await _goalsService.getPersonalRecords(userId: _userId!);

      if (mounted) {
        setState(() {
          _goalsData = goals;
          _recordsData = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _showCreateGoalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateGoalSheet(
        onSubmit: (exerciseName, goalType, targetValue) async {
          await _goalsService.createGoal(
            userId: _userId!,
            exerciseName: exerciseName,
            goalType: goalType,
            targetValue: targetValue,
          );
          _loadData();
        },
      ),
    );
  }

  void _showRecordAttemptDialog(Map<String, dynamic> goal) {
    final goalType = PersonalGoalType.fromString(goal['goal_type'] ?? 'single_max');
    final isMaxAttempt = goalType == PersonalGoalType.singleMax;

    showDialog(
      context: context,
      builder: (context) => RecordAttemptDialog(
        exerciseName: goal['exercise_name'] ?? 'Exercise',
        isMaxAttempt: isMaxAttempt,
        currentValue: goal['current_value'] ?? 0,
        personalBest: goal['personal_best'],
        onSubmit: (value, notes) async {
          if (isMaxAttempt) {
            await _goalsService.recordAttempt(
              userId: _userId!,
              goalId: goal['id'],
              attemptValue: value,
              attemptNotes: notes,
            );
          } else {
            await _goalsService.addVolume(
              userId: _userId!,
              goalId: goal['id'],
              volumeToAdd: value,
            );
          }
          _loadData();
        },
      ),
    );
  }

  void _showSuggestionDetail(GoalSuggestionItem suggestion) {
    // Determine accent color based on category
    Color accentColor;
    switch (suggestion.category) {
      case SuggestionCategory.beatYourRecords:
        accentColor = AppColors.orange;
        break;
      case SuggestionCategory.popularWithFriends:
        accentColor = AppColors.purple;
        break;
      case SuggestionCategory.newChallenges:
        accentColor = AppColors.cyan;
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpandedSuggestionCard(
        suggestion: suggestion,
        accentColor: accentColor,
        onAccept: () {
          Navigator.pop(context);
          _acceptSuggestion(suggestion);
        },
        onDismiss: () {
          Navigator.pop(context);
          _dismissSuggestion(suggestion);
        },
      ),
    );
  }

  Future<void> _acceptSuggestion(GoalSuggestionItem suggestion) async {
    try {
      await _goalsService.acceptSuggestion(
        userId: _userId!,
        suggestionId: suggestion.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal created: ${suggestion.exerciseName}'),
            backgroundColor: AppColors.green,
          ),
        );
        // Refresh data and invalidate suggestions
        _loadData();
        ref.invalidate(goalSuggestionsProvider(
          GoalSuggestionsParams(userId: _userId!, forceRefresh: true),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create goal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _dismissSuggestion(GoalSuggestionItem suggestion) async {
    try {
      await _goalsService.dismissSuggestion(
        userId: _userId!,
        suggestionId: suggestion.id,
      );

      if (mounted) {
        // Invalidate suggestions to remove dismissed one
        ref.invalidate(goalSuggestionsProvider(
          GoalSuggestionsParams(userId: _userId!, forceRefresh: true),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to dismiss suggestion: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLeaderboardSheet(Map<String, dynamic> goal) {
    final goalType = PersonalGoalType.fromString(goal['goal_type'] ?? 'single_max');

    showGoalLeaderboardSheet(
      context,
      userId: _userId!,
      goalId: goal['id'],
      exerciseName: goal['exercise_name'] ?? 'Exercise',
      goalType: goalType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Weekly Goals'),
        backgroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(textPrimary, textSecondary),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGoalSheet,
        backgroundColor: AppColors.cyan,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textPrimary
                  : AppColorsLight.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondary
                  : AppColorsLight.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color textPrimary, Color textSecondary) {
    final goals = (_goalsData?['goals'] as List?) ?? [];
    final records = (_recordsData?['records'] as List?) ?? [];
    final prsThisWeek = _goalsData?['total_prs_this_week'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI-powered suggestion carousel
            if (_userId != null)
              SuggestionCarousel(
                userId: _userId!,
                onSuggestionTap: _showSuggestionDetail,
                onAccept: _acceptSuggestion,
                onDismiss: _dismissSuggestion,
              ),

            // Summary stats
            if (goals.isNotEmpty || prsThisWeek > 0) ...[
              _buildSummaryCard(goals.length, prsThisWeek),
              const SizedBox(height: 24),
            ],

            // Current goals section
            Row(
              children: [
                Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                if (goals.isNotEmpty)
                  Text(
                    '${goals.length} ${goals.length == 1 ? 'goal' : 'goals'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (goals.isEmpty)
              _buildEmptyGoalsState()
            else
              ...goals.map((goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GoalCard(
                      goal: goal,
                      onRecordAttempt: () => _showRecordAttemptDialog(goal),
                      onAddVolume: () => _showRecordAttemptDialog(goal),
                      friendsCount: goal['friends_count'] ?? 0,
                      onFriendsTap: (goal['friends_count'] ?? 0) > 0
                          ? () => _showLeaderboardSheet(goal)
                          : null,
                    ),
                  )),

            const SizedBox(height: 24),

            // Personal records section
            if (records.isNotEmpty) ...[
              Text(
                'Personal Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...records.take(5).map((record) => _buildRecordTile(record)),
              if (records.length > 5)
                TextButton(
                  onPressed: () {
                    // TODO: Show all records screen
                  },
                  child: Text('View all ${records.length} records'),
                ),
            ],

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int activeGoals, int prsThisWeek) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cyan.withValues(alpha: 0.15),
            AppColors.purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.flag,
            value: '$activeGoals',
            label: 'Active Goals',
            color: AppColors.cyan,
          ),
          Container(
            width: 1,
            height: 40,
            color: textMuted.withValues(alpha: 0.3),
          ),
          _buildSummaryItem(
            icon: Icons.emoji_events,
            value: '$prsThisWeek',
            label: 'New PRs',
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyGoalsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No goals this week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set a weekly challenge to push your limits!',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreateGoalSheet,
            icon: const Icon(Icons.add),
            label: const Text('Set Your First Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(Map<String, dynamic> record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final exerciseName = record['exercise_name'] ?? 'Exercise';
    final goalType = PersonalGoalType.fromString(record['goal_type'] ?? 'single_max');
    final recordValue = record['record_value'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emoji_events,
              color: AppColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Text(
                  goalType == PersonalGoalType.singleMax ? 'Max Reps' : 'Weekly Volume',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$recordValue',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.orange,
            ),
          ),
          Text(
            ' reps',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
