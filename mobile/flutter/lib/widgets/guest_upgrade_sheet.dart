import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../data/providers/guest_mode_provider.dart';
import '../data/providers/guest_usage_limits_provider.dart';

/// Types of features that can trigger upgrade prompts
enum GuestFeatureLimit {
  chat,
  workout,
  foodScan,
  photoScan,
  barcodeScan,
  textDescribe,
  nutrition,
  progress,
  fasting,
  workoutHistory,
  custom,
}

/// Shows a bottom sheet prompting guest users to sign up when they hit a limit
class GuestUpgradeSheet extends ConsumerWidget {
  final GuestFeatureLimit feature;
  final String? customTitle;
  final String? customMessage;
  final VoidCallback? onDismiss;

  const GuestUpgradeSheet({
    super.key,
    required this.feature,
    this.customTitle,
    this.customMessage,
    this.onDismiss,
  });

  /// Show the upgrade sheet as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    required GuestFeatureLimit feature,
    String? customTitle,
    String? customMessage,
    VoidCallback? onDismiss,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GuestUpgradeSheet(
        feature: feature,
        customTitle: customTitle,
        customMessage: customMessage,
        onDismiss: onDismiss,
      ),
    );
  }

  String _getTitle() {
    if (customTitle != null) return customTitle!;
    switch (feature) {
      case GuestFeatureLimit.chat:
        return 'Daily Chat Limit Reached';
      case GuestFeatureLimit.workout:
        return 'Workout Limit Reached';
      case GuestFeatureLimit.foodScan:
        return 'Scan Limit Reached';
      case GuestFeatureLimit.photoScan:
        return 'Photo Scan Used';
      case GuestFeatureLimit.barcodeScan:
        return 'Barcode Scan Used';
      case GuestFeatureLimit.textDescribe:
        return 'Text Entry Used';
      case GuestFeatureLimit.nutrition:
        return 'Daily Log Limit Reached';
      case GuestFeatureLimit.progress:
        return 'Progress Tracking Locked';
      case GuestFeatureLimit.fasting:
        return 'Fasting Tracker Locked';
      case GuestFeatureLimit.workoutHistory:
        return 'Workout History Locked';
      case GuestFeatureLimit.custom:
        return 'Feature Locked';
    }
  }

  String _getMessage() {
    if (customMessage != null) return customMessage!;
    switch (feature) {
      case GuestFeatureLimit.chat:
        return 'You\'ve used your ${GuestUsageLimits.maxChatMessagesPerDay} free chat messages. Sign up free to continue chatting with your AI coach!';
      case GuestFeatureLimit.workout:
        return 'Guest mode includes ${GuestUsageLimits.maxWorkoutGenerationsTotal} sample workout. Sign up free to generate 4 workouts/month, or go Premium for unlimited!';
      case GuestFeatureLimit.foodScan:
        return 'You\'ve used all your free scans. Sign up free to scan more meals and track nutrition!';
      case GuestFeatureLimit.photoScan:
        return 'You\'ve used your free photo scan. Sign up free to scan unlimited meals!';
      case GuestFeatureLimit.barcodeScan:
        return 'You\'ve used your free barcode scan. Sign up free to scan unlimited products!';
      case GuestFeatureLimit.textDescribe:
        return 'You\'ve used your free text entry. Sign up free for unlimited meal logging!';
      case GuestFeatureLimit.nutrition:
        return 'Guest mode has limited nutrition logging. Sign up free to track all your meals!';
      case GuestFeatureLimit.progress:
        return 'Progress tracking requires an account to save your data. Sign up free to track your fitness journey!';
      case GuestFeatureLimit.fasting:
        return 'Fasting tracker is a Premium feature. Sign up to track your intermittent fasting!';
      case GuestFeatureLimit.workoutHistory:
        return 'Workout history requires an account. Sign up free to save and review all your workouts!';
      case GuestFeatureLimit.custom:
        return 'This feature requires an account. Sign up free to unlock it!';
    }
  }

  IconData _getIcon() {
    switch (feature) {
      case GuestFeatureLimit.chat:
        return Icons.chat_bubble_outline;
      case GuestFeatureLimit.workout:
        return Icons.fitness_center;
      case GuestFeatureLimit.foodScan:
        return Icons.camera_alt_outlined;
      case GuestFeatureLimit.photoScan:
        return Icons.photo_camera_outlined;
      case GuestFeatureLimit.barcodeScan:
        return Icons.qr_code_scanner;
      case GuestFeatureLimit.textDescribe:
        return Icons.edit_note;
      case GuestFeatureLimit.nutrition:
        return Icons.restaurant_menu;
      case GuestFeatureLimit.progress:
        return Icons.insights;
      case GuestFeatureLimit.fasting:
        return Icons.timer_outlined;
      case GuestFeatureLimit.workoutHistory:
        return Icons.history;
      case GuestFeatureLimit.custom:
        return Icons.lock_outline;
    }
  }

  Color _getColor() {
    switch (feature) {
      case GuestFeatureLimit.chat:
        return AppColors.purple;
      case GuestFeatureLimit.workout:
        return AppColors.cyan;
      case GuestFeatureLimit.foodScan:
        return AppColors.orange;
      case GuestFeatureLimit.photoScan:
        return AppColors.orange;
      case GuestFeatureLimit.barcodeScan:
        return AppColors.orange;
      case GuestFeatureLimit.textDescribe:
        return AppColors.orange;
      case GuestFeatureLimit.nutrition:
        return AppColors.green;
      case GuestFeatureLimit.progress:
        return AppColors.teal;
      case GuestFeatureLimit.fasting:
        return AppColors.purple;
      case GuestFeatureLimit.workoutHistory:
        return AppColors.cyan;
      case GuestFeatureLimit.custom:
        return AppColors.cyan;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : Colors.white;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final usage = ref.watch(guestUsageLimitsProvider);
    final accentColor = _getColor();

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 24),

              // Icon with gradient background
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor.withOpacity(0.2), accentColor.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(), color: accentColor, size: 36),
              ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),

              const SizedBox(height: 20),

              // Title
              Text(
                _getTitle(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                _getMessage(),
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Usage stats card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surface : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'YOUR GUEST USAGE TODAY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildUsageStat(
                          'Chats',
                          '${usage.chatMessagesToday}/${GuestUsageLimits.maxChatMessagesPerDay}',
                          usage.isChatLimitReached,
                          AppColors.purple,
                        ),
                        _buildUsageStat(
                          'Workouts',
                          '${usage.workoutGenerationsTotal}/${GuestUsageLimits.maxWorkoutGenerationsTotal}',
                          usage.isWorkoutLimitReached,
                          AppColors.cyan,
                        ),
                        _buildUsageStat(
                          'Scans',
                          '${usage.photoScansTotal + usage.barcodeScansTotal + usage.textDescribeTotal}/3',
                          usage.isPhotoScanLimitReached && usage.isBarcodeScanLimitReached && usage.isTextDescribeLimitReached,
                          AppColors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Benefits list
              _buildBenefitsList(textPrimary),

              const SizedBox(height: 24),

              // Sign Up button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(guestModeProvider.notifier).exitGuestMode(convertedToSignup: true);
                    if (context.mounted) {
                      context.go('/pre-auth-quiz');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Sign Up Free',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Continue as guest button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss?.call();
                },
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageStat(String label, String value, bool isLimitReached, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isLimitReached ? AppColors.error : color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isLimitReached ? AppColors.error : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsList(Color textColor) {
    final benefits = [
      ('Unlimited AI coaching', Icons.chat_bubble_outline),
      ('Personalized workout plans', Icons.fitness_center),
      ('Progress tracking', Icons.trending_up),
      ('Nutrition logging', Icons.restaurant_menu),
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.success,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Icon(benefit.$2, size: 18, color: AppColors.cyan),
              const SizedBox(width: 8),
              Text(
                benefit.$1,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// A small banner widget that shows guest usage remaining
class GuestUsageBanner extends ConsumerWidget {
  const GuestUsageBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    if (!isGuest) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usage = ref.watch(guestUsageLimitsProvider);
    final elevatedColor = isDark ? AppColors.elevated : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Guest Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${usage.remainingChatMessages} chats left',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Sign up free for unlimited access',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              await ref.read(guestModeProvider.notifier).exitGuestMode(convertedToSignup: true);
              if (context.mounted) {
                context.go('/pre-auth-quiz');
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppColors.cyan,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
