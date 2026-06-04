import 'package:flutter/material.dart';

enum QuickActionBehavior {
  route,
  waterQuickAdd,
  foodLog,
  foodScan,    // Opens LogMealSheet and immediately launches multi-image food scan
  menuScan,    // Opens LogMealSheet and immediately launches menu scan
  foodPhoto,   // Opens LogMealSheet and immediately fires the single-photo camera flow
  foodBarcode, // Opens LogMealSheet and immediately fires the barcode scanner
  weightLog,
  moodLog,
  fastingNav,
  quickWorkout,
  chat,
  // Issue 2: opens EquipmentSnapFlow in identify mode → success routes to
  // chat with the photo attached and identify_equipment tool already running.
  identifyEquipment,
  // F3B: one-tap Travel Mode — activates the bodyweight Travel/Hotel gym
  // profile (find-or-restore-or-create on the backend), then invalidates the
  // workout providers so Today/Workouts regenerate against bodyweight.
  travelMode,
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
  // "Photo Log" replaces 'scan_food' as the default slot-5 entry — single
  // camera shot of a meal. Uses a food (lunch_dining) icon to telegraph
  // "snap your plate" rather than the document-scanner glyph.
  'photo_food': QuickAction(
    id: 'photo_food',
    // Surface 1.3 — clearer verb: "Snap Food" reads as the camera action.
    label: 'Snap Food',
    icon: Icons.lunch_dining_outlined,
    color: Color(0xFF22C55E),
    behavior: QuickActionBehavior.foodPhoto,
  ),
  'barcode_food': QuickAction(
    id: 'barcode_food',
    label: 'Barcode',
    icon: Icons.qr_code_scanner_outlined,
    color: Color(0xFF14B8A6),
    behavior: QuickActionBehavior.foodBarcode,
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
    // Surface 1.3 — "Progress Photo" makes the destination unambiguous;
    // grid cell wraps gracefully at this length on iPhone SE.
    label: 'Progress Photo',
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
  // Meditate — opens today's curated guided session (the same destination the
  // removed home "Mind" card used). Behavior is `route`, but the launcher
  // special-cases the 'meditate' id BEFORE the default branch to resolve the
  // daily pick (slug/title/duration/audio) before pushing /mindfulness/session.
  'meditate': QuickAction(
    id: 'meditate',
    label: 'Meditate',
    icon: Icons.self_improvement_outlined,
    color: Color(0xFF8B5CF6),
    behavior: QuickActionBehavior.route,
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
  // Lives only inside the "More" overflow sheet — never the primary 2×5
  // grid. Tapping opens SharePlanPeriodSheet which mints a zealova.com link.
  'share_plan': QuickAction(
    id: 'share_plan',
    label: 'Share',
    icon: Icons.ios_share_rounded,
    color: Color(0xFF0EA5E9),
    behavior: QuickActionBehavior.route,
    route: '/share-plan',
  ),
  // Issue 2: lives ONLY in the More overflow sheet (never the 2×5 grid —
  // memory feedback_quick_actions_layout: slot 9 = scan_menu, slot 10 =
  // More, never remove). Tapping opens EquipmentSnapFlow in identify
  // mode; on success, returns to chat with photo + identify_equipment
  // tool result already pre-loaded.
  'identify_equipment': QuickAction(
    id: 'identify_equipment',
    label: "What's this?",
    icon: Icons.camera_alt_outlined,
    color: Color(0xFF06B6D4),
    behavior: QuickActionBehavior.identifyEquipment,
  ),
  // F3B: one-tap Travel Mode. Lives in the More overflow by default (pinnable
  // via the customize sheet). Switches the active gym to the bodyweight
  // Travel/Hotel profile so workouts work in any hotel room.
  'travel_mode': QuickAction(
    id: 'travel_mode',
    label: 'Travel Mode',
    icon: Icons.hotel_outlined,
    color: Color(0xFFF59E0B),
    behavior: QuickActionBehavior.travelMode,
  ),
};

// Home shortcut bar layout (home-v27 redesign — `CompactQuickActionsRow`):
//   Single-row mode  → slots 1-5 are the first 5 entries; slot 6 = fixed "More".
//   Two-row mode     → slots 1-11 are the first 11 entries; slot 12 = fixed "More".
// The user reorders this list in the customize sheet; "More" is never an
// entry here — it is appended by the row widget. Anything past the visible
// cutoff stays reachable inside the full QuickActionsSheet (via More).
//
// D3: 'workout' / 'quick_workout' removed from the pinned default — the
// Workouts tab already covers them. They remain in the catalog below so
// users can still pin them via the customize sheet / reach them via More.
//
// 'chat' removed from the pinned default — the Coach is now reachable via
// the persistent `FloatingChatBubble` (draggable coach head) rendered by
// `MainShell` on every main tab. The action itself remains in the catalog
// above so users who want a second entry point (e.g. as a quick-action
// shortcut) can re-pin it via the customize sheet.
const defaultQuickActionOrder = [
  // Default row 1 (single-row mode shows the first 6, scrollable; trailing
  // More tile is appended by the row widget):
  //   Log Food · Scan Menu · Water · Weight · Snap Food · Meditate
  'food', 'scan_menu', 'water', 'weight', 'photo_food', 'meditate',
  // Two-row mode fills the next slots from here (slot 12 = More):
  'photo', 'mood', 'scan_food', 'barcode_food', 'measure', 'hydration',
  // ─── long-tail (More sheet only unless reordered up):
  'quick_workout', 'workout', 'history', 'steps', 'programs',
  'library', 'settings', 'schedule', 'habits',
  'progress', 'stats', 'achievements', 'summaries',
  // ─── More-only overflow ── never appears in the primary grid:
  'share_plan',
  // Issue 2: discoverable in More sheet only.
  'identify_equipment',
  // F3B: Travel Mode — More-only by default, pinnable. Sits in the overflow
  // region (after identify_equipment, before chat); never displaces the
  // protected primary slots (slot 9 = scan_menu, slot 10 = More).
  'travel_mode',
  // 'chat' kept in the catalog for users who want to re-pin it.
  'chat',
];
