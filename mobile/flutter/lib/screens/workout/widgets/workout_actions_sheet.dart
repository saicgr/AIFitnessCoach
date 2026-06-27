import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/workout_mutation_coordinator.dart';
import '../../../widgets/app_dialog.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/models/workout.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/providers/workout_studio_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:fitwiz/core/constants/branding.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Shows a bottom sheet with workout actions.
///
/// The base action set (Reschedule, Regenerate, Version history, Generate
/// warm-up, Generate stretches, Share-when-completed, Delete) is always
/// rendered. The Quick-group affordances (Mark as done, Shuffle, View details,
/// Skip) are OPT-IN via the flags below so callers that don't want them — or
/// that drive them through their own navigation — stay unaffected. This single
/// sheet is shared by the workout-detail "⋯" menu and the home hero-card "⋯"
/// menu so the two can't drift in parity.
///
/// [showMarkDone] / [showShuffle] / [showSkip] are handled internally (they
/// call the same repository / studio-service / completion endpoint the detail
/// screen uses). [onViewDetails], when provided, adds a "View details" tile
/// that pops the sheet and invokes the callback — the sheet itself stays
/// navigation-agnostic so it doesn't need a router import.
Future<void> showWorkoutActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Workout workout, {
  VoidCallback? onRefresh,
  bool showMarkDone = false,
  bool showShuffle = false,
  bool showSkip = false,
  VoidCallback? onViewDetails,
}) async {
  await showGlassSheet(
    context: context,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _WorkoutActionsSheet(
        workout: workout,
        onRefresh: onRefresh,
        showMarkDone: showMarkDone,
        showShuffle: showShuffle,
        showSkip: showSkip,
        onViewDetails: onViewDetails,
      ),
    ),
  );
}

class _WorkoutActionsSheet extends ConsumerStatefulWidget {
  final Workout workout;
  final VoidCallback? onRefresh;
  final bool showMarkDone;
  final bool showShuffle;
  final bool showSkip;
  final VoidCallback? onViewDetails;

  const _WorkoutActionsSheet({
    required this.workout,
    this.onRefresh,
    this.showMarkDone = false,
    this.showShuffle = false,
    this.showSkip = false,
    this.onViewDetails,
  });

  @override
  ConsumerState<_WorkoutActionsSheet> createState() =>
      _WorkoutActionsSheetState();
}

class _WorkoutActionsSheetState extends ConsumerState<_WorkoutActionsSheet> {
  bool _isLoading = false;
  String? _loadingAction;

  // Streaming progress state for regeneration
  int _regenerateStep = 0;
  int _regenerateTotalSteps = 4;
  String _regenerateMessage = '';

  /// Whether the workout already counts as completed — hides "Mark as done".
  bool get _alreadyDone => widget.workout.isCompleted == true;

