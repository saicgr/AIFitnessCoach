import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';
import 'onboarding_theme.dart';

/// Glassmorphic primary goal selection widget for quiz screens.
class QuizPrimaryGoal extends StatelessWidget {
  final String question;
  final String subtitle;
  final List<Map<String, dynamic>> options;
  final String? selectedValue;
  final ValueChanged<String> onSelect;
  final bool showHeader;

  const QuizPrimaryGoal({
    super.key,
    required this.question,
    required this.subtitle,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
    this.showHeader = true,
  });

  static Widget buildInfoButton(BuildContext context) {
    final t = OnboardingTheme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showInfoSheet(context);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: t.cardFill,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.info_outline,
          size: 20,
          color: t.textPrimary,
        ),
      ),
    );
  }

  static void _showInfoSheet(BuildContext context) {
    final t = OnboardingTheme.of(context);
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.auto_awesome, color: AppColors.orange, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('How AI Uses This', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.textPrimary)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: t.textMuted, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoSection(context, icon: Icons.fitness_center, title: 'Rep Ranges', description: 'Sets the number of reps per exercise. Hypertrophy uses 8-12 reps, Strength uses 3-6, Endurance uses 12+.'),
              const SizedBox(height: 16),
              _buildInfoSection(context, icon: Icons.speed, title: 'Workout Intensity', description: 'Adjusts rest periods, exercise difficulty, and overall workout volume based on your focus.'),
              const SizedBox(height: 16),
              _buildInfoSection(context, icon: Icons.list_alt, title: 'Exercise Selection', description: 'AI picks exercises that best match your goal—compound lifts for strength, isolation moves for hypertrophy.'),
              const SizedBox(height: 16),
              _buildInfoSection(context, icon: Icons.refresh, title: 'Can Change Anytime', description: 'You can update your training focus in Settings whenever your goals evolve.'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Got it', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final t = OnboardingTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: t.cardFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: t.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textPrimary)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                buildInfoButton(context),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: t.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final id = option['id'] as String;
                final isSelected = selectedValue == id;

                return _GlassPrimaryGoalCard(
                  option: option,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(id);
                  },
                  index: index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPrimaryGoalCard extends StatelessWidget {
  final Map<String, dynamic> option;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _GlassPrimaryGoalCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);
    final color = option['color'] as Color? ?? AppColors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: t.cardSelectedGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : t.cardFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? t.borderSelected : t.borderDefault,
                  width: isSelected ? 2.0 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.1),
                          blurRadius: 16,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? t.iconContainerSelectedGradient
                            : t.iconContainerGradient(color),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? t.iconContainerSelectedBorder
                            : t.iconContainerBorder(color),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      option['icon'] as IconData,
                      color: isSelected ? t.textPrimary : color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option['label'] as String,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          option['description'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: t.textSecondary,
                            height: 1.4,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? t.checkBg : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: t.checkBorderUnselected,
                              width: 2,
                            ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: t.checkIcon, size: 20, weight: 700)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
