import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/generation_mode_provider.dart';
import '../../../data/providers/model_download_provider.dart';
import '../../../data/services/offline_media_service.dart';
import '../../../data/services/sync_engine.dart';
import '../../../services/model_download_service.dart';
import '../../../data/services/food_database_service.dart';
import '../../../widgets/sync_status_widget.dart';
import '../ai_model_download_screen.dart';
import '../sync_details_screen.dart';
import '../widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Persistence providers for offline settings
// ---------------------------------------------------------------------------

/// Whether pre-caching is enabled (default: true).
final preCacheEnabledProvider =
    StateNotifierProvider<_BoolPrefNotifier, bool>((ref) {
  return _BoolPrefNotifier('offline_precache_enabled', true);
});

/// Days to pre-cache (default: 7).
final preCacheDaysProvider =
    StateNotifierProvider<_IntPrefNotifier, int>((ref) {
  return _IntPrefNotifier('offline_precache_days', 7);
});

/// Whether exercise details caching is enabled (default: true).
final cacheExerciseDetailsProvider =
    StateNotifierProvider<_BoolPrefNotifier, bool>((ref) {
  return _BoolPrefNotifier('offline_cache_exercise_details', true);
});

/// Whether offline video downloads are enabled (default: false).
final offlineVideoEnabledProvider =
    StateNotifierProvider<_BoolPrefNotifier, bool>((ref) {
  return _BoolPrefNotifier('offline_video_enabled', false);
});

/// Simple bool notifier persisted to SharedPreferences.
class _BoolPrefNotifier extends StateNotifier<bool> {
  final String _key;
  _BoolPrefNotifier(this._key, bool defaultValue) : super(defaultValue) {
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_key);
    if (v != null) state = v;
  }
  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// Simple int notifier persisted to SharedPreferences.
class _IntPrefNotifier extends StateNotifier<int> {
  final String _key;
  _IntPrefNotifier(this._key, int defaultValue) : super(defaultValue) {
    _load();
  }
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_key);
    if (v != null) state = v;
  }
  Future<void> set(int value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }
}

// ---------------------------------------------------------------------------
// Section Widget
// ---------------------------------------------------------------------------

/// The offline mode settings section.
///
/// Contains subsections:
/// 1. Workout Generation Mode (radio tiles)
/// 2. On-Device AI Model Management (conditional)
/// 3. Pre-Cache Settings
/// 4. Video Downloads
/// 5. Sync Status
class OfflineModeSection extends ConsumerWidget {
  const OfflineModeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Workout Generation Mode ---
        const SectionHeader(title: 'WORKOUT GENERATION'),
        const SizedBox(height: 8),
        _GenerationModeSelector(),
        const SizedBox(height: 16),

        // --- Pre-Cache Settings ---
        const SectionHeader(title: 'BACKGROUND SYNC'),
        const SizedBox(height: 8),
        _PreCacheSettings(),
        const SizedBox(height: 16),

        // --- Video Downloads ---
        const SectionHeader(title: 'EXERCISE VIDEOS'),
        const SizedBox(height: 8),
        _VideoDownloadSettings(),
        const SizedBox(height: 16),

        // --- Food Database ---
        const SectionHeader(title: 'FOOD DATABASE'),
        const SizedBox(height: 8),
        _FoodDatabaseSettings(),
        const SizedBox(height: 16),

