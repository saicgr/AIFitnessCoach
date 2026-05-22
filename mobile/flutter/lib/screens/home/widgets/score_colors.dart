/// Shared Today Score contributor colours.
///
/// Train uses the brand orange; Fuel and Move are the macro-family green and
/// blue, consistent across the home redesign. Kept in one place so the score
/// card, the ring and the detail sheet never drift.
library;

import 'package:flutter/painting.dart';

import '../../../data/models/today_score.dart';

const Color kTrainColor = Color(0xFFEC8B2C);
const Color kFuelColor = Color(0xFF3FA66B);
const Color kMoveColor = Color(0xFF3E8FD0);

/// The solid colour for a contributor.
Color colorForContributor(ContributorKind kind) {
  switch (kind) {
    case ContributorKind.train:
      return kTrainColor;
    case ContributorKind.fuel:
      return kFuelColor;
    case ContributorKind.move:
      return kMoveColor;
  }
}
