import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/api_client.dart';
import 'auth_provider.dart';

/// State for weight increment preferences per equipment type.
class WeightIncrementsState {
  final double dumbbell;
  final double barbell;
  final double machine;
  final double kettlebell;
  final double cable;
  final String unit; // 'kg' or 'lbs'
  final bool isLoading;
  final String? error;

  const WeightIncrementsState({
    this.dumbbell = 2.5,
    this.barbell = 2.5,
    this.machine = 5.0,
    this.kettlebell = 4.0,
    this.cable = 2.5,
    this.unit = 'kg',
    this.isLoading = false,
    this.error,
  });

  /// Default values for weight increments.
  static const defaults = WeightIncrementsState();

  /// Get the increment value for a given equipment type.
  double getIncrement(String? equipmentType) {
    if (equipmentType == null) return dumbbell;
    final eq = equipmentType.toLowerCase();
    if (eq.contains('dumbbell')) return dumbbell;
    if (eq.contains('barbell')) return barbell;
    if (eq.contains('machine')) return machine;
    if (eq.contains('kettlebell')) return kettlebell;
    if (eq.contains('cable')) return cable;
    return dumbbell; // Default to dumbbell increment
  }

  /// Get increment in kg (converts if stored in lbs).
  double getIncrementKg(String? equipmentType) {
    final value = getIncrement(equipmentType);
    return unit == 'lbs' ? value / 2.20462 : value;
  }

  /// Get the unit suffix string.
  String get unitSuffix => unit;

