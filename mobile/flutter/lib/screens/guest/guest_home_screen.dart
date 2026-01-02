import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/providers/guest_mode_provider.dart';
import '../../data/services/haptic_service.dart';
import 'widgets/guest_sample_workout_card.dart';
import 'widgets/guest_locked_feature_card.dart';
import 'widgets/guest_sign_up_banner.dart';
import 'widgets/guest_session_timer.dart';

/// Guest home screen showing limited app features for preview
/// Allows users to explore the app before creating an account
class GuestHomeScreen extends ConsumerStatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen> {
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();
    _startSessionCheck();
  }

  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    super.dispose();
  }

  void _startSessionCheck() {
    _sessionCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkSessionStatus(),
    );
  }

  void _checkSessionStatus() {
    final guestState = ref.read(guestModeProvider);

    // Check if warning should be shown
    if (guestState.shouldShowSessionWarning) {
      ref.read(guestModeProvider.notifier).markWarningShown();
      _showSessionWarningDialog();
    }

    // Check if session expired
    if (guestState.isSessionExpired) {
      _showSessionExpiredDialog();
    }
  }

  void _showSessionWarningDialog() {
    final remaining = ref.read(guestSessionRemainingProvider);
    final minutes = remaining.inMinutes;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return AlertDialog(
          backgroundColor: elevatedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer, color: AppColors.warning, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Session Ending Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your guest preview session expires in $minutes ${minutes == 1 ? 'minute' : 'minutes'}.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign up free to continue using all features without limits!',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continue Preview',
                style: TextStyle(color: textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToSignUp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Up Free',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return AlertDialog(
          backgroundColor: elevatedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  color: AppColors.cyan,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enjoying the Preview?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your 10-minute preview session has ended.',
                style: TextStyle(
                  fontSize: 15,
                  color: textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign up free to unlock all features and start your fitness journey!',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildBenefitsList(textPrimary),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToSignUp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Up Free',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBenefitsList(Color textPrimary) {
    final benefits = [
      'Personalized AI Workout Plans',
      'Nutrition Tracking',
      'Progress Analytics',
      'AI Coach Chat 24/7',
    ];

    return Column(
      children: benefits
          .map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  void _navigateToSignUp() async {
    await ref.read(guestModeProvider.notifier).exitGuestMode(convertedToSignup: true);
    if (mounted) {
      context.go('/sign-in');
    }
  }

  void _showLockedFeatureDialog(String featureName) {
    ref.read(guestModeProvider.notifier).trackFeatureAttempt(featureName);

    final displayName = GuestModeFeatures.featureDisplayNames[featureName] ?? featureName;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
        final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

        return AlertDialog(
          backgroundColor: elevatedColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock, color: AppColors.purple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This feature requires a free account. Sign up to unlock $displayName and all other premium features!',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToSignUp();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Up Free',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with Guest Badge
            SliverToBoxAdapter(
              child: _buildHeader(context, isDark, textPrimary, textSecondary),
            ),

            // Session Timer Banner
            const SliverToBoxAdapter(
              child: GuestSessionTimer(),
            ),

            // Sign Up Banner (persistent)
            SliverToBoxAdapter(
              child: GuestSignUpBanner(
                onSignUp: _navigateToSignUp,
              ),
            ),

            // Section: PREVIEW
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'PREVIEW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            // Sample Workout Card
            const SliverToBoxAdapter(
              child: GuestSampleWorkoutCard(),
            ),

            // Exercise Library Quick Access
            SliverToBoxAdapter(
              child: _buildExerciseLibraryCard(isDark, textPrimary, textSecondary),
            ),

            // Section: LOCKED FEATURES
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'FULL ACCESS FEATURES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FREE WITH SIGNUP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Locked Features Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final features = [
                      ('ai_coach_chat', Icons.chat_bubble_outline, 'AI Coach Chat'),
                      ('nutrition_tracking', Icons.restaurant_menu, 'Nutrition'),
                      ('progress_analytics', Icons.insights, 'Analytics'),
                      ('workout_generation', Icons.auto_awesome, 'AI Workouts'),
                    ];
                    final feature = features[index];
                    return GuestLockedFeatureCard(
                      featureId: feature.$1,
                      icon: feature.$2,
                      title: feature.$3,
                      onTap: () => _showLockedFeatureDialog(feature.$1),
                    ).animate().fadeIn(
                          delay: Duration(milliseconds: 100 * index),
                          duration: const Duration(milliseconds: 300),
                        );
                  },
                  childCount: 4,
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Guest Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.purple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.purple,
              size: 24,
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
                      'Welcome, Guest',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PREVIEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Explore what FitWiz can do',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Exit Guest Mode button
          Material(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () async {
                HapticService.light();
                await ref.read(guestModeProvider.notifier).exitGuestMode();
                if (mounted) {
                  context.go('/stats-welcome');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.close,
                  color: textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseLibraryCard(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final borderColor = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            HapticService.light();
            context.push('/guest-library');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.cyan,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exercise Library',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Preview 20 exercises',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '1700+ with signup',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }
}
