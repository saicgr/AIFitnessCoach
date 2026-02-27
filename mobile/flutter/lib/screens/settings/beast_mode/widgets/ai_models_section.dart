import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/providers/device_capability_provider.dart';
import '../../../../data/providers/model_download_provider.dart';
import '../../../../services/device_capability_service.dart';
import '../../../../services/model_download_service.dart';
import '../beast_mode_constants.dart';
import 'shared/beast_card.dart';

/// On-device AI models management — device capability, model library,
/// download/delete, and HuggingFace token input.
class AiModelsSection extends ConsumerStatefulWidget {
  final BeastThemeData theme;

  const AiModelsSection({super.key, required this.theme});

  @override
  ConsumerState<AiModelsSection> createState() => _AiModelsSectionState();
}

class _AiModelsSectionState extends ConsumerState<AiModelsSection> {
  final _tokenController = TextEditingController();
  bool _tokenObscured = true;
  bool _tokenSaved = false;
  bool _tokenLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenState();
  }

  Future<void> _loadTokenState() async {
    final token =
        await ref.read(modelDownloadProvider.notifier).getHuggingFaceToken();
    if (mounted) {
      setState(() {
        _tokenSaved = token != null && token.isNotEmpty;
        _tokenLoading = false;
      });
    }
  }

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    await ref.read(modelDownloadProvider.notifier).setHuggingFaceToken(token);
    _tokenController.clear();
    if (mounted) {
      setState(() => _tokenSaved = true);
    }
  }

  Future<void> _clearToken() async {
    await ref.read(modelDownloadProvider.notifier).clearHuggingFaceToken();
    if (mounted) {
      setState(() => _tokenSaved = false);
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final capabilityAsync = ref.watch(deviceCapabilityProvider);
    final ramAsync = ref.watch(deviceRamProvider);
    final downloadState = ref.watch(modelDownloadProvider);

    return BeastCard(
      theme: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('On-Device AI Models',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary)),
          const SizedBox(height: 4),
          Text('Manage Gemma models for offline workout generation',
              style: TextStyle(fontSize: 11, color: t.textMuted)),
          const SizedBox(height: 16),

          // ── Device Capability Badge ──
          _buildCapabilityBadge(t, capabilityAsync, ramAsync),

          const SizedBox(height: 16),
          Divider(color: t.cardBorder),
          const SizedBox(height: 16),

          // ── Model List ──
          Text('Model Library',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.textPrimary)),
          const SizedBox(height: 8),

          capabilityAsync.when(
            data: (cap) =>
                _buildModelList(t, ref, downloadState, cap),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => _buildModelList(
                t, ref, downloadState, DeviceCapability.basic),
          ),

          // ── Download Progress ──
          if (downloadState.status == DownloadStatus.downloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: downloadState.progress,
              backgroundColor: AppColors.orange.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Downloading... ${(downloadState.progress * 100).toInt()}%',
                  style: TextStyle(fontSize: 11, color: t.textMuted),
                ),
                GestureDetector(
                  onTap: () => ref
                      .read(modelDownloadProvider.notifier)
                      .cancelDownload(),
                  child: Text('Cancel',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (downloadState.progressDisplay.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(downloadState.progressDisplay,
                  style: TextStyle(fontSize: 10, color: t.textMuted)),
            ],
          ],

          // ── Download / Delete Buttons ──
          if (downloadState.status != DownloadStatus.downloading) ...[
            const SizedBox(height: 12),
            if (downloadState.status == DownloadStatus.downloaded)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(modelDownloadProvider.notifier).deleteModel(),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(
                    'Delete Model (Free ${downloadState.model?.formattedSize ?? ""})',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else if (downloadState.model != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => ref
                      .read(modelDownloadProvider.notifier)
                      .startDownload(),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    'Download ${downloadState.model!.displayName}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],

          // ── Error Display ──
          if (downloadState.error != null) ...[
            const SizedBox(height: 8),
            Text(downloadState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],

          const SizedBox(height: 16),
          Divider(color: t.cardBorder),
          const SizedBox(height: 16),

          // ── HuggingFace Token ──
          _buildTokenSection(t),
        ],
      ),
    );
  }

  Widget _buildCapabilityBadge(
    BeastThemeData t,
    AsyncValue<DeviceCapability> capAsync,
    AsyncValue<double> ramAsync,
  ) {
    return capAsync.when(
      data: (cap) {
        final color = switch (cap) {
          DeviceCapability.incompatible => Colors.red,
          DeviceCapability.basic => Colors.amber,
          DeviceCapability.standard => Colors.blue,
          DeviceCapability.optimal => Colors.green,
        };

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.memory_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Device: ${cap.displayName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ramAsync.when(
                          data: (ram) => Text(
                            '${ram.toStringAsFixed(1)} GB RAM',
                            style: TextStyle(fontSize: 11, color: t.textMuted),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cap.description,
                      style: TextStyle(fontSize: 11, color: t.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.cardBorder.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('Checking device capabilities...',
                style: TextStyle(fontSize: 12, color: t.textMuted)),
          ],
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 10),
            Text('Could not detect device capability',
                style: TextStyle(fontSize: 12, color: t.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildModelList(
    BeastThemeData t,
    WidgetRef ref,
    ModelDownloadState downloadState,
    DeviceCapability cap,
  ) {
    final models = [
      (type: GemmaModelType.gemma3_270M, minCap: DeviceCapability.basic, badges: ['Recommended']),
      (type: GemmaModelType.gemma3_1B, minCap: DeviceCapability.standard, badges: <String>[]),
      (type: GemmaModelType.gemma3n_E2B, minCap: DeviceCapability.standard, badges: ['Multimodal']),
      (type: GemmaModelType.gemma3n_E4B, minCap: DeviceCapability.optimal, badges: ['Multimodal', 'Best Quality']),
      (type: GemmaModelType.embeddingGemma300M, minCap: DeviceCapability.basic, badges: ['Search']),
    ];

    return Column(
      children: [
        for (int i = 0; i < models.length; i++) ...[
          if (i > 0) Divider(height: 1, color: t.cardBorder),
          _buildModelTile(t, ref, models[i].type, downloadState, cap,
              models[i].minCap, models[i].badges),
        ],
      ],
    );
  }

  Widget _buildModelTile(
    BeastThemeData t,
    WidgetRef ref,
    GemmaModelType modelType,
    ModelDownloadState downloadState,
    DeviceCapability deviceCap,
    DeviceCapability minCap,
    List<String> badges,
  ) {
    final info = GemmaModelInfo.fromType(modelType);
    final isSupported = deviceCap.index >= minCap.index;
    final isSelected = downloadState.model?.type == modelType;
    final opacity = isSupported ? 1.0 : 0.45;

    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: isSupported
            ? () {
                HapticFeedback.selectionClick();
                ref
                    .read(modelDownloadProvider.notifier)
                    .selectModel(modelType);
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: isSelected ? true : null,
                onChanged:
                    isSupported ? (_) => ref.read(modelDownloadProvider.notifier).selectModel(modelType) : null,
                activeColor: AppColors.orange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(info.displayName,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: t.textPrimary)),
                        ),
                        for (final badge in badges) ...[
                          const SizedBox(width: 4),
                          _BadgeChip(label: badge),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.storage_rounded, size: 10, color: t.textMuted),
                        const SizedBox(width: 3),
                        Text(info.formattedSize,
                            style: TextStyle(fontSize: 10, color: t.textMuted)),
                        const SizedBox(width: 8),
                        Icon(Icons.memory_rounded, size: 10, color: t.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          '${info.minRamGB == info.minRamGB.roundToDouble() ? info.minRamGB.toInt() : info.minRamGB.toStringAsFixed(1)} GB RAM',
                          style: TextStyle(fontSize: 10, color: t.textMuted),
                        ),
                      ],
                    ),
                    if (!isSupported)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('Not supported on this device',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTokenSection(BeastThemeData t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('HuggingFace Token',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary)),
            const SizedBox(width: 8),
            if (_tokenLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_tokenSaved)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 16),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Required to download gated models from HuggingFace.',
          style: TextStyle(fontSize: 11, color: t.textMuted),
        ),
        const SizedBox(height: 10),
        if (_tokenSaved) ...[
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: Colors.green, size: 14),
              const SizedBox(width: 6),
              Text('Token saved securely',
                  style: TextStyle(
                      fontSize: 12,
                      color: t.textPrimary,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              GestureDetector(
                onTap: _clearToken,
                child: Text('Remove',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ] else ...[
          TextField(
            controller: _tokenController,
            obscureText: _tokenObscured,
            style: TextStyle(fontSize: 12, color: t.textPrimary),
            decoration: InputDecoration(
              hintText: 'hf_...',
              hintStyle: TextStyle(color: t.textMuted, fontSize: 12),
              filled: true,
              fillColor: t.isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(
                  _tokenObscured
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 18,
                  color: t.textMuted,
                ),
                onPressed: () =>
                    setState(() => _tokenObscured = !_tokenObscured),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveToken,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child:
                  const Text('Save Token', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse('https://huggingface.co/settings/tokens'),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            'Get token at huggingface.co/settings/tokens',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade400,
              decoration: TextDecoration.underline,
              decorationColor: Colors.blue.shade400,
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  const _BadgeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final Color color = switch (label) {
      'Recommended' => Colors.green,
      'Multimodal' => Colors.blue,
      'Best Quality' => Colors.purple,
      'Search' => Colors.teal,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 8, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
