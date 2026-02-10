import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:system_info_plus/system_info_plus.dart';

/// Device capability level for on-device AI model selection
enum DeviceCapability {
  /// Device cannot run any on-device models (<2GB RAM)
  incompatible,

  /// Can only run the smallest models (2-3GB RAM, 270M + embeddings)
  basic,

  /// Can run small/medium models (3-4GB RAM, up to Gemma 3n E2B)
  standard,

  /// Can run all models (4GB+ RAM, all models including Gemma 3n E4B)
  optimal,
}

extension DeviceCapabilityExtension on DeviceCapability {
  String get displayName {
    switch (this) {
      case DeviceCapability.incompatible:
        return 'Incompatible';
      case DeviceCapability.basic:
        return 'Basic';
      case DeviceCapability.standard:
        return 'Standard';
      case DeviceCapability.optimal:
        return 'Optimal';
    }
  }

  String get description {
    switch (this) {
      case DeviceCapability.incompatible:
        return 'This device does not have enough RAM for on-device AI.';
      case DeviceCapability.basic:
        return 'Supports lightweight AI models (270M, embeddings).';
      case DeviceCapability.standard:
        return 'Supports small to medium AI models (up to Gemma 3n E2B).';
      case DeviceCapability.optimal:
        return 'Supports all AI model sizes including multimodal.';
    }
  }

  bool get canRunOnDeviceAI => this != DeviceCapability.incompatible;
}

/// Detects device hardware capabilities for on-device AI model selection.
class DeviceCapabilityService {
  /// Get total device RAM in GB.
  Future<double> getDeviceRam() async {
    try {
      final ramBytes = await SystemInfoPlus.physicalMemory;
      if (ramBytes == null || ramBytes <= 0) {
        debugPrint('⚠️ [DeviceCapability] Could not read RAM, defaulting to 0');
        return 0.0;
      }
      final ramGB = ramBytes / 1024.0; // physicalMemory returns MB
      debugPrint('🔍 [DeviceCapability] Device RAM: ${ramGB.toStringAsFixed(1)} GB');
      return ramGB;
    } catch (e) {
      debugPrint('❌ [DeviceCapability] Error reading RAM: $e');
      return 0.0;
    }
  }

  /// Get available storage in GB.
  Future<double> getAvailableStorage() async {
    try {
      // Use dart:io to check available disk space on the app's directory
      final directory = Directory.systemTemp;
      final stat = await directory.stat();
      // FileStat doesn't give free space; use a best-effort check
      // On mobile, we rely on path_provider storage checks at download time
      debugPrint('🔍 [DeviceCapability] Storage check via ${stat.type}');
      return -1; // Unknown; caller should check at download time
    } catch (e) {
      debugPrint('❌ [DeviceCapability] Error checking storage: $e');
      return -1;
    }
  }

  /// Assess device capability based on available RAM.
  ///
  /// Thresholds:
  /// - <2GB: incompatible
  /// - 2-3GB: basic (FunctionGemma 270M, EmbeddingGemma 300M)
  /// - 3-4GB: standard (+ Gemma 3 1B, Gemma 3n E2B)
  /// - 4GB+: optimal (+ Gemma 3n E4B)
  Future<DeviceCapability> assessCapability() async {
    final ramGB = await getDeviceRam();

    if (ramGB < 2.0) {
      debugPrint('🔍 [DeviceCapability] Assessment: incompatible (${ramGB.toStringAsFixed(1)} GB)');
      return DeviceCapability.incompatible;
    } else if (ramGB < 3.0) {
      debugPrint('🔍 [DeviceCapability] Assessment: basic (${ramGB.toStringAsFixed(1)} GB)');
      return DeviceCapability.basic;
    } else if (ramGB < 4.0) {
      debugPrint('🔍 [DeviceCapability] Assessment: standard (${ramGB.toStringAsFixed(1)} GB)');
      return DeviceCapability.standard;
    } else {
      debugPrint('🔍 [DeviceCapability] Assessment: optimal (${ramGB.toStringAsFixed(1)} GB)');
      return DeviceCapability.optimal;
    }
  }

  /// Get the recommended model for this device's capability level.
  Future<GemmaModelInfo> getRecommendedModel() async {
    final capability = await assessCapability();
    switch (capability) {
      case DeviceCapability.incompatible:
        // Return smallest model even though device can't run it;
        // caller should check capability first.
        return GemmaModelInfo.functionGemma270M();
      case DeviceCapability.basic:
        return GemmaModelInfo.functionGemma270M();
      case DeviceCapability.standard:
        return GemmaModelInfo.gemma3n_E2B();
      case DeviceCapability.optimal:
        return GemmaModelInfo.gemma3n_E4B();
    }
  }
}

