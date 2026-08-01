import 'package:flutter/material.dart';

/// Codepoint → **const** `IconData`, so release builds can tree-shake icons.
///
/// ## Why this exists (E2E #157)
///
/// `flutter build ios --release` failed **project-wide** with:
///
///     Target release_ios_bundle_flutter_assets failed:
///     Avoid non-constant invocations of IconData
///
/// Release mode strips unused glyphs out of the icon fonts, which it can only
/// do if every `IconData` is a compile-time constant it can see. Two sites
/// built one from a runtime integer, so the compiler could not know which
/// glyphs were reachable and refused to build at all — no IPA, no TestFlight,
/// no App Store. Broken since 2026-06-14, and nothing caught it because no CI
/// workflow builds iOS.
///
/// ## Why a fixed table loses nothing
///
/// Both call sites are **round-trips of icons the app itself chose**, not icons
/// arriving from outside:
///
///  * Habits — the icon originates in `habits_section.dart`'s
///    `_getIconData(String)`, a hardcoded name→icon map. `HabitDetailData`
///    only serialises `icon.codePoint` so the icon survives a JSON hop between
///    screens, then rebuilds it on the far side.
///  * Shareables — `IconProps.iconCodepoint` is **never assigned anywhere in
///    `lib/`**; every icon prop today is an emoji (`isEmoji` is true exactly
///    when the codepoint is null). The non-emoji branch was unreachable and
///    still broke the build.
///
/// So nothing can supply a codepoint outside this table, and keeping
/// tree-shaking costs no capability. If a genuinely open-ended icon source is
/// ever added, the honest options are to extend this table or to pass
/// `--no-tree-shake-icons` — not to reintroduce a dynamic `IconData`.
///
/// ## Why the list is const but the map is not
///
/// Only the `IconData` *invocations* must be constant for tree-shaking; the
/// lookup structure need not be. Deriving the keys with `icon.codePoint`
/// rather than hand-writing hex avoids a whole class of silent bug — a
/// mistyped codepoint would map to the wrong glyph, or to none, and would only
/// ever be noticed on screen.
///
/// Gated by `test/core/const_icons_test.dart`, which fails if a new non-const
/// `IconData(...)` appears anywhere in `lib/`.
const List<IconData> kKnownIcons = <IconData>[
  // The habit icon set (`habits_section.dart` / `habits_card.dart`).
  Icons.add,
  Icons.add_rounded,
  Icons.arrow_forward,
  Icons.bedtime,
  Icons.check,
  Icons.check_circle,
  Icons.check_rounded,
  Icons.directions_run,
  Icons.directions_walk,
  Icons.do_not_disturb,
  Icons.eco,
  Icons.edit_note,
  Icons.error_outline,
  Icons.favorite,
  Icons.fitness_center,
  Icons.local_fire_department,
  Icons.medication,
  Icons.menu_book,
  Icons.no_drinks,
  Icons.phone_disabled,
  Icons.restaurant,
  Icons.restaurant_menu,
  Icons.self_improvement,
  Icons.spa,
  Icons.star,
  Icons.track_changes,
  Icons.water_drop,
  Icons.wb_sunny,
];

/// Built from [kKnownIcons] so the codepoints can never drift from the glyphs.
final Map<int, IconData> kIconsByCodePoint = <int, IconData>{
  for (final icon in kKnownIcons) icon.codePoint: icon,
};

/// Shown when a stored codepoint is not in [kIconsByCodePoint].
///
/// Deliberately neutral rather than an error glyph: an unknown codepoint means
/// the table is out of date, which is a developer problem — not something to
/// shout at the user about mid-workout.
const IconData kFallbackIcon = Icons.check_circle;

/// Resolve a serialised codepoint back to a const [IconData].
IconData iconFromCodePoint(int? codePoint) =>
    kIconsByCodePoint[codePoint] ?? kFallbackIcon;
