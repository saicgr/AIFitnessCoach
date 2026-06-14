import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/habit.dart';
import '../../data/providers/habits_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/habit_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/share_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../utils/image_capture_utils.dart';
import '../../widgets/segmented_tab_bar.dart';

import '../../l10n/generated/app_localizations.dart';
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

  // ---- JSON codec for the cache-first disk cache --------------------------
  //
  // HabitDetailData is not a generated model, so it carries a hand-written
  // codec. Non-JSON-native fields are encoded explicitly:
  //  - IconData  -> codePoint + fontFamily (rebuilt as a const-free IconData)
  //  - Color     -> 32-bit ARGB int
  //  - DateTime  -> 'yyyy-MM-dd' (yearlyData is day-bucketed, time is noise)

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'iconFontPackage': icon.fontPackage,
        'color': color.toARGB32(),
        'isAutoTracked': isAutoTracked,
        'description': description,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'totalCompletions': totalCompletions,
        'completionRate': completionRate,
        'yearlyData': {
          for (final e in yearlyData.entries)
            _dateKey(e.key): e.value,
        },
        'recentLogs': recentLogs.map((l) => l.toJson()).toList(),
        'route': route,
        'last30Days': last30Days,
      };

  /// Rebuild from a persisted map. Throws on a malformed map — the caller
  /// decodes inside a try and treats a throw as a cache miss.
  factory HabitDetailData.fromJson(Map<String, dynamic> json) {
    final yearly = <DateTime, bool>{};
    final rawYearly = json['yearlyData'];
    if (rawYearly is Map) {
      rawYearly.forEach((k, v) {
        final parsed = DateTime.tryParse(k as String);
        if (parsed != null) {
          yearly[DateTime(parsed.year, parsed.month, parsed.day)] = v == true;
        }
      });
    }
    return HabitDetailData(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: IconData(
        (json['iconCodePoint'] as num).toInt(),
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
      color: Color((json['color'] as num).toInt()),
      isAutoTracked: json['isAutoTracked'] == true,
      description: json['description'] as String?,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      totalCompletions: (json['totalCompletions'] as num?)?.toInt() ?? 0,
      completionRate: (json['completionRate'] as num?)?.toInt() ?? 0,
      yearlyData: yearly,
      recentLogs: ((json['recentLogs'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) =>
              HabitLogEntry.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      route: json['route'] as String?,
      last30Days: ((json['last30Days'] as List?) ?? const [])
          .map((e) => e == true)
          .toList(),
    );
  }

  /// 'yyyy-MM-dd' for a date — zero-padded so string sort == chronological.
  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
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

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'note': note,
        'value': value,
      };

  factory HabitLogEntry.fromJson(Map<String, dynamic> json) => HabitLogEntry(
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        value: (json['value'] as num?)?.toDouble(),
      );
}

// ============================================
// PROVIDER
// ============================================

/// Per-habit refresh trigger. Bumped after a cache hit to drive a background
/// revalidate, and incremented elsewhere to force a clean network read.
final habitDetailRefreshProvider =
    StateProvider.autoDispose.family<int, String>((ref, habitId) => 0);

/// Schema version for the persisted habit-detail envelope.
const int _kHabitDetailCacheVersion = 1;

/// Disk-persisted stale-while-revalidate cache for [HabitDetailData].
///
/// Mirrors the schedule provider's `_ScheduleDiskCache`: a versioned + TTL
/// SharedPreferences envelope, scoped by (user, habitId), so a habit-detail
/// screen renders the last-known stats instantly on a cold start.
class _HabitDetailDiskCache {
  const _HabitDetailDiskCache._();

  static const String _prefix = 'habit_detail_cache';

  /// 24h TTL — a stale stats blob still beats a blocking spinner and the
  /// background revalidate corrects it within the session.
  static const Duration _ttl = Duration(hours: 24);

  static String _key(String userId, String habitId) =>
      '$_prefix::v$_kHabitDetailCacheVersion::$userId::$habitId';

  /// Read + validate a cached blob. Null on miss / expiry / corruption.
  static Future<HabitDetailData?> read(String userId, String habitId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId, habitId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['v'] != _kHabitDetailCacheVersion) return null;
      final cachedAt = decoded['cachedAt'];
      if (cachedAt is! int) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      if (age < 0 || age >= _ttl.inMilliseconds) {
        await prefs.remove(_key(userId, habitId));
        return null;
      }
      final body = decoded['data'];
      if (body is! Map<String, dynamic>) return null;
      return HabitDetailData.fromJson(body);
    } catch (e) {
      debugPrint('💾 [HabitDetailCache] read failed: $e');
      return null;
    }
  }

  /// Persist a habit-detail blob in a versioned TTL envelope. Best-effort.
  static Future<void> write(
      String userId, String habitId, HabitDetailData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId, habitId),
        jsonEncode({
          'v': _kHabitDetailCacheVersion,
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
          'data': data.toJson(),
        }),
      );
    } catch (e) {
      debugPrint('💾 [HabitDetailCache] write failed: $e');
    }
  }
}

