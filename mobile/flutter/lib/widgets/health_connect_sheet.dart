import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../data/services/haptic_service.dart';
import '../data/services/health_service.dart';
import 'glass_sheet.dart';
import 'sheet_header.dart';

/// SharedPreferences key for tracking when the user last dismissed this sheet.
const _kDismissedAtKey = 'health_connect_dismissed_at';

/// Duration before the auto-show prompt reappears after dismissal.
const _kSuppressDuration = Duration(days: 7);

/// Returns true if the popup is currently suppressed (dismissed within 7 days).
Future<bool> isHealthConnectPopupSuppressed() async {
  final prefs = await SharedPreferences.getInstance();
  final dismissedAt = prefs.getInt(_kDismissedAtKey);
  if (dismissedAt == null) return false;
  final dismissedTime = DateTime.fromMillisecondsSinceEpoch(dismissedAt);
  return DateTime.now().difference(dismissedTime) < _kSuppressDuration;
}

/// Stores the current timestamp as the dismissal time.
Future<void> _markDismissed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kDismissedAtKey, DateTime.now().millisecondsSinceEpoch);
}

/// Shows the Health Connect / Apple Health connection bottom sheet.
Future<void> showHealthConnectSheet(BuildContext context, WidgetRef ref) {
  return showGlassSheet(
    context: context,
    builder: (ctx) => GlassSheet(
      showHandle: true,
      child: _HealthConnectSheetContent(parentRef: ref),
    ),
  );
}

class _HealthConnectSheetContent extends StatefulWidget {
  final WidgetRef parentRef;

  const _HealthConnectSheetContent({required this.parentRef});

  @override
  State<_HealthConnectSheetContent> createState() =>
      _HealthConnectSheetContentState();
}

class _HealthConnectSheetContentState
    extends State<_HealthConnectSheetContent> {
  bool _isConnecting = false;
  bool _isSuccess = false;
  String? _error;

  Future<void> _handleConnect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final notifier = widget.parentRef.read(healthSyncProvider.notifier);
      final connected = await notifier.connect();

      if (!mounted) return;

      if (connected) {
        setState(() {
          _isConnecting = false;
          _isSuccess = true;
        });
        HapticService.success();
        // Pop after a brief delay to show success state
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _isConnecting = false;
          _error = 'Permissions not granted. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _error = 'Failed to connect. Please try again.';
      });
    }
  }

  void _handleDismiss() {
    HapticService.light();
    _markDismissed();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final platformName =
        Platform.isAndroid ? 'Health Connect' : 'Apple Health';
    final platformIcon =
        Platform.isAndroid ? Icons.monitor_heart_outlined : Icons.favorite;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        SheetHeader(
          icon: Icons.monitor_heart_outlined,
          iconColor: AppColors.green,
          title: 'Connect Health',
          showHandle: false, // GlassSheet already shows handle
          onClose: _handleDismiss,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Description
              Text(
                'Sync your health data for personalized fitness insights',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              // Platform badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(platformIcon, size: 18, color: AppColors.green),
                    const SizedBox(width: 8),
                    Text(
                      platformName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Benefits list
              _BenefitRow(
                icon: Icons.directions_walk,
                text: 'Steps & distance tracking',
                textColor: textPrimary,
              ),
              const SizedBox(height: 10),
              _BenefitRow(
                icon: Icons.favorite,
                text: 'Heart rate monitoring',
                textColor: textPrimary,
              ),
              const SizedBox(height: 10),
              _BenefitRow(
                icon: Icons.bedtime_outlined,
                text: 'Sleep tracking',
                textColor: textPrimary,
              ),
              const SizedBox(height: 10),
              _BenefitRow(
                icon: Icons.fitness_center,
                text: 'Workout sync',
                textColor: textPrimary,
              ),

              const SizedBox(height: 24),

              // Success message
              if (_isSuccess)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Connected successfully!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),

              // Error message with retry
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleConnect,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Connect button (shown when not success and no error)
              if (!_isSuccess && _error == null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isConnecting ? null : _handleConnect,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.accent : AppColorsLight.accent,
                      foregroundColor: isDark
                          ? AppColors.accentContrast
                          : AppColorsLight.accentContrast,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isConnecting
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isDark
                                  ? AppColors.accentContrast
                                  : AppColorsLight.accentContrast,
                            ),
                          )
                        : const Text(
                            'Connect',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: _handleDismiss,
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
              ],

              // Bottom safe area padding
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color textColor;

  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.green),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
