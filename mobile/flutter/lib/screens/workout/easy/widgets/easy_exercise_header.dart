// Easy tier — exercise header.
//
// 280 pt tall on default devices (180 pt thumbnail compacted for iPhone SE).
// Shows:
//   • Big exercise name (24 pt, w600, centered)
//   • "Set N of M" subtitle (14 pt muted)
//   • Centered demo thumbnail (gifUrl → videoUrl fallback)
//   • Row: ▶ Show video · 📋 Plan · [ kg | lb ]
//
// Nothing scrolls: the thumbnail sizes down on tiny safe-area heights.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../data/models/exercise.dart';
import '../../../../data/services/api_client.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/accent_color_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../widgets/exercise_image.dart';
import '../../../../widgets/exercise_stats_widgets.dart';
import '../../../../widgets/glass_sheet.dart';
import '../../../../data/providers/exercise_history_provider.dart';
import '../../shared/unit_chip.dart';

import '../../../../l10n/generated/app_localizations.dart';

class EasyExerciseHeader extends ConsumerWidget {
  final WorkoutExercise exercise;
  final int currentSet; // 1-indexed
  final int totalSets;
  final VoidCallback onShowVideo;
  final VoidCallback onOpenPlan;
  final VoidCallback onShowInfo;

  /// Opens the AI Form-Check sheet for this exercise (pre-filled, editable).
  /// Rendered as the accent-tinted hero chip in the media row. Null hides it.
  final VoidCallback? onFormCheck;

  /// Tap + on the "Set N of M" row. Null disables (e.g. at the upper cap).
  final VoidCallback? onAddSet;

  /// Tap − on the "Set N of M" row. Null disables (e.g. can't drop a
  /// completed or the current set).
  final VoidCallback? onRemoveSet;

  /// Tap handler for the 📝 note chip in the header row. Null hides it.
  final VoidCallback? onEditNote;

  /// Whether a note/audio/photo is currently attached to the focal set.
  final bool hasNote;

  /// Tap handler for the "•••" More chip — opens the easy exercise
  /// actions sheet (Swap / Report pain / Change equipment / Skip / Video).
  /// Null hides the chip; in practice always wired by easy_active_workout_state.
  final VoidCallback? onShowMore;

  /// When true, compact layout for SE-class devices (180 pt thumbnail).
  final bool compact;

