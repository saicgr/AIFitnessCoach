import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Training split selection question widget with educational information.
class QuizTrainingSplit extends StatelessWidget {
  final String? selectedSplit;
  final ValueChanged<String> onSplitChanged;
  final VoidCallback? onSkip;

  const QuizTrainingSplit({
    super.key,
    required this.selectedSplit,
    required this.onSplitChanged,
    this.onSkip,
  });

  static const _splits = [
    {
      'id': 'push_pull_legs',
      'label': 'Push/Pull/Legs',
      'icon': Icons.splitscreen,
      'color': AppColors.purple,
      'description': 'Classic 3-day split for muscle building',
      'bestFor': 'Most Popular',
      'detail': 'Push (chest, shoulders, triceps), Pull (back, biceps), and Legs on separate days. The most versatile split - works for 3-6 days/week with good volume and recovery.',
      'isDefault': true,
    },
    {
      'id': 'full_body',
      'label': 'Full Body',
      'icon': Icons.accessibility_new,
      'color': AppColors.success,
      'description': 'Train all muscle groups each session',
      'bestFor': 'Beginners, 2-3 days/week',
      'detail': 'Works your entire body in each workout. Great for beginners or those with limited time. Ensures balanced development and allows for recovery between sessions.',
    },
    {
      'id': 'upper_lower',
      'label': 'Upper/Lower',
      'icon': Icons.swap_vert,
      'color': AppColors.electricBlue,
      'description': 'Alternate between upper and lower body',
      'bestFor': '4 days/week',
      'detail': 'Splits workouts into upper body (chest, back, shoulders, arms) and lower body (legs, glutes) days. Good balance of volume and recovery for intermediate lifters.',
    },
    {
      'id': 'phul',
      'label': 'PHUL',
      'icon': Icons.flash_on,
      'color': AppColors.orange,
      'description': 'Power & Hypertrophy Upper Lower',
      'bestFor': '4 days/week, Strength + Size',
      'detail': 'Combines strength (power days) and muscle building (hypertrophy days). Upper Power, Lower Power, Upper Hypertrophy, Lower Hypertrophy. Best of both worlds for building strength and size.',
    },
    {
      'id': 'body_part',
      'label': 'Body Part Split',
      'icon': Icons.filter_frames,
      'color': AppColors.coral,
      'description': 'Focus on one muscle group per session',
      'bestFor': '5-6 days/week, Advanced',
      'detail': 'Each day focuses on one muscle group (e.g., Chest Monday, Back Tuesday). Allows maximum volume per muscle but requires more gym days for full coverage.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(textPrimary, textSecondary),
            const SizedBox(height: 8),
            _buildSubtitle(textSecondary),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildHelpButton(context, isDark, textSecondary),
                const Spacer(),
                if (onSkip != null)
                  _buildSkipButton(textSecondary),
              ],
            ),
            const SizedBox(height: 20),
            ..._buildSplitCards(context, isDark, textPrimary, textSecondary),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton(Color textSecondary) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSkip?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Skip for now",
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: textSecondary, size: 12),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildTitle(Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            "How do you like to split your training?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: textSecondary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Optional',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(Color textSecondary) {
    return Text(
      "We'll design your workouts around this structure",
      style: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildHelpButton(BuildContext context, bool isDark, Color textSecondary) {
    return GestureDetector(
      onTap: () => _showExplanationSheet(context, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, color: AppColors.cyan, size: 16),
            const SizedBox(width: 6),
            Text(
              "Not sure? Tap to learn more",
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  void _showExplanationSheet(BuildContext context, bool isDark) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.school_outlined, color: AppColors.cyan, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Training Splits Explained',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'A training split is how you organize which muscle groups to train on which days. The right split depends on your schedule and goals.',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ..._splits.map((split) => _buildDetailCard(
                    isDark,
                    textPrimary,
                    textSecondary,
                    split,
                  )),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.cyan),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Not sure? Push/Pull/Legs is our top recommendation - it works for most people and schedules. PHUL is great if you want both strength and size.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Map<String, dynamic> split,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (split['color'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  split['icon'] as IconData,
                  color: split['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      split['label'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (split['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        split['bestFor'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: split['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            split['detail'] as String,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSplitCards(BuildContext context, bool isDark, Color textPrimary, Color textSecondary) {
    return _splits.asMap().entries.map((entry) {
      final index = entry.key;
      final split = entry.value;
      final isSelected = selectedSplit == split['id'];
      final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSplitChanged(split['id'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.cyanGradient : null,
              color: isSelected
                  ? null
                  : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.cyan : cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : (split['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    split['icon'] as IconData,
                    color: isSelected ? Colors.white : (split['color'] as Color),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              split['label'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (split['isDefault'] == true) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: isSelected ? Colors.white : AppColors.warning,
                            ),
                          ],
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : (split['color'] as Color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              split['bestFor'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : (split['color'] as Color),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        split['description'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white70 : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(color: cardBorder, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ).animate(delay: (100 + index * 60).ms).fadeIn().slideX(begin: 0.05),
      );
    }).toList();
  }
}
