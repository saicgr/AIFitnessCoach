/// Exercise Instructions Screen
///
/// Full screen showing exercise video prominently with collapsible
/// Setup and Tips sections at the bottom.
/// Opens when user taps the Instructions button in the workout bottom bar.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/exercise_video_overrides.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/exercise.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/exercise_image.dart';
import '../shared/exercise_instruction_copy.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Show the exercise instructions as a full screen page.
///
/// When [playlist] + [playlistIndex] are supplied, the sheet shows prev/next
/// chevrons so the user can skip between exercises without leaving the viewer
/// (Easy mode passes its full exercise list here). Single-exercise callers omit
/// them and the chevrons stay hidden.
Future<void> showExerciseInfoSheet({
  required BuildContext context,
  required WorkoutExercise exercise,
  List<WorkoutExercise>? playlist,
  int? playlistIndex,
}) {
  HapticFeedback.mediumImpact();

  return Navigator.of(context).push(
    AppPageRoute(
      builder: (context) => ExerciseInstructionsScreen(
        exercise: exercise,
        playlist: playlist,
        playlistIndex: playlistIndex,
      ),
    ),
  );
}

/// Exercise Instructions Screen - full video with collapsible Setup/Tips at bottom
class ExerciseInstructionsScreen extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;

  /// Optional list of exercises this viewer can skip through (prev/next).
  /// When null/empty, the viewer is single-exercise and chevrons are hidden.
  final List<WorkoutExercise>? playlist;

  /// Starting index into [playlist]. Ignored when [playlist] is null/empty.
  final int? playlistIndex;

  const ExerciseInstructionsScreen({
    super.key,
    required this.exercise,
    this.playlist,
    this.playlistIndex,
  });

  @override
  ConsumerState<ExerciseInstructionsScreen> createState() =>
      _ExerciseInstructionsScreenState();
}

