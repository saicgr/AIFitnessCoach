// Gate for STEP 2 of the 2026-08 nav evolution: the You slot converts to
// Community, and profile moves behind the Community masthead avatar.
//
// The recorded decision (2026-06-11) was *"Future Social = stage 1 inside You;
// stage 2 (if earned) You→Community tab, profile behind header avatar"*. Social
// earned it. Four invariants, each of which silently breaks a real surface if
// it drifts:
//
//  1. THE BAR ORDER AND THE POSITIONAL BRANCH CONTRACT.
//     `MainShell` addresses branches by INDEX (`goBranch(index)`,
//     `_calculateSelectedIndex`). Converting the fifth branch must leave the
//     first four exactly where they were and must NOT add a sixth.
//
//  2. EVERY `/profile` DEEP LINK STILL LANDS. ~40 shipped call sites push or
//     go to `/profile`, most with a query (`?tab=profile`, `?tab=rewards`,
//     `?scrollTo=preferences`, `?tab=measurements&action=weigh_in`). The You
//     hub did not move branches — it moved behind the avatar — so all of them
//     must still resolve, still activate branch 4, and still route `?tab=` to
//     the same hub tab index.
//
//  3. `/social` STILL RESOLVES, WITH ITS QUERY INTACT. `/social` was the old
//     path (and, worse, was registered inside the NUTRITION branch, which
//     corrupted that branch's last-route memory the same way `/fasting` once
//     did). It is now a redirect. Dropping the query string would silently
//     land every challenge notification on the Feed tab instead of Challenges.
//
//  4. "SAVE AS ROUTINE" ACTUALLY CALLS THE SHIPPED ENDPOINT. The affordance is
//     a copy + surface change over `POST /saved-workouts/save-from-activity`,
//     which has been live all along behind "accept challenge" / "schedule it".
//     The one thing that would make it a lie is the button not calling
//     `saveWorkoutFromActivity`.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fitwiz/data/services/api_client.dart';
import 'package:fitwiz/data/services/saved_workouts_service.dart';
import 'package:fitwiz/l10n/generated/app_localizations.dart';
import 'package:fitwiz/screens/social/widgets/activity_card.dart';
// `socialToCommunityRedirect` is a part of this library.
import 'package:fitwiz/navigation/app_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

String _read(String relative) => File(relative).readAsStringSync();

/// The ROOT path of each `StatefulShellBranch`, in declaration order — i.e.
/// the bottom-bar order. Only the FIRST `path:` of a branch counts; later ones
/// are secondary routes inside that branch (`/profile` is branch 4's second).
List<String> _branchRootPaths(String source) {
  final shellStart = source.indexOf('StatefulShellRoute.indexedStack');
  expect(shellStart, greaterThan(-1));
  final shellEnd = source.indexOf('GoRoute(\n        path:', shellStart);
  expect(shellEnd, greaterThan(shellStart));
  final body = source.substring(shellStart, shellEnd);
  final pathRe = RegExp(r"path:\s*'([^']+)'");
  return body
      .split('StatefulShellBranch(')
      .skip(1)
      .map((segment) => pathRe.firstMatch(segment)?.group(1))
      .whereType<String>()
      .toList();
}

/// Every `path:` declared inside the LAST `StatefulShellBranch`, in order.
List<String> _communityBranchPaths(String source) {
  final shellStart = source.indexOf('StatefulShellRoute.indexedStack');
  final shellEnd = source.indexOf('GoRoute(\n        path:', shellStart);
  final body = source.substring(shellStart, shellEnd);
  final last = body.split('StatefulShellBranch(').last;
  return RegExp(r"path:\s*'([^']+)'")
      .allMatches(last)
      .map((m) => m.group(1)!)
      .toList();
}

/// A `SavedWorkoutsService` whose one network call is replaced by a recorder.
///
/// It EXTENDS the shipped service (rather than reimplementing the interface)
/// so the test is bound to the real signature: change
/// `saveWorkoutFromActivity`'s parameters and this stops compiling instead of
/// silently passing against a stale parallel type.
class _SpySavedWorkouts extends SavedWorkoutsService {
  _SpySavedWorkouts()
      : super(ApiClient(const FlutterSecureStorage()));

  final calls = <Map<String, String?>>[];
  Object? throwThis;

