part of 'derived_metric_detail_screen.dart';

/// Utility methods extracted from _DerivedMetricDetailScreenState
extension _DerivedMetricDetailScreenHelpers on _DerivedMetricDetailScreenState {
  // Health Zone Lines for Chart
  // ═════════════════════════════════════════════════════════════════

  List<HorizontalLine> _getHealthZoneLines(
      DerivedMetricType type, String? gender) {
    final isMale = gender?.toLowerCase() == 'male';

    switch (type) {
      case DerivedMetricType.bmi:
        return [
          _zoneLine(18.5, 'Underweight', Colors.blue),
          _zoneLine(25, 'Overweight', Colors.amber),
          _zoneLine(30, 'Obese', Colors.red),
        ];

      case DerivedMetricType.waistToHipRatio:
        if (isMale) {
          return [
            _zoneLine(0.90, 'Moderate', Colors.amber),
            _zoneLine(1.0, 'High Risk', Colors.red),
          ];
        } else {
          return [
            _zoneLine(0.80, 'Moderate', Colors.amber),
            _zoneLine(0.85, 'High Risk', Colors.red),
          ];
        }

      case DerivedMetricType.waistToHeightRatio:
        return [
          _zoneLine(0.4, 'Underweight', Colors.blue),
          _zoneLine(0.5, 'Overweight', Colors.amber),
          _zoneLine(0.6, 'Obese', Colors.red),
        ];

      case DerivedMetricType.ffmi:
        if (isMale) {
          return [
            _zoneLine(18, 'Average', Colors.amber),
            _zoneLine(20, 'Above Avg', Colors.green),
            _zoneLine(25, 'Natural Limit', Colors.red),
          ];
        } else {
          return [
            _zoneLine(14, 'Average', Colors.amber),
            _zoneLine(16, 'Above Avg', Colors.green),
            _zoneLine(21, 'Natural Limit', Colors.red),
          ];
        }

      case DerivedMetricType.armSymmetry:
      case DerivedMetricType.legSymmetry:
        return [
          _zoneLine(88, 'Imbalanced', Colors.red),
          _zoneLine(93, 'Moderate', Colors.amber),
          _zoneLine(97, 'Good', Colors.green),
        ];

      // No standard health zones for these
      case DerivedMetricType.leanBodyMass:
      case DerivedMetricType.shoulderToWaistRatio:
      case DerivedMetricType.chestToWaistRatio:
        return [];
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // Input Values (Based On)
  // ═════════════════════════════════════════════════════════════════

  List<({String label, String value})> _getInputValues(
      MeasurementsState state, double? heightCm) {
    final summary = state.summary;
    if (summary == null) return [];

    final inputs = <({String label, String value})>[];

    switch (_type) {
      case DerivedMetricType.bmi:
        final weight = summary.latestByType[MeasurementType.weight];
        if (weight != null) {
          inputs.add((
            label: 'Weight',
            value: '${_formatValue(weight.getValueInUnit(true))} kg'
          ));
        }
        if (heightCm != null) {
          inputs.add(
              (label: 'Height', value: '${_formatValue(heightCm)} cm'));
        }
        break;

      case DerivedMetricType.waistToHipRatio:
        final waist = summary.latestByType[MeasurementType.waist];
        final hips = summary.latestByType[MeasurementType.hips];
        if (waist != null) {
          inputs.add((
            label: 'Waist',
            value: '${_formatValue(waist.getValueInUnit(true))} cm'
          ));
        }
        if (hips != null) {
          inputs.add((
            label: 'Hips',
            value: '${_formatValue(hips.getValueInUnit(true))} cm'
          ));
        }
        break;

      case DerivedMetricType.waistToHeightRatio:
        final waist = summary.latestByType[MeasurementType.waist];
        if (waist != null) {
          inputs.add((
            label: 'Waist',
            value: '${_formatValue(waist.getValueInUnit(true))} cm'
          ));
        }
        if (heightCm != null) {
          inputs.add(
              (label: 'Height', value: '${_formatValue(heightCm)} cm'));
        }
        break;

      case DerivedMetricType.ffmi:
        final weight = summary.latestByType[MeasurementType.weight];
        final bodyFat = summary.latestByType[MeasurementType.bodyFat];
        if (weight != null) {
          inputs.add((
            label: 'Weight',
            value: '${_formatValue(weight.getValueInUnit(true))} kg'
          ));
        }
        if (bodyFat != null) {
          inputs.add((
            label: 'Body Fat',
            value: '${_formatValue(bodyFat.value)}%'
          ));
        }
        if (heightCm != null) {
          inputs.add(
              (label: 'Height', value: '${_formatValue(heightCm)} cm'));
        }
        break;

      case DerivedMetricType.leanBodyMass:
        final weight = summary.latestByType[MeasurementType.weight];
        final bodyFat = summary.latestByType[MeasurementType.bodyFat];
        if (weight != null) {
          inputs.add((
            label: 'Weight',
            value: '${_formatValue(weight.getValueInUnit(true))} kg'
          ));
        }
        if (bodyFat != null) {
          inputs.add((
            label: 'Body Fat',
            value: '${_formatValue(bodyFat.value)}%'
          ));
        }
        break;

      case DerivedMetricType.shoulderToWaistRatio:
        final shoulders = summary.latestByType[MeasurementType.shoulders];
        final waist = summary.latestByType[MeasurementType.waist];
        if (shoulders != null) {
          inputs.add((
            label: 'Shoulders',
            value: '${_formatValue(shoulders.getValueInUnit(true))} cm'
          ));
        }
        if (waist != null) {
          inputs.add((
            label: 'Waist',
            value: '${_formatValue(waist.getValueInUnit(true))} cm'
          ));
        }
        break;

      case DerivedMetricType.chestToWaistRatio:
        final chest = summary.latestByType[MeasurementType.chest];
        final waist = summary.latestByType[MeasurementType.waist];
        if (chest != null) {
          inputs.add((
            label: 'Chest',
            value: '${_formatValue(chest.getValueInUnit(true))} cm'
          ));
        }
        if (waist != null) {
          inputs.add((
            label: 'Waist',
            value: '${_formatValue(waist.getValueInUnit(true))} cm'
          ));
        }
        break;

      case DerivedMetricType.armSymmetry:
        final left = summary.latestByType[MeasurementType.bicepsLeft];
        final right = summary.latestByType[MeasurementType.bicepsRight];
        if (left != null) {
          inputs.add((
            label: 'Biceps (L)',
            value: '${_formatValue(left.getValueInUnit(true))} cm'
          ));
        }
        if (right != null) {
          inputs.add((
            label: 'Biceps (R)',
            value: '${_formatValue(right.getValueInUnit(true))} cm'
          ));
        }
        break;

      case DerivedMetricType.legSymmetry:
        final left = summary.latestByType[MeasurementType.thighLeft];
        final right = summary.latestByType[MeasurementType.thighRight];
        if (left != null) {
          inputs.add((
            label: 'Thigh (L)',
            value: '${_formatValue(left.getValueInUnit(true))} cm'
          ));
        }
        if (right != null) {
          inputs.add((
            label: 'Thigh (R)',
            value: '${_formatValue(right.getValueInUnit(true))} cm'
          ));
        }
        break;
    }

    return inputs;
  }

  List<({DateTime date, double value})> _filterByPeriod(
      List<({DateTime date, double value})> history) {
    if (_selectedPeriod == 'all') return history;

    final days = (_periods
        .firstWhere((p) => p['value'] == _selectedPeriod)['days'] as num).toInt();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return history.where((e) => e.date.isAfter(cutoff)).toList();
  }
}
