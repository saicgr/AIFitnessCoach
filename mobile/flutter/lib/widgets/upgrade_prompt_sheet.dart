import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/usage_tracking_provider.dart';

/// Display names for known feature keys.
const _featureDisplayNames = <String, String>{
  'food_scanning': 'Food Scans',
  'ai_workout_generation': 'AI Workouts',
  'text_to_calories': 'Text-to-Calories',
};

/// Shows a glass-morphic bottom sheet when a feature's free limit is reached.
void showUpgradePromptSheet(
  BuildContext context, {
  required String featureKey,
  String? featureName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _UpgradePromptContent(
      featureKey: featureKey,
      featureName:
          featureName ?? _featureDisplayNames[featureKey] ?? featureKey,
    ),
  );
}

class _UpgradePromptContent extends ConsumerStatefulWidget {
  final String featureKey;
  final String featureName;

  const _UpgradePromptContent({
    required this.featureKey,
    required this.featureName,
  });

  @override
  ConsumerState<_UpgradePromptContent> createState() =>
      _UpgradePromptContentState();
}

class _UpgradePromptContentState extends ConsumerState<_UpgradePromptContent> {
  Timer? _countdownTimer;
  Duration _timeUntilReset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initCountdown();
  }

  void _initCountdown() {
    final state = ref.read(usageTrackingProvider);
    final feature = state.limits[widget.featureKey];
    if (feature?.resetsAt != null) {
      _timeUntilReset = feature!.resetsAt!.difference(DateTime.now());
      if (_timeUntilReset.isNegative) _timeUntilReset = Duration.zero;

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _timeUntilReset = feature.resetsAt!.difference(DateTime.now());
          if (_timeUntilReset.isNegative) {
            _timeUntilReset = Duration.zero;
            _countdownTimer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final hasCountdown = _timeUntilReset > Duration.zero;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lock icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.orange : AppColorsLight.orange)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 28,
                      color:
                          isDark ? AppColors.orange : AppColorsLight.orange,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Limit Reached',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColorsLight.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    "You've used all free ${widget.featureName} for this period.",
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColorsLight.textSecondary,
                    ),
                  ),

                  // Countdown timer
                  if (hasCountdown) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.glassSurface
                            : AppColorsLight.glassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.cardBorder
                              : AppColorsLight.cardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColorsLight.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Resets in ${_formatDuration(_timeUntilReset)}',
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColorsLight.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push('/paywall');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? AppColors.orange : AppColorsLight.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'See Premium Plans',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dismiss
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColorsLight.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
