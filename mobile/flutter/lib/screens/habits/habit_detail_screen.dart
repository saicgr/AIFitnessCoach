import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/habit.dart';
import '../../data/providers/habits_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/share_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../utils/image_capture_utils.dart';
import '../../widgets/segmented_tab_bar.dart';

// ============================================
// DATA MODELS
// ============================================

class HabitDetailData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isAutoTracked;
  final String? description;
  final int currentStreak;
  final int longestStreak;
  final int totalCompletions;
  final int completionRate;
  final Map<DateTime, bool> yearlyData;
  final List<HabitLogEntry> recentLogs;
  final String? route;
  final List<bool> last30Days;

  const HabitDetailData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isAutoTracked,
    this.description,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCompletions,
    required this.completionRate,
    required this.yearlyData,
    required this.recentLogs,
    this.route,
    this.last30Days = const [],
  });

  /// Habit Strength Score (Loop Habit Tracker formula)
  /// Uses exponential smoothing: score = completed ? 0.1 + 0.9*prev : 0.9*prev
  /// Returns 0-100
  double get habitStrength {
    if (yearlyData.isEmpty && last30Days.isEmpty) return 0.0;

    // Build chronological list of completions
    List<bool> history;
    if (yearlyData.isNotEmpty) {
      final sorted = yearlyData.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      history = sorted.map((e) => e.value).toList();
    } else {
      history = last30Days;
    }

    double score = 0.0;
    for (final completed in history) {
      score = completed ? (0.1 + 0.9 * score) : (0.9 * score);
    }
    return (score * 100).clamp(0.0, 100.0);
  }

  /// Day-of-week completion rates (1=Mon..7=Sun -> 0.0-1.0)
  Map<int, double> get dayOfWeekRates {
    final counts = <int, int>{};
    final totals = <int, int>{};

    for (final entry in yearlyData.entries) {
      final weekday = entry.key.weekday;
      totals[weekday] = (totals[weekday] ?? 0) + 1;
      if (entry.value) {
        counts[weekday] = (counts[weekday] ?? 0) + 1;
      }
    }

    final rates = <int, double>{};
    for (int day = 1; day <= 7; day++) {
      final total = totals[day] ?? 0;
      final completed = counts[day] ?? 0;
      rates[day] = total > 0 ? completed / total : 0.0;
    }
    return rates;
  }

  /// Weekly bar data (last 8 weeks), oldest first
  List<WeeklyBarData> get weeklyBars {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bars = <WeeklyBarData>[];

    for (int w = 7; w >= 0; w--) {
      final weekEnd = today.subtract(Duration(days: w * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      int completed = 0;

      for (int d = 0; d < 7; d++) {
        final date = DateTime(weekStart.year, weekStart.month, weekStart.day + d);
        if (yearlyData[date] == true) completed++;
      }

      bars.add(WeeklyBarData(
        weekStart: weekStart,
        daysCompleted: completed,
        isCurrentWeek: w == 0,
      ));
    }
    return bars;
  }

  /// Weekly completion rates for sparkline (last 8 weeks)
  List<double> get weeklyRates {
    return weeklyBars.map((b) => b.daysCompleted / 7.0).toList();
  }

  /// Trend direction based on last 4 weeks vs previous 4 weeks
  String get trend {
    final rates = weeklyRates;
    if (rates.length < 4) return 'stable';
    final recent = rates.sublist(rates.length - 4).fold(0.0, (a, b) => a + b) / 4;
    final older = rates.sublist(0, 4).fold(0.0, (a, b) => a + b) / 4;
    final diff = recent - older;
    if (diff > 0.05) return 'improving';
    if (diff < -0.05) return 'declining';
    return 'stable';
  }

  /// Days until best streak is beaten (null if already at best or no streak)
  int? get daysUntilBestStreak {
    if (currentStreak <= 0 || currentStreak >= longestStreak) return null;
    final remaining = longestStreak - currentStreak;
    if (remaining <= 5) return remaining;
    return null;
  }
}

class WeeklyBarData {
  final DateTime weekStart;
  final int daysCompleted;
  final bool isCurrentWeek;

  const WeeklyBarData({
    required this.weekStart,
    required this.daysCompleted,
    this.isCurrentWeek = false,
  });

  String get label {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[weekStart.month - 1]} ${weekStart.day}';
  }
}

