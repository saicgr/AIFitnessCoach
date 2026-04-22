import 'package:flutter/material.dart';

enum QuickActionBehavior {
  route,
  waterQuickAdd,
  foodLog,
  foodScan,   // Opens LogMealSheet and immediately launches multi-image food scan
  menuScan,   // Opens LogMealSheet and immediately launches menu scan
  weightLog,
  moodLog,
  fastingNav,
  quickWorkout,
  chat,
}

class QuickAction {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final QuickActionBehavior behavior;
  final String? route;

  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.behavior,
    this.route,
  });
}

const quickActionRegistry = <String, QuickAction>{
  'weight': QuickAction(
    id: 'weight',
    label: 'Weight',
    icon: Icons.monitor_weight_outlined,
    color: Color(0xFFF59E0B),
    behavior: QuickActionBehavior.weightLog,
  ),
  'food': QuickAction(
    id: 'food',
    label: 'Food',
    icon: Icons.restaurant_outlined,
    color: Color(0xFF22C55E),
    behavior: QuickActionBehavior.foodLog,
  ),
  'scan_food': QuickAction(
    id: 'scan_food',
    label: 'Scan Food',
    // Distinct from Progress Photo (accessibility_new) and the bottom-bar
    // camera button — "document scanner" reads as "scan this thing" in the
    // Material set and pairs with the amber Scan Menu entry.
    icon: Icons.document_scanner_outlined,
    color: Color(0xFF16A34A),
    behavior: QuickActionBehavior.foodScan,
  ),
  'scan_menu': QuickAction(
    id: 'scan_menu',
    label: 'Scan Menu',
    icon: Icons.menu_book_outlined,
    color: Color(0xFFF59E0B),
    behavior: QuickActionBehavior.menuScan,
  ),
  'water': QuickAction(
    id: 'water',
    label: 'Water',
    icon: Icons.water_drop_outlined,
    color: Color(0xFF3B82F6),
    behavior: QuickActionBehavior.waterQuickAdd,
  ),
  'photo': QuickAction(
    id: 'photo',
    // Keep this label ≤ 8 chars — the quick-actions grid cell (~65dp wide
    // at fontSize 10) ellipsizes anything longer. Pair with the purple
    // accessibility-stance icon so the "progress photo" meaning still reads.
    label: 'Photo',
    icon: Icons.accessibility_new_outlined,
    color: Color(0xFFA855F7),
    behavior: QuickActionBehavior.route,
    route: '/stats?openPhoto=true',
  ),
  'quick_workout': QuickAction(
    id: 'quick_workout',
    label: 'Quick',
    icon: Icons.flash_on,
    color: Color(0xFF00D9FF),
    behavior: QuickActionBehavior.quickWorkout,
  ),
  'fasting': QuickAction(
    id: 'fasting',
    label: 'Fasting',
    icon: Icons.timer_outlined,
    color: Color(0xFFF97316),
    behavior: QuickActionBehavior.fastingNav,
    route: '/fasting',
  ),
  'measure': QuickAction(
    id: 'measure',
    label: 'Measure',
    icon: Icons.straighten_outlined,
    color: Color(0xFFA855F7),
    behavior: QuickActionBehavior.route,
    route: '/measurements',
  ),
  'mood': QuickAction(
    id: 'mood',
    label: 'Mood',
    icon: Icons.mood_outlined,
    color: Color(0xFFEC4899),
    behavior: QuickActionBehavior.moodLog,
  ),
  'history': QuickAction(
    id: 'history',
    label: 'History',
    icon: Icons.history_outlined,
    color: Color(0xFF6B7280),
    behavior: QuickActionBehavior.route,
    route: '/workout-gallery',
  ),
  'steps': QuickAction(
    id: 'steps',
    label: 'Steps',
    icon: Icons.directions_walk_outlined,
    color: Color(0xFF10B981),
    behavior: QuickActionBehavior.route,
    route: '/neat',
  ),
  'workout': QuickAction(
    id: 'workout',
    label: 'Workout',
    icon: Icons.fitness_center_outlined,
    color: Color(0xFFEF4444),
    behavior: QuickActionBehavior.route,
    route: '/workouts',
  ),
  'library': QuickAction(
    id: 'library',
    label: 'Library',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF8B5CF6),
    behavior: QuickActionBehavior.route,
    route: '/library',
  ),
  'programs': QuickAction(
    id: 'programs',
    label: 'Programs',
    icon: Icons.view_list_outlined,
    color: Color(0xFFE11D48),
    behavior: QuickActionBehavior.route,
    route: '/library?tab=1',
  ),
  'chat': QuickAction(
    id: 'chat',
    label: 'Chat',
    icon: Icons.auto_awesome,
    color: Color(0xFF9B59B6),
    behavior: QuickActionBehavior.chat,
  ),
  'settings': QuickAction(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    color: Color(0xFF64748B),
    behavior: QuickActionBehavior.route,
    route: '/settings',
  ),
  'schedule': QuickAction(
    id: 'schedule',
    label: 'Schedule',
    icon: Icons.calendar_today_outlined,
    color: Color(0xFF0EA5E9),
    behavior: QuickActionBehavior.route,
    route: '/schedule',
  ),
  'habits': QuickAction(
    id: 'habits',
    label: 'Habits',
    icon: Icons.checklist_outlined,
    color: Color(0xFF14B8A6),
    behavior: QuickActionBehavior.route,
    route: '/habits',
  ),
  'progress': QuickAction(
    id: 'progress',
    label: 'Progress',
    icon: Icons.show_chart_outlined,
    color: Color(0xFF22C55E),
    behavior: QuickActionBehavior.route,
    route: '/stats?tab=2',
  ),
  'achievements': QuickAction(
    id: 'achievements',
    label: 'Achieve',
    icon: Icons.emoji_events_outlined,
    color: Color(0xFFEAB308),
    behavior: QuickActionBehavior.route,
    route: '/achievements',
  ),
  'hydration': QuickAction(
    id: 'hydration',
    label: 'Hydration',
    icon: Icons.local_drink_outlined,
    color: Color(0xFF3B82F6),
    behavior: QuickActionBehavior.route,
    route: '/nutrition?tab=2',
  ),
  'summaries': QuickAction(
    id: 'summaries',
    label: 'Summary',
    icon: Icons.summarize_outlined,
    color: Color(0xFF8B5CF6),
    behavior: QuickActionBehavior.route,
    route: '/summaries',
  ),
  'stats': QuickAction(
    id: 'stats',
    label: 'Stats',
    icon: Icons.leaderboard_outlined,
    color: Color(0xFF6366F1),
    behavior: QuickActionBehavior.route,
    route: '/stats',
  ),
};

// Home shortcut bar layout: 2 rows × 5 slots.
//   Row 1 (slots 1-5): first 5 entries below.
//   Row 2 (slots 6-9): entries 6-9. Slot 10 is the fixed "More" tile.
// Anything beyond index 8 lives in the full QuickActionsSheet (reached via More).
const defaultQuickActionOrder = [
  // COMING SOON: 'fasting' removed from default order — re-add when fasting feature launches
  'quick_workout', 'food', 'water', 'chat', 'scan_food',   // row 1 (slots 1-5)
  'weight', 'photo', 'measure', 'scan_menu',                // row 2 (slots 6-9); slot 10 = More
  'mood', 'history', 'steps', 'workout', 'programs',
  'library', 'settings', 'schedule', 'habits',
  'progress', 'stats', 'achievements', 'hydration', 'summaries',
];
