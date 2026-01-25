import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Introductory sheet shown when users first navigate to Programs tab
/// Explains what to expect and shows the program is under development
class ProgramsIntroSheet extends StatelessWidget {
  const ProgramsIntroSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cyan.withOpacity(0.2), orange.withOpacity(0.2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 32,
                      color: cyan,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workout Programs',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Currently Being Developed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // What to expect section
              Text(
                'What You Can Expect',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              _buildExpectationItem(
                icon: Icons.calendar_month,
                title: 'Flexible Duration',
                description: 'Choose programs ranging from 1 to 16 weeks based on your goals',
                color: cyan,
                isDark: isDark,
              ),

              _buildExpectationItem(
                icon: Icons.event_repeat,
                title: 'Custom Frequency',
                description: 'Select 3-7 workout days per week to fit your schedule',
                color: cyan,
                isDark: isDark,
              ),

              _buildExpectationItem(
                icon: Icons.speed,
                title: 'Intensity Levels',
                description: 'Programs tailored for Beginner, Intermediate, and Advanced levels',
                color: cyan,
                isDark: isDark,
              ),

              _buildExpectationItem(
                icon: Icons.list_alt,
                title: '185+ Unique Programs',
                description: 'Covering strength, cardio, mobility, sport-specific training, and more',
                color: cyan,
                isDark: isDark,
              ),

              _buildExpectationItem(
                icon: Icons.video_library,
                title: 'Exercise Demonstrations',
                description: 'High-quality videos and detailed instructions for every exercise',
                color: cyan,
                isDark: isDark,
              ),

              _buildExpectationItem(
                icon: Icons.trending_up,
                title: 'Progress Tracking',
                description: 'Track your workouts, weights, and see your improvement over time',
                color: cyan,
                isDark: isDark,
              ),

              const SizedBox(height: 32),

              // Program categories preview
              Text(
                'Program Categories',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip('Strength Training', isDark),
                  _buildCategoryChip('Weight Loss', isDark),
                  _buildCategoryChip('Muscle Building', isDark),
                  _buildCategoryChip('Athletic Performance', isDark),
                  _buildCategoryChip('Home Workouts', isDark),
                  _buildCategoryChip('Bodyweight Training', isDark),
                  _buildCategoryChip('Powerlifting', isDark),
                  _buildCategoryChip('HIIT', isDark),
                  _buildCategoryChip('Yoga & Mobility', isDark),
                  _buildCategoryChip('Sport-Specific', isDark),
                ],
              ),

              const SizedBox(height: 32),

              // Current status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.construction, color: orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Work in Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We\'re currently finalizing exercise videos, instructions, and program structures. '
                      'All programs are marked as "Coming Soon" while we ensure they meet our quality standards.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '🎯 Our Goal: Deliver 100% complete programs with full video demonstrations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Browse Programs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpectationItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cyan.withOpacity(0.1)
            : AppColorsLight.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? AppColors.cyan.withOpacity(0.3)
              : AppColorsLight.cyan.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.cyan : AppColorsLight.cyan,
        ),
      ),
    );
  }
}
