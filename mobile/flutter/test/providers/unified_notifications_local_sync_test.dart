/// Regression: the notification bell showed NOTHING while the home banner
/// stack was showing six cards (reported 2026-08).
///
/// `StackedBannerPanel` records every banner it renders into the local feed
/// (`notificationsProvider`) via `BannerNotificationMapper`, and push messages
/// land there too (`addFromPushMessage`). But the bell reads
/// `unifiedUnreadCountProvider` → `unifiedNotificationsProvider`, which only
/// ever read the local feed ONCE, in its constructor:
///
///   * that read happens before `NotificationsNotifier._loadNotifications()`
///     (a SharedPreferences round-trip) has resolved, so on a cold start it
///     saw an EMPTY list, and
///   * nothing re-read it afterwards, so every banner/push added at runtime
///     was invisible to the bell until an unrelated `_loadAll()` fired.
///
/// The fix is a `ref.listen` on `notificationsProvider` that re-merges the
/// local feed into the unified state, preserving network-sourced entries.
///
/// Wiring the two providers together was necessary but NOT sufficient — the
/// local feed's own write path had two defects that made the bell go quiet
/// again the next day (also reported), both covered below:
///
///   * `addNotification` deduped on id alone, while recurring banners
///     (`streak_at_risk`, `daily_crate`, `renewal`, `calibration`, …) carry a
///     STABLE id — that id doubles as their dismiss key. So the first day's
///     entry got read and every later day's genuinely-new banner was silently
///     swallowed. Dedupe is now scoped to the local DAY.
///   * `_loadNotifications` ASSIGNED the persisted list over `state`, racing
///     the post-frame callback that records banners on the first frame.
///     Whichever finished last won. It now merges, and writes await hydration
///     so a first-frame write can't truncate the stored history.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitwiz/core/providers/auth_provider.dart';
import 'package:fitwiz/data/providers/unified_notifications_provider.dart';
import 'package:fitwiz/data/repositories/auth_repository.dart';
import 'package:fitwiz/screens/notifications/notifications_screen.dart';

