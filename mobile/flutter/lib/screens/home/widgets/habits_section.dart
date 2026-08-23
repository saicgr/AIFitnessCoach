import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/habit.dart';
import '../../../data/providers/habits_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/habit_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../nutrition/log_meal_sheet.dart';
import 'components/quick_actions_row.dart';
import 'habit_card.dart';

import '../../../l10n/generated/app_localizations.dart';
/// Provider to fetch custom habits for home section
final customHabitsHomeProvider = FutureProvider.autoDispose<List<HabitWithStatus>>((ref) async {
  // Survive Home tab switches so the habits row doesn't re-fetch on every
  // return. (keepAlive-only: invalidated explicitly after a habit is toggled —
  // see refreshAllHome / habit write path — so the row stays correct.)
  ref.keepAlive();
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  if (userId == null || userId.isEmpty) return [];

  final repository = ref.watch(habitRepositoryProvider);
  try {
    final response = await repository.getTodayHabits(userId);
    return response.habits;
  } catch (e) {
    debugPrint('❌ [CustomHabitsHome] Error fetching habits: $e');
    return [];
  }
});

/// Provider to load saved habit order from SharedPreferences
final _savedHabitOrderProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.user?.id;
  if (userId == null || userId.isEmpty) return [];
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('habit_order_$userId') ?? [];
  } catch (_) {
    return [];
  }
});

/// Number of recent-completion dots rendered per habit row (newest =
/// rightmost) — one per day of the week, matching the mockup's 7-dot streak
/// row.
const int _kHabitDots = 7;

/// Streaks section (was "Your Habits") — Signature v2 hairline dot-rows.
///
/// Each habit (the auto-tracked Workouts / Food Log / Water plus any custom
/// habits from `habitsProvider`/`customHabitsHomeProvider`) renders as a slim
/// hairline row: a leading themed icon, the habit name + today's progress, a
/// run of 7 filled/empty dots showing the week's completion (from the habit's
/// real `last30Days` tail), and a static "+" to log — deliberately NOT a
/// checkbox/pill action button like the coach's "To do today" rows, so a
/// glance reads as consistency rather than another chore. No boxed cards, no
/// 30-day heatmap, no glow.
class HabitsSection extends ConsumerWidget {
  const HabitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ThemeColors.of(context);

    // Auto-tracked habits (Workouts, Food Log, Water) — tag with stable IDs
    final autoTrackedHabits = ref.watch(habitsProvider).map((h) {
      final id = 'auto_${h.name.toLowerCase().replaceAll(' ', '_')}';
      return HabitData(name: h.name, id: id, icon: h.icon, last30Days: h.last30Days,
          currentStreak: h.currentStreak, route: h.route, todayCompleted: h.todayCompleted);
    }).toList();

    // Custom habits from API
    final customHabitsAsync = ref.watch(customHabitsHomeProvider);

    // Convert custom habits to HabitData format for display
    final customHabitCards = customHabitsAsync.when(
      data: (habits) => habits.map((h) => _convertToHabitData(h)).toList(),
      loading: () => <HabitData>[],
      error: (_, __) => <HabitData>[],
    );

    // Saved habit order from SharedPreferences
    final savedOrder = ref.watch(_savedHabitOrderProvider).valueOrNull ?? [];

