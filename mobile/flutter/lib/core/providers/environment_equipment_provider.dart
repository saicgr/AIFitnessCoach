import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../constants/api_constants.dart';

/// Workout environment options
enum WorkoutEnvironment {
  commercialGym,
  homeGym,
  home,
  outdoors,
  hotel,
  apartmentGym,
  officeGym,
  custom;

  String get value {
    switch (this) {
      case WorkoutEnvironment.commercialGym:
        return 'commercial_gym';
      case WorkoutEnvironment.homeGym:
        return 'home_gym';
      case WorkoutEnvironment.home:
        return 'home';
      case WorkoutEnvironment.outdoors:
        return 'outdoors';
      case WorkoutEnvironment.hotel:
        return 'hotel';
      case WorkoutEnvironment.apartmentGym:
        return 'apartment_gym';
      case WorkoutEnvironment.officeGym:
        return 'office_gym';
      case WorkoutEnvironment.custom:
        return 'custom';
    }
  }

  String get displayName {
    switch (this) {
      case WorkoutEnvironment.commercialGym:
        return 'Commercial Gym';
      case WorkoutEnvironment.homeGym:
        return 'Home Gym';
      case WorkoutEnvironment.home:
        return 'Home (Minimal)';
      case WorkoutEnvironment.outdoors:
        return 'Outdoors';
      case WorkoutEnvironment.hotel:
        return 'Hotel/Travel';
      case WorkoutEnvironment.apartmentGym:
        return 'Apartment Gym';
      case WorkoutEnvironment.officeGym:
        return 'Office Gym';
      case WorkoutEnvironment.custom:
        return 'Custom Setup';
    }
  }

  String get description {
    switch (this) {
      case WorkoutEnvironment.commercialGym:
        return 'Full access to machines and free weights';
      case WorkoutEnvironment.homeGym:
        return 'Dedicated home gym setup';
      case WorkoutEnvironment.home:
        return 'Minimal equipment workouts';
      case WorkoutEnvironment.outdoors:
        return 'Parks, trails, outdoor spaces';
      case WorkoutEnvironment.hotel:
        return 'Travel-friendly workouts';
      case WorkoutEnvironment.apartmentGym:
        return 'Basic machines and dumbbells';
      case WorkoutEnvironment.officeGym:
        return 'Workplace fitness center';
      case WorkoutEnvironment.custom:
        return 'Define your own equipment';
    }
  }

  String get icon {
    switch (this) {
      case WorkoutEnvironment.commercialGym:
        return '🏢';
      case WorkoutEnvironment.homeGym:
        return '🏠';
      case WorkoutEnvironment.home:
        return '🏡';
      case WorkoutEnvironment.outdoors:
        return '🌳';
      case WorkoutEnvironment.hotel:
        return '🧳';
      case WorkoutEnvironment.apartmentGym:
        return '🏬';
      case WorkoutEnvironment.officeGym:
        return '💼';
      case WorkoutEnvironment.custom:
        return '⚙️';
    }
  }

