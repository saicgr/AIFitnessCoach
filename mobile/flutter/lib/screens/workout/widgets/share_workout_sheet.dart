import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/coach_persona.dart';
import '../../../data/providers/workout_gallery_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/share_service.dart';
import '../../../data/services/workout_gallery_service.dart';
import '../../../screens/ai_settings/ai_settings_screen.dart';
import '../../../utils/image_capture_utils.dart';
import 'share_templates/stats_template.dart';
import 'share_templates/prs_template.dart';
import 'share_templates/photo_overlay_template.dart';
import 'share_templates/motivational_template.dart';
import 'share_templates/coach_review_template.dart';
import 'share_templates/progress_template.dart';

/// Share Workout Bottom Sheet
///
/// Shows a carousel of 4 shareable templates and options to:
/// - Share to Instagram Stories (deep link)
/// - Share via system share sheet
/// - Post to app's social feed
/// - Save to gallery
class ShareWorkoutSheet extends ConsumerStatefulWidget {
  final String workoutName;
  final String workoutLogId;
  final int durationSeconds;
  final int? calories;
  final double? totalVolumeKg;
  final int? totalSets;
  final int? totalReps;
  final int exercisesCount;
  final List<Map<String, dynamic>>? newPRs;
  final List<Map<String, dynamic>>? achievements;
  final int? currentStreak;
  final int? totalWorkouts;

  const ShareWorkoutSheet({
    super.key,
    required this.workoutName,
    required this.workoutLogId,
    required this.durationSeconds,
    this.calories,
    this.totalVolumeKg,
    this.totalSets,
    this.totalReps,
    required this.exercisesCount,
    this.newPRs,
    this.achievements,
    this.currentStreak,
    this.totalWorkouts,
  });

  @override
  ConsumerState<ShareWorkoutSheet> createState() => _ShareWorkoutSheetState();
}

