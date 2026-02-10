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

/// Provider for offline chat state
final offlineChatStateProvider = Provider<OfflineChatState>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final gemmaService = ref.watch(onDeviceGemmaServiceProvider);

  return OfflineChatState(
    isAvailable: !isOnline && gemmaService.isModelLoaded,
    isMultimodal: gemmaService.isMultimodal,
    modelName: gemmaService.loadedModelType != null
        ? GemmaModelInfo.fromType(gemmaService.loadedModelType!).displayName
        : null,
  );
});

/// Whether chat should use offline mode
final shouldUseOfflineChatProvider = Provider<bool>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final gemmaService = ref.watch(onDeviceGemmaServiceProvider);
  return !isOnline && gemmaService.isModelLoaded;
});
