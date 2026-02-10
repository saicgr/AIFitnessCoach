import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Progression and constraints selection widget (Screen 9: Phase 2 personalization).
///
/// Allows user to select:
/// - Progression pace (Slow, Medium, Fast)
/// - Physical limitations (None, Knees, Shoulders, Lower Back, Wrists, Elbows, Hips, Ankles, Neck, Other)
/// - Custom limitation input for "Other" option
class QuizProgressionConstraints extends StatefulWidget {
  final String? selectedPace;
  final List<String> selectedLimitations;
  final String? customLimitation;  // ← ADDED: Store custom limitation text
  final String fitnessLevel;
  final ValueChanged<String> onPaceChanged;
  final ValueChanged<List<String>> onLimitationsChanged;
  final ValueChanged<String?>? onCustomLimitationChanged;  // ← ADDED: Callback for custom text
  final bool showHeader;

  const QuizProgressionConstraints({
    super.key,
    required this.selectedPace,
    required this.selectedLimitations,
    this.customLimitation,
    required this.fitnessLevel,
    required this.onPaceChanged,
    required this.onLimitationsChanged,
    this.onCustomLimitationChanged,
    this.showHeader = true,
  });

  @override
  State<QuizProgressionConstraints> createState() => _QuizProgressionConstraintsState();
}

class _QuizProgressionConstraintsState extends State<QuizProgressionConstraints> {
  final TextEditingController _customLimitationController = TextEditingController();
  final FocusNode _customLimitationFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize custom limitation text if provided
    if (widget.customLimitation != null) {
      _customLimitationController.text = widget.customLimitation!;
    }
  }

  @override
  void dispose() {
    _customLimitationController.dispose();
    _customLimitationFocus.dispose();
    super.dispose();
  }

  /// Get recommended pace based on fitness level
  String get _recommendedPace {
    if (widget.fitnessLevel == 'beginner') return 'slow';
    if (widget.fitnessLevel == 'advanced') return 'fast';
    return 'medium';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            // Title
            Text(
              'Progression & Safety',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              'Set your pace and tell us about any limitations',
              style: TextStyle(
                fontSize: 15,
                color: textSecondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Section A: Progression Pace
                Text(
                  'How fast do you want to progress?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                _buildPaceCard(
                  id: 'slow',
                  title: 'Slow & Steady',
                  description: 'Build strength gradually, lower injury risk',
                  icon: Icons.trending_flat,
                  recommended: _recommendedPace == 'slow',
                  isDark: isDark,
                  delay: 300.ms,
                ),
                const SizedBox(height: 12),
                _buildPaceCard(
                  id: 'medium',
                  title: 'Balanced',
                  description: 'Steady progress with manageable challenge',
                  icon: Icons.trending_up,
                  recommended: _recommendedPace == 'medium',
                  isDark: isDark,
                  delay: 400.ms,
                ),
                const SizedBox(height: 12),
                _buildPaceCard(
                  id: 'fast',
                  title: 'Fast & Aggressive',
                  description: 'Push hard, faster gains (advanced)',
                  icon: Icons.rocket_launch,
                  recommended: _recommendedPace == 'fast',
                  isDark: isDark,
                  delay: 500.ms,
                ),

                const SizedBox(height: 32),

                // Section B: Physical Limitations
                Text(
                  'Any physical limitations?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We\'ll avoid exercises that stress these areas',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Limitation chips - ← EXPANDED with more options
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildLimitationChip('none', 'None', isDark, 600.ms),
                    _buildLimitationChip('knees', 'Knees', isDark, 625.ms),
                    _buildLimitationChip('shoulders', 'Shoulders', isDark, 650.ms),
                    _buildLimitationChip('lower_back', 'Lower Back', isDark, 675.ms),
                    _buildLimitationChip('wrists', 'Wrists', isDark, 700.ms),
                    _buildLimitationChip('elbows', 'Elbows', isDark, 725.ms),
                    _buildLimitationChip('hips', 'Hips', isDark, 750.ms),
                    _buildLimitationChip('ankles', 'Ankles', isDark, 775.ms),
                    _buildLimitationChip('neck', 'Neck', isDark, 800.ms),
                    _buildLimitationChip('other', 'Other', isDark, 825.ms),
                  ],
                ),
                const SizedBox(height: 16),

                // ← ADDED: Custom limitation input field (shown when "Other" is selected)
                if (widget.selectedLimitations.contains('other')) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.orange.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Describe your limitation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customLimitationController,
                          focusNode: _customLimitationFocus,
                          style: TextStyle(
                            fontSize: 15,
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., Carpal tunnel, herniated disc, etc.',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: textSecondary.withOpacity(0.6),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.glassSurface : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? AppColors.glassBorder : AppColorsLight.cardBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.orange,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          maxLines: 2,
                          textInputAction: TextInputAction.done,
                          onChanged: (value) {
                            // Save custom limitation text
                            if (widget.onCustomLimitationChanged != null) {
                              widget.onCustomLimitationChanged!(value.trim().isEmpty ? null : value.trim());
                            }
                          },
                          onSubmitted: (_) {
                            _customLimitationFocus.unfocus();
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 850.ms).slideY(begin: 0.05),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
    bool recommended = false,
    required bool isDark,
    required Duration delay,
  }) {
    final isSelected = widget.selectedPace == id;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onPaceChanged(id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFE85A24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.orange
                : (isDark ? AppColors.glassBorder : AppColorsLight.cardBorder),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.orange.withValues(alpha: 0.2)
                    : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : textSecondary,
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
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FOR YOU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
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
                      color: isSelected ? Colors.white.withOpacity(0.9) : textSecondary,
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
                  color: Colors.white,
                ),
                child: Icon(Icons.check, size: 20, color: AppColors.orange, weight: 700),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05);
  }

  Widget _buildLimitationChip(String id, String label, bool isDark, Duration delay) {
    final isSelected = widget.selectedLimitations.contains(id);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        List<String> newLimitations = List.from(widget.selectedLimitations);

        if (id == 'none') {
          // Selecting "None" clears all others
          newLimitations = ['none'];
          // Clear custom limitation text
          if (widget.onCustomLimitationChanged != null) {
            widget.onCustomLimitationChanged!(null);
            _customLimitationController.clear();
          }
        } else {
          // Selecting any limitation removes "None"
          newLimitations.remove('none');

          if (isSelected) {
            newLimitations.remove(id);
            // If deselecting "Other", clear custom text
            if (id == 'other') {
              if (widget.onCustomLimitationChanged != null) {
                widget.onCustomLimitationChanged!(null);
                _customLimitationController.clear();
              }
            }
          } else {
            newLimitations.add(id);
            // If selecting "Other", focus the text field
            if (id == 'other') {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _customLimitationFocus.requestFocus();
                }
              });
            }
          }

          // If all are deselected, default to "None"
          if (newLimitations.isEmpty) {
            newLimitations = ['none'];
          }
        }

        widget.onLimitationsChanged(newLimitations);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange
              : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.orange
                : (isDark ? AppColors.glassBorder : AppColorsLight.cardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).scale(begin: const Offset(0.9, 0.9));
  }
}