  static WorkoutEnvironment fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'commercial_gym':
        return WorkoutEnvironment.commercialGym;
      case 'home_gym':
        return WorkoutEnvironment.homeGym;
      case 'home':
        return WorkoutEnvironment.home;
      case 'outdoors':
        return WorkoutEnvironment.outdoors;
      case 'hotel':
        return WorkoutEnvironment.hotel;
      case 'apartment_gym':
        return WorkoutEnvironment.apartmentGym;
      case 'office_gym':
        return WorkoutEnvironment.officeGym;
      case 'custom':
        return WorkoutEnvironment.custom;
      default:
        return WorkoutEnvironment.commercialGym;
    }
  }

  /// Get default equipment for this environment
  List<String> get defaultEquipment {
    switch (this) {
      case WorkoutEnvironment.commercialGym:
        return [
          'barbell',
          'dumbbells',
          'kettlebells',
          'cable_machine',
          'smith_machine',
          'leg_press',
          'lat_pulldown',
          'bench_press',
          'squat_rack',
          'power_rack',
          'dip_station',
          'ez_curl_bar',
          'leg_curl_machine',
          'leg_extension_machine',
          'chest_fly_machine',
          'shoulder_press_machine',
          'hack_squat',
          'calf_raise_machine',
          'seated_row_machine',
          'treadmill',
          'stationary_bike',
          'elliptical',
          'rowing_machine',
        ];
      case WorkoutEnvironment.homeGym:
        return [
          'barbell',
          'dumbbells',
          'kettlebells',
          'pull_up_bar',
          'resistance_bands',
          'adjustable_bench',
          'squat_rack',
          'weight_plates',
          'ez_curl_bar',
          'dip_station',
          'yoga_mat',
        ];
      case WorkoutEnvironment.home:
        return [
          'resistance_bands',
          'yoga_mat',
          'jump_rope',
        ];
      case WorkoutEnvironment.outdoors:
        return [
          'resistance_bands',
          'jump_rope',
        ];
      case WorkoutEnvironment.hotel:
        return [
          'dumbbells',
          'resistance_bands',
          'treadmill',
          'stationary_bike',
          'yoga_mat',
        ];
      case WorkoutEnvironment.apartmentGym:
        return [
          'dumbbells',
          'cable_machine',
          'treadmill',
          'stationary_bike',
          'elliptical',
          'adjustable_bench',
          'leg_press',
          'lat_pulldown',
        ];
      case WorkoutEnvironment.officeGym:
        return [
          'dumbbells',
          'cable_machine',
          'treadmill',
          'stationary_bike',
          'adjustable_bench',
          'resistance_bands',
        ];
      case WorkoutEnvironment.custom:
        return []; // User defines their own
    }
  }
}

/// State for environment and equipment settings
class EnvironmentEquipmentState {
  final WorkoutEnvironment environment;
  final List<String> equipment;
  final bool isLoading;
  final String? error;

  const EnvironmentEquipmentState({
    this.environment = WorkoutEnvironment.commercialGym,
    this.equipment = const [],
    this.isLoading = false,
    this.error,
  });

