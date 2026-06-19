/// Shared registry of bundled stock background images for share cards.
///
/// These were shipped to `assets/images/shareable_backgrounds/{pack}` by the
/// redesign foundation (A1). Lifted out of `card_editor_screen.dart`'s private
/// `_BackgroundSheet._packs` so the photo-first compose screen
/// (`ShareComposeScreen`) and the editor's Background sheet draw from ONE
/// source of truth — adding a pack/asset here surfaces it in both places.
///
/// Each entry is an `assets/`-prefixed path. Apply one to a card background via
/// a [CardBackground] with `photo: CardPhotoRef(staticPath: <path>)` and
/// `kind: CardBackgroundKind.photo` (see `card_editor_screen.dart`
/// `_setAssetPhoto`).
library;

import 'shareable_data.dart';

/// One named pack of stock backgrounds (e.g. "Workout").
class StockBackgroundPack {
  final String name;
  final List<String> assets;
  const StockBackgroundPack(this.name, this.assets);
}

/// Ordered list of stock-background packs. The order here is the order shown in
/// the compose screen's Stock tab and the editor's Background sheet.
const List<StockBackgroundPack> kStockBackgroundPacks = [
  StockBackgroundPack('Workout', _workoutBgs),
  StockBackgroundPack('Nutrition', _nutritionBgs),
  StockBackgroundPack('Abstract', _abstractBgs),
];

const List<String> _workoutBgs = [
  'assets/images/shareable_backgrounds/workout/bg-01.jpg',
  'assets/images/shareable_backgrounds/workout/bg-02.jpg',
  'assets/images/shareable_backgrounds/workout/bg-03.jpg',
  'assets/images/shareable_backgrounds/workout/bg-04.jpg',
  'assets/images/shareable_backgrounds/workout/bg-05.jpg',
  'assets/images/shareable_backgrounds/workout/bg-06.jpg',
  'assets/images/shareable_backgrounds/workout/bg-07.jpg',
  'assets/images/shareable_backgrounds/workout/bg-08.jpg',
  'assets/images/shareable_backgrounds/workout/bg-09.jpg',
  'assets/images/shareable_backgrounds/workout/bg-10.jpg',
  'assets/images/shareable_backgrounds/workout/bg-11.jpg',
  'assets/images/shareable_backgrounds/workout/bg-12.jpg',
  'assets/images/shareable_backgrounds/workout/bg-21.jpg',
  'assets/images/shareable_backgrounds/workout/bg-22.jpg',
  'assets/images/shareable_backgrounds/workout/bg-23.jpg',
  'assets/images/shareable_backgrounds/workout/bg-24.jpg',
  'assets/images/shareable_backgrounds/workout/bg-25.jpg',
  'assets/images/shareable_backgrounds/workout/bg-26.jpg',
  'assets/images/shareable_backgrounds/workout/bg-27.jpg',
  'assets/images/shareable_backgrounds/workout/bg-28.jpg',
];

const List<String> _nutritionBgs = [
  'assets/images/shareable_backgrounds/nutrition/bg-01.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-02.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-03.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-04.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-05.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-06.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-07.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-08.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-09.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-10.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-21.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-22.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-23.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-24.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-25.jpg',
  'assets/images/shareable_backgrounds/nutrition/bg-26.jpg',
];

const List<String> _abstractBgs = [
  'assets/images/shareable_backgrounds/abstract/bg-21.jpg',
  'assets/images/shareable_backgrounds/abstract/bg-22.jpg',
  'assets/images/shareable_backgrounds/abstract/bg-23.jpg',
  'assets/images/shareable_backgrounds/abstract/bg-24.jpg',
  'assets/images/shareable_backgrounds/abstract/bg-25.jpg',
  'assets/images/shareable_backgrounds/abstract/bg-26.jpg',
];

/// Flat list of every stock background asset, across all packs.
List<String> get kAllStockBackgrounds =>
    [for (final p in kStockBackgroundPacks) ...p.assets];

/// The pack most relevant to a share kind — surfaced first in the compose
/// screen so a food share lands on Nutrition backgrounds and a workout share
/// on Workout backgrounds. Falls back to Abstract for everything else.
String defaultStockPackNameForKind(ShareableKind kind) {
  switch (kind) {
    case ShareableKind.foodLog:
    case ShareableKind.nutrition:
      return 'Nutrition';
    case ShareableKind.workoutComplete:
    case ShareableKind.personalRecords:
    case ShareableKind.oneRm:
    case ShareableKind.exerciseHistory:
    case ShareableKind.muscleAnalytics:
    case ShareableKind.strength:
    case ShareableKind.weeklyPlan:
    case ShareableKind.monthlyPlan:
    case ShareableKind.weeklyProgress:
    case ShareableKind.weeklySummary:
      return 'Workout';
    default:
      return 'Abstract';
  }
}
