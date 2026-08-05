// Regression gate for defect 1: the equipment-profile pill in the Workouts
// masthead sub-line truncated a normal gym name ("Commercial Gym" →
// "Commer…") because it shared the row with a redundant "TODAY · AUG 5"
// label via two equal-flex `Flexible` widgets, each capped at ~50% of the
// row's width regardless of how short the gym name actually was. The date
// label was also redundant — the day strip immediately below the masthead
// already highlights today.
//
// Fix (workouts_screen.dart, `_buildFloatingHeader`): the date `Text` was
// deleted outright, and the equipment-profile pill is now the row's only
// child, free to use the full row width (still `Flexible` so an unusually
// long profile name can still shrink/ellipsise as a last resort).
//
// This suite pumps the REAL `WorkoutsScreen` (not a hand-built proxy of the
// masthead row) at an iPhone-16e-class width, so it exercises the actual
// parent-width constraint chain the bug lived in.

import 'dart:convert' show jsonEncode;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/user_provider.dart';
import 'package:fitwiz/data/models/gym_profile.dart';
import 'package:fitwiz/data/models/user.dart';
import 'package:fitwiz/data/providers/gym_profile_provider.dart';
import 'package:fitwiz/data/repositories/gym_profile_repository.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/workouts/workouts_screen.dart';

import '../../helpers/fake_supabase.dart';

/// A signed-in-shaped user with every weekday scheduled, so
/// `HeroWorkoutCarousel` takes its normal "here's the week" path instead of
/// the empty "no workout days" state — that empty state has a pre-existing
/// (unrelated to this fix, and out of this task's scope —
/// `hero_workout_carousel.dart` lives under `lib/screens/home/`) layout
/// overflow at this width that would otherwise fail every test in this file
/// before the masthead assertions even run.
final _fakeUser = User(
  id: 'user-1',
  preferences: jsonEncode({
    'workout_days': [0, 1, 2, 3, 4, 5, 6],
  }),
);

/// A [GymProfilesNotifier] subclass that skips the real constructor's
/// network/cache side effects (achieved by passing a null user id, exactly
/// like the base class does for a signed-out session) and then seeds a fixed
/// profile list directly — no repository call, no Supabase round trip.
class _FixedGymProfilesNotifier extends GymProfilesNotifier {
  _FixedGymProfilesNotifier(Ref ref, List<GymProfile> profiles)
      : super(ref.watch(gymProfileRepositoryProvider), null, ref) {
    state = AsyncValue.data(profiles);
  }
}

GymProfile _profile(String name) => GymProfile(
      id: 'gym-1',
      userId: 'user-1',
      name: name,
      isActive: true,
    );

Widget _app(String gymName, {ThemeData? theme}) {
  return ProviderScope(
    overrides: [
      gymProfilesProvider.overrideWith(
        (ref) => _FixedGymProfilesNotifier(ref, [_profile(gymName)]),
      ),
      currentUserProvider.overrideWithValue(AsyncValue.data(_fakeUser)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme ?? ThemeData.dark(),
      home: const WorkoutsScreen(),
    ),
  );
}

void main() {
  setUpAll(initFakeSupabase);

  group('WorkoutsScreen masthead — gym chip + date line', () {
    // The exact device class the truncation was reported on.
    const iPhone16e = Size(393, 852);

    // `setSurfaceSize` must run inside the test zone (a `testWidgets` body),
    // not `setUp` — calling it from `setUp` trips flutter_test's `inTest`
    // assertion. Each test calls this first and tears itself down.
    Future<void> setDeviceSize(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(iPhone16e);
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    testWidgets('renders a normal gym name in FULL, with no ellipsis',
        (tester) async {
      await setDeviceSize(tester);
      await tester.pumpWidget(_app('Commercial Gym'));
      // Bounded pumps (not pumpAndSettle) — several below-fold sections have
      // perpetual shimmer/loading animations in the signed-out test
      // environment that would never let pumpAndSettle finish.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      final finder = find.text('Commercial Gym');
      expect(finder, findsOneWidget,
          reason: 'the full gym name must appear verbatim in the tree — '
              'a truncated render would show as different text ("Commer…")'
              ' and this finder would find nothing');

      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(paragraph.didExceedMaxLines, isFalse,
          reason: 'a normal-length gym name ("Commercial Gym") must render '
              'without hitting its `maxLines: 1` + ellipsis clamp — if this '
              'is true, the name is being cut off exactly like the reported '
              'defect');
    });

    testWidgets(
        'the redundant "TODAY · <date>" label is gone from the masthead',
        (tester) async {
      await setDeviceSize(tester);
      await tester.pumpWidget(_app('Commercial Gym'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // The exact format the removed label used to render
      // ("TODAY  ·  AUG 5"): all-caps "TODAY" + a middle-dot + a 3-letter
      // month + day number. Matched narrowly so this doesn't collide with
      // any unrelated "Today" copy elsewhere on the screen (e.g. a workout
      // card's own "Today" badge, which is not all-caps and has no dot).
      final oldDateLabel = RegExp(r'^TODAY\s*·\s*[A-Z]{3}\s+\d{1,2}$');
      final matches = find.byWidgetPredicate((widget) {
        return widget is Text &&
            widget.data != null &&
            oldDateLabel.hasMatch(widget.data!);
      });
      expect(matches, findsNothing,
          reason: 'the masthead sub-line date label was removed as '
              'redundant with the day strip below it — if this finds a '
              'match, the old label (or an equivalent) came back');
    });

    testWidgets(
        'an unusually long gym name degrades gracefully (ellipsis, no '
        'layout overflow crash)', (tester) async {
      await setDeviceSize(tester);
      await tester.pumpWidget(_app('Planet Fitness Downtown Location'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // No RenderFlex/layout-overflow exception thrown during layout.
      expect(tester.takeException(), isNull);

      final finder = find.text('Planet Fitness Downtown Location');
      expect(finder, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(paragraph.didExceedMaxLines, isTrue,
          reason: 'an unusually long profile name is EXPECTED to hit the '
              'ellipsis clamp as a last resort — this is the graceful-'
              'degradation half of the fix, not a regression');
    });
  });
}
