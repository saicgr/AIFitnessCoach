import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/banner_notification_mapper.dart';
import '../../notifications/notifications_screen.dart';
import '../../../data/providers/billing_reminder_provider.dart';
import '../../../data/providers/scheduling_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/providers/week1_tips_provider.dart';
import '../../../data/providers/weekly_plan_provider.dart';
import '../../../data/providers/wrapped_provider.dart';
import '../../../data/providers/xp_provider.dart'
    show activeDoubleXPEventProvider, dailyCratesProvider, showDailyCrateBannerProvider,
         unclaimedCratesProvider, unclaimedCratesCountProvider;
import '../../../data/repositories/xp_repository.dart' show UnclaimedCrate;
import '../../../data/models/weekly_plan.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/scheduling_repository.dart' show MissedWorkout;
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../workout/widgets/reschedule_sheet.dart';
import 'open_all_crates_sheet.dart';
import 'banner_card_data.dart';
import 'compact_banner_card.dart';
import 'stacked_banner_controller.dart';

/// A phone notification-panel style stacked banner system.
///
/// Collects ALL active banners (not just the highest priority), renders them
/// as uniform 84px cards stacked with peek edges, and supports per-card
/// swipe-to-dismiss revealing the next card underneath.
class StackedBannerPanel extends ConsumerStatefulWidget {
  const StackedBannerPanel({super.key});

  @override
  ConsumerState<StackedBannerPanel> createState() => _StackedBannerPanelState();
}

