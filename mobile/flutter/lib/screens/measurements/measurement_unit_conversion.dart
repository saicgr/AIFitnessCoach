import '../../data/repositories/measurements_repository.dart';

/// Converts a raw user-entered value to the canonical metric unit used for
/// storage. Body-fat is always a percentage (no conversion). Weight converts
/// lbs → kg. Everything else (circumferences) converts in → cm.
///
/// Returns `(valueInMetric, metricUnitString)` so the caller can call
/// [MeasurementsRepository.addEntry] without duplicating the unit-lookup
/// logic.
({double value, String unit}) convertToMetric(
  double rawValue,
  MeasurementType type,
  bool isImperial,
) {
  // Body fat is stored as-is (the UI never offers a unit toggle for it).
  if (type == MeasurementType.bodyFat) {
    return (value: rawValue, unit: '%');
  }

  if (!isImperial) {
    return (value: rawValue, unit: type.metricUnit);
  }

  // Imperial → metric
  if (type == MeasurementType.weight) {
    return (value: rawValue / 2.20462, unit: 'kg');
  }
  // All other measurements are circumferences (inches → cm).
  return (value: rawValue * 2.54, unit: 'cm');
}

/// Converts a stored metric value to the display unit the user currently has
/// selected. Useful for pre-filling an editor with an existing measurement
/// when the user is working in imperial.
double convertFromMetric(double metricValue, MeasurementType type, bool isImperial) {
  if (!isImperial || type == MeasurementType.bodyFat) return metricValue;
  if (type == MeasurementType.weight) return metricValue * 2.20462;
  return metricValue / 2.54;
}