    // Combine auto-tracked + custom habits, then sort by saved order
    List<HabitData> allHabits;
    if (savedOrder.isNotEmpty) {
      final habitsById = <String, HabitData>{};
      for (final h in autoTrackedHabits) {
        habitsById[h.id ?? h.name] = h;
      }
      for (final h in customHabitCards) {
        habitsById[h.id ?? h.name] = h;
      }
      final ordered = <HabitData>[];
      for (final id in savedOrder) {
        if (habitsById.containsKey(id)) {
          ordered.add(habitsById.remove(id)!);
        }
      }
      ordered.addAll(habitsById.values);
      allHabits = ordered;
    } else {
      allHabits = [...autoTrackedHabits, ...customHabitCards];
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── "STREAKS" Barlow kicker + View all link ──
          // Hardcoded (not the shared `habitsYourHabits` l10n string) — that
          // key is also the title of the dedicated /habits screen, which
          // keeps its "Your Habits" name; only this Home section renamed.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'STREAKS',
                  style: ZType.lbl(
                    11,
                    color: c.textSecondary,
                    letterSpacing: 1.8,
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticService.light();
                    context.push('/habits');
                  },
                  child: Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Hairline dot-rows ──
          for (int i = 0; i < allHabits.length; i++)
            _HabitDotRow(
              habit: allHabits[i],
              isLast: false,
              onTap: () => _onHabitTap(context, allHabits[i]),
              onLog: () => _onHabitLog(context, ref, allHabits[i], customHabitsAsync),
            ),

          // ── "Add habit" — a slim hairline affordance, not a big tile ──
          _AddHabitRow(
            isLast: true,
            onTap: () => _showAddHabitSheet(context, ref),
          ),
        ],
      ),
    );
  }

  // Tap a habit row → navigate to its surface (preserved verbatim).
  void _onHabitTap(BuildContext context, HabitData habit) {
    HapticService.light();
    // Use context.go (not push) so we switch branches in StatefulShellRoute —
    // otherwise the floating nav stays highlighted on Home while the user is
    // now on /nutrition.
    //
    // Append a unique nav token so the URL differs from any prior visit.
    // NutritionScreen lives inside an IndexedStack branch and keeps its tab
    // state across branch switches; without a URL change, didUpdateWidget never
    // fires and the requested tab/section is ignored.
    if (habit.route != null) {
      final route = habit.route!;
      final separator = route.contains('?') ? '&' : '?';
      final nav = '_nav=${DateTime.now().millisecondsSinceEpoch}';
      context.go('$route$separator$nav');
    } else {
      context.go('/habits');
    }
  }

  // Long-press / log a habit row → open the LOGGING surface (preserved verbatim).
  void _onHabitLog(
    BuildContext context,
    WidgetRef ref,
    HabitData habit,
    AsyncValue<List<HabitWithStatus>> customHabitsAsync,
  ) {
    HapticService.medium();
    // Food Log → log-meal sheet; Water → water quick-add sheet (matches the
    // Home water tile's long-press UX). Workouts + custom → navigate / toggle.
    if (habit.id == 'auto_food_log') {
      context.go('/nutrition');
      Future.microtask(() {
        if (context.mounted) showLogMealSheet(context, ref);
      });
      return;
    }
    if (habit.id == 'auto_water') {
      showWaterQuickAddSheet(context, ref);
      return;
    }
    if (habit.route != null) {
      context.go(habit.route!);
      return;
    }
    // Custom habit — toggle via API.
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;
    final customHabits = customHabitsAsync.valueOrNull ?? [];
    final match = customHabits.where((h) => h.name == habit.name).firstOrNull;
    if (match != null) {
      final repository = ref.read(habitRepositoryProvider);
      repository.toggleTodayHabit(userId, match.id, !habit.todayCompleted).then((_) {
        ref.invalidate(customHabitsHomeProvider);
      });
    }
  }

  /// Convert HabitWithStatus from API to HabitData for the dot-row.
  HabitData _convertToHabitData(HabitWithStatus habit) {
    // Generate last 30 days data based on completion rate
    // For now, we mark today as completed if todayCompleted is true
    final last30Days = List<bool>.filled(30, false);

    // Mark today based on completion status
    if (habit.todayCompleted) {
      last30Days[29] = true;
    }

    // Estimate some completion based on 7-day rate
    // This is a rough approximation - ideally we'd fetch actual history
    final completedDays = (habit.completionRate7d * 7).round();
    for (int i = 0; i < completedDays && i < 7; i++) {
      last30Days[28 - i] = true;
    }

    return HabitData(
      name: habit.name,
      id: habit.id,
      icon: _getIconData(habit.icon),
      last30Days: last30Days,
      currentStreak: habit.currentStreak,
      route: null, // Custom habits don't have a specific route
      todayCompleted: habit.todayCompleted,
    );
  }

  /// Parse icon string to IconData
  IconData _getIconData(String iconName) {
    final iconMap = {
      'check_circle': Icons.check_circle,
      'water_drop': Icons.water_drop,
      'eco': Icons.eco,
      'do_not_disturb': Icons.do_not_disturb,
      'medication': Icons.medication,
      'directions_walk': Icons.directions_walk,
      'self_improvement': Icons.self_improvement,
      'directions_run': Icons.directions_run,
      'fitness_center': Icons.fitness_center,
      'bedtime': Icons.bedtime,
      'spa': Icons.spa,
      'no_drinks': Icons.no_drinks,
      'wb_sunny': Icons.wb_sunny,
      'menu_book': Icons.menu_book,
      'edit_note': Icons.edit_note,
      'phone_disabled': Icons.phone_disabled,
      'favorite': Icons.favorite,
      'restaurant_menu': Icons.restaurant_menu,
      'local_fire_department': Icons.local_fire_department,
    };
    return iconMap[iconName] ?? Icons.check_circle;
  }

  void _showAddHabitSheet(BuildContext context, WidgetRef ref) {
    // NOTE: `?addHabit=true` used to auto-open the add-habit sheet on
    // HabitsScreen, but that path mutates `_autoOpenFiredProvider` from
    // inside build() (habits_screen.dart, outside this lane's ownership),
    // which Riverpod rejects and renders the error-boundary dead end with
    // no way back. Route to the plain habits screen (same destination the
    // working "View all" entry point uses) until that provider write is
    // moved out of build() at the source.
    context.push('/habits');
  }
}

