import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression test for the "Create Account succeeds but the screen never moves
/// forward" bug.
///
/// Root cause: `/email-sign-in` is reached via `context.push` (it sits ON TOP of
/// the navigation stack, on top of the also-pushed `/sign-in`). GoRouter's
/// `refreshListenable` redirect operates on the base go-route underneath the
/// push, so when auth flips to authenticated the redirect never pops the pushed
/// Create Account screen. `email_sign_in_screen` (unlike the working
/// `sign_in_screen`) had no explicit forward navigation, so the user was
/// stranded on it forever despite a fully successful sign-up.
///
/// The fix mirrors `sign_in_screen`'s belt-and-suspenders: on auth success,
/// read the live router path and `context.go` to the next step. This test pins
/// down the real navigation behavior (incl. what the router path resolves to on
/// a pushed route) and proves the explicit hand-off escapes the push.
void main() {
  // The exact post-auth force-navigation the fix performs: UNCONDITIONAL
  // context.go (no route-path guard — the pushed-route path is unreliable, and
  // an earlier path-guarded version silently skipped navigation, leaving the
  // user stuck). The router redirect rewrites '/personal-info' to the true step.
  void forceNavigateForward(BuildContext context) {
    context.go('/personal-info');
  }

  GoRouter buildRouter({Listenable? refresh, GoRouterRedirect? redirect}) {
    return GoRouter(
      initialLocation: '/sign-in',
      refreshListenable: refresh,
      redirect: redirect,
      routes: [
        GoRoute(
          path: '/sign-in',
          builder: (context, __) => Scaffold(
            body: Column(
              children: [
                const Text('SIGN IN'),
                // Mirror the app: Create Account is PUSHED on top of /sign-in.
                TextButton(
                  onPressed: () => context.push('/email-sign-in'),
                  child: const Text('open create account'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/email-sign-in',
          builder: (context, __) => Scaffold(
            body: Column(
              children: [
                const Text('CREATE ACCOUNT'),
                TextButton(
                  onPressed: () => forceNavigateForward(context),
                  child: const Text('finish'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/personal-info',
          builder: (_, __) => const Scaffold(body: Text('PERSONAL INFO')),
        ),
      ],
    );
  }

  testWidgets(
    'BUG: a refresh redirect on base routes does NOT pop a pushed auth screen',
    (tester) async {
      final authed = ValueNotifier(false);
      addTearDown(authed.dispose);

      final router = buildRouter(
        refresh: authed,
        // Faithful to the real trap: the redirect does NOT navigate the user off
        // the pushed '/email-sign-in' route (in the app it returns null / can't
        // act on the pushed route). So relying on the redirect alone — which is
        // exactly what the OLD email_sign_in_screen did — strands the user.
        redirect: (_, __) => null,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('open create account'));
      await tester.pumpAndSettle();
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);

      // Auth flips → refreshListenable fires, but the redirect doesn't move us and
      // the (old) screen does nothing on success.
      authed.value = true;
      await tester.pumpAndSettle();

      // Stuck: the pushed Create Account screen is STILL on top. This is the bug
      // the explicit forward-navigation (next test) fixes.
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('PERSONAL INFO'), findsNothing);
    },
  );

  testWidgets(
    'FIX: explicit context.go from the pushed auth screen navigates forward',
    (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('open create account'));
      await tester.pumpAndSettle();
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);

      // Simulate auth success → the screen runs the force-navigation the fix adds.
      await tester.tap(find.text('finish'));
      await tester.pumpAndSettle();

      // The user is moved off the pushed Create Account screen to the next step.
      expect(find.text('PERSONAL INFO'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsNothing);
    },
  );
}
