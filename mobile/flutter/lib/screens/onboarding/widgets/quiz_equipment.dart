import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Equipment selection widget for quiz screens.
class QuizEquipment extends StatelessWidget {
  final Set<String> selectedEquipment;
  final int dumbbellCount;
  final int kettlebellCount;
  final ValueChanged<String> onEquipmentToggled;
  final ValueChanged<int> onDumbbellCountChanged;
  final ValueChanged<int> onKettlebellCountChanged;
  final Function(BuildContext, String, bool) onInfoTap;
  final VoidCallback? onOtherTap;
  final Set<String> otherSelectedEquipment;

  const QuizEquipment({
    super.key,
    required this.selectedEquipment,
    required this.dumbbellCount,
    required this.kettlebellCount,
    required this.onEquipmentToggled,
    required this.onDumbbellCountChanged,
    required this.onKettlebellCountChanged,
    required this.onInfoTap,
    this.onOtherTap,
    this.otherSelectedEquipment = const {},
  });

  static const _allEquipmentIds = [
    'bodyweight',
    'dumbbells',
    'barbell',
    'resistance_bands',
    'pull_up_bar',
    'kettlebell',
    'cable_machine',
  ];

  static const _equipment = [
    {'id': 'bodyweight', 'label': 'Bodyweight Only', 'icon': Icons.accessibility_new},
    {'id': 'dumbbells', 'label': 'Dumbbells', 'icon': Icons.fitness_center, 'hasQuantity': true},
    {'id': 'barbell', 'label': 'Barbell', 'icon': Icons.line_weight},
    {'id': 'resistance_bands', 'label': 'Resistance Bands', 'icon': Icons.cable},
    {'id': 'pull_up_bar', 'label': 'Pull-up Bar', 'icon': Icons.sports_gymnastics},
    {'id': 'kettlebell', 'label': 'Kettlebell', 'icon': Icons.sports_handball, 'hasQuantity': true},
    {'id': 'cable_machine', 'label': 'Cable Machine', 'icon': Icons.settings_ethernet},
    {'id': 'full_gym', 'label': 'Full Gym Access', 'icon': Icons.store},
  ];

  bool get _hasFullGym =>
      selectedEquipment.contains('full_gym') ||
      _allEquipmentIds.every((id) => selectedEquipment.contains(id));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Total items = equipment list + "Other" option
    final totalItems = _equipment.length + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(textPrimary),
          const SizedBox(height: 8),
          _buildSubtitle(textSecondary),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: totalItems,
              itemBuilder: (context, index) {
                // Last item is "Other"
                if (index == _equipment.length) {
                  return _buildOtherCard(context, index, isDark, textPrimary, textSecondary);
                }
                final item = _equipment[index];
                return _buildEquipmentCard(context, item, index, isDark, textPrimary, textSecondary);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(Color textPrimary) {
    return Text(
      'What equipment do you have access to?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(Color textSecondary) {
    return Text(
      "Select all that apply - we'll design workouts around what you have",
      style: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEquipmentCard(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final id = item['id'] as String;
    final isFullGymOption = id == 'full_gym';
    final isSelected = isFullGymOption ? _hasFullGym : selectedEquipment.contains(id);
    final hasQuantity = item['hasQuantity'] == true;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onEquipmentToggled(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          ),
          child: Row(
            children: [
              Icon(
                item['icon'] as IconData,
                color: isSelected ? Colors.white : textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                ),
              ),
              if (hasQuantity && isSelected && !_hasFullGym)
                _buildQuantitySelector(
                  id: id,
                  context: context,
                  isDark: isDark,
                )
              else if (hasQuantity && isSelected && _hasFullGym)
                _buildFullAccessIndicator()
              else
                _buildCheckbox(isSelected, cardBorder, isDark),
            ],
          ),
        ),
      ).animate(delay: (100 + index * 50).ms).fadeIn().slideX(begin: 0.05),
    );
  }

  Widget _buildQuantitySelector({
    required String id,
    required BuildContext context,
    required bool isDark,
  }) {
    final isSingle = id == 'dumbbells' ? dumbbellCount == 1 : kettlebellCount == 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onInfoTap(context, id, isDark),
          child: Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white70,
              size: 16,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (id == 'dumbbells') {
                    onDumbbellCountChanged(1);
                  } else {
                    onKettlebellCountChanged(1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSingle ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: isSingle ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: isSingle ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 20,
                color: Colors.white24,
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (id == 'dumbbells') {
                    onDumbbellCountChanged(2);
                  } else {
                    onKettlebellCountChanged(2);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: !isSingle ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                  ),
                  child: Text(
                    '1+',
                    style: TextStyle(
                      color: !isSingle ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: !isSingle ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullAccessIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '\u221E',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isSelected, Color cardBorder, bool isDark) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        shape: BoxShape.circle,
        border: isSelected
            ? null
            : Border.all(
                color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                width: 2,
              ),
      ),
      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
    );
  }

  Widget _buildOtherCard(
    BuildContext context,
    int index,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final hasOtherSelected = otherSelectedEquipment.isNotEmpty;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onOtherTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: hasOtherSelected ? AppColors.cyanGradient : null,
            color: hasOtherSelected
                ? null
                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasOtherSelected ? AppColors.cyan : cardBorder,
              width: hasOtherSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.more_horiz,
                color: hasOtherSelected ? Colors.white : textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Other Equipment',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: hasOtherSelected ? FontWeight.w600 : FontWeight.w500,
                        color: hasOtherSelected ? Colors.white : textPrimary,
                      ),
                    ),
                    if (hasOtherSelected)
                      Text(
                        '${otherSelectedEquipment.length} selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.search,
                color: hasOtherSelected ? Colors.white70 : textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ).animate(delay: (100 + index * 50).ms).fadeIn().slideX(begin: 0.05),
    );
  }
}
