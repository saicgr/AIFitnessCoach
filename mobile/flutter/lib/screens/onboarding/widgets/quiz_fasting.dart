import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'scroll_hint_arrow.dart';

/// Fasting interest question for the pre-auth quiz.
/// Shows yes/no selection and optional protocol picker if interested.
/// Includes recommendations based on user's fitness level and goals.
/// Also collects sleep schedule for optimal fasting window suggestions.
class QuizFasting extends StatefulWidget {
  final bool? interestedInFasting;
  final String? selectedProtocol;
  final ValueChanged<bool> onInterestChanged;
  final ValueChanged<String?> onProtocolChanged;

  // Data from previous quiz steps for recommendations
  final String? fitnessLevel;  // beginner, intermediate, advanced
  final String? weightDirection;  // lose, gain, maintain
  final String? activityLevel;  // sedentary, lightly_active, moderately_active, very_active

  // Sleep schedule
  final TimeOfDay? wakeTime;
  final TimeOfDay? sleepTime;
  final ValueChanged<TimeOfDay>? onWakeTimeChanged;
  final ValueChanged<TimeOfDay>? onSleepTimeChanged;

  // Meals per day (for validation and distribution display)
  final int? mealsPerDay;
  final ValueChanged<int>? onMealsPerDayChanged;

  const QuizFasting({
    super.key,
    required this.interestedInFasting,
    required this.selectedProtocol,
    required this.onInterestChanged,
    required this.onProtocolChanged,
    this.fitnessLevel,
    this.weightDirection,
    this.activityLevel,
    this.wakeTime,
    this.sleepTime,
    this.onWakeTimeChanged,
    this.onSleepTimeChanged,
    this.mealsPerDay,
    this.onMealsPerDayChanged,
  });

  @override
  State<QuizFasting> createState() => _QuizFastingState();
}

class _QuizFastingState extends State<QuizFasting> {
  // Custom protocol values
  int _customFastingHours = 16;
  int _customEatingHours = 8;
  bool _showCustomInput = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// All available fasting protocols
  static List<Map<String, dynamic>> get allFastingProtocols => [
    {
      'id': '12:12',
      'label': '12:12',
      'description': 'Fast 12 hours, eat within 12 hours',
      'fastingHours': 12,
      'eatingHours': 12,
      'icon': Icons.wb_sunny_outlined,
      'color': AppColors.success,
      'difficulty': 'Beginner',
      'bestFor': ['beginners', 'maintain'],
    },
    {
      'id': '14:10',
      'label': '14:10',
      'description': 'Fast 14 hours, eat within 10 hours',
      'fastingHours': 14,
      'eatingHours': 10,
      'icon': Icons.access_time,
      'color': AppColors.teal,
      'difficulty': 'Beginner',
      'bestFor': ['beginners', 'maintain', 'lose'],
    },
    {
      'id': '16:8',
      'label': '16:8',
      'description': 'Fast 16 hours, eat within 8 hours',
      'fastingHours': 16,
      'eatingHours': 8,
      'icon': Icons.schedule,
      'color': AppColors.accent,
      'difficulty': 'Intermediate',
      'bestFor': ['intermediate', 'lose', 'maintain'],
      'popular': true,
    },
    {
      'id': '18:6',
      'label': '18:6',
      'description': 'Fast 18 hours, eat within 6 hours',
      'fastingHours': 18,
      'eatingHours': 6,
      'icon': Icons.timer,
      'color': AppColors.accent,
      'difficulty': 'Intermediate',
      'bestFor': ['intermediate', 'advanced', 'lose'],
    },
    {
      'id': '20:4',
      'label': '20:4',
      'description': 'Fast 20 hours, eat within 4 hours',
      'fastingHours': 20,
      'eatingHours': 4,
      'icon': Icons.hourglass_top,
      'color': AppColors.accent,
      'difficulty': 'Advanced',
      'bestFor': ['advanced', 'lose'],
    },
    {
      'id': 'omad',
      'label': 'OMAD',
      'description': 'One Meal A Day - 23:1 fasting',
      'fastingHours': 23,
      'eatingHours': 1,
      'icon': Icons.restaurant,
      'color': AppColors.error,
      'difficulty': 'Advanced',
      'bestFor': ['advanced', 'lose'],
      'warning': 'Requires careful meal planning',
    },
    {
      'id': '5:2',
      'label': '5:2',
      'description': 'Eat normally 5 days, fast 2 days/week',
      'fastingHours': 24,
      'eatingHours': 0,
      'icon': Icons.calendar_view_week,
      'color': AppColors.pink,
      'difficulty': 'Intermediate',
      'bestFor': ['intermediate', 'lose'],
      'isModified': true,
    },
    {
      'id': 'custom',
      'label': 'Custom',
      'description': 'Set your own fasting window',
      'fastingHours': 0,
      'eatingHours': 0,
      'icon': Icons.tune,
      'color': AppColors.textMuted,
      'difficulty': 'Varies',
      'bestFor': [],
    },
  ];

