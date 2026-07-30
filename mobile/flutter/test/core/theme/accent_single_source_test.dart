// Accent single-source regression test (E2E register row 15).
//
// The app used to decide "the accent" in several places at once — the gym
// profile override (async, so the same screen was orange on one launch and
// cyan on the next), `ColorScheme.secondary` pinned to purple, and
// `ThemeColors.cyan/orange/purple` silently returning monochrome white. This
// test asserts that every reader a widget could plausibly reach resolves to
// ONE colour. Companion static gate:
// `lib/core/theme/accent_source_gate.dart --check`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitwiz/core/theme/accent_color_provider.dart';
import 'package:fitwiz/core/theme/theme_colors.dart';
import 'package:fitwiz/core/theme/app_theme.dart';
import 'package:fitwiz/core/theme/seeded_scheme.dart';

void main() {
  testWidgets('every accent reader returns the SAME colour', (tester) async {
    late Color viaScope, viaThemeColors, viaLegacyCyan, viaLegacyPurple,
        viaSchemePrimary, viaSchemeSecondary, viaContextExt;

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final accent = container.read(accentColorProvider); // default = orange
    final primary = container.read(appPrimaryColorProvider(true));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: AccentColorScope(
          accent: accent,
          child: MaterialApp(
            theme: AppTheme.buildDarkTheme(primary),
            home: Builder(builder: (ctx) {
              final tc = ThemeColors.of(ctx);
              viaScope = AccentColorScope.colorOf(ctx);
              viaContextExt = ctx.accentColor;
              viaThemeColors = tc.accent;
              viaLegacyCyan = tc.cyan;
              viaLegacyPurple = tc.purple;
              viaSchemePrimary = Theme.of(ctx).colorScheme.primary;
              viaSchemeSecondary = Theme.of(ctx).colorScheme.secondary;
              return const SizedBox();
            }),
          ),
        ),
      ),
    );

    expect(viaScope, primary);
    expect(viaContextExt, primary);
    expect(viaThemeColors, primary);
    expect(viaLegacyCyan, primary, reason: 'colors.cyan must be the accent');
    expect(viaLegacyPurple, primary, reason: 'colors.purple must be the accent');
    expect(viaSchemePrimary, primary);
    // secondary is no longer a fixed purple: it is seeded from the accent, so
    // its hue must track the accent hue rather than sit at Material's 270deg.
    final accentHue = HSLColor.fromColor(primary).hue;
    final secHue = HSLColor.fromColor(viaSchemeSecondary).hue;
    expect((secHue - accentHue).abs() < 45, isTrue,
        reason: 'secondary hue $secHue must track accent hue $accentHue');
  });

  test('ResolvedAccent exposes no override channel', () {
    const r = ResolvedAccent(accent: AccentColor.orange);
    expect(r.getColor(true), AccentColor.orange.getColor(true));
  });

  // The seeded ColorScheme is memoised (seeded_scheme.dart) because
  // ColorScheme.fromSeed costs ~287us vs ~0.4us for the const scheme it
  // replaced, and app.dart builds BOTH themes on every root rebuild. The cache
  // must be value-identical to fromSeed and must not collide across seeds or
  // brightnesses — a collision would repaint the app in the wrong accent, i.e.
  // reintroduce exactly the bug row 15 is about.
  test('seededScheme matches fromSeed and never collides', () {
    const orange = Color(0xFFF97316);
    const cyan = Color(0xFF06B6D4);
    final direct = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.dark,
    );
    final memoDark = seededScheme(orange, Brightness.dark);
    expect(memoDark.secondary, direct.secondary);
    expect(memoDark.tertiary, direct.tertiary);
    expect(memoDark.surfaceContainerHigh, direct.surfaceContainerHigh);

    // Repeat read is the cached instance, not a recomputation with drift.
    expect(identical(seededScheme(orange, Brightness.dark), memoDark), isTrue);

    // Same seed, other brightness → different scheme.
    final memoLight = seededScheme(orange, Brightness.light);
    expect(memoLight.brightness, Brightness.light);
    expect(memoDark.brightness, Brightness.dark);

    // Other seed, same brightness → different scheme.
    final other = seededScheme(cyan, Brightness.dark);
    expect(other.primary, isNot(memoDark.primary));
  });
}
