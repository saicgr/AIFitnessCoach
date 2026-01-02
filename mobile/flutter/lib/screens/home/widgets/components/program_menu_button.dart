import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/branded_program_provider.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/haptic_service.dart';
import '../edit_program_sheet.dart';

/// Settings icon button for the home screen header
/// Navigates directly to settings screen
class SettingsButton extends StatelessWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const SettingsButton({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return IconButton(
      onPressed: () {
        HapticService.light();
        context.push('/settings');
      },
      icon: Icon(
        Icons.settings_outlined,
        color: textMuted,
        size: 24,
      ),
      tooltip: 'Settings',
    );
  }
}

/// Customize Program button for the TODAY section
/// Opens the edit program sheet or shows a popup menu with options
class CustomizeProgramButton extends ConsumerStatefulWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const CustomizeProgramButton({
    super.key,
    required this.isDark,
  });

  @override
  ConsumerState<CustomizeProgramButton> createState() => _CustomizeProgramButtonState();
}

class _CustomizeProgramButtonState extends ConsumerState<CustomizeProgramButton> {
  bool _isRegenerating = false;

  @override
  Widget build(BuildContext context) {
    final elevatedColor = widget.isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = widget.isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Watch for current program name
    final currentProgramName = ref.watch(currentProgramNameProvider);
    final displayText = _isRegenerating
        ? 'Regenerating...'
        : currentProgramName ?? 'Program';

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _isRegenerating ? null : () => _showProgramMenu(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          constraints: const BoxConstraints(maxWidth: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isRegenerating)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cyan,
                  ),
                )
              else
                Icon(
                  currentProgramName != null ? Icons.fitness_center : Icons.tune,
                  size: 14,
                  color: AppColors.cyan,
                ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isRegenerating ? textMuted : AppColors.cyan,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (!_isRegenerating) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: AppColors.cyan,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showProgramMenu(BuildContext context) {
    HapticService.light();
    final isDark = widget.isDark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center, color: AppColors.cyan, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Program Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Customize your workout program or regenerate with current settings.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Reset Option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _quickRegenerate();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.refresh,
                              color: AppColors.orange,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Regenerate This Week',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Get fresh workouts with your current settings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Customize Program Option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditProgramSheet(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.tune,
                              color: AppColors.purple,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customize Program',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Change days, equipment, difficulty, and more',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Browse Programs Option
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/programs');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.explore,
                              color: AppColors.cyan,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Browse Programs',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Try celebrity workouts, sport training & more',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickRegenerate() async {
    HapticService.medium();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return AlertDialog(
          backgroundColor: elevatedColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.refresh, color: AppColors.orange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Regenerate Workouts?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This will delete your upcoming incomplete workouts and generate fresh ones using your current program settings.\n\nCompleted workouts will NOT be affected.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Regenerate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isRegenerating = true);

    try {
      final repo = ref.read(workoutRepositoryProvider);
      final userId = await ref.read(apiClientProvider).getUserId();

      if (userId == null) {
        if (mounted) {
          setState(() => _isRegenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to regenerate workouts'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Step 1: Call the quick regenerate endpoint to clear old workouts
      final result = await repo.quickRegenerateWorkouts();

      if (result['success'] != true) {
        if (mounted) {
          setState(() => _isRegenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to clear workouts'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Step 2: Get user's current preferences for workout generation
      final prefs = await repo.getProgramPreferences(userId);

      // Convert day names to indices (0=Mon, 6=Sun)
      const dayNameToIndex = {
        'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3,
        'Friday': 4, 'Saturday': 5, 'Sunday': 6,
        'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3,
        'Fri': 4, 'Sat': 5, 'Sun': 6,
      };
      List<int> selectedDays;
      if (prefs?.workoutDays.isNotEmpty == true) {
        selectedDays = prefs!.workoutDays
            .map((name) => dayNameToIndex[name] ?? 0)
            .toList();
      } else {
        selectedDays = [0, 2, 4]; // Mon, Wed, Fri default
      }
      final durationMinutes = prefs?.durationMinutes ?? 45;

      // Step 3: Generate new workouts using streaming
      int generatedCount = 0;
      await for (final progress in repo.generateMonthlyWorkoutsStreaming(
        userId: userId,
        selectedDays: selectedDays,
        durationMinutes: durationMinutes,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          setState(() => _isRegenerating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${progress.message}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (progress.isCompleted) {
          generatedCount = progress.workouts.length;
          break;
        }
      }

      if (mounted) {
        setState(() => _isRegenerating = false);
        HapticService.success();

        // Refresh workouts and invalidate to force UI rebuild
        await ref.read(workoutsProvider.notifier).refresh();
        ref.invalidate(workoutsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Generated $generatedCount fresh workouts!',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showEditProgramSheet(BuildContext context) async {
    final result = await showEditProgramSheet(context, ref);

    if (result == true && context.mounted) {
      // Small delay to ensure database transaction completes
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh workouts after program update and invalidate to force UI rebuild
      await ref.read(workoutsProvider.notifier).refresh();
      ref.invalidate(workoutsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Program updated! Your new workouts are ready.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

/// My Space button for the TODAY section
/// Opens the layout editor to customize home screen tiles
class MySpaceButton extends StatelessWidget {
  /// Whether the current theme is dark
  final bool isDark;

  const MySpaceButton({
    super.key,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/settings/homescreen');
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.purple.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                size: 14,
                color: AppColors.purple,
              ),
              const SizedBox(width: 6),
              Text(
                'My Space',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// @deprecated Use [MySpaceButton] instead
typedef EditHomescreenButton = MySpaceButton;

/// @deprecated Use [SettingsButton] and [CustomizeProgramButton] instead
/// Kept for backwards compatibility
typedef ProgramMenuButton = SettingsButton;