class _StackedBannerPanelState extends ConsumerState<StackedBannerPanel>
    with TickerProviderStateMixin {
  static const double _cardHeight = CompactBannerCard.cardHeight;
  static const double _peekOffset = 8.0;
  static const int _maxVisiblePeeks = 2;
  static const int _maxMissedWorkoutBanners = 3;

  late AnimationController _dismissController;
  Animation<double>? _dismissAnimation;
  double _dragOffset = 0;
  bool _isDragging = false;
  bool _isAnimatingDismiss = false;

  // Dismiss-all X badge → pill animation
  late AnimationController _dismissAllController;
  late Animation<double> _dismissAllAnimation;
  bool _isDismissAllExpanded = false;

  // Contextual banner dismiss state (loaded from SharedPreferences)
  Set<String> _contextualDismissedKeys = {};
  bool _contextualPrefsLoaded = false;

  // Wrapped banner dismiss state
  Map<String, bool> _wrappedDismissedMap = {};

  // Missed workout persistent dismiss state
  Set<String> _dismissedMissedWorkoutIds = {};

  // Week 1 tip same-day dismiss state
  bool _week1TipDismissedToday = false;

  // Session flag: when dismiss-all is used, suppress ALL banners until
  // the widget is remounted (e.g. user navigates away and back).
  bool _allBannersDismissed = false;

  @override
  void initState() {
    super.initState();
    _dismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dismissController.addListener(_onDismissAnimationTick);

    _dismissAllController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dismissAllAnimation = CurvedAnimation(
      parent: _dismissAllController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _loadDismissState();
  }

  @override
  void dispose() {
    _dismissController.removeListener(_onDismissAnimationTick);
    _dismissController.dispose();
    _dismissAllController.dispose();
    super.dispose();
  }

  void _onDismissAnimationTick() {
    if (_dismissAnimation != null && mounted) {
      setState(() {
        _dragOffset = _dismissAnimation!.value;
      });
    }
  }

  Future<void> _loadDismissState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekKey = '${monday.year}-${monday.month}-${monday.day}';

    final contextualKeys = <String>{};

    final fastingDismissed = prefs.getString('contextual_banner_fasting_dismissed');
    if (fastingDismissed != null) contextualKeys.add(fastingDismissed);

    final weeklyDismissed = prefs.getString('contextual_banner_weekly_dismissed');
    if (weeklyDismissed == weekKey) contextualKeys.add('weekly_$weekKey');

    final prDismissed = prefs.getString('contextual_banner_pr_dismissed');
    if (prDismissed == todayKey) contextualKeys.add('pr_$todayKey');

    final wrappedMap = <String, bool>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('wrapped_dismissed_')) {
        final period = key.replaceFirst('wrapped_dismissed_', '');
        wrappedMap[period] = prefs.getBool(key) ?? false;
      }
    }

    // Load persistently dismissed missed workout IDs
    final missedIds = prefs.getStringList('dismissed_missed_workout_ids') ?? [];
    // Prune to max 20 entries
    final prunedMissedIds = missedIds.length > 20
        ? missedIds.sublist(missedIds.length - 20)
        : missedIds;

    // Check if week1 tip was dismissed today
    final week1Dismissed = prefs.getString('week1_tip_dismissed_$todayKey');

    if (mounted) {
      setState(() {
        _contextualDismissedKeys = contextualKeys;
        _contextualPrefsLoaded = true;
        _wrappedDismissedMap = wrappedMap;
        _dismissedMissedWorkoutIds = prunedMissedIds.toSet();
        _week1TipDismissedToday = week1Dismissed != null;
      });
    }
  }

  /// Collect all active banners from their providers.
  List<BannerCardData> _collectBanners() {
    final banners = <BannerCardData>[];
    final dismissedIds = ref.watch(stackedBannerControllerProvider);

    // 1. Renewal reminder
    final renewalState = ref.watch(upcomingRenewalProvider);
    final renewal = renewalState.valueOrNull;
    if (renewal != null && renewal.showBanner) {
      final days = renewal.daysUntilRenewal ?? 0;
      final urgencyColor = days <= 1
          ? Colors.red
          : days <= 3
              ? AppColors.orange
              : AppColors.cyan;
      banners.add(BannerCardData(
        type: BannerType.renewal,
        id: 'renewal',
        icon: Icons.credit_card_rounded,
        title: 'Subscription Renewing',
        subtitle: '${renewal.tier ?? "Plan"} renews in $days days for ${renewal.formattedAmount}',
        accentColor: urgencyColor,
        actionLabel: 'Manage',
        onAction: () {
          HapticService.light();
          context.push('/settings/subscription');
        },
      ));
    }

    // 2. Missed workouts (filter dismissed, cap at 3)
    final missedAsync = ref.watch(missedWorkoutsProvider);
    final missedWorkouts = (missedAsync.valueOrNull ?? [])
        .where((w) => !_dismissedMissedWorkoutIds.contains('missed_${w.id}'))
        .take(_maxMissedWorkoutBanners);
    for (final workout in missedWorkouts) {
      banners.add(BannerCardData(
        type: BannerType.missedWorkout,
        id: 'missed_${workout.id}',
        icon: Icons.schedule_rounded,
        title: 'Missed: ${_formatWorkoutType(workout.type)}',
        subtitle: '${workout.missedDescription} · ${workout.durationMinutes}min · ${workout.exercisesCount} exercises',
        accentColor: AppColors.orange,
        actionLabel: 'Do Today',
        onAction: () => _handleDoToday(workout),
        onTap: () => _handleDoToday(workout),
        payload: workout,
      ));
    }

    // 3. Daily crate (includes accumulated unclaimed crates)
    final showCrate = ref.watch(showDailyCrateBannerProvider);
    final unclaimedCount = ref.watch(unclaimedCratesCountProvider);
    // Show banner if today's crate is available OR there are past unclaimed crates
    if (showCrate || unclaimedCount > 0) {
      final displayCount = unclaimedCount > 0 ? unclaimedCount : 1;
      banners.add(BannerCardData(
        type: BannerType.dailyCrate,
        id: 'daily_crate',
        emoji: '🎁',
        title: displayCount > 1
            ? '$displayCount Crates Available!'
            : 'Daily Crate Available!',
        subtitle: displayCount > 1
            ? '$displayCount crates ready to open'
            : 'Tap to pick your reward',
        accentColor: const Color(0xFFFFB300),
        actionLabel: displayCount > 1 ? 'Open All' : 'Open',
        onTap: () {
          HapticService.medium();
          _showOpenAllCratesSheet();
        },
      ));
    }

    // 4. Double XP event
    final doubleXPEvent = ref.watch(activeDoubleXPEventProvider);
    if (doubleXPEvent != null) {
      final remaining = doubleXPEvent.endAt.difference(DateTime.now());
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes % 60;
      final timeStr = hours > 0 ? '${hours}h ${minutes}m left' : '${minutes}m left';
      banners.add(BannerCardData(
        type: BannerType.doubleXP,
        id: 'double_xp_${doubleXPEvent.id}',
        icon: Icons.bolt_rounded,
        title: '${doubleXPEvent.xpMultiplier.toInt()}x XP Active',
        subtitle: '${doubleXPEvent.eventName} · $timeStr',
        accentColor: AppColors.orange,
        onTap: () {
          HapticService.light();
          context.push('/xp');
        },
      ));
    }

    // 5. Week 1 tip (skip if dismissed today)
    final week1Tip = ref.watch(week1TipProvider);
    if (week1Tip != null && !_week1TipDismissedToday) {
      banners.add(BannerCardData(
        type: BannerType.week1Tip,
        id: 'week1_${week1Tip.featureKey}',
        icon: week1Tip.icon,
        title: week1Tip.title,
        subtitle: week1Tip.subtitle,
        accentColor: week1Tip.accentColor,
        actionLabel: 'Try It',
        onTap: () {
          HapticService.light();
          if (week1Tip.actionRoute != null) {
            context.push(week1Tip.actionRoute!);
          }
        },
      ));
    }

    // 6. Contextual banners
    if (_contextualPrefsLoaded) {
      final contextualBanner = _determineContextualBanner();
      if (contextualBanner != null) {
        banners.add(contextualBanner);
      }
    }

    // 7. Wrapped banner
    final wrappedAsync = ref.watch(wrappedSummaryProvider);
    final wrappedSummary = wrappedAsync.valueOrNull;
    if (wrappedSummary != null) {
      for (final info in wrappedSummary.available) {
        if (!info.viewed) {
          // State A: unviewed wrapped - always show (not dismissible until viewed)
          final month = info.monthDisplayName.toUpperCase();
          final volumeStr = _formatVolume(info.totalVolumeLbs);
          banners.add(BannerCardData(
            type: BannerType.wrapped,
            id: 'wrapped_${info.period}',
            emoji: '✨',
            title: 'Your $month Wrapped Is Here',
            subtitle: '${info.totalWorkouts} workouts · $volumeStr lifted',
            accentColor: const Color(0xFF9D4EDD),
            actionLabel: 'View',
            onTap: () {
              HapticService.medium();
              context.push('/wrapped/${info.period}');
            },
          ));
        } else if (!(_wrappedDismissedMap[info.period] ?? false)) {
          // State B: viewed but not dismissed
          final month = info.monthDisplayName;
          banners.add(BannerCardData(
            type: BannerType.wrapped,
            id: 'wrapped_${info.period}',
            emoji: '✨',
            title: '$month Wrapped',
            subtitle: 'Tap to revisit your gym personality',
            accentColor: const Color(0xFF7B2FF7),
            actionLabel: 'View',
            onTap: () {
              HapticService.light();
              context.push('/wrapped/${info.period}');
            },
          ));
        }
      }
    }

    // Filter out session-dismissed banners
    banners.removeWhere((b) => dismissedIds.contains(b.id));

    return banners;
  }

  BannerCardData? _determineContextualBanner() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekKey = '${monday.year}-${monday.month}-${monday.day}';

    // Weekly goal progress (Thu-Sun)
    if (today.weekday >= 4) {
      final weeklyDismissKey = 'weekly_$weekKey';
      if (!_contextualDismissedKeys.contains(weeklyDismissKey)) {
        final weeklyPlanState = ref.watch(weeklyPlanProvider);
        final plan = weeklyPlanState.currentPlan;
        if (plan != null) {
          int completedCount = 0;
          int plannedCount = 0;
          for (final entry in plan.dailyEntries) {
            if (entry.dayType == DayType.training) {
              plannedCount++;
              if (entry.workoutCompleted) completedCount++;
            }
          }
          final remaining = plannedCount - completedCount;
          if (remaining > 0 && remaining <= 3) {
            final workoutWord = remaining == 1 ? 'workout' : 'workouts';
            return BannerCardData(
              type: BannerType.contextual,
              id: 'contextual_weekly_$weekKey',
              icon: Icons.flag_outlined,
              title: 'Keep it up!',
              subtitle: "You're $remaining $workoutWord away from your weekly goal",
              accentColor: AppColors.cyan,
              actionLabel: 'View',
              onTap: () {
                HapticService.light();
                context.push('/workouts');
              },
            );
          }
        }
      }
    }

    // Recent PR celebration
    final prDismissKey = 'pr_$todayKey';
    if (!_contextualDismissedKeys.contains(prDismissKey)) {
      final prStats = ref.watch(prStatsProvider);
      if (prStats != null && prStats.recentPrs.isNotEmpty) {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        for (final pr in prStats.recentPrs) {
          try {
            final prDate = DateTime.parse(pr.achievedAt);
            final prDateOnly = DateTime(prDate.year, prDate.month, prDate.day);
            final todayOnly = DateTime(now.year, now.month, now.day);
            final yesterdayOnly = DateTime(yesterday.year, yesterday.month, yesterday.day);
            if (prDateOnly == todayOnly || prDateOnly == yesterdayOnly) {
              final weightLbs = (pr.weightKg * 2.205).round();
              return BannerCardData(
                type: BannerType.contextual,
                id: 'contextual_pr_$todayKey',
                icon: Icons.emoji_events_outlined,
                title: 'New PR!',
                subtitle: '${pr.exerciseName}: $weightLbs lbs',
                accentColor: AppColors.success,
                actionLabel: 'View',
                onTap: () {
                  HapticService.light();
                  context.push('/stats');
                },
              );
            }
          } catch (_) {}
        }
      }
    }

    return null;
  }

  Future<void> _handleDoToday(MissedWorkout workout) async {
    HapticService.medium();
    final result = await showRescheduleSheet(context, ref, workout: workout);
    if (result == true && mounted) {
      ref.read(stackedBannerControllerProvider.notifier).dismiss('missed_${workout.id}');
    }
  }

  Future<void> _handleSwipeDismiss(BannerCardData banner) async {
    HapticService.light();
    ref.read(stackedBannerControllerProvider.notifier).dismiss(banner.id);
    await _persistBannerDismissal(banner);
    ref.read(notificationsProvider.notifier).addNotification(
      BannerNotificationMapper.toNotification(banner),
    );
  }

  Future<void> _showCrateDismissConfirmation(List<BannerCardData> banners) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Collapse the pill immediately
    setState(() => _isDismissAllExpanded = false);
    _dismissAllController.reverse();

    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Dialog(
        backgroundColor: isDark ? AppColors.elevated : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'You have unopened crates!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open them before dismissing?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondary : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              // Open All button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, 'open'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Open All',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Dismiss Anyway
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'dismiss'),
                child: Text(
                  'Dismiss Anyway',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondary : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (result == 'open') {
      HapticService.medium();
      // Open the crate selection grid
      _showOpenAllCratesSheet();
      // Dismiss all non-crate banners
      final nonCrateIds = banners
          .where((b) => b.type != BannerType.dailyCrate)
          .map((b) => b.id)
          .toList();
      ref.read(stackedBannerControllerProvider.notifier).dismissAll(nonCrateIds);
      for (final b in banners.where((b) => b.type != BannerType.dailyCrate)) {
        _persistBannerDismissal(b);
      }
    } else if (result == 'dismiss') {
      _executeDismissAll(banners);
    }
  }

  void _showOpenAllCratesSheet() {
    var unclaimed = ref.read(unclaimedCratesProvider).valueOrNull ?? [];

    // If no accumulated unclaimed crates, build from today's daily crate state
    if (unclaimed.isEmpty) {
      final dailyCrates = ref.read(dailyCratesProvider);
      if (dailyCrates != null && dailyCrates.hasAvailableCrate) {
        unclaimed = [
          UnclaimedCrate(
            crateDate: dailyCrates.crateDate,
            dailyCrateAvailable: dailyCrates.dailyCrateAvailable,
            streakCrateAvailable: dailyCrates.streakCrateAvailable,
            activityCrateAvailable: dailyCrates.activityCrateAvailable,
          ),
        ];
      }
    }

    if (unclaimed.isEmpty) return;

    showGlassSheet(
      context: context,
      builder: (ctx) => GlassSheet(
        child: OpenAllCratesSheet(
          unclaimedCrates: unclaimed,
          onAllCollected: () {
            // Dismiss the crate banner after all crates collected
            ref.read(stackedBannerControllerProvider.notifier).dismiss('daily_crate');
            ref.invalidate(unclaimedCratesProvider);
          },
        ),
      ),
    );
  }

  static String _formatWorkoutType(String type) {
    const typeLabels = {
      'push': 'Push',
      'pull': 'Pull',
      'legs': 'Legs',
      'full_body': 'Full Body',
      'upper': 'Upper Body',
      'upper_body': 'Upper Body',
      'lower': 'Lower Body',
      'lower_body': 'Lower Body',
      'core': 'Core',
      'strength': 'Strength',
      'recovery': 'Recovery',
      'cardio': 'Cardio',
      'mobility': 'Mobility',
    };
    if (type.isEmpty) return 'Workout';
    return typeLabels[type.toLowerCase()] ??
        type.split('_').map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : w).join(' ');
  }

  static String _formatVolume(double lbs) {
    if (lbs >= 1000000) return '${(lbs / 1000000).toStringAsFixed(1)}M lbs';
    if (lbs >= 1000) return '${(lbs / 1000).toStringAsFixed(0)}K lbs';
    return '${lbs.toStringAsFixed(0)} lbs';
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimatingDismiss) return;
    setState(() {
      _isDragging = true;
      _dragOffset += details.delta.dx;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, BannerCardData topBanner) {
    if (_isAnimatingDismiss) return;
    final velocity = details.primaryVelocity ?? 0;
    final screenWidth = MediaQuery.of(context).size.width;

    if (_dragOffset.abs() > 100 || velocity.abs() > 800) {
      // Dismiss: animate off screen
      final targetOffset = _dragOffset > 0 ? screenWidth : -screenWidth;
      _isAnimatingDismiss = true;

      _dismissAnimation = Tween<double>(
        begin: _dragOffset,
        end: targetOffset,
      ).animate(CurvedAnimation(
        parent: _dismissController,
        curve: Curves.easeOut,
      ));

      _dismissController.reset();
      _dismissController.forward().then((_) {
        if (mounted) {
          _dismissAnimation = null;
          _isAnimatingDismiss = false;
          setState(() {
            _dragOffset = 0;
            _isDragging = false;
          });
          _handleSwipeDismiss(topBanner);
        }
      });
    } else {
      // Spring back
      _dismissAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0,
      ).animate(CurvedAnimation(
        parent: _dismissController,
        curve: Curves.easeOut,
      ));

      _dismissController.reset();
      _dismissController.forward().then((_) {
        if (mounted) {
          _dismissAnimation = null;
          setState(() {
            _isDragging = false;
            _dragOffset = 0;
          });
        }
      });
    }
  }

  /// Persist dismissal for a single banner (reused by swipe + dismiss-all).
  Future<void> _persistBannerDismissal(BannerCardData banner) async {
    if (banner.type == BannerType.renewal) {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      if (userId != null) {
        ref.read(dismissRenewalBannerProvider(userId));
        ref.invalidate(upcomingRenewalProvider);
      }
    } else if (banner.type == BannerType.wrapped) {
      final period = banner.id.replaceFirst('wrapped_', '');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wrapped_dismissed_$period', true);
      if (mounted) setState(() => _wrappedDismissedMap[period] = true);
    } else if (banner.type == BannerType.contextual) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      if (banner.id.contains('weekly_')) {
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final weekKey = '${monday.year}-${monday.month}-${monday.day}';
        await prefs.setString('contextual_banner_weekly_dismissed', weekKey);
      } else if (banner.id.contains('pr_')) {
        final todayKey = '${today.year}-${today.month}-${today.day}';
        await prefs.setString('contextual_banner_pr_dismissed', todayKey);
      }
    } else if (banner.type == BannerType.week1Tip) {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      await prefs.setString('week1_tip_dismissed_$todayKey', banner.id);
      if (mounted) setState(() => _week1TipDismissedToday = true);
    } else if (banner.type == BannerType.missedWorkout) {
      final prefs = await SharedPreferences.getInstance();
      _dismissedMissedWorkoutIds.add(banner.id);
      await prefs.setStringList(
        'dismissed_missed_workout_ids',
        _dismissedMissedWorkoutIds.toList(),
      );
      // Also mark as skipped on backend so it won't reappear after reinstall
      final workoutId = banner.id.replaceFirst('missed_', '');
      if (workoutId.isNotEmpty) {
        ref.read(schedulingActionProvider.notifier).skipWorkout(
          workoutId,
          reasonCategory: 'dismissed',
        );
      }
    }
  }

  /// Execute dismiss-all: session dismiss + persist each banner type.
  void _executeDismissAll(List<BannerCardData> banners) {
    HapticService.medium();

    // Set session flag so build() returns empty immediately —
    // prevents any banner from surviving due to async provider timing.
    _allBannersDismissed = true;

    final ids = banners.map((b) => b.id).toList();
    ref.read(stackedBannerControllerProvider.notifier).dismissAll(ids);

    // Persist dismissals and create notifications for all banner types
    for (final banner in banners) {
      _persistBannerDismissal(banner);
      ref.read(notificationsProvider.notifier).addNotification(
        BannerNotificationMapper.toNotification(banner),
      );
    }

    setState(() => _isDismissAllExpanded = false);
    _dismissAllController.reverse();
  }

  void _onDismissAllTap(List<BannerCardData> banners) {
    if (banners.isEmpty) return;

    HapticService.light();

    if (!_isDismissAllExpanded) {
      // First tap: expand X into "Dismiss All" pill
      setState(() => _isDismissAllExpanded = true);
      _dismissAllController.forward();

      // Auto-collapse after 3 seconds if not tapped again
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isDismissAllExpanded) {
          setState(() => _isDismissAllExpanded = false);
          _dismissAllController.reverse();
        }
      });
    } else {
      // Second tap: check for crate banners before dismissing
      final hasCrate = banners.any((b) => b.type == BannerType.dailyCrate);
      if (hasCrate) {
        _showCrateDismissConfirmation(banners);
      } else {
        _executeDismissAll(banners);
      }
    }
  }

  Widget _buildDismissAllBadge(List<BannerCardData> banners) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _onDismissAllTap(banners),
      child: AnimatedBuilder(
        animation: _dismissAllAnimation,
        builder: (context, child) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isDismissAllExpanded ? 8 : 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDismissAllExpanded
                    ? AppColors.orange.withOpacity(0.5)
                    : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.close_rounded,
                  size: 12,
                  color: _isDismissAllExpanded
                      ? AppColors.orange
                      : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary),
                ),
                // Animated "Dismiss All" label
                SizeTransition(
                  sizeFactor: _dismissAllAnimation,
                  axis: Axis.horizontal,
                  child: FadeTransition(
                    opacity: _dismissAllAnimation,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Dismiss All',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // After dismiss-all, suppress everything until widget remounts
    if (_allBannersDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final current = ref.read(activeBannerIdsProvider);
          if (current.isNotEmpty) {
            ref.read(activeBannerIdsProvider.notifier).state = [];
          }
        }
      });
      return const SizedBox.shrink();
    }

    final banners = _collectBanners();

    // Report active banner IDs so other widgets can read them
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final ids = banners.map((b) => b.id).toList();
        final current = ref.read(activeBannerIdsProvider);
        if (ids.length != current.length || !ids.every(current.contains)) {
          ref.read(activeBannerIdsProvider.notifier).state = ids;
        }
      }
    });

    if (banners.isEmpty) {
      // Reset dismiss-all state when all banners gone
      if (_isDismissAllExpanded) {
        _isDismissAllExpanded = false;
        _dismissAllController.reset();
      }
      return const SizedBox.shrink();
    }

    final visibleCount = banners.length.clamp(1, _maxVisiblePeeks + 1);
    final totalHeight = _cardHeight + (_peekOffset * (visibleCount - 1));

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Render cards from back to front (bottom of stack first)
              for (int i = (visibleCount - 1).clamp(0, banners.length - 1); i >= 0; i--)
                _buildStackedCard(banners, i, visibleCount),

              // Dismiss-all X badge (top right of banner stack)
              Positioned(
                right: 0,
                top: -8,
                child: _buildDismissAllBadge(banners),
              ),

              // Card count indicator
              if (banners.length > 1)
                Positioned(
                  right: 8,
                  bottom: 0,
                  child: _buildCountBadge(banners.length),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStackedCard(List<BannerCardData> banners, int index, int visibleCount) {
    final isTop = index == 0;
    final depthIndex = index; // 0 = top, 1 = second, 2 = third
    final yOffset = depthIndex * _peekOffset;
    final scale = 1.0 - (depthIndex * 0.03);
    final opacity = depthIndex == 0 ? 1.0 : (depthIndex == 1 ? 0.7 : 0.4);

    Widget card = Transform.scale(
      scaleX: scale,
      alignment: Alignment.topCenter,
      child: Opacity(
        opacity: opacity,
        child: CompactBannerCard(data: banners[index]),
      ),
    );

    if (isTop) {
      // Top card: apply drag offset and gesture detection
      card = GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, banners[0]),
        child: Transform.translate(
          offset: Offset(_dragOffset, 0),
          child: Opacity(
            opacity: _isDragging
                ? (1.0 - (_dragOffset.abs() / MediaQuery.of(context).size.width).clamp(0.0, 0.6))
                : 1.0,
            child: CompactBannerCard(data: banners[index]),
          ),
        ),
      );
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      top: yOffset,
      left: 0,
      right: 0,
      child: card,
    );
  }

  Widget _buildCountBadge(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : AppColorsLight.glassSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
          width: 0.5,
        ),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
        ),
      ),
    );
  }
}
