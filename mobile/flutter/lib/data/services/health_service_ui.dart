part of 'health_service.dart';

/// Methods extracted from HealthService
extension HealthServiceExt on HealthService {

  // Data types we want to read from Health Connect / HealthKit.
  //
  // Removed 2026-05-07 to comply with Google Play "Minimum Scope" Health
  // Connect Permissions policy: Distance (delta + walking/running),
  // FloorsClimbed (FLIGHTS_CLIMBED), HeartRateVariability (RMSSD + SDNN),
  // ElevationGained, Power, Speed, RespiratoryRate, BasalMetabolicRate
  // (BASAL_ENERGY_BURNED), OxygenSaturation (BLOOD_OXYGEN), BodyTemperature.
  // None of these surface in the user-facing product.
  static final List<HealthDataType> _readTypes = [
    // Body measurements
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,

    // Heart
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,

    // Activity
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,

    // Workout
    HealthDataType.WORKOUT,

    // Sleep
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
    HealthDataType.SLEEP_OUT_OF_BED,
    HealthDataType.SLEEP_SESSION,

    // Hydration
    HealthDataType.WATER,

    // Diabetic metrics
    HealthDataType.BLOOD_GLUCOSE,
  ];

  // Data types we want to write to Health Connect
  static final List<HealthDataType> _writeTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Check if Health Connect is available on the device
  Future<bool> isHealthConnectAvailable() async {
    try {
      await _ensureConfigured();
      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        return status == HealthConnectSdkStatus.sdkAvailable;
      } else if (Platform.isIOS) {
        // HealthKit is always available on iOS (if device supports it)
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking Health Connect availability: $e');
      return false;
    }
  }


  // ============================================
  // Sleep Data
  // ============================================

  /// Get sleep data summary for recent nights
  Future<SleepSummary> getSleepData({int days = 1}) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // Fetch all sleep-related types
      final sleepTypes = _getAvailableTypes([
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_AWAKE_IN_BED,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: sleepTypes,
      );

      final uniqueData = _health.removeDuplicates(data);

      int totalMinutes = 0;
      int deepMinutes = 0;
      int remMinutes = 0;
      int lightMinutes = 0;
      int awakeMinutes = 0;
      DateTime? earliestBed;
      DateTime? latestWake;

      for (final point in uniqueData) {
        final durationMin = point.dateTo.difference(point.dateFrom).inMinutes;
        switch (point.type) {
          case HealthDataType.SLEEP_ASLEEP:
            totalMinutes += durationMin;
            break;
          case HealthDataType.SLEEP_DEEP:
            deepMinutes += durationMin;
            break;
          case HealthDataType.SLEEP_REM:
            remMinutes += durationMin;
            break;
          case HealthDataType.SLEEP_LIGHT:
            lightMinutes += durationMin;
            break;
          case HealthDataType.SLEEP_AWAKE:
          case HealthDataType.SLEEP_AWAKE_IN_BED:
            awakeMinutes += durationMin;
            break;
          default:
            break;
        }

        // Track bed/wake times
        if (earliestBed == null || point.dateFrom.isBefore(earliestBed)) {
          earliestBed = point.dateFrom;
        }
        if (latestWake == null || point.dateTo.isAfter(latestWake)) {
          latestWake = point.dateTo;
        }
      }

      // If we only have stage breakdown but no SLEEP_ASLEEP total, sum the stages
      if (totalMinutes == 0 && (deepMinutes > 0 || remMinutes > 0 || lightMinutes > 0)) {
        totalMinutes = deepMinutes + remMinutes + lightMinutes;
      }

      // Include awake minutes in total if SLEEP_ASLEEP was 0 (some devices report only stages)
      if (totalMinutes == 0 && awakeMinutes > 0) {
        totalMinutes = awakeMinutes;
      }

      debugPrint('😴 Sleep data: ${totalMinutes}min total, ${deepMinutes}min deep, ${remMinutes}min REM, ${lightMinutes}min light, ${awakeMinutes}min awake');
      return SleepSummary(
        totalMinutes: totalMinutes,
        deepMinutes: deepMinutes,
        remMinutes: remMinutes,
        lightMinutes: lightMinutes,
        awakeMinutes: awakeMinutes,
        bedTime: earliestBed,
        wakeTime: latestWake,
      );
    } catch (e) {
      debugPrint('❌ Error getting sleep data: $e');
      return const SleepSummary();
    }
  }


  // ============================================
  // Recovery Metrics
  // ============================================

  /// Get recovery metrics. HRV and SpO2 were removed 2026-05-07 (Google Play
  /// minimum scope), so this now only returns resting heart rate. The
  /// RecoveryMetrics class still carries hrv/bloodOxygen fields for
  /// backwards compatibility — they are always null.
  Future<RecoveryMetrics> getRecoveryMetrics() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 1));

      final types = _getAvailableTypes([
        HealthDataType.RESTING_HEART_RATE,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      final uniqueData = _health.removeDuplicates(data);

      int? restingHR;

      for (final point in uniqueData) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        if (point.type == HealthDataType.RESTING_HEART_RATE) {
          restingHR ??= value.toInt();
        }
      }

      debugPrint('💚 Recovery: HR=$restingHR');
      return RecoveryMetrics(restingHR: restingHR);
    } catch (e) {
      debugPrint('❌ Error getting recovery metrics: $e');
      return const RecoveryMetrics();
    }
  }


  /// Get today's vitals (heart rate + water).
  ///
  /// HRV, SpO2, body temperature, respiratory rate, basal calories, and
  /// flights climbed were removed 2026-05-07 (Google Play minimum scope).
  /// The legacy null-valued keys for those metrics were also dropped — UI
  /// consumers no longer look them up.
  Future<Map<String, dynamic>> getTodayVitals() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final types = _getAvailableTypes([
        HealthDataType.HEART_RATE,
        HealthDataType.WATER,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: types,
      );

      final uniqueData = _health.removeDuplicates(data);

      int heartRateSum = 0;
      int heartRateCount = 0;
      int maxHeartRate = 0;
      int? minHeartRate;
      double waterMl = 0;

      for (final point in uniqueData) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        switch (point.type) {
          case HealthDataType.HEART_RATE:
            final v = value.toInt();
            heartRateSum += v;
            heartRateCount++;
            if (v > maxHeartRate) maxHeartRate = v;
            if (minHeartRate == null || v < minHeartRate) minHeartRate = v;
            break;
          case HealthDataType.WATER:
            waterMl += value;
            break;
          default:
            break;
        }
      }

      return {
        'avgHeartRate': heartRateCount > 0 ? heartRateSum ~/ heartRateCount : null,
        'maxHeartRate': maxHeartRate > 0 ? maxHeartRate : null,
        'minHeartRate': minHeartRate,
        'waterMl': waterMl > 0 ? waterMl.toInt() : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting today vitals: $e');
      return {};
    }
  }

}