  /// True when any Quick-group affordance is shown; drives the section labels
  /// (we only label "Quick"/"Options" when the menu is the fuller parity menu).
  bool get _hasQuickGroup =>
      (widget.showMarkDone && !_alreadyDone) ||
      widget.showShuffle ||
      widget.onViewDetails != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final cardBorder = isDark
        ? AppColors.cardBorder
        : AppColorsLight.cardBorder;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(
                          context,
                        ).workoutActionsWorkoutOptions,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.workout.name ??
                            AppLocalizations.of(context).navWorkout,
                        style: TextStyle(
                          fontSize: 14,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textMuted, size: 22),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: cardBorder),

          // Actions — scrollable so a long action list (all groups + delete)
          // never overflows the constrained bottom-sheet height. Mirrors the
          // Flexible + scroll pattern used by sibling sheets in this file.
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    // ── Quick group (opt-in) ──
                    // Mark done / Shuffle / View details. Only shown when the
                    // caller asks for them so the detail-screen and home-card
                    // menus share one widget without forcing every caller to
                    // surface the same affordances.
                    if (_hasQuickGroup) _GroupLabel(text: 'Quick'),
                    if (widget.showMarkDone && !_alreadyDone)
                      _ActionTile(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Mark as done',
                        subtitle: 'Log as completed, no PRs',
                        isLoading: _loadingAction == 'markDone',
                        onTap: () => _handleMarkDone(context),
                      ),
                    if (widget.showShuffle)
                      _ActionTile(
                        icon: Icons.shuffle_rounded,
                        title: 'Shuffle exercises',
                        subtitle: 'Re-roll with fresh picks',
                        isLoading: _loadingAction == 'shuffle',
                        onTap: () => _handleShuffle(context),
                      ),
                    if (widget.onViewDetails != null)
                      _ActionTile(
                        icon: Icons.visibility_outlined,
                        title: AppLocalizations.of(
                          context,
                        ).heroWorkoutCardViewDetails,
                        subtitle: 'Open the full workout',
                        isLoading: false,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onViewDetails!.call();
                        },
                      ),

                    // ── Options group ──
                    if (_hasQuickGroup) _GroupLabel(text: 'Options'),
                    _ActionTile(
                      icon: Icons.calendar_month,
                      title: AppLocalizations.of(
                        context,
                      ).workoutActionsReschedule,
                      subtitle: AppLocalizations.of(
                        context,
                      ).workoutActionsChangeWorkoutDate,
                      isLoading: _loadingAction == 'reschedule',
                      onTap: () => _handleReschedule(context),
                    ),
                    _ActionTile(
                      icon: Icons.refresh,
                      title: AppLocalizations.of(
                        context,
                      ).workoutActionsRegenerate,
                      subtitle:
                          _loadingAction == 'regenerate' &&
                              _regenerateMessage.isNotEmpty
                          ? '$_regenerateMessage ($_regenerateStep/$_regenerateTotalSteps)'
                          : 'Create a new workout for this day',
                      isLoading: _loadingAction == 'regenerate',
                      onTap: () => _handleRegenerate(context),
                    ),
                    _ActionTile(
                      icon: Icons.history,
                      title: AppLocalizations.of(
                        context,
                      ).workoutActionsVersionHistory,
                      subtitle: AppLocalizations.of(
                        context,
                      ).workoutActionsViewAndRestorePrevious,
                      isLoading: _loadingAction == 'versions',
                      onTap: () => _handleVersionHistory(context),
                    ),
                    _ActionTile(
                      icon: Icons.directions_run,
                      title: AppLocalizations.of(
                        context,
                      ).workoutActionsGenerateWarmup,
                      subtitle: AppLocalizations.of(
                        context,
                      ).workoutActionsCreateWarmupExercises,
                      isLoading: _loadingAction == 'warmup',
                      onTap: () => _handleGenerateWarmup(context),
                    ),
                    _ActionTile(
                      icon: Icons.self_improvement,
                      title: AppLocalizations.of(
                        context,
                      ).workoutActionsGenerateStretches,
                      subtitle: AppLocalizations.of(
                        context,
                      ).workoutActionsCreateCoolDownStretches,
                      isLoading: _loadingAction == 'stretches',
                      onTap: () => _handleGenerateStretches(context),
                    ),
                    // Backend rejects share-link generation for unfinished
                    // workouts (only completed sessions get a public token).
                    // Hide the affordance entirely so the user isn't left
                    // tapping a button that silently 400s.
                    if (widget.workout.isCompleted == true)
                      _ActionTile(
                        icon: Icons.ios_share_rounded,
                        title: AppLocalizations.of(
                          context,
                        ).workoutSummaryShareWorkout,
                        subtitle:
                            'Get a ${Branding.marketingDomain} link for friends',
                        isLoading: _loadingAction == 'share',
                        onTap: () => _handleShare(context),
                      )
                    else
                      _ActionTile(
                        icon: Icons.ios_share_rounded,
                        title: AppLocalizations.of(
                          context,
                        ).workoutSummaryShareWorkout,
                        subtitle: AppLocalizations.of(
                          context,
                        ).workoutActionsFinishThisWorkoutTo,
                        isLoading: false,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                ).workoutActionsCompleteTheWorkoutFirst,
                              ),
                            ),
                          );
                        },
                      ),
                    if (widget.showSkip)
                      _ActionTile(
                        icon: Icons.skip_next_rounded,
                        title: AppLocalizations.of(
                          context,
                        ).workoutOptionsSkipWorkout,
                        subtitle: 'Remove without completing it',
                        isLoading: _loadingAction == 'skip',
                        onTap: () => _handleSkip(context),
                      ),

                    // ── Delete, visually separated ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      child: Divider(
                        height: 1,
                        color: cardBorder.withValues(alpha: 0.5),
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.delete_outline,
                      title: AppLocalizations.of(
                        context,
                      ).workoutActionsDeleteWorkout,
                      subtitle: AppLocalizations.of(
                        context,
                      ).workoutActionsRemoveThisWorkout,
                      isDestructive: true,
                      isLoading: _loadingAction == 'delete',
                      onTap: () => _handleDelete(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleReschedule(BuildContext context) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(widget.workout.scheduledDate ?? '') ??
          DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.cyan,
              surface: AppColors.nearBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null && mounted) {
      setState(() {
        _isLoading = true;
        _loadingAction = 'reschedule';
      });

      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.rescheduleWorkout(
        widget.workout.id!,
        newDate.toIso8601String().split('T')[0],
      );

      setState(() {
        _isLoading = false;
        _loadingAction = null;
      });

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          widget.onRefresh?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).workoutActionsWorkoutRescheduled,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).workoutActionsFailedToRescheduleWorkout,
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    if (_loadingAction != null) return;
    final id = widget.workout.id;
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).workoutActionsThisWorkoutCannotBe,
          ),
        ),
      );
      return;
    }
    setState(() => _loadingAction = 'share');
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/workouts/$id/share-link');
      final data = res.data;
      String? url;
      if (data is Map && data['url'] is String) url = data['url'] as String;
      if (!mounted) return;
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).workoutActionsCouldNotCreateShare,
            ),
          ),
        );
        return;
      }
      // Copy first so the user has a guaranteed result even if the OS share
      // sheet is unavailable (iOS Simulator, missing target apps). Then show
      // the snackbar BEFORE popping the sheet — popping first hides the
      // SnackBar behind the dismissed sheet and makes the action look silent.
      await Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).workoutActionsLinkCopiedToClipboard,
          ),
        ),
      );
      Navigator.of(context).pop();
      await Share.share(
        '${widget.workout.name ?? 'My workout'} — ${Branding.appName}\n$url',
        subject: '${Branding.appName} workout',
      );
    } catch (e) {
      if (!mounted) return;
      // Surface the failure visibly: keep the sheet open so the SnackBar
      // isn't hidden behind a popping animation.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Share failed: $e')));
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }

  Future<void> _handleRegenerate(BuildContext context) async {
    final confirm = await AppDialog.confirm(
      context,
      title: AppLocalizations.of(context).workoutActionsRegenerateWorkout,
      message: AppLocalizations.of(context).workoutActionsThisWillCreateA,
      confirmText: 'Regenerate',
      icon: Icons.refresh_rounded,
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoading = true;
        _loadingAction = 'regenerate';
        _regenerateStep = 0;
        _regenerateMessage = 'Starting regeneration...';
      });

      final userId = await ref.read(apiClientProvider).getUserId();
      final repo = ref.read(workoutRepositoryProvider);
      Workout? generatedWorkout;

      // Use streaming for real-time progress updates
      await for (final progress in repo.regenerateWorkoutStreaming(
        workoutId: widget.workout.id!,
        userId: userId!,
      )) {
        if (!mounted) break;

        if (progress.hasError) {
          setState(() {
            _isLoading = false;
            _loadingAction = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${progress.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }

        setState(() {
          _regenerateStep = progress.step;
          _regenerateTotalSteps = progress.totalSteps;
          _regenerateMessage = progress.message;
        });

        if (progress.isCompleted && progress.workout != null) {
          generatedWorkout = progress.workout;
          break;
        }
      }

      setState(() {
        _isLoading = false;
        _loadingAction = null;
      });

      if (mounted) {
        Navigator.pop(context);
        if (generatedWorkout != null) {
          widget.onRefresh?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).workoutActionsWorkoutRegenerated,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).workoutActionsFailedToRegenerateWorkout,
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleVersionHistory(BuildContext context) async {
    setState(() {
      _loadingAction = 'versions';
    });

    final repo = ref.read(workoutRepositoryProvider);
    final versions = await repo.getWorkoutVersions(widget.workout.id!);

    setState(() {
      _loadingAction = null;
    });

    if (!mounted) return;

    Navigator.pop(context);

    await showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: _VersionHistorySheet(
          workoutId: widget.workout.id!,
          versions: versions,
          onRevert: () {
            widget.onRefresh?.call();
          },
        ),
      ),
    );
  }

  Future<void> _handleGenerateWarmup(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _loadingAction = 'warmup';
    });

    final repo = ref.read(workoutRepositoryProvider);
    final warmup = await repo.generateWarmup(widget.workout.id!);

    setState(() {
      _isLoading = false;
      _loadingAction = null;
    });

    if (!mounted) return;

    Navigator.pop(context);

    if (warmup.isNotEmpty) {
      await showGlassSheet(
        context: context,
        builder: (context) => GlassSheet(
          child: _WarmupStretchesSheet(
            title: AppLocalizations.of(context).workoutActionsWarmupExercises,
            exercises: warmup,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).workoutActionsFailedToGenerateWarmup,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGenerateStretches(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _loadingAction = 'stretches';
    });

    final repo = ref.read(workoutRepositoryProvider);
    final stretches = await repo.generateStretches(widget.workout.id!);

    setState(() {
      _isLoading = false;
      _loadingAction = null;
    });

    if (!mounted) return;

    Navigator.pop(context);

    if (stretches.isNotEmpty) {
      await showGlassSheet(
        context: context,
        builder: (context) => GlassSheet(
          child: _WarmupStretchesSheet(
            title: AppLocalizations.of(context).workoutActionsCoolDownStretches,
            exercises: stretches,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).workoutActionsFailedToGenerateStretches,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await AppDialog.destructive(
      context,
      title: AppLocalizations.of(context).workoutActionsDeleteWorkout2,
      message: AppLocalizations.of(context).workoutActionsThisActionCannotBe,
      icon: Icons.delete_rounded,
    );

    if (confirm == true && mounted) {
      setState(() {
        _isLoading = true;
        _loadingAction = 'delete';
      });

      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.deleteWorkout(widget.workout.id!);

      setState(() {
        _isLoading = false;
        _loadingAction = null;
      });

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          widget.onRefresh?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).workoutActionsWorkoutDeleted,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  // ── Quick-group handlers ───────────────────────────────────────────────────
  // These mirror the workout-detail screen's own handlers 1:1 (same completion
  // endpoint + studio shuffle service) so the home-card menu can't drift from
  // the detail menu. Each refreshes dependent views via the dispose-proof
  // root-container coordinator (the sheet may be popped before the refresh
  // settles).

  /// Mark as done — logs the workout as completed without running the timer,
  /// hitting the same `/complete?completion_method=marked_done` endpoint the
  /// detail screen uses. No PRs are created server-side for this path.
  Future<void> _handleMarkDone(BuildContext context) async {
    if (_loadingAction != null) return;
    final wid = widget.workout.id;
    if (wid == null || wid.isEmpty || _alreadyDone) return;

    final confirm = await AppDialog.confirm(
      context,
      title: 'Mark as done?',
      message:
          'Log this workout as completed without running the timer. '
          'No personal records will be created.',
      confirmText: 'Mark as done',
      icon: Icons.check_circle_outline_rounded,
    );
    if (confirm != true || !mounted) return;

    setState(() => _loadingAction = 'markDone');
    HapticService.selection();
    try {
      await ref
          .read(apiClientProvider)
          .post(
            '${ApiConstants.workouts}/$wid/complete',
            queryParameters: {'completion_method': 'marked_done'},
          );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRefresh?.call();
      // Full-set refresh so muscle/score/consistency update too.
      unawaited(
        refreshAfterWorkoutMutation(source: 'markDone', workoutId: wid),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged as done'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAction = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not log workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Shuffle — re-rolls the workout with fresh exercise picks via the studio
  /// service (same path as the detail screen's Shuffle).
  Future<void> _handleShuffle(BuildContext context) async {
    if (_loadingAction != null) return;
    final wid = widget.workout.id;
    if (wid == null || wid.isEmpty) return;

    setState(() => _loadingAction = 'shuffle');
    HapticService.selection();
    try {
      await ref.read(workoutStudioServiceProvider).shuffle(wid);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onRefresh?.call();
      unawaited(refreshAfterWorkoutMutation(source: 'shuffle', workoutId: wid));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shuffled in fresh exercises'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAction = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not shuffle: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Skip — removes the workout for this day without completing it (mirrors the
  /// home card's prior Skip flow: delete + refresh).
  Future<void> _handleSkip(BuildContext context) async {
    if (_loadingAction != null) return;
    final wid = widget.workout.id;
    if (wid == null || wid.isEmpty) return;

    final confirm = await AppDialog.destructive(
      context,
      title: AppLocalizations.of(context).workoutOptionsSkipWorkout,
      message: AppLocalizations.of(context).workoutOptionsThisWorkoutWillBe,
      confirmText: 'Skip',
      icon: Icons.skip_next_rounded,
    );
    if (confirm != true || !mounted) return;

    setState(() => _loadingAction = 'skip');
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final success = await repo.deleteWorkout(wid);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        widget.onRefresh?.call();
        unawaited(refreshAfterWorkoutMutation(source: 'skip', workoutId: wid));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout skipped'),
            backgroundColor: AppColors.textMuted,
          ),
        );
      } else {
        setState(() => _loadingAction = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).heroWorkoutCardCouldNotSkipWorkout,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingAction = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).heroWorkoutCardCouldNotSkipWorkout,
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Small uppercase section divider label ("QUICK" / "OPTIONS") used by the
/// parity menu. Mirrors the detail screen's group label styling.
class _GroupLabel extends StatelessWidget {
  final String text;

  const _GroupLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
            color: textMuted,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final textSecondary = isDark
        ? AppColors.textSecondary
        : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final errorColor = isDark ? AppColors.error : AppColorsLight.error;

    final iconColor = isDestructive ? errorColor : accentColor;
    final titleColor = isDestructive ? errorColor : textPrimary;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
            : Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive
                ? errorColor.withValues(alpha: 0.7)
                : textSecondary,
            fontSize: 13,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: isLoading ? null : onTap,
    );
  }
}

// Version History Sheet
class _VersionHistorySheet extends ConsumerWidget {
  final String workoutId;
  final List<Map<String, dynamic>> versions;
  final VoidCallback? onRevert;

  const _VersionHistorySheet({
    required this.workoutId,
    required this.versions,
    this.onRevert,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.cyan),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).workoutActionsVersionHistory,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Versions list
          Flexible(
            child: versions.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.history,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).workoutActionsNoVersionHistory,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: versions.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final version = versions[index];
                      final versionNum = version['version'] ?? index + 1;
                      final createdAt = version['created_at'] ?? '';
                      final name = version['name'] ?? 'Version $versionNum';
                      final isCurrent = index == 0;

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.cyan.withOpacity(0.2)
                                : AppColors.elevated,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'v$versionNum',
                              style: TextStyle(
                                color: isCurrent
                                    ? AppColors.cyan
                                    : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          _formatDate(createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isCurrent
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).workoutActionsCurrent,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              )
                            : TextButton(
                                onPressed: () async {
                                  final confirm = await AppDialog.confirm(
                                    context,
                                    title: AppLocalizations.of(
                                      context,
                                    ).workoutActionsRevertToThisVersion,
                                    message: 'Restore "$name"?',
                                    confirmText: 'Revert',
                                    icon: Icons.restore_rounded,
                                  );

                                  if (confirm == true) {
                                    final repo = ref.read(
                                      workoutRepositoryProvider,
                                    );
                                    await repo.revertWorkout(
                                      workoutId,
                                      versionNum,
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      onRevert?.call();
                                    }
                                  }
                                },
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).workoutDetailRevert,
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

// Warmup/Stretches Sheet
class _WarmupStretchesSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> exercises;

  const _WarmupStretchesSheet({required this.title, required this.exercises});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.nearBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  title.contains('Warmup')
                      ? Icons.directions_run
                      : Icons.self_improvement,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Exercises list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: exercises.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                final name = exercise['name'] ?? 'Exercise ${index + 1}';
                final duration =
                    exercise['duration_seconds'] ?? exercise['duration'] ?? 30;
                final instructions = exercise['instructions'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Index
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (instructions.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                instructions,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Duration
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${duration}s',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
