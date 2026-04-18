/// Static holder for a pending daily-crate auto-claim request.
///
/// Flow:
///   1. User taps a `daily_crate` push notification.
///   2. Notification handler sets [pending] = true.
///   3. App navigates to /home.
///   4. StackedBannerPanel reads [pending] on build, triggers the auto-claim
///      flow (same path as tapping the banner's "Open" button), then calls
///      [consume] to reset the flag so it fires only once per tap.
class CrateNotificationRouter {
  CrateNotificationRouter._();

  static bool pending = false;

  static bool consume() {
    if (!pending) return false;
    pending = false;
    return true;
  }
}
