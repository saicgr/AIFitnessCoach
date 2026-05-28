import '../../screens/home/widgets/banner_card_data.dart';
import '../../screens/notifications/notifications_screen.dart';

/// Maps home-screen banners to notification-bell items.
///
/// The notification bell is the universal inbox (Phase C3): EVERY banner the
/// user sees is recorded there — the moment it appears, not only on dismissal
/// — so nothing shown to the user is missing from the bell. This mapper
/// therefore covers ALL [BannerType] values; a `switch` without a `default`
/// keeps it exhaustive so a future banner type fails the build until it is
/// mapped here.
class BannerNotificationMapper {
  BannerNotificationMapper._();

  /// Notification `type` string for the proactive health-coaching surface
  /// (Phase C3). Shared by the home card, the banner, and the coaching push
  /// so they land in the same bell filter and tap route.
  static const String healthCoachingType = 'health_coaching';

  /// Maps a [BannerType] to the notification `type` string used by the bell's
  /// filter taxonomy and tap routing in `notifications_screen.dart`.
  ///
  /// Exhaustive by design — no `default`. Adding a [BannerType] without a case
  /// here is a compile error, which guarantees every banner reaches the bell.
  static String typeString(BannerType type) {
    switch (type) {
      case BannerType.renewal:
        return 'renewal';
      case BannerType.missedWorkout:
        return 'missed_workout';
      case BannerType.rankPercentile:
        return 'rank_percentile';
      case BannerType.dailyCrate:
        return 'daily_crate';
      case BannerType.doubleXP:
        return 'double_xp';
      case BannerType.week1Tip:
        return 'week1_tip';
      case BannerType.contextual:
        return 'contextual';
      case BannerType.wrapped:
        return 'wrapped';
      case BannerType.healthCoaching:
        return healthCoachingType;
      case BannerType.streakAtRisk:
        return 'streak_at_risk';
    }
  }

  /// Convert a banner into a notification-bell item.
  ///
  /// Id resolution:
  ///   • when the banner carries a [BannerCardData.notifId] (a shared
  ///     deterministic `<type>_<localdate>` id), it is used verbatim so a push
  ///     and the same-day banner dedupe to ONE bell entry;
  ///   • otherwise the legacy `banner_<id>` scheme is used.
  ///
  /// Either way, [NotificationsNotifier.addNotification] ignores a duplicate
  /// id, so recording a banner on appearance AND again on dismissal is safe.
  static NotificationItem toNotification(BannerCardData banner) {
    return NotificationItem(
      id: banner.notifId ?? 'banner_${banner.id}',
      title: banner.title,
      body: banner.subtitle,
      type: typeString(banner.type),
      timestamp: DateTime.now(),
    );
  }
}
