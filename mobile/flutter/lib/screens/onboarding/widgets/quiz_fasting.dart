import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_theme.dart';
import 'scroll_hint_arrow.dart';

part 'quiz_fasting_ui.dart';


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
  final bool showHeader;

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
    this.showHeader = true,
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
      'color': AppColors.green,
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
      'color': AppColors.orange,
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
      'color': AppColors.purple,
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
      'color': AppColors.electricBlue,
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

  String? _getRecommendedProtocol() {
    final fitness = widget.fitnessLevel?.toLowerCase() ?? 'beginner';
    final direction = widget.weightDirection?.toLowerCase() ?? 'maintain';

    if (fitness == 'beginner') {
      if (direction == 'lose') return '14:10';
      return '12:12';
    }

    if (fitness == 'intermediate') {
      if (direction == 'lose') return '16:8';
      if (direction == 'gain') return '14:10';
      return '16:8';
    }

    if (fitness == 'advanced') {
      if (direction == 'lose') return '18:6';
      if (direction == 'gain') return '16:8';
      return '16:8';
    }

    return '16:8';
  }

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

  int _getMaxMealsForProtocol(String? protocolId) {
    if (protocolId == null) return 6;

    int eatingHours = 8;

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
      eatingHours = (protocol['eatingHours'] as num).toInt();
    }

    if (eatingHours <= 1) return 1;
    if (eatingHours <= 4) return 2;
    if (eatingHours <= 6) return 3;
    if (eatingHours <= 8) return 4;
    if (eatingHours <= 10) return 5;
    return 6;
  }

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
    return (protocol['eatingHours'] as num).toInt();
  }

  List<Widget> _getBenefitChips(OnboardingTheme t) {
    final direction = widget.weightDirection?.toLowerCase() ?? 'maintain';

    List<Map<String, dynamic>> benefits;

    if (direction == 'lose') {
      benefits = [
        {'icon': Icons.local_fire_department, 'text': 'Burns fat'},
        {'icon': Icons.trending_down, 'text': 'Reduces cravings'},
        {'icon': Icons.bolt, 'text': 'Boosts energy'},
      ];
    } else if (direction == 'gain') {
      benefits = [
        {'icon': Icons.fitness_center, 'text': 'Builds muscle'},
        {'icon': Icons.trending_up, 'text': 'Growth hormone'},
        {'icon': Icons.restaurant, 'text': 'Better digestion'},
      ];
    } else {
      benefits = [
        {'icon': Icons.psychology, 'text': 'Mental clarity'},
        {'icon': Icons.favorite, 'text': 'Heart health'},
        {'icon': Icons.schedule, 'text': 'Simple routine'},
      ];
    }

    return benefits.map((b) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.cardFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(b['icon'] as IconData, size: 12, color: t.textPrimary),
          const SizedBox(width: 4),
          Text(
            b['text'] as String,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
        ],
      ),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final recommendedId = _getRecommendedProtocol();

    final benefitMessage = _getBenefitMessage();

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showHeader) ...[
                Text(
                  'Intermittent fasting can help you reach your goals faster',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: t.textPrimary,
                    height: 1.3,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                const SizedBox(height: 12),
              ],

              // Benefits container
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.cardFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefitMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: t.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _getBenefitChips(t),
                        ),
                      ],
                    ),
                  ),
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
                      t: t,
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
                      t: t,
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
                    color: t.textPrimary,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 2),
                Text(
                  'Optional - you can set this later',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textSecondary,
                  ),
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 10),

                // Protocol list
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
                              widget.onProtocolChanged(isSelected ? null : id);
                              setState(() => _showCustomInput = false);
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: t.cardSelectedGradient,
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected ? null : t.cardFill,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isRecommended && !isSelected
                                        ? AppColors.green.withValues(alpha: 0.6)
                                        : (isSelected
                                            ? t.borderSelected
                                            : t.borderDefault),
                                    width: isSelected || isRecommended ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isSelected
                                              ? t.iconContainerSelectedGradient(color)
                                              : t.iconContainerGradient(color),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? t.iconContainerSelectedBorder(color)
                                              : t.iconContainerBorder(color),
                                        ),
                                      ),
                                      child: Icon(
                                        protocol['icon'] as IconData,
                                        color: color,
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
                                                  color: t.textPrimary,
                                                ),
                                              ),
                                              if (isRecommended) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: t.badgeBg,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Recommended',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: t.badgeText,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (protocol['popular'] == true && !isRecommended) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: t.cardFill,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Popular',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: t.textPrimary,
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
                                              color: t.textSecondary,
                                            ),
                                          ),
                                          if (isRecommended && !isSelected) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              _getRecommendationReason(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: AppColors.green,
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
                                                  color: isSelected
                                                      ? t.textSecondary
                                                      : AppColors.warning,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  protocol['warning'] as String,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isSelected
                                                        ? t.textSecondary
                                                        : AppColors.warning,
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
                                        color: isSelected ? t.checkBg : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? null
                                            : Border.all(color: t.borderDefault, width: 1.5),
                                      ),
                                      child: isSelected
                                          ? Icon(Icons.check, color: t.checkIcon, size: 12)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ).animate(delay: (200 + index * 60).ms).fadeIn().slideX(begin: 0.05),

                        // Custom protocol input
                        if (isCustom && _showCustomInput) ...[
                          const SizedBox(height: 8),
                          _buildCustomProtocolInput(t),
                        ],
                      ],
                    ),
                  );
                }),

                // Meal distribution info
                if (widget.selectedProtocol != null && widget.mealsPerDay != null)
                  _buildMealDistributionInfo(t),

                // Sleep schedule section
                if (widget.onWakeTimeChanged != null)
                  _buildSleepScheduleSection(t),
              ],

              const SizedBox(height: 60),
            ],
          ),
        ),
        ScrollHintArrow(scrollController: _scrollController),
      ],
    );
  }

  Widget _buildCustomProtocolInput(OnboardingTheme t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.cardFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.borderDefault),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set your custom fasting window',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
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
                            color: t.textSecondary,
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
                              t: t,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$_customFastingHours h',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: t.textPrimary,
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
                              t: t,
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
                            color: t.textSecondary,
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
                              t: t,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$_customEatingHours h',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: t.textPrimary,
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
                              t: t,
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
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
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

              // Apply button - glassmorphic
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          widget.onProtocolChanged('custom:$_customFastingHours:$_customEatingHours');
                          setState(() => _showCustomInput = false);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: t.buttonGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: t.buttonBorder),
                          ),
                          child: Center(
                            child: Text(
                              'Apply Custom Protocol',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: t.buttonText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildIncrementButton({
    required IconData icon,
    required VoidCallback onTap,
    required OnboardingTheme t,
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
          color: t.cardFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: t.borderDefault),
        ),
        child: Icon(
          icon,
          color: t.textPrimary,
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
}
