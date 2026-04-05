part of 'diabetes_dashboard_screen.dart';



// ============================================
// Diabetes Data Models
// ============================================

/// Glucose reading status based on value
enum GlucoseStatus {
  low,
  normal,
  high,
  veryHigh;

  String get label {
    switch (this) {
      case GlucoseStatus.low:
        return 'LOW';
      case GlucoseStatus.normal:
        return 'NORMAL';
      case GlucoseStatus.high:
        return 'HIGH';
      case GlucoseStatus.veryHigh:
        return 'VERY HIGH';
    }
  }

  Color get color {
    switch (this) {
      case GlucoseStatus.low:
        return AppColors.error;
      case GlucoseStatus.normal:
        return AppColors.success;
      case GlucoseStatus.high:
        return AppColors.warning;
      case GlucoseStatus.veryHigh:
        return AppColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case GlucoseStatus.low:
        return Icons.arrow_downward;
      case GlucoseStatus.normal:
        return Icons.check_circle;
      case GlucoseStatus.high:
        return Icons.arrow_upward;
      case GlucoseStatus.veryHigh:
        return Icons.warning;
    }
  }

  static GlucoseStatus fromValue(double mgDl) {
    if (mgDl < 70) return GlucoseStatus.low;
    if (mgDl <= 140) return GlucoseStatus.normal;
    if (mgDl <= 180) return GlucoseStatus.high;
    return GlucoseStatus.veryHigh;
  }
}


/// Single glucose reading
class GlucoseReading {
  final String id;
  final double valueMgDl;
  final DateTime timestamp;
  final String? notes;
  final String? source; // 'manual', 'cgm', 'health_connect'

  const GlucoseReading({
    required this.id,
    required this.valueMgDl,
    required this.timestamp,
    this.notes,
    this.source,
  });

  GlucoseStatus get status => GlucoseStatus.fromValue(valueMgDl);
}


/// Insulin dose record
class InsulinDose {
  final String id;
  final double units;
  final String type; // 'rapid', 'long', 'mixed'
  final DateTime timestamp;
  final String? notes;

  const InsulinDose({
    required this.id,
    required this.units,
    required this.type,
    required this.timestamp,
    this.notes,
  });

  String get typeLabel {
    switch (type) {
      case 'rapid':
        return 'Rapid-Acting';
      case 'long':
        return 'Long-Acting';
      case 'mixed':
        return 'Mixed';
      default:
        return type;
    }
  }

  Color get typeColor {
    switch (type) {
      case 'rapid':
        return AppColors.cyan;
      case 'long':
        return AppColors.purple;
      case 'mixed':
        return AppColors.orange;
      default:
        return AppColors.textSecondary;
    }
  }
}


/// Time in range data
class TimeInRangeData {
  final double percentInRange; // 70-140 mg/dL
  final double percentBelow; // <70 mg/dL
  final double percentAbove; // >140 mg/dL
  final DateTime calculatedAt;
  final int daysIncluded;

  const TimeInRangeData({
    required this.percentInRange,
    required this.percentBelow,
    required this.percentAbove,
    required this.calculatedAt,
    this.daysIncluded = 7,
  });
}


/// A1C record
class A1CRecord {
  final double value;
  final DateTime measuredAt;
  final bool isEstimated;
  final String? notes;

  const A1CRecord({
    required this.value,
    required this.measuredAt,
    this.isEstimated = false,
    this.notes,
  });

  Color get statusColor {
    if (value < 5.7) return AppColors.success;
    if (value < 6.5) return AppColors.warning;
    return AppColors.error;
  }

  String get statusLabel {
    if (value < 5.7) return 'Normal';
    if (value < 6.5) return 'Prediabetic';
    return 'Diabetic Range';
  }
}


/// Today's insulin summary
class InsulinSummary {
  final double totalRapidUnits;
  final double totalLongUnits;
  final int doseCount;
  final DateTime lastDoseAt;

  const InsulinSummary({
    required this.totalRapidUnits,
    required this.totalLongUnits,
    required this.doseCount,
    required this.lastDoseAt,
  });

  double get totalUnits => totalRapidUnits + totalLongUnits;
}


// ============================================
// Diabetes State & Provider
// ============================================

