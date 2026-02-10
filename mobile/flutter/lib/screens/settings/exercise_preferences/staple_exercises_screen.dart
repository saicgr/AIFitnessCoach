import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/staples_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/repositories/exercise_preferences_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/exercise_image.dart';
import '../../library/components/exercise_detail_sheet.dart';
import 'widgets/exercise_picker_sheet.dart';

/// Screen for managing staple exercises (core lifts that never rotate)
class StapleExercisesScreen extends ConsumerWidget {
  const StapleExercisesScreen({super.key});

  Future<void> _showAddExercisePicker(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();

    final staplesState = ref.read(staplesProvider);
    final excludeNames = staplesState.staples
        .map((s) => s.exerciseName.toLowerCase())
        .toSet();

    final result = await showExercisePickerSheet(
      context,
      ref,
      type: ExercisePickerType.staple,
      excludeExercises: excludeNames,
    );

    if (result != null && context.mounted) {
      // Show choice sheet before saving
      final choice = await _showStapleChoiceSheet(context);
      if (choice == null) return; // Cancelled

      final success = await ref.read(staplesProvider.notifier).addStaple(
        result.exerciseName,
        libraryId: result.exerciseId,
        muscleGroup: result.muscleGroup,
        reason: result.reason,
        addToCurrentWorkout: choice.addToday,
        section: choice.section,
        gymProfileId: choice.gymProfileId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Added "${result.exerciseName}" as a staple'
                  : 'Failed to add exercise',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<({bool addToday, String section, String? gymProfileId})?> _showStapleChoiceSheet(
    BuildContext context,
  ) async {
    return showModalBottomSheet<({bool addToday, String section, String? gymProfileId})>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _StapleChoiceSheet(
        onCancel: () async {
          // Show discard confirmation
          final discard = await showDialog<bool>(
            context: sheetContext,
            builder: (dialogContext) {
              final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
              return AlertDialog(
                backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
                title: const Text('Discard selection?'),
                content: const Text(
                  'Your exercise won\'t be saved as a staple.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(
                      'Discard',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              );
            },
          );
          if (discard == true && sheetContext.mounted) {
            Navigator.pop(sheetContext); // Pop the choice sheet, returns null
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final staplesState = ref.watch(staplesProvider);

    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main content with top padding for floating header
          Padding(
            padding: EdgeInsets.only(top: topPad + 60),
            child: staplesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : staplesState.staples.isEmpty
                    ? _buildEmptyState(context, ref, textMuted)
                    : _buildStaplesList(
                        context,
                        ref,
                        staplesState.staples,
                        isDark,
                        textPrimary,
                        textMuted,
                        elevated,
                      ),
          ),

          // Floating header row
          Positioned(
            top: topPad + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Floating back button
                _buildFloatingButton(
                  icon: Icons.arrow_back,
                  onTap: () => context.pop(),
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: textPrimary,
                  cardBorder: cardBorder,
                ),
                const Spacer(),
                // Title
                Text(
                  'Staple Exercises',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                // Floating add button
                _buildFloatingButton(
                  icon: Icons.add,
                  onTap: staplesState.isRegenerating
                      ? null
                      : () => _showAddExercisePicker(context, ref),
                  isDark: isDark,
                  elevated: elevated,
                  textPrimary: AppColors.cyan,
                  cardBorder: cardBorder,
                ),
              ],
            ),
          ),

          // Regeneration overlay
          if (staplesState.isRegenerating)
            _buildRegenerationOverlay(context, staplesState.regenerationMessage, isDark),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required bool isDark,
    required Color elevated,
    required Color textPrimary,
    required Color cardBorder,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticService.light();
              onTap();
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: onTap != null
                  ? textPrimary
                  : textPrimary.withValues(alpha: 0.3),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegenerationOverlay(BuildContext context, String? message, bool isDark) {
    return Container(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
            const SizedBox(height: 24),
            Text(
              'Regenerating Workouts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message ?? 'Adding staple to upcoming workouts...',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This may take a moment',
              style: TextStyle(
                fontSize: 12,
                color: (isDark ? AppColors.textMuted : AppColorsLight.textMuted)
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, Color textMuted) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 72,
              color: textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Staple Exercises',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Staple exercises are your core lifts that will NEVER be rotated out of your workouts.',
              style: TextStyle(
                fontSize: 14,
                color: textMuted.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddExercisePicker(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Staple'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaplesList(
    BuildContext context,
    WidgetRef ref,
    List<StapleExercise> staples,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
  ) {
    final profileCount = ref.read(gymProfilesProvider).valueOrNull?.length ?? 1;

    return Column(
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock,
                color: AppColors.cyan,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These core lifts will NEVER be rotated out of your workouts, regardless of your variety setting.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Staples list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: staples.length,
            itemBuilder: (context, index) {
              final staple = staples[index];
              return _StapleExerciseTile(
                staple: staple,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                elevated: elevated,
                showProfileBadge: profileCount >= 2,
                onRemove: () async {
                  HapticFeedback.lightImpact();
                  final confirmed = await _showRemoveDialog(
                    context,
                    staple.exerciseName,
                    isDark,
                  );
                  if (confirmed == true) {
                    ref
                        .read(staplesProvider.notifier)
                        .removeStaple(staple.id);
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<bool?> _showRemoveDialog(
    BuildContext context,
    String exerciseName,
    bool isDark,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.elevated,
        title: const Text('Remove Staple?'),
        content: Text(
          'Remove "$exerciseName" from your staples? This exercise may be rotated out in future workouts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StapleExerciseTile extends StatelessWidget {
  final StapleExercise staple;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color elevated;
  final bool showProfileBadge;
  final VoidCallback onRemove;

  const _StapleExerciseTile({
    required this.staple,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.elevated,
    this.showProfileBadge = false,
    required this.onRemove,
  });

  void _showDetail(BuildContext context) {
    final libraryExercise = LibraryExercise(
      id: staple.libraryId,
      nameValue: staple.exerciseName,
      bodyPart: staple.bodyPart,
      equipmentValue: staple.equipment,
      gifUrl: staple.gifUrl,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseDetailSheet(exercise: libraryExercise),
    );
  }

  Color _badgeColor(String? reason) {
    switch (reason) {
      case 'core_compound':
        return AppColors.cyan;
      case 'favorite':
        return Colors.redAccent;
      case 'rehab':
        return Colors.green;
      case 'strength_focus':
        return Colors.orange;
      default:
        return AppColors.cyan;
    }
  }

  IconData _badgeIcon(String? reason) {
    switch (reason) {
      case 'core_compound':
        return Icons.fitness_center;
      case 'favorite':
        return Icons.favorite;
      case 'rehab':
        return Icons.healing;
      case 'strength_focus':
        return Icons.trending_up;
      default:
        return Icons.lock;
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(staple.reason);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: isDark ? null : Border.all(color: AppColorsLight.cardBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showDetail(context),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ExerciseImage(
                exerciseName: staple.exerciseName,
                width: 56,
                height: 56,
                borderRadius: 12,
              ),
              // Play icon overlay to indicate tappable for video
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              // Reason badge
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: elevated, width: 1.5),
                  ),
                  child: Icon(_badgeIcon(staple.reason), color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          staple.exerciseName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section badge + muscle group row
            Row(
              children: [
                if (staple.section != 'main')
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: staple.section == 'warmup'
                            ? Colors.orange.withValues(alpha: 0.15)
                            : Colors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        staple.section == 'warmup' ? 'Warmup' : 'Stretch',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: staple.section == 'warmup' ? Colors.orange : Colors.teal,
                        ),
                      ),
                    ),
                  ),
                if (staple.muscleGroup != null)
                  Flexible(
                    child: Text(
                      staple.muscleGroup!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            if (staple.isCardioEquipment)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  staple.cardioParamsDisplay,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (staple.reason != null)
              Text(
                _formatReason(staple.reason!),
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            if (showProfileBadge && (staple.gymProfileName != null || staple.gymProfileId == null))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: staple.gymProfileColor != null
                            ? _parseColor(staple.gymProfileColor!)
                            : textMuted.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      staple.gymProfileName ?? 'All Profiles',
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: textMuted),
          onPressed: onRemove,
        ),
      ),
    );
  }

  String _formatReason(String reason) {
    switch (reason) {
      case 'core_compound':
        return 'Core Compound';
      case 'favorite':
        return 'Personal Favorite';
      case 'rehab':
        return 'Rehab / Recovery';
      case 'strength_focus':
        return 'Strength Focus';
      default:
        return reason.replaceAll('_', ' ').split(' ').map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
  }
}

/// Bottom sheet for choosing when a staple exercise should apply
class _StapleChoiceSheet extends ConsumerStatefulWidget {
  final VoidCallback onCancel;

  const _StapleChoiceSheet({required this.onCancel});

  @override
  ConsumerState<_StapleChoiceSheet> createState() => _StapleChoiceSheetState();
}

class _StapleChoiceSheetState extends ConsumerState<_StapleChoiceSheet> {
  String _selectedSection = 'main';
  String? _selectedProfileId;
  bool _profileIdInitialized = false;

  static const _sections = [
    ('main', 'Main'),
    ('warmup', 'Warmup'),
    ('stretches', 'Stretch'),
  ];

  Color _parseChipColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    final profiles = ref.watch(gymProfilesProvider).valueOrNull ?? [];
    final activeProfile = ref.watch(activeGymProfileProvider);

    // Initialize selected profile ID to active profile on first build
    if (!_profileIdInitialized && activeProfile != null) {
      _selectedProfileId = activeProfile.id;
      _profileIdInitialized = true;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Gym profile picker (only show if 2+ profiles)
          if (profiles.length >= 2) ...[
            Text(
              'Which gym profile?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // "All Profiles" chip
                  GestureDetector(
                    onTap: () {
                      HapticService.light();
                      setState(() => _selectedProfileId = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedProfileId == null
                            ? textMuted.withValues(alpha: 0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedProfileId == null
                              ? textMuted.withValues(alpha: 0.5)
                              : textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'All Profiles',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedProfileId == null
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _selectedProfileId == null
                              ? textPrimary
                              : textMuted,
                        ),
                      ),
                    ),
                  ),
                  // Profile chips
                  ...profiles.map((profile) {
                    final isSelected = _selectedProfileId == profile.id;
                    final chipColor = _parseChipColor(profile.color);
                    return GestureDetector(
                      onTap: () {
                        HapticService.light();
                        setState(() => _selectedProfileId = profile.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? chipColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? chipColor
                                : textMuted.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          profile.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : textMuted,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Title
          Text(
            'When should this apply?',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Option 1: Add to today's workout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                HapticService.light();
                Navigator.pop(
                  context,
                  (addToday: true, section: _selectedSection, gymProfileId: _selectedProfileId),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          color: AppColors.cyan,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add to today\'s workout',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Section chips
                    Row(
                      children: _sections.map((entry) {
                        final (value, label) = entry;
                        final isSelected = _selectedSection == value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              HapticService.light();
                              setState(() => _selectedSection = value);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.cyan
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.cyan
                                      : textMuted.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? Colors.white
                                      : textMuted,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option 2: Start from next workout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                HapticService.light();
                Navigator.pop(
                  context,
                  (addToday: false, section: _selectedSection, gymProfileId: _selectedProfileId),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.skip_next,
                      color: textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start from next workout',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current workout unchanged',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cancel button
          TextButton(
            onPressed: widget.onCancel,
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                color: textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
