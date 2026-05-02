import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/posthog_service.dart';

/// First Action Prompt — Onboarding v5 (Day 0 activation)
///
/// Shown ONCE on first home-screen load after signup. Surfaces a single
/// quick win the user can complete in <60 seconds:
///   - Log breakfast (text parse — works anywhere)
///   - Connect Apple Health
///   - Reply to coach welcome message
///
/// Activation research: users who complete one meaningful action in their
/// first session convert 2.3x higher than those who don't. This prompt is
/// the highest-leverage single addition to the onboarding flow.
///
/// Idempotency: persisted via `seen_first_action_prompt` SharedPref.
class FirstActionPrompt extends ConsumerStatefulWidget {
  const FirstActionPrompt({super.key});

  static const String _seenKey = 'seen_first_action_prompt';

  static Future<bool> _shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_seenKey) ?? false);
  }

  static Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  ConsumerState<FirstActionPrompt> createState() => _FirstActionPromptState();
}

class _FirstActionPromptState extends ConsumerState<FirstActionPrompt> {
  bool _shouldShow = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final show = await FirstActionPrompt._shouldShow();
    if (mounted) {
      setState(() {
        _shouldShow = show;
        _checked = true;
      });
    }
  }

  Future<void> _dismiss() async {
    HapticFeedback.lightImpact();
    await FirstActionPrompt._markSeen();
    ref.read(posthogServiceProvider).capture(
          eventName: 'first_action_prompt_dismissed',
        );
    if (mounted) setState(() => _shouldShow = false);
  }

  Future<void> _trigger(String action, String route) async {
    HapticFeedback.mediumImpact();
    await FirstActionPrompt._markSeen();
    ref.read(posthogServiceProvider).capture(
          eventName: 'first_action_prompt_triggered',
          properties: {'action': action},
        );
    if (mounted) {
      setState(() => _shouldShow = false);
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_shouldShow) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.onboardingAccent.withValues(alpha: 0.18),
            const Color(0xFFFF6B00).withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.onboardingAccent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded,
                  color: AppColors.onboardingAccent, size: 20),
              const SizedBox(width: 6),
              Text(
                'Quick start',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onboardingAccent,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _dismiss,
                child: Icon(Icons.close_rounded,
                    color: textSecondary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pick one — takes under a minute.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              height: 1.3,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 14),
          _ActionRow(
            icon: Icons.restaurant_rounded,
            iconColor: const Color(0xFF2ECC71),
            label: 'Log a meal',
            detail: 'Type what you ate. Macros appear instantly.',
            onTap: () => _trigger('log_meal', '/log-meal'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFE74C3C),
            label: 'Connect Apple Health',
            detail: 'Pull in your activity, sleep, weight history.',
            onTap: () => _trigger('connect_health', '/health-connect-setup'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.chat_bubble_rounded,
            iconColor: const Color(0xFF9B59B6),
            label: 'Say hi to your coach',
            detail: 'They have a message waiting for you.',
            onTap: () => _trigger('coach_chat', '/chat'),
            isDark: isDark,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String detail;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.detail,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.pureBlack.withValues(alpha: 0.4)
              : AppColorsLight.pureWhite.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}