        // --- Sync Status ---
        const SectionHeader(title: 'SYNC STATUS'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const SyncStatusWidget(),
              Divider(height: 1, indent: 56, color: dividerColor),
              _SyncDetailsLink(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Generation Mode Selector
// ---------------------------------------------------------------------------

class _GenerationModeSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(generationModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _GenerationModeRadioTile(
            icon: Icons.cloud_outlined,
            title: 'Cloud AI',
            subtitle: 'Generates workouts on our servers using advanced AI.\nRequires internet connection.',
            value: WorkoutGenerationMode.cloudAI,
            groupValue: currentMode,
            onChanged: (mode) =>
                ref.read(generationModeProvider.notifier).setMode(mode),
            isFirst: true,
          ),
          Divider(height: 1, indent: 56, color: Colors.white.withOpacity(0.06)),
          _GenerationModeRadioTile(
            icon: Icons.phone_android_outlined,
            title: 'On-Device AI',
            subtitle: 'Runs a small AI model on your phone.\nWorks offline after model download.',
            value: WorkoutGenerationMode.onDeviceAI,
            groupValue: currentMode,
            onChanged: (mode) {
              ref.read(generationModeProvider.notifier).setMode(mode);
              final downloadStatus = ref.read(modelDownloadProvider).status;
              if (downloadStatus != DownloadStatus.downloaded) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AiModelDownloadScreen()),
                );
              }
            },
            trailing: _OnDeviceAIChip(),
            bottom: _OnDeviceSetupAction(),
          ),
          Divider(height: 1, indent: 56, color: Colors.white.withOpacity(0.06)),
          _GenerationModeRadioTile(
            icon: Icons.calculate_outlined,
            title: 'Rule-Based',
            subtitle: 'Uses smart algorithms to create workouts instantly.\nWorks on all devices, no download needed.',
            value: WorkoutGenerationMode.ruleBased,
            groupValue: currentMode,
            onChanged: (mode) =>
                ref.read(generationModeProvider.notifier).setMode(mode),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _GenerationModeRadioTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final WorkoutGenerationMode value;
  final WorkoutGenerationMode groupValue;
  final ValueChanged<WorkoutGenerationMode> onChanged;
  final Widget? trailing;
  final Widget? bottom;
  final bool isFirst;
  final bool isLast;

  const _GenerationModeRadioTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.trailing,
    this.bottom,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? AppColors.orange : textMuted, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: 8),
                            trailing!,
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: textMuted, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Radio<WorkoutGenerationMode>(
                  value: value,
                  groupValue: groupValue,
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                  activeColor: AppColors.orange,
                ),
              ],
            ),
            if (bottom != null && isSelected) ...[
              const SizedBox(height: 8),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Action row shown below On-Device AI when selected and model not ready.
class _OnDeviceSetupAction extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(modelDownloadProvider);

    if (downloadState.status == DownloadStatus.downloaded) {
      return const SizedBox.shrink();
    }

    final String label;
    final IconData icon;

    switch (downloadState.status) {
      case DownloadStatus.downloading:
        label = 'Downloading... ${(downloadState.progress * 100).toInt()}%';
        icon = Icons.sync_rounded;
      case DownloadStatus.failed:
        label = 'Download failed. Tap to retry';
        icon = Icons.refresh_rounded;
      default:
        label = 'Download model to get started';
        icon = Icons.download_rounded;
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AiModelDownloadScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.only(left: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.orange.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.orange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.orange, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Chip showing model status for on-device AI option.
class _OnDeviceAIChip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(modelDownloadProvider);

    final String label;
    final Color bgColor;
    final Color textColor;

    switch (downloadState.status) {
      case DownloadStatus.downloaded:
        label = 'Ready';
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
      case DownloadStatus.downloading:
        label = '${(downloadState.progress * 100).toInt()}%';
        bgColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue;
      case DownloadStatus.notDownloaded:
        label = 'Setup needed';
        bgColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
      case DownloadStatus.failed:
        label = 'Error';
        bgColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
    }

    return GestureDetector(
      onTap: downloadState.status != DownloadStatus.downloaded
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AiModelDownloadScreen()),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pre-Cache Settings
// ---------------------------------------------------------------------------

class _PreCacheSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preCacheEnabled = ref.watch(preCacheEnabledProvider);
    final preCacheDays = ref.watch(preCacheDaysProvider);
    final cacheDetails = ref.watch(cacheExerciseDetailsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SettingSwitchTile(
            icon: Icons.download_done_rounded,
            title: 'Pre-cache upcoming workouts',
            subtitle: 'Downloads your next workouts so they\'re available offline.',
            value: preCacheEnabled,
            onChanged: (v) => ref.read(preCacheEnabledProvider.notifier).set(v),
          ),
          if (preCacheEnabled) ...[
            Divider(height: 1, indent: 56, color: Colors.white.withOpacity(0.06)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded,
                      color: AppColors.cyan, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Days to pre-cache',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColorsLight.textSecondary,
                      ),
                    ),
                  ),
                  DropdownButton<int>(
                    value: preCacheDays,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 14, child: Text('14 days')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(preCacheDaysProvider.notifier).set(v);
                      }
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 1, indent: 56, color: Colors.white.withOpacity(0.06)),
            SettingSwitchTile(
              icon: Icons.library_books_outlined,
              title: 'Cache exercise details',
              subtitle: 'Saves exercise instructions for offline viewing.',
              value: cacheDetails,
              onChanged: (v) =>
                  ref.read(cacheExerciseDetailsProvider.notifier).set(v),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Video Download Settings
// ---------------------------------------------------------------------------

class _VideoDownloadSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoEnabled = ref.watch(offlineVideoEnabledProvider);
    ref.watch(offlineMediaServiceProvider);
    final storageAsync = ref.watch(mediaStorageUsedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SettingSwitchTile(
            icon: Icons.video_library_outlined,
            title: 'Download videos for offline',
            subtitle: 'Downloads exercise demo videos for your upcoming workouts.',
            value: videoEnabled,
            onChanged: (v) =>
                ref.read(offlineVideoEnabledProvider.notifier).set(v),
          ),
          if (videoEnabled) ...[
            Divider(height: 1, indent: 56, color: Colors.white.withOpacity(0.06)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.storage_rounded, color: textMuted, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Storage used: ${storageAsync.maybeWhen(
                        data: (bytes) => _formatBytes(bytes),
                        orElse: () => '...',
                      )} / 500 MB cap',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(offlineMediaServiceProvider.notifier).clearAllMedia(),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
              child: Text(
                'Videos are ~5-10 MB each. A week of workouts uses ~50-200 MB.',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

// ---------------------------------------------------------------------------
// Food Database Settings
// ---------------------------------------------------------------------------

class _FoodDatabaseSettings extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final foodCountStream = ref.watch(foodDatabaseServiceProvider).watchFoodCount();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu_rounded,
                    color: AppColors.cyan, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline food database',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColorsLight.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      StreamBuilder<int>(
                        stream: foodCountStream,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            '$count foods available offline',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, indent: 56, color: Colors.white.withOpacity(0.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 8, 16, 12),
            child: Text(
              'USDA nutrition data is included. Additional foods are cached from online searches.',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sync Details Link
// ---------------------------------------------------------------------------

class _SyncDetailsLink extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncEngineProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ListTile(
      leading: Icon(
        syncState.deadLetterCount > 0
            ? Icons.warning_amber_rounded
            : Icons.info_outline_rounded,
        color: syncState.deadLetterCount > 0 ? Colors.red : textMuted,
        size: 22,
      ),
      title: Text(
        syncState.deadLetterCount > 0
            ? '${syncState.deadLetterCount} item${syncState.deadLetterCount == 1 ? '' : 's'} failed to sync'
            : 'Sync details',
        style: TextStyle(
          fontSize: 14,
          color: syncState.deadLetterCount > 0
              ? Colors.red
              : isDark
                  ? AppColors.textSecondary
                  : AppColorsLight.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SyncDetailsScreen()),
        );
      },
    );
  }
}