/// Gemma model variant type
enum GemmaModelType {
  /// FunctionGemma 270M - smallest, fastest, function-calling format
  functionGemma270M,

  /// Gemma 3 1B - medium, good quality with instruction format
  gemma3_1B,

  /// Gemma 3n E2B - mobile-optimized multimodal model
  gemma3n_E2B,

  /// Gemma 3n E4B - best mobile model, full multimodal
  gemma3n_E4B,

  /// EmbeddingGemma 300M - on-device semantic search embeddings
  embeddingGemma300M,
}

/// Information about a specific Gemma model variant.
class GemmaModelInfo {
  final GemmaModelType type;
  final String displayName;
  final String description;
  final int sizeBytes; // Approximate download size
  final double minRamGB;
  final String fileName;
  final bool isMultimodal;
  final int contextLength;

  const GemmaModelInfo({
    required this.type,
    required this.displayName,
    required this.description,
    required this.sizeBytes,
    required this.minRamGB,
    required this.fileName,
    this.isMultimodal = false,
    this.contextLength = 32768,
  });

  /// FunctionGemma 270M - ~200MB, needs 2GB RAM
  factory GemmaModelInfo.functionGemma270M() => const GemmaModelInfo(
        type: GemmaModelType.functionGemma270M,
        displayName: 'FunctionGemma 270M',
        description: 'Lightweight model for basic workout generation. Fast inference, minimal storage.',
        sizeBytes: 200 * 1024 * 1024, // ~200 MB
        minRamGB: 2.0,
        fileName: 'function_gemma_270m.bin',
        isMultimodal: false,
        contextLength: 32768,
      );

  /// Gemma 3 1B - ~700MB, needs 3GB RAM
  factory GemmaModelInfo.gemma3_1B() => const GemmaModelInfo(
        type: GemmaModelType.gemma3_1B,
        displayName: 'Gemma 3 1B',
        description: 'Balanced model for quality workout generation. Good quality with moderate storage.',
        sizeBytes: 700 * 1024 * 1024, // ~700 MB
        minRamGB: 3.0,
        fileName: 'gemma3_1b.bin',
        isMultimodal: false,
        contextLength: 32768,
      );

  /// Gemma 3n E2B - ~3.1GB, needs 2GB RAM (mobile-optimized)
  factory GemmaModelInfo.gemma3n_E2B() => const GemmaModelInfo(
        type: GemmaModelType.gemma3n_E2B,
        displayName: 'Gemma 3n E2B',
        description: 'Mobile-optimized multimodal model. Supports images for exercise form check and food photo recognition.',
        sizeBytes: 3100 * 1024 * 1024, // ~3.1 GB
        minRamGB: 2.0,
        fileName: 'gemma3n_e2b.bin',
        isMultimodal: true,
        contextLength: 32768,
      );

  /// Gemma 3n E4B - ~6.5GB, needs 3GB RAM (best mobile model)
  factory GemmaModelInfo.gemma3n_E4B() => const GemmaModelInfo(
        type: GemmaModelType.gemma3n_E4B,
        displayName: 'Gemma 3n E4B',
        description: 'Best mobile AI model. Full multimodal with highest quality output.',
        sizeBytes: 6500 * 1024 * 1024, // ~6.5 GB
        minRamGB: 3.0,
        fileName: 'gemma3n_e4b.bin',
        isMultimodal: true,
        contextLength: 32768,
      );

  /// EmbeddingGemma 300M - ~200MB, needs 0.5GB RAM
  factory GemmaModelInfo.embeddingGemma300M() => const GemmaModelInfo(
        type: GemmaModelType.embeddingGemma300M,
        displayName: 'EmbeddingGemma 300M',
        description: 'Enables offline semantic search for exercises and food. Very lightweight.',
        sizeBytes: 200 * 1024 * 1024, // ~200 MB
        minRamGB: 0.5,
        fileName: 'embedding_gemma_300m.bin',
        isMultimodal: false,
        contextLength: 2048,
      );

  /// Get model info by type
  factory GemmaModelInfo.fromType(GemmaModelType type) {
    switch (type) {
      case GemmaModelType.functionGemma270M:
        return GemmaModelInfo.functionGemma270M();
      case GemmaModelType.gemma3_1B:
        return GemmaModelInfo.gemma3_1B();
      case GemmaModelType.gemma3n_E2B:
        return GemmaModelInfo.gemma3n_E2B();
      case GemmaModelType.gemma3n_E4B:
        return GemmaModelInfo.gemma3n_E4B();
      case GemmaModelType.embeddingGemma300M:
        return GemmaModelInfo.embeddingGemma300M();
    }
  }

  /// Human-readable file size (e.g., "200 MB", "2.5 GB")
  String get formattedSize {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(sizeBytes / (1024 * 1024)).round()} MB';
  }
}
