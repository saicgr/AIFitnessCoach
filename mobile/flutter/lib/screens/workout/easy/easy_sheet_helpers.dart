// Easy tier — sheet launchers.
//
// Thin wrappers that keep the state class small. Each function is
// context-dependent (needs a BuildContext) but state-independent — safe
// to call from anywhere with the right arguments.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/haptic_service.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';
import '../models/workout_state.dart';
import '../shared/exercise_instruction_copy.dart';
import '../shared/plan_sheet.dart';
import 'easy_active_workout_state_models.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Launch a full-screen video-only viewer for the current exercise.
///
/// Resolution order (matches the rest of the app):
///   1. exercise.videoUrl / videoS3Path / gifUrl
///   2. API `/videos/by-exercise/<name>` — returns a presigned S3 URL
///   3. Snackbar fallback if neither returns media
Future<void> openEasyVideo(
  BuildContext context,
  WorkoutExercise exercise, {
  required WidgetRef ref,
}) async {
  HapticService.instance.tap();
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _EasyVideoOnlyScreen(
        exerciseName: exercise.name,
        directUrl: exercise.videoUrl?.isNotEmpty == true
            ? exercise.videoUrl
            : (exercise.videoS3Path?.isNotEmpty == true
                ? exercise.videoS3Path
                : (exercise.gifUrl?.isNotEmpty == true
                    ? exercise.gifUrl
                    : null)),
      ),
    ),
  );
}

/// Launch the shared plan sheet with the Easy-tier dataset.
/// `onJumpTo` receives the tapped exercise index so the caller can swap
/// the focal card.
void openEasyPlanSheet({
  required BuildContext context,
  required List<WorkoutExercise> exercises,
  required Map<int, EasyExerciseState> perExercise,
  required int currentIndex,
  required ValueChanged<int> onJumpTo,
}) {
  HapticService.instance.tap();
  final completed = <int, List<SetLog>>{};
  final totals = <int, int>{};
  perExercise.forEach((i, st) {
    completed[i] = st.completed;
    totals[i] = st.totalSets;
  });
  showPlanSheet(
    context: context,
    exercises: exercises,
    completedSets: completed,
    totalSetsPerExercise: totals,
    currentExerciseIndex: currentIndex,
    onJumpTo: onJumpTo,
  );
}

/// Launch a text-only instructions sheet for the current exercise. Shows
/// muscle group, body part, equipment, and the how-to text — no video.
void openEasyInfoSheet(BuildContext context, WorkoutExercise exercise) {
  HapticService.instance.tap();
  showGlassSheet<void>(
    context: context,
    builder: (_) => GlassSheet(
      maxHeightFraction: 0.85,
      child: _EasyInstructionsContent(exercise: exercise),
    ),
  );
}

/// Full-screen video-only viewer. Uses the same `VideoPlayerController`
/// + API pattern as ExerciseInstructionsScreen (which works), but without
/// the instructions tabs — pure playback.
class _EasyVideoOnlyScreen extends ConsumerStatefulWidget {
  final String exerciseName;
  final String? directUrl;
  const _EasyVideoOnlyScreen({
    required this.exerciseName,
    required this.directUrl,
  });

  @override
  ConsumerState<_EasyVideoOnlyScreen> createState() =>
      _EasyVideoOnlyScreenState();
}

class _EasyVideoOnlyScreenState extends ConsumerState<_EasyVideoOnlyScreen> {
  VideoPlayerController? _controller;
  String? _resolvedUrl;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _resolveAndPlay();
  }

  Future<void> _resolveAndPlay() async {
    // 1. Prefer an already-resolved URL on the exercise model — but ONLY if
    // it's a real https URL. A raw `s3://bucket/key` path (videoS3Path) is
    // NOT playable by ExoPlayer ("unknown protocol: s3"), so treat it as
    // unresolved and fall through to the API, which returns a presigned
    // https URL. Mirrors widgets/exercise_image.dart's resolution.
    final direct = widget.directUrl;
    if (direct != null && direct.startsWith('http')) {
      _resolvedUrl = direct;
    } else {
      // 2. Fall back to the API (handles s3:// paths + missing media).
      try {
        final apiClient = ref.read(apiClientProvider);
        final res = await apiClient.get(
          '/videos/by-exercise/${Uri.encodeComponent(widget.exerciseName)}',
        );
        if (res.statusCode == 200 && res.data != null) {
          _resolvedUrl = res.data['url'] as String?;
        }
      } catch (e) {
        debugPrint('❌ [EasyVideo] API lookup failed: $e');
      }
    }

    if (_resolvedUrl == null || _resolvedUrl!.isEmpty) {
      if (mounted) setState(() => _error = true);
      return;
    }
    await _initController();
  }

  Future<void> _initController() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(_resolvedUrl!));
      await c.initialize();
      c
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ [EasyVideo] Init failed: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _body()),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          PositionedDirectional(start: 16,
            end: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Text(
              widget.exerciseName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const CircularProgressIndicator(color: Colors.white70);
    }
    if (_error || _controller == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 56),
          SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).easySheetHelpersNoDemoVideoFor,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}

