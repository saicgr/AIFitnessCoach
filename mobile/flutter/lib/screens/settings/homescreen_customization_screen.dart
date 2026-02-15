import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';

/// Provider for homescreen card visibility settings
final homescreenCardsProvider =
    StateNotifierProvider<HomescreenCardsNotifier, HomescreenCardsState>((ref) {
  return HomescreenCardsNotifier();
});

/// State for homescreen card visibility
class HomescreenCardsState {
  final bool showFitnessScoreCard;
  final bool showMoodPickerCard;
  final bool showDailyActivityCard;
  final bool showQuickActionsRow;
  final bool showUpcomingFeaturesCard;
  final bool showWeekChangesCard;
  final bool showWeeklyProgressCard;
  final bool showWeeklyGoalsCard;
  final bool isLoading;

  const HomescreenCardsState({
    this.showFitnessScoreCard = true,
    this.showMoodPickerCard = true,
    this.showDailyActivityCard = true,
    this.showQuickActionsRow = true,
    this.showUpcomingFeaturesCard = true,
    this.showWeekChangesCard = true,
    this.showWeeklyProgressCard = true,
    this.showWeeklyGoalsCard = true,
    this.isLoading = true,
  });

  HomescreenCardsState copyWith({
    bool? showFitnessScoreCard,
    bool? showMoodPickerCard,
    bool? showDailyActivityCard,
    bool? showQuickActionsRow,
    bool? showUpcomingFeaturesCard,
    bool? showWeekChangesCard,
    bool? showWeeklyProgressCard,
    bool? showWeeklyGoalsCard,
    bool? isLoading,
  }) {
    return HomescreenCardsState(
      showFitnessScoreCard: showFitnessScoreCard ?? this.showFitnessScoreCard,
      showMoodPickerCard: showMoodPickerCard ?? this.showMoodPickerCard,
      showDailyActivityCard: showDailyActivityCard ?? this.showDailyActivityCard,
      showQuickActionsRow: showQuickActionsRow ?? this.showQuickActionsRow,
      showUpcomingFeaturesCard: showUpcomingFeaturesCard ?? this.showUpcomingFeaturesCard,
      showWeekChangesCard: showWeekChangesCard ?? this.showWeekChangesCard,
      showWeeklyProgressCard: showWeeklyProgressCard ?? this.showWeeklyProgressCard,
      showWeeklyGoalsCard: showWeeklyGoalsCard ?? this.showWeeklyGoalsCard,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for managing homescreen card visibility
class HomescreenCardsNotifier extends StateNotifier<HomescreenCardsState> {
  HomescreenCardsNotifier() : super(const HomescreenCardsState()) {
    _loadSettings();
  }

  static const _keyPrefix = 'homescreen_show_';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = HomescreenCardsState(
      showFitnessScoreCard: prefs.getBool('${_keyPrefix}fitness_score') ?? true,
      showMoodPickerCard: prefs.getBool('${_keyPrefix}mood_picker') ?? true,
      showDailyActivityCard: prefs.getBool('${_keyPrefix}daily_activity') ?? true,
      showQuickActionsRow: prefs.getBool('${_keyPrefix}quick_actions') ?? true,
      showUpcomingFeaturesCard: prefs.getBool('${_keyPrefix}upcoming_features') ?? true,
      showWeekChangesCard: prefs.getBool('${_keyPrefix}week_changes') ?? true,
      showWeeklyProgressCard: prefs.getBool('${_keyPrefix}weekly_progress') ?? true,
      showWeeklyGoalsCard: prefs.getBool('${_keyPrefix}weekly_goals') ?? true,
      isLoading: false,
    );
  }

  Future<void> setFitnessScoreCard(bool value) async {
    state = state.copyWith(showFitnessScoreCard: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}fitness_score', value);
  }

  Future<void> setMoodPickerCard(bool value) async {
    state = state.copyWith(showMoodPickerCard: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}mood_picker', value);
  }

  Future<void> setDailyActivityCard(bool value) async {
    state = state.copyWith(showDailyActivityCard: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}daily_activity', value);
  }

  Future<void> setQuickActionsRow(bool value) async {
    state = state.copyWith(showQuickActionsRow: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}quick_actions', value);
  }

  Future<void> setUpcomingFeaturesCard(bool value) async {
    state = state.copyWith(showUpcomingFeaturesCard: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}upcoming_features', value);
  }

  Future<void> setWeekChangesCard(bool value) async {
    state = state.copyWith(showWeekChangesCard: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}week_changes', value);
  }

  Future<void> setWeeklyProgressCard(bool value) async {
    state = state.copyWith(showWeeklyProgressCard: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}weekly_progress', value);
  }

  Future<void> setWeeklyGoalsCard(bool value) async {
    state = state.copyWith(showWeeklyGoalsCard: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}weekly_goals', value);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}fitness_score');
    await prefs.remove('${_keyPrefix}mood_picker');
    await prefs.remove('${_keyPrefix}daily_activity');
    await prefs.remove('${_keyPrefix}quick_actions');
    await prefs.remove('${_keyPrefix}upcoming_features');
    await prefs.remove('${_keyPrefix}week_changes');
    await prefs.remove('${_keyPrefix}weekly_progress');
    await prefs.remove('${_keyPrefix}weekly_goals');
    state = const HomescreenCardsState(isLoading: false);
  }
}

/// Screen to customize which cards appear on the home screen
class HomescreenCustomizationScreen extends ConsumerWidget {
  const HomescreenCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final cardsState = ref.watch(homescreenCardsProvider);
    final cardsNotifier = ref.read(homescreenCardsProvider.notifier);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          'Customize Home',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        actions: [
          TextButton(
            onPressed: () {
              HapticService.light();
              cardsNotifier.resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset to defaults'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Reset',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: cardsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section header
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Choose which cards to show on your home screen',
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                    ),
                  ),
                ),

