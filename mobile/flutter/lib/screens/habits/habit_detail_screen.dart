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

part 'habit_detail_screen_part_compact_hero_section.dart';
part 'habit_detail_screen_part_yearly_heatmap_state.dart';


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
            onTap: () { if (!_isSharing) _shareHabitProgress(data, isDark); },
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
