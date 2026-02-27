import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/section_header.dart';

/// The Wear OS section for connecting to smartwatch.
/// Only visible on Android devices.
class WearOSSection extends StatelessWidget {
  const WearOSSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Hide on iOS - WearOS not available
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SectionHeader(title: 'WEAR OS'),
        SizedBox(height: 12),
        _WearOSComingSoonCard(),
      ],
    );
  }
}

/// Card for WearOS feature.
class _WearOSComingSoonCard extends StatelessWidget {
  const _WearOSComingSoonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Watch icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.watch,
                    color: AppColors.cyan,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smartwatch',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track workouts from your wrist',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Feature preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textMuted.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coming features:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureRow(Icons.fitness_center, 'Log sets directly from watch', textMuted),
                  const SizedBox(height: 6),
                  _buildFeatureRow(Icons.favorite, 'Real-time heart rate tracking', textMuted),
                  const SizedBox(height: 6),
                  _buildFeatureRow(Icons.restaurant, 'Quick food logging via voice', textMuted),
                  const SizedBox(height: 6),
                  _buildFeatureRow(Icons.sync, 'Automatic data sync', textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: textColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ORIGINAL IMPLEMENTATION (COMMENTED OUT FOR COMING SOON)
// Uncomment this and remove _WearOSComingSoonCard when ready to launch
// =============================================================================

/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/wearable_service.dart';

/// Provider for watch connection status.
final watchConnectionStatusProvider = FutureProvider.autoDispose<WatchConnectionStatus>((ref) async {
  // Only check on Android
  if (!Platform.isAndroid) {
    return WatchConnectionStatus.noDevice();
  }
  return WearableService.instance.getWatchConnectionStatus();
});

class _WearOSCard extends ConsumerStatefulWidget {
  const _WearOSCard();

  @override
  ConsumerState<_WearOSCard> createState() => _WearOSCardState();
}

class _WearOSCardState extends ConsumerState<_WearOSCard> {
  bool _isInstalling = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final statusAsync = ref.watch(watchConnectionStatusProvider);

    return Container(
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: statusAsync.when(
        loading: () => _buildLoadingState(textMuted),
        error: (_, __) => _buildErrorState(textPrimary, textSecondary, textMuted),
        data: (status) => _buildContent(status, isDark, textPrimary, textSecondary, textMuted),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Checking for watch...',
            style: TextStyle(
              fontSize: 14,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color textPrimary, Color textSecondary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Error',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Could not check watch status',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(watchConnectionStatusProvider),
            icon: Icon(
              Icons.refresh,
              color: textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    WatchConnectionStatus status,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Watch icon with status color
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.watch,
                  color: _getStatusColor(status),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smartwatch',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            color: status.isConnected ? AppColors.success : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Refresh button
              IconButton(
                onPressed: () {
                  HapticService.light();
                  ref.invalidate(watchConnectionStatusProvider);
                },
                icon: Icon(
                  Icons.refresh,
                  color: textSecondary,
                  size: 20,
                ),
                tooltip: 'Refresh status',
              ),
            ],
          ),

          // Show install button if watch detected but app not installed
          if (status.shouldShowInstallPrompt) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isInstalling ? null : _installOnWatch,
                icon: _isInstalling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded, size: 18),
                label: Text(_isInstalling ? 'Opening Play Store...' : 'Install FitWiz on Watch'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: AppColors.cyan.withOpacity(0.5),
                ),
              ),
            ),
          ],

          // Show connected info if fully connected
          if (status.isConnected) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Workouts and data sync automatically',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Show info if no device detected
          if (status.state == WatchConnectionState.noDevice) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pair a Wear OS watch to track workouts from your wrist',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(WatchConnectionStatus status) {
    switch (status.state) {
      case WatchConnectionState.connected:
        return AppColors.success;
      case WatchConnectionState.noApp:
        return AppColors.orange;
      case WatchConnectionState.noDevice:
        return AppColors.textMuted;
      case WatchConnectionState.error:
        return AppColors.error;
    }
  }

  String _getStatusText(WatchConnectionStatus status) {
    switch (status.state) {
      case WatchConnectionState.connected:
        return 'Connected';
      case WatchConnectionState.noApp:
        return 'Watch detected - App not installed';
      case WatchConnectionState.noDevice:
        return 'No watch detected';
      case WatchConnectionState.error:
        return 'Error: ${status.errorMessage ?? "Unknown"}';
    }
  }

  Future<void> _installOnWatch() async {
    HapticService.medium();

    setState(() {
      _isInstalling = true;
    });

    try {
      final success = await WearableService.instance.promptWatchAppInstall();

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening Play Store on your watch...'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
          // Refresh status after a delay to check if installed
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              ref.invalidate(watchConnectionStatusProvider);
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Play Store on watch. Please install manually.'),
              backgroundColor: AppColors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error installing on watch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to watch. Please try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInstalling = false;
        });
      }
    }
  }
}
*/
