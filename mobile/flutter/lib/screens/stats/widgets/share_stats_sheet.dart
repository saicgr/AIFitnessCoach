import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/providers/milestones_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/models/milestone.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/share_service.dart';
import '../../../data/services/stats_gallery_service.dart';
import '../../../shareables/adapters/stats_adapter.dart';
import '../../../shareables/shareable_sheet.dart';
import '../../../utils/image_capture_utils.dart';
import 'share_templates/stats_overview_template.dart';
import 'share_templates/stats_achievements_template.dart';
import 'share_templates/stats_prs_template.dart';
import 'share_templates/stats_streak_fire_template.dart';
import 'share_templates/stats_weekly_report_template.dart';
import 'share_templates/stats_level_up_template.dart';
import 'share_templates/stats_elite_template.dart';
import '../../../data/providers/cosmetics_provider.dart';
import '../../../data/providers/xp_provider.dart';

/// Share Stats Bottom Sheet
///
/// Shows a carousel of 6 shareable stats templates and options to:
/// - Share to Instagram Stories (deep link)
/// - Share via system share sheet
/// - Post to app's social feed
/// - Save to gallery
class ShareStatsSheet extends ConsumerStatefulWidget {
  const ShareStatsSheet({super.key});

  /// Show the share stats bottom sheet.
  ///
  /// Delegates to the unified `ShareableSheet` via `StatsAdapter` so the
  /// streak / weekly progress / total time fields all reflect a fresh
  /// fetch from the consistency API (kills the "0 day streak with completed
  /// workout" bug). Falls back to the legacy carousel only if the adapter
  /// returns null (no data at all).
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final shareable = await StatsAdapter.fromProviders(ref);
    if (!context.mounted) return;
    if (shareable != null) {
      await ShareableSheet.show(context, data: shareable);
      return;
    }
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

  // Capture keys for each template (7 templates — Elite is cosmetic-gated)
  final List<GlobalKey> _captureKeys = List.generate(7, (_) => GlobalKey());

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

  List<String> get _templateNames =>
      ['Overview', 'Achievements', 'PRs', 'Streak', 'Weekly', 'Level Up', 'Elite'];

  /// Whether the Elite template is unlocked for this user (owns `stats_card_elite`).
  bool get _ownsElite =>
      ref.watch(cosmeticsProvider.select((s) => s.ownsCosmetic('stats_card_elite')));

