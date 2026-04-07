import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 6),
            Text(
              "We'll avoid exercises that stress these areas",
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.7),
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
                    _buildLimitationChip('none', 'None', 300.ms),
                    _buildLimitationChip('knees', 'Knees', 325.ms),
                    _buildLimitationChip('shoulders', 'Shoulders', 350.ms),
                    _buildLimitationChip('lower_back', 'Lower Back', 375.ms),
                    _buildLimitationChip('wrists', 'Wrists', 400.ms),
                    _buildLimitationChip('elbows', 'Elbows', 425.ms),
                    _buildLimitationChip('hips', 'Hips', 450.ms),
                    _buildLimitationChip('ankles', 'Ankles', 475.ms),
                    _buildLimitationChip('neck', 'Neck', 500.ms),
                    _buildLimitationChip('other', 'Other', 525.ms),
                  ],
                ),
                const SizedBox(height: 16),

                // Custom limitation input field (shown when "Other" is selected)
                if (widget.selectedLimitations.contains('other')) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
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
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Describe your limitation',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _customLimitationController,
                              focusNode: _customLimitationFocus,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g., Carpal tunnel, herniated disc, etc.',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              cursorColor: Colors.white,
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
                      ),
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

  Widget _buildLimitationChip(String id, String label, Duration delay) {
    final isSelected = widget.selectedLimitations.contains(id);

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.16),
                      ],
                    )
                  : null,
              color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay).scale(begin: const Offset(0.9, 0.9));
  }
}
