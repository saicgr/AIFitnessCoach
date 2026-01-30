import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Workout environment options for quick selection
class _WorkoutEnvironmentOption {
  final String id;
  final String label;
  final String emoji;
  final String description;
  final List<String> defaultEquipment;

  const _WorkoutEnvironmentOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
    required this.defaultEquipment,
  });
}

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
  final String? selectedEnvironment;
  final ValueChanged<String>? onEnvironmentChanged;

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
    this.selectedEnvironment,
    this.onEnvironmentChanged,
  });

  static const _environments = [
    _WorkoutEnvironmentOption(
      id: 'commercial_gym',
      label: 'Gym',
      emoji: '🏢',
      description: 'Full gym with machines, cables, and free weights',
      defaultEquipment: ['full_gym'],
    ),
    _WorkoutEnvironmentOption(
      id: 'home',
      label: 'Home',
      emoji: '🏡',
      description: 'Minimal equipment - bodyweight, bands, mat',
      defaultEquipment: ['bodyweight', 'resistance_bands'],
    ),
    _WorkoutEnvironmentOption(
      id: 'home_gym',
      label: 'Home Gym',
      emoji: '🏠',
      description: 'Dedicated space with dumbbells, barbell, bench',
      defaultEquipment: ['bodyweight', 'dumbbells', 'barbell', 'resistance_bands', 'pull_up_bar', 'kettlebell'],
    ),
    _WorkoutEnvironmentOption(
      id: 'hotel',
      label: 'Hotel',
      emoji: '🧳',
      description: 'Travel-friendly - dumbbells, cardio machines',
      defaultEquipment: ['bodyweight', 'dumbbells', 'resistance_bands'],
    ),
  ];

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
    {'id': 'full_gym', 'label': 'Full Gym Access', 'icon': Icons.store},
    {'id': 'bodyweight', 'label': 'Bodyweight Only', 'icon': Icons.accessibility_new},
    {'id': 'dumbbells', 'label': 'Dumbbells', 'icon': Icons.fitness_center, 'hasQuantity': true},
    {'id': 'barbell', 'label': 'Barbell', 'icon': Icons.line_weight},
    {'id': 'resistance_bands', 'label': 'Resistance Bands', 'icon': Icons.cable},
    {'id': 'pull_up_bar', 'label': 'Pull-up Bar', 'icon': Icons.sports_gymnastics},
    {'id': 'kettlebell', 'label': 'Kettlebell', 'icon': Icons.sports_handball, 'hasQuantity': true},
    {'id': 'cable_machine', 'label': 'Cable Machine', 'icon': Icons.settings_ethernet},
  ];

  bool get _hasFullGym =>
      selectedEquipment.contains('full_gym') ||
      _allEquipmentIds.every((id) => selectedEquipment.contains(id));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use stronger, more visible colors with proper contrast
    final textPrimary = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textSecondary = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    // Total items = equipment list + "Other" option
    final totalItems = _equipment.length + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(textPrimary),
          const SizedBox(height: 6),
          _buildSubtitle(textSecondary),
          const SizedBox(height: 12),
          // Environment quick selection chips
          if (onEnvironmentChanged != null) ...[
            _buildEnvironmentSection(context, isDark, textPrimary, textSecondary),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
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

  Widget _buildEnvironmentSection(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Where do you workout?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showEnvironmentInfo(context, isDark),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.accent,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _environments.map((env) {
              final isSelected = selectedEnvironment == env.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onEnvironmentChanged?.call(env.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
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
                            ? AppColors.accent
                            : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          env.emoji,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          env.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 200.ms),
        if (selectedEnvironment != null) ...[
          const SizedBox(height: 8),
          Text(
            _environments.firstWhere((e) => e.id == selectedEnvironment).description,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(),
        ],
      ],
    );
  }

  void _showEnvironmentInfo(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 16),
              Text(
                'Workout Environment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Selecting your workout environment helps us recommend the right exercises and equipment for your setup.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              ..._environments.map((env) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(env.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            env.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppColorsLight.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            env.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
              Text(
                'You can customize equipment after selecting an environment, or skip this and select equipment manually.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(Color textPrimary) {
    return Text(
      'What equipment do you have access to?',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.2,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(Color textSecondary) {
    return Text(
      "Select all that apply - we'll design workouts around what you have",
      style: TextStyle(
        fontSize: 13,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onEquipmentToggled(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                  ? LinearGradient(
                      colors: [AppColors.orange, AppColors.orange.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            color: isSelected
                ? null
                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.orange : cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                item['icon'] as IconData,
                color: isSelected ? Colors.white : textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
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
      width: 22,
      height: 22,
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
      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onOtherTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: hasOtherSelected ? AppColors.accentGradient : null,
            color: hasOtherSelected
                ? null
                : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasOtherSelected ? AppColors.accent : cardBorder,
              width: hasOtherSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.more_horiz,
                color: hasOtherSelected ? Colors.white : textSecondary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Other Equipment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hasOtherSelected ? FontWeight.w600 : FontWeight.w500,
                        color: hasOtherSelected ? Colors.white : textPrimary,
                      ),
                    ),
                    if (hasOtherSelected)
                      Text(
                        '${otherSelectedEquipment.length} selected',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.search,
                color: hasOtherSelected ? Colors.white70 : textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ).animate(delay: (100 + index * 50).ms).fadeIn().slideX(begin: 0.05),
    );
  }
}
