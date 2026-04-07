import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';
import 'onboarding_theme.dart';

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

/// Follow-up suggestion shown after selecting certain equipment
class _FollowUp {
  final String suggest;
  final String title;
  final String subtitle;

  const _FollowUp({
    required this.suggest,
    required this.title,
    required this.subtitle,
  });
}

/// Equipment selection widget for quiz screens.
class QuizEquipment extends StatefulWidget {
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
      emoji: '\u{1F3E2}',
      description: 'Full gym with machines, cables, and free weights',
      defaultEquipment: ['full_gym'],
    ),
    _WorkoutEnvironmentOption(
      id: 'home',
      label: 'Home',
      emoji: '\u{1F3E1}',
      description: 'Minimal equipment - bodyweight, mat',
      defaultEquipment: ['bodyweight'],
    ),
    _WorkoutEnvironmentOption(
      id: 'home_gym',
      label: 'Home Gym',
      emoji: '\u{1F3E0}',
      description: 'Dedicated space with dumbbells, barbell, bench',
      defaultEquipment: ['bodyweight', 'dumbbells', 'barbell', 'resistance_bands', 'pull_up_bar', 'kettlebell'],
    ),
    _WorkoutEnvironmentOption(
      id: 'hotel',
      label: 'Hotel',
      emoji: '\u{1F9F3}',
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
    'bench',
    'squat_rack',
    'medicine_ball',
    'trx',
  ];

  static const _equipment = [
    {'id': 'full_gym', 'label': 'Full Gym Access', 'icon': Icons.store},
    {'id': 'bodyweight', 'label': 'Bodyweight Only', 'icon': Icons.accessibility_new},
    {'id': 'dumbbells', 'label': 'Dumbbells', 'icon': Icons.fitness_center, 'hasQuantity': true},
    {'id': 'barbell', 'label': 'Barbell', 'icon': Icons.line_weight},
    {'id': 'bench', 'label': 'Flat Bench', 'icon': Icons.weekend, 'subtitle': 'Enables chest press, rows & more'},
    {'id': 'squat_rack', 'label': 'Squat Rack', 'icon': Icons.fitness_center, 'subtitle': 'Needed for barbell squats & press'},
    {'id': 'resistance_bands', 'label': 'Resistance Bands', 'icon': Icons.cable},
    {'id': 'pull_up_bar', 'label': 'Pull-up Bar', 'icon': Icons.sports_gymnastics},
    {'id': 'kettlebell', 'label': 'Kettlebell', 'icon': Icons.sports_handball, 'hasQuantity': true},
    {'id': 'cable_machine', 'label': 'Cable Machine', 'icon': Icons.settings_ethernet},
    {'id': 'medicine_ball', 'label': 'Medicine Ball', 'icon': Icons.circle},
    {'id': 'trx', 'label': 'TRX / Suspension', 'icon': Icons.swap_vert},
  ];

  /// Follow-up suggestions: selecting a primary equipment suggests a secondary
  static const _equipmentFollowUps = {
    'dumbbells': _FollowUp(
      suggest: 'bench',
      title: 'Do you have a weight bench?',
      subtitle: 'Unlocks: Bench Press, Incline Press, Pullover, Chest-Supported Rows',
    ),
    'kettlebell': _FollowUp(
      suggest: 'bench',
      title: 'Do you have a weight bench?',
      subtitle: 'Unlocks: Chest-Supported KB Row, KB Floor Press alternatives',
    ),
    'barbell': _FollowUp(
      suggest: 'squat_rack',
      title: 'Do you have a squat rack?',
      subtitle: 'Required for: Barbell Squat, Overhead Press, Barbell Bench Press',
    ),
  };

  @override
  State<QuizEquipment> createState() => _QuizEquipmentState();
}

class _QuizEquipmentState extends State<QuizEquipment> {
  final _shownFollowUps = <String>{};