  StatsTemplateType get _currentTemplateType {
    switch (_currentPage) {
      case 0:
        return StatsTemplateType.overview;
      case 1:
        return StatsTemplateType.achievements;
      case 2:
        return StatsTemplateType.prs;
      case 3:
        return StatsTemplateType.streakFire;
      case 4:
        return StatsTemplateType.weeklyReport;
      case 5:
        return StatsTemplateType.levelUp;
      case 6:
        return StatsTemplateType.elite;
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

  static String _categoryToEmoji(MilestoneCategory category) {
    switch (category) {
      case MilestoneCategory.workouts:
        return '💪';
      case MilestoneCategory.streak:
        return '🔥';
      case MilestoneCategory.strength:
        return '🏆';
      case MilestoneCategory.volume:
        return '⚡';
      case MilestoneCategory.time:
        return '⏱️';
      case MilestoneCategory.weight:
        return '⚖️';
      case MilestoneCategory.prs:
        return '🥇';
      case MilestoneCategory.firstSteps:
        return '🚀';
    }
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
                    color: _showWatermark
                        ? (isDark ? AppColors.accent : AppColorsLight.accent)
                        : Colors.grey,
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
                    activeTrackColor: isDark ? AppColors.accent : AppColorsLight.accent,
                    activeThumbColor: isDark ? AppColors.accentContrast : AppColorsLight.accentContrast,
                  ),
                ],
              ),
            ),

            // Template carousel — defensive try/catch because a stats-share
            // template can hit "Bad state: No element" when underlying lists
            // are empty (no workouts logged, no PRs yet) and a template's
            // internal list ops bypass the guards in _buildTemplateCarousel.
            // Fall back to an empty-state placeholder rather than crashing.
            Expanded(
              child: Builder(
                builder: (context) {
                  try {
                    return _buildTemplateCarousel();
                  } catch (e, st) {
                    debugPrint('⚠️ [ShareStatsSheet] template build failed: $e\n$st');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Log a workout to unlock share templates.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_templateNames.length, (index) {
                    final isActive = _currentPage == index;
                    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
                    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
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
                          horizontal: isActive ? 12 : 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? accent
                              : isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _templateNames[index],
                          style: TextStyle(
                            color: isActive
                                ? accentContrast
                                : isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
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
                      // TODO: Re-enable social features when user base grows
                      // Expanded(
                      //   child: _buildShareButton(
                      //     onPressed: _postToFeed,
                      //     icon: Icons.feed_rounded,
                      //     label: 'Post to Feed',
                      //     isPrimary: false,
                      //     isLoading: _isSharing,
                      //   ),
                      // ),
                      // const SizedBox(width: 12),
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
      case 3: // Streak Fire - orange/red/dark
        return const [Color(0xFF1C1917), Color(0xFF7F1D1D), Color(0xFF1C1917)];
      case 4: // Weekly Report - navy
        return const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)];
      case 5: // Level Up - purple/indigo
        return const [Color(0xFF1E1045), Color(0xFF2E1065), Color(0xFF0F0A2E)];
      default:
        return const [Color(0xFF1A2634), Color(0xFF0F1922), Color(0xFF0A0F14)];
    }
  }

  Widget _buildTemplateCarousel() {
    final consistencyState = ref.watch(consistencyProvider);
    final insights = consistencyState.insights;
    final workoutsNotifier = ref.read(workoutsProvider.notifier);
    // `weeklyProgress` and the milestone/PR projections each touch list
    // operations (`reduce`, `first`, `last`) under the hood — when the
    // user opens the share sheet before any workouts have synced these
    // throw "Bad state: No element". Wrap in try/catch + fallbacks so the
    // sheet still renders zero-state templates instead of crashing.
    (int, int) weeklyProgress;
    try {
      weeklyProgress = workoutsNotifier.weeklyProgress;
    } catch (_) {
      weeklyProgress = (0, 0);
    }

    // Real achievements from milestones provider
    final milestonesState = ref.watch(milestonesProvider);
    List<AchievementData> realAchievements;
    try {
      realAchievements = milestonesState.achieved.take(4).map((mp) {
        return AchievementData(
          emoji: _categoryToEmoji(mp.milestone.category),
          name: mp.milestone.name,
        );
      }).toList();
    } catch (_) {
      realAchievements = const <AchievementData>[];
    }
    // Fallback if no achievements yet
    final achievements = realAchievements.isNotEmpty
        ? realAchievements
        : [const AchievementData(emoji: '🎯', name: 'Getting Started')];

    // Real PRs from scores provider
    final prStats = ref.watch(prStatsProvider);
    List<PRData> realPRs;
    try {
      realPRs = (prStats?.recentPrs ?? []).take(3).map((pr) {
        final date = DateTime.tryParse(pr.achievedAt);
        return PRData(
          exerciseName: pr.exerciseDisplayName,
          value: pr.weightKg.toStringAsFixed(0),
          unit: 'kg',
          date: date != null ? DateFormat('MMM d, yyyy').format(date) : '',
          type: PRType.weight,
        );
      }).toList();
    } catch (_) {
      realPRs = const <PRData>[];
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
                totalTimeFormatted: workoutsNotifier.totalDurationFormatted,
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
                achievements: achievements,
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
                recentPRs: realPRs,
                totalPRCount: realPRs.length,
                dateRangeLabel: _dateRangeLabel,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),

        // Streak Fire Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[3],
            child: InstagramStoryWrapper(
              backgroundGradient: _getGradientForTemplate(3),
              child: StatsStreakFireTemplate(
                currentStreak: consistencyState.currentStreak,
                longestStreak: consistencyState.longestStreak,
                totalWorkouts: insights?.monthWorkoutsCompleted ?? workoutsNotifier.completedCount,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),

        // Weekly Report Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[4],
            child: InstagramStoryWrapper(
              backgroundGradient: _getGradientForTemplate(4),
              child: StatsWeeklyReportTemplate(
                weeklyCompleted: weeklyProgress.$1,
                weeklyGoal: weeklyProgress.$2,
                currentStreak: consistencyState.currentStreak,
                totalTimeFormatted: workoutsNotifier.totalDurationFormatted,
                dateRangeLabel: _dateRangeLabel,
                totalWorkouts: insights?.monthWorkoutsCompleted ?? workoutsNotifier.completedCount,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),

        // Level Up Template
        Center(
          child: CapturableWidget(
            captureKey: _captureKeys[5],
            child: InstagramStoryWrapper(
              backgroundGradient: _getGradientForTemplate(5),
              child: StatsLevelUpTemplate(
                totalWorkouts: insights?.monthWorkoutsCompleted ?? workoutsNotifier.completedCount,
                currentStreak: consistencyState.currentStreak,
                weeklyCompleted: weeklyProgress.$1,
                weeklyGoal: weeklyProgress.$2,
                longestStreak: consistencyState.longestStreak,
                showWatermark: _showWatermark,
              ),
            ),
          ),
        ),

        // Elite Template (cosmetic-gated — owned when user hits Level 75)
        Center(
          child: _ownsElite
              ? CapturableWidget(
                  captureKey: _captureKeys[6],
                  child: InstagramStoryWrapper(
                    backgroundGradient: _getGradientForTemplate(6),
                    child: StatsEliteTemplate(
                      totalWorkouts: insights?.monthWorkoutsCompleted ?? workoutsNotifier.completedCount,
                      currentStreak: consistencyState.currentStreak,
                      longestStreak: consistencyState.longestStreak,
                      weeklyCompleted: weeklyProgress.$1,
                      weeklyGoal: weeklyProgress.$2,
                      xpLevel: ref.watch(xpProvider).userXp?.currentLevel ?? 1,
                      xpTotal: ref.watch(xpProvider).userXp?.totalXp ?? 0,
                      dateRangeLabel: _dateRangeLabel,
                      showWatermark: _showWatermark,
                    ),
                  ),
                )
              : _buildLockedEliteCard(),
        ),
      ],
    );
  }

  Widget _buildLockedEliteCard() {
    final level = ref.watch(xpProvider).userXp?.currentLevel ?? 1;
    final levelsToGo = (75 - level).clamp(0, 999);
    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1000), Color(0xFF2E1D00), Color(0xFF1A0F00)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.lock, color: Color(0xFFFFD700), size: 38),
            ),
            const SizedBox(height: 20),
            const Text(
              'ELITE TEMPLATE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD700),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                levelsToGo > 0
                    ? 'Unlocks at Level 75 · $levelsToGo levels to go'
                    : 'Unlocked at Level 75 — open your Cosmetics',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: accentContrast,
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
                  valueColor: AlwaysStoppedAnimation(accentContrast),
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
        foregroundColor: textColor,
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2)),
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
                valueColor: AlwaysStoppedAnimation(textColor),
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
