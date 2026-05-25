/// Shared Today Score contributor colours.
///
/// Train uses the brand orange; Fuel and Move are the macro-family green and
/// blue, consistent across the home redesign. Kept in one place so the score
/// card, the ring and the detail sheet never drift.
library;

import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import '../../../data/models/today_score.dart';
import '../../../l10n/generated/app_localizations.dart';

const Color kTrainColor = Color(0xFFEC8B2C);
const Color kFuelColor = Color(0xFF3FA66B); // Nourish (internal key remains "fuel")
const Color kMoveColor = Color(0xFF3E8FD0);
const Color kSleepColor = Color(0xFF8B5CF6); // Matches sleep iconography + Light/Deep bars

/// The solid colour for a contributor.
Color colorForContributor(ContributorKind kind) {
  switch (kind) {
    case ContributorKind.train:
      return kTrainColor;
    case ContributorKind.fuel:
      return kFuelColor;
    case ContributorKind.move:
      return kMoveColor;
    case ContributorKind.sleep:
      return kSleepColor;
  }
}

/// Lighten/darken a color by a [percent] (-1.0 to +1.0). Used by the G1 ring
/// gradient stops (light → vivid → dark sweep). Translated from the JS
/// `shade()` helper in `design-mocks/home/circle-compositions.html`.
Color shadeColor(Color base, double percent) {
  final delta = (255 * percent).round();
  // Use .r/.g/.b (Color.value/red/green/blue all deprecated in Flutter 3.27+).
  int clamp(int v) => v < 0 ? 0 : (v > 255 ? 255 : v);
  final r = clamp((base.r * 255.0).round() + delta);
  final g = clamp((base.g * 255.0).round() + delta);
  final b = clamp((base.b * 255.0).round() + delta);
  return Color.fromARGB((base.a * 255.0).round(), r, g, b);
}

/// Tier label and color for a 0-100 sleep / pillar score.
/// Returns the English label as a stable identifier; prefer
/// [localizedTierLabel] for UI display.
({String label, Color color}) tierFor(int score) {
  if (score >= 85) return (label: 'Excellent', color: Color(0xFF16A34A));
  if (score >= 70) return (label: 'Good', color: Color(0xFF3FA66B));
  if (score >= 50) return (label: 'Fair', color: Color(0xFFEC8B2C));
  return (label: 'Low', color: Color(0xFFE5544D));
}

/// Localized tier label for a 0-100 score.
String localizedTierLabel(BuildContext context, int score) {
  final l10n = AppLocalizations.of(context)!;
  if (score >= 85) return l10n.tierExcellent;
  if (score >= 70) return l10n.tierGood;
  if (score >= 50) return l10n.tierFair;
  return l10n.tierLow;
}
