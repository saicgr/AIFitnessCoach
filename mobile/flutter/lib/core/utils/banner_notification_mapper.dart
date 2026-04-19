import '../../screens/home/widgets/banner_card_data.dart';
import '../../screens/notifications/notifications_screen.dart';

/// Maps dismissed banners to notification items for the notification center.
class BannerNotificationMapper {
  BannerNotificationMapper._();

  static String _typeString(BannerType type) {
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
    }
  }

  /// Convert a dismissed banner into a notification item.
  /// Uses a deterministic ID based on banner id to prevent duplicates.
  static NotificationItem toNotification(BannerCardData banner) {
    return NotificationItem(
      id: 'banner_${banner.id}',
      title: banner.title,
      body: banner.subtitle,
      type: _typeString(banner.type),
      timestamp: DateTime.now(),
    );
  }
}
