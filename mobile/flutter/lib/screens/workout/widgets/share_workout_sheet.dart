import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/workout_gallery_provider.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/share_service.dart';
import '../../../data/services/workout_gallery_service.dart';
import '../../../utils/image_capture_utils.dart';
import 'share_templates/stats_template.dart';
import 'share_templates/prs_template.dart';
import 'share_templates/photo_overlay_template.dart';
import 'share_templates/motivational_template.dart';

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

  // Capture keys for each template
  final List<GlobalKey> _captureKeys = List.generate(4, (_) => GlobalKey());

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
        return GalleryTemplateType.photoOverlay;
      case 3:
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

        // Switch to photo overlay template
        _pageController.animateToPage(
          2,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      _showError('Failed to pick photo');
    }
  }

  Future<Uint8List?> _captureCurrentTemplate() async {
    return await ImageCaptureUtils.captureWidget(
      _captureKeys[_currentPage],
      pixelRatio: 3.0,
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
    if (_isSharing || _userId == null) return;
    HapticFeedback.mediumImpact();

    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      // Upload image and share to feed
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

      // Share to feed
      await service.shareToFeed(
        userId: _userId!,
        imageId: image.id,
        caption: 'Just finished my ${widget.workoutName} workout!',
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Posted to feed!');
      }
    } catch (e) {
      _showError('Failed to post to feed');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
                const SizedBox(width: 48), // Balance the close button
              ],
            ),
          ),

          // Template carousel
          Expanded(
            child: _buildTemplateCarousel(),
          ),

          // Page indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(
                      horizontal: isActive ? 12 : 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.cyan
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _templateNames[index],
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Add photo button (for photo overlay template)
          if (_currentPage == 2)
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
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
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
    );
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
          child: CapturableWidget(
            captureKey: _captureKeys[0],
            child: StatsTemplate(
              workoutName: widget.workoutName,
              durationSeconds: widget.durationSeconds,
              calories: widget.calories,
              totalVolumeKg: widget.totalVolumeKg,
              totalSets: widget.totalSets,
              totalReps: widget.totalReps,
              exercisesCount: widget.exercisesCount,
              completedAt: now,
            ),
          ),
        ),

        // PRs Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[1],
            child: PrsTemplate(
              workoutName: widget.workoutName,
              prsData: widget.newPRs ?? [],
              achievementsData: widget.achievements,
              completedAt: now,
            ),
          ),
        ),

        // Photo Overlay Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[2],
            child: PhotoOverlayTemplate(
              workoutName: widget.workoutName,
              durationSeconds: widget.durationSeconds,
              calories: widget.calories,
              totalVolumeKg: widget.totalVolumeKg,
              exercisesCount: widget.exercisesCount,
              userPhotoBytes: _userPhotoBytes,
              completedAt: now,
            ),
          ),
        ),

        // Motivational Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[3],
            child: MotivationalTemplate(
              workoutName: widget.workoutName,
              currentStreak: widget.currentStreak,
              totalWorkouts: widget.totalWorkouts ?? 1,
              durationSeconds: widget.durationSeconds,
              completedAt: now,
            ),
          ),
        ),
      ],
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
