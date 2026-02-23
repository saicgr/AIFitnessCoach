import 'package:flutter/material.dart';

enum QuickActionBehavior { route, waterQuickAdd, foodLog, weightLog, moodLog, fastingNav, quickWorkout }

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
  'water': QuickAction(
    id: 'water',
    label: 'Water',
    icon: Icons.water_drop_outlined,
    color: Color(0xFF3B82F6),
    behavior: QuickActionBehavior.waterQuickAdd,
  ),
  'photo': QuickAction(
    id: 'photo',
    label: 'Photo',
    icon: Icons.camera_alt_outlined,
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
    route: '/stats',
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
  'settings': QuickAction(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    color: Color(0xFF64748B),
    behavior: QuickActionBehavior.route,
    route: '/settings',
  ),
  'chat': QuickAction(
    id: 'chat',
    label: 'Chat',
    icon: Icons.chat_outlined,
    color: Color(0xFF06B6D4),
    behavior: QuickActionBehavior.route,
    route: '/chat',
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
    route: '/progress',
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
    route: '/hydration',
  ),
  'summaries': QuickAction(
    id: 'summaries',
    label: 'Summary',
    icon: Icons.summarize_outlined,
    color: Color(0xFF8B5CF6),
    behavior: QuickActionBehavior.route,
    route: '/summaries',
  ),
};

const defaultQuickActionOrder = [
  'quick_workout', 'food', 'water', 'chat', 'weight', 'photo', 'fasting', 'measure', 'mood',
  'history', 'steps', 'workout', 'library', 'settings', 'schedule', 'habits',
  'progress', 'achievements', 'hydration', 'summaries',
];
