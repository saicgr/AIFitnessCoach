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

/// Show the exercise instructions as a full screen page
Future<void> showExerciseInfoSheet({
  required BuildContext context,
  required WorkoutExercise exercise,
}) {
  HapticFeedback.mediumImpact();

  return Navigator.of(context).push(
    AppPageRoute(
      builder: (context) => ExerciseInstructionsScreen(
        exercise: exercise,
      ),
    ),
  );
}

/// Exercise Instructions Screen - full video with collapsible Setup/Tips at bottom
class ExerciseInstructionsScreen extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;

  const ExerciseInstructionsScreen({
    super.key,
    required this.exercise,
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

  // Bottom tabs state
  int _selectedTab = 0; // 0 = Setup, 1 = Tips
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadVideoUrl();
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
    final exerciseName = widget.exercise.name;

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
        setState(() {
          _videoError = true;
          _isLoadingVideo = false;
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
        ],
      ),
    );
  }

  Widget _buildSubstituteBanner(Color textPrimary, Color textMuted) {
    final original = _substituteOriginalName ?? widget.exercise.name;
    final matched = _substituteMatchedName ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCD34D).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFCD34D).withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Color(0xFFFCD34D)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, color: textPrimary, height: 1.3),
                children: [
                  const TextSpan(text: 'Showing '),
                  TextSpan(
                    text: matched,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: ' — closest match for '),
                  TextSpan(
                    text: original,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
                  _titleCase(widget.exercise.name),
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
          // Spacer to balance
          const SizedBox(width: 48),
        ],
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
              'Loading video...',
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
    final crop = exerciseVideoCropFor(widget.exercise.name);

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
              exerciseName: widget.exercise.name,
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
            exerciseName: widget.exercise.name,
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
                            _isRetrying ? 'Retrying' : 'Retry',
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
    if (widget.exercise.primaryMuscle != null &&
        widget.exercise.primaryMuscle!.isNotEmpty) {
      return widget.exercise.primaryMuscle!;
    } else if (widget.exercise.muscleGroup != null &&
        widget.exercise.muscleGroup!.isNotEmpty) {
      return widget.exercise.muscleGroup!;
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

  /// Routes an exercise to its setup template. Routing table is intentionally
  /// ordered most-specific first so compound names ("dumbbell fly flat bench")
  /// don't fall into the bench-press bucket.
  ///
  /// Expected routing for plan test fixtures:
  ///   - "dumbbell fly flat bench slow"     → fly
  ///   - "barbell romanian deadlift"        → romanian deadlift
  ///   - "bulgarian split squat"            → split squat (rear-foot-elevated)
  ///   - "dumbbell shoulder press"          → overhead press
  ///   - "bodyweight squat"                 → bodyweight squat
  ///   - "hip thrust"                       → hip thrust
  ///   - "t-bar row"                        → row
  ///   - "farmer's carry"                   → generic safety blurb
  ///   - "push-ups"                         → generic safety blurb
  String _routeKey() {
    final name = widget.exercise.name.toLowerCase();
    final eq = (widget.exercise.equipment ?? '').toLowerCase();

    // Most specific first.
    if (name.contains('fly') || name.contains('flye')) return 'fly';
    if (name.contains('romanian deadlift') || name.contains('rdl')) {
      return 'rdl';
    }
    if (name.contains('bulgarian split squat') ||
        name.contains('rear foot elevated') ||
        name.contains('rear-foot-elevated')) {
      return 'bulgarian_split_squat';
    }
    if (name.contains('t-bar row') ||
        name.contains('barbell row') ||
        name.contains('dumbbell row') ||
        name.contains('cable row') ||
        name.contains('seated row') ||
        (name.contains('row') && !name.contains('rower'))) {
      return 'row';
    }
    if (name.contains('overhead squat')) return 'overhead_squat';
    if (name.contains('goblet squat')) return 'goblet_squat';
    if (name.contains('bodyweight squat') ||
        name.contains('air squat') ||
        (name.contains('squat') && eq.contains('bodyweight'))) {
      return 'bodyweight_squat';
    }
    if (name.contains('split squat')) return 'split_squat';
    if (name.contains('back squat') ||
        name.contains('front squat') ||
        name.contains('barbell squat') ||
        (name.contains('squat') && eq.contains('barbell'))) {
      return 'barbell_squat';
    }
    if (name.contains('hip thrust') || name.contains('glute bridge')) {
      return 'hip_thrust';
    }
    if (name.contains('leg curl')) return 'hamstring_curl';
    if (name.contains('curl')) return 'bicep_curl';
    if (name.contains('shoulder press') ||
        name.contains('military press') ||
        name.contains('overhead press')) {
      return 'overhead_press';
    }
    if (name.contains('bench press') ||
        (name.contains('press') && name.contains('bench'))) {
      return 'bench_press';
    }
    if (name.contains('deadlift')) return 'deadlift';
    if (name.contains('pull') &&
        (name.contains('up') || name.contains('down'))) {
      return 'pull';
    }
    return 'generic';
  }

  /// DB-backed instruction steps if the exercise model has them populated.
  /// Returns null if no DB content is available — caller falls through to
  /// the keyword router.
  List<String>? _dbInstructionSteps() {
    final steps = widget.exercise.instructions;
    if (steps == null || steps.isEmpty) return null;
    // Reuse the model's parser if present (handles numbered/sentence-split).
    final parsed = widget.exercise.instructions.toString();
    if (parsed.trim().isEmpty) return null;
    // Try splitting on common separators.
    final lines = parsed
        .split(RegExp(r'(?:\d+[.)]\s*)|(?:\n+)|(?<=\.)\s+(?=[A-Z])'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return lines.length >= 2 ? lines : null;
  }

  List<String> _getSetupInstructions() {
    final db = _dbInstructionSteps();
    if (db != null) return db;

    // If the model carries an explicit `setup` cue, prefer that as the first
    // step alongside the template.
    final setup = widget.exercise.setup;
    final List<String> base;
    switch (_routeKey()) {
      case 'fly':
        base = [
          'Lie back on the bench with feet planted firmly on the floor.',
          'Press the dumbbells up so they meet over your chest, palms facing in.',
          'Keep a soft bend in your elbows — lock that angle for the entire set.',
          'Lower the weights in a wide arc until you feel a stretch across your chest.',
          'Squeeze your pecs to bring the dumbbells back together along the same arc.',
        ];
        break;
      case 'rdl':
        base = [
          'Stand tall holding the bar at hip level, feet hip-width apart.',
          'Soften the knees slightly and keep them locked at that angle.',
          'Hinge at the hips, pushing them straight back as the bar slides down your thighs.',
          'Lower until you feel a strong hamstring stretch (around mid-shin for most lifters).',
          'Drive your hips forward to stand back up — squeeze the glutes at the top.',
        ];
        break;
      case 'bulgarian_split_squat':
        base = [
          'Place the top of your rear foot on a bench behind you.',
          'Step the front foot forward far enough that the front knee tracks over the laces.',
          'Stay tall through the chest, brace your core, and shift weight onto the front leg.',
          'Lower straight down until the front thigh is roughly parallel to the floor.',
          'Drive through the front heel to return to the start.',
        ];
        break;
      case 'row':
        base = [
          'Hinge at the hips with a slight knee bend, back flat.',
          'Grip the bar/handle with arms fully extended.',
          'Brace your core and pin your shoulder blades down before pulling.',
          'Pull the weight to your lower chest / upper abdomen, leading with the elbows.',
          'Lower under control to a full stretch — no body english.',
        ];
        break;
      case 'overhead_squat':
        base = [
          'Hold the bar overhead with a wide grip, arms locked out.',
          'Stand with feet slightly wider than shoulder-width, toes slightly out.',
          'Brace hard and keep the bar stacked over mid-foot the whole rep.',
          'Squat down with the chest tall and the bar tracking straight up.',
          'Drive through the floor to stand back up with the bar still locked overhead.',
        ];
        break;
      case 'goblet_squat':
        base = [
          'Hold a single dumbbell or kettlebell at chest height, elbows tucked under.',
          'Stand with feet just outside shoulder-width, toes slightly out.',
          'Brace the core and squat straight down between the knees.',
          'Use your elbows to gently push the knees out at the bottom.',
          'Drive through mid-foot to stand back up tall.',
        ];
        break;
      case 'bodyweight_squat':
        base = [
          'Stand with feet shoulder-width apart, toes slightly pointed out.',
          'Reach your arms forward for balance as you sit your hips back.',
          'Squat down until thighs are at least parallel to the floor.',
          'Keep your knees tracking in line with your toes — no caving in.',
          'Drive through your whole foot to stand back up tall.',
        ];
        break;
      case 'split_squat':
        base = [
          'Step into a long lunge stance, feet roughly hip-width apart.',
          'Stay tall through the torso with the core braced.',
          'Lower straight down until the back knee hovers just above the floor.',
          'Keep the front knee tracking over the laces, not collapsing inward.',
          'Drive through the front heel to return to the start position.',
        ];
        break;
      case 'barbell_squat':
        base = [
          'Position the bar on your upper back (not your neck).',
          'Stand with feet shoulder-width apart, toes slightly pointed out.',
          'Brace your core hard before descending.',
          'Sit between the hips, knees tracking over toes.',
          'Descend until thighs are at least parallel, then drive up through the floor.',
        ];
        break;
      case 'hip_thrust':
        base = [
          'Sit on the floor with your upper back against a bench, knees bent.',
          'Roll the bar (with a pad) over your hips, feet flat and shoulder-width.',
          'Brace your core and tuck your chin slightly.',
          'Drive through your heels to lift your hips until your body forms a straight line.',
          'Squeeze the glutes hard at the top, then lower under control.',
        ];
        break;
      case 'bicep_curl':
        base = [
          'Stand tall with the weight at arm\'s length, palms facing forward.',
          'Pin your elbows to your sides — they don\'t move during the rep.',
          'Curl the weight up by flexing at the elbow only.',
          'Squeeze the biceps at the top of the rep.',
          'Lower slowly to full extension — no swinging on the way down.',
        ];
        break;
      case 'hamstring_curl':
        base = [
          'Set the machine so the pad sits just above your heels (or below for seated).',
          'Lie/sit with your knees aligned with the machine pivot.',
          'Brace your core and hold the handles for stability.',
          'Curl the pad through a full range, leading with the heels.',
          'Lower under control — don\'t let the stack slam back.',
        ];
        break;
      case 'overhead_press':
        base = [
          'Stand with feet shoulder-width, weight at shoulder height.',
          'Brace your core and squeeze your glutes — no leaning back.',
          'Press the weight straight up overhead, finishing with biceps near your ears.',
          'Lock out at the top with shoulders shrugged into the bar/dumbbells.',
          'Lower under control back to the shoulders.',
        ];
        break;
      case 'bench_press':
        base = [
          'Set up the bench at the appropriate angle (flat, incline, or decline).',
          'Grip the bar slightly wider than shoulder-width.',
          'Plant your feet firmly on the ground.',
          'Retract your shoulder blades and maintain a slight arch in the lower back.',
          'Unrack and position the bar directly above the chest before the first rep.',
        ];
        break;
      case 'deadlift':
        base = [
          'Stand with feet hip-width apart, bar over mid-foot.',
          'Hinge down and grip the bar just outside your legs.',
          'Set a flat back, chest up, lats tight.',
          'Take the slack out of the bar before pulling.',
          'Drive through your whole foot and push your hips through to lockout.',
        ];
        break;
      case 'pull':
        base = [
          'Grip the bar slightly wider than shoulder-width.',
          'Hang with arms fully extended.',
          'Engage your lats before pulling.',
          'Pull your elbows down and back, chest to bar.',
          'Lower with control to full arm extension.',
        ];
        break;
      case 'generic':
      default:
        // Honest fallback — never bench-press copy. Per project rule:
        // "no silent fallbacks" — surface that this is a generic blurb.
        base = [
          'Set up with proper posture and check your form in a mirror if available.',
          'Brace your core before the first rep.',
          'Move under control through the full range of motion.',
          'Breathe out on exertion, in on the way back.',
          'Keep tension on the target muscle — don\'t use momentum.',
        ];
        break;
    }

    if (setup != null && setup.trim().isNotEmpty) {
      // Prepend the AI-coach-provided setup line so it's not lost.
      return [setup.trim(), ...base];
    }
    return base;
  }

  List<String> _getFormTips() {
    // DB-backed form cue takes precedence as the first tip.
    final cue = widget.exercise.formCue;
    final breathing = widget.exercise.breathingCue;
    final List<String> base;
    switch (_routeKey()) {
      case 'fly':
        base = [
          'Keep that elbow angle locked — it\'s a fly, not a press.',
          'Stop just past the line of the bench; deeper isn\'t better here.',
          'Squeeze the chest at the top, don\'t just clank the dumbbells.',
        ];
        break;
      case 'rdl':
        base = [
          'Push the hips back — don\'t just bend forward at the waist.',
          'Bar stays in contact with your legs the whole way down.',
          'Stop where your hamstrings stop — not where your back rounds.',
        ];
        break;
      case 'bulgarian_split_squat':
        base = [
          'Most of your weight stays on the front leg the whole set.',
          'Front shin can travel over the toes — that\'s fine, it\'s a knee-flexion movement.',
          'Stay tall through the chest; don\'t fold over the front leg.',
        ];
        break;
      case 'row':
        base = [
          'Pull with your back — initiate from the lats, not the biceps.',
          'No body english; the torso angle stays put.',
          'Squeeze the shoulder blades together at the top.',
        ];
        break;
      case 'overhead_squat':
        base = [
          'Bar stays directly over mid-foot the entire rep.',
          'Push the hands up and out — keep the lats packed.',
          'Mobility is the gate here — don\'t chase weight if depth disappears.',
        ];
        break;
      case 'goblet_squat':
        base = [
          'Keep elbows tucked under the weight — don\'t flare them.',
          'Chest tall the whole rep; the dumbbell shouldn\'t pull you forward.',
          'Use the elbows to gently nudge the knees out at the bottom.',
        ];
        break;
      case 'bodyweight_squat':
        base = [
          'Drive through the whole foot, not just the heels.',
          'Don\'t let the knees cave inward.',
          'Keep your torso upright — sit between the hips, not over them.',
        ];
        break;
      case 'split_squat':
        base = [
          'Lower straight down — don\'t lunge forward.',
          'Keep the front knee tracking over the second toe.',
          'Brace the core to stay upright — no folding forward.',
        ];
        break;
      case 'barbell_squat':
        base = [
          'Knees track over toes — don\'t let them cave.',
          'Brace the core like you\'re about to be punched.',
          'Drive through the floor on the way up; lead with the chest.',
        ];
        break;
      case 'hip_thrust':
        base = [
          'Finish each rep with a hard glute squeeze, not a back arch.',
          'Keep your chin tucked — eyes track over the knees at the top.',
          'Don\'t over-extend the lower back at lockout.',
        ];
        break;
      case 'bicep_curl':
        base = [
          'Elbows stay pinned at your sides the whole set.',
          'No body english — if you have to swing, the weight is too heavy.',
          'Lower slowly. Eccentrics build biceps.',
        ];
        break;
      case 'hamstring_curl':
        base = [
          'Lead with the heels, don\'t pull with the hip flexors.',
          'Pause briefly in the contracted position.',
          'Lower the weight slowly — fight the eccentric.',
        ];
        break;
      case 'overhead_press':
        base = [
          'Glutes squeezed, ribs down — no lower-back hyperextension.',
          'Bar/dumbbell path is straight up over the shoulders, not in front.',
          'Lock out at the top with shoulders shrugged into the weight.',
        ];
        break;
      case 'bench_press':
        base = [
          'Wrists stay straight and stacked over the elbows.',
          'Lower to mid-chest under control — no bouncing.',
          'Drive through the chest, not just the triceps.',
          'Keep your feet planted; don\'t lift your hips off the bench.',
        ];
        break;
      case 'deadlift':
        base = [
          'Never round the lower back — set the lats before you pull.',
          'Bar stays in contact with your legs the whole rep.',
          'Lock out by squeezing the glutes, not by hyperextending.',
        ];
        break;
      case 'pull':
        base = [
          'Initiate the pull with the lats, not the biceps.',
          'Avoid kipping or swinging.',
          'Lower under control to a full hang or full extension.',
        ];
        break;
      case 'generic':
      default:
        base = [
          'Move under control — don\'t let the weight dictate the tempo.',
          'Keep tension on the target muscle through the full range.',
          'If form breaks down, drop the weight rather than push another rep.',
          'Breathe out on the hard part, in on the easy part.',
        ];
        break;
    }

    if (cue != null && cue.trim().isNotEmpty) {
      base.insert(0, cue.trim());
    }
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