class _EasyInstructionsContent extends StatelessWidget {
  final WorkoutExercise exercise;
  const _EasyInstructionsContent({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final fg = isDark ? Colors.white : Colors.black87;
    final muted = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.6);

    // Prefer the backend-supplied instructions string when it's present
    // and substantial (not just a one-liner). Otherwise fall back to the
    // pattern-matched numbered steps so the sheet always has real content.
    final serverText = (exercise.instructions ?? '').trim();
    final useServerText = serverInstructionsAreSubstantial(serverText);
    final setupSteps = useServerText
        ? splitInstructionsIntoSteps(serverText)
        : getSetupSteps(exercise.name, equipment: exercise.equipment);
    final formTips = getFormTips(exercise.name, equipment: exercise.equipment);
    final breathingCues = getBreathingCues(exercise.name, equipment: exercise.equipment);

    final aboutRows = <_InfoRow>[];
    final primary = exercise.primaryMuscle?.isNotEmpty == true
        ? exercise.primaryMuscle!
        : (exercise.muscleGroup ?? '');
    if (primary.isNotEmpty) {
      aboutRows.add(_InfoRow(
          icon: Icons.accessibility_new_rounded,
          label: AppLocalizations.of(context).easySheetHelpersPrimaryMuscle,
          value: primary));
    }
    final secondary = exercise.secondaryMuscles;
    final secondaryList = secondary is List
        ? secondary.map((e) => e.toString()).toList()
        : <String>[];
    if (secondaryList.isNotEmpty) {
      aboutRows.add(_InfoRow(
          icon: Icons.format_list_bulleted_rounded,
          label: AppLocalizations.of(context).easySheetHelpersSecondary,
          value: secondaryList.join(', ')));
    }
    if ((exercise.bodyPart ?? '').isNotEmpty) {
      aboutRows.add(_InfoRow(
          icon: Icons.category_outlined,
          label: AppLocalizations.of(context).easySheetHelpersBodyPart,
          value: exercise.bodyPart!));
    }
    if ((exercise.equipment ?? '').isNotEmpty) {
      aboutRows.add(_InfoRow(
          icon: Icons.fitness_center_rounded,
          label: AppLocalizations.of(context).trainingSetupCardEquipment,
          value: exercise.equipment!));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700, color: fg),
          ),
          if (primary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(primary,
                style: TextStyle(
                    fontSize: 13,
                    color: muted,
                    fontWeight: FontWeight.w500)),
          ],
          const SizedBox(height: 20),

          // ── Primary content: numbered How-to steps ─────────────────
          _SectionLabel(label: AppLocalizations.of(context).easySheetHelpersHowToPerform, fg: fg),
          const SizedBox(height: 10),
          ...List.generate(setupSteps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        setupSteps[i],
                        style: TextStyle(
                            fontSize: 14, color: fg, height: 1.45),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Secondary sections collapse by default so the sheet opens
          // scannable (name + How-to-perform), not a wall of text. Tap to
          // expand the form tips, breathing, and about details.
          _CollapsibleSection(
            title: AppLocalizations.of(context).easySheetHelpersFormTips,
            icon: Icons.lightbulb_outline,
            fg: fg,
            accent: accent,
            children: formTips
                .map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                  fontSize: 14, color: fg, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),

          _CollapsibleSection(
            title: AppLocalizations.of(context).workoutUiBuildersBreathing,
            icon: Icons.air_rounded,
            fg: fg,
            accent: accent,
            children: breathingCues
                .map((cue) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.arrow_right_rounded,
                              size: 18,
                              color: accent.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              cue,
                              style: TextStyle(
                                  fontSize: 14, color: fg, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),

          if (aboutRows.isNotEmpty)
            _CollapsibleSection(
              title: AppLocalizations.of(context)
                  .easySheetHelpersAboutThisExercise,
              fg: fg,
              accent: accent,
              children: aboutRows
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildRow(r, fg: fg, muted: muted),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(_InfoRow row, {required Color fg, required Color muted}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(row.icon, size: 18, color: muted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.label,
                style: TextStyle(
                    fontSize: 12,
                    color: muted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3),
              ),
              const SizedBox(height: 2),
              Text(
                row.value,
                style: TextStyle(
                    fontSize: 14, color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tap-to-expand instructions section (collapsed by default) so the
/// exercise sheet opens scannable instead of as one long wall of text.
/// Uses [ExpansionTile] so it manages its own open/closed state.
class _CollapsibleSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color fg;
  final Color accent;
  final List<Widget> children;

  const _CollapsibleSection({
    required this.title,
    required this.fg,
    required this.accent,
    required this.children,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: accent,
        collapsedIconColor: accent,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color fg;
  const _SectionLabel({required this.label, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.4),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
}