  /// Get recommended protocol based on user data
  String? _getRecommendedProtocol() {
    final fitness = widget.fitnessLevel?.toLowerCase() ?? 'beginner';
    final direction = widget.weightDirection?.toLowerCase() ?? 'maintain';

    // Beginners
    if (fitness == 'beginner') {
      if (direction == 'lose') return '14:10';
      return '12:12';
    }

    // Intermediate
    if (fitness == 'intermediate') {
      if (direction == 'lose') return '16:8';
      if (direction == 'gain') return '14:10';
      return '16:8';
    }

    // Advanced
    if (fitness == 'advanced') {
      if (direction == 'lose') return '18:6';
      if (direction == 'gain') return '16:8';
      return '16:8';
    }

    // Default
    return '16:8';
  }

  /// Get recommendation reason text
  String _getRecommendationReason() {
    final fitness = widget.fitnessLevel?.toLowerCase() ?? 'beginner';
    final direction = widget.weightDirection?.toLowerCase() ?? 'maintain';

    if (fitness == 'beginner') {
      return 'Great for starting out - easy to maintain';
    }
    if (direction == 'lose') {
      return 'Optimized for fat loss goals';
    }
    if (direction == 'gain') {
      return 'Allows enough eating time for muscle building';
    }
    return 'Balanced approach for your fitness level';
  }

  /// Get personalized benefit message based on user's goals
  String _getBenefitMessage() {
    final direction = widget.weightDirection?.toLowerCase() ?? 'maintain';

    if (direction == 'lose') {
      return 'Studies show intermittent fasting can boost fat burning by up to 14% and help preserve muscle mass while losing weight.';
    }
    if (direction == 'gain') {
      return 'Fasting can increase human growth hormone levels by up to 5x, helping you build lean muscle more efficiently.';
    }
    return 'Intermittent fasting improves insulin sensitivity, mental clarity, and can help maintain a healthy metabolism.';
  }

  /// Get max meals allowed based on eating window hours
  /// Rule: Need at least 2 hours between meals for digestion
  int _getMaxMealsForProtocol(String? protocolId) {
    if (protocolId == null) return 6;

    int eatingHours = 8; // default

    if (protocolId.startsWith('custom:')) {
      final parts = protocolId.split(':');
      if (parts.length >= 3) {
        eatingHours = int.tryParse(parts[2]) ?? 8;
      }
    } else {
      final protocol = allFastingProtocols.firstWhere(
        (p) => p['id'] == protocolId,
        orElse: () => {'eatingHours': 8},
      );
      eatingHours = protocol['eatingHours'] as int;
    }

    // OMAD (1 hour eating window) = 1 meal
    // 4 hour window = max 2 meals (2 hours apart)
    // 6 hour window = max 3 meals
    // 8 hour window = max 4 meals
    // 10+ hour window = max 5-6 meals
    if (eatingHours <= 1) return 1;
    if (eatingHours <= 4) return 2;
    if (eatingHours <= 6) return 3;
    if (eatingHours <= 8) return 4;
    if (eatingHours <= 10) return 5;
    return 6;
  }

  /// Get eating window hours for a protocol
  int _getEatingHours(String? protocolId) {
    if (protocolId == null) return 24;

    if (protocolId.startsWith('custom:')) {
      final parts = protocolId.split(':');
      if (parts.length >= 3) {
        return int.tryParse(parts[2]) ?? 8;
      }
    }

    final protocol = allFastingProtocols.firstWhere(
      (p) => p['id'] == protocolId,
      orElse: () => {'eatingHours': 24},
    );
    return protocol['eatingHours'] as int;
  }

