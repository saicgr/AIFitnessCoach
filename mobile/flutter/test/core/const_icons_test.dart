// Regression gate for E2E #157 — the release build must stay buildable.
//
// `flutter build ios --release` strips unused glyphs from the icon fonts, and
// can only do so when every `IconData` is a compile-time constant. A single
// `IconData(someRuntimeInt)` anywhere in lib/ fails the WHOLE release build:
//
//     Target release_ios_bundle_flutter_assets failed:
//     Avoid non-constant invocations of IconData
//
// That is not a warning — it means no IPA, no TestFlight, no App Store. It had
// been broken for ~7 weeks before anyone noticed, because no CI workflow
// builds iOS and a debug/simulator build tree-shakes nothing, so local work
// looks completely healthy.
//
// This test is the cheap substitute for the iOS build nobody runs: it fails in
// ~a second on `flutter test` instead of at submission time.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitwiz/core/utils/const_icons.dart';

/// `IconData(` NOT preceded by `const` and not part of a type annotation
/// (`IconData?`, `List<IconData>`, `IconData foo`). Deliberately simple — it
/// is meant to catch the shape the compiler rejects, not to parse Dart.
final _dynamicIconData = RegExp(r'(?<!const )\bIconData\s*\(');

void main() {
  group('release-build icon tree-shaking', () {
    test('no non-const IconData construction anywhere in lib/', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue,
          reason: 'run this from mobile/flutter');

      final offenders = <String>[];
      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // Generated l10n is enormous and contains no IconData construction.
        if (entity.path.contains('/l10n/generated/')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trimLeft();
          // Skip comments — the fix's own docs quote the offending shape.
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
          if (trimmed.startsWith('*') || trimmed.startsWith('/*')) continue;
          if (_dynamicIconData.hasMatch(line)) {
            offenders.add('${entity.path}:${i + 1}: ${trimmed.trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'These construct IconData from a runtime value, which fails '
            '`flutter build ios --release` for the ENTIRE app.\n'
            'Resolve the codepoint through iconFromCodePoint() in '
            'core/utils/const_icons.dart instead:\n  '
            '${offenders.join('\n  ')}',
      );
    });
  });

  group('const icon table', () {
    test('every known icon round-trips through its codepoint', () {
      for (final icon in kKnownIcons) {
        expect(iconFromCodePoint(icon.codePoint), icon,
            reason: '${icon.codePoint} should resolve back to itself');
      }
    });

    test('codepoints are unique — no glyph silently shadows another', () {
      final seen = <int, IconData>{};
      for (final icon in kKnownIcons) {
        expect(seen.containsKey(icon.codePoint), isFalse,
            reason: 'duplicate codepoint ${icon.codePoint}');
        seen[icon.codePoint] = icon;
      }
      expect(seen.length, kKnownIcons.length);
    });

    test('an unknown or null codepoint degrades to the fallback', () {
      expect(iconFromCodePoint(null), kFallbackIcon);
      expect(iconFromCodePoint(0x0), kFallbackIcon);
      expect(iconFromCodePoint(999999), kFallbackIcon);
    });

    test('the habit icons that are actually serialised are all covered', () {
      // HabitDetailData.toJson writes icon.codePoint; these come from
      // habits_section.dart's _getIconData map. If one is missing here it
      // silently renders as the fallback on the detail screen.
      const serialised = <IconData>[
        Icons.check_circle,
        Icons.water_drop,
        Icons.eco,
        Icons.do_not_disturb,
        Icons.medication,
        Icons.directions_walk,
        Icons.self_improvement,
        Icons.directions_run,
        Icons.fitness_center,
        Icons.bedtime,
        Icons.spa,
        Icons.no_drinks,
        Icons.wb_sunny,
        Icons.menu_book,
        Icons.edit_note,
        Icons.phone_disabled,
        Icons.favorite,
        Icons.restaurant_menu,
        Icons.local_fire_department,
      ];
      for (final icon in serialised) {
        expect(kIconsByCodePoint.containsKey(icon.codePoint), isTrue,
            reason: 'habit icon ${icon.codePoint} missing from kKnownIcons');
      }
    });
  });
}
