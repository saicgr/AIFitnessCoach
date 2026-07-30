import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitwiz/core/providers/workout_ui_mode_provider.dart';
import 'package:fitwiz/data/models/user.dart' as app_user;
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/screens/workout/shared/tier_toggle_persistence.dart';

/// Stand-in notifier: applies the tier LOCALLY but never gets it to the server
/// (the reported #13b behaviour — PUT /users silently drops the field, so
/// `users.workout_ui_mode` stays NULL and setMode reports nothing).
class _DroppingNotifier extends WorkoutUiModeNotifier {
  _DroppingNotifier(super.ref);
  @override
  Future<void> setMode(WorkoutUiMode mode) async {
    state = state.copyWith(mode: mode, isUserExplicit: true);
  }
}

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('E2E #13b — a tier tap that never reaches the server is reported',
      (tester) async {
    // Auth carries a user whose workout_ui_mode is NULL — exactly what the
    // register found in production after an explicit tap.
    const user = app_user.User(id: 'u1', email: 'a@b.c');
    final container = ProviderContainer(overrides: [
      workoutUiModeProvider.overrideWith((ref) => _DroppingNotifier(ref)),
      authStateProvider.overrideWith(
        (ref) => _FakeAuth(const AuthState(
          status: AuthStatus.authenticated,
          user: user,
        )),
      ),
    ]);
    addTearDown(container.dispose);

    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Consumer(builder: (ctx, ref, _) {
          capturedRef = ref;
          capturedContext = ctx;
          return const Scaffold(body: SizedBox.shrink());
        }),
      ),
    ));
    await tester.pump();

    final ok = await applyExplicitTierChange(
        capturedContext, capturedRef, WorkoutUiMode.advanced);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // ignore: avoid_print
    print('confirmed=$ok  localMode='
        '${container.read(workoutUiModeProvider).mode.asString}');
    expect(ok, isFalse, reason: 'server did not confirm the tier');
    expect(find.textContaining('did not sync'), findsOneWidget);
    // The local preference is still honoured for this session.
    expect(container.read(workoutUiModeProvider).mode, WorkoutUiMode.advanced);
  });
}
