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

import '../../../core/constants/app_colors.dart';
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
    MaterialPageRoute(
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
  bool _videoError = false;

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

  /// Load video URL from API
  Future<void> _loadVideoUrl() async {
    final exerciseName = widget.exercise.name;

    try {
      final apiClient = ref.read(apiClientProvider);

      // Fetch presigned video URL from backend
      final videoResponse = await apiClient.get(
        '/videos/by-exercise/${Uri.encodeComponent(exerciseName)}',
      );

      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        _videoUrl = videoResponse.data['url'] as String?;

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
    }

    if (mounted && _videoUrl == null) {
      setState(() {
        _isLoadingVideo = false;
      });
    }
  }

  /// Initialize video player
  Future<void> _initializeVideo() async {
    if (_videoUrl == null) return;

    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(_videoUrl!));
      await _videoController!.initialize();
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
                  widget.exercise.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  maxLines: 1,
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

    if (_isVideoInitialized && _videoController != null) {
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
            // Video player - centered and fitted
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            ),
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

    // Placeholder when no video - show the exercise image
    return Center(
      child: ExerciseImage(
        exerciseName: widget.exercise.name,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.5,
        borderRadius: 0,
        fit: BoxFit.contain,
        backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
        iconColor: textMuted,
      ),
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

  List<String> _getSetupInstructions() {
    final name = widget.exercise.name.toLowerCase();

    if (name.contains('bench') || name.contains('press')) {
      return [
        'Set up the bench at the appropriate angle (flat, incline, or decline).',
        'Grip the bar slightly wider than shoulder-width.',
        'Plant your feet firmly on the ground.',
        'Retract your shoulder blades and maintain a slight arch in your lower back.',
        'Unrack the weight and position it directly above your chest.',
      ];
    } else if (name.contains('squat')) {
      return [
        'Position the bar on your upper back (not your neck).',
        'Stand with feet shoulder-width apart, toes slightly pointed out.',
        'Brace your core before descending.',
        'Keep your knees tracking over your toes.',
        'Descend until thighs are at least parallel to the floor.',
      ];
    } else if (name.contains('deadlift')) {
      return [
        'Stand with feet hip-width apart, bar over mid-foot.',
        'Grip the bar just outside your legs.',
        'Keep your back flat and chest up.',
        'Take the slack out of the bar before pulling.',
        'Drive through your heels and push hips forward.',
      ];
    } else if (name.contains('row')) {
      return [
        'Hinge at the hips with a slight knee bend.',
        'Keep your back flat and core engaged.',
        'Grip the weight with arms extended.',
        'Pull the weight toward your lower chest/upper abs.',
        'Squeeze your shoulder blades together at the top.',
      ];
    } else if (name.contains('curl')) {
      return [
        'Stand with feet shoulder-width apart.',
        'Grip the weight with palms facing up.',
        'Keep your elbows close to your sides.',
        'Curl the weight toward your shoulders.',
        'Lower with control to full arm extension.',
      ];
    } else if (name.contains('pull') &&
        (name.contains('up') || name.contains('down'))) {
      return [
        'Grip the bar slightly wider than shoulder-width.',
        'Hang with arms fully extended.',
        'Engage your lats before pulling.',
        'Pull your elbows down and back.',
        'Lower with control to full arm extension.',
      ];
    }

    // Default generic instructions
    return [
      'Set up your equipment and check your form in a mirror if available.',
      'Warm up with lighter weight first.',
      'Position yourself in the starting position.',
      'Focus on controlled movements throughout.',
      'Breathe consistently - exhale on exertion.',
    ];
  }

  List<String> _getFormTips() {
    final name = widget.exercise.name.toLowerCase();

    if (name.contains('bench') || name.contains('press')) {
      return [
        'Keep your wrists straight and stacked over your elbows.',
        'Lower the bar to your mid-chest with control.',
        'Press through your chest, not just your arms.',
        'Maintain tension at the bottom - no bouncing.',
        'Keep your feet planted and avoid lifting your hips.',
      ];
    } else if (name.contains('squat')) {
      return [
        'Keep your weight in your heels and mid-foot.',
        'Go as deep as your mobility allows with good form.',
        "Don't let your knees cave inward.",
        'Stand up by driving your hips forward.',
        'Keep your core braced throughout the movement.',
      ];
    } else if (name.contains('deadlift')) {
      return [
        'Never round your lower back.',
        'Keep the bar close to your body throughout.',
        "Lock out by squeezing your glutes, not hyperextending.",
        "Lower with control - don't drop the weight.",
        'Reset your position between each rep.',
      ];
    } else if (name.contains('row')) {
      return [
        'Initiate the pull with your back, not your arms.',
        'Keep your core tight to protect your lower back.',
        'Avoid jerky movements - stay controlled.',
        'Focus on the muscle contraction at the top.',
        'Keep your neck neutral - look at the floor.',
      ];
    } else if (name.contains('curl')) {
      return [
        'Keep your upper arms stationary.',
        "Don't swing the weight or use your back.",
        'Squeeze at the top of the movement.',
        'Lower slowly for maximum tension.',
        "Don't fully lock out at the bottom to maintain tension.",
      ];
    }

    // Default generic tips
    return [
      'Focus on mind-muscle connection.',
      'Control the weight through the full range of motion.',
      'Avoid using momentum - let the target muscle do the work.',
      'If form breaks down, reduce the weight.',
      'Take your time and prioritize quality over quantity.',
    ];
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
        MaterialPageRoute(
          builder: (context) => ExerciseInstructionsScreen(exercise: exercise),
        ),
      );
    });
    return const SizedBox.shrink();
  }
}