/// State for Diabetes Dashboard
class DiabetesState {
  final GlucoseReading? currentGlucose;
  final List<GlucoseReading> recentReadings;
  final TimeInRangeData? timeInRange;
  final A1CRecord? latestA1C;
  final A1CRecord? estimatedA1C;
  final InsulinSummary? todayInsulinSummary;
  final List<InsulinDose> todayInsulinDoses;
  final bool isLoading;
  final bool isSyncing;
  final String? error;
  final DateTime? lastSyncedAt;

  const DiabetesState({
    this.currentGlucose,
    this.recentReadings = const [],
    this.timeInRange,
    this.latestA1C,
    this.estimatedA1C,
    this.todayInsulinSummary,
    this.todayInsulinDoses = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.lastSyncedAt,
  });

  DiabetesState copyWith({
    GlucoseReading? currentGlucose,
    List<GlucoseReading>? recentReadings,
    TimeInRangeData? timeInRange,
    A1CRecord? latestA1C,
    A1CRecord? estimatedA1C,
    InsulinSummary? todayInsulinSummary,
    List<InsulinDose>? todayInsulinDoses,
    bool? isLoading,
    bool? isSyncing,
    String? error,
    DateTime? lastSyncedAt,
    bool clearError = false,
  }) {
    return DiabetesState(
      currentGlucose: currentGlucose ?? this.currentGlucose,
      recentReadings: recentReadings ?? this.recentReadings,
      timeInRange: timeInRange ?? this.timeInRange,
      latestA1C: latestA1C ?? this.latestA1C,
      estimatedA1C: estimatedA1C ?? this.estimatedA1C,
      todayInsulinSummary: todayInsulinSummary ?? this.todayInsulinSummary,
      todayInsulinDoses: todayInsulinDoses ?? this.todayInsulinDoses,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}


/// Diabetes State Notifier - wired to real API providers
class DiabetesNotifier extends StateNotifier<DiabetesState> {
  final Ref _ref;

  DiabetesNotifier(this._ref) : super(const DiabetesState());

  /// Load all diabetes data from the real API providers
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Trigger the auto-loading provider which sets user IDs and loads all data
      await _ref.read(diabetesDataProvider.future);

      final glucoseState = _ref.read(glucoseReadingsProvider);
      final insulinState = _ref.read(insulinDosesProvider);
      final analyticsState = _ref.read(diabetesAnalyticsProvider);

      final now = DateTime.now();

      // Map latest glucose reading to local UI model
      GlucoseReading? currentGlucose;
      if (glucoseState.latestReading != null) {
        final r = glucoseState.latestReading!;
        currentGlucose = GlucoseReading(
          id: r.id,
          valueMgDl: r.glucoseValue.toDouble(),
          timestamp: r.recordedAt,
          notes: r.notes,
          source: r.readingType,
        );
      }

      // Map recent readings
      final recentReadings = glucoseState.readings.take(10).map((r) {
        return GlucoseReading(
          id: r.id,
          valueMgDl: r.glucoseValue.toDouble(),
          timestamp: r.recordedAt,
          notes: r.notes,
          source: r.readingType,
        );
      }).toList();

      // Map time in range from analytics
      TimeInRangeData? timeInRange;
      final weekSummary = analyticsState.weekSummary;
      if (weekSummary != null) {
        timeInRange = TimeInRangeData(
          percentInRange: weekSummary.timeInRangePercent,
          percentBelow: weekSummary.timeBelowRangePercent,
          percentAbove: weekSummary.timeAboveRangePercent,
          calculatedAt: now,
          daysIncluded: 7,
        );
      }

      // Map A1C data from analytics dashboard
      final dashboard = analyticsState.dashboard;
      A1CRecord? latestA1C;
      A1CRecord? estimatedA1C;
      if (dashboard != null) {
        if (dashboard.latestA1c != null) {
          latestA1C = A1CRecord(
            value: dashboard.latestA1c!,
            measuredAt: dashboard.a1cDate ?? now.subtract(const Duration(days: 45)),
            isEstimated: false,
          );
        }
        if (dashboard.estimatedA1c != null) {
          estimatedA1C = A1CRecord(
            value: dashboard.estimatedA1c!,
            measuredAt: now,
            isEstimated: true,
          );
        }
      }

      // Map insulin doses
      final todayInsulinDoses = insulinState.doses.map((d) {
        String type = 'rapid';
        if (d.isBasal) type = 'long';
        if (d.insulinTypeEnum.value == 'mixed') type = 'mixed';
        return InsulinDose(
          id: d.id,
          units: d.units,
          type: type,
          timestamp: d.administeredAt,
          notes: d.notes,
        );
      }).toList();

      InsulinSummary? todayInsulinSummary;
      if (todayInsulinDoses.isNotEmpty) {
        todayInsulinSummary = InsulinSummary(
          totalRapidUnits: todayInsulinDoses
              .where((d) => d.type == 'rapid')
              .fold(0.0, (sum, d) => sum + d.units),
          totalLongUnits: todayInsulinDoses
              .where((d) => d.type == 'long')
              .fold(0.0, (sum, d) => sum + d.units),
          doseCount: todayInsulinDoses.length,
          lastDoseAt: todayInsulinDoses.last.timestamp,
        );
      }

      state = state.copyWith(
        currentGlucose: currentGlucose,
        recentReadings: recentReadings,
        timeInRange: timeInRange,
        latestA1C: latestA1C,
        estimatedA1C: estimatedA1C,
        todayInsulinSummary: todayInsulinSummary,
        todayInsulinDoses: todayInsulinDoses,
        isLoading: false,
        lastSyncedAt: now,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load diabetes data: $e',
      );
    }
  }

