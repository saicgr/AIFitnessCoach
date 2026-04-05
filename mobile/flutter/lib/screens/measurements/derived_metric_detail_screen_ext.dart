part of 'derived_metric_detail_screen.dart';

/// Methods extracted from _DerivedMetricDetailScreenState
extension __DerivedMetricDetailScreenStateExt on _DerivedMetricDetailScreenState {

  DerivedMetricType _parseType(String typeStr) {
    return DerivedMetricType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => DerivedMetricType.bmi,
    );
  }


  Future<void> _loadMeasurements() async {
    final auth = ref.read(authStateProvider);
    if (auth.user != null) {
      await ref
          .read(measurementsProvider.notifier)
          .loadAllMeasurements(auth.user!.id);
    }
  }


  HorizontalLine _zoneLine(double y, String label, Color color) {
    return HorizontalLine(
      y: y,
      color: color.withOpacity(0.3),
      strokeWidth: 1,
      dashArray: [5, 5],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        style: TextStyle(fontSize: 9, color: color.withOpacity(0.7)),
        labelResolver: (_) => label,
      ),
    );
  }


  // ═════════════════════════════════════════════════════════════════
  // Utility Helpers
  // ═════════════════════════════════════════════════════════════════

  String _getDisplayName(DerivedMetricType type) {
    switch (type) {
      case DerivedMetricType.bmi:
        return 'BMI';
      case DerivedMetricType.waistToHipRatio:
        return 'Waist-to-Hip Ratio';
      case DerivedMetricType.waistToHeightRatio:
        return 'Waist-to-Height Ratio';
      case DerivedMetricType.ffmi:
        return 'FFMI';
      case DerivedMetricType.leanBodyMass:
        return 'Lean Body Mass';
      case DerivedMetricType.shoulderToWaistRatio:
        return 'Shoulder-to-Waist Ratio';
      case DerivedMetricType.chestToWaistRatio:
        return 'Chest-to-Waist Ratio';
      case DerivedMetricType.armSymmetry:
        return 'Arm Symmetry';
      case DerivedMetricType.legSymmetry:
        return 'Leg Symmetry';
    }
  }


  String _getUnit(DerivedMetricType type) {
    switch (type) {
      case DerivedMetricType.bmi:
        return 'kg/m\u00B2';
      case DerivedMetricType.waistToHipRatio:
      case DerivedMetricType.waistToHeightRatio:
      case DerivedMetricType.shoulderToWaistRatio:
      case DerivedMetricType.chestToWaistRatio:
        return 'ratio';
      case DerivedMetricType.ffmi:
        return 'kg/m\u00B2';
      case DerivedMetricType.leanBodyMass:
        return 'kg';
      case DerivedMetricType.armSymmetry:
      case DerivedMetricType.legSymmetry:
        return '%';
    }
  }


  String _getInsufficientDataHint(DerivedMetricType type) {
    switch (type) {
      case DerivedMetricType.bmi:
        return 'Log weight measurements to see BMI trend';
      case DerivedMetricType.waistToHipRatio:
        return 'Log waist and hip measurements on the same day';
      case DerivedMetricType.waistToHeightRatio:
        return 'Log waist measurements to see trend';
      case DerivedMetricType.ffmi:
        return 'Log weight and body fat on the same day';
      case DerivedMetricType.leanBodyMass:
        return 'Log weight and body fat on the same day';
      case DerivedMetricType.shoulderToWaistRatio:
        return 'Log shoulder and waist measurements on the same day';
      case DerivedMetricType.chestToWaistRatio:
        return 'Log chest and waist measurements on the same day';
      case DerivedMetricType.armSymmetry:
        return 'Log left and right biceps on the same day';
      case DerivedMetricType.legSymmetry:
        return 'Log left and right thigh on the same day';
    }
  }


  String _formatValue(double value) {
    if (value == value.roundToDouble() && value.abs() < 1000) {
      return value.toInt().toString();
    }
    // Use 2 decimal places for ratios, 1 for everything else
    if (_type == DerivedMetricType.waistToHipRatio ||
        _type == DerivedMetricType.waistToHeightRatio ||
        _type == DerivedMetricType.shoulderToWaistRatio ||
        _type == DerivedMetricType.chestToWaistRatio) {
      return value.toStringAsFixed(2);
    }
    return value.toStringAsFixed(1);
  }


  Color _getChangeColor(double change) {
    // For BMI and WHR/WHtR, decrease is generally good
    if (_type == DerivedMetricType.bmi ||
        _type == DerivedMetricType.waistToHipRatio ||
        _type == DerivedMetricType.waistToHeightRatio) {
      return change < 0 ? AppColors.success : AppColors.error;
    }
    // For FFMI, lean mass, symmetry, and ratios, increase is good
    return change > 0 ? AppColors.success : AppColors.error;
  }


  Color _getRateColor(double rate, bool isDark) {
    if (rate.abs() < 0.01) {
      return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
    return _getChangeColor(rate);
  }

}