/// A single slim hairline habit row: leading themed icon + name & progress +
/// a compact run of recent-completion dots (newest = rightmost). Tap navigates
/// to the habit's surface; the trailing log glyph opens its logging surface.
class _HabitDotRow extends StatelessWidget {
  final HabitData habit;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLog;

  const _HabitDotRow({
    required this.habit,
    required this.isLast,
    required this.onTap,
    required this.onLog,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : c.cardBorder,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        child: Row(
          children: [
            // Leading glyph — themed Icon for both auto-tracked and custom habits.
            SizedBox(
              width: 22,
              child: Center(child: _leadingGlyph(c, isDark)),
            ),
            const SizedBox(width: 10),
            // Name · progress
            Expanded(
              child: Text(
                _rowLabel(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Streak dots — 7 days, today rightmost. This alone carries the
            // "done" signal now (see the static "+" below).
            _DotsRow(days: _recentDays(), accent: c.accent, isDark: isDark),
            const SizedBox(width: 9),
            // Static "+" to log — never swaps to a checkmark/fill. A row that
            // toggles into a filled checkbox reads as a to-do; the dots above
            // already say whether today is done, so this stays a plain,
            // always-the-same increment affordance (not an action button).
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLog,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: c.hairlineStrong,
                    width: 1,
                  ),
                ),
                child: Icon(Icons.add_rounded, size: 15, color: c.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadingGlyph(ThemeColors c, bool isDark) {
    return Icon(habit.icon, size: 16, color: c.textSecondary);
  }

  /// "Water · 6 of 8"-style label. Auto-tracked habits use a localized name +
  /// recent-completion count; custom habits keep their user-typed name and a
  /// streak suffix when present.
  String _rowLabel(BuildContext context) {
    final name = HabitCard.displayName(context, habit);
    final recent = _recentDays();
    final done = recent.where((d) => d).length;
    if (habit.currentStreak > 0) {
      return '$name · ${habit.currentStreak}-day streak';
    }
    return '$name · $done of ${recent.length}';
  }

  /// The last [_kHabitDots] days of completion, oldest→newest (today last) —
  /// the real tail of `last30Days` (index 29 = today). Padded with `false`
  /// when fewer days are available so the dot run is always the same width.
  List<bool> _recentDays() {
    final src = habit.last30Days;
    if (src.isEmpty) return List<bool>.filled(_kHabitDots, false);
    if (src.length >= _kHabitDots) {
      return src.sublist(src.length - _kHabitDots);
    }
    return [
      ...List<bool>.filled(_kHabitDots - src.length, false),
      ...src,
    ];
  }
}

/// A compact run of completion dots. Filled (accent) = completed that day;
/// hollow (hairline) = not. Today is the rightmost dot.
class _DotsRow extends StatelessWidget {
  final List<bool> days;
  final Color accent;
  final bool isDark;

  const _DotsRow({
    required this.days,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final emptyColor = c.hairlineStrong;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < days.length; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: days[i] ? accent : emptyColor,
              ),
            ),
          ),
      ],
    );
  }
}

/// "Add habit" — a slim hairline row (NOT a big tile). Mirrors the dot-row
/// geometry so it reads as the last item in the list.
class _AddHabitRow extends StatelessWidget {
  final bool isLast;
  final VoidCallback onTap;

  const _AddHabitRow({required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : c.cardBorder,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Center(
                child: Icon(Icons.add_rounded, size: 17, color: c.accent),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).habitsTileCardAddHabit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: c.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
