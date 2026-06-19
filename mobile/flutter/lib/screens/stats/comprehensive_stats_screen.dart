import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/animations/app_animations.dart';
import '../../data/providers/consistency_provider.dart';
import '../../data/providers/milestones_provider.dart';
import '../../data/providers/scores_provider.dart';
import '../../data/repositories/progress_photos_repository.dart';
import '../../data/services/api_client.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/design_system/zealova.dart';
import '../../core/services/posthog_service.dart';
import '../progress/comparison_view.dart';
import 'widgets/date_range_filter_sheet.dart';
import 'widgets/export_stats_sheet.dart';
import 'widgets/share_stats_sheet.dart';
import 'widgets/overview_tab.dart';
import 'widgets/photos_tab.dart';
import 'widgets/strength_tab.dart';
import 'widgets/measurements_tab.dart';
import 'widgets/nutrition_tab.dart';
import 'widgets/mood_tab.dart';
import '../progress/dashboard/progressive_overload_dashboard_screen.dart';

import '../../l10n/generated/app_localizations.dart';
/// Comprehensive Stats Screen
/// Combines: Workout stats, achievements, body measurements, progress graphs, nutrition
class ComprehensiveStatsScreen extends ConsumerStatefulWidget {
  /// If true, opens the add photo sheet immediately after loading
  final bool openPhotoSheet;

  /// If set, opens this tab index on load
  final int? initialTab;

  const ComprehensiveStatsScreen({
    super.key,
    this.openPhotoSheet = false,
    this.initialTab,
  });

  @override
  ConsumerState<ComprehensiveStatsScreen> createState() => _ComprehensiveStatsScreenState();
}

class _ComprehensiveStatsScreenState extends ConsumerState<ComprehensiveStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _pillScrollController = ScrollController();
  String? _userId;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
        _loadTabData(_tabController.index);
        _scrollToSelectedPill(_tabController.index);
      }
    });
    if (widget.initialTab != null && widget.initialTab! >= 0 && widget.initialTab! < 7) {
      _tabController.index = widget.initialTab!;
      _currentTabIndex = widget.initialTab!;
    }
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'comprehensive_stats_viewed');
      _scrollToSelectedPill(_tabController.index);
    });
  }

  void _scrollToSelectedPill(int index) {
    if (!_pillScrollController.hasClients) return;
    // Each pill is roughly 120px wide (padding + icon + text + gap)
    const estimatedPillWidth = 120.0;
    final viewportWidth = _pillScrollController.position.viewportDimension;
    final targetOffset = (index * estimatedPillWidth - viewportWidth / 2 + estimatedPillWidth / 2)
        .clamp(0.0, _pillScrollController.position.maxScrollExtent);
    _pillScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  final Set<int> _loadedTabs = {};

  Future<void> _loadData() async {
    final userId = await ref.read(apiClientProvider).getUserId();
    if (userId != null && mounted) {
      setState(() {
        _userId = userId;
      });
      // Only load overview tab data on init — other tabs load lazily
      _loadTabData(0);

      // If openPhotoSheet is requested, switch to Photos tab (now index 2 after
      // the Overload tab was inserted at index 1).
      if (widget.openPhotoSheet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tabController.animateTo(2);
          }
        });
      }
    }
  }

  void _loadTabData(int tabIndex) {
    if (_userId == null || _loadedTabs.contains(tabIndex)) return;
    _loadedTabs.add(tabIndex);

    switch (tabIndex) {
      case 0: // Overview — scores + milestones + calendar stats
        // All four loaders fire in parallel (notifiers are non-blocking).
        // We also pre-warm the activity heatmap for the default 3M range so
        // the chart isn't a second wave of fetches when its widget mounts —
        // before this, the chart spinner stayed up ~500ms after the rest of
        // the page rendered, making the screen feel half-loaded.
        Future.wait<void>([
          Future.sync(() => ref
              .read(scoresProvider.notifier)
              .loadScoresOverview(userId: _userId!)),
          Future.sync(() => ref
              .read(milestonesProvider.notifier)
              .loadMilestoneProgress(userId: _userId!)),
          Future.sync(() => ref
              .read(consistencyProvider.notifier)
              .loadCalendar(userId: _userId!, weeks: 52)),
        ]);
        // Pre-warm the heatmap. Default range matches overview_tab.dart's
        // initial `heatmapTimeRangeProvider` (3M = 13 weeks). FutureProvider
        // dedupes the fetch when the chart widget watches it later.
        // Wrapped in Future.microtask so the read runs after the current
        // setState pass — avoids "ref used after dispose" if the user back-
        // swipes immediately.
        Future.microtask(() {
          if (!mounted) return;
          ref.read(activityHeatmapProvider((
            userId: _userId!,
            weeks: 13,
            startDate: null,
            endDate: null,
          )));
        });
        break;
      // case 1 (Overload) self-fetches via overloadDashboardProvider on mount.
      case 2: // Photos
        ref.read(progressPhotosNotifierProvider(_userId!).notifier).loadAll();
        break;
      case 3: // Score
        ref.read(scoresProvider.notifier).loadPersonalRecords(userId: _userId!);
        break;
      // Tabs 4-6 (Measurements, Nutrition, Mood) load their own data via providers
    }
  }

  static const _tabLabels = ['Overview', 'Overload', 'Photos', 'Score', 'Measurements', 'Nutrition', 'Mood'];

  Widget _buildPillTabBar() {
    // Signature text-tabs: Barlow uppercase labels with an accent underline on
    // the active item. Horizontally scrollable to keep all six tabs reachable.
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return SingleChildScrollView(
          controller: _pillScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: ZealovaTextTabs(
            tabs: _tabLabels,
            activeIndex: _tabController.index,
            onChanged: (i) {
              HapticFeedback.lightImpact();
              _tabController.animateTo(i);
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pillScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).youHubStatsScores,
        actions: [
          // Time Range Selector — hide on Overload (index 1, has its own range
          // bar) and Photos (index 2).
          PillAppBarAction(
            icon: Icons.calendar_month_outlined,
            visible: _currentTabIndex != 1 && _currentTabIndex != 2,
            onTap: () => DateRangeFilterSheet.show(context, ref),
          ),
          // Export
          PillAppBarAction(
            icon: Icons.file_download_outlined,
            onTap: () => ExportStatsSheet.show(context, ref),
          ),
          // Share
          PillAppBarAction(
            icon: Icons.ios_share_outlined,
            onTap: () => ShareStatsSheet.show(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Pill Tab Bar
          _buildPillTabBar(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const OverviewTab(),
                const ProgressiveOverloadDashboardScreen(),
                PhotosTab(userId: _userId, openPhotoSheet: widget.openPhotoSheet),
                StrengthTab(userId: _userId),
                MeasurementsTab(userId: _userId),
                NutritionTab(userId: _userId),
                const MoodTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComparisonPicker() {
    if (_userId == null) return;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (context) => ComparisonView(userId: _userId!),
      ),
    );
  }
}