/// Stubs out the real `authStateProvider`, which would otherwise reach for
/// `Supabase.instance` (uninitialised in a unit test) via the API client.
class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier()
      : super(_FakeAuthRepository(), _NoopRef()) {
    // ignore: invalid_use_of_protected_member
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

class _FakeAuthRepository extends Mock implements AuthRepository {}

class _NoopRef extends Mock implements Ref {}

List<Override> _overrides() => [
      authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
      // Anonymous → `_loadAll()` short-circuits before any network call, so
      // the test exercises the local-feed path in isolation.
      currentUserIdProvider.overrideWithValue(null),
    ];

NotificationItem _item(String id, {bool isRead = false, DateTime? at}) =>
    NotificationItem(
      id: id,
      title: 'Title $id',
      body: 'Body $id',
      type: 'contextual',
      timestamp: at ?? DateTime.now(),
      isRead: isRead,
    );

/// A persisted feed entry, serialised the way the notifier stores it.
String _persisted(String id, {required DateTime at, bool isRead = false}) =>
    '{"id":"$id","title":"T $id","body":"B $id","type":"contextual",'
    '"timestamp":"${at.toIso8601String()}","isRead":$isRead}';

/// Pumps microtasks until [test] passes or [tries] is exhausted.
Future<void> _settle(
  ProviderContainer c, {
  required bool Function() test,
  int tries = 40,
}) async {
  for (var i = 0; i < tries; i++) {
    if (test()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() {
    SharedPreferences.setMockInitialValues({});
    final c = ProviderContainer(overrides: _overrides());
    addTearDown(c.dispose);
    return c;
  }

  group('unified notifications track the local feed', () {
    test('a banner added after construction reaches the bell', () async {
      final c = makeContainer();

      // Mount the bell's count provider first — this is the real ordering:
      // the header builds, THEN the banner panel registers its banners.
      expect(c.read(unifiedUnreadCountProvider), 0);

      c.read(notificationsProvider.notifier).addNotification(_item('banner_a'));
      c.read(notificationsProvider.notifier).addNotification(_item('banner_b'));

      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 2);

      expect(c.read(unifiedUnreadCountProvider), 2,
          reason: 'banners recorded after the unified provider was built must '
              'still raise the bell badge');
      final ids = c
          .read(unifiedNotificationsProvider)
          .value!
          .map((n) => n.id)
          .toList();
      expect(ids, containsAll(<String>['banner_a', 'banner_b']));
    });

    test('a feed hydrated from disk AFTER construction reaches the bell',
        () async {
      // The cold-start case: SharedPreferences already holds notifications,
      // but `NotificationsNotifier` loads them asynchronously — the old
      // constructor-only read saw an empty list and never looked again.
      SharedPreferences.setMockInitialValues({
        'app_notifications':
            '[${_jsonOf('persisted_1')},${_jsonOf('persisted_2')}]',
      });
      final c = ProviderContainer(overrides: _overrides());
      addTearDown(c.dispose);

      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 2);

      expect(c.read(unifiedUnreadCountProvider), 2,
          reason: 'the disk-hydrated local feed must reach the unified feed');
    });

    test('read state propagates — marking all read clears the badge', () async {
      final c = makeContainer();
      c.read(notificationsProvider.notifier).addNotification(_item('banner_a'));
      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 1);

      c.read(notificationsProvider.notifier).markAllAsRead();
      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 0);

      expect(c.read(unifiedUnreadCountProvider), 0);
      expect(c.read(unifiedNotificationsProvider).value!.length, 1,
          reason: 'read notifications stay in the list, they just stop '
              'counting toward the badge');
    });

    test('a RECURRING banner read yesterday re-raises the bell today',
        () async {
      // `streak_at_risk` is the reported case: the banner shows every evening
      // it applies, but its id never changes, so once yesterday's entry was
      // read the bell stayed silent for good.
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      SharedPreferences.setMockInitialValues({
        'app_notifications':
            '[${_persisted('banner_streak_at_risk', at: yesterday, isRead: true)}]',
      });
      final c = ProviderContainer(overrides: _overrides());
      addTearDown(c.dispose);

      // Yesterday's entry hydrates, already read → no badge.
      await _settle(c, test: () => c.read(unifiedNotificationsProvider).value?.length == 1);
      expect(c.read(unifiedUnreadCountProvider), 0);

      // Tonight the banner shows again — same stable id, new occurrence.
      c.read(notificationsProvider.notifier)
          .addNotification(_item('banner_streak_at_risk'));

      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 1);
      expect(c.read(unifiedUnreadCountProvider), 1,
          reason: 'a new day\'s streak banner must raise the bell again');
      expect(c.read(notificationsProvider).length, 1,
          reason: 're-raised IN PLACE — one row per recurring banner, not one '
              'row per day');
    });

    test('the SAME day stays deduped — home rebuilds must not spam the bell',
        () async {
      final c = makeContainer();
      final notifier = c.read(notificationsProvider.notifier);
      final now = DateTime.now();

      // Home rebuilds many times a session; the panel re-records on each one.
      for (var i = 0; i < 5; i++) {
        notifier.addNotification(_item('banner_daily_crate', at: now));
      }
      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 1);
      expect(c.read(notificationsProvider).length, 1);

      // And once read today, re-recording today must NOT resurrect it.
      notifier.markAsRead('banner_daily_crate');
      notifier.addNotification(_item('banner_daily_crate', at: now));
      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 0);
      expect(c.read(unifiedUnreadCountProvider), 0);
    });

    test('a first-frame write neither loses the banner nor wipes history',
        () async {
      // The panel records banners from a post-frame callback on frame 1 —
      // while `_loadNotifications()` is still awaiting SharedPreferences.
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      SharedPreferences.setMockInitialValues({
        'app_notifications':
            '[${_persisted('banner_old', at: lastWeek, isRead: true)}]',
      });
      final c = ProviderContainer(overrides: _overrides());
      addTearDown(c.dispose);

      // No settle: write immediately, mid-hydration.
      c.read(notificationsProvider.notifier).addNotification(_item('banner_new'));

      await _settle(c, test: () => c.read(notificationsProvider).length == 2);

      final ids = c.read(notificationsProvider).map((n) => n.id).toList();
      expect(ids, containsAll(<String>['banner_new', 'banner_old']),
          reason: 'the in-flight write and the persisted history must BOTH '
              'survive — assignment-over-state dropped one or the other '
              'depending on which future resolved last');
      expect(c.read(unifiedUnreadCountProvider), 1);

      // History must also still be on disk, not truncated by the early write.
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_notifications')!;
      expect(stored, contains('banner_old'));
      expect(stored, contains('banner_new'));
    });

    test('deleting from the local feed removes it from the unified feed',
        () async {
      final c = makeContainer();
      c.read(notificationsProvider.notifier).addNotification(_item('banner_a'));
      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 1);

      c.read(notificationsProvider.notifier).deleteNotification('banner_a');
      await _settle(c, test: () => c.read(unifiedUnreadCountProvider) == 0);

      expect(c.read(unifiedNotificationsProvider).value, isEmpty);
    });
  });
}

String _jsonOf(String id) => '{"id":"$id","title":"T $id","body":"B $id",'
    '"type":"contextual","timestamp":"2026-08-08T12:00:00.000",'
    '"isRead":false}';
