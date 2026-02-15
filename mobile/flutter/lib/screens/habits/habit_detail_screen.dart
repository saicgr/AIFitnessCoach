import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Provider for habit detail data
final habitDetailProvider = FutureProvider.autoDispose
    .family<HabitDetailData?, String>((ref, habitId) async {
  final repository = ref.watch(habitRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id ?? '';

  if (userId.isEmpty) return null;

  // Check if it's an auto-tracked habit
  if (habitId.startsWith('auto_')) {
    // Use ref.watch to react to data changes from nutrition/hydration/workout providers
    final autoHabits = ref.watch(habitsProvider);
    final habitName = habitId.replaceFirst('auto_', '').replaceAll('_', ' ');
    final autoHabit = autoHabits.firstWhere(
      (h) => h.name.toLowerCase() == habitName,
      orElse: () => autoHabits.first,
    );

    // Build detail from auto-tracked data
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
      last30Days: autoHabit.last30Days, // Pass directly for heatmap
    );
  }

  // Custom habit - fetch from API
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
    final normalizedDate = DateTime(date.year, date.month, date.day);
    data[normalizedDate] = last30Days[i];
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
  final oldestLog = logs.last;
  final dateParts = oldestLog.date.split('-');
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
    'self_improvement': Icons.self_improvement,
    'directions_run': Icons.directions_run,
    'bedtime': Icons.bedtime,
    'eco': Icons.eco,
    'wb_sunny': Icons.wb_sunny,
    'menu_book': Icons.menu_book,
    'favorite': Icons.favorite,
    'star': Icons.star,
  };
  return iconMap[iconName] ?? Icons.check_circle;
}

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
  final List<bool> last30Days; // Direct array for heatmap display

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
}

class HabitLogEntry {
  final DateTime date;
  final String? note;
  final double? value;

  const HabitLogEntry({required this.date, this.note, this.value});
}

