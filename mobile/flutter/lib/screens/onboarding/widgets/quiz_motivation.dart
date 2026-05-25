import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'onboarding_theme.dart';

/// Motivation multi-select widget for quiz screens.
class QuizMotivation extends StatelessWidget {
  final Set<String> selectedMotivations;
  final ValueChanged<String> onToggle;
  final bool showHeader;

  const QuizMotivation({
    super.key,
    required this.selectedMotivations,
    required this.onToggle,
    this.showHeader = true,
  });

  static List<Map<String, Object>> _buildMotivations(AppLocalizations l10n) => [
    {'id': 'look_better', 'label': l10n.quizMotivationLookBetter, 'icon': Icons.auto_awesome, 'color': AppColors.onboardingAccent},
    {'id': 'feel_stronger', 'label': l10n.quizMotivationFeelStronger, 'icon': Icons.fitness_center, 'color': AppColors.purple},
    {'id': 'more_energy', 'label': l10n.quizMotivationHaveMoreEnergy, 'icon': Icons.bolt, 'color': AppColors.electricBlue},
    {'id': 'mental_health', 'label': l10n.quizMotivationImproveMentalHealth, 'icon': Icons.psychology, 'color': AppColors.green},
    {'id': 'sleep_better', 'label': l10n.quizMotivationSleepBetter, 'icon': Icons.nightlight_round, 'color': AppColors.electricBlue},
    {'id': 'be_healthier', 'label': l10n.quizMotivationBeHealthierOverall, 'icon': Icons.favorite, 'color': AppColors.pink},
    {'id': 'sports_performance', 'label': l10n.quizMotivationSportsPerformance, 'icon': Icons.sports_basketball, 'color': AppColors.onboardingAccent},
    {'id': 'confidence', 'label': l10n.quizMotivationBuildConfidence, 'icon': Icons.star, 'color': AppColors.onboardingAccent},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final motivations = _buildMotivations(l10n);
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            _buildTitle(context, t),
            const SizedBox(height: 8),
            _buildSubtitle(context, t),
            const SizedBox(height: 24),
          ],
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: motivations.length,
              itemBuilder: (context, index) {
                final motivation = motivations[index];
                return _MotivationCard(
                  motivation: motivation,
                  isSelected: selectedMotivations.contains(motivation['id'] as String),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onToggle(motivation['id'] as String);
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

  Widget _buildTitle(BuildContext context, OnboardingTheme t) {
    return Text(
      AppLocalizations.of(context)!.quizMotivationWhatSDrivingYou,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: t.textPrimary,
        height: 1.3,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(BuildContext context, OnboardingTheme t) {
    return Text(
      AppLocalizations.of(context)!.quizMotivationSelectAllThatResonate,
      style: TextStyle(
        fontSize: 14,
        color: t.textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _MotivationCard extends StatelessWidget {
  final Map<String, dynamic> motivation;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _MotivationCard({
    required this.motivation,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: AlignmentDirectional.topStart,
                        end: AlignmentDirectional.bottomEnd,
                        colors: t.cardSelectedGradient,
                      )
                    : null,
                color: isSelected ? null : t.cardFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? t.borderSelected : t.borderDefault,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Builder(builder: (context) {
                    final color = motivation['color'] as Color? ?? AppColors.onboardingAccent;
                    return Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected
                              ? t.iconContainerSelectedGradient(color)
                              : t.iconContainerGradient(color),
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? t.iconContainerSelectedBorder(color)
                              : t.iconContainerBorder(color),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        motivation['icon'] as IconData,
                        color: color,
                        size: 20,
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      motivation['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? t.checkBg : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? null
                          : Border.all(color: t.checkBorderUnselected, width: 2),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: t.checkIcon, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate(delay: (100 + index * 60).ms).fadeIn().slideX(begin: 0.05),
    );
  }
}
