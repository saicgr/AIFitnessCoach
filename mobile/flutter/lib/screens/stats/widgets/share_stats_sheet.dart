import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/share_service.dart';
import '../../../data/services/stats_gallery_service.dart';
import '../../../utils/image_capture_utils.dart';
import 'share_templates/stats_overview_template.dart';
import 'share_templates/stats_achievements_template.dart';
import 'share_templates/stats_prs_template.dart';

/// Share Stats Bottom Sheet
///
/// Shows a carousel of 3 shareable stats templates and options to:
/// - Share to Instagram Stories (deep link)
/// - Share via system share sheet
/// - Post to app's social feed
/// - Save to gallery
class ShareStatsSheet extends ConsumerStatefulWidget {
  const ShareStatsSheet({super.key});

  /// Show the share stats bottom sheet
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => const ShareStatsSheet(),
    );
  }

  @override
  ConsumerState<ShareStatsSheet> createState() => _ShareStatsSheetState();
}

class _ShareStatsSheetState extends ConsumerState<ShareStatsSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSharing = false;
  bool _isSaving = false;
  String? _userId;
  bool _showWatermark = true;

  // Capture keys for each template (3 templates)
  final List<GlobalKey> _captureKeys = List.generate(3, (_) => GlobalKey());

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

  List<String> get _templateNames => ['Overview', 'Achievements', 'PRs'];

  StatsTemplateType get _currentTemplateType {
    switch (_currentPage) {
      case 0:
        return StatsTemplateType.overview;
      case 1:
        return StatsTemplateType.achievements;
      case 2:
        return StatsTemplateType.prs;
      default:
        return StatsTemplateType.overview;
    }
  }

  String get _dateRangeLabel {
    final customRange = ref.read(customStatsDateRangeProvider);
    if (customRange != null) {
      final formatter = DateFormat('MMM d');
      final start = formatter.format(customRange.start);
      final end = DateFormat('MMM d, yyyy').format(customRange.end);
      return '$start - $end';
    }

    final timeRange = ref.read(heatmapTimeRangeProvider);
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: timeRange.weeks * 7));
    final formatter = DateFormat('MMM d');
    return '${formatter.format(startDate)} - ${DateFormat('MMM d, yyyy').format(now)}';
  }

  Future<Uint8List?> _captureCurrentTemplate() async {
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
        if (_userId != null) {
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
        caption: 'Check out my fitness stats!',
      );

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
    debugPrint('[ShareStats] _postToFeed called');

    HapticFeedback.lightImpact();

    if (_isSharing) {
      debugPrint('[ShareStats] Already sharing, returning');
      _showError('Please wait, another action is in progress...');
      return;
    }

    if (_userId == null) {
      debugPrint('[ShareStats] User ID is null');
      _showError('Please wait, loading user data...');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      debugPrint('[ShareStats] Capturing template...');
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        debugPrint('[ShareStats] Failed to capture template');
        _showError('Failed to capture image');
        return;
      }
      debugPrint('[ShareStats] Template captured: ${bytes.length} bytes');

      // Get stats data
      final statsSnapshot = _buildStatsSnapshot();

      // Upload image
      debugPrint('[ShareStats] Uploading image...');
      final service = ref.read(statsGalleryServiceProvider);
      final image = await service.uploadImage(
        userId: _userId!,
        templateType: _currentTemplateType,
        imageBytes: bytes,
        statsSnapshot: statsSnapshot,
      );
      debugPrint('[ShareStats] Image uploaded: ${image.id}');

      // Share to feed
      debugPrint('[ShareStats] Sharing to feed...');
      await service.shareToFeed(
        userId: _userId!,
        imageId: image.id,
        caption: 'Check out my fitness stats!',
      );
      debugPrint('[ShareStats] Posted to feed successfully');

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Posted to feed!');
      }
    } catch (e, st) {
      debugPrint('[ShareStats] Error posting to feed: $e');
      debugPrint('[ShareStats] Stack trace: $st');
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

      final saveResult = await ShareService.saveToGallery(bytes);

      if (!saveResult.success) {
        _showError(saveResult.error ?? 'Failed to save image');
        return;
      }

      if (_userId != null) {
        try {
          await _saveToGalleryInternal(bytes);
        } catch (e) {
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

    final statsSnapshot = _buildStatsSnapshot();

    final service = ref.read(statsGalleryServiceProvider);
    final image = await service.uploadImage(
      userId: _userId!,
      templateType: _currentTemplateType,
      imageBytes: bytes,
      statsSnapshot: statsSnapshot,
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

  /// Build stats snapshot from current state
  StatsSnapshot _buildStatsSnapshot() {
    final consistencyState = ref.read(consistencyProvider);
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final weeklyProgress = workoutsNotifier.weeklyProgress;

    return StatsSnapshot(
      totalWorkouts: consistencyState.insights?.monthWorkoutsCompleted,
      weeklyCompleted: weeklyProgress.$1,
      weeklyGoal: weeklyProgress.$2,
      currentStreak: consistencyState.currentStreak,
      longestStreak: consistencyState.longestStreak,
      dateRangeLabel: _dateRangeLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return GlassSheet(
      maxHeightFraction: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                    'Share Your Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Placeholder for symmetry
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

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
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
                        horizontal: isActive ? 12 : 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.cyan
                            : Colors.grey.withOpacity(0.3),
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

            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
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
                          label: 'Share',
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

  /// Get background gradient colors for Instagram Story wrapper based on template
  List<Color> _getGradientForTemplate(int index) {
    switch (index) {
      case 0: // Overview - dark blue gradient
        return const [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF21262D)];
      case 1: // Achievements - purple/dark gradient
        return const [Color(0xFF1A1A2E), Color(0xFF2D1B4E), Color(0xFF1A1A2E)];
      case 2: // PRs - blue/dark gradient
        return const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)];
      default:
        return const [Color(0xFF1A2634), Color(0xFF0F1922), Color(0xFF0A0F14)];
    }
  }

  Widget _buildTemplateCarousel() {
    final consistencyState = ref.watch(consistencyProvider);
    final insights = consistencyState.insights;
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    final weeklyProgress = workoutsNotifier.weeklyProgress;

    // Sample achievements data (in production, pull from achievements provider)
    final sampleAchievements = [
      const AchievementData(emoji: '💪', name: 'First PR'),
      const AchievementData(emoji: '🔥', name: '7 Day Streak'),
      const AchievementData(emoji: '🏆', name: '100 Workouts'),
      const AchievementData(emoji: '⚡', name: 'Speed Demon'),
    ];

    // Sample PRs data (in production, pull from PRs provider)
    final samplePRs = [
      const PRData(
        exerciseName: 'Bench Press',
        value: '225',
        unit: 'lbs',
        date: 'Jan 10, 2026',
        type: PRType.weight,
      ),
      const PRData(
        exerciseName: 'Deadlift',
        value: '315',
        unit: 'lbs',
        date: 'Jan 8, 2026',
        type: PRType.weight,
      ),
      const PRData(
        exerciseName: 'Pull-ups',
        value: '15',
        unit: 'reps',
        date: 'Jan 5, 2026',
        type: PRType.reps,
      ),
    ];

    // Format total time
    String formatTotalTime(int? minutes) {
      if (minutes == null || minutes == 0) return '0h';
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
      if (hours > 0) return '${hours}h';
      return '${mins}m';
    }

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        setState(() => _currentPage = index);
      },
      children: [
        // Overview Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[0],
            child: InstagramStoryWrapper(
              backgroundGradient: _getGradientForTemplate(0),
              child: StatsOverviewTemplate(
                totalWorkouts: insights?.monthWorkoutsCompleted ?? workoutsNotifier.completedCount,
                weeklyCompleted: weeklyProgress.$1,
                weeklyGoal: weeklyProgress.$2,
                currentStreak: consistencyState.currentStreak,
                totalTimeFormatted: formatTotalTime(null), // TODO: Add total time tracking
                dateRangeLabel: _dateRangeLabel,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),

        // Achievements Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[1],
            child: InstagramStoryWrapper(
              backgroundGradient: _getGradientForTemplate(1),
              child: StatsAchievementsTemplate(
                achievements: sampleAchievements,
                currentStreak: consistencyState.currentStreak,
                totalWorkouts: insights?.monthWorkoutsCompleted ?? workoutsNotifier.completedCount,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),

        // PRs Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[2],
            child: InstagramStoryWrapper(
              backgroundGradient: _getGradientForTemplate(2),
              child: StatsPRsTemplate(
                recentPRs: samplePRs,
                totalPRCount: samplePRs.length,
                dateRangeLabel: _dateRangeLabel,
                showWatermark: _showWatermark,
              ),
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
        side: BorderSide(color: AppColors.cyan.withOpacity(0.5)),
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