/// Habit Detail Screen with yearly heatmap and stats
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _shareHabitProgress(HabitDetailData data, Color accentColor, bool isDark) async {
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
      if (mounted) {
        setState(() => _isSharing = false);
      }
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
                Text('Failed to load habit details', style: TextStyle(color: textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(habitDetailProvider(widget.habitId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (data) {
            if (data == null) {
              return Center(
                child: Text('Habit not found', style: TextStyle(color: textSecondary)),
              );
            }

            return Stack(
              children: [
                Column(
                  children: [
                    // Header row with back and share buttons
                    _buildTopBar(context, data, accentColor, isDark, cardBg, cardBorder, textPrimary),

                    // Main scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Shareable content
                            RepaintBoundary(
                              key: _shareableKey,
                              child: Container(
                                color: backgroundColor,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    _buildHeader(data, textPrimary, textSecondary, accentColor),
                                    const SizedBox(height: 12),
                                    _buildStatsRow(data, textPrimary, textSecondary, cardBg, cardBorder, accentColor),
                                    const SizedBox(height: 16),
                                    _buildCompactHeatmap(data, textSecondary, accentColor, isDark),
                                  ],
                                ),
                              ),
                            ),

                            // Tab bar (matching app style)
                            _buildTabBar(cardBg, accentColor, textSecondary, isDark),

                            // Tab content
                            SizedBox(
                              height: 400,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildCalendarTab(data, textPrimary, textSecondary, cardBg, cardBorder, accentColor),
                                  _buildHistoryTab(data, textPrimary, textSecondary, cardBg, cardBorder, accentColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    HabitDetailData data,
    Color accentColor,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button
          GlassBackButton(
            onTap: () {
              HapticService.light();
              context.pop();
            },
          ),
          const Spacer(),
          // Share button
          _GlassmorphicButton(
            onTap: _isSharing ? () {} : () => _shareHabitProgress(data, accentColor, isDark),
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

  Widget _buildHeader(HabitDetailData data, Color textPrimary, Color textSecondary, Color accentColor) {
    return Column(
      children: [
        // Icon - smaller size
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: data.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(data.icon, color: data.color, size: 26),
        ),
        const SizedBox(height: 10),
        // Name with AUTO badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            if (data.isAutoTracked) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'AUTO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (data.description != null && data.description!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            data.description!,
            style: TextStyle(fontSize: 12, color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(
    HabitDetailData data,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
    Color accentColor,
  ) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.local_fire_department, '${data.currentStreak}', 'Current\nStreak', Colors.orange, cardBg, cardBorder, textPrimary, textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(Icons.emoji_events, '${data.longestStreak}', 'Best\nStreak', Colors.amber, cardBg, cardBorder, textPrimary, textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(Icons.check_circle, '${data.totalCompletions}', 'Total\nCompleted', Colors.green, cardBg, cardBorder, textPrimary, textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: _buildStatCard(Icons.trending_up, '${data.completionRate}%', 'Success\nRate', accentColor, cardBg, cardBorder, textPrimary, textSecondary)),
      ],
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Compact heatmap - Last 30 days in a simple grid (5 rows x 6 cols)
  Widget _buildCompactHeatmap(
    HabitDetailData data,
    Color textSecondary,
    Color accentColor,
    bool isDark,
  ) {
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    // Use last30Days directly if available, otherwise build from yearlyData
    List<bool> last30;
    if (data.last30Days.isNotEmpty) {
      // For auto-tracked habits, use the direct array
      last30 = List<bool>.from(data.last30Days);
      // Ensure we have exactly 30 entries
      while (last30.length < 30) {
        last30.insert(0, false);
      }
      if (last30.length > 30) last30 = last30.sublist(last30.length - 30);
    } else {
      // For custom habits, build from yearlyData
      final now = DateTime.now();
      last30 = [];
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final normalizedDate = DateTime(date.year, date.month, date.day);
        last30.add(data.yearlyData[normalizedDate] == true);
      }
    }

    final completedCount = last30.where((d) => d).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Last 30 Days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            Text(
              '$completedCount/30 days',
              style: TextStyle(
                fontSize: 12,
                color: accentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Grid: 5 rows x 6 columns
        Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(30, (index) {
              final completed = last30[index];
              return Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: completed ? accentColor : emptyColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: emptyColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text('Missed', style: TextStyle(fontSize: 10, color: textSecondary)),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text('Completed', style: TextStyle(fontSize: 10, color: textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(Color elevated, Color accentColor, Color textMuted, bool isDark) {
    return SegmentedTabBar(
      controller: _tabController,
      showIcons: false,
      tabs: const [
        SegmentedTabItem(label: 'Calendar'),
        SegmentedTabItem(label: 'History'),
      ],
    );
  }

  Widget _buildCalendarTab(
    HabitDetailData data,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
    Color accentColor,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
          ),
          const SizedBox(height: 12),
          _buildMonthlySummary(data, textPrimary, textSecondary, cardBg, cardBorder, accentColor),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(
    HabitDetailData data,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
    Color accentColor,
  ) {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    final monthlyData = <int, int>{};
    for (final entry in data.yearlyData.entries) {
      if (entry.value && entry.key.year == now.year) {
        monthlyData[entry.key.month] = (monthlyData[entry.key.month] ?? 0) + 1;
      }
    }

    final displayMonths = months.sublist(0, now.month);

    return Column(
      children: displayMonths.asMap().entries.map((entry) {
        final monthIndex = entry.key + 1;
        final monthName = entry.value;
        final completions = monthlyData[monthIndex] ?? 0;
        final daysInMonth = DateTime(now.year, monthIndex + 1, 0).day;
        final percentage = (completions / daysInMonth * 100).round();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  monthName,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: accentColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$completions/$daysInMonth',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab(
    HabitDetailData data,
    Color textPrimary,
    Color textSecondary,
    Color cardBg,
    Color cardBorder,
    Color accentColor,
  ) {
    if (data.recentLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No activity yet', style: TextStyle(fontSize: 16, color: textSecondary)),
            const SizedBox(height: 8),
            Text(
              'Complete this habit to see your history',
              style: TextStyle(fontSize: 13, color: textSecondary.withValues(alpha: 0.7)),
            ),
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
              padding: EdgeInsets.only(bottom: 8, top: index > 0 ? 16.0 : 0),
              child: Text(
                dateKey,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
              ),
            ),
            ...logs.map((log) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Completed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                            Text(_formatTime(log.date), style: TextStyle(fontSize: 12, color: textSecondary)),
                          ],
                        ),
                      ),
                      if (log.value != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${log.value}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor),
                          ),
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

/// Glassmorphic button with blur effect (matching library screen style)
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
