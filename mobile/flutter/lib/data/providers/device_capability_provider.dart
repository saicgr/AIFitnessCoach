import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/device_capability_service.dart';

/// Provider for the overall device capability assessment.
/// Returns the capability level (incompatible, basic, standard, optimal).
final deviceCapabilityProvider = FutureProvider<DeviceCapability>((ref) async {
  final service = DeviceCapabilityService();
  return service.assessCapability();
});

/// Provider for the device RAM in GB.
final deviceRamProvider = FutureProvider<double>((ref) async {
  final service = DeviceCapabilityService();
  return service.getDeviceRam();
});

/// Provider for the recommended Gemma model for this device.
final recommendedModelProvider = FutureProvider<GemmaModelInfo>((ref) async {
  final service = DeviceCapabilityService();
  return service.getRecommendedModel();
});

/// Provider that checks whether the device can run on-device AI at all.
final canRunOnDeviceAIProvider = FutureProvider<bool>((ref) async {
  final capability = await ref.watch(deviceCapabilityProvider.future);
  return capability.canRunOnDeviceAI;
});
