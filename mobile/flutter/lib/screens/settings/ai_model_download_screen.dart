import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/device_capability_provider.dart';
import '../../data/providers/model_download_provider.dart';
import '../../services/device_capability_service.dart';
import '../../services/model_download_service.dart';

/// Dedicated screen for managing on-device AI model downloads.
///
/// Shows:
/// - Device capability assessment (RAM, storage)
/// - Model options with recommendations
/// - Download progress
/// - Test generation button
class AiModelDownloadScreen extends ConsumerWidget {
  const AiModelDownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final capabilityAsync = ref.watch(deviceCapabilityProvider);
    final ramAsync = ref.watch(deviceRamProvider);
    final downloadState = ref.watch(modelDownloadProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.background : AppColorsLight.background,
      appBar: AppBar(
        title: const Text('On-Device AI Model'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Device Compatibility ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Device Compatibility',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary)),
                const SizedBox(height: 12),
                ramAsync.when(
                  data: (ram) => _CompatibilityRow(
                    label: 'RAM',
                    value: '${ram.toStringAsFixed(1)} GB',
                    isGood: ram >= 2.0,
                  ),
                  loading: () => const _CompatibilityRow(
                      label: 'RAM', value: 'Checking...', isGood: true),
                  error: (e, _) => _CompatibilityRow(
                      label: 'RAM', value: 'Unknown', isGood: false),
                ),
                const SizedBox(height: 8),
                capabilityAsync.when(
                  data: (cap) {
                    final label = switch (cap) {
                      DeviceCapability.incompatible => 'Not compatible',
                      DeviceCapability.basic => 'Basic (270M + embeddings)',
                      DeviceCapability.standard => 'Standard (up to Gemma 3n E2B)',
                      DeviceCapability.optimal => 'Optimal (all models)',
                    };
                    return _CompatibilityRow(
                      label: 'Capability',
                      value: label,
                      isGood: cap != DeviceCapability.incompatible,
                    );
                  },
                  loading: () => const _CompatibilityRow(
                      label: 'Capability',
                      value: 'Checking...',
                      isGood: true),
                  error: (e, _) => const _CompatibilityRow(
                      label: 'Capability', value: 'Unknown', isGood: false),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Battery / Performance Warning ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.battery_alert_rounded,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'On-device AI models run intensive computations on your phone. '
                    'This may increase battery drain and cause the device to warm up '
                    'during workout generation. Larger models use more resources.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Model Options ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Model Options',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary)),
                const SizedBox(height: 12),

                capabilityAsync.when(
                  data: (cap) => _buildModelList(ref, downloadState, cap),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => _buildModelList(ref, downloadState, DeviceCapability.basic),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Download / Delete ---
          if (downloadState.status == DownloadStatus.downloading) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: downloadState.progress,
                    backgroundColor: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Downloading... ${(downloadState.progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.read(modelDownloadProvider.notifier).cancelDownload(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ] else if (downloadState.status == DownloadStatus.downloaded) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(modelDownloadProvider.notifier).deleteModel(),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(
                        'Delete Model (Free ${downloadState.model?.formattedSize ?? ""})',
                        style: const TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.15),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: downloadState.model != null
                    ? () => ref
                        .read(modelDownloadProvider.notifier)
                        .startDownload()
                    : null,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                    'Download ${downloadState.model?.displayName ?? "Select a model"}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          if (downloadState.error != null) ...[
            const SizedBox(height: 8),
            Text(
              downloadState.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModelList(WidgetRef ref, ModelDownloadState downloadState, DeviceCapability cap) {
    final allModels = [
      (
        type: GemmaModelType.functionGemma270M,
        minCap: DeviceCapability.basic,
        recommended: true,
        badges: const <String>['Recommended'],
      ),
      (
        type: GemmaModelType.gemma3_1B,
        minCap: DeviceCapability.standard,
        recommended: false,
        badges: const <String>[],
      ),
      (
        type: GemmaModelType.gemma3n_E2B,
        minCap: DeviceCapability.standard,
        recommended: false,
        badges: const <String>['Multimodal'],
      ),
      (
        type: GemmaModelType.gemma3n_E4B,
        minCap: DeviceCapability.optimal,
        recommended: false,
        badges: const <String>['Multimodal', 'Best Quality'],
      ),
      (
        type: GemmaModelType.embeddingGemma300M,
        minCap: DeviceCapability.basic,
        recommended: false,
        badges: const <String>['Search'],
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < allModels.length; i++) ...[
          if (i > 0) const Divider(height: 1),
          _buildModelTile(
            ref: ref,
            modelType: allModels[i].type,
            downloadState: downloadState,
            deviceCap: cap,
            minCap: allModels[i].minCap,
            badges: allModels[i].badges,
          ),
        ],
      ],
    );
  }

  Widget _buildModelTile({
    required WidgetRef ref,
    required GemmaModelType modelType,
    required ModelDownloadState downloadState,
    required DeviceCapability deviceCap,
    required DeviceCapability minCap,
    required List<String> badges,
  }) {
    final info = GemmaModelInfo.fromType(modelType);
    final isSupported = deviceCap.index >= minCap.index;
    final isSelected = downloadState.model?.type == modelType;

    return _ModelOptionTile(
      model: modelType,
      name: info.displayName,
      description: info.description,
      size: info.formattedSize,
      minRamGB: info.minRamGB,
      badges: badges,
      isMultimodal: info.isMultimodal,
      isSelected: isSelected,
      isEnabled: isSupported,
      onSelect: isSupported
          ? () => ref.read(modelDownloadProvider.notifier).selectModel(modelType)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Helper Widgets
// ---------------------------------------------------------------------------

class _CompatibilityRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGood;

  const _CompatibilityRow({
    required this.label,
    required this.value,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isGood ? Icons.check_circle_rounded : Icons.warning_rounded,
          color: isGood ? Colors.green : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSecondary
                    : AppColorsLight.textSecondary)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimary
                    : AppColorsLight.textPrimary)),
      ],
    );
  }
}

class _ModelOptionTile extends StatelessWidget {
  final GemmaModelType model;
  final String name;
  final String description;
  final String size;
  final double minRamGB;
  final List<String> badges;
  final bool isMultimodal;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onSelect;

  const _ModelOptionTile({
    required this.model,
    required this.name,
    required this.description,
    required this.size,
    required this.minRamGB,
    this.badges = const [],
    this.isMultimodal = false,
    required this.isSelected,
    this.isEnabled = true,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final opacity = isEnabled ? 1.0 : 0.45;

    final ramLabel = minRamGB == minRamGB.roundToDouble()
        ? '${minRamGB.toInt()} GB'
        : '${minRamGB.toStringAsFixed(1)} GB';

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isSelected ? true : null,
                onChanged: isEnabled ? (_) => onSelect?.call() : null,
                activeColor: AppColors.orange,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary)),
                        ),
                        for (final badge in badges) ...[
                          const SizedBox(width: 6),
                          _BadgeChip(label: badge),
                        ],
                        if (isMultimodal && !badges.contains('Multimodal')) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Images',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(fontSize: 12, color: textMuted)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.memory_rounded,
                            size: 12,
                            color: isEnabled ? textMuted : Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Requires $ramLabel RAM',
                          style: TextStyle(
                            fontSize: 11,
                            color: isEnabled ? textMuted : Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.storage_rounded,
                            size: 12,
                            color: isEnabled ? textMuted : Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '$size storage',
                          style: TextStyle(
                            fontSize: 11,
                            color: isEnabled ? textMuted : Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                    if (!isEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Not supported on this device',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700)),
                      ),
                  ],
                ),
              ),
              Text(size,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;

  const _BadgeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (label) {
      case 'Recommended':
        color = Colors.green;
        break;
      case 'Multimodal':
        color = Colors.blue;
        break;
      case 'Best Quality':
        color = Colors.purple;
        break;
      case 'Search':
        color = Colors.teal;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}
