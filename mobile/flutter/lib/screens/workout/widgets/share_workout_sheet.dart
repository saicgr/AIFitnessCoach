import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../data/providers/workout_gallery_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/providers/share_preferences_provider.dart';
import '../../../data/services/share_caption_service.dart';
import '../../../data/services/share_service.dart';
import '../../../data/services/workout_gallery_service.dart';
import '../../../utils/image_capture_utils.dart';
import 'share_templates/_share_common.dart';
import 'share_templates/anatomy_hero_template.dart';
import 'share_templates/classic_stats_template.dart';
import 'share_templates/exercise_breakdown_template.dart';
import 'share_templates/newspaper_template.dart';
import 'share_templates/pr_poster_template.dart';
import 'share_templates/receipt_template.dart';
import 'share_templates/retro_80s_template.dart';
import 'share_templates/streak_calendar_template.dart';
import 'share_templates/trading_card_template.dart';
import 'share_templates/transparent_sticker_template.dart';
import 'share_templates/volume_hero_template.dart';
import 'share_templates/wrapped_template.dart';

part 'share_workout_sheet_part_simple_photo_editor.dart';

part 'share_workout_sheet_ui.dart';

part 'share_workout_sheet_ext.dart';


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

  // New fields for the gallery templates (Commit 2+). All optional so
  // existing callers keep working.
  /// Per-muscle set counts — powers the Anatomy Hero + Trading Card top move.
  final Map<String, int>? musclesWorked;
  /// Slim view-model list of exercises — powers Exercise Breakdown / Receipt / Newspaper.
  final List<ShareExerciseSummary>? exercises;
  /// For Trading Card name + Newspaper byline.
  final String? userDisplayName;
  final String? userAvatarUrl;
  /// For Streak Calendar heatmap fill.
  final List<DateTime>? recentWorkoutDates;

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
    this.musclesWorked,
    this.exercises,
    this.userDisplayName,
    this.userAvatarUrl,
    this.recentWorkoutDates,
  });

  @override
  ConsumerState<ShareWorkoutSheet> createState() => _ShareWorkoutSheetState();
}

class _ShareWorkoutSheetState extends ConsumerState<ShareWorkoutSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSharing = false;
  bool _isSaving = false;
  bool _isGeneratingCaption = false;
  Uint8List? _userPhotoBytes;
  String? _userId;
  bool _showWatermark = true;

  // Capture keys for each of the 12 gallery templates.
  // See _buildTemplateGallery() for the canonical template order.
  final List<GlobalKey> _captureKeys = List.generate(12, (_) => GlobalKey());

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
    // Clamp the page cursor against the actual capture key list. PageView
    // callbacks can briefly outrun the child count when templates are
    // added/removed (e.g. cosmetic unlock changes _templateNames length
    // mid-build), throwing `RangeError (length): Invalid value: Not in
    // inclusive range 0..N: M` from `_captureKeys[_currentPage]`.
    if (_captureKeys.isEmpty) return null;
    final safeIndex = _currentPage.clamp(0, _captureKeys.length - 1);
    // Use Instagram Stories optimal size (1080x1920) for proper aspect ratio
    return await ImageCaptureUtils.captureWidgetWithSize(
      _captureKeys[safeIndex],
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
          // Snackbar must reflect what actually happened — the native handler
          // can fall back to the system share sheet when Instagram isn't
          // installed, in which case "Opening Instagram..." would be a lie.
          final message = result.destination == ShareDestination.instagramStories
              ? 'Opening Instagram Stories...'
              : 'Opening share sheet...';
          _showSuccess(message);
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

  /// Generates an AI caption for the current workout via the backend
  /// Gemini endpoint and copies it to the clipboard. Shows a snackbar
  /// with the caption preview so the user sees what they just copied.
  Future<void> _copyAiCaption() async {
    if (_isGeneratingCaption) return;
    HapticFeedback.mediumImpact();
    setState(() => _isGeneratingCaption = true);
    try {
      final useKg = ref.read(useKgForWorkoutProvider);
      final volKg = widget.totalVolumeKg;
      final displayVol = volKg == null
          ? '—'
          : (useKg
              ? '${volKg.round()} kg'
              : '${(volKg * 2.20462).round()} lb');
      final svc = ShareCaptionService(ref.read(apiClientProvider));
      final caption = await svc.generate(
        workoutName: widget.workoutName,
        volumeDisplay: displayVol,
        sets: widget.totalSets ?? 0,
        durationSeconds: widget.durationSeconds,
        topExercise: widget.exercises?.isNotEmpty == true
            ? widget.exercises!.first.name
            : null,
        prCount: widget.newPRs?.length ?? 0,
      );
      await Clipboard.setData(ClipboardData(text: caption));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: "$caption"'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      _showError('Could not generate caption');
    } finally {
      if (mounted) setState(() => _isGeneratingCaption = false);
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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Native showModalBottomSheet drag handle is already rendered
                // by showGlassSheet() via showDragHandle: true — no second
                // handle needed here.

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
            child: _buildTemplateGallery(),
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
                        onPressed: _saveToGallery,
                        icon: Icons.save_alt_rounded,
                        label: 'Save Only',
                        isPrimary: false,
                        isLoading: _isSaving,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildShareButton(
                        onPressed: _copyAiCaption,
                        icon: Icons.auto_awesome,
                        label: _isGeneratingCaption ? 'Writing...' : 'AI Caption',
                        isPrimary: false,
                        isLoading: _isGeneratingCaption,
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

    // Clamp the page cursor against the template list — `_currentPage` is
    // updated by PageView callbacks that can briefly outrun the actual
    // child count when templates are added/removed (e.g. cosmetic unlock
    // changes _templateNames length mid-build), causing
    // `RangeError (length): Invalid value: Not in inclusive range 0..N`.
    final names = _templateNames;
    final safeIndex = names.isEmpty
        ? 0
        : _currentPage.clamp(0, names.length - 1);
    final templateName = names.isEmpty ? '' : names[safeIndex];

    // Show full-screen preview
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (context) => _ImagePreviewDialog(
        imageBytes: bytes,
        templateName: templateName,
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
}