class _ShareWorkoutSheetState extends ConsumerState<ShareWorkoutSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSharing = false;
  bool _isSaving = false;
  Uint8List? _userPhotoBytes;
  String? _userId;
  bool _showWatermark = true;

  // Capture keys for each template (6 templates now)
  final List<GlobalKey> _captureKeys = List.generate(6, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (mounted) {
      setState(() => _userId = userId);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _templateNames => [
        'Stats',
        'PRs',
        'Coach',
        'Progress',
        'Photo',
        'Motivational',
      ];

  GalleryTemplateType get _currentTemplateType {
    switch (_currentPage) {
      case 0:
        return GalleryTemplateType.stats;
      case 1:
        return GalleryTemplateType.prs;
      case 2:
        return GalleryTemplateType.stats; // Coach review uses stats type
      case 3:
        return GalleryTemplateType.stats; // Progress uses stats type
      case 4:
        return GalleryTemplateType.photoOverlay;
      case 5:
        return GalleryTemplateType.motivational;
      default:
        return GalleryTemplateType.stats;
    }
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.lightImpact();

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _userPhotoBytes = bytes);

        // Switch to photo overlay template (index 4)
        _pageController.animateToPage(
          4,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      _showError('Failed to pick photo');
    }
  }

  Future<Uint8List?> _captureCurrentTemplate() async {
    // Use Instagram Stories optimal size (1080x1920) for proper aspect ratio
    return await ImageCaptureUtils.captureWidgetWithSize(
      _captureKeys[_currentPage],
      width: ImageCaptureUtils.instagramStoriesSize.width,
      height: ImageCaptureUtils.instagramStoriesSize.height,
      pixelRatio: 1.0,
    );
  }

  Future<void> _shareToInstagram() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();

    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      final result = await ShareService.shareToInstagramStories(bytes);

      if (result.success) {
        // Track external share
        if (_userId != null) {
          // First upload/save the image
          await _saveToGalleryInternal(bytes, trackExternal: true);
        }
        if (mounted) {
          Navigator.pop(context);
          _showSuccess('Opening Instagram...');
        }
      } else if (result.error != null) {
        _showError('Could not open Instagram');
      }
    } catch (e) {
      _showError('Failed to share');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _shareGeneric() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();

    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      await ShareService.shareGeneric(
        bytes,
        caption: 'Just crushed my ${widget.workoutName} workout!',
      );

      // Track external share
      if (_userId != null) {
        await _saveToGalleryInternal(bytes, trackExternal: true);
      }
    } catch (e) {
      _showError('Failed to share');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _postToFeed() async {
    debugPrint('🔍 [ShareWorkout] _postToFeed called');
    debugPrint('🔍 [ShareWorkout] _isSharing: $_isSharing, _userId: $_userId');
    debugPrint('🔍 [ShareWorkout] workoutLogId: "${widget.workoutLogId}"');

    // Show immediate feedback
    HapticFeedback.lightImpact();

    if (_isSharing) {
      debugPrint('⚠️ [ShareWorkout] Already sharing, returning');
      _showError('Please wait, another action is in progress...');
      return;
    }

    if (_userId == null) {
      debugPrint('⚠️ [ShareWorkout] User ID is null, showing error');
      _showError('Please wait, loading user data...');
      return;
    }

    // Validate workoutLogId before attempting upload
    if (widget.workoutLogId.isEmpty) {
      debugPrint('❌ [ShareWorkout] workoutLogId is empty');
      _showError('Cannot post: workout data not saved. Try sharing to Instagram instead.');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() => _isSharing = true);

    try {
      debugPrint('🔍 [ShareWorkout] Capturing template...');
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        debugPrint('❌ [ShareWorkout] Failed to capture template');
        _showError('Failed to capture image');
        return;
      }
      debugPrint('✅ [ShareWorkout] Template captured: ${bytes.length} bytes');

      // Upload image and share to feed
      debugPrint('🔍 [ShareWorkout] Uploading image...');
      final service = ref.read(workoutGalleryServiceProvider);
      final image = await service.uploadImage(
        userId: _userId!,
        workoutLogId: widget.workoutLogId,
        templateType: _currentTemplateType,
        imageBytes: bytes,
        workoutSnapshot: WorkoutSnapshot(
          workoutName: widget.workoutName,
          durationSeconds: widget.durationSeconds,
          calories: widget.calories,
          totalVolumeKg: widget.totalVolumeKg,
          totalSets: widget.totalSets,
          totalReps: widget.totalReps,
          exercisesCount: widget.exercisesCount,
        ),
        prsData: widget.newPRs,
        achievementsData: widget.achievements,
        userPhotoBytes: _userPhotoBytes,
      );
      debugPrint('✅ [ShareWorkout] Image uploaded: ${image.id}');

      // Share to feed
      debugPrint('🔍 [ShareWorkout] Sharing to feed...');
      await service.shareToFeed(
        userId: _userId!,
        imageId: image.id,
        caption: 'Just finished my ${widget.workoutName} workout!',
      );
      debugPrint('✅ [ShareWorkout] Posted to feed successfully');

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Posted to feed!');
      }
    } catch (e, st) {
      debugPrint('❌ [ShareWorkout] Error posting to feed: $e');
      debugPrint('❌ [ShareWorkout] Stack trace: $st');
      _showError('Failed to post to feed: ${e.toString().split(':').last.trim()}');
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();

    setState(() => _isSaving = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      // Save to device gallery/storage
      final saveResult = await ShareService.saveToGallery(bytes);

      if (!saveResult.success) {
        _showError(saveResult.error ?? 'Failed to save image');
        return;
      }

      // Also upload to backend gallery if user is logged in
      if (_userId != null) {
        try {
          await _saveToGalleryInternal(bytes);
        } catch (e) {
          // Don't fail the whole save if backend upload fails
          debugPrint('Backend gallery upload failed: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Saved to device!');
      }
    } catch (e) {
      _showError('Failed to save: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveToGalleryInternal(
    Uint8List bytes, {
    bool trackExternal = false,
  }) async {
    if (_userId == null) return;

    // Skip backend upload if workoutLogId is missing
    if (widget.workoutLogId.isEmpty) {
      debugPrint('⚠️ [ShareWorkout] Skipping backend upload: workoutLogId is empty');
      return;
    }

    final service = ref.read(workoutGalleryServiceProvider);
    final image = await service.uploadImage(
      userId: _userId!,
      workoutLogId: widget.workoutLogId,
      templateType: _currentTemplateType,
      imageBytes: bytes,
      workoutSnapshot: WorkoutSnapshot(
        workoutName: widget.workoutName,
        durationSeconds: widget.durationSeconds,
        calories: widget.calories,
        totalVolumeKg: widget.totalVolumeKg,
        totalSets: widget.totalSets,
        totalReps: widget.totalReps,
        exercisesCount: widget.exercisesCount,
      ),
      prsData: widget.newPRs,
      achievementsData: widget.achievements,
      userPhotoBytes: _userPhotoBytes,
    );

    if (trackExternal) {
      await service.trackExternalShare(
        userId: _userId!,
        imageId: image.id,
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPhotoEditor() async {
    HapticFeedback.lightImpact();

    // Capture current template
    final bytes = await _captureCurrentTemplate();
    if (bytes == null) {
      _showError('Failed to capture image');
      return;
    }

    if (!mounted) return;

    // Navigate to photo editor
    final editedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => _SimplePhotoEditor(
          imageBytes: bytes,
          workoutName: widget.workoutName,
        ),
      ),
    );

    // If user returned edited image, use it for sharing
    if (editedBytes != null && mounted) {
      // Share the edited image directly
      await ShareService.shareGeneric(
        editedBytes,
        caption: 'Just crushed my ${widget.workoutName} workout!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                const Text(
                  'Share Your Workout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Edit button
                IconButton(
                  onPressed: _openPhotoEditor,
                  icon: Icon(
                    Icons.edit_rounded,
                    color: AppColors.cyan,
                  ),
                  tooltip: 'Edit Image',
                ),
              ],
            ),
          ),

          // Watermark toggle row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.branding_watermark_rounded,
                  size: 18,
                  color: _showWatermark ? AppColors.cyan : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Show Watermark',
                  style: TextStyle(
                    fontSize: 14,
                    color: _showWatermark ? null : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _showWatermark,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _showWatermark = value);
                  },
                  activeTrackColor: AppColors.cyan,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
          ),

          // Template carousel
          Expanded(
            child: _buildTemplateCarousel(),
          ),

          // Page indicators - scrollable for 6 templates
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isActive = _currentPage == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: EdgeInsets.symmetric(
                        horizontal: isActive ? 10 : 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.cyan
                            : Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _templateNames[index],
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Add photo button (for photo overlay template - now index 4)
          if (_currentPage == 4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: Icon(
                  _userPhotoBytes != null
                      ? Icons.check_circle_rounded
                      : Icons.add_a_photo_rounded,
                  size: 20,
                ),
                label: Text(
                  _userPhotoBytes != null ? 'Change Photo' : 'Add Your Photo',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  side: BorderSide(
                    color: AppColors.cyan.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primary share buttons row
                Row(
                  children: [
                    Expanded(
                      child: _buildShareButton(
                        onPressed: _shareToInstagram,
                        icon: Icons.camera_alt_rounded,
                        label: 'Instagram',
                        isPrimary: true,
                        isLoading: _isSharing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildShareButton(
                        onPressed: _shareGeneric,
                        icon: Icons.share_rounded,
                        label: 'More',
                        isPrimary: false,
                        isLoading: _isSharing,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Secondary buttons row
                Row(
                  children: [
                    Expanded(
                      child: _buildShareButton(
                        onPressed: _postToFeed,
                        icon: Icons.feed_rounded,
                        label: 'Post to Feed',
                        isPrimary: false,
                        isLoading: _isSharing,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildShareButton(
                        onPressed: _saveToGallery,
                        icon: Icons.save_alt_rounded,
                        label: 'Save Only',
                        isPrimary: false,
                        isLoading: _isSaving,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _showImagePreview() async {
    HapticFeedback.mediumImpact();

    // Capture the current template
    final bytes = await _captureCurrentTemplate();
    if (bytes == null) {
      _showError('Failed to capture image');
      return;
    }

    if (!mounted) return;

    // Show full-screen preview
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) => _ImagePreviewDialog(
        imageBytes: bytes,
        templateName: _templateNames[_currentPage],
      ),
    );
  }

  /// Get background gradient colors for Instagram Story wrapper based on template
  List<Color> _getGradientForTemplate(int index) {
    switch (index) {
      case 0: // Stats - dark blue gradient
        return const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)];
      case 1: // PRs - gold/dark gradient
        return const [Color(0xFF2D1F00), Color(0xFF1A1200), Color(0xFF0D0A00)];
      case 2: // Coach Review - dark gray
        return const [Color(0xFF1A1A1A), Color(0xFF0D0D0D), Color(0xFF000000)];
      case 3: // Progress - teal/dark gradient
        return const [Color(0xFF1A2634), Color(0xFF0F1922), Color(0xFF0A0F14)];
      case 4: // Photo Overlay - near black
        return const [Color(0xFF0A0A0A), Color(0xFF050505), Color(0xFF000000)];
      case 5: // Motivational - black
        return const [Color(0xFF0A0A0A), Color(0xFF000000), Color(0xFF000000)];
      default:
        return const [Color(0xFF1A2634), Color(0xFF0F1922), Color(0xFF0A0F14)];
    }
  }

  Widget _buildTemplateCarousel() {
    final now = DateTime.now();

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() => _currentPage = index);
      },
      children: [
        // Stats Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[0],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(0),
                    child: StatsTemplate(
                      workoutName: widget.workoutName,
                      durationSeconds: widget.durationSeconds,
                      calories: widget.calories,
                      totalVolumeKg: widget.totalVolumeKg,
                      totalSets: widget.totalSets,
                      totalReps: widget.totalReps,
                      exercisesCount: widget.exercisesCount,
                      completedAt: now,
                      showWatermark: _showWatermark,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // PRs Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[1],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(1),
                    child: PrsTemplate(
                      workoutName: widget.workoutName,
                      prsData: widget.newPRs ?? [],
                      achievementsData: widget.achievements,
                      completedAt: now,
                      showWatermark: _showWatermark,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // Coach Review Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final aiSettings = ref.watch(aiSettingsProvider);
                    final coach = CoachPersona.findById(aiSettings.coachPersonaId)
                        ?? CoachPersona.defaultCoach;
                    return CapturableWidget(
                      captureKey: _captureKeys[2],
                      child: InstagramStoryWrapper(
                        backgroundGradient: _getGradientForTemplate(2),
                        child: CoachReviewTemplate(
                          workoutName: widget.workoutName,
                          durationSeconds: widget.durationSeconds,
                          calories: widget.calories,
                          totalVolumeKg: widget.totalVolumeKg,
                          exercisesCount: widget.exercisesCount,
                          totalSets: widget.totalSets,
                          totalReps: widget.totalReps,
                          coach: coach,
                          performanceRating: _calculatePerformanceRating(),
                          completedAt: now,
                          showWatermark: _showWatermark,
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // Progress Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[3],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(3),
                    child: ProgressTemplate(
                      workoutName: widget.workoutName,
                      durationSeconds: widget.durationSeconds,
                      exercisesCount: widget.exercisesCount,
                      totalWorkouts: widget.totalWorkouts,
                      currentStreak: widget.currentStreak,
                      sessionVolume: widget.totalVolumeKg,
                      prsThisMonth: widget.newPRs?.length ?? 0,
                      completedAt: now,
                      showWatermark: _showWatermark,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // Photo Overlay Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[4],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(4),
                    child: PhotoOverlayTemplate(
                      workoutName: widget.workoutName,
                      durationSeconds: widget.durationSeconds,
                      calories: widget.calories,
                      totalVolumeKg: widget.totalVolumeKg,
                      exercisesCount: widget.exercisesCount,
                      userPhotoBytes: _userPhotoBytes,
                      completedAt: now,
                      showWatermark: _showWatermark,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),

        // Motivational Template
        Center(
          child: GestureDetector(
            onTap: _showImagePreview,
            child: Stack(
              children: [
                CapturableWidget(
                  captureKey: _captureKeys[5],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(5),
                    child: MotivationalTemplate(
                      workoutName: widget.workoutName,
                      currentStreak: widget.currentStreak,
                      totalWorkouts: widget.totalWorkouts ?? 1,
                      durationSeconds: widget.durationSeconds,
                      completedAt: now,
                      showWatermark: _showWatermark,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildPreviewHint(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Calculate a performance rating based on workout stats
  double _calculatePerformanceRating() {
    double rating = 0.7; // Base rating

    // Bonus for longer workouts
    if (widget.durationSeconds >= 3600) rating += 0.1; // 1+ hour
    else if (widget.durationSeconds >= 2700) rating += 0.07; // 45+ min
    else if (widget.durationSeconds >= 1800) rating += 0.05; // 30+ min

    // Bonus for more exercises
    if (widget.exercisesCount >= 8) rating += 0.1;
    else if (widget.exercisesCount >= 5) rating += 0.05;

    // Bonus for PRs
    if (widget.newPRs != null && widget.newPRs!.isNotEmpty) {
      rating += 0.1 * (widget.newPRs!.length.clamp(0, 3) / 3);
    }

    // Bonus for volume
    if (widget.totalVolumeKg != null && widget.totalVolumeKg! > 5000) {
      rating += 0.05;
    }

    return rating.clamp(0.5, 1.0);
  }

  Widget _buildPreviewHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.zoom_out_map_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Tap to preview',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isLoading,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan,
        side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.cyan),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }
}

/// Simple photo editor for basic image manipulation
class _SimplePhotoEditor extends StatefulWidget {
  final Uint8List imageBytes;
  final String workoutName;

  const _SimplePhotoEditor({
    required this.imageBytes,
    required this.workoutName,
  });

  @override
  State<_SimplePhotoEditor> createState() => _SimplePhotoEditorState();
}

class _SimplePhotoEditorState extends State<_SimplePhotoEditor> {
  double _brightness = 0.0;
  double _contrast = 1.0;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : AppColorsLight.background,
      appBar: AppBar(
        title: const Text('Edit Image'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSharing ? null : _shareEdited,
            child: Text(
              'Share',
              style: TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            child: Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_buildColorMatrix()),
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Edit controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brightness slider
                Row(
                  children: [
                    Icon(Icons.brightness_6_rounded, color: AppColors.cyan),
                    const SizedBox(width: 12),
                    const Text('Brightness'),
                    const Spacer(),
                    Text('${(_brightness * 100).toInt()}%'),
                  ],
                ),
                Slider(
                  value: _brightness,
                  min: -0.5,
                  max: 0.5,
                  onChanged: (value) => setState(() => _brightness = value),
                  activeColor: AppColors.cyan,
                ),

                const SizedBox(height: 16),

                // Contrast slider
                Row(
                  children: [
                    Icon(Icons.contrast_rounded, color: AppColors.purple),
                    const SizedBox(width: 12),
                    const Text('Contrast'),
                    const Spacer(),
                    Text('${(_contrast * 100).toInt()}%'),
                  ],
                ),
                Slider(
                  value: _contrast,
                  min: 0.5,
                  max: 1.5,
                  onChanged: (value) => setState(() => _contrast = value),
                  activeColor: AppColors.purple,
                ),

                const SizedBox(height: 16),

                // Reset button
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _brightness = 0.0;
                        _contrast = 1.0;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> _buildColorMatrix() {
    // Simple brightness and contrast matrix
    final b = _brightness;
    final c = _contrast;
    final t = (1.0 - c) / 2.0;

    return [
      c, 0, 0, 0, b * 255 + t * 255,
      0, c, 0, 0, b * 255 + t * 255,
      0, 0, c, 0, b * 255 + t * 255,
      0, 0, 0, 1, 0,
    ];
  }

  Future<void> _shareEdited() async {
    setState(() => _isSharing = true);

    try {
      // For now, share the original image with filters applied
      // In a full implementation, we'd capture the filtered image
      await ShareService.shareGeneric(
        widget.imageBytes,
        caption: 'Just crushed my ${widget.workoutName} workout!',
      );

      if (mounted) {
        Navigator.pop(context, widget.imageBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }
}

/// Full-screen image preview dialog with pinch-to-zoom
class _ImagePreviewDialog extends StatelessWidget {
  final Uint8List imageBytes;
  final String templateName;

  const _ImagePreviewDialog({
    required this.imageBytes,
    required this.templateName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dismiss on tap outside
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // Image with pinch-to-zoom
          Center(
            child: Hero(
              tag: 'preview_$templateName',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Template name label
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                templateName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Hint at bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pinch to zoom • Tap anywhere to close',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
