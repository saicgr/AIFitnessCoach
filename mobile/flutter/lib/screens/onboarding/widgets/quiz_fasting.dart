import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Fasting interest question for the pre-auth quiz.
/// Shows yes/no selection and optional protocol picker if interested.
class QuizFasting extends StatelessWidget {
  final bool? interestedInFasting;
  final String? selectedProtocol;
  final ValueChanged<bool> onInterestChanged;
  final ValueChanged<String?> onProtocolChanged;

  const QuizFasting({
    super.key,
    required this.interestedInFasting,
    required this.selectedProtocol,
    required this.onInterestChanged,
    required this.onProtocolChanged,
  });

  static const List<Map<String, dynamic>> fastingProtocols = [
    {
      'id': '16:8',
      'label': '16:8',
      'description': 'Fast 16 hours, eat within 8 hours',
      'icon': Icons.schedule,
      'color': AppColors.cyan,
    },
    {
      'id': '18:6',
      'label': '18:6',
      'description': 'Fast 18 hours, eat within 6 hours',
      'icon': Icons.timer,
      'color': AppColors.purple,
    },
    {
      'id': '14:10',
      'label': '14:10',
      'description': 'Fast 14 hours, eat within 10 hours',
      'icon': Icons.access_time,
      'color': AppColors.teal,
    },
    {
      'id': '20:4',
      'label': '20:4',
      'description': 'Fast 20 hours, eat within 4 hours',
      'icon': Icons.hourglass_top,
      'color': AppColors.orange,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interested in intermittent fasting?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              height: 1.3,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
          const SizedBox(height: 8),
          Text(
            'We can help track your fasting windows',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          // Yes/No selection
          Row(
            children: [
              Expanded(
                child: _InterestButton(
                  label: 'Yes',
                  icon: Icons.check_circle_outline,
                  isSelected: interestedInFasting == true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onInterestChanged(true);
                  },
                  isDark: isDark,
                  textPrimary: textPrimary,
                  cardBorder: cardBorder,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InterestButton(
                  label: 'Not now',
                  icon: Icons.cancel_outlined,
                  isSelected: interestedInFasting == false,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onInterestChanged(false);
                    onProtocolChanged(null);
                  },
                  isDark: isDark,
                  textPrimary: textPrimary,
                  cardBorder: cardBorder,
                ),
              ),
            ],
          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),

          // Protocol selection (only if interested)
          if (interestedInFasting == true) ...[
            const SizedBox(height: 24),
            Text(
              'Choose a fasting protocol',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 4),
            Text(
              'Optional - you can set this later',
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
              ),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: fastingProtocols.length,
                itemBuilder: (context, index) {
                  final protocol = fastingProtocols[index];
                  final id = protocol['id'] as String;
                  final isSelected = selectedProtocol == id;
                  final color = protocol['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        // Toggle off if already selected
                        onProtocolChanged(isSelected ? null : id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.cyanGradient : null,
                          color: isSelected
                              ? null
                              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.cyan : cardBorder,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.cyan.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                protocol['icon'] as IconData,
                                color: isSelected ? Colors.white : color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    protocol['label'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    protocol['description'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white70 : textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? null
                                    : Border.all(color: cardBorder, width: 2),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: (200 + index * 80).ms).fadeIn().slideX(begin: 0.05),
                  );
                },
              ),
            ),
          ] else if (interestedInFasting != null) ...[
            // Show spacer when "Not now" is selected
            const Spacer(),
          ] else ...[
            // Show spacer when nothing is selected yet
            const Spacer(),
          ],
        ],
      ),
    );
  }
}

class _InterestButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color textPrimary;
  final Color cardBorder;

  const _InterestButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.textPrimary,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.cyan,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
