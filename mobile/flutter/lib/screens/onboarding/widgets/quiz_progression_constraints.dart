import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'onboarding_theme.dart';

/// Progression pace selection widget (Phase 2 personalization).
///
/// Allows user to select progression pace (Slow, Medium, Fast).
/// Physical limitations have been moved to QuizLimitations (shown earlier in Phase 1).
class QuizProgressionConstraints extends StatelessWidget {
  final String? selectedPace;
  final String fitnessLevel;
  final ValueChanged<String> onPaceChanged;
  final bool showHeader;

  const QuizProgressionConstraints({
    super.key,
    required this.selectedPace,
    required this.fitnessLevel,
    required this.onPaceChanged,
    this.showHeader = true,
  });

  /// Get recommended pace based on fitness level
  String get _recommendedPace {
    if (fitnessLevel == 'beginner') return 'slow';
    if (fitnessLevel == 'advanced') return 'fast';
    return 'medium';
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Text(
              'Progression Pace',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              'How fast do you want to progress?',
              style: TextStyle(
                fontSize: 15,
                color: t.textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildPaceCard(
                  context: context,
                  id: 'slow',
                  title: 'Slow & Steady',
                  description: 'Build strength gradually, lower injury risk',
                  icon: Icons.trending_flat,
                  recommended: _recommendedPace == 'slow',
                  badgeLabel: _recommendedPace == 'slow' ? 'FOR YOU' : null,
                  delay: 300.ms,
                ),
                const SizedBox(height: 12),
                _buildPaceCard(
                  context: context,
                  id: 'medium',
                  title: 'Balanced',
                  description: 'Steady progress with manageable challenge',
                  icon: Icons.trending_up,
                  recommended: true,
                  badgeLabel: 'Recommended',
                  delay: 400.ms,
                ),
                const SizedBox(height: 12),
                _buildPaceCard(
                  context: context,
                  id: 'fast',
                  title: 'Fast & Aggressive',
                  description: 'Push hard, faster gains (advanced)',
                  icon: Icons.rocket_launch,
                  recommended: _recommendedPace == 'fast',
                  badgeLabel: _recommendedPace == 'fast' ? 'FOR YOU' : null,
                  delay: 500.ms,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceCard({
    required BuildContext context,
    required String id,
    required String title,
    required String description,
    required IconData icon,
    bool recommended = false,
    String? badgeLabel,
    required Duration delay,
  }) {
    final t = OnboardingTheme.of(context);
    final isSelected = selectedPace == id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onPaceChanged(id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
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
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? t.checkBg : t.cardFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? t.textPrimary : t.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: t.textPrimary,
                            ),
                          ),
                          if (recommended && badgeLabel != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.checkBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: t.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? t.textPrimary
                              : t.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Checkmark
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.textPrimary,
                    ),
                    child: const Icon(Icons.check, size: 20, color: Color(0xFF0D9488), weight: 700),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }
}
