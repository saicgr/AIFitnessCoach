import 'package:flutter/material.dart';

enum QuickActionBehavior {
  route,
  waterQuickAdd,
  foodLog,
  foodScan, // Opens LogMealSheet and immediately launches multi-image food scan
  menuScan, // Opens LogMealSheet and immediately launches menu scan
  foodPhoto, // Opens LogMealSheet and immediately fires the single-photo camera flow
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
  // Opens the RecipeBuilderSheet (create a custom recipe from scratch /
  // ingredients). Surfaced because the builder previously had no entry point
  // outside the Food Library.
  recipeBuilder,
  // Opens the Form Analysis sheet with NO exercise name — the AI auto-detects
  // the movement from the clip. Record/upload a set from anywhere.
  formCheck,
  // Opens the create-custom-exercise sheet (Fill-with-AI). Surfaced so a user
  // can add a movement from Quick Actions, not just deep in the Library.
  addExercise,
  // Opens the gut-health (Bristol-scale) log sheet — the same one-tap sheet on
  // the Nutrition Daily tab. Feeds the Patterns "Your natural rhythm" section.
  gutHealth,
}

// E2E register row 15: this registry used to hand each of the 35 quick
// actions its own private hex (amber/green/teal/blue/purple/pink/red/...),
// independent of the app's accent setting. `color` below is now
// single-sourced to [_defaultChipColor] instead of a distinct value per
// action.
//
// This registry is a top-level `const` map with no `BuildContext`, so it
// cannot read `context.accentColor` itself. `copyWith` exists so a
// context-aware call site CAN re-tint an action with the live accent
// (`action.copyWith(color: context.accentColor)`); `lib/widgets/quick_actions_sheet.dart`
// (owned by this pass) has been wired to do so. Consumers under
// `lib/screens/home/` (outside this pass's file ownership) still render the
// single default colour below pending the same wiring.
const _defaultChipColor = Color(0xFFF97316); // accent-allowlist: const registry has no BuildContext to read the live accent from; single-sourced default (was 35 distinct per-action hexes) pending a context-aware override at each lib/screens/home/ consumer via copyWith

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

  /// Lets a context-aware caller re-tint this action (e.g. with
  /// `context.accentColor`) without the model itself needing a BuildContext.
  QuickAction copyWith({
    String? id,
    String? label,
    IconData? icon,
    Color? color,
    QuickActionBehavior? behavior,
    String? route,
  }) {
    return QuickAction(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      behavior: behavior ?? this.behavior,
      route: route ?? this.route,
    );
  }
}

