import 'package:flutter/material.dart';
import 'package:fitwiz/core/constants/branding.dart';

/// Catalog of data-export categories surfaced in the Export dialog.
///
/// Keys are the wire format consumed by
/// `backend/services/data_export.py::EXPORT_CATEGORIES`. Changes here MUST
/// be mirrored there (and vice-versa) — the backend silently ignores
/// unknown keys, so a typo here would show a toggle that does nothing.
///
/// Profile is always included server-side and intentionally not listed here:
/// the export is useless without the user record and there is no legitimate
/// reason to opt out of it.
class ExportCategory {
  final String key;
  final String label;
  final String description;
  final IconData icon;

  const ExportCategory({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const List<ExportCategory> kExportCategories = [
  ExportCategory(
    key: 'workouts',
    label: 'Workouts & Sets',
    description: 'Scheduled plans, completed logs, and exercise sets',
    icon: Icons.fitness_center,
  ),
  ExportCategory(
    key: 'strength',
    label: 'Personal Records',
    description: '1RMs and strength milestones',
    icon: Icons.emoji_events_outlined,
  ),
  ExportCategory(
    key: 'body',
    label: 'Body Metrics',
    description: 'Weight, measurements, body composition',
    icon: Icons.monitor_weight_outlined,
  ),
  ExportCategory(
    key: 'achievements',
    label: 'Achievements & Streaks',
    description: 'Trophies earned and streak history',
    icon: Icons.military_tech_outlined,
  ),
  ExportCategory(
    key: 'nutrition',
    label: 'Nutrition',
    description: 'Food logs, daily summaries, water intake',
    icon: Icons.restaurant_outlined,
  ),
  ExportCategory(
    key: 'chat',
    label: 'Coach Chat History',
    description: 'Your conversations with ${Branding.appName} coaches',
    icon: Icons.chat_bubble_outline,
  ),
  ExportCategory(
    key: 'photos',
    label: 'Progress Photos',
    description: 'Photo metadata and URLs',
    icon: Icons.photo_library_outlined,
  ),
  ExportCategory(
    key: 'health',
    label: 'Health & Wellness',
    description: 'Injuries, mood, cardio, cycle & kegel logs',
    icon: Icons.favorite_outline,
  ),
  ExportCategory(
    key: 'goals',
    label: 'Goals & Habits',
    description: 'Personal goals, habits, and completions',
    icon: Icons.flag_outlined,
  ),
  ExportCategory(
    key: 'custom',
    label: 'Custom Content',
    description: 'Custom exercises and AI settings',
    icon: Icons.tune,
  ),
];

/// Fast lookup by key. Used when rehydrating persisted selections.
final Map<String, ExportCategory> kExportCategoryByKey = {
  for (final c in kExportCategories) c.key: c,
};
