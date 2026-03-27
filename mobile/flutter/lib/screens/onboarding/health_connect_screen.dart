import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../data/services/health_service.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';

/// SharedPreferences key for tracking when the user skips health connect
/// during onboarding.
const String kHealthConnectSkippedOnboardingKey =
    'health_connect_skipped_onboarding';

/// Health Connect / Apple Health onboarding screen.
///
/// Prompts users to connect their platform health service for richer AI
/// coaching. Appears after the accuracy-intro screen and before
/// feature-showcase.
class HealthConnectScreen extends ConsumerStatefulWidget {
  const HealthConnectScreen({super.key});

  @override
  ConsumerState<HealthConnectScreen> createState() =>
      _HealthConnectScreenState();
}

class _HealthConnectScreenState extends ConsumerState<HealthConnectScreen> {
  bool _isConnecting = false;
  bool _isSuccess = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Check if already connected from a previous session or earlier in this flow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final syncState = ref.read(healthSyncProvider);
      if (syncState.isConnected) {
        setState(() => _isSuccess = true);
      }
    });
  }

  // ---------- actions ----------

  Future<void> _handleConnect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final connected = await ref.read(healthSyncProvider.notifier).connect();

      if (!mounted) return;

      if (connected) {
        setState(() {
          _isConnecting = false;
          _isSuccess = true;
        });
        HapticService.success();

        // Track health connect decision
        ref.read(posthogServiceProvider).capture(
          eventName: 'onboarding_health_connect_decision',
          properties: {'connected': true},
        );

        // Brief pause so the user can see the success state before navigating.
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/feature-showcase');
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

  Future<void> _handleSkip() async {
    HapticService.light();

    // Track health connect skipped
    ref.read(posthogServiceProvider).capture(
      eventName: 'onboarding_health_connect_decision',
      properties: {'connected': false},
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHealthConnectSkippedOnboardingKey, true);
    if (mounted) context.go('/feature-showcase');
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final greenAccent = isDark ? AppColors.green : AppColorsLight.green;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.pureBlack,
                    AppColors.pureBlack.withValues(alpha: 0.95),
                    const Color(0xFF0D0D1A),
                  ]
                : [
                    AppColorsLight.pureWhite,
                    AppColorsLight.pureWhite.withValues(alpha: 0.95),
                    const Color(0xFFF5F5FA),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GlassBackButton(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go('/accuracy-intro');
                    },
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // --- Hero icon ---
                      _buildHeroIcon(isDark, greenAccent),

                      const SizedBox(height: 24),

                      // --- Title ---
                      Text(
                        'Sync Your Health Data',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.08),

                      const SizedBox(height: 8),

                      Text(
                        'Get more accurate coaching with real data',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: textSecondary,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms),

                      const SizedBox(height: 20),

                      // --- Platform badge ---
                      _buildPlatformBadge(
                          isDark, textPrimary, greenAccent),

                      const SizedBox(height: 28),

                      // --- Benefits list ---
                      _buildBenefitRow(
                        icon: Icons.directions_walk,
                        text: 'Auto-track steps & calories',
                        delay: 400,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        accentColor: greenAccent,
                      ),
                      const SizedBox(height: 10),
                      _buildBenefitRow(
                        icon: Icons.fitness_center,
                        text: 'Import workouts from other apps',
                        delay: 480,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        accentColor: greenAccent,
                      ),
                      const SizedBox(height: 10),
                      _buildBenefitRow(
                        icon: Icons.favorite,
                        text: 'See heart rate during workouts',
                        delay: 560,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        accentColor: greenAccent,
                      ),
                      const SizedBox(height: 10),
                      _buildBenefitRow(
                        icon: Icons.auto_awesome,
                        text: 'Better AI coaching with your real data',
                        delay: 640,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        accentColor: greenAccent,
                      ),

                      const SizedBox(height: 28),

                      // --- Social proof chip ---
                      _buildSocialProofChip(isDark, greenAccent),

                      const SizedBox(height: 16),

                      // --- Error message ---
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
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
                        ).animate().fadeIn().shake(hz: 2, offset: const Offset(2, 0)),
                        const SizedBox(height: 16),
                      ],

                      // --- Success message ---
                      if (_isSuccess)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: greenAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: greenAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Connected successfully!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: greenAccent,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().scaleXY(begin: 0.95),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // --- Bottom buttons ---
              _buildBottomButtons(isDark, textSecondary, greenAccent),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- sub-widgets ----------

  Widget _buildHeroIcon(bool isDark, Color greenAccent) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            greenAccent,
            greenAccent.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: greenAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.monitor_heart_outlined,
        color: Colors.white,
        size: 40,
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scaleXY(begin: 0.7, end: 1.0, curve: Curves.easeOutBack);
  }

  Widget _buildPlatformBadge(
      bool isDark, Color textPrimary, Color greenAccent) {
    final platformName =
        Platform.isAndroid ? 'Google Health Connect' : 'Apple Health';
    final platformIcon =
        Platform.isAndroid ? Icons.monitor_heart_outlined : Icons.favorite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(platformIcon, size: 18, color: greenAccent),
          const SizedBox(width: 8),
          Text(
            platformName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms).scaleXY(begin: 0.9);
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String text,
    required int delay,
    required bool isDark,
    required Color textPrimary,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.04);
  }

  Widget _buildSocialProofChip(bool isDark, Color greenAccent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: greenAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: greenAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, size: 20, color: greenAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Users who sync health data are 2x more likely to hit their goals',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: greenAccent,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 720.ms)
        .slideY(begin: 0.06);
  }

  Widget _buildBottomButtons(
      bool isDark, Color textSecondary, Color greenAccent) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite)
                .withValues(alpha: 0),
            isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary button: Connect Now or Continue (if already connected)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      greenAccent,
                      greenAccent.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: greenAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: _isConnecting
                      ? null
                      : _isSuccess
                          ? () {
                              HapticFeedback.mediumImpact();
                              context.go('/feature-showcase');
                            }
                          : _handleConnect,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isConnecting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : _isSuccess
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Connected — Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Connect Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 800.ms)
                .slideY(begin: 0.1),

            const SizedBox(height: 8),

            // Secondary: Maybe Later (hidden when already connected)
            if (!_isSuccess)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: _isConnecting ? null : _handleSkip,
                  child: Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }
}