class _ExerciseInstructionsScreenState
    extends ConsumerState<ExerciseInstructionsScreen> {
  // Video player state
  VideoPlayerController? _videoController;
  String? _videoUrl;
  bool _isLoadingVideo = true;
  bool _isVideoInitialized = false;

  // Three terminal states distinguish "the spinner is over":
  //   _isVideoInitialized == true   → playing
  //   _videoError == true           → had a real error (network/timeout/init)
  //                                   → show retry button
  //   neither, _videoUrl == null    → backend honestly has no video
  //                                   → show "No video yet" caption only
  bool _videoError = false;

  // Substitute-exercise metadata returned by the backend's similarity
  // fallback. When non-null, render an honest banner above the video so we
  // never silently swap one exercise for another.
  String? _substituteOriginalName;
  String? _substituteMatchedName;

  // Guard against double-fire from rapid retries.
  bool _isRetrying = false;

  // ── Playlist / skip state ──────────────────────────────────────────────
  // When the caller passes a playlist, the viewer tracks a mutable index so
  // prev/next chevrons can swap the displayed exercise (and its video) in
  // place. Single-exercise callers collapse to a one-item list.
  late int _index;
  List<WorkoutExercise> get _playlist =>
      (widget.playlist != null && widget.playlist!.isNotEmpty)
          ? widget.playlist!
          : [widget.exercise];
  WorkoutExercise get _exercise =>
      _playlist[_index.clamp(0, _playlist.length - 1)];
  bool get _hasPrev => _index > 0;
  bool get _hasNext => _index < _playlist.length - 1;

  // Bottom tabs state
  int _selectedTab = 0; // 0 = Setup, 1 = Tips
  bool _isExpanded = false;

  // Playback-speed control. The chosen rate persists across a video re-init
  // (retry / substitute) by being re-applied in [_loadVideo]. `_speedMenuOpen`
  // toggles the expanded option row.
  double _playbackSpeed = 1.0;
  bool _speedMenuOpen = false;
  static const List<double> _kPlaybackSpeeds = [0.25, 0.5, 0.75, 1.0, 2.0];

  void _setPlaybackSpeed(double speed) {
    HapticFeedback.selectionClick();
    setState(() {
      _playbackSpeed = speed;
      _speedMenuOpen = false;
    });
    _videoController?.setPlaybackSpeed(speed);
  }

  /// "1x", "0.5x", "0.25x" — drops a trailing zero for whole multipliers.
  String _formatSpeed(double s) {
    final str = s == s.roundToDouble() ? s.toStringAsFixed(0) : s.toString();
    return '${str}x';
  }

  @override
  void initState() {
    super.initState();
    _index = (widget.playlist != null &&
            widget.playlist!.isNotEmpty &&
            widget.playlistIndex != null)
        ? widget.playlistIndex!.clamp(0, widget.playlist!.length - 1)
        : 0;
    _loadVideoUrl();
  }

  /// Skip to another exercise in the playlist. Tears down the current video,
  /// resets the load state, and re-runs the loader for the new exercise. The
  /// chosen playback speed persists (re-applied in [_initializeVideo]).
  Future<void> _goToExercise(int newIndex) async {
    if (newIndex < 0 ||
        newIndex >= _playlist.length ||
        newIndex == _index) {
      return;
    }
    HapticFeedback.selectionClick();
    try {
      await _videoController?.dispose();
    } catch (_) {}
    _videoController = null;
    if (!mounted) return;
    setState(() {
      _index = newIndex;
      _videoUrl = null;
      _isLoadingVideo = true;
      _isVideoInitialized = false;
      _videoError = false;
      _substituteOriginalName = null;
      _substituteMatchedName = null;
      _speedMenuOpen = false;
    });
    await _loadVideoUrl();
  }

  /// Opens the Setup + Tips detail in a bottom sheet (the "more" action). These
  /// were previously inline tabs; the ⋯ button revives them on demand without
  /// cluttering the full-screen video.
  void _showMoreSheet() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = ref.read(accentColorProvider).getColor(isDark);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.elevated : AppColorsLight.pureWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    _titleCase(_exercise.name),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).easySheetHelpersHowToPerform,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildSetupContent(isDark, textPrimary, textMuted, accentColor),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context).easySheetHelpersFormTips,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTipsContent(isDark, textPrimary, textMuted, accentColor),
                  // Tips/Setup builders for the detail strings are unchanged.
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  /// Load video URL from API.
  ///
  /// Both the lookup and the player init are bounded by hard timeouts so a
  /// missing or slow video file (e.g. an AI-generated variant that isn't in
  /// the cleaned exercise library) can never leave the user staring at a
  /// black loading screen — we always fall through to the still-image
  /// placeholder within ~20s worst case.
  Future<void> _loadVideoUrl() async {
    final exerciseName = _exercise.name;

    try {
      final apiClient = ref.read(apiClientProvider);

      final videoResponse = await apiClient
          .get('/videos/by-exercise/${Uri.encodeComponent(exerciseName)}')
          .timeout(const Duration(seconds: 10));

      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        final body = videoResponse.data as Map<String, dynamic>;
        _videoUrl = body['url'] as String?;
        // Backend may return a substitute when the original exercise has
        // no canonical video — surface it honestly instead of silently
        // playing a different exercise's video.
        if (body['is_substitute'] == true) {
          final sim = body['similar_to'];
          if (sim is Map) {
            _substituteOriginalName = sim['original'] as String?;
            _substituteMatchedName = sim['matched'] as String?;
          }
        }

        if (_videoUrl != null && mounted) {
          await _initializeVideo();
        }
      }
    } catch (e) {
      debugPrint('❌ [Instructions] Error loading video: $e');
      if (mounted) {
        setState(() {
          _videoError = true;
          _isLoadingVideo = false;
        });
      }
      return;
    }

    if (mounted && !_isVideoInitialized) {
      // No video URL returned (404 or null), or init failed — drop the
      // spinner so the placeholder image renders. _videoError remains
      // false here because there's nothing to retry.
      setState(() {
        _isLoadingVideo = false;
      });
    }
  }

  /// User-triggered retry. Resets state and re-runs the loader. Disabled
  /// while a previous retry is still in flight to avoid double-fires.
  Future<void> _retryVideo() async {
    if (_isRetrying) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isRetrying = true;
      _videoError = false;
      _videoUrl = null;
      _isLoadingVideo = true;
      _isVideoInitialized = false;
      _substituteOriginalName = null;
      _substituteMatchedName = null;
    });
    try {
      await _videoController?.dispose();
    } catch (_) {}
    _videoController = null;
    await _loadVideoUrl();
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  /// Initialize video player
  Future<void> _initializeVideo() async {
    if (_videoUrl == null) return;

    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
      await _videoController!.initialize().timeout(
            const Duration(seconds: 10),
          );
      _videoController!.setLooping(true);
      _videoController!.setVolume(0); // Muted
      _videoController!.play(); // Auto-play
      // Re-apply the user's chosen rate so it survives a retry / substitute
      // re-init (defaults to 1.0 on a fresh open).
      _videoController!.setPlaybackSpeed(_playbackSpeed);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isLoadingVideo = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [Instructions] Error initializing video: $e');
      // Tear down a half-initialized controller so we don't leak it.
      try {
        await _videoController?.dispose();
      } catch (_) {}
      _videoController = null;
      if (mounted) {
        // If the URL that failed was only a SUBSTITUTE (the exercise has no
        // canonical video and the backend offered another move's clip), a
        // hard "Couldn't load — Retry" is wrong: retrying re-fetches the same
        // broken substitute. Fall back quietly to the still illustration —
        // exactly what cardio/functional stations (SkiErg, Plank Hold) want.
        final wasSubstitute = _substituteMatchedName != null;
        setState(() {
          _isLoadingVideo = false;
          if (wasSubstitute) {
            _videoUrl = null;
            _videoError = false;
            _substituteOriginalName = null;
            _substituteMatchedName = null;
          } else {
            _videoError = true;
          }
        });
      }
    }
  }

  void _toggleExpanded() {
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _selectTab(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTab = index;
      if (!_isExpanded) {
        _isExpanded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Get dynamic accent color
    final accentColor = ref.watch(accentColorProvider).getColor(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Stack(
        children: [
          // Full screen video/image area
          Positioned.fill(
            child: _buildFullScreenVideo(isDark, textMuted, accentColor),
          ),

          // Top bar with back button and exercise name
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(isDark, textPrimary, textMuted, accentColor),
          ),

          // Substitute banner — shown only when the backend's similarity
          // fallback returned a different exercise's video. We never want
          // to silently swap one exercise for another.
          if (_substituteMatchedName != null && _isVideoInitialized)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 12,
              right: 12,
              child: _buildSubstituteBanner(textPrimary, textMuted),
            ),

          // Bottom section with tabs
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSection(isDark, textPrimary, textMuted, accentColor),
          ),

          // Prev/next exercise chevrons — only for multi-exercise playlists.
          _buildSkipChevrons(),

          // Playback-speed control — only while a video is actually playing.
          if (_isVideoInitialized && _videoController != null)
            _buildSpeedControl(accentColor),
        ],
      ),
    );
  }

  /// Bottom-left playback-speed overlay (0.25x–2x). A tap on the pill expands
  /// the options upward; the inner GestureDetectors win the arena so they don't
  /// trigger the video's play/pause tap.
  Widget _buildSpeedControl(Color accentColor) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: _speedMenuOpen
                ? Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      // High opacity + hairline border so it stays legible over
                      // a WHITE video frame as well as a dark one.
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final s in _kPlaybackSpeeds)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _setPlaybackSpeed(s),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              child: Text(
                                _formatSpeed(s),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: s == _playbackSpeed
                                      ? accentColor
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _speedMenuOpen = !_speedMenuOpen),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                // Near-opaque dark pill + hairline border → crisp white text on
                // a white video frame (black54 composited to muddy grey there).
                color: Colors.black.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatSpeed(_playbackSpeed),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstituteBanner(Color textPrimary, Color textMuted) {
    final original = _substituteOriginalName ?? _exercise.name;
    final matched = _substituteMatchedName ?? '';
    // This banner overlays the exercise video, whose brightness is
    // unpredictable (white while loading, dark mid-clip). A translucent
    // light-yellow background with theme `textPrimary` rendered near-white text
    // on near-white video → invisible. Use a dark scrim + fixed near-white text
    // with amber emphasis so it's guaranteed legible in every theme/media state.
    const amber = Color(0xFFFCD34D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: amber.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: amber),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFFAFAFA), height: 1.3),
                children: [
                  const TextSpan(text: 'Showing '),
                  TextSpan(
                    text: matched,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: amber),
                  ),
                  const TextSpan(text: ' — closest match for '),
                  TextSpan(
                    text: original,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: amber),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDark, Color textPrimary, Color textMuted, Color accentColor) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textPrimary,
              size: 20,
            ),
          ),
          // Exercise name
          Expanded(
            child: Column(
              children: [
                Text(
                  _titleCase(_exercise.name),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _getTargetMuscles(),
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // "More" — Setup + Tips detail. Balances the back button.
          IconButton(
            onPressed: _showMoreSheet,
            icon: Icon(
              Icons.more_horiz_rounded,
              color: textPrimary,
              size: 24,
            ),
            tooltip: AppLocalizations.of(context).homeMore,
          ),
        ],
      ),
    );
  }

  /// Vertically-centered prev/next chevrons overlaid on the video sides. Only
  /// rendered when a multi-exercise playlist was supplied. The buttons sit
  /// above the play/pause tap target (own GestureDetector wins the arena).
  Widget _buildSkipChevrons() {
    if (_playlist.length < 2) return const SizedBox.shrink();
    Widget chevron({required bool next}) {
      final enabled = next ? _hasNext : _hasPrev;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () => _goToExercise(next ? _index + 1 : _index - 1)
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: enabled ? 1.0 : 0.25,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              next
                  ? Icons.chevron_right_rounded
                  : Icons.chevron_left_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                chevron(next: false),
                chevron(next: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenVideo(bool isDark, Color textMuted, Color accentColor) {
    if (_isLoadingVideo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).exerciseInfoLoadingVideo,
              style: TextStyle(
                fontSize: 14,
                color: textMuted,
              ),
            ),
          ],
        ),
      );
    }

    // Per-exercise framing override (see exercise_video_overrides.dart).
    // Null for almost every exercise — falls back to native aspect.
    final crop = exerciseVideoCropFor(_exercise.name);

    if (_isVideoInitialized && _videoController != null) {
      final nativeAspect = _videoController!.value.aspectRatio;
      final targetAspect = crop?.aspectRatio ?? nativeAspect;
      final scale = crop?.scale ?? 1.0;

      Widget videoChild = AspectRatio(
        aspectRatio: nativeAspect,
        child: VideoPlayer(_videoController!),
      );

      // If an override is set, force a tighter frame and optionally zoom in
      // to crop the baked-in whitespace.
      if (crop != null) {
        videoChild = ClipRect(
          child: AspectRatio(
            aspectRatio: targetAspect,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _videoController!.value.size.width * scale,
                height: _videoController!.value.size.height * scale,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: () {
          // Toggle play/pause
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
          setState(() {});
          HapticFeedback.selectionClick();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(child: videoChild),
            // Play/pause overlay
            if (!_videoController!.value.isPlaying)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
          ],
        ),
      );
    }

    // Placeholder when no video - show the exercise image.
    // If an override exists, mirror the same crop so the still image matches
    // the cropped video framing.
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final image = crop != null
        ? AspectRatio(
            aspectRatio: crop.aspectRatio,
            child: ExerciseImage(
              exerciseName: _exercise.name,
              width: screenW,
              height: screenW / crop.aspectRatio,
              borderRadius: 0,
              fit: BoxFit.cover,
              backgroundColor:
                  isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
              iconColor: textMuted,
            ),
          )
        : ExerciseImage(
            exerciseName: _exercise.name,
            width: screenW,
            height: screenH * 0.5,
            borderRadius: 0,
            fit: BoxFit.contain,
            backgroundColor:
                isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
            iconColor: textMuted,
          );

    // Three terminal states share the still-image fallback:
    //   1. _videoError == true   → real failure → caption + Retry button
    //   2. _videoUrl == null     → backend honestly has no video → caption only
    //   3. (init returned null)  → same as above
    //
    // The user explicitly tapped "Video", so silently showing the illustration
    // without explanation looks broken (the prior bug behind Kabaddi Squat
    // Jumps and other AI-generated variants).
    final caption = _videoError
        ? 'Couldn\'t load the video — check your connection and try again.'
        : 'No video yet for this exercise — showing the illustration.';
    return Stack(
      alignment: Alignment.center,
      children: [
        Center(child: image),
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: textMuted.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _videoError
                      ? Icons.error_outline_rounded
                      : Icons.videocam_off_rounded,
                  size: 16,
                  color: textMuted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    caption,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_videoError) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isRetrying ? null : _retryVideo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.7),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isRetrying)
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: accentColor,
                              ),
                            )
                          else
                            Icon(Icons.refresh_rounded,
                                size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            _isRetrying ? AppLocalizations.of(context).exerciseInfoRetrying : AppLocalizations.of(context).buttonRetry,
                            style: TextStyle(
                              fontSize: 12,
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(
      bool isDark, Color textPrimary, Color textMuted, Color accentColor) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding + 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      ),
      child: const SizedBox.shrink(),
    );
  }

  // Removed tab button - Setup/Tips moved to Info sheet
  Widget _buildTabButtonLegacy({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color accentColor,
  }) {
    final isSelected = _selectedTab == index;
    final color = isSelected ? accentColor : textMuted;

    return GestureDetector(
      onTap: () => _selectTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            if (_isExpanded && isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: color,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSetupContent(bool isDark, Color textPrimary, Color textMuted, Color accentColor) {
    final instructions = _getSetupInstructions();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: instructions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    instructions[index],
                    style: TextStyle(
                      fontSize: 14,
                      color: textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipsContent(bool isDark, Color textPrimary, Color textMuted, Color accentColor) {
    final tips = _getFormTips();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    tips[index],
                    style: TextStyle(
                      fontSize: 14,
                      color: textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTargetMuscles() {
    if (_exercise.primaryMuscle != null &&
        _exercise.primaryMuscle!.isNotEmpty) {
      return _exercise.primaryMuscle!;
    } else if (_exercise.muscleGroup != null &&
        _exercise.muscleGroup!.isNotEmpty) {
      return _exercise.muscleGroup!;
    }
    return 'Full Body';
  }

  /// Title-case an exercise name following project rules:
  ///   - Hyphens with capitals on both sides ("Push-Up", "T-Bar")
  ///   - Preserve apostrophes ("Farmer's Carry", "Women's Bar")
  ///   - Keep numbers intact ("21s", "1-Arm")
  ///   - Don't lowercase Roman numerals at end of words ("Bench Press III")
  ///   - Small connector words stay lowercase mid-phrase (with, on, of, the,
  ///     and, to, for, in) but always capitalize the first word.
  String _titleCase(String raw) {
    if (raw.isEmpty) return raw;
    const small = {'with', 'on', 'of', 'the', 'and', 'to', 'for', 'in', 'a',
        'an', 'or', 'at', 'by', 'as'};
    final romanRe = RegExp(r'^[IVX]+$');

    String capWord(String w, bool isFirst) {
      if (w.isEmpty) return w;
      // Already has a digit or already uppercase Roman → leave alone.
      if (romanRe.hasMatch(w)) return w;
      // If contains digits (e.g., "21s", "1-arm") leave digit segment as-is
      // and just uppercase first alpha char if any.
      if (RegExp(r'\d').hasMatch(w)) {
        // Still capitalize a leading alpha char if it starts with one.
        final m = RegExp(r'^([a-zA-Z]+)').firstMatch(w);
        if (m != null) {
          final alpha = m.group(1)!;
          return alpha[0].toUpperCase() + alpha.substring(1).toLowerCase() +
              w.substring(alpha.length);
        }
        return w;
      }
      final lower = w.toLowerCase();
      if (!isFirst && small.contains(lower)) return lower;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }

    // Split on whitespace, then within each token also split on '-' and '/'
    // while preserving the separator. Apostrophes stay attached.
    final tokens = raw.trim().split(RegExp(r'\s+'));
    final out = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final tok = tokens[i];
      // Split keeping hyphens and slashes — both sides get capitalized.
      final parts = tok.split(RegExp(r'(?=[-/])|(?<=[-/])'));
      final rebuilt = StringBuffer();
      var firstAlphaSeen = false;
      for (final p in parts) {
        if (p == '-' || p == '/') {
          rebuilt.write(p);
        } else {
          // For hyphenated words ("push-up"), capitalize each side.
          rebuilt.write(capWord(p, i == 0 && !firstAlphaSeen));
          if (p.isNotEmpty) firstAlphaSeen = true;
        }
      }
      out.add(rebuilt.toString());
    }
    return out.join(' ');
  }

  // NOTE: setup/form-tip routing now lives in the SHARED engine
  // `exercise_instruction_copy.dart` (`getSetupSteps` / `getFormTips`).
  // This sheet used to carry its own duplicate keyword classifier + DB-split
  // helper; both were removed so a fix (e.g. a missing cardio machine) lands
  // in one place for every surface.

  List<String> _getSetupInstructions() {
    // Single source of truth: substantial server/DB instructions win, else the
    // shared pattern engine (which classifies cardio/bodyweight/machine/etc.).
    final serverText = (_exercise.instructions ?? '').trim();
    if (serverInstructionsAreSubstantial(serverText)) {
      return splitInstructionsIntoSteps(serverText);
    }
    final base = getSetupSteps(_exercise.name, equipment: _exercise.equipment);
    // If the model carries an explicit `setup` cue, prepend it so it's not lost.
    final setup = _exercise.setup;
    if (setup != null && setup.trim().isNotEmpty) {
      return [setup.trim(), ...base];
    }
    return base;
  }

  List<String> _getFormTips() {
    // Shared pattern engine is the single source; DB cues take precedence.
    final base = List<String>.from(
        getFormTips(_exercise.name, equipment: _exercise.equipment));
    final cue = _exercise.formCue;
    if (cue != null && cue.trim().isNotEmpty) {
      base.insert(0, cue.trim());
    }
    final breathing = _exercise.breathingCue;
    if (breathing != null && breathing.trim().isNotEmpty) {
      base.add('Breathing: ${breathing.trim()}');
    }
    return base;
  }
}

/// Legacy support - keep ExerciseInfoSheet as an alias
class ExerciseInfoSheet extends StatelessWidget {
  final WorkoutExercise exercise;

  const ExerciseInfoSheet({
    super.key,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    // Redirect to the new screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pop(context);
      Navigator.push(
        context,
        AppPageRoute(
          builder: (context) => ExerciseInstructionsScreen(exercise: exercise),
        ),
      );
    });
    return const SizedBox.shrink();
  }
}