                // TODAY Section
                _buildSectionHeader('TODAY SECTION', textMuted),
                const SizedBox(height: 8),

                _buildToggleCard(
                  context: context,
                  title: 'Fitness Score',
                  subtitle: 'Overall fitness, strength & nutrition scores',
                  icon: Icons.insights,
                  iconColor: AppColors.cyan,
                  value: cardsState.showFitnessScoreCard,
                  onChanged: (value) {
                    HapticService.light();
                    cardsNotifier.setFitnessScoreCard(value);
                  },
                  isDark: isDark,
                  elevatedColor: elevatedColor,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),

                _buildToggleCard(
                  context: context,
                  title: 'Mood Check-in',
                  subtitle: 'Quick mood picker for instant workouts',
                  icon: Icons.wb_sunny_outlined,
                  iconColor: AppColors.orange,
                  value: cardsState.showMoodPickerCard,
                  onChanged: (value) {
                    HapticService.light();
                    cardsNotifier.setMoodPickerCard(value);
                  },
                  isDark: isDark,
                  elevatedColor: elevatedColor,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),

                _buildToggleCard(
                  context: context,
                  title: 'Daily Activity',
                  subtitle: 'Health device activity summary',
                  icon: Icons.watch,
                  iconColor: AppColors.green,
                  value: cardsState.showDailyActivityCard,
                  onChanged: (value) {
                    HapticService.light();
                    cardsNotifier.setDailyActivityCard(value);
                  },
                  isDark: isDark,
                  elevatedColor: elevatedColor,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),

                _buildToggleCard(
                  context: context,
                  title: 'Quick Actions',
                  subtitle: 'Log Food, Stats, Share, Water buttons',
                  icon: Icons.apps,
                  iconColor: AppColors.purple,
                  value: cardsState.showQuickActionsRow,
                  onChanged: (value) {
                    HapticService.light();
                    cardsNotifier.setQuickActionsRow(value);
                  },
                  isDark: isDark,
                  elevatedColor: elevatedColor,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),

                _buildToggleCard(
                  context: context,
                  title: 'Upcoming Features',
                  subtitle: 'Feature voting and roadmap preview',
                  icon: Icons.new_releases_outlined,
                  iconColor: AppColors.yellow,
                  value: cardsState.showUpcomingFeaturesCard,
                  onChanged: (value) {
                    HapticService.light();
                    cardsNotifier.setUpcomingFeaturesCard(value);
                  },
                  isDark: isDark,
                  elevatedColor: elevatedColor,
                  textColor: textColor,
                  textMuted: textMuted,
                ),

                const SizedBox(height: 24),

                // YOUR WEEK Section
                _buildSectionHeader('YOUR WEEK SECTION', textMuted),
                const SizedBox(height: 8),

                _buildToggleCard(
                  context: context,
                  title: 'Week Changes',
                  subtitle: 'Exercise variation this week',
                  icon: Icons.swap_horiz,
                  iconColor: AppColors.cyan,
                  value: cardsState.showWeekChangesCard,
                  onChanged: (value) {
                    HapticService.light();
                    cardsNotifier.setWeekChangesCard(value);
                  },
                  isDark: isDark,
                  elevatedColor: elevatedColor,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),

                _buildToggleCard(
                  context: context,
                  title: 'Weekly Progress',
                  subtitle: 'Workout completion progress ring',
                  icon: Icons.donut_large,
                  iconColor: AppColors.green,
                  value: cardsState.showWeeklyProgressCard,
                  onChanged: (value) {
                    HapticService.light();
                    cardsNotifier.setWeeklyProgressCard(value);
                  },
                  isDark: isDark,
                  elevatedColor: elevatedColor,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 12),

                _buildToggleCard(
                  context: context,
                  title: 'Weekly Goals',
                  subtitle: 'Goals and milestones for the week',
                  icon: Icons.flag_outlined,
                  iconColor: AppColors.orange,
                  value: cardsState.showWeeklyGoalsCard,
                  onChanged: (value) {
                    HapticService.light();
                    cardsNotifier.setWeeklyGoalsCard(value);
                  },
                  isDark: isDark,
                  elevatedColor: elevatedColor,
                  textColor: textColor,
                  textMuted: textMuted,
                ),

                const SizedBox(height: 32),

                // Info text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: elevatedColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cyan.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.cyan,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Changes are saved automatically and apply immediately.',
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? iconColor.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: iconColor,
        ),
      ),
    );
  }
}