  const EasyExerciseHeader({
    super.key,
    required this.exercise,
    required this.currentSet,
    required this.totalSets,
    required this.onShowVideo,
    required this.onOpenPlan,
    required this.onShowInfo,
    this.onFormCheck,
    this.onAddSet,
    this.onRemoveSet,
    this.onEditNote,
    this.hasNote = false,
    this.onShowMore,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final muted = textColor.withValues(alpha: 0.58);
    final accent = AccentColorScope.of(context).getColor(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          // Wide MEDIA (mockup): the move's video/illustration in a landscape
          // frame with a centered play affordance + a fullscreen expand.
          // Tapping opens the looping full-screen player.
          _WideMedia(
            exercise: exercise,
            isDark: isDark,
            height: compact ? 132 : 168,
            onTap: () async {
              await HapticService.instance.tap();
              onShowVideo();
            },
          ),
          const SizedBox(height: 12),
          // Name (left) + ↺ History chip (right). History rehomes here from
          // the tab row — it's DATA (this session's ledger is already inline,
          // History opens previous sessions + progress).
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.disp(
                    compact ? 21 : 24,
                    color: ThemeColors.of(context).textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _HistoryChip(
                color: textColor,
                onTap: () {
                  HapticService.instance.tap();
                  showEasyExerciseHistorySheet(context, ref, exercise.name);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tab row = RESOURCES: kg|lb · Form check · Instructions · Plan ·
          // Note. (History moved beside the name; the ⋯ actions live in the
          // top bar.) Scales down to fit narrow devices.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const UnitChip(),
                const SizedBox(width: 12),
                if (onFormCheck != null) ...[
                  _LinkChip(
                    icon: Icons.sports_gymnastics_outlined,
                    label: 'Form check',
                    color: accent,
                    onTap: () async {
                      await HapticService.instance.tap();
                      onFormCheck!();
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                _LinkChip(
                  icon: Icons.menu_book_outlined,
                  label:
                      AppLocalizations.of(context).workoutShowcaseInstructions,
                  color: textColor,
                  onTap: () async {
                    await HapticService.instance.tap();
                    onShowInfo();
                  },
                ),
                const SizedBox(width: 10),
                _LinkChip(
                  icon: Icons.list_alt_rounded,
                  label: AppLocalizations.of(context).workoutsPlan,
                  color: textColor,
                  onTap: () async {
                    await HapticService.instance.tap();
                    onOpenPlan();
                  },
                ),
                if (onEditNote != null) ...[
                  const SizedBox(width: 10),
                  _NoteHeaderChip(
                    onTap: onEditNote!,
                    hasNote: hasNote,
                    color: textColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // SET n OF m stepper.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SetCountStepButton(
                icon: Icons.remove_rounded,
                onTap: onRemoveSet,
                color: muted,
                tooltip:
                    AppLocalizations.of(context).easyExerciseHeaderRemoveSet,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'SET $currentSet OF $totalSets',
                  style: ZType.lbl(
                    12,
                    color: muted,
                    weight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _SetCountStepButton(
                icon: Icons.add_rounded,
                onTap: onAddSet,
                color: muted,
                tooltip: AppLocalizations.of(context).easyExerciseHeaderAddSet,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wide landscape media frame — the move's video (autoplays inline, muted +
/// looping) or, while it resolves / when there's none, the illustration. A
/// fullscreen-expand button opens the full-screen player. Matches the mockup.
class _WideMedia extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;
  final bool isDark;
  final double height;
  final VoidCallback onTap;

  const _WideMedia({
    required this.exercise,
    required this.isDark,
    required this.height,
    required this.onTap,
  });

  @override
  ConsumerState<_WideMedia> createState() => _WideMediaState();
}

class _WideMediaState extends ConsumerState<_WideMedia> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _resolveAndPlay();
  }

  @override
  void didUpdateWidget(covariant _WideMedia old) {
    super.didUpdateWidget(old);
    // Focal exercise changed → tear down + re-resolve the new move's video.
    if (old.exercise.name != widget.exercise.name) {
      _controller?.dispose();
      _controller = null;
      _ready = false;
      _resolveAndPlay();
    }
  }

  Future<void> _resolveAndPlay() async {
    // Resolution mirrors openEasyVideo: a real https URL on the model, else
    // the `/videos/by-exercise/<name>` endpoint (returns a presigned URL).
    String? url;
    final direct = widget.exercise.videoUrl;
    if (direct != null && direct.startsWith('http')) {
      url = direct;
    } else {
      try {
        final res = await ref.read(apiClientProvider).get(
              '/videos/by-exercise/${Uri.encodeComponent(widget.exercise.name)}',
            );
        if (res.statusCode == 200 && res.data != null) {
          url = res.data['url'] as String?;
        }
      } catch (_) {
        // No video → silently fall back to the illustration.
      }
    }
    if (url == null || url.isEmpty || !mounted) return;
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
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
        _ready = true;
      });
    } catch (_) {
      // Init failed (codec / network) → keep the illustration.
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final border =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10);
    final preResolved = widget.exercise.imageS3Path ??
        widget.exercise.gifUrl ??
        widget.exercise.videoUrl;
    final hasVideo = _ready && _controller != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasVideo)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                ExerciseImage(
                  exerciseName: widget.exercise.name,
                  imageUrl: preResolved,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 0,
                  fit: BoxFit.cover,
                  backgroundColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.04),
                  iconColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.22),
                ),
              // Centered play affordance — only while showing the still (the
              // video, once playing, needs none).
              if (!hasVideo)
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 34),
                  ),
                ),
              // Fullscreen expand affordance, bottom-right.
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.open_in_full_rounded,
                      color: Colors.black87, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-style ↺ History chip shown beside the exercise name.
class _HistoryChip extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _HistoryChip({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = color.withValues(alpha: 0.82);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(
              'History',
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the ↺ History sheet — previous SESSIONS for this exercise (this
/// session's sets are already in the set-ledger). Reuses [ExerciseSessionCard]
/// + [exerciseHistoryProvider]. Public so the set-ledger pills (tap → History,
/// per the locked spec) can reuse the exact same sheet.
void showEasyExerciseHistorySheet(
    BuildContext context, WidgetRef ref, String exerciseName) {
  showGlassSheet<void>(
    context: context,
    builder: (_) => GlassSheet(child: _EasyHistorySheet(exerciseName: exerciseName)),
  );
}

class _EasyHistorySheet extends ConsumerWidget {
  final String exerciseName;
  const _EasyHistorySheet({required this.exerciseName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tc = ThemeColors.of(context);
    final async = ref.watch(exerciseHistoryProvider(exerciseName));
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: Text(
              'History · ${exerciseName.toUpperCase()}',
              style: ZType.lbl(13, color: tc.textMuted, letterSpacing: 1.5),
            ),
          ),
          Flexible(
            child: async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text("Couldn't load history",
                    style: TextStyle(color: tc.textMuted)),
              ),
              data: (h) {
                final sessions = h.sortedSessionsNewestFirst;
                if (sessions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Text('No history yet for this exercise.',
                        style: TextStyle(color: tc.textMuted)),
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    for (final s in sessions) ExerciseSessionCard(session: s),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LinkChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha: 0.80)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small 24-pt +/− button flanking the "Set N of M" subtitle. Null [onTap]
/// disables the button and renders it at reduced opacity.
class _SetCountStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final String tooltip;

  const _SetCountStepButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled
              ? () async {
                  await HapticService.instance.tap();
                  onTap!();
                }
              : null,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: enabled ? 0.10 : 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color.withValues(alpha: enabled ? 1.0 : 0.35),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header-row `📝 Note` chip. Matches the visual weight of the sibling
/// Video / Instructions / Plan link chips but adds an accent-tinted state
/// + ✓ indicator once the current focal set has a note / audio / photo.
class _NoteHeaderChip extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasNote;
  final Color color;

  const _NoteHeaderChip({
    required this.onTap,
    required this.hasNote,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final fg = hasNote ? accent : color.withValues(alpha: 0.80);
    final label = hasNote ? 'Note ✓' : 'Note';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await HapticService.instance.tap();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: 18, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