  /// Get benefit chips based on user's goals
  List<Widget> _getBenefitChips(bool isDark, Color textSecondary) {
    final direction = widget.weightDirection?.toLowerCase() ?? 'maintain';

    List<Map<String, dynamic>> benefits;

    if (direction == 'lose') {
      benefits = [
        {'icon': Icons.local_fire_department, 'text': 'Burns fat', 'color': AppColors.accent},
        {'icon': Icons.trending_down, 'text': 'Reduces cravings', 'color': AppColors.accent},
        {'icon': Icons.bolt, 'text': 'Boosts energy', 'color': AppColors.accent},
      ];
    } else if (direction == 'gain') {
      benefits = [
        {'icon': Icons.fitness_center, 'text': 'Builds muscle', 'color': AppColors.accent},
        {'icon': Icons.trending_up, 'text': 'Growth hormone', 'color': AppColors.success},
        {'icon': Icons.restaurant, 'text': 'Better digestion', 'color': AppColors.teal},
      ];
    } else {
      benefits = [
        {'icon': Icons.psychology, 'text': 'Mental clarity', 'color': AppColors.accent},
        {'icon': Icons.favorite, 'text': 'Heart health', 'color': AppColors.accent},
        {'icon': Icons.schedule, 'text': 'Simple routine', 'color': AppColors.accent},
      ];
    }

    return benefits.map((b) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (b['color'] as Color).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(b['icon'] as IconData, size: 12, color: b['color'] as Color),
          const SizedBox(width: 4),
          Text(
            b['text'] as String,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: b['color'] as Color,
            ),
          ),
        ],
      ),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final recommendedId = _getRecommendedProtocol();

    // Get personalized benefit message based on user's goal
    final benefitMessage = _getBenefitMessage();

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Intermittent fasting can help you reach your goals faster',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  height: 1.3,
                ),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
              const SizedBox(height: 12),

              // Benefits container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefitMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _getBenefitChips(isDark, textSecondary),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // Yes/No selection (compact)
              Row(
                children: [
                  Expanded(
                    child: _buildCompactChoiceButton(
                      label: "Yes, let's try it",
                      icon: Icons.rocket_launch_outlined,
                      isSelected: widget.interestedInFasting == true,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onInterestChanged(true);
                      },
                      isDark: isDark,
                      textPrimary: textPrimary,
                      cardBorder: cardBorder,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactChoiceButton(
                      label: 'Maybe later',
                      icon: Icons.schedule_outlined,
                      isSelected: widget.interestedInFasting == false,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.onInterestChanged(false);
                        widget.onProtocolChanged(null);
                      },
                      isDark: isDark,
                      textPrimary: textPrimary,
                      cardBorder: cardBorder,
                    ),
                  ),
                ],
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

              // Protocol selection (only if interested)
              if (widget.interestedInFasting == true) ...[
                const SizedBox(height: 20),
                Text(
                  'Choose a fasting protocol',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 2),
                Text(
                  'Optional - you can set this later',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 10),

                // Protocol list (inline, not in ListView)
                ...allFastingProtocols.asMap().entries.map((entry) {
                  final index = entry.key;
                  final protocol = entry.value;
                  final id = protocol['id'] as String;
                  final isSelected = widget.selectedProtocol == id ||
                      (id == 'custom' && widget.selectedProtocol?.startsWith('custom:') == true);
                  final isRecommended = id == recommendedId;
                  final color = protocol['color'] as Color;
                  final isCustom = id == 'custom';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (isCustom) {
                              setState(() => _showCustomInput = !_showCustomInput);
                              if (!_showCustomInput) {
                                widget.onProtocolChanged(isSelected ? null : 'custom:$_customFastingHours:$_customEatingHours');
                              }
                            } else {
                              // Toggle off if already selected
                              widget.onProtocolChanged(isSelected ? null : id);
                              setState(() => _showCustomInput = false);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppColors.accentGradient : null,
                              color: isSelected
                                  ? null
                                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRecommended && !isSelected
                                    ? AppColors.success
                                    : (isSelected ? AppColors.accent : cardBorder),
                                width: isSelected || isRecommended ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    protocol['icon'] as IconData,
                                    color: isSelected ? Colors.white : color,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            protocol['label'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? Colors.white : textPrimary,
                                            ),
                                          ),
                                          if (isRecommended) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.white.withValues(alpha: 0.2)
                                                    : AppColors.success.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Recommended',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected ? Colors.white : AppColors.success,
                                                ),
                                              ),
                                            ),
                                          ],
                                          if (protocol['popular'] == true && !isRecommended) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? Colors.white.withValues(alpha: 0.2)
                                                    : AppColors.accent.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Popular',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isSelected ? Colors.white : AppColors.accent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        protocol['description'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isSelected ? Colors.white70 : textSecondary,
                                        ),
                                      ),
                                      if (isRecommended && !isSelected) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _getRecommendationReason(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                      if (protocol['warning'] != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 12,
                                              color: isSelected ? Colors.white70 : AppColors.warning,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              protocol['warning'] as String,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isSelected ? Colors.white70 : AppColors.warning,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? null
                                        : Border.all(color: cardBorder, width: 1.5),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: (200 + index * 60).ms).fadeIn().slideX(begin: 0.05),

                        // Custom protocol input
                        if (isCustom && _showCustomInput) ...[
                          const SizedBox(height: 8),
                          _buildCustomProtocolInput(isDark, textPrimary, textSecondary, cardBorder),
                        ],
                      ],
                    ),
                  );
                }),

                // Meal distribution info (show when protocol selected and meals are set)
                if (widget.selectedProtocol != null && widget.mealsPerDay != null)
                  _buildMealDistributionInfo(isDark, textPrimary, textSecondary, cardBorder),

                // Sleep schedule section
                if (widget.onWakeTimeChanged != null)
                  _buildSleepScheduleSection(isDark, textPrimary, textSecondary, cardBorder),
              ],

              const SizedBox(height: 60), // Bottom padding for scroll hint
            ],
          ),
        ),
        ScrollHintArrow(scrollController: _scrollController),
      ],
    );
  }

  Widget _buildCompactChoiceButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color cardBorder,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.accentGradient : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.accent,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealDistributionInfo(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBorder,
  ) {
    final meals = widget.mealsPerDay ?? 3;
    final eatingHours = _getEatingHours(widget.selectedProtocol);
    final maxMeals = _getMaxMealsForProtocol(widget.selectedProtocol);
    final isValid = meals <= maxMeals;

    // Calculate time between meals
    final hoursBetweenMeals = meals > 1 ? (eatingHours / (meals - 1)).toStringAsFixed(1) : eatingHours.toString();

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isValid
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isValid
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.restaurant_menu : Icons.warning_amber_rounded,
                  color: isValid ? AppColors.accent : AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isValid
                        ? 'Meal schedule in ${eatingHours}h window'
                        : 'Too many meals for this window',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isValid ? AppColors.accent : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isValid) ...[
              Text(
                '$meals meals spaced ~$hoursBetweenMeals hours apart',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              if (eatingHours <= 4) ...[
                const SizedBox(height: 4),
                Text(
                  'Tip: Consider larger, nutrient-dense meals',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ] else ...[
              Text(
                'A ${eatingHours}h eating window fits max $maxMeals meals.',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onMealsPerDayChanged?.call(maxMeals);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_high, size: 14, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Adjust to $maxMeals meals',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildCustomProtocolInput(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBorder,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set your custom fasting window',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Fasting hours
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fasting hours',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildIncrementButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (_customFastingHours > 1) {
                              setState(() => _customFastingHours--);
                              _updateCustomProtocol();
                            }
                          },
                          isDark: isDark,
                          cardBorder: cardBorder,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$_customFastingHours h',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                        _buildIncrementButton(
                          icon: Icons.add,
                          onTap: () {
                            if (_customFastingHours < 23) {
                              setState(() => _customFastingHours++);
                              _updateCustomProtocol();
                            }
                          },
                          isDark: isDark,
                          cardBorder: cardBorder,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eating hours',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildIncrementButton(
                          icon: Icons.remove,
                          onTap: () {
                            if (_customEatingHours > 1) {
                              setState(() => _customEatingHours--);
                              _updateCustomProtocol();
                            }
                          },
                          isDark: isDark,
                          cardBorder: cardBorder,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$_customEatingHours h',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ),
                        _buildIncrementButton(
                          icon: Icons.add,
                          onTap: () {
                            if (_customEatingHours < 23) {
                              setState(() => _customEatingHours++);
                              _updateCustomProtocol();
                            }
                          },
                          isDark: isDark,
                          cardBorder: cardBorder,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Total hours indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_customFastingHours + _customEatingHours == 24)
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  (_customFastingHours + _customEatingHours == 24)
                      ? Icons.check_circle
                      : Icons.info_outline,
                  size: 16,
                  color: (_customFastingHours + _customEatingHours == 24)
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (_customFastingHours + _customEatingHours == 24)
                        ? 'Custom $_customFastingHours:$_customEatingHours protocol'
                        : 'Total should equal 24h (currently ${_customFastingHours + _customEatingHours}h)',
                    style: TextStyle(
                      fontSize: 12,
                      color: (_customFastingHours + _customEatingHours == 24)
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onProtocolChanged('custom:$_customFastingHours:$_customEatingHours');
                setState(() => _showCustomInput = false);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Apply Custom Protocol'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildIncrementButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardBorder,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardBorder),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
          size: 18,
        ),
      ),
    );
  }

  void _updateCustomProtocol() {
    if (widget.selectedProtocol?.startsWith('custom:') == true) {
      widget.onProtocolChanged('custom:$_customFastingHours:$_customEatingHours');
    }
  }

  Widget _buildSleepScheduleSection(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBorder,
  ) {
    final wakeTime = widget.wakeTime ?? const TimeOfDay(hour: 7, minute: 0);
    final sleepTime = widget.sleepTime ?? const TimeOfDay(hour: 23, minute: 0);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.elevated : AppColorsLight.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.bedtime_outlined, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your sleep schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Helps optimize your fasting window',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Wake and Sleep time pickers
            Row(
              children: [
                Expanded(
                  child: _buildTimePicker(
                    label: 'Wake up',
                    icon: Icons.wb_sunny_outlined,
                    color: AppColors.accent,
                    time: wakeTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: wakeTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppColors.accent,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        widget.onWakeTimeChanged?.call(picked);
                      }
                    },
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBorder: cardBorder,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePicker(
                    label: 'Bedtime',
                    icon: Icons.nightlight_outlined,
                    color: AppColors.accent,
                    time: sleepTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: sleepTime,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppColors.accent,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        widget.onSleepTimeChanged?.call(picked);
                      }
                    },
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBorder: cardBorder,
                  ),
                ),
              ],
            ),

            // Suggestion based on sleep schedule
            if (widget.selectedProtocol != null) ...[
              const SizedBox(height: 16),
              _buildFastingWindowSuggestion(wakeTime, sleepTime, isDark, textSecondary),
            ],
          ],
        ),
      ),
    ).animate(delay: 700.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildTimePicker({
    required String label,
    required IconData icon,
    required Color color,
    required TimeOfDay time,
    required VoidCallback onTap,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    final formattedTime = time.format(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_outlined,
              size: 16,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFastingWindowSuggestion(
    TimeOfDay wakeTime,
    TimeOfDay sleepTime,
    bool isDark,
    Color textSecondary,
  ) {
    // Calculate suggested eating window based on wake time
    final protocol = widget.selectedProtocol;
    int eatingHours = 8;

    if (protocol?.startsWith('custom:') == true) {
      final parts = protocol!.split(':');
      if (parts.length >= 3) {
        eatingHours = int.tryParse(parts[2]) ?? 8;
      }
    } else {
      final protocolData = allFastingProtocols.firstWhere(
        (p) => p['id'] == protocol,
        orElse: () => {'fastingHours': 16, 'eatingHours': 8},
      );
      eatingHours = protocolData['eatingHours'] as int;
    }

    // Suggest eating window starting 1-2 hours after wake
    final eatingStartHour = (wakeTime.hour + 1) % 24;
    final eatingEndHour = (eatingStartHour + eatingHours) % 24;

    String formatHour(int hour) {
      final h = hour % 12 == 0 ? 12 : hour % 12;
      final period = hour < 12 ? 'AM' : 'PM';
      return '$h $period';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Suggested eating window: ${formatHour(eatingStartHour)} - ${formatHour(eatingEndHour)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
