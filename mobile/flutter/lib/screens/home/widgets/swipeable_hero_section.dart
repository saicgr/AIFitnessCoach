import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import 'hero_workout_card.dart';
import 'hero_nutrition_card.dart';
import 'hero_fasting_card.dart';
import 'compact_workout_row.dart';

/// Focus type for the home screen
enum HomeFocus { workout, nutrition, fasting }

/// Provider to persist the user's home focus preference
final homeFocusProvider = StateProvider<HomeFocus>((ref) => HomeFocus.workout);

/// Swipeable hero section allowing users to switch between workout, nutrition, and fasting focus
/// Each focus shows a hero card with the compact workout row below (if not workout focus)
class SwipeableHeroSection extends ConsumerStatefulWidget {
  final Workout? todayWorkout;
  final bool isGenerating;

  const SwipeableHeroSection({
    super.key,
    this.todayWorkout,
    this.isGenerating = false,
  });

  @override
  ConsumerState<SwipeableHeroSection> createState() => _SwipeableHeroSectionState();
}

class _SwipeableHeroSectionState extends ConsumerState<SwipeableHeroSection> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialFocus = ref.read(homeFocusProvider);
    _pageController = PageController(
      initialPage: initialFocus.index,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    ref.read(homeFocusProvider.notifier).state = HomeFocus.values[index];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentFocus = ref.watch(homeFocusProvider);

    return Column(
      children: [
        // Page indicator dots
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: HomeFocus.values.map((focus) {
              final isActive = focus == currentFocus;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    focus.index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: isActive
                        ? _getFocusColor(focus)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Focus labels
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: HomeFocus.values.map((focus) {
              final isActive = focus == currentFocus;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    focus.index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _getFocusLabel(focus),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive
                          ? _getFocusColor(focus)
                          : (isDark
                              ? AppColors.textMuted
                              : AppColorsLight.textMuted),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Swipeable hero cards
        SizedBox(
          height: _getHeroHeight(currentFocus),
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              // Workout focus
              _buildWorkoutHero(),

              // Nutrition focus
              _buildNutritionHero(),

              // Fasting focus
              _buildFastingHero(),
            ],
          ),
        ),

        // Compact workout row (when not in workout focus)
        if (currentFocus != HomeFocus.workout && widget.todayWorkout != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CompactWorkoutRow(workout: widget.todayWorkout!),
          ),
      ],
    );
  }

  Widget _buildWorkoutHero() {
    if (widget.isGenerating) {
      return const GeneratingHeroCard();
    }

    if (widget.todayWorkout != null) {
      return HeroWorkoutCard(workout: widget.todayWorkout!);
    }

    return _buildNoWorkoutCard();
  }

  Widget _buildNutritionHero() {
    return const HeroNutritionCard();
  }

  Widget _buildFastingHero() {
    return const HeroFastingCard();
  }

  Widget _buildNoWorkoutCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Motivational messages for rest day
    final messages = [
      'Recovery is progress!',
      'Rest days build strength',
      'Your muscles are growing',
      'Time to recharge',
      'Active recovery wins',
    ];
    // Use day of year for consistent daily message
    final messageIndex = DateTime.now().dayOfYear % messages.length;
    final message = messages[messageIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rest day icon with calming color
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.spa,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Rest Day',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),

              // Suggested activity
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_walk,
                      color: AppColors.cyan,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggested: 20-min walk',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Light movement aids recovery',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick action buttons
              Row(
                children: [
                  Expanded(
                    child: _RestDayActionButton(
                      icon: Icons.self_improvement,
                      label: 'Stretch',
                      color: AppColors.purple,
                      onTap: () => _showRestDayActivity(context, 'stretch'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RestDayActionButton(
                      icon: Icons.directions_run,
                      label: 'Light Cardio',
                      color: AppColors.orange,
                      onTap: () => _showRestDayActivity(context, 'cardio'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RestDayActionButton(
                      icon: Icons.spa,
                      label: 'Yoga',
                      color: AppColors.cyan,
                      onTap: () => _showRestDayActivity(context, 'yoga'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRestDayActivity(BuildContext context, String activity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Map<String, Map<String, dynamic>> activities = {
      'stretch': {
        'title': 'Quick Stretch Routine',
        'duration': '10-15 min',
        'items': [
          'Neck rolls - 30 sec each direction',
          'Shoulder shrugs - 15 reps',
          'Cat-cow stretches - 10 reps',
          'Hamstring stretch - 30 sec each leg',
          'Hip flexor stretch - 30 sec each side',
          'Child\'s pose - 1 min',
        ],
        'color': AppColors.purple,
      },
      'cardio': {
        'title': 'Light Cardio Options',
        'duration': '15-30 min',
        'items': [
          'Brisk walk around the block',
          'Easy bike ride',
          'Swimming at relaxed pace',
          'Light dancing',
          'Stair climbing (slow pace)',
        ],
        'color': AppColors.orange,
      },
      'yoga': {
        'title': 'Restorative Yoga Flow',
        'duration': '15-20 min',
        'items': [
          'Mountain pose - 1 min',
          'Forward fold - 1 min',
          'Downward dog - 1 min',
          'Warrior II - 30 sec each side',
          'Pigeon pose - 1 min each side',
          'Savasana - 3 min',
        ],
        'color': AppColors.cyan,
      },
    };

    final data = activities[activity]!;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (data['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activity == 'stretch'
                        ? Icons.self_improvement
                        : activity == 'cardio'
                            ? Icons.directions_run
                            : Icons.spa,
                    color: data['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                        ),
                      ),
                      Text(
                        data['duration'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...(data['items'] as List<String>).map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: data['color'] as Color,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getFocusColor(HomeFocus focus) {
    switch (focus) {
      case HomeFocus.workout:
        return AppColors.cyan;
      case HomeFocus.nutrition:
        return const Color(0xFF34C759);
      case HomeFocus.fasting:
        return AppColors.orange;
    }
  }

  String _getFocusLabel(HomeFocus focus) {
    switch (focus) {
      case HomeFocus.workout:
        return 'Workout';
      case HomeFocus.nutrition:
        return 'Nutrition';
      case HomeFocus.fasting:
        return 'Fasting';
    }
  }

  double _getHeroHeight(HomeFocus focus) {
    // Different hero cards have different heights
    switch (focus) {
      case HomeFocus.workout:
        return 340;
      case HomeFocus.nutrition:
        return 460;
      case HomeFocus.fasting:
        return 420;
    }
  }
}

/// Rest day action button widget
class _RestDayActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RestDayActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to get day of year from DateTime
extension DateTimeExtensions on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
}
