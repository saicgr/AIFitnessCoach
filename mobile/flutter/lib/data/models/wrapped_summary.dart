class WrappedSummary {
  final List<WrappedPeriodInfo> available;
  final CurrentMonthProgress? currentMonth;
  final int personalitiesCollected;

  const WrappedSummary({
    required this.available,
    this.currentMonth,
    required this.personalitiesCollected,
  });

  factory WrappedSummary.fromJson(Map<String, dynamic> json) {
    return WrappedSummary(
      available: (json['available'] as List<dynamic>?)
              ?.map(
                  (e) => WrappedPeriodInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentMonth: json['current_month'] != null
          ? CurrentMonthProgress.fromJson(
              json['current_month'] as Map<String, dynamic>)
          : null,
      personalitiesCollected:
          (json['personalities_collected'] as num?)?.toInt() ?? 0,
    );
  }
}

class WrappedPeriodInfo {
  final String period;
  final bool viewed;
  final String? personality;
  final int totalWorkouts;
  final double totalVolumeLbs;

  const WrappedPeriodInfo({
    required this.period,
    required this.viewed,
    this.personality,
    required this.totalWorkouts,
    required this.totalVolumeLbs,
  });

  factory WrappedPeriodInfo.fromJson(Map<String, dynamic> json) {
    return WrappedPeriodInfo(
      period: json['period'] as String,
      viewed: json['viewed'] as bool? ?? false,
      personality: json['personality'] as String?,
      totalWorkouts: (json['total_workouts'] as num?)?.toInt() ?? 0,
      totalVolumeLbs: (json['total_volume_lbs'] as num?)?.toDouble() ?? 0,
    );
  }

  // Helper: month display name (reuses logic from WrappedData)
  String get monthDisplayName {
    final parts = period.split('-');
    if (parts.length != 2) return period;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  String get yearDisplay {
    final parts = period.split('-');
    return parts.isNotEmpty ? parts[0] : '';
  }
}

class CurrentMonthProgress {
  final String period;
  final int workoutsSoFar;
  final double volumeSoFar;
  final int prsSoFar;
  final int daysUntilDrop;
  final bool eligible;

  const CurrentMonthProgress({
    required this.period,
    required this.workoutsSoFar,
    required this.volumeSoFar,
    required this.prsSoFar,
    required this.daysUntilDrop,
    required this.eligible,
  });

  factory CurrentMonthProgress.fromJson(Map<String, dynamic> json) {
    return CurrentMonthProgress(
      period: json['period'] as String,
      workoutsSoFar: (json['workouts_so_far'] as num?)?.toInt() ?? 0,
      volumeSoFar: (json['volume_so_far'] as num?)?.toDouble() ?? 0,
      prsSoFar: (json['prs_so_far'] as num?)?.toInt() ?? 0,
      daysUntilDrop: (json['days_until_drop'] as num?)?.toInt() ?? 0,
      eligible: json['eligible'] as bool? ?? false,
    );
  }
}
