part of 'trophy_room_screen.dart';



/// Filter options for trophy status display
enum TrophyStatusFilter {
  all,
  earned,
  inProgress,
  locked,
}


extension TrophyStatusFilterExtension on TrophyStatusFilter {
  String get displayName {
    switch (this) {
      case TrophyStatusFilter.all:
        return 'All';
      case TrophyStatusFilter.earned:
        return 'Earned';
      case TrophyStatusFilter.inProgress:
        return 'In Progress';
      case TrophyStatusFilter.locked:
        return 'Locked';
    }
  }

  IconData get icon {
    switch (this) {
      case TrophyStatusFilter.all:
        return Icons.grid_view_rounded;
      case TrophyStatusFilter.earned:
        return Icons.emoji_events;
      case TrophyStatusFilter.inProgress:
        return Icons.trending_up;
      case TrophyStatusFilter.locked:
        return Icons.lock_outline;
    }
  }
}