class HabitLogEntry {
  final DateTime date;
  final String? note;
  final double? value;

  const HabitLogEntry({required this.date, this.note, this.value});
}

// ============================================
// PROVIDER
// ============================================

final habitDetailProvider = FutureProvider.autoDispose
    .family<HabitDetailData?, String>((ref, habitId) async {
  final repository = ref.watch(habitRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id ?? '';

  if (userId.isEmpty) return null;

  if (habitId.startsWith('auto_')) {
    final autoHabits = ref.watch(habitsProvider);
    final habitName = habitId.replaceFirst('auto_', '').replaceAll('_', ' ');
    final autoHabit = autoHabits.firstWhere(
      (h) => h.name.toLowerCase() == habitName,
      orElse: () => autoHabits.first,
    );

    return HabitDetailData(
      id: habitId,
      name: autoHabit.name,
      icon: autoHabit.icon,
      color: AppColors.accent,
      isAutoTracked: true,
      description: _getAutoHabitDescription(autoHabit.name),
      currentStreak: autoHabit.currentStreak,
      longestStreak: autoHabit.currentStreak,
      totalCompletions: autoHabit.last30Days.where((d) => d).length,
      completionRate: autoHabit.last30Days.isNotEmpty
          ? (autoHabit.last30Days.where((d) => d).length /
                  autoHabit.last30Days.length *
                  100)
              .round()
          : 0,
      yearlyData: _generateYearlyDataFromLast30(autoHabit.last30Days),
      recentLogs: _generateLogsFromLast30(autoHabit.last30Days, autoHabit.name),
      route: autoHabit.route,
      last30Days: autoHabit.last30Days,
    );
  }

  try {
    final detail = await repository.getHabitDetail(userId, habitId);
    if (detail == null) return null;

    final yearStart = DateTime(DateTime.now().year, 1, 1);
    final logs = await repository.getHabitLogs(
      userId,
      habitId,
      startDate: yearStart,
      endDate: DateTime.now(),
    );

    final yearlyData = <DateTime, bool>{};
    for (final log in logs) {
      if (log.isCompleted) {
        final dateParts = log.date.split('-');
        if (dateParts.length == 3) {
          final date = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
          yearlyData[date] = true;
        }
      }
    }

    return HabitDetailData(
      id: detail.habit.id,
      name: detail.habit.name,
      icon: _getIconFromName(detail.habit.icon),
      color: _parseColor(detail.habit.color, AppColors.accent),
      isAutoTracked: false,
      description: detail.habit.description,
      currentStreak: detail.streak.currentStreak,
      longestStreak: detail.streak.longestStreak,
      totalCompletions: logs.where((l) => l.isCompleted).length,
      completionRate: _calculateCompletionRate(detail.habit, logs),
      yearlyData: yearlyData,
      recentLogs: logs
          .where((l) => l.isCompleted)
          .take(20)
          .map((l) {
            DateTime logDate;
            if (l.completedAt != null) {
              logDate = l.completedAt!;
            } else {
              final dateParts = l.date.split('-');
              logDate = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
            }
            return HabitLogEntry(
              date: logDate,
              note: l.notes,
              value: l.value?.toDouble(),
            );
          })
          .toList(),
    );
  } catch (e) {
    debugPrint('Error loading habit detail: $e');
    return null;
  }
});

// ============================================
// HELPERS
// ============================================

String _getAutoHabitDescription(String name) {
  switch (name.toLowerCase()) {
    case 'workouts':
      return 'Track your completed workout sessions';
    case 'food log':
      return 'Track your daily food logging activity';
    case 'water':
      return 'Track your daily hydration';
    default:
      return 'Auto-tracked based on your activity';
  }
}

Map<DateTime, bool> _generateYearlyDataFromLast30(List<bool> last30Days) {
  final data = <DateTime, bool>{};
  final now = DateTime.now();
  for (int i = 0; i < last30Days.length; i++) {
    final date = now.subtract(Duration(days: last30Days.length - 1 - i));
    data[DateTime(date.year, date.month, date.day)] = last30Days[i];
  }
  return data;
}

List<HabitLogEntry> _generateLogsFromLast30(List<bool> last30Days, String name) {
  final logs = <HabitLogEntry>[];
  final now = DateTime.now();
  for (int i = last30Days.length - 1; i >= 0; i--) {
    if (last30Days[i]) {
      final date = now.subtract(Duration(days: last30Days.length - 1 - i));
      logs.add(HabitLogEntry(date: date, note: null, value: null));
    }
  }
  return logs.take(20).toList();
}

int _calculateCompletionRate(HabitWithStatus habit, List<HabitLog> logs) {
  if (logs.isEmpty) return 0;
  final completedDays = logs.where((l) => l.isCompleted).length;
  final dateParts = logs.last.date.split('-');
  if (dateParts.length != 3) return 0;
  final oldestDate = DateTime(
    int.parse(dateParts[0]),
    int.parse(dateParts[1]),
    int.parse(dateParts[2]),
  );
  final totalDays = DateTime.now().difference(oldestDate).inDays + 1;
  if (totalDays <= 0) return 100;
  return ((completedDays / totalDays) * 100).round().clamp(0, 100);
}

Color _parseColor(String colorHex, Color fallback) {
  try {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  } catch (_) {
    return fallback;
  }
}

IconData _getIconFromName(String iconName) {
  const iconMap = {
    'check_circle': Icons.check_circle,
    'water_drop': Icons.water_drop,
    'fitness_center': Icons.fitness_center,
    'restaurant_menu': Icons.restaurant_menu,
    'restaurant': Icons.restaurant,
    'self_improvement': Icons.self_improvement,
    'directions_run': Icons.directions_run,
    'directions_walk': Icons.directions_walk,
    'bedtime': Icons.bedtime,
    'eco': Icons.eco,
    'wb_sunny': Icons.wb_sunny,
    'menu_book': Icons.menu_book,
    'favorite': Icons.favorite,
    'star': Icons.star,
    'spa': Icons.spa,
    'edit_note': Icons.edit_note,
    'medication': Icons.medication,
    'no_drinks': Icons.no_drinks,
    'do_not_disturb': Icons.do_not_disturb,
    'phone_disabled': Icons.phone_disabled,
  };
  return iconMap[iconName] ?? Icons.check_circle;
}

// ============================================
// MAIN SCREEN
// ============================================

class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey _shareableKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _shareHabitProgress(HabitDetailData data, bool isDark) async {
    if (_isSharing) return;
    HapticService.medium();
    setState(() => _isSharing = true);
    try {
      final bytes = await ImageCaptureUtils.captureWidgetWithSize(
        _shareableKey,
        width: ImageCaptureUtils.instagramStoriesSize.width,
        height: ImageCaptureUtils.instagramStoriesSize.height,
        pixelRatio: 2.0,
      );
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to capture image')),
          );
        }
        return;
      }
      final result = await ShareService.shareGeneric(
        bytes,
        caption: '${data.name} - ${data.currentStreak} day streak!',
      );
      if (result.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shared successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);
    final habitDetailAsync = ref.watch(habitDetailProvider(widget.habitId));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: habitDetailAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: accentColor),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: textSecondary),
                const SizedBox(height: 16),
                Text('Failed to load habit details',
                    style: TextStyle(color: textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(habitDetailProvider(widget.habitId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (data) {
            if (data == null) {
              return Center(
                child: Text('Habit not found',
                    style: TextStyle(color: textSecondary)),
              );
            }

            final habitColor = data.isAutoTracked ? accentColor : data.color;

            return Column(
              children: [
                // Top bar with back + share
                _buildTopBar(context, data, accentColor, isDark),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Shareable hero section
                        RepaintBoundary(
                          key: _shareableKey,
                          child: Container(
                            color: backgroundColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _CompactHeroSection(
                              data: data,
                              habitColor: habitColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tab bar
                        SegmentedTabBar(
                          controller: _tabController,
                          showIcons: false,
                          tabs: const [
                            SegmentedTabItem(label: 'Overview'),
                            SegmentedTabItem(label: 'Calendar'),
                            SegmentedTabItem(label: 'History'),
                          ],
                        ),
                        // Tab content
                        SizedBox(
                          height: 560,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _OverviewTab(data: data, habitColor: habitColor, textPrimary: textPrimary, textSecondary: textSecondary, cardBg: cardBg, cardBorder: cardBorder, isDark: isDark),
                              _CalendarTab(data: data, habitColor: habitColor, textPrimary: textPrimary, textSecondary: textSecondary, cardBg: cardBg, cardBorder: cardBorder, isDark: isDark),
                              _HistoryTab(data: data, habitColor: habitColor, textPrimary: textPrimary, textSecondary: textSecondary, cardBg: cardBg, cardBorder: cardBorder),
                            ],
                          ),
                        ),
                        // Motivational card
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: _MotivationalCard(data: data, habitColor: habitColor, textPrimary: textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, HabitDetailData data, Color accentColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          GlassBackButton(
            onTap: () {
              HapticService.light();
              context.pop();
            },
          ),
          const Spacer(),
          _GlassmorphicButton(
            onTap: _isSharing ? () {} : () => _shareHabitProgress(data, isDark),
            isDark: isDark,
            child: _isSharing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: accentColor),
                  )
                : Icon(
                    Icons.ios_share,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 18,
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// COMPACT HERO SECTION (icon + ring + stats in one row)
// Eliminates wasted vertical space by combining header and ring
// ============================================

class _CompactHeroSection extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _CompactHeroSection({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Streak ring on left, name + stats on right
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Streak ring (compact)
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SimpleCircularProgressBar(
                    size: 100,
                    progressStrokeWidth: 8,
                    backStrokeWidth: 8,
                    valueNotifier: ValueNotifier(data.completionRate.toDouble()),
                    progressColors: [habitColor, habitColor.withValues(alpha: 0.7)],
                    backColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    startAngle: -90,
                    mergeMode: true,
                    animationDuration: 1,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${data.currentStreak}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'day streak',
                        style: TextStyle(fontSize: 10, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Name + description + mini stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + name row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              habitColor.withValues(alpha: 0.2),
                              habitColor.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(data.icon, color: habitColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    data.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (data.isAutoTracked) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: habitColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'AUTO',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: habitColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (data.description != null && data.description!.isNotEmpty)
                              Text(
                                data.description!,
                                style: TextStyle(fontSize: 11, color: textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Habit strength bar
                  _HabitStrengthBar(
                    strength: data.habitStrength,
                    habitColor: habitColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Row 2: Quick stats - 4 compact tiles
        Row(
          children: [
            _MiniStatTile(icon: Icons.local_fire_department, value: '${data.currentStreak}', label: 'Streak', color: Colors.orange, cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(width: 8),
            _MiniStatTile(icon: Icons.emoji_events, value: '${data.longestStreak}', label: 'Best', color: Colors.amber, cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(width: 8),
            _MiniStatTile(icon: Icons.check_circle_outline, value: '${data.totalCompletions}', label: 'Total', color: Colors.green, cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
            const SizedBox(width: 8),
            _MiniStatTile(icon: Icons.trending_up, value: '${data.completionRate}%', label: 'Rate', color: habitColor, cardBg: cardBg, cardBorder: cardBorder, textPrimary: textPrimary, textSecondary: textSecondary),
          ],
        ),
        // Best streak proximity alert
        if (data.daysUntilBestStreak != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  '${data.daysUntilBestStreak} days until you beat your personal best!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Habit strength bar (Loop-style exponential score)
class _HabitStrengthBar extends StatelessWidget {
  final double strength;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;

  const _HabitStrengthBar({
    required this.strength,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Habit Strength',
              style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
            ),
            Text(
              '${strength.round()}%',
              style: TextStyle(fontSize: 11, color: habitColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength / 100,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation<Color>(habitColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color cardBg;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;

  const _MiniStatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.cardBg,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
            Text(label, style: TextStyle(fontSize: 9, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ============================================
// TAB 1: OVERVIEW
// ============================================

class _OverviewTab extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _OverviewTab({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Completion trend sparkline + trend arrow
          _TrendSparkline(
            data: data,
            habitColor: habitColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            cardBorder: cardBorder,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Weekly completion bar chart
          _WeeklyBarChart(
            data: data,
            habitColor: habitColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            cardBorder: cardBorder,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          // Day of week breakdown
          _DayOfWeekChart(
            data: data,
            habitColor: habitColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            cardBg: cardBg,
            cardBorder: cardBorder,
          ),
        ],
      ),
    );
  }
}

// ============================================
// TREND SPARKLINE + TREND ARROW
// ============================================

class _TrendSparkline extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _TrendSparkline({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final rates = data.weeklyRates;
    final trend = data.trend;
    final hasData = rates.any((r) => r > 0);

    Color trendColor;
    IconData trendIcon;
    String trendLabel;
    switch (trend) {
      case 'improving':
        trendColor = Colors.green;
        trendIcon = Icons.trending_up;
        trendLabel = 'Improving';
        break;
      case 'declining':
        trendColor = Colors.redAccent;
        trendIcon = Icons.trending_down;
        trendLabel = 'Declining';
        break;
      default:
        trendColor = Colors.amber;
        trendIcon = Icons.trending_flat;
        trendLabel = 'Stable';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          // Trend indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(trendIcon, color: trendColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Trend label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trendLabel,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: trendColor),
              ),
              Text(
                '8-week trend',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
          const Spacer(),
          // Sparkline chart
          if (hasData)
            SizedBox(
              width: 120,
              height: 36,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 1,
                  lineTouchData: const LineTouchData(enabled: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: rates.asMap().entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: trendColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: trendColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text('--', style: TextStyle(fontSize: 18, color: textSecondary)),
        ],
      ),
    );
  }
}

// ============================================
// WEEKLY BAR CHART
// ============================================

class _WeeklyBarChart extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _WeeklyBarChart({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bars = data.weeklyBars;
    final hasData = bars.any((b) => b.daysCompleted > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: habitColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Weekly Completions',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Complete this habit to see weekly trends',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 7,
                  minY: 0,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.85),
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      tooltipMargin: 6,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final bar = bars[group.x.toInt()];
                        return BarTooltipItem(
                          '${bar.daysCompleted}/7 days',
                          TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= bars.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              bars[index].label,
                              style: TextStyle(
                                color: bars[index].isCurrentWeek ? habitColor : textSecondary,
                                fontSize: 8,
                                fontWeight: bars[index].isCurrentWeek ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                        reservedSize: 24,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == 7) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text('${value.toInt()}', style: TextStyle(fontSize: 9, color: textSecondary)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 20,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 7,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: textSecondary.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  barGroups: List.generate(bars.length, (index) {
                    final bar = bars[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: bar.daysCompleted.toDouble(),
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          gradient: LinearGradient(
                            colors: bar.isCurrentWeek
                                ? [habitColor, habitColor.withValues(alpha: 0.7)]
                                : [habitColor.withValues(alpha: 0.55), habitColor.withValues(alpha: 0.3)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================
// DAY-OF-WEEK BREAKDOWN
// ============================================

class _DayOfWeekChart extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  const _DayOfWeekChart({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final rates = data.dayOfWeekRates;
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final hasData = rates.values.any((v) => v > 0);

    int? bestDay;
    int? worstDay;
    double bestRate = -1;
    double worstRate = 2;
    if (hasData) {
      for (int d = 1; d <= 7; d++) {
        final rate = rates[d] ?? 0;
        if (rate > bestRate) { bestRate = rate; bestDay = d; }
        if (rate < worstRate) { worstRate = rate; worstDay = d; }
      }
    }

    const fullDayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week_rounded, color: habitColor, size: 18),
              const SizedBox(width: 8),
              Text('Day of Week', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasData)
            SizedBox(
              height: 60,
              child: Center(child: Text('Not enough data yet', style: TextStyle(fontSize: 12, color: textSecondary))),
            )
          else ...[
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final rate = rates[day] ?? 0;
                  final isBest = day == bestDay;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${(rate * 100).round()}%',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: isBest ? habitColor : textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: rate.clamp(0.05, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isBest ? habitColor : habitColor.withValues(alpha: 0.3),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dayLabels[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isBest ? FontWeight.w700 : FontWeight.w500,
                              color: isBest ? habitColor : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (bestDay != null)
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 13, color: Colors.green),
                      const SizedBox(width: 3),
                      Text(
                        'Best: ${fullDayNames[bestDay]} (${(bestRate * 100).round()}%)',
                        style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                if (worstDay != null && bestDay != worstDay)
                  Row(
                    children: [
                      const Icon(Icons.arrow_downward_rounded, size: 13, color: Colors.redAccent),
                      const SizedBox(width: 3),
                      Text(
                        'Weakest: ${fullDayNames[worstDay]} (${(worstRate * 100).round()}%)',
                        style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================
// TAB 2: CALENDAR (HEATMAP + MONTHLY)
// ============================================

class _CalendarTab extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _CalendarTab({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _YearlyHeatmap(data: data, habitColor: habitColor, textPrimary: textPrimary, textSecondary: textSecondary, cardBg: cardBg, cardBorder: cardBorder, isDark: isDark),
          const SizedBox(height: 16),
          Text('Monthly Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 10),
          _MonthlySummary(data: data, habitColor: habitColor, textPrimary: textPrimary, textSecondary: textSecondary, cardBg: cardBg, cardBorder: cardBorder),
        ],
      ),
    );
  }
}

// ============================================
// GITHUB-STYLE YEARLY HEATMAP
// ============================================

class _YearlyHeatmap extends StatefulWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;
  final bool isDark;

  const _YearlyHeatmap({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
    required this.isDark,
  });

  @override
  State<_YearlyHeatmap> createState() => _YearlyHeatmapState();
}

class _YearlyHeatmapState extends State<_YearlyHeatmap> {
  final ScrollController _scrollController = ScrollController();
  String? _tappedDateLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final emptyColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);

    final weeks = <List<DateTime?>>[];
    var current = yearStart;
    while (current.weekday != DateTime.monday) {
      current = current.subtract(const Duration(days: 1));
    }

    while (current.isBefore(now) || current.isAtSameMomentAs(now)) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final date = current.add(Duration(days: d));
        if (date.year == now.year && !date.isAfter(now)) {
          week.add(date);
        } else {
          week.add(null);
        }
      }
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }

    final monthLabels = <int, String>{};
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int w = 0; w < weeks.length; w++) {
      for (final date in weeks[w]) {
        if (date != null && date.day <= 7 && date.weekday == DateTime.monday) {
          monthLabels[w] = monthNames[date.month - 1];
          break;
        }
      }
    }

    const cellSize = 11.0;
    const cellSpacing = 2.5;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: widget.habitColor, size: 18),
              const SizedBox(width: 8),
              Text('${now.year} Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 7 * (cellSize + cellSpacing) + 18,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 14,
                    child: Row(
                      children: List.generate(weeks.length, (w) {
                        return SizedBox(
                          width: cellSize + cellSpacing,
                          child: monthLabels.containsKey(w)
                              ? Text(monthLabels[w]!, style: TextStyle(fontSize: 8, color: widget.textSecondary))
                              : null,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(7, (dayIndex) {
                    return Row(
                      children: List.generate(weeks.length, (weekIndex) {
                        final date = weeks[weekIndex][dayIndex];
                        if (date == null) {
                          return SizedBox(width: cellSize + cellSpacing, height: cellSize + cellSpacing);
                        }
                        final normalizedDate = DateTime(date.year, date.month, date.day);
                        final completed = widget.data.yearlyData[normalizedDate] == true;
                        final isToday = normalizedDate.year == now.year &&
                            normalizedDate.month == now.month &&
                            normalizedDate.day == now.day;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              final status = completed ? 'Completed' : 'Missed';
                              _tappedDateLabel = '${monthNames[date.month - 1]} ${date.day}: $status';
                            });
                          },
                          child: Container(
                            width: cellSize,
                            height: cellSize,
                            margin: const EdgeInsets.all(cellSpacing / 2),
                            decoration: BoxDecoration(
                              color: completed ? widget.habitColor : emptyColor,
                              borderRadius: BorderRadius.circular(2.5),
                              border: isToday
                                  ? Border.all(color: widget.habitColor, width: 1.5)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (_tappedDateLabel != null)
            Center(child: Text(_tappedDateLabel!, style: TextStyle(fontSize: 10, color: widget.textSecondary, fontWeight: FontWeight.w500)))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(color: emptyColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('Missed', style: TextStyle(fontSize: 9, color: widget.textSecondary)),
                const SizedBox(width: 14),
                Container(width: 9, height: 9, decoration: BoxDecoration(color: widget.habitColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 4),
                Text('Done', style: TextStyle(fontSize: 9, color: widget.textSecondary)),
              ],
            ),
        ],
      ),
    );
  }
}

// ============================================
// MONTHLY SUMMARY
// ============================================

class _MonthlySummary extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  const _MonthlySummary({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    final monthlyData = <int, int>{};
    for (final entry in data.yearlyData.entries) {
      if (entry.value && entry.key.year == now.year) {
        monthlyData[entry.key.month] = (monthlyData[entry.key.month] ?? 0) + 1;
      }
    }

    final displayMonths = <int>[];
    for (int m = 1; m <= now.month; m++) {
      if ((monthlyData[m] ?? 0) > 0 || m == now.month) displayMonths.add(m);
    }

    if (displayMonths.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No monthly data yet', style: TextStyle(fontSize: 12, color: textSecondary)),
        ),
      );
    }

    return Column(
      children: displayMonths.map((monthIndex) {
        final monthName = months[monthIndex - 1];
        final completions = monthlyData[monthIndex] ?? 0;
        final daysInMonth = DateTime(now.year, monthIndex + 1, 0).day;
        final maxDays = monthIndex == now.month ? now.day : daysInMonth;
        final percentage = maxDays > 0 ? (completions / maxDays * 100).round() : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 65,
                child: Text(monthName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: habitColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '$percentage%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: habitColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ============================================
// TAB 3: HISTORY
// ============================================

class _HistoryTab extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final Color cardBorder;

  const _HistoryTab({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    if (data.recentLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 44, color: textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 14),
            Text('No activity yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
            const SizedBox(height: 6),
            Text('Complete this habit to see your history', style: TextStyle(fontSize: 12, color: textSecondary)),
          ],
        ),
      );
    }

    final groupedLogs = <String, List<HabitLogEntry>>{};
    for (final log in data.recentLogs) {
      final key = _formatDateHeader(log.date);
      groupedLogs.putIfAbsent(key, () => []).add(log);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedLogs.length,
      itemBuilder: (context, index) {
        final dateKey = groupedLogs.keys.elementAt(index);
        final logs = groupedLogs[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 6, top: index > 0 ? 14.0 : 0),
              child: Text(dateKey, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
            ),
            ...logs.map((log) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: habitColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: habitColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                            Text(_formatTime(log.date), style: TextStyle(fontSize: 11, color: textSecondary)),
                          ],
                        ),
                      ),
                      if (log.value != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: habitColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${log.value}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: habitColor)),
                        ),
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(dateOnly).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

// ============================================
// MOTIVATIONAL CARD (with best-streak proximity)
// ============================================

class _MotivationalCard extends StatelessWidget {
  final HabitDetailData data;
  final Color habitColor;
  final Color textPrimary;

  const _MotivationalCard({
    required this.data,
    required this.habitColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, message) = _getMotivation(data.currentStreak);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: habitColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  (String, String) _getMotivation(int streak) {
    if (streak == 0) {
      return ('🎯', 'Start your streak today! Every journey begins with a single step.');
    } else if (streak < 7) {
      return ('🌱', 'Great start! $streak days and counting. Keep building momentum.');
    } else if (streak < 14) {
      return ('💪', 'One week strong! You\'re building a real habit.');
    } else if (streak < 30) {
      return ('🔥', '$streak days! Research shows 21 days makes a habit.');
    } else if (streak < 60) {
      return ('⭐', 'Incredible $streak-day consistency! This habit is part of you now.');
    } else {
      return ('🏆', '$streak days! You\'ve mastered this habit. Truly inspiring.');
    }
  }
}

// ============================================
// GLASSMORPHIC BUTTON
// ============================================

class _GlassmorphicButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isDark;

  const _GlassmorphicButton({
    required this.onTap,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
