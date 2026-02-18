import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';

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
  final bool showHeader;

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
    this.showHeader = true,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            _buildTitle(textPrimary),
            const SizedBox(height: 6),
            _buildSubtitle(textSecondary),
            const SizedBox(height: 12),
          ],
          // Environment quick selection chips
          if (onEnvironmentChanged != null) ...[
            _buildEnvironmentSection(context, isDark, textPrimary, textSecondary),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._equipment.map((item) =>
                        _buildEquipmentChip(context, item, isDark, textPrimary, textSecondary),
                      ),
                      _buildOtherChip(context, isDark, textPrimary, textSecondary),
                    ],
                  ),
                  // Quantity selectors shown below the grid when applicable
                  if (selectedEquipment.contains('dumbbells') && !_hasFullGym) ...[
                    const SizedBox(height: 12),
                    _QuantityRow(
                      label: 'Dumbbells',
                      isSingle: dumbbellCount == 1,
                      onSingle: () => onDumbbellCountChanged(1),
                      onMultiple: () => onDumbbellCountChanged(2),
                      onInfo: () => onInfoTap(context, 'dumbbells', isDark),
                      isDark: isDark,
                    ),
                  ],
                  if (selectedEquipment.contains('kettlebell') && !_hasFullGym) ...[
                    const SizedBox(height: 8),
                    _QuantityRow(
                      label: 'Kettlebell',
                      isSingle: kettlebellCount == 1,
                      onSingle: () => onKettlebellCountChanged(1),
                      onMultiple: () => onKettlebellCountChanged(2),
                      onInfo: () => onInfoTap(context, 'kettlebell', isDark),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
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
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

  Widget _buildEquipmentChip(
    BuildContext context,
    Map<String, dynamic> item,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final id = item['id'] as String;
    final isFullGymOption = id == 'full_gym';
    final isSelected = isFullGymOption ? _hasFullGym : selectedEquipment.contains(id);
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: (MediaQuery.of(context).size.width - 48 - 8) / 2, // 2 columns with spacing
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onEquipmentToggled(id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item['icon'] as IconData,
                color: isSelected ? Colors.white : textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
                          width: 1.5,
                        ),
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherChip(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final hasOtherSelected = otherSelectedEquipment.isNotEmpty;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: (MediaQuery.of(context).size.width - 48 - 8) / 2,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onOtherTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.more_horiz,
                color: hasOtherSelected ? Colors.white : textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hasOtherSelected
                      ? 'Other (${otherSelectedEquipment.length})'
                      : 'Other Equipment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: hasOtherSelected ? FontWeight.w600 : FontWeight.w500,
                    color: hasOtherSelected ? Colors.white : textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.search,
                color: hasOtherSelected ? Colors.white70 : textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact quantity toggle row shown below the chip grid
class _QuantityRow extends StatelessWidget {
  final String label;
  final bool isSingle;
  final VoidCallback onSingle;
  final VoidCallback onMultiple;
  final VoidCallback onInfo;
  final bool isDark;

  const _QuantityRow({
    required this.label,
    required this.isSingle,
    required this.onSingle,
    required this.onMultiple,
    required this.onInfo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final mutedColor = isDark ? const Color(0xFFD4D4D8) : const Color(0xFF52525B);

    return Row(
      children: [
        Icon(Icons.fitness_center, size: 16, color: mutedColor),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.orange.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSingle();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSingle ? AppColors.orange : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                  ),
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: isSingle ? Colors.white : mutedColor,
                      fontSize: 13,
                      fontWeight: isSingle ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 18,
                color: AppColors.orange.withOpacity(0.3),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onMultiple();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: !isSingle ? AppColors.orange : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                  ),
                  child: Text(
                    '1+',
                    style: TextStyle(
                      color: !isSingle ? Colors.white : mutedColor,
                      fontSize: 13,
                      fontWeight: !isSingle ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onInfo,
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}
