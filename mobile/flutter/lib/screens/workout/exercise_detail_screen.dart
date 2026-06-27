import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/cache/cache_first_mixin.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/design_system/zealova.dart';
import '../../core/utils/exercise_name_format.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/favorites_provider.dart';
import '../../core/providers/staples_provider.dart';
import '../../core/providers/exercise_queue_provider.dart';
import '../../core/providers/avoided_provider.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/exercise_stats_widgets.dart';
import '../../data/models/exercise.dart';
import '../../data/models/exercise_history.dart';
import '../../data/providers/exercise_history_provider.dart';
import '../../data/repositories/form_analysis_repository.dart';
import '../../data/services/api_client.dart';
import 'widgets/form_analysis_gauge_card.dart';
import 'widgets/form_analysis_sheet.dart';


import '../../l10n/generated/app_localizations.dart';
part 'exercise_detail_screen_part_previous_set_data.dart';
part 'exercise_detail_screen_part_cue_item.dart';

part 'exercise_detail_screen_ui.dart';


/// Full-screen exercise detail with autoplay video
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final WorkoutExercise exercise;

  /// Initial tab index: 0=Info, 1=Stats, 2=History, 3=Form.
  /// Used when the caller wants to deep-link into a specific tab
  /// (e.g. "View History" from the 3-dot exercise-options sheet).
  final int initialTab;

  /// True when the caller (e.g. the muscle-heatmap "Tag muscles" CTA in
  /// `workout_summary_advanced.dart`) wants the muscle-tag editor opened
  /// automatically after the screen settles. Drives a post-frame scroll
  /// + open of the editor on the Info tab.
  final bool pendingMuscleTag;

  /// BROWSE mode. False (default) → the full active-workout execution screen
  /// (rest timer, set-logging table). True → a read-only library/program
  /// preview: media + title + pills + Favorite/Staple/Queue/Avoid row +
  /// INFO/STATS/HISTORY/FORM tabs, but NO rest-timer card and NO set table
  /// (those assume a live workout and would crash on a null-sets exercise).
  final bool browse;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.initialTab = 0,
    this.pendingMuscleTag = false,
    this.browse = false,
  });

  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin, CacheFirstMixin {
  VideoPlayerController? _videoController;
  String? _imageUrl;
  String? _videoUrl;
  bool _isLoadingMedia = true;
  bool _videoInitialized = false;
  bool _showVideo = true;

  // Playback-speed control for the hero video. The chosen rate persists across
  // a video re-init (e.g. switching exercises) by being re-applied in
  // [_initVideo]. `_speedMenuOpen` toggles the expanded option row.
  double _playbackSpeed = 1.0;
  bool _speedMenuOpen = false;
  static const List<double> _kPlaybackSpeeds = [0.25, 0.5, 0.75, 1.0, 2.0];

  // Rest timer
  Timer? _restTimer;
  int _restSeconds = 0;
  bool _isResting = false;

  // Previous performance
  List<PreviousSetData> _previousSets = [];
  bool _isLoadingPrevious = true;

  // Tab controller for Info/Stats/History floating pill bar
  late TabController _tabController;
  int _selectedTab = 0;

  // Scroll-aware status-bar overlay. The hero header is a LIGHT (white) écorché
  // image drawn full-bleed under the status bar, so the status-bar icons need
  // to be DARK while it's expanded — otherwise white-on-white makes the clock /
  // battery invisible. Once the SliverAppBar collapses to its solid bar we flip
  // to theme-appropriate icons (light on the dark-theme black bar).
  final ScrollController _scrollController = ScrollController();
  bool _headerCollapsed = false;

  // Set true when the route was opened with `pendingMuscleTag: true`. The
  // Info-tab UI watches this in `exercise_detail_screen_ui.dart` and renders
  // a primed "Tag your muscles" editor + scrolls it into view. Cleared once
  // the user saves (or dismisses) so re-renders don't loop.
  bool pendingMuscleTagFlag = false;

  /// Auto-scroll target — assigned in the UI part file when the muscle-tag
  /// editor renders. Triggers `Scrollable.ensureVisible` on the next frame.
  GlobalKey? muscleTagAnchorKey;

  @override
  void initState() {
    super.initState();
    final startTab = widget.initialTab.clamp(0, 3);
    _tabController = TabController(length: 4, vsync: this, initialIndex: startTab);
    _selectedTab = startTab;
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedTab = _tabController.index);
    });

    // Flip the status-bar icon brightness once the 300pt hero collapses to the
    // pinned bar. Threshold ≈ expandedHeight − toolbar − a little slack.
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final collapsed = _scrollController.offset > (300 - kToolbarHeight - 30);
      if (collapsed != _headerCollapsed) {
        setState(() => _headerCollapsed = collapsed);
      }
    });

    // Honor the `pending_muscle_tag` deep-link flag. Force the Info tab
    // (where the muscle editor lives) and let the UI mount the editor in
    // the open state. Auto-scroll happens after first frame so the anchor
    // key has been wired.
    if (widget.pendingMuscleTag) {
      pendingMuscleTagFlag = true;
      _tabController.index = 0;
      _selectedTab = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final key = muscleTagAnchorKey;
        final ctx = key?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 320),
            alignment: 0.1,
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    _loadMediaAndAutoplay();
    _loadPreviousPerformance();
    // Avoided provider is lazy — ensure it's loaded so isAvoided() works
    ref.read(avoidedProvider.notifier).ensureInitialized();

    // Track exercise detail viewed
    ref.read(posthogServiceProvider).capture(
      eventName: 'exercise_detail_viewed',
      properties: {
        'exercise_name': widget.exercise.name,
        'muscle_group': widget.exercise.muscleGroup ?? '',
      },
    );
  }

  /// Slug for the per-exercise disk-cache keys. Uses the library UUID when
  /// available (stable, variant-precise) and falls back to the lower-cased
  /// name so name-only exercises still cache.
  String get _cacheSlug {
    final id = widget.exercise.exerciseId ?? widget.exercise.libraryId;
    return id ?? widget.exercise.name.toLowerCase().trim();
  }

  /// Decode a list of [PreviousSetData] from a backend `sets` payload.
  List<PreviousSetData> _parsePreviousSets(List<dynamic> sets) {
    return sets
        .map((s) => PreviousSetData(
              setNumber: s['set_number'] ?? 0,
              weightKg: (s['weight_kg'] as num?)?.toDouble(),
              reps: s['reps_completed'] as int?,
              setType: s['set_type'] ?? 'working',
              rir: s['rir'] as int?,
              rpe: s['rpe'] as int?,
            ))
        .toList();
  }

  Future<void> _loadPreviousPerformance() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingPrevious = false);
      return;
    }

    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId() ?? '';

    // Cache-first: a re-open of the same exercise paints the previous-set
    // table instantly from disk, then revalidates against the network. The
    // raw `sets` payload is what's persisted (24h TTL, user-scoped).
    await loadCacheFirst<List<Map<String, dynamic>>>(
      cacheKey: 'exercise_detail_last_perf_$_cacheSlug',
      userId: userId,
      ttl: const Duration(hours: 24),
      schemaVersion: 1,
      fetch: () async {
        final response = await apiClient.get(
          '/performance-db/exercise-last-performance/'
          '${Uri.encodeComponent(exerciseName)}',
          queryParameters: {'user_id': userId},
        );
        if (response.statusCode == 200 && response.data != null) {
          final sets = response.data['sets'] as List?;
          return (sets ?? const [])
              .map((s) => Map<String, dynamic>.from(s as Map))
              .toList();
        }
        return const <Map<String, dynamic>>[];
      },
      decode: (json) => (json['sets'] as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList(),
      encode: (sets) => {'sets': sets},
      emit: (sets, {required bool fromCache}) {
        if (!mounted) return;
        // Don't let a late cache emit overwrite a fresh network result.
        if (fromCache && !_isLoadingPrevious) return;
        setState(() {
          if (sets.isNotEmpty) _previousSets = _parsePreviousSets(sets);
          _isLoadingPrevious = false;
        });
      },
      onError: (e, _) {
        debugPrint('Error loading previous performance: $e');
        if (mounted) setState(() => _isLoadingPrevious = false);
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _restTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  /// Initialize + autoplay the looping muted video at [url]. Bounded so a dead
  /// URL can't pin the spinner. Safe to call when [url] is null (no-op).
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

  Future<void> _initVideo(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize().timeout(const Duration(seconds: 10));
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.setLooping(true);
      controller.setVolume(0);
      controller.play();
      // Re-apply the user's chosen playback rate so it survives an exercise
      // switch / re-init (defaults to 1.0 on a fresh screen).
      controller.setPlaybackSpeed(_playbackSpeed);
      setState(() {
        _videoController = controller;
        _videoInitialized = true;
      });
    } catch (e) {
      debugPrint('Video unavailable: $e');
      try {
        await _videoController?.dispose();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _videoController = null;
          _videoInitialized = false;
        });
      }
    }
  }

  /// Resolve the image + video URLs from the backend. Pure network — the
  /// caller (`_loadMediaAndAutoplay`) routes it through [loadCacheFirst].
  Future<Map<String, dynamic>> _resolveMediaUrls(String exerciseName) async {
    final apiClient = ref.read(apiClientProvider);
    String? imageUrl;
    String? videoUrl;

    // Authoritative S3 illustration. Pass exercise_id so we hit the exact
    // library row — without it the backend ilike-on-name path is
    // non-deterministic when multiple rows share a display name.
    try {
      final libraryUuid =
          widget.exercise.exerciseId ?? widget.exercise.libraryId;
      final queryParams = <String, dynamic>{};
      if (libraryUuid != null) queryParams['exercise_id'] = libraryUuid;
      final imageResponse = await apiClient
          .get(
            '/exercise-images/${Uri.encodeComponent(exerciseName)}',
            queryParameters: queryParams.isEmpty ? null : queryParams,
          )
          .timeout(const Duration(seconds: 10));
      if (imageResponse.statusCode == 200 && imageResponse.data != null) {
        imageUrl = imageResponse.data['url'] as String?;
      }
    } catch (_) {}

    // Fall back to the exercise's own gifUrl if the API gave nothing.
    if (imageUrl == null) {
      final gif = widget.exercise.gifUrl;
      if (gif != null && gif.isNotEmpty) imageUrl = gif;
    }

    try {
      final videoResponse = await apiClient
          .get('/videos/by-exercise/${Uri.encodeComponent(exerciseName)}')
          .timeout(const Duration(seconds: 10));
      if (videoResponse.statusCode == 200 && videoResponse.data != null) {
        videoUrl = videoResponse.data['url'] as String?;
      }
    } catch (e) {
      debugPrint('Video lookup failed for $exerciseName: $e');
    }

    return {'imageUrl': imageUrl, 'videoUrl': videoUrl};
  }

  Future<void> _loadMediaAndAutoplay() async {
    final exerciseName = widget.exercise.name;
    if (exerciseName.isEmpty || exerciseName == 'Exercise') {
      setState(() => _isLoadingMedia = false);
      return;
    }

    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId() ?? '';

    // Cache-first: a re-open paints the media header instantly from the
    // disk-cached URLs (and starts the video init right away) instead of
    // waiting on the two lookup round-trips. The network revalidate keeps the
    // URLs fresh. URLs are stable per exercise, so a 24h TTL is generous.
    var videoStarted = false;
    await loadCacheFirst<Map<String, dynamic>>(
      cacheKey: 'exercise_detail_media_$_cacheSlug',
      userId: userId,
      ttl: const Duration(hours: 24),
      schemaVersion: 1,
      fetch: () => _resolveMediaUrls(exerciseName),
      decode: (json) => {
        'imageUrl': json['imageUrl'] as String?,
        'videoUrl': json['videoUrl'] as String?,
      },
      encode: (media) => {
        'imageUrl': media['imageUrl'],
        'videoUrl': media['videoUrl'],
      },
      emit: (media, {required bool fromCache}) {
        if (!mounted) return;
        final newImage = media['imageUrl'] as String?;
        final newVideo = media['videoUrl'] as String?;
        final videoUrlChanged = newVideo != _videoUrl;
        setState(() {
          _imageUrl = newImage;
          _videoUrl = newVideo;
          _isLoadingMedia = false;
        });
        // Initialize the video once. The cached emit fires first and gets us
        // playing immediately; only re-init if the fresh network emit
        // actually changed the resolved URL.
        if (!videoStarted || videoUrlChanged) {
          videoStarted = true;
          _initVideo(newVideo);
        }
      },
      onError: (e, _) {
        debugPrint('Error loading media: $e');
        if (mounted) setState(() => _isLoadingMedia = false);
      },
    );
  }

  void _toggleVideo() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  void _startRestTimer() {
    final restTime = widget.exercise.restSeconds ?? 120;
    setState(() {
      _isResting = true;
      _restSeconds = restTime;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds > 0) {
        setState(() => _restSeconds--);
      } else {
        _stopRestTimer();
      }
    });

    HapticFeedback.mediumImpact();
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSeconds = 0;
    });
    HapticFeedback.lightImpact();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _getRepRange() {
    if (widget.exercise.reps != null) {
      final reps = widget.exercise.reps!;
      if (reps <= 6) return '${reps - 1}-${reps + 1}';
      if (reps <= 12) return '${reps - 2}-${reps + 2}';
      return '${reps - 3}-${reps + 3}';
    }
    return '8-12';
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final totalSets = exercise.sets ?? 3;
    final warmupSets = 2;
    final repRange = _getRepRange();
    final restSeconds = exercise.restSeconds ?? 120;

    // Timed move (warmup / stretch / cardio hold): no sets×reps grid makes
    // sense for a 30-sec "Arm circle", so we surface a single DURATION/HOLD
    // countdown card instead of the set table.
    final int? timedSecs = exercise.durationSeconds ?? exercise.holdSeconds;
    final bool isTimedMove = exercise.isTimed == true ||
        (timedSecs != null && (exercise.sets == null || exercise.sets == 0));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    // The hero media can be a WHITE écorché OR a dark video — either way a top
    // scrim (added in _buildVideoSection) darkens the status-bar strip, so we
    // use LIGHT icons while expanded. Once collapsed, match the solid bar:
    // light icons on the dark-theme black bar, dark icons on a light-theme bar.
    final overlayStyle = (_headerCollapsed && !isDark
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light)
        .copyWith(statusBarColor: Colors.transparent);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App bar with video
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                automaticallyImplyLeading: false, // Remove default back button
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildVideoSection(elevated, textMuted),
                ),
              ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise name (C5: title-cased for display) — Anton masthead.
                  Text(
                    exercise.name.titleCaseExercise.toUpperCase(),
                    style: ZType.disp(30, color: textPrimary),
                  ),
                  const SizedBox(height: 10),

                  // Target muscle + equipment — Barlow uppercase hairline chips.
                  if (exercise.primaryMuscle != null || exercise.muscleGroup != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ZealovaChip(
                          label: _cleanMuscleLabel(
                              exercise.primaryMuscle ?? exercise.muscleGroup ?? ''),
                          selected: true,
                        ),
                        if (exercise.equipment != null)
                          ZealovaChip(
                            label: exercise.equipment!,
                          ),
                      ],
                    ),
                  const SizedBox(height: 20),

                  // Quick action buttons
                  _buildActionRow(exercise, elevated, cardBorder, textMuted, accentColor),
                  const SizedBox(height: 24),

                  // Tab content - switches based on floating pill bar selection
                  if (_selectedTab == 0) ...[
                    // INFO TAB
                    // Instructions
                    if (exercise.instructions != null &&
                        exercise.instructions!.isNotEmpty)
                      _buildInstructionsSection(exercise.instructions!, elevated, textSecondary),

                    // Timer card — a working countdown. For a timed move it
                    // doubles as the DURATION/HOLD timer (seeded with the hold
                    // length); otherwise it's the inter-set rest timer.
                    // Hidden in browse mode (no active workout to rest between).
                    if (!widget.browse) ...[
                      _buildRestTimerCard(
                        isTimedMove ? (timedSecs ?? restSeconds) : restSeconds,
                        elevated,
                        textMuted,
                        textPrimary,
                        label: isTimedMove
                            ? (exercise.holdSeconds != null &&
                                    exercise.durationSeconds == null
                                ? 'Hold'
                                : 'Duration')
                            : null,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Set table — only for rep-based exercises. A timed
                    // warmup/stretch has no sets×reps grid (it's a duration).
                    // Hidden in browse mode — the set targets assume a live
                    // workout and a browse-constructed exercise has null sets.
                    if (!isTimedMove && !widget.browse) ...[
                      // Set table header — Barlow uppercase kicker.
                      const ZealovaSectionKicker('Sets'),
                      const SizedBox(height: 12),

                      // Set table
                      _buildSetTable(warmupSets, totalSets, repRange, exercise.weight, elevated, glassSurface, cardBorder, textPrimary, textMuted, textSecondary),
                      const SizedBox(height: 24),
                    ],

                    // Coaching cues (form, breathing, setup, tempo)
                    _buildCoachingCuesSection(exercise, elevated, cardBorder, textPrimary, textSecondary, textMuted, accentColor),

                    // Exercise info (difficulty, secondary muscles, substitution, notes)
                    _buildExerciseInfoSection(exercise, elevated, cardBorder, textPrimary, textSecondary, textMuted, accentColor),
                  ] else if (_selectedTab == 1) ...[
                    // STATS TAB
                    _buildStatsTabContent(textMuted),
                  ] else if (_selectedTab == 2) ...[
                    // HISTORY TAB
                    _buildHistoryTabContent(textMuted),
                  ] else ...[
                    // FORM TAB
                    _buildFormTabContent(textMuted),
                  ],

                  // Bottom padding for floating pill bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Floating back button
      Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        child: GlassBackButton(
          onTap: () => context.pop(),
          // Hero video can be light or dark — keep dark scrim for contrast.
          forceDarkScrim: true,
        ),
      ),
      // Floating pill bar at bottom
      Positioned(
        left: 0,
        right: 0,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        child: _buildFloatingPillBar(accentColor, isDark),
      ),
        ],
      ),
      ),
    );
  }

  /// Strip the verbose anatomical parentheticals from a target-muscle string so
  /// the chip reads cleanly, e.g.
  ///   "Chest (Pectoralis Major), Middle Back (Latissimus Dorsi, Teres Major)"
  ///   -> "Chest, Middle Back"
  /// Keeps every distinct muscle GROUP (unlike the expanded card's first-only
  /// shortener) but drops the Latin names that blew past the chip width. The
  /// ZealovaChip ellipsis is the final safety net for pathological cases.
  String _cleanMuscleLabel(String raw) {
    if (raw.trim().isEmpty) return '';
    // Drop everything inside parentheses (which itself may contain commas).
    final noParens = raw.replaceAll(RegExp(r'\([^)]*\)'), ' ');
    final groups = <String>[];
    for (final part in noParens.split(',')) {
      final cleaned = part.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleaned.isNotEmpty && !groups.contains(cleaned)) groups.add(cleaned);
    }
    return groups.isEmpty ? raw.trim() : groups.join(', ');
  }

  Widget _buildFloatingPillBar(Color accentColor, bool isDark) {
    final pillBarColor = isDark
        ? Colors.grey.shade900.withValues(alpha: 0.92)
        : Colors.grey.shade100.withValues(alpha: 0.95);
    final iconMuted = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    // Full-width bar with four EVEN segments, each showing its icon AND label
    // at all times (not just the selected one) — the user wants every tab
    // worded and visible by default. Equal Expanded segments guarantee the bar
    // always fits the screen regardless of label length.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: pillBarColor,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildPillItem(Icons.info_outline, Icons.info_rounded, 'Info', 0, accentColor, iconMuted, isDark),
            _buildPillItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats', 1, accentColor, iconMuted, isDark),
            _buildPillItem(Icons.history_outlined, Icons.history_rounded, 'History', 2, accentColor, iconMuted, isDark),
            _buildPillItem(Icons.sports_gymnastics_outlined, Icons.sports_gymnastics_rounded, 'Form', 3, accentColor, iconMuted, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPillItem(IconData icon, IconData selectedIcon, String label, int index, Color accentColor, Color mutedColor, bool isDark) {
    final isSelected = _selectedTab == index;
    final fg = isSelected ? accentColor : mutedColor;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _tabController.animateTo(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: isDark ? 0.18 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                color: fg,
                size: 17,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(10.5, color: fg, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTabContent(Color textMuted) {
    final exerciseName = widget.exercise.name;
    final historyAsync = ref.watch(exerciseHistoryProvider(exerciseName));

    return historyAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Error loading history: $error')),
      ),
      data: (history) {
        final sessions = history.sortedSessionsNewestFirst;

        if (sessions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history_outlined, size: 48, color: textMuted),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).exerciseDetailNoHistoryForThis,
                    style: ZType.ser(14, color: textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).exerciseDetailYourSessionsWillAppear,
                    style: ZType.ser(12, color: textMuted.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          );
        }

        // Weight-over-time sparkline (Signature v2 Frame 4). Oldest→newest
        // left to right; the latest point is the screen's single orange dot.
        final useLbs = !ref.watch(useKgForWorkoutProvider);
        final weightPoints = sessions.reversed
            .where((s) => s.weightKg > 0)
            .map((s) => useLbs ? s.weightKg * 2.20462 : s.weightKg)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (weightPoints.length >= 2) ...[
              Text(
                'WEIGHT OVER TIME',
                style: ZType.lbl(10,
                    color: textMuted, letterSpacing: 2.0),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                width: double.infinity,
                child: CustomPaint(
                  painter: _HistoryWeightSparkline(
                    values: weightPoints,
                    lineColor: textMuted,
                    prColor: ThemeColors.of(context).accent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              '${sessions.length} SESSION${sessions.length == 1 ? '' : 'S'}',
              style: ZType.lbl(12, color: textMuted, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            ...sessions.map((session) => ExerciseSessionCard(session: session)),
          ],
        );
      },
    );
  }

  Widget _buildVideoSection(Color elevated, Color textMuted) {
    return GestureDetector(
      onTap: _toggleVideo,
      child: Container(
        color: elevated,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isLoadingMedia)
              // Layout-matched shimmer that fills the whole 300pt header so
              // the media → skeleton swap is reflow-free. A re-open is seeded
              // from the disk cache and skips this entirely.
              const SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                radius: 0,
              )
            else if (_videoInitialized && _showVideo && _videoController != null)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
            else if (_imageUrl != null)
              CachedNetworkImage(
                imageUrl: _imageUrl!,
                fit: BoxFit.cover,
                // Shimmer while the (already-resolved) image bytes download.
                placeholder: (_, __) => const SkeletonBox(
                  width: double.infinity,
                  height: double.infinity,
                  radius: 0,
                ),
                errorWidget: (_, __, ___) => _buildPlaceholder(elevated, textMuted),
              )
            else
              _buildPlaceholder(elevated, textMuted),

            // Status-bar scrim — keeps the phone's clock/battery legible over a
            // WHITE video/image frame (the écorché bleeds under the notch).
            // Pairs with the LIGHT status-bar icons set above.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: MediaQuery.of(context).padding.top + 16,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x73000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
            ),

            // Play/Pause overlay
            if (_videoInitialized && _videoController != null)
              Center(
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Video/Image toggle
            if (_videoUrl != null && _imageUrl != null)
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showVideo = !_showVideo;
                      if (_showVideo && _videoController != null) {
                        _videoController!.play();
                      } else if (_videoController != null) {
                        _videoController!.pause();
                        _speedMenuOpen = false; // hide speed menu with the video
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _showVideo ? Icons.image : Icons.play_circle,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showVideo ? AppLocalizations.of(context).exerciseDetailImage : AppLocalizations.of(context).workoutShowcaseVideo,
                          style: ZType.lbl(12, color: Colors.white, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Playback-speed control — only while the video is actually
            // showing. A tap on the pill expands the 0.25x–2x options upward;
            // the inner GestureDetectors win the arena so they don't trigger
            // the section's play/pause tap.
            if (_videoInitialized && _showVideo && _videoController != null)
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: _speedMenuOpen
                          // IntrinsicWidth bounds the menu so the inner
                          // stretch-Column has a finite width to stretch to.
                          // The Positioned (left+bottom only) otherwise hands it
                          // an unbounded width → "forces infinite width" crash.
                          ? IntrinsicWidth(
                              child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                // High opacity + hairline border so it stays
                                // legible over a WHITE video frame too.
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.18)),
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
                                          style: ZType.lbl(
                                            13,
                                            color: s == _playbackSpeed
                                                ? ref.colors(context).accent
                                                : Colors.white,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          setState(() => _speedMenuOpen = !_speedMenuOpen),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          // Near-opaque dark pill + hairline border → crisp on a
                          // white video frame (black54 goes muddy grey there).
                          color: Colors.black.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.speed, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              _formatSpeed(_playbackSpeed),
                              style: ZType.lbl(12,
                                  color: Colors.white, letterSpacing: 0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color elevated, Color textMuted) {
    return Container(
      color: elevated,
      child: Center(
        child: Icon(
          Icons.fitness_center,
          size: 64,
          color: textMuted,
        ),
      ),
    );
  }

  Widget _buildInstructionsSection(String instructions, Color elevated, Color textSecondary) {
    // Hairline section (no boxed card): Barlow kicker + Fraunces coaching line.
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZealovaSectionKicker(
            AppLocalizations.of(context).workoutShowcaseInstructions,
          ),
          const SizedBox(height: 12),
          Text(
            instructions,
            style: ZType.ser(15, color: textSecondary, height: 1.5),
          ),
          const SizedBox(height: 4),
          const ZealovaRule(margin: EdgeInsets.only(top: 16)),
        ],
      ),
    );
  }

  Widget _buildRestTimerCard(int defaultSeconds, Color elevated, Color textMuted, Color textPrimary, {String? label}) {
    final mins = defaultSeconds ~/ 60;
    final secs = defaultSeconds % 60;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;
    // Default label is the localized "Rest Timer"; a timed move overrides it
    // with "Duration" / "Hold".
    final cardLabel =
        (label ?? AppLocalizations.of(context).exerciseDetailRestTimer).toUpperCase();

    return GestureDetector(
      onTap: _isResting ? _stopRestTimer : _startRestTimer,
      child: ZealovaCard(
        // While resting, the timer is the one accent-tinted focus on screen.
        variant: _isResting
            ? ZealovaCardVariant.hero
            : ZealovaCardVariant.outlined,
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: _isResting ? accentColor : textMuted,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cardLabel,
                    style: ZType.lbl(
                      11,
                      color: _isResting ? accentColor : textMuted,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Telemetry numeral — Space Mono.
                  Text(
                    _isResting
                        ? _formatTime(_restSeconds)
                        : '${mins}m ${secs}s',
                    style: ZType.data(
                      26,
                      color: _isResting ? accentColor : textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _isResting ? 'SKIP' : 'START',
              style: ZType.lbl(13, color: accentColor, letterSpacing: 2.0),
            ),
          ],
        ),
      ),
    );
  }

  /// Get previous performance for a specific set
  PreviousSetData? _getPreviousSet(int setNumber, bool isWarmup) {
    final setType = isWarmup ? 'warmup' : 'working';
    try {
      return _previousSets.firstWhere(
        (s) => s.setNumber == setNumber && s.setType == setType,
      );
    } catch (_) {
      // Try to find any set with same number regardless of type
      try {
        return _previousSets.firstWhere((s) => s.setNumber == setNumber);
      } catch (_) {
        return null;
      }
    }
  }

  /// Format previous set display (e.g., "40 × 7")
  String _formatPreviousSet(PreviousSetData? previous) {
    if (previous == null) return '-';
    final weight = previous.weightKg;
    final reps = previous.reps;
    if (weight == null && reps == null) return '-';
    // Bodyweight (no load): "BW × 7" rather than a bare "× 7".
    if (weight == null || weight <= 0) return 'BW × $reps';
    if (reps == null) return '${weight.toInt()}';
    return '${weight.toInt()} × $reps';
  }

  /// Get RIR color based on value (matching WorkoutDesign colors)
  Color _getRirColor(int rir) {
    if (rir <= 0) return const Color(0xFFEF4444); // Red - failure
    if (rir == 1) return const Color(0xFFF97316); // Orange
    if (rir == 2) return const Color(0xFFEAB308); // Yellow
    return const Color(0xFF22C55E); // Green for 3+
  }

  /// Get RIR text color for contrast
  Color _getRirTextColor(int rir) {
    if (rir == 2) return Colors.black87; // Dark text on yellow
    return Colors.white;
  }

  Widget _buildSetTable(int warmupSets, int workingSets, String repRange, double? weight, Color elevated, Color glassSurface, Color cardBorder, Color textPrimary, Color textMuted, Color textSecondary) {
    final hasPrevious = _previousSets.isNotEmpty;
    final exercise = widget.exercise;
    final setTargets = exercise.setTargets ?? [];

    return Column(
        children: [
          // Header - matches active workout screen: Set | Previous | Target (weight × reps + RIR)
          Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.hairlineStrong),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text(AppLocalizations.of(context).workoutSummaryAdvancedSet.toUpperCase(), style: ZType.lbl(10, color: textMuted, letterSpacing: 1.2))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(AppLocalizations.of(context).summaryExerciseTablePrevious.toUpperCase(), style: ZType.lbl(10, color: textMuted, letterSpacing: 1.2)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(AppLocalizations.of(context).workoutSummaryAdvancedTarget.toUpperCase(), style: ZType.lbl(10, color: textMuted, letterSpacing: 1.2)),
                ),
              ],
            ),
          ),

          // Build rows from setTargets - NO FALLBACK, must fail if setTargets is empty
          ...setTargets.asMap().entries.map((entry) {
            final index = entry.key;
            final target = entry.value;
            final isWarmup = target.setType == 'warmup';
            final previous = _getPreviousSet(target.setNumber, isWarmup);

            return _buildTableRow(
              setLabel: isWarmup ? 'W' : '${target.setNumber}',
              isWarmup: isWarmup,
              previousData: previous,
              hasPrevious: hasPrevious,
              targetWeight: target.targetWeightKg,
              targetReps: target.targetReps,
              targetRir: target.targetRir,
              isLast: index == setTargets.length - 1,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textMuted: textMuted,
              textSecondary: textSecondary,
            );
          }),
        ],
    );
  }
}

