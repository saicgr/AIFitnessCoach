/// Evidence-based rest period lookup.
///
/// Values sourced from:
/// - Singer 2024 (rest period meta-analysis)
/// - Schoenfeld 2016 (rest intervals for hypertrophy)
/// - de Salles 2009 (rest interval between sets)
///
/// All values clamped to 30-300s range.
class RestPeriodTable {
  RestPeriodTable._();

  // Rest periods in seconds: [beginner, intermediate, advanced]
  // by goal x compound/isolation
  static const Map<String, Map<String, List<int>>> _table = {
    'strength': {
      'compound':  [210, 180, 150],
      'isolation': [150, 120, 90],
    },
    'hypertrophy': {
      'compound':  [150, 120, 90],
      'isolation': [90, 75, 60],
    },
    'endurance': {
      'compound':  [75, 60, 45],
      'isolation': [60, 45, 30],
    },
    'power': {
      'compound':  [270, 240, 210],
      'isolation': [180, 150, 120],
    },
  };

  static const _levelIndex = {
    'beginner': 0,
    'intermediate': 1,
    'advanced': 2,
  };

  /// Get rest seconds for the given parameters.
  ///
  /// [goal] - 'strength', 'hypertrophy', 'endurance', 'power'
  /// [isCompound] - true for compound exercises
  /// [fitnessLevel] - 'beginner', 'intermediate', 'advanced'
  static int getRestSeconds(String goal, bool isCompound, String fitnessLevel) {
    final goalEntry = _table[goal.toLowerCase()] ?? _table['hypertrophy']!;
    final key = isCompound ? 'compound' : 'isolation';
    final values = goalEntry[key]!;
    final idx = _levelIndex[fitnessLevel.toLowerCase()] ?? 1;
    return values[idx].clamp(30, 300);
  }

  /// Intra-pair rest for supersets (between the two exercises in a pair).
  static int getSupersetIntraPairRest() => 15;

  /// Inter-pair rest for supersets (between complete pairs).
  static int getSupersetInterPairRest(String goal) {
    switch (goal.toLowerCase()) {
      case 'strength': return 150;
      case 'power': return 150;
      case 'endurance': return 75;
      default: return 90; // hypertrophy
    }
  }
}
