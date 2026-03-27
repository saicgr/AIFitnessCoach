import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../repositories/auth_repository.dart';
import 'feature_adoption_provider.dart';

// ============================================
// Week 1 Tip Model
// ============================================

/// A single progressive feature tip shown during the user's first two weeks.
class Week1Tip {
  final String featureKey;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionRoute;
  final Color accentColor;

  const Week1Tip({
    required this.featureKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionRoute,
    required this.accentColor,
  });
}

// ============================================
// Tip Schedule
// ============================================

/// Internal schedule entry pairing a day range with tip content.
class _TipScheduleEntry {
  final int startDay; // Inclusive
  final int endDay; // Exclusive (tip shows when startDay <= daysSinceSignup < endDay)
  final Week1Tip tip;

  const _TipScheduleEntry({
    required this.startDay,
    required this.endDay,
    required this.tip,
  });
}

/// Ordered tip schedule. The first tip whose day range matches AND whose
/// feature has NOT been used yet is shown. Covers days 0–14.
const List<_TipScheduleEntry> _tipSchedule = [
  // ── Week 1: Core habits ──────────────────────────────────
  _TipScheduleEntry(
    startDay: 0,
    endDay: 2,
    tip: Week1Tip(
      featureKey: 'photo_meal_log',
      title: 'Snap & Track',
      subtitle: 'Snap a photo of your meal for instant nutrition tracking',
      icon: Icons.camera_alt_outlined,
      actionRoute: '/nutrition?camera=true',
      accentColor: AppColors.orange,
    ),
  ),
  _TipScheduleEntry(
    startDay: 1,
    endDay: 3,
    tip: Week1Tip(
      featureKey: 'barcode_scan',
      title: 'Barcode Scanner',
      subtitle: 'Scan any product barcode for precise nutrition data',
      icon: Icons.qr_code_scanner_outlined,
      actionRoute: '/nutrition?barcode=true',
      accentColor: AppColors.cyan,
    ),
  ),
  _TipScheduleEntry(
    startDay: 2,
    endDay: 4,
    tip: Week1Tip(
      featureKey: 'ai_chat_message',
      title: 'Ask Your Coach',
      subtitle: 'Ask your AI coach anything about fitness or nutrition',
      icon: Icons.chat_outlined,
      actionRoute: '/chat',
      accentColor: AppColors.purple,
    ),
  ),
  _TipScheduleEntry(
    startDay: 3,
    endDay: 5,
    tip: Week1Tip(
      featureKey: 'workout_completed',
      title: 'Build Your Streak',
      subtitle: "Complete today's workout to build your streak",
      icon: Icons.fitness_center_outlined,
      actionRoute: '/consistency',
      accentColor: AppColors.success,
    ),
  ),
  _TipScheduleEntry(
    startDay: 4,
    endDay: 6,
    tip: Week1Tip(
      featureKey: 'nutrition_target_set',
      title: 'Set Nutrition Targets',
      subtitle: 'Set your daily nutrition targets for better tracking',
      icon: Icons.track_changes_outlined,
      actionRoute: '/nutrition-settings',
      accentColor: AppColors.orange,
    ),
  ),
  _TipScheduleEntry(
    startDay: 5,
    endDay: 7,
    tip: Week1Tip(
      featureKey: 'health_connect_enabled',
      title: 'Connect Health',
      subtitle: 'Connect Health to auto-track steps and calories',
      icon: Icons.monitor_heart_outlined,
      actionRoute: '/settings/health-devices',
      accentColor: AppColors.green,
    ),
  ),
  // ── Week 2: Discovery & engagement ───────────────────────
  _TipScheduleEntry(
    startDay: 7,
    endDay: 9,
    tip: Week1Tip(
      featureKey: 'water_logged',
      title: 'Log Your Water',
      subtitle: 'Stay hydrated — track your daily water intake',
      icon: Icons.water_drop_outlined,
      actionRoute: '/nutrition?tab=2',
      accentColor: AppColors.cyan,
    ),
  ),
  _TipScheduleEntry(
    startDay: 8,
    endDay: 10,
    tip: Week1Tip(
      featureKey: 'weight_logged',
      title: 'Track Your Weight',
      subtitle: 'Log your weight to see trends over time',
      icon: Icons.monitor_weight_outlined,
      actionRoute: '/measurements/weight',
      accentColor: AppColors.orange,
    ),
  ),
  _TipScheduleEntry(
    startDay: 9,
    endDay: 11,
    tip: Week1Tip(
      featureKey: 'progress_photo_taken',
      title: 'Progress Photo',
      subtitle: 'Take a photo to compare your transformation later',
      icon: Icons.photo_camera_front_outlined,
      actionRoute: '/stats?openPhoto=true',
      accentColor: AppColors.purple,
    ),
  ),
  _TipScheduleEntry(
    startDay: 10,
    endDay: 12,
    tip: Week1Tip(
      featureKey: 'stats_viewed',
      title: 'View Your Stats',
      subtitle: 'Explore your workout analytics and muscle breakdown',
      icon: Icons.bar_chart_outlined,
      actionRoute: '/stats',
      accentColor: AppColors.success,
    ),
  ),
  _TipScheduleEntry(
    startDay: 11,
    endDay: 13,
    tip: Week1Tip(
      featureKey: 'achievements_viewed',
      title: 'Check Achievements',
      subtitle: 'See what badges and trophies you\'ve unlocked',
      icon: Icons.emoji_events_outlined,
      actionRoute: '/achievements',
      accentColor: AppColors.orange,
    ),
  ),
  _TipScheduleEntry(
    startDay: 12,
    endDay: 14,
    tip: Week1Tip(
      featureKey: 'weekly_summary_viewed',
      title: 'Weekly Summary',
      subtitle: 'Review your week — workouts, nutrition, and insights',
      icon: Icons.summarize_outlined,
      actionRoute: '/summaries',
      accentColor: AppColors.cyan,
    ),
  ),
];

// ============================================
// Provider
// ============================================

/// Provides the current [Week1Tip] to show, or null if none applies.
///
/// Logic:
/// 1. Compute days since signup from user.createdAt.
/// 2. Walk the schedule in order.
/// 3. Return the first tip where the day range matches AND the feature has
///    not yet been used (per [featureAdoptionProvider]).
/// 4. Return null after day 14 or when all tips are used.
final week1TipProvider = Provider<Week1Tip?>((ref) {
  // Read auth state to get createdAt
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  if (user == null || user.createdAt == null) return null;

  // Parse createdAt and compute days since signup
  final DateTime createdAt;
  try {
    createdAt = DateTime.parse(user.createdAt!);
  } catch (_) {
    return null;
  }

  final now = DateTime.now();
  final daysSinceSignup = now.difference(createdAt).inDays;

  // Past two weeks — no more tips
  if (daysSinceSignup >= 14) return null;

  // Read feature adoption state
  final adoptionState = ref.watch(featureAdoptionProvider);

  // Find the first eligible tip
  for (final entry in _tipSchedule) {
    if (daysSinceSignup >= entry.startDay &&
        daysSinceSignup < entry.endDay &&
        !adoptionState.hasUsedFeature(entry.tip.featureKey)) {
      return entry.tip;
    }
  }

  return null;
});
