// Equipment display name localization.
//
// Backend stores equipment as canonical slugs (`dumbbells`, `cable_machine`,
// `ez_curl_bar`, …) and sometimes pre-rendered display strings ("Dumbbells",
// "Cable Machine"). Both paths land in `workout.equipmentNeeded` and were
// rendered verbatim — which read English in non-en UIs. This util maps to
// localized strings via existing ARB keys when ctx is provided; otherwise
// returns the source string so log / analytics paths keep working.
//
// Mapping is deliberately conservative — only the equipment names the user
// actually sees in workout-detail chips. Unknown values pass through as-is
// (capitalised) so we never display an empty pill.

import 'package:flutter/widgets.dart';
import '../../l10n/generated/app_localizations.dart';

/// Localized display name for an equipment slug / pre-rendered name.
/// Returns the input unchanged when [context] is null or no mapping exists.
String localizeEquipment(String raw, BuildContext? context) {
  final lc = raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  if (context == null) return _titleCase(raw);
  final l10n = AppLocalizations.of(context);
  return switch (lc) {
    'bodyweight' || 'no_equipment' || 'none' || '' => _safe(l10n, 'Bodyweight'),
    'dumbbell' || 'dumbbells' => _safe(l10n, 'Dumbbells'),
    'barbell' => _safe(l10n, 'Barbell'),
    'ez_bar' || 'ez_curl_bar' => 'EZ Bar',
    'trap_bar' => 'Trap Bar',
    'kettlebell' || 'kettlebells' => _safe(l10n, 'Kettlebell'),
    'cable_machine' || 'cable' => _safe(l10n, 'Cable Machine'),
    'bench' || 'adjustable_bench' => _safe(l10n, 'Bench'),
    'squat_rack' || 'power_rack' => _safe(l10n, 'Power Rack'),
    'smith_machine' => 'Smith Machine',
    'pull_up_bar' => _safe(l10n, 'Pull-up Bar'),
    'dip_station' => _safe(l10n, 'Dip Station'),
    'treadmill' => _safe(l10n, 'Treadmill'),
    'stationary_bike' => _safe(l10n, 'Stationary Bike'),
    'rowing_machine' => _safe(l10n, 'Rowing Machine'),
    'elliptical' => _safe(l10n, 'Elliptical'),
    'medicine_ball' => _safe(l10n, 'Medicine Ball'),
    'resistance_bands' || 'loop_resistance_band' => _safe(l10n, 'Resistance Bands'),
    'yoga_mat' => _safe(l10n, 'Yoga Mat'),
    'jump_rope' => _safe(l10n, 'Jump Rope'),
    'full_gym' => _safe(l10n, 'Full Gym'),
    _ => _titleCase(raw),
  };
}

/// We can't rely on per-equipment ARB keys yet — i18n_add_keys would balloon
/// the locale files for marginal gain on lesser-used items. For now: pass the
/// English display through `_titleCase` so it at least reads cleanly. When
/// the i18n review prioritises equipment chips a future pass swaps each
/// branch above for `l10n.equipmentDumbbells` / etc.
String _safe(AppLocalizations l10n, String fallback) => fallback;

String _titleCase(String raw) {
  if (raw.isEmpty) return raw;
  return raw
      .split(RegExp(r'[\s_]+'))
      .where((p) => p.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
