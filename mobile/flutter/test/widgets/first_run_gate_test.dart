import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitwiz/data/models/user.dart' as app_user;
import 'package:fitwiz/widgets/first_run/first_run_gate.dart';

app_user.User _user({String? createdAt, bool? isNewUser}) => app_user.User(
  id: 'u1',
  email: 'a@b.com',
  createdAt: createdAt,
  isNewUser: isNewUser,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirstRunGate.isFreshAccount', () {
    test('true for an account created minutes ago', () {
      final now = DateTime.now().toUtc();
      expect(
        FirstRunGate.isFreshAccount(
          _user(
            createdAt: now
                .subtract(const Duration(minutes: 3))
                .toIso8601String(),
          ),
        ),
        isTrue,
      );
    });

    test('false for an account created days ago', () {
      final old = DateTime.now().toUtc().subtract(const Duration(days: 5));
      expect(
        FirstRunGate.isFreshAccount(_user(createdAt: old.toIso8601String())),
        isFalse,
      );
    });

    test('falls back to isNewUser when createdAt missing', () {
      expect(FirstRunGate.isFreshAccount(_user(isNewUser: true)), isTrue);
      expect(FirstRunGate.isFreshAccount(_user(isNewUser: false)), isFalse);
      expect(FirstRunGate.isFreshAccount(null), isFalse);
    });
  });

  test(
    'markVersionAnnouncementsSeenForFreshUser sets the seen flags',
    () async {
      SharedPreferences.setMockInitialValues({});
      await FirstRunGate.markVersionAnnouncementsSeenForFreshUser();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('score_change_v2_seen'), isTrue);
      expect(prefs.getBool('whats_new_seen_gravl_v1'), isTrue);
    },
  );

  group('FirstRunModalQueue', () {
    test('runs queued modals strictly one at a time (no overlap)', () async {
      final order = <String>[];
      var active = 0;
      var maxConcurrent = 0;

      Future<void> fakeModal(String id, Duration shown) async {
        active++;
        maxConcurrent = active > maxConcurrent ? active : maxConcurrent;
        order.add('open:$id');
        await Future<void>.delayed(shown); // modal visible until dismissed
        order.add('close:$id');
        active--;
      }

      final f1 = FirstRunModalQueue.enqueue(
        () => fakeModal('A', const Duration(milliseconds: 60)),
      );
      final f2 = FirstRunModalQueue.enqueue(
        () => fakeModal('B', const Duration(milliseconds: 30)),
      );
      final f3 = FirstRunModalQueue.enqueue(
        () => fakeModal('C', const Duration(milliseconds: 10)),
      );
      await Future.wait([f1, f2, f3]);

      // Never more than one modal visible at once.
      expect(maxConcurrent, 1);
      // Strict open→close→open ordering, in enqueue order.
      expect(order, [
        'open:A',
        'close:A',
        'open:B',
        'close:B',
        'open:C',
        'close:C',
      ]);
      expect(FirstRunModalQueue.isBusy, isFalse);
    });

    test('a thrown modal does not wedge the queue', () async {
      final ran = <String>[];
      final f1 = FirstRunModalQueue.enqueue(() async {
        throw StateError('boom');
      });
      final f2 = FirstRunModalQueue.enqueue(() async {
        ran.add('B');
      });
      await Future.wait([f1, f2]);
      expect(ran, ['B']);
      expect(FirstRunModalQueue.isBusy, isFalse);
    });
  });
}
