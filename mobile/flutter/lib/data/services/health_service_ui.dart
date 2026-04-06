part of 'health_service.dart';

/// Methods extracted from HealthService
extension HealthServiceExt on HealthService {

  // Data types we want to read from Health Connect
  static final List<HealthDataType> _readTypes = [
    // Body measurements
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,

    // Heart
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,

    // Activity
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.FLIGHTS_CLIMBED,

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

  /// Get recovery metrics (resting HR, HRV, SpO2) in parallel
  Future<RecoveryMetrics> getRecoveryMetrics() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 1));

      final types = _getAvailableTypes([
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        HealthDataType.BLOOD_OXYGEN,
      ]);

      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: now,
        types: types,
      );

      final uniqueData = _health.removeDuplicates(data);

      int? restingHR;
      double? hrv;
      double? bloodOxygen;

      // Get the most recent value for each type
      for (final point in uniqueData) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        switch (point.type) {
          case HealthDataType.RESTING_HEART_RATE:
            restingHR ??= value.toInt();
            break;
          case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
          case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
            hrv ??= value;
            break;
          case HealthDataType.BLOOD_OXYGEN:
            bloodOxygen ??= value;
            break;
          default:
            break;
        }
      }

      debugPrint('💚 Recovery: HR=$restingHR, HRV=$hrv, SpO2=$bloodOxygen');
      return RecoveryMetrics(
        restingHR: restingHR,
        hrv: hrv,
        bloodOxygen: bloodOxygen,
      );
    } catch (e) {
      debugPrint('❌ Error getting recovery metrics: $e');
      return const RecoveryMetrics();
    }
  }


  /// Get today's vitals data (HRV, SpO2, body temp, respiratory rate, basal cal, flights, water)
  Future<Map<String, dynamic>> getTodayVitals() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final types = _getAvailableTypes([
        HealthDataType.HEART_RATE,
        HealthDataType.HEART_RATE_VARIABILITY_SDNN,
        HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.BODY_TEMPERATURE,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.FLIGHTS_CLIMBED,
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
      double? hrv;
      double? bloodOxygen;
      double? bodyTemperature;
      int? respiratoryRate;
      double basalCalories = 0;
      int flightsClimbed = 0;
      double waterMl = 0;

      for (final point in uniqueData) {
        final value = (point.value as NumericHealthValue).numericValue.toDouble();
        switch (point.type) {
          case HealthDataType.HEART_RATE:
            heartRateSum += value.toInt();
            heartRateCount++;
            if (value.toInt() > maxHeartRate) maxHeartRate = value.toInt();
            break;
          case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
          case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
            hrv ??= value;
            break;
          case HealthDataType.BLOOD_OXYGEN:
            bloodOxygen ??= value;
            break;
          case HealthDataType.BODY_TEMPERATURE:
            bodyTemperature ??= value;
            break;
          case HealthDataType.RESPIRATORY_RATE:
            respiratoryRate ??= value.toInt();
            break;
          case HealthDataType.BASAL_ENERGY_BURNED:
            basalCalories += value;
            break;
          case HealthDataType.FLIGHTS_CLIMBED:
            flightsClimbed += value.toInt();
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
        'hrv': hrv,
        'bloodOxygen': bloodOxygen,
        'bodyTemperature': bodyTemperature,
        'respiratoryRate': respiratoryRate,
        'basalCalories': basalCalories > 0 ? basalCalories : null,
        'flightsClimbed': flightsClimbed > 0 ? flightsClimbed : null,
        'waterMl': waterMl > 0 ? waterMl.toInt() : null,
      };
    } catch (e) {
      debugPrint('❌ Error getting today vitals: $e');
      return {};
    }
  }

}