  @override
  Future<Map<String, dynamic>> saveWorkoutFromActivity({
    required String userId,
    required String activityId,
    String? folder,
    String? notes,
  }) async {
    calls.add({
      'userId': userId,
      'activityId': activityId,
      'folder': folder,
      'notes': notes,
    });
    if (throwThis != null) throw throwThis!;
    return {'id': 'saved-1'};
  }
}

Widget _wrapCard(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

ActivityCard _workoutPost({
  required SavedWorkoutsService service,
  String activityType = 'workout_completed',
  String currentUserId = 'me',
  String postUserId = 'them',
  Map<String, dynamic>? data,
}) =>
    ActivityCard(
      activityId: 'act-1',
      currentUserId: currentUserId,
      postUserId: postUserId,
      userName: 'Marcus R.',
      activityType: activityType,
      activityData: data ??
          const {
            'workout_name': 'Push Day',
            'duration_minutes': 52,
            'total_volume': 8240.0,
            'exercises_count': 6,
          },
      timestamp: DateTime(2026, 8, 9),
      reactionCount: 12,
      commentCount: 3,
      hasUserReacted: false,
      onReact: (_) {},
      onComment: () {},
      savedWorkoutsService: service,
    );

void main() {
  // ───────────────────────────────────────────────────────────────────────
  group('1 — the bar is Home · Workout · Health · Nutrition · Community', () {
    late String shellRoutes;

    setUpAll(() {
      shellRoutes = _read('lib/navigation/app_router_main_shell_routes.dart');
    });

    test('five branches, in order, with Community converted from You', () {
      expect(
        _branchRootPaths(shellRoutes),
        ['/home', '/workouts', '/health', '/nutrition', '/community'],
        reason: 'the slot CONVERTS — a sixth branch would both break Material '
            "3's five-slot cap and shift nothing, since MainShell addresses "
            'branches positionally',
      );
    });

    test('still exactly five branches — the slot was converted, not added', () {
      expect(_branchRootPaths(shellRoutes).length, 5);
    });

    test('MainShell maps /community AND /profile to index 4', () {
      final shell = _read('lib/widgets/main_shell.dart');
      expect(shell, contains("if (location.startsWith('/community')) return 4;"));
      expect(
        shell,
        contains("if (location.startsWith('/profile')) return 4;"),
        reason: 'the You hub did not change branches — it moved behind the '
            'Community masthead avatar — so a /profile location must still '
            'highlight the fifth tab',
      );
      expect(shell, contains("context.go('/community');"));
    });

    test('the nav bar renders navCommunity with a tour anchor', () {
      final navBar = _read('lib/widgets/main_shell_part_edge_panel_handle.dart');
      expect(navBar, contains('AppLocalizations.of(context).navCommunity'));
      expect(navBar, contains('AppTourKeys.communityNavKey'));
      expect(navBar, isNot(contains('AppLocalizations.of(context).navYou')));
    });

    test('communityNavKey and profileNavKey are the SAME anchor', () {
      // A GlobalKey may be mounted once. The fifth slot is one widget, and
      // home_screen.dart's shipped `nav_step_profile` tour step still resolves
      // through `profileNavKey` — so the Step-2 name must alias it, never
      // introduce a second (permanently unmounted) anchor.
      final tour = _read('lib/widgets/app_tour/app_tour_controller.dart');
      expect(tour, contains('communityNavKey => TooltipAnchors.profileNav'));
      expect(tour, contains('profileNavKey => TooltipAnchors.profileNav'));
    });

    test('_warmActiveTab case 4 warms the Community feed', () {
      final shell = _read('lib/widgets/main_shell.dart');
      final start = shell.indexOf('case 4: // Community');
      expect(start, greaterThan(-1),
          reason: 'no Community case in _warmActiveTab');
      final case4 = shell.substring(start, shell.indexOf('}', start));
      expect(case4, contains('activityFeedProvider'),
          reason: 'the Feed chip is the tab landing view — it is the real '
              'first-paint dependency');
      // Profile is one tap away behind this tab's avatar and lives in the same
      // branch, so its first-paint providers stay warmed here too.
      expect(case4, contains('xpProvider'));
    });

    test('navCommunity ships in all 36 .arb files, non-empty', () {
      final arbs = Directory('lib/l10n')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList();
      expect(arbs.length, 36);
      const keys = [
        'navCommunity',
        'communitySaveAsRoutine',
        'communityRoutineSaved',
        'communityRoutineSaveFailed',
        'communityYourProfile',
      ];
      for (final f in arbs) {
        final map = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final key in keys) {
          expect(map[key], isA<String>(), reason: '${f.path} is missing "$key"');
          expect((map[key] as String).trim(), isNotEmpty,
              reason: '${f.path} has an empty "$key"');
        }
      }
    });

    test('the generated localisations expose navCommunity', () {
      final gen = _read('lib/l10n/generated/app_localizations.dart');
      expect(gen, contains('String get navCommunity;'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('2 — profile lives behind the avatar, in the SAME branch', () {
    late String shellRoutes;

    setUpAll(() {
      shellRoutes = _read('lib/navigation/app_router_main_shell_routes.dart');
    });

    test('branch 4 declares /community FIRST, then /profile', () {
      expect(
        _communityBranchPaths(shellRoutes),
        ['/community', '/profile'],
        reason: "go_router treats a branch's FIRST route as its default "
            'location, so /community must lead — otherwise tapping the '
            'Community tab from another tab would land on the profile hub',
      );
    });

    test('/profile is NOT re-registered as a top-level route', () {
      // A second registration would shadow the branch one and open the hub
      // with no nav bar.
      final shellStart =
          shellRoutes.indexOf('StatefulShellRoute.indexedStack');
      final shellEnd =
          shellRoutes.indexOf('GoRoute(\n        path:', shellStart);
      final afterShell = shellRoutes.substring(shellEnd);
      expect(afterShell, isNot(contains("path: '/profile',")));
    });

    test('the ?tab= mapping the deep links depend on is unchanged', () {
      expect(shellRoutes, contains("if (tabParam == 'profile') {"));
      expect(shellRoutes, contains("initialTab = 1;"));
      expect(shellRoutes, contains("} else if (tabParam == 'rewards') {"));
      expect(shellRoutes, contains("initialTab = 2;"));
      expect(shellRoutes, contains("state.uri.queryParameters['scrollTo']"));
    });

    test('the Community masthead avatar pushes /profile', () {
      final social = _read('lib/screens/social/social_screen.dart');
      expect(social, contains("context.push('/profile')"));
      expect(social, contains('communityYourProfile'),
          reason: 'the avatar must carry a semantics label — it is an '
              'icon-only control and the only route to the profile hub');
      // E2E finding #436: the AppBar `title:` ("COMMUNITY") was removed, not
      // relocalized — with the avatar (~45pt), the username chip, and three
      // icon buttons already competing for a 402pt-wide bar, a redundant
      // title was what truncated to "CO…" in the first place. The DONE note
      // on #436 confirms this is the shipped fix ("verified: one accent, no
      // AppBar title present"), and the tab's name is still available from
      // the bottom nav bar label, so `AppBar.title` must stay unset here.
      expect(social, isNot(contains('l10n.navCommunity.toUpperCase()')));
      final shellStart = social.indexOf('return Scaffold(');
      final appBarStart = social.indexOf('appBar: AppBar(', shellStart);
      expect(appBarStart, greaterThan(-1));
      final appBarEnd = social.indexOf('body: Column(', appBarStart);
      final appBarBody = social.substring(appBarStart, appBarEnd);
      expect(appBarBody, isNot(contains('title:')),
          reason: 'no widget should reintroduce a masthead title Text — the '
              'nav bar already labels this tab, and a second label is the '
              'truncation bug #436 fixed by removing');
    });

    // ── The behavioural half. Group 2's other tests are source scans; this
    // builds a REAL GoRouter with the same structural shape (five branches,
    // branch 4 holding /community then /profile, plus the /social redirect)
    // and drives real go_router navigation through it.
    GoRouter buildRouter({String initialLocation = '/home'}) {
      String? capturedTab;
      String? capturedScrollTo;
      return GoRouter(
        initialLocation: initialLocation,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => shell,
            branches: [
              for (final p in ['/home', '/workouts', '/health', '/nutrition'])
                StatefulShellBranch(routes: [
                  GoRoute(
                    path: p,
                    builder: (c, s) =>
                        Scaffold(body: Center(child: Text('ROOT $p'))),
                  ),
                ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: '/community',
                  builder: (c, s) => const Scaffold(
                      body: Center(child: Text('COMMUNITY ROOT'))),
                ),
                GoRoute(
                  path: '/profile',
                  builder: (c, s) {
                    capturedTab = s.uri.queryParameters['tab'];
                    capturedScrollTo = s.uri.queryParameters['scrollTo'];
                    return Scaffold(
                      body: Center(
                        child: Text(
                          'PROFILE HUB tab=$capturedTab '
                          'scrollTo=$capturedScrollTo',
                        ),
                      ),
                    );
                  },
                ),
              ]),
            ],
          ),
          GoRoute(
            path: '/social',
            redirect: (context, state) {
              final q = state.uri.query;
              return q.isEmpty ? '/community' : '/community?$q';
            },
          ),
        ],
      );
    }

    testWidgets('every shipped /profile deep-link shape still lands',
        (tester) async {
      // Exactly the query shapes in the codebase today.
      const links = [
        ('/profile', 'tab=null scrollTo=null'),
        ('/profile?tab=profile', 'tab=profile scrollTo=null'),
        ('/profile?tab=rewards', 'tab=rewards scrollTo=null'),
        ('/profile?tab=overview', 'tab=overview scrollTo=null'),
        ('/profile?scrollTo=preferences', 'tab=null scrollTo=preferences'),
        ('/profile?tab=measurements&action=weigh_in',
            'tab=measurements scrollTo=null'),
        ('/profile?tab=stats&source=weekly_digest', 'tab=stats scrollTo=null'),
      ];
      for (final (link, expected) in links) {
        final router = buildRouter();
        addTearDown(router.dispose);
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        router.go(link);
        await tester.pumpAndSettle();

        expect(find.text('PROFILE HUB $expected'), findsOneWidget,
            reason: '$link must still land on the profile hub with its query '
                'intact');
      }
    });

    testWidgets('pushing /profile from Community pops back to Community',
        (tester) async {
      final router = buildRouter(initialLocation: '/community');
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('COMMUNITY ROOT'), findsOneWidget);

      // What the masthead avatar does.
      router.push('/profile');
      await tester.pumpAndSettle();
      expect(find.text('PROFILE HUB tab=null scrollTo=null'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('COMMUNITY ROOT'), findsOneWidget,
          reason: 'profile is behind the avatar, so back must return to the '
              'tab the user was standing on');
    });

    test('/social redirects to /community, PRESERVING the query string', () {
      // Asserts the PRODUCTION function, not a copy of it. The previous
      // version of this test re-implemented the redirect inside the test
      // file, so breaking `socialToCommunityRedirect` left it green.
      expect(socialToCommunityRedirect(Uri.parse('/social')), '/community');
      expect(
        socialToCommunityRedirect(Uri.parse('/social?tab=challenges')),
        '/community?tab=challenges',
        reason: 'challenge notifications deep-link with ?tab=challenges; '
            'dropping the query lands every one of them on the Feed',
      );
      expect(
        socialToCommunityRedirect(Uri.parse('/social?tab=friends&x=1')),
        '/community?tab=friends&x=1',
      );
    });

    test('/social is a redirect and no longer sits in the Nutrition branch',
        () {
      final nutritionBranchPaths = () {
        final shellStart =
            shellRoutes.indexOf('StatefulShellRoute.indexedStack');
        final shellEnd =
            shellRoutes.indexOf('GoRoute(\n        path:', shellStart);
        final body = shellRoutes.substring(shellStart, shellEnd);
        // Branch 3 = Nutrition (segments are 1-indexed after the split).
        final segment = body.split('StatefulShellBranch(')[4];
        return RegExp(r"path:\s*'([^']+)'")
            .allMatches(segment)
            .map((m) => m.group(1)!)
            .toList();
      }();
      expect(nutritionBranchPaths, ['/nutrition'],
          reason: '/social inside the Nutrition branch made that branch '
              'remember Social as its "current" page — the same tap-twice bug '
              '/fasting caused');
      expect(
        // Tolerates comment lines between the path and the redirect — the
        // original `\s*\n\s*` form broke the moment one was added, which is
        // a brittleness worth not re-introducing.
        RegExp(r"path: '/social',(?:[^)]*?)redirect:").hasMatch(shellRoutes),
        isTrue,
        reason: '~15 shipped call sites still use /social, so the path must '
            'stay registered as a redirect rather than being deleted',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('3 — the feed post carries the Hevy anatomy', () {
    testWidgets('duration · volume render as a stat row from REAL fields',
        (tester) async {
      await tester.pumpWidget(_wrapCard(
        _workoutPost(service: _SpySavedWorkouts()),
      ));
      await tester.pump();

      expect(find.text('52m'), findsOneWidget);
      expect(find.text('8,240'), findsOneWidget);
      expect(find.text('DURATION'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
    });

    testWidgets('the PR cell only appears when the payload actually has one',
        (tester) async {
      // No producer emits `pr_count` today, so the honest behaviour is an
      // ABSENT cell — never a fabricated "0 PRs".
      await tester.pumpWidget(_wrapCard(
        _workoutPost(service: _SpySavedWorkouts()),
      ));
      await tester.pump();
      expect(find.text('PRS'), findsNothing);

      await tester.pumpWidget(_wrapCard(
        _workoutPost(service: _SpySavedWorkouts(), data: const {
          'workout_name': 'Push Day',
          'duration_minutes': 52,
          'total_volume_lbs': 8240,
          'pr_count': 2,
        }),
      ));
      await tester.pump();
      expect(find.text('PRS'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('both volume field names are read', (tester) async {
      // `autoPostWorkoutCompletion` writes `total_volume`; `create_post_sheet`
      // writes `total_volume_lbs`. A post from either producer must render.
      for (final key in ['total_volume', 'total_volume_lbs']) {
        await tester.pumpWidget(_wrapCard(
          _workoutPost(service: _SpySavedWorkouts(), data: {
            'workout_name': 'Push Day',
            'duration_minutes': 40,
            key: 11100,
          }),
        ));
        await tester.pump();
        expect(find.text('11,100'), findsOneWidget, reason: 'key: $key');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('4 — "Save as Routine" calls the shipped endpoint', () {
    testWidgets('tapping it calls saveWorkoutFromActivity with the post ids',
        (tester) async {
      final spy = _SpySavedWorkouts();
      await tester.pumpWidget(_wrapCard(_workoutPost(service: spy)));
      await tester.pump();

      final button = find.text('SAVE AS ROUTINE');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();
      await tester.pump();

      expect(spy.calls, hasLength(1));
      expect(spy.calls.single['userId'], 'me');
      expect(spy.calls.single['activityId'], 'act-1');
    });

    testWidgets('a second tap cannot double-save', (tester) async {
      final spy = _SpySavedWorkouts();
      await tester.pumpWidget(_wrapCard(_workoutPost(service: spy)));
      await tester.pump();

      await tester.tap(find.text('SAVE AS ROUTINE'));
      await tester.pump();
      await tester.pump();
      // Now in the saved state — the label changed, and the control is inert.
      expect(find.text('SAVED TO YOUR ROUTINES'), findsOneWidget);
      await tester.tap(find.text('SAVED TO YOUR ROUTINES'));
      await tester.pump();
      await tester.pump();

      expect(spy.calls, hasLength(1),
          reason: 'the saved state must be terminal — a second call would '
              'create a duplicate routine in the library');
    });

    testWidgets('a failure leaves the control tappable and does NOT claim saved',
        (tester) async {
      final spy = _SpySavedWorkouts()..throwThis = Exception('boom');
      await tester.pumpWidget(_wrapCard(_workoutPost(service: spy)));
      await tester.pump();

      await tester.tap(find.text('SAVE AS ROUTINE'));
      await tester.pump();
      await tester.pump();

      expect(find.text('SAVE AS ROUTINE'), findsOneWidget,
          reason: 'the routine was NOT saved, so the control must not say it '
              'was');
      expect(find.text('SAVED TO YOUR ROUTINES'), findsNothing);

      // And it is still usable — a retry reaches the service again.
      spy.throwThis = null;
      await tester.tap(find.text('SAVE AS ROUTINE'));
      await tester.pump();
      await tester.pump();
      expect(spy.calls, hasLength(2));
    });

    testWidgets('it is absent on your OWN post', (tester) async {
      await tester.pumpWidget(_wrapCard(_workoutPost(
        service: _SpySavedWorkouts(),
        currentUserId: 'me',
        postUserId: 'me',
      )));
      await tester.pump();
      expect(find.text('SAVE AS ROUTINE'), findsNothing,
          reason: 'the workout is already in the author\'s own library');
    });

    testWidgets('it is absent on a non-workout post', (tester) async {
      // `save-from-activity` reads the activity's workout payload server-side;
      // offering it on an achievement would be an action with nothing to copy.
      await tester.pumpWidget(_wrapCard(_workoutPost(
        service: _SpySavedWorkouts(),
        activityType: 'achievement_earned',
        data: const {
          'achievement_name': 'First 5K',
          'achievement_icon': '🏆',
        },
      )));
      await tester.pump();
      expect(find.text('SAVE AS ROUTINE'), findsNothing);
    });
  });
}