  EnvironmentEquipmentState copyWith({
    WorkoutEnvironment? environment,
    List<String>? equipment,
    bool? isLoading,
    String? error,
  }) {
    return EnvironmentEquipmentState(
      environment: environment ?? this.environment,
      equipment: equipment ?? this.equipment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get equipment count for display
  String get equipmentCountDisplay {
    if (equipment.isEmpty) return 'None selected';
    if (equipment.length == 1) return '1 item';
    return '${equipment.length} items';
  }
}

/// Provider for environment and equipment settings
final environmentEquipmentProvider =
    StateNotifierProvider<EnvironmentEquipmentNotifier, EnvironmentEquipmentState>(
        (ref) {
  return EnvironmentEquipmentNotifier(ref);
});

/// Notifier for managing environment and equipment state
class EnvironmentEquipmentNotifier extends StateNotifier<EnvironmentEquipmentState> {
  final Ref _ref;

  EnvironmentEquipmentNotifier(this._ref) : super(const EnvironmentEquipmentState()) {
    _init();
  }

  /// Parse preferences JSON string to Map
  Map<String, dynamic>? _parsePreferences(String? prefsJson) {
    if (prefsJson == null || prefsJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(prefsJson);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parse equipment JSON string to List
  List<String> _parseEquipment(String? equipJson) {
    if (equipJson == null || equipJson.isEmpty) return [];
    try {
      final decoded = jsonDecode(equipJson);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Initialize from user profile
  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user != null) {
        final prefsMap = _parsePreferences(authState.user!.preferences);
        final environment = WorkoutEnvironment.fromString(
          prefsMap?['workout_environment']?.toString(),
        );
        final equipment = _parseEquipment(authState.user!.equipment);

        state = EnvironmentEquipmentState(
          environment: environment,
          equipment: equipment,
        );
        debugPrint(
          '   [EnvEquip] Loaded: env=${environment.value}, equipment=${equipment.length} items',
        );
        return;
      }
      state = const EnvironmentEquipmentState();
      debugPrint('   [EnvEquip] Using defaults');
    } catch (e) {
      debugPrint('   [EnvEquip] Init error: $e');
      state = EnvironmentEquipmentState(error: e.toString());
    }
  }

  /// Set workout environment and sync to backend (without changing equipment)
  Future<void> setEnvironment(WorkoutEnvironment env) async {
    if (env == state.environment) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'workout_environment': env.value},
        );
        debugPrint('   [EnvEquip] Synced environment: ${env.value}');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(environment: env, isLoading: false);
      debugPrint('   [EnvEquip] Updated environment to: ${env.value}');
    } catch (e) {
      debugPrint('   [EnvEquip] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set workout environment AND update equipment to defaults for that environment
  Future<void> setEnvironmentWithDefaultEquipment(WorkoutEnvironment env) async {
    if (env == state.environment) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();
      final defaultEquip = env.defaultEquipment;

      if (userId != null) {
        // Update both environment and equipment in one call
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {
            'workout_environment': env.value,
            'equipment': defaultEquip,
          },
        );
        debugPrint('   [EnvEquip] Synced environment: ${env.value} with ${defaultEquip.length} default items');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(
        environment: env,
        equipment: defaultEquip,
        isLoading: false,
      );
      debugPrint('   [EnvEquip] Updated environment to: ${env.value} with default equipment');
    } catch (e) {
      debugPrint('   [EnvEquip] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set equipment list and sync to backend
  Future<void> setEquipment(List<String> equipment) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {'equipment': equipment},
        );
        debugPrint('   [EnvEquip] Synced equipment: ${equipment.length} items');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(equipment: equipment, isLoading: false);
      debugPrint('   [EnvEquip] Updated equipment to: ${equipment.length} items');
    } catch (e) {
      debugPrint('   [EnvEquip] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Set detailed equipment with quantities and weights, and sync to backend
  /// This updates both 'equipment' (simple list) and 'equipment_details' (detailed list)
  Future<void> setEquipmentDetails(List<Map<String, dynamic>> equipmentDetails) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      // Extract simple equipment names for backward compatibility
      final simpleEquipment = equipmentDetails.map((e) => e['name'] as String).toList();

      if (userId != null) {
        await apiClient.put(
          '${ApiConstants.users}/$userId',
          data: {
            'equipment': simpleEquipment,
            'equipment_details': equipmentDetails,
          },
        );
        debugPrint('   [EnvEquip] Synced equipment_details: ${equipmentDetails.length} items');
      }

      // Refresh user to get updated data
      await _ref.read(authStateProvider.notifier).refreshUser();

      state = state.copyWith(equipment: simpleEquipment, isLoading: false);
      debugPrint('   [EnvEquip] Updated equipment_details: ${equipmentDetails.length} items');
    } catch (e) {
      debugPrint('   [EnvEquip] Update error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add a single equipment item
  Future<void> addEquipment(String item) async {
    if (state.equipment.contains(item)) return;
    final newList = [...state.equipment, item];
    await setEquipment(newList);
  }

  /// Remove a single equipment item
  Future<void> removeEquipment(String item) async {
    if (!state.equipment.contains(item)) return;
    final newList = state.equipment.where((e) => e != item).toList();
    await setEquipment(newList);
  }

  /// Refresh from user profile
  Future<void> refresh() async {
    final authState = _ref.read(authStateProvider);
    if (authState.user != null) {
      final prefsMap = _parsePreferences(authState.user!.preferences);
      final environment = WorkoutEnvironment.fromString(
        prefsMap?['workout_environment']?.toString(),
      );
      final equipment = _parseEquipment(authState.user!.equipment);

      state = EnvironmentEquipmentState(
        environment: environment,
        equipment: equipment,
      );
    }
  }
}

/// Common equipment options for selection
const List<String> commonEquipmentOptions = [
  'barbell',
  'dumbbells',
  'kettlebells',
  'pull_up_bar',
  'resistance_bands',
  'cable_machine',
  'smith_machine',
  'leg_press',
  'lat_pulldown',
  'rowing_machine',
  'treadmill',
  'stationary_bike',
  'elliptical',
  'bench_press',
  'squat_rack',
  'power_rack',
  'dip_station',
  'ez_curl_bar',
  'trap_bar',
  'medicine_ball',
  'stability_ball',
  'foam_roller',
  'ab_roller',
  'battle_ropes',
  'trx_suspension',
  'yoga_mat',
  'jump_rope',
  'weight_plates',
  'adjustable_bench',
  'preacher_curl_bench',
  'leg_curl_machine',
  'leg_extension_machine',
  'chest_fly_machine',
  'shoulder_press_machine',
  'hack_squat',
  'calf_raise_machine',
  'seated_row_machine',
];

/// Get display name for equipment
String getEquipmentDisplayName(String equipment) {
  return equipment
      .split('_')
      .map((word) => word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1)}'
          : '')
      .join(' ');
}