/// Signature v2 weight-over-time sparkline for the History tab. Draws a thin
/// hairline path across the session weights (oldest→newest), marks the prior
/// points as small muted dots, and renders the latest point as the screen's
/// single orange (accent) focal dot. No axes/labels — a magazine spark, not a
/// full chart (the Stats tab carries the full progression chart).
class _HistoryWeightSparkline extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color prColor;

  const _HistoryWeightSparkline({
    required this.values,
    required this.lineColor,
    required this.prColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const double padX = 6;
    const double padY = 10;
    final double w = size.width - padX * 2;
    final double h = size.height - padY * 2;

    double minV = values.reduce((a, b) => a < b ? a : b);
    double maxV = values.reduce((a, b) => a > b ? a : b);
    if (maxV - minV < 0.0001) {
      // Flat history — center the line so it doesn't collapse.
      minV -= 1;
      maxV += 1;
    }

    Offset pointAt(int i) {
      final double x = padX + (w * i / (values.length - 1));
      final double t = (values[i] - minV) / (maxV - minV);
      final double y = padY + h * (1 - t);
      return Offset(x, y);
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Prior points — small muted dots.
    final dotPaint = Paint()..color = lineColor.withValues(alpha: 0.6);
    for (var i = 0; i < values.length - 1; i++) {
      canvas.drawCircle(pointAt(i), 2.2, dotPaint);
    }

    // Latest point — the single orange focal dot, with a soft halo.
    final last = pointAt(values.length - 1);
    canvas.drawCircle(
      last,
      6,
      Paint()..color = prColor.withValues(alpha: 0.22),
    );
    canvas.drawCircle(last, 3.5, Paint()..color = prColor);
  }

  @override
  bool shouldRepaint(_HistoryWeightSparkline oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.prColor != prColor;
}