  bool get _hasFullGym =>
      widget.selectedEquipment.contains('full_gym') ||
      QuizEquipment._allEquipmentIds.every((id) => widget.selectedEquipment.contains(id));

  /// Check if a chip should show the "Recommended" badge
  bool _isRecommended(String chipId) {
    if (_hasFullGym || widget.selectedEquipment.contains(chipId)) return false;
    for (final entry in QuizEquipment._equipmentFollowUps.entries) {
      if (entry.value.suggest == chipId && widget.selectedEquipment.contains(entry.key)) {
        return true;
      }
    }
    return false;
  }

  void _handleChipTap(String id) {
    HapticFeedback.selectionClick();
    final wasSelected = widget.selectedEquipment.contains(id);
    widget.onEquipmentToggled(id);
    // After toggling ON, check for follow-up
    if (!wasSelected) {
      _checkFollowUp(context, id);
    }
  }

  void _checkFollowUp(BuildContext context, String itemId) {
    final followUp = QuizEquipment._equipmentFollowUps[itemId];
    if (followUp == null) return;
    if (widget.selectedEquipment.contains(followUp.suggest)) return;
    if (_hasFullGym) return;
    if (_shownFollowUps.contains(itemId)) return;
    _shownFollowUps.add(itemId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showFollowUpDialog(context, followUp);
    });
  }

  void _showFollowUpDialog(BuildContext context, _FollowUp followUp) {
    final t = OnboardingTheme.of(context);
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
                  followUp.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  followUp.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: t.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: t.cardFill,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: t.borderDefault),
                          ),
                          child: Center(
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: t.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          widget.onEquipmentToggled(followUp.suggest);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: t.selectionAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'Yes, Add It',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            _buildTitle(t),
            const SizedBox(height: 6),
            _buildSubtitle(t),
            const SizedBox(height: 12),
          ],
          // Environment quick selection chips
          if (widget.onEnvironmentChanged != null) ...[
            _buildEnvironmentSection(context, t),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTwoColumnGrid(context, t),
                  // Quantity selectors shown below the grid when applicable
                  if (widget.selectedEquipment.contains('dumbbells') && !_hasFullGym) ...[
                    const SizedBox(height: 12),
                    _QuantityRow(
                      label: 'Dumbbells',
                      isSingle: widget.dumbbellCount == 1,
                      onSingle: () => widget.onDumbbellCountChanged(1),
                      onMultiple: () => widget.onDumbbellCountChanged(2),
                      onInfo: () => widget.onInfoTap(context, 'dumbbells', true),
                      icon: Icons.fitness_center,
                    ),
                  ],
                  if (widget.selectedEquipment.contains('kettlebell') && !_hasFullGym) ...[
                    const SizedBox(height: 8),
                    _QuantityRow(
                      label: 'Kettlebell',
                      isSingle: widget.kettlebellCount == 1,
                      onSingle: () => widget.onKettlebellCountChanged(1),
                      onMultiple: () => widget.onKettlebellCountChanged(2),
                      onInfo: () => widget.onInfoTap(context, 'kettlebell', true),
                      icon: Icons.sports_handball,
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

  Widget _buildEnvironmentSection(BuildContext context, OnboardingTheme t) {
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
                color: t.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _showEnvironmentInfo(context, t),
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: t.textMuted,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: QuizEquipment._environments.map((env) {
              final isSelected = widget.selectedEnvironment == env.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onEnvironmentChanged?.call(env.id);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                color: t.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ).animate().fadeIn(delay: 200.ms),
        if (widget.selectedEnvironment != null) ...[
          const SizedBox(height: 8),
          Text(
            QuizEquipment._environments.firstWhere((e) => e.id == widget.selectedEnvironment).description,
            style: TextStyle(
              fontSize: 12,
              color: t.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(),
        ],
      ],
    );
  }

  void _showEnvironmentInfo(BuildContext context, OnboardingTheme t) {
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
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Selecting your workout environment helps us recommend the right exercises and equipment for your setup.',
                style: TextStyle(
                  fontSize: 14,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ...QuizEquipment._environments.map((env) => Padding(
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
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            env.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: t.textSecondary,
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
                  color: t.textSecondary,
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

  Widget _buildTitle(OnboardingTheme t) {
    return Text(
      'What equipment do you have access to?',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: t.textPrimary,
        height: 1.2,
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05);
  }

  Widget _buildSubtitle(OnboardingTheme t) {
    return Text(
      "Select all that apply - we'll design workouts around what you have",
      style: TextStyle(
        fontSize: 13,
        color: t.textSecondary,
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildTwoColumnGrid(BuildContext context, OnboardingTheme t) {
    final chips = [
      ...QuizEquipment._equipment.map((item) =>
        _buildEquipmentChip(context, item, t),
      ),
      _buildOtherChip(context, t),
    ];

    final rows = <Widget>[];
    for (int i = 0; i < chips.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 8));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: chips[i]),
              const SizedBox(width: 8),
              i + 1 < chips.length
                  ? Expanded(child: chips[i + 1])
                  : const Expanded(child: SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildEquipmentChip(
    BuildContext context,
    Map<String, dynamic> item,
    OnboardingTheme t,
  ) {
    final id = item['id'] as String;
    final isFullGymOption = id == 'full_gym';
    final isSelected = isFullGymOption ? _hasFullGym : widget.selectedEquipment.contains(id);
    final subtitle = item['subtitle'] as String?;
    final recommended = _isRecommended(id);

    return GestureDetector(
        onTap: () => _handleChipTap(id),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: t.cardSelectedGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : t.cardFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? t.borderSelected
                          : recommended
                              ? t.checkBorderUnselected
                              : t.borderDefault,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: t.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: t.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: t.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? t.checkBg : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: t.borderDefault,
                                  width: 1.5,
                                ),
                        ),
                        child: isSelected ? Icon(Icons.check, color: t.checkIcon, size: 13) : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // "Recommended" badge
            if (recommended)
              Positioned(
                top: -6,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.badgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: t.selectionAccent.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: t.badgeText,
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildOtherChip(BuildContext context, OnboardingTheme t) {
    final hasOtherSelected = widget.otherSelectedEquipment.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onOtherTap?.call();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: hasOtherSelected
                  ? LinearGradient(
                      colors: t.cardSelectedGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasOtherSelected ? null : t.cardFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasOtherSelected ? t.borderSelected : t.borderDefault,
                width: hasOtherSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(
                  Icons.more_horiz,
                  color: hasOtherSelected ? t.textPrimary : t.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    hasOtherSelected
                        ? 'Other (${widget.otherSelectedEquipment.length})'
                        : 'Other Equipment',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasOtherSelected ? FontWeight.w600 : FontWeight.w500,
                      color: t.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.search,
                  color: t.textSecondary,
                  size: 16,
                ),
              ],
            ),
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
  final IconData icon;

  const _QuantityRow({
    required this.label,
    required this.isSingle,
    required this.onSingle,
    required this.onMultiple,
    required this.onInfo,
    this.icon = Icons.fitness_center,
  });

  @override
  Widget build(BuildContext context) {
    final t = OnboardingTheme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: t.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: t.cardFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: t.borderDefault,
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
                        color: isSingle ? t.checkBg : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                      ),
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: isSingle ? t.textPrimary : t.textSecondary,
                          fontSize: 13,
                          fontWeight: isSingle ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: t.borderDefault,
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onMultiple();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: !isSingle ? t.checkBg : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                      ),
                      child: Text(
                        '1+',
                        style: TextStyle(
                          color: !isSingle ? t.textPrimary : t.textSecondary,
                          fontSize: 13,
                          fontWeight: !isSingle ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onInfo,
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: t.textMuted,
          ),
        ),
      ],
    );
  }
}
