import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/on_device_gemma_service.dart';
import '../../services/device_capability_service.dart';
import '../services/connectivity_service.dart';

/// State for offline chat
class OfflineChatState {
  final bool isAvailable;
  final bool isMultimodal;
  final String? modelName;
  final bool isGenerating;

  const OfflineChatState({
    this.isAvailable = false,
    this.isMultimodal = false,
    this.modelName,
    this.isGenerating = false,
  });

  OfflineChatState copyWith({
    bool? isAvailable,
    bool? isMultimodal,
    String? modelName,
    bool? isGenerating,
  }) {
    return OfflineChatState(
      isAvailable: isAvailable ?? this.isAvailable,
      isMultimodal: isMultimodal ?? this.isMultimodal,
      modelName: modelName ?? this.modelName,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

/// Provider for offline chat state.
///
/// Offline Mode is Coming Soon — always returns unavailable so no
/// on-device AI or offline chat fallback is triggered.
final offlineChatStateProvider = Provider<OfflineChatState>((ref) {
  // Offline Mode is Coming Soon — disabled until launch.
  return const OfflineChatState(isAvailable: false);
});

/// Whether chat should use offline mode.
///
/// Offline Mode is Coming Soon — always returns false.
final shouldUseOfflineChatProvider = Provider<bool>((ref) {
  return false;
});