final habitDetailProvider = FutureProvider.autoDispose
    .family<HabitDetailData?, String>((ref, habitId) async {
  final repository = ref.watch(habitRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id ?? '';

  if (userId.isEmpty) return null;

  // Watch the refresh trigger so a background revalidate / forced reload
  // re-runs this provider.
  ref.watch(habitDetailRefreshProvider(habitId));

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

  // ---- Cache-first: serve the last-known detail instantly ----------------
  // Skip the disk cache on an explicit refresh so a forced reload always hits
  // the network instead of re-serving the just-served stale blob.
  final isRefresh = ref.read(habitDetailRefreshProvider(habitId)) > 0;
  if (!isRefresh) {
    final cached = await _HabitDetailDiskCache.read(userId, habitId);
    if (cached != null) {
      debugPrint('✅ [HabitDetail] from cache: $habitId');
      // Revalidate in the background — bumping the trigger re-runs this
      // provider on the network path on the next microtask. Wrapped in a
      // try/catch because the provider may have been disposed by then.
      Future.microtask(() {
        try {
          ref.read(habitDetailRefreshProvider(habitId).notifier).state++;
        } catch (_) {/* provider disposed — nothing to revalidate */}
      });
      return cached;
    }
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

    final result = HabitDetailData(
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
    // Write-through so the next cold open of this habit is instant.
    await _HabitDetailDiskCache.write(userId, habitId, result);
    return result;
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
            SnackBar(content: Text(AppLocalizations.of(context).prShareCardFailedToCaptureImage)),
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
          SnackBar(content: Text(AppLocalizations.of(context).habitDetailSharedSuccessfully)),
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
        child: Builder(
          builder: (context) {
            // Instant-load: keep the last-known detail visible while a silent
            // revalidate runs, and show a layout-matched skeleton (never a
            // blocking spinner) on a true cold open.
            final data = habitDetailAsync.valueOrNull;

            if (data == null && habitDetailAsync.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: textSecondary),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).habitDetailFailedToLoadHabit.toUpperCase(),
                        style: ZType.lbl(13, color: textSecondary, letterSpacing: 1.4)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(habitDetailProvider(widget.habitId)),
                      child: Text(AppLocalizations.of(context).buttonRetry),
                    ),
                  ],
                ),
              );
            }

            if (data == null) {
              // Still loading and nothing cached — layout-matched skeleton:
              // a hero block, a tab-bar strip and a content list.
              if (habitDetailAsync.isLoading) {
                return _buildDetailSkeleton();
              }
              // Resolved to null → the habit genuinely doesn't exist.
              return Center(
                child: Text(AppLocalizations.of(context).habitDetailHabitNotFound.toUpperCase(),
                    style: ZType.lbl(13, color: textSecondary, letterSpacing: 1.4)),
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
                          tabs: [
                            SegmentedTabItem(label: AppLocalizations.of(context).youHubOverview),
                            SegmentedTabItem(label: AppLocalizations.of(context).habitDetailCalendar),
                            SegmentedTabItem(label: AppLocalizations.of(context).workoutHistory),
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

  /// Layout-matched skeleton for the habit-detail screen — a hero block, a
  /// tab-bar strip and a stack of content placeholders. Mirrors the real
  /// layout so the skeleton -> content cross-fade does not reflow. Cold-open
  /// only; the cache-first provider serves a cached detail instantly for
  /// returning users.
  Widget _buildDetailSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        // Hero block placeholder (ring + headline stats).
        SkeletonBox(height: 200, radius: 20),
        SizedBox(height: 16),
        // Tab-bar strip placeholder.
        SkeletonBox(height: 44, radius: 12),
        SizedBox(height: 20),
        // Content card placeholders.
        SkeletonList(itemCount: 4, spacing: 14),
      ],
    );
  }
}
