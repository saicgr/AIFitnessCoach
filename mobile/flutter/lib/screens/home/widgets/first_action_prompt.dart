import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/chrome_constants.dart'
    show kFloatCircleDiameter, kFabClusterEdgeInset;
import '../../../core/services/posthog_service.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/theme_colors.dart';
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
        ThemeColors.of(context).textPrimary;
    final textSecondary =
        ThemeColors.of(context).textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            AppColors.onboardingAccent.withValues(alpha: 0.18),
            const Color(0xFFFF6B00).withValues(alpha: 0.10),  // accent-allowlist: onboarding funnel's own fixed branding gradient (partner stop of AppColors.onboardingAccent), not the live app accent
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
                AppLocalizations.of(context).quizPersonalizationGateQuickStart,
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
            AppLocalizations.of(context).firstActionPromptPickOneTakesUnder,
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
            iconColor: context.accentColor,
            label: 'Log a meal',
            detail: 'Type what you ate. Macros appear instantly.',
            onTap: () => _trigger('log_meal', '/log-meal'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.favorite_rounded,
            iconColor: context.accentColor,
            label: 'Connect Apple Health',
            detail: AppLocalizations.of(context).firstActionPromptPullInYourActivity,
            onTap: () => _trigger('connect_health', '/health-connect-setup'),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _ActionRow(
            icon: Icons.chat_bubble_rounded,
            iconColor: context.accentColor,
            label: 'Say hi to your coach',
            detail: AppLocalizations.of(context).firstActionPromptTheyHaveAMessage,
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
        ThemeColors.of(context).textPrimary;
    final textSecondary =
        ThemeColors.of(context).textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // On a brand-new account Home has almost no other content, so this
        // card (and whichever of its three rows the viewport happens to end
        // on) can sit right at the bottom of the screen — directly under
        // the fixed bottom-right coach + Quick Log FAB cluster, which floats
        // independent of scroll position. Right-inset each row so its label
        // and arrow are never covered by it.
        padding: const EdgeInsetsDirectional.fromSTEB(
          12,
          10,
          12 + kFloatCircleDiameter + kFabClusterEdgeInset,
          10,
        ),
        decoration: BoxDecoration(
          color: ThemeColors.of(context)
              .background
              .withValues(alpha: isDark ? 0.4 : 0.6),
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
