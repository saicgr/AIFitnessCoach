import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Physical limitations selection widget (moved from QuizProgressionConstraints).
///
/// Now shown as its own screen after Equipment selection (Phase 1).
/// Allows user to select:
/// - Physical limitations (None, Knees, Shoulders, Lower Back, Wrists, Elbows, Hips, Ankles, Neck, Other)
/// - Custom limitation input for "Other" option
class QuizLimitations extends StatefulWidget {
  final List<String> selectedLimitations;
  final String? customLimitation;
  final ValueChanged<List<String>> onLimitationsChanged;
  final ValueChanged<String?>? onCustomLimitationChanged;
  final bool showHeader;

  const QuizLimitations({
    super.key,
    required this.selectedLimitations,
    this.customLimitation,
    required this.onLimitationsChanged,
    this.onCustomLimitationChanged,
    this.showHeader = true,
  });

  @override
  State<QuizLimitations> createState() => _QuizLimitationsState();
}

class _QuizLimitationsState extends State<QuizLimitations> {
  final TextEditingController _customLimitationController = TextEditingController();
  final FocusNode _customLimitationFocus = FocusNode();

  @override
  void initState() {
    super.initState();
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
            Text(
              'Any injuries or limitations?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              "We'll avoid exercises that stress these areas",
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
                // Limitation chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildLimitationChip('none', 'None', isDark, 300.ms),
                    _buildLimitationChip('knees', 'Knees', isDark, 325.ms),
                    _buildLimitationChip('shoulders', 'Shoulders', isDark, 350.ms),
                    _buildLimitationChip('lower_back', 'Lower Back', isDark, 375.ms),
                    _buildLimitationChip('wrists', 'Wrists', isDark, 400.ms),
                    _buildLimitationChip('elbows', 'Elbows', isDark, 425.ms),
                    _buildLimitationChip('hips', 'Hips', isDark, 450.ms),
                    _buildLimitationChip('ankles', 'Ankles', isDark, 475.ms),
                    _buildLimitationChip('neck', 'Neck', isDark, 500.ms),
                    _buildLimitationChip('other', 'Other', isDark, 525.ms),
                  ],
                ),
                const SizedBox(height: 16),

                // Custom limitation input field (shown when "Other" is selected)
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
                  ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.05),
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

  Widget _buildLimitationChip(String id, String label, bool isDark, Duration delay) {
    final isSelected = widget.selectedLimitations.contains(id);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        List<String> newLimitations = List.from(widget.selectedLimitations);

        if (id == 'none') {
          newLimitations = ['none'];
          if (widget.onCustomLimitationChanged != null) {
            widget.onCustomLimitationChanged!(null);
            _customLimitationController.clear();
          }
        } else {
          newLimitations.remove('none');

          if (isSelected) {
            newLimitations.remove(id);
            if (id == 'other') {
              if (widget.onCustomLimitationChanged != null) {
                widget.onCustomLimitationChanged!(null);
                _customLimitationController.clear();
              }
            }
          } else {
            newLimitations.add(id);
            if (id == 'other') {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  _customLimitationFocus.requestFocus();
                }
              });
            }
          }

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