const quickActionRegistry = <String, QuickAction>{
  'weight': QuickAction(
    id: 'weight',
    label: 'Weight',
    // scale (not monitor_weight): the boxy monitor_weight glyph read as an
    // unrecognizable square at small tile sizes in the quick-log sheet.
    icon: Icons.scale_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.weightLog,
  ),
  'food': QuickAction(
    id: 'food',
    label: 'Food',
    icon: Icons.restaurant_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.foodLog,
  ),
  'scan_food': QuickAction(
    id: 'scan_food',
    label: 'Scan Food',
    // Distinct from Progress Photo (accessibility_new) and the bottom-bar
    // camera button — "document scanner" reads as "scan this thing" in the
    // Material set and pairs with the amber Scan Menu entry.
    icon: Icons.document_scanner_outlined,
    color: _defaultChipColor,
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
    color: _defaultChipColor,
    behavior: QuickActionBehavior.foodPhoto,
  ),
  'barcode_food': QuickAction(
    id: 'barcode_food',
    label: 'Barcode',
    icon: Icons.qr_code_scanner_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.foodBarcode,
  ),
  'scan_menu': QuickAction(
    id: 'scan_menu',
    label: 'Scan Menu',
    icon: Icons.menu_book_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.menuScan,
  ),
  'water': QuickAction(
    id: 'water',
    label: 'Water',
    icon: Icons.water_drop_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.waterQuickAdd,
  ),
  'photo': QuickAction(
    id: 'photo',
    // Surface 1.3 — "Progress Photo" makes the destination unambiguous;
    // grid cell wraps gracefully at this length on iPhone SE.
    label: 'Progress Photo',
    icon: Icons.accessibility_new_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/stats?openPhoto=true',
  ),
  'quick_workout': QuickAction(
    id: 'quick_workout',
    label: 'Quick',
    icon: Icons.flash_on,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.quickWorkout,
  ),
  'fasting': QuickAction(
    id: 'fasting',
    label: 'Fasting',
    icon: Icons.timer_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.fastingNav,
    route: '/fasting',
  ),
  'measure': QuickAction(
    id: 'measure',
    label: 'Measure',
    icon: Icons.straighten_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/measurements',
  ),
  'mood': QuickAction(
    id: 'mood',
    label: 'Mood',
    icon: Icons.mood_outlined,
    color: _defaultChipColor,
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
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
  ),
  'history': QuickAction(
    id: 'history',
    label: 'History',
    icon: Icons.history_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/workout-gallery',
  ),
  'steps': QuickAction(
    id: 'steps',
    label: 'Steps',
    icon: Icons.directions_walk_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/neat',
  ),
  'workout': QuickAction(
    id: 'workout',
    label: 'Workout',
    icon: Icons.fitness_center_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/workouts',
  ),
  'library': QuickAction(
    id: 'library',
    label: 'Library',
    icon: Icons.menu_book_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/library',
  ),
  'programs': QuickAction(
    id: 'programs',
    label: 'Programs',
    icon: Icons.view_list_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/library?tab=1',
  ),
  'chat': QuickAction(
    id: 'chat',
    label: 'Chat',
    icon: Icons.auto_awesome,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.chat,
  ),
  'settings': QuickAction(
    id: 'settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/settings',
  ),
  'schedule': QuickAction(
    id: 'schedule',
    label: 'Schedule',
    icon: Icons.calendar_today_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/schedule',
  ),
  'habits': QuickAction(
    id: 'habits',
    label: 'Habits',
    icon: Icons.checklist_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/habits',
  ),
  'progress': QuickAction(
    id: 'progress',
    label: 'Progress',
    icon: Icons.show_chart_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    // Score tab is index 3 (Overload was inserted at index 1).
    route: '/stats?tab=3',
  ),
  'achievements': QuickAction(
    id: 'achievements',
    label: 'Achieve',
    icon: Icons.emoji_events_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/achievements',
  ),
  'hydration': QuickAction(
    id: 'hydration',
    label: 'Hydration',
    icon: Icons.local_drink_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/hydration',
  ),
  'summaries': QuickAction(
    id: 'summaries',
    label: 'Summary',
    icon: Icons.summarize_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/summaries',
  ),
  'stats': QuickAction(
    id: 'stats',
    label: 'Stats',
    icon: Icons.leaderboard_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/stats',
  ),
  // Lives only inside the "More" overflow sheet — never the primary 2×5
  // grid. Tapping opens SharePlanPeriodSheet which mints a zealova.com link.
  'share_plan': QuickAction(
    id: 'share_plan',
    label: 'Share',
    icon: Icons.ios_share_rounded,
    color: _defaultChipColor,
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
    color: _defaultChipColor,
    behavior: QuickActionBehavior.identifyEquipment,
  ),
  // F3B: one-tap Travel Mode. Lives in the More overflow by default (pinnable
  // via the customize sheet). Switches the active gym to the bodyweight
  // Travel/Hotel profile so workouts work in any hotel room.
  'travel_mode': QuickAction(
    id: 'travel_mode',
    label: 'Travel Mode',
    icon: Icons.hotel_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.travelMode,
  ),
  // Calorii-audit surfacing — all four already exist as features; these
  // tiles just make them reachable from Quick Actions.
  'meal_planner': QuickAction(
    id: 'meal_planner',
    label: 'Meal Plan',
    icon: Icons.event_note_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/nutrition/meal-planner',
  ),
  'recipe_creator': QuickAction(
    id: 'recipe_creator',
    label: 'New Recipe',
    icon: Icons.menu_book_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.recipeBuilder,
  ),
  'from_fridge': QuickAction(
    id: 'from_fridge',
    label: 'From Fridge',
    icon: Icons.kitchen_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/nutrition/from-fridge',
  ),
  'gut_health': QuickAction(
    id: 'gut_health',
    label: 'Gut Health',
    icon: Icons.spa_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.gutHealth,
  ),
  'custom_trends': QuickAction(
    id: 'custom_trends',
    label: 'Custom Trends',
    icon: Icons.insights_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/trends/custom',
  ),
  // Form Check — record/upload any clip, exercise name optional (AI
  // auto-detects). More-only by default, pinnable; never displaces the
  // protected primary slots (slot 9 = scan_menu, slot 10 = More).
  'form_check': QuickAction(
    id: 'form_check',
    label: 'Form Check',
    // videocam (not sports_gymnastics): form check = record/upload a video
    // of your lift; the gymnast glyph read as martial arts, not video review.
    icon: Icons.videocam_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.formCheck,
  ),
  // Add Exercise — open the AI create-exercise sheet (Fill-with-AI) directly.
  'add_exercise': QuickAction(
    id: 'add_exercise',
    label: 'Add Exercise',
    icon: Icons.add_circle_outline,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.addExercise,
  ),
  // Pelvic Floor Exercises — built (Quick Start card, Beginner/Intermediate
  // tiers, postpartum + prostate protocols) but previously reachable only by
  // deep link. More-only by default, pinnable.
  'kegel': QuickAction(
    id: 'kegel',
    label: 'Pelvic Floor',
    icon: Icons.self_improvement_outlined,
    color: _defaultChipColor,
    behavior: QuickActionBehavior.route,
    route: '/kegel-session',
  ),
};

// Home shortcut bar layout (`CompactQuickActionsRow`):
//   A single fixed row → slots 1-6 are the first 6 entries; slot 7 = fixed
//   "More". The row is hidden by default and shown via the customize sheet's
//   "Show on home screen" toggle.
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
  // The pinned row shows the first 6 (trailing More tile is appended by the
  // row widget):
  //   Log Food · Scan Menu · Water · Weight · Snap Food · Meditate
  'food', 'scan_menu', 'water', 'weight', 'photo_food', 'meditate',
  // Everything past slot 6 lives in the More sheet unless reordered up:
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
  // Calorii-audit surfacing tiles — More-only by default, pinnable.
  'meal_planner', 'recipe_creator', 'from_fridge', 'custom_trends',
  // Gut-health one-tap logger — More-only by default, pinnable. Same sheet as
  // the Nutrition Daily tile; feeds the Patterns "natural rhythm" section.
  'gut_health',
  // Gravl-parity additions — More-only by default, pinnable. Form Check rides
  // the AI form-analysis flow (no exercise name → AI auto-detects); Add
  // Exercise opens the Fill-with-AI create-exercise sheet.
  'form_check', 'add_exercise',
  // Pelvic Floor Exercises — More-only by default, pinnable.
  'kegel',
  // 'chat' kept in the catalog for users who want to re-pin it.
  'chat',
];
