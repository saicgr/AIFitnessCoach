import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_colors.dart';

/// Health checklist modal shown at end of onboarding
/// Collects injuries and health conditions (optional)
class HealthChecklistModal extends StatefulWidget {
  final void Function(List<String> injuries, List<String> conditions) onComplete;
  final VoidCallback onSkip;

  const HealthChecklistModal({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<HealthChecklistModal> createState() => _HealthChecklistModalState();
}

class _HealthChecklistModalState extends State<HealthChecklistModal>
    with SingleTickerProviderStateMixin {
  static const _injuryOptions = [
    'Lower back pain',
    'Shoulder issues',
    'Knee problems',
    'Wrist/elbow pain',
    'Neck pain',
    'Hip issues',
    'Leg pain',
    'Ankle issues',
    'Other',
    'None',
  ];

  static const _healthConditions = [
    'High blood pressure',
    'Heart condition',
    'Diabetes',
    'Asthma',
    'Arthritis',
    'Pregnancy',
    'Recent surgery',
    'Other',
    'None',
  ];

  final Set<String> _selectedInjuries = {};
  final Set<String> _selectedConditions = {};

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleItem(String item, Set<String> set, bool isNone) {
    HapticFeedback.selectionClick();
    setState(() {
      if (item == 'None') {
        // "None" is exclusive
        if (set.contains('None')) {
          set.clear();
        } else {
          set.clear();
          set.add('None');
        }
      } else {
        // Remove "None" if selecting other items
        set.remove('None');
        if (set.contains(item)) {
          set.remove(item);
        } else {
          set.add(item);
        }
      }
    });
  }

  void _handleComplete() {
    HapticFeedback.mediumImpact();
    final injuries = _selectedInjuries.contains('None')
        ? <String>[]
        : _selectedInjuries.toList();
    final conditions = _selectedConditions.contains('None')
        ? <String>[]
        : _selectedConditions.toList();
    widget.onComplete(injuries, conditions);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              color: colors.elevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Health & Safety Check',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us keep your workouts safe. This is optional - skip if you prefer.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Injuries section
                  Text(
                    'Current Injuries or Pain',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _injuryOptions.map((injury) {
                      final isSelected = _selectedInjuries.contains(injury);
                      final isNone = injury == 'None';
                      return _buildChip(
                        injury,
                        isSelected,
                        isNone ? colors.success : colors.error,
                        () => _toggleItem(injury, _selectedInjuries, isNone),
                        colors,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Health conditions section
                  Text(
                    'Health Conditions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _healthConditions.map((condition) {
                      final isSelected = _selectedConditions.contains(condition);
                      final isNone = condition == 'None';
                      return _buildChip(
                        condition,
                        isSelected,
                        isNone ? colors.success : colors.orange,
                        () => _toggleItem(condition, _selectedConditions, isNone),
                        colors,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onSkip();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: colors.glassSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.cardBorder),
                            ),
                            child: Center(
                              child: Text(
                                'Skip for now',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _handleComplete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: colors.cyanGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.cyan.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    String label,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap,
    ThemeColors colors,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.3)
              : colors.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : accentColor.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? accentColor : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