  WeightIncrementsState copyWith({
    double? dumbbell,
    double? barbell,
    double? machine,
    double? kettlebell,
    double? cable,
    String? unit,
    bool? isLoading,
    String? error,
  }) {
    return WeightIncrementsState(
      dumbbell: dumbbell ?? this.dumbbell,
      barbell: barbell ?? this.barbell,
      machine: machine ?? this.machine,
      kettlebell: kettlebell ?? this.kettlebell,
      cable: cable ?? this.cable,
      unit: unit ?? this.unit,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  Map<String, dynamic> toJson() => {
        'dumbbell': dumbbell,
        'barbell': barbell,
        'machine': machine,
        'kettlebell': kettlebell,
        'cable': cable,
        'unit': unit,
      };

  factory WeightIncrementsState.fromJson(Map<String, dynamic> json) {
    return WeightIncrementsState(
      dumbbell: (json['dumbbell'] as num?)?.toDouble() ?? 2.5,
      barbell: (json['barbell'] as num?)?.toDouble() ?? 2.5,
      machine: (json['machine'] as num?)?.toDouble() ?? 5.0,
      kettlebell: (json['kettlebell'] as num?)?.toDouble() ?? 4.0,
      cable: (json['cable'] as num?)?.toDouble() ?? 2.5,
      unit: json['unit'] as String? ?? 'kg',
    );
  }
}

/// Provider for weight increment preferences.
final weightIncrementsProvider =
    StateNotifierProvider<WeightIncrementsNotifier, WeightIncrementsState>(
        (ref) {
  return WeightIncrementsNotifier(ref);
});

/// Notifier for managing weight increment preferences.
class WeightIncrementsNotifier extends StateNotifier<WeightIncrementsState> {
  final Ref _ref;

  // SharedPreferences keys
  static const String _dumbbellKey = 'weight_increment_dumbbell';
  static const String _barbellKey = 'weight_increment_barbell';
  static const String _machineKey = 'weight_increment_machine';
  static const String _kettlebellKey = 'weight_increment_kettlebell';
  static const String _cableKey = 'weight_increment_cable';
  static const String _unitKey = 'weight_increment_unit';

  WeightIncrementsNotifier(this._ref)
      : super(const WeightIncrementsState()) {
    _init();
  }

  /// Initialize from local storage and backend.
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      // Load from local storage first for instant feedback
      await _loadFromLocalStorage();

      debugPrint('✅ [WeightIncrements] Loaded from local storage');

      // Try to fetch from backend
      await _fetchFromBackend();
    } catch (e) {
      debugPrint('❌ [WeightIncrements] Init error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load preferences from local storage.
  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    state = WeightIncrementsState(
      dumbbell: prefs.getDouble(_dumbbellKey) ?? 2.5,
      barbell: prefs.getDouble(_barbellKey) ?? 2.5,
      machine: prefs.getDouble(_machineKey) ?? 5.0,
      kettlebell: prefs.getDouble(_kettlebellKey) ?? 4.0,
      cable: prefs.getDouble(_cableKey) ?? 2.5,
      unit: prefs.getString(_unitKey) ?? 'kg',
      isLoading: false,
    );
  }

  /// Fetch preferences from backend and update state.
  Future<void> _fetchFromBackend() async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        debugPrint('⚠️ [WeightIncrements] No user ID, skipping backend fetch');
        return;
      }

      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get('/weight-increments/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        state = state.copyWith(
          dumbbell: (data['dumbbell'] as num?)?.toDouble() ?? 2.5,
          barbell: (data['barbell'] as num?)?.toDouble() ?? 2.5,
          machine: (data['machine'] as num?)?.toDouble() ?? 5.0,
          kettlebell: (data['kettlebell'] as num?)?.toDouble() ?? 4.0,
          cable: (data['cable'] as num?)?.toDouble() ?? 2.5,
          unit: data['unit'] as String? ?? 'kg',
          isLoading: false,
        );

        // Save to local storage
        await _saveToLocalStorage();

        debugPrint('✅ [WeightIncrements] Synced from backend');
      }
    } catch (e) {
      // Don't fail if backend fetch fails - local storage is the fallback
      debugPrint('⚠️ [WeightIncrements] Backend fetch failed: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Save current state to local storage.
  Future<void> _saveToLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dumbbellKey, state.dumbbell);
    await prefs.setDouble(_barbellKey, state.barbell);
    await prefs.setDouble(_machineKey, state.machine);
    await prefs.setDouble(_kettlebellKey, state.kettlebell);
    await prefs.setDouble(_cableKey, state.cable);
    await prefs.setString(_unitKey, state.unit);
  }

  /// Sync current state to backend.
  Future<void> _syncToBackend(Map<String, dynamic> updates) async {
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) {
        debugPrint('⚠️ [WeightIncrements] No user ID, skipping backend sync');
        return;
      }

      final apiClient = _ref.read(apiClientProvider);
      await apiClient.put('/weight-increments/$userId', data: updates);
      debugPrint('✅ [WeightIncrements] Synced to backend: $updates');
    } catch (e) {
      debugPrint('⚠️ [WeightIncrements] Backend sync failed: $e');
    }
  }

  /// Set increment for a specific equipment type.
  Future<void> setIncrement(String equipment, double value) async {
    final clamped = value.clamp(0.5, 50.0);

    switch (equipment) {
      case 'dumbbell':
        if (clamped == state.dumbbell) return;
        state = state.copyWith(dumbbell: clamped);
        break;
      case 'barbell':
        if (clamped == state.barbell) return;
        state = state.copyWith(barbell: clamped);
        break;
      case 'machine':
        if (clamped == state.machine) return;
        state = state.copyWith(machine: clamped);
        break;
      case 'kettlebell':
        if (clamped == state.kettlebell) return;
        state = state.copyWith(kettlebell: clamped);
        break;
      case 'cable':
        if (clamped == state.cable) return;
        state = state.copyWith(cable: clamped);
        break;
      default:
        debugPrint('⚠️ [WeightIncrements] Unknown equipment: $equipment');
        return;
    }

    await _saveToLocalStorage();
    await _syncToBackend({equipment: clamped});
  }

  /// Set the unit preference (kg or lbs).
  Future<void> setUnit(String unit) async {
    if (unit != 'kg' && unit != 'lbs') {
      debugPrint('⚠️ [WeightIncrements] Invalid unit: $unit');
      return;
    }
    if (unit == state.unit) return;

    state = state.copyWith(unit: unit);
    await _saveToLocalStorage();
    await _syncToBackend({'unit': unit});
  }

  /// Reset all preferences to defaults.
  Future<void> resetToDefaults() async {
    state = const WeightIncrementsState();
    await _saveToLocalStorage();

    // Delete from backend (resets to defaults)
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId != null) {
        final apiClient = _ref.read(apiClientProvider);
        await apiClient.delete('/weight-increments/$userId');
        debugPrint('✅ [WeightIncrements] Reset to defaults on backend');
      }
    } catch (e) {
      debugPrint('⚠️ [WeightIncrements] Reset sync failed: $e');
    }
  }

  /// Refresh from backend.
  Future<void> refresh() async {
    await _fetchFromBackend();
  }
}