  /// Sync with Health Connect (refresh data from server)
  Future<void> syncHealthConnect() async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      // Refresh all providers from the server
      final glucoseNotifier = _ref.read(glucoseReadingsProvider.notifier);
      final insulinNotifier = _ref.read(insulinDosesProvider.notifier);
      final analyticsNotifier = _ref.read(diabetesAnalyticsProvider.notifier);

      await Future.wait([
        glucoseNotifier.refresh(),
        insulinNotifier.refresh(),
        analyticsNotifier.refresh(),
      ]);

      // Reload the UI state from refreshed providers
      await loadData();

      state = state.copyWith(
        isSyncing: false,
        lastSyncedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Sync failed: $e',
      );
    }
  }

  /// Log a new glucose reading via real API
  Future<bool> logGlucose({
    required double valueMgDl,
    String? notes,
  }) async {
    try {
      final glucoseNotifier = _ref.read(glucoseReadingsProvider.notifier);
      final reading = await glucoseNotifier.addReading(
        glucoseValue: valueMgDl.toInt(),
        mealContext: 'other',
        notes: notes,
      );

      if (reading != null) {
        // Map the new reading to the local UI model and update state
        final newReading = GlucoseReading(
          id: reading.id,
          valueMgDl: reading.glucoseValue.toDouble(),
          timestamp: reading.recordedAt,
          notes: reading.notes,
          source: reading.readingType,
        );
        state = state.copyWith(
          currentGlucose: newReading,
          recentReadings: [newReading, ...state.recentReadings],
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to log glucose: $e');
      return false;
    }
  }

  /// Log a new insulin dose via real API
  Future<bool> logInsulin({
    required double units,
    required String type,
    String? notes,
  }) async {
    try {
      final insulinNotifier = _ref.read(insulinDosesProvider.notifier);
      String insulinType = 'rapid_acting';
      if (type == 'long') insulinType = 'long_acting';
      if (type == 'mixed') insulinType = 'mixed';

      final dose = await insulinNotifier.addDose(
        insulinName: type == 'long' ? 'Basal Insulin' : 'Rapid Insulin',
        insulinType: insulinType,
        units: units,
        notes: notes,
      );

      if (dose != null) {
        final newDose = InsulinDose(
          id: dose.id,
          units: dose.units,
          type: type,
          timestamp: dose.administeredAt,
          notes: dose.notes,
        );
        final updatedDoses = [...state.todayInsulinDoses, newDose];
        final updatedSummary = InsulinSummary(
          totalRapidUnits: updatedDoses
              .where((d) => d.type == 'rapid')
              .fold(0.0, (sum, d) => sum + d.units),
          totalLongUnits: updatedDoses
              .where((d) => d.type == 'long')
              .fold(0.0, (sum, d) => sum + d.units),
          doseCount: updatedDoses.length,
          lastDoseAt: newDose.timestamp,
        );
        state = state.copyWith(
          todayInsulinDoses: updatedDoses,
          todayInsulinSummary: updatedSummary,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to log insulin: $e');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadData();
  }
}

