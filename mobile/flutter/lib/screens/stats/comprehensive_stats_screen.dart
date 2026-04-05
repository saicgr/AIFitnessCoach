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
  String? _userId;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
        _loadTabData(_tabController.index);
      }
    });
    if (widget.initialTab != null && widget.initialTab! >= 0 && widget.initialTab! < 6) {
      _tabController.index = widget.initialTab!;
    }
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(posthogServiceProvider).capture(eventName: 'comprehensive_stats_viewed');
    });
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

      // If openPhotoSheet is requested, switch to Photos tab
      if (widget.openPhotoSheet) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tabController.animateTo(1);
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
        ref.read(scoresProvider.notifier).loadScoresOverview(userId: _userId!);
        ref.read(milestonesProvider.notifier).loadMilestoneProgress(userId: _userId!);
        // Load calendar data for stats (Total/Week/Time)
        ref.read(consistencyProvider.notifier).loadCalendar(userId: _userId!, weeks: 52);
        break;
      case 1: // Photos
        ref.read(progressPhotosNotifierProvider(_userId!).notifier).loadAll();
        break;
      case 2: // Score
        ref.read(scoresProvider.notifier).loadPersonalRecords(userId: _userId!);
        break;
      // Tabs 3-5 (Measurements, Nutrition, Mood) load their own data via providers
    }
  }

  static const _tabLabels = ['Overview', 'Photos', 'Score', 'Measurements', 'Nutrition', 'Mood'];
  static const _tabIcons = [
    Icons.dashboard_rounded,      // Overview
    Icons.photo_library_rounded,  // Photos
    Icons.emoji_events_rounded,   // Score
    Icons.straighten_rounded,     // Measurements
    Icons.restaurant_rounded,     // Nutrition
    Icons.mood_rounded,           // Mood
  ];
  static const _tabColors = [
    Color(0xFF3B82F6), // Overview - Blue
    Color(0xFFA855F7), // Photos - Purple
    Color(0xFFF97316), // Score - Orange
    Color(0xFF22C55E), // Measurements - Green
    Color(0xFFEF4444), // Nutrition - Red
    Color(0xFFEC4899), // Mood - Pink
  ];

  Widget _buildPillTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedText = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: List.generate(_tabLabels.length, (i) {
              final animValue = _tabController.animation?.value ?? 0.0;
              final progress = (1.0 - (animValue - i).abs()).clamp(0.0, 1.0);
              final isSelected = _tabController.index == i;
              final pillColor = _tabColors[i];

              final bg = Color.lerp(
                isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
                pillColor,
                progress,
              )!;
              final fg = Color.lerp(mutedText, Colors.white, progress)!;

              return Padding(
                padding: EdgeInsets.only(right: i < _tabLabels.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _tabController.animateTo(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: pillColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tabIcons[i], size: 16, color: fg),
                        const SizedBox(width: 6),
                        Text(
                          _tabLabels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PillAppBar(
        title: 'Stats & Scores',
        actions: [
          // Time Range Selector (hide on Photos tab)
          PillAppBarAction(
            icon: Icons.calendar_month_outlined,
            visible: _currentTabIndex != 1,
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
