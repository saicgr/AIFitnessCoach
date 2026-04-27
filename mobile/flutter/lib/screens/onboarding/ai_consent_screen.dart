import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_links.dart';
import '../../core/services/posthog_service.dart';
import '../../core/providers/window_mode_provider.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/press_and_hold_button.dart';
import 'health_disclaimer_screen.dart';
import 'widgets/foldable_quiz_scaffold.dart';

/// Key used to store AI consent acceptance in SharedPreferences
const String kAiConsentAcceptedKey = 'ai_consent_accepted';

/// Provider that tracks whether the user has accepted AI consent.
/// Initialized from SharedPreferences on first read.
final aiConsentProvider = StateNotifierProvider<AiConsentNotifier, bool>((ref) {
  return AiConsentNotifier();
});

class AiConsentNotifier extends StateNotifier<bool> {
  /// True once SharedPreferences has been read.
  /// The router uses this to avoid routing to /ai-consent based on the
  /// default false value before the real value has loaded.
  bool isLoaded = false;

  AiConsentNotifier() : super(false) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(kAiConsentAcceptedKey) ?? false;
    isLoaded = true;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kAiConsentAcceptedKey, true);
    state = true;
    isLoaded = true;
  }
}

/// AI Consent Screen - Shown during onboarding after personal info, before coach selection.
/// Covers both data privacy and health & safety disclaimer in one screen.
class AiConsentScreen extends ConsumerStatefulWidget {
  const AiConsentScreen({super.key});

  @override
  ConsumerState<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends ConsumerState<AiConsentScreen> {
  void _onConfirmed() async {
    try {
      await ref.read(aiConsentProvider.notifier).accept();
      await ref.read(healthDisclaimerProvider.notifier).accept();
      debugPrint('User accepted privacy & health disclaimer');

      // Track AI consent acceptance
      ref.read(posthogServiceProvider).capture(
        eventName: 'onboarding_ai_consent_decision',
        properties: {'accepted': true},
      );

      if (mounted) {
        context.go('/coach-selection');
      }
    } catch (e) {
      debugPrint('Error saving consent: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

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
          child: FoldableQuizScaffold(
            headerTitle: 'Privacy & Safety',
            headerSubtitle: 'How we protect you and your data',
            headerExtra: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 26),
            ),
            headerOverlay: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GlassBackButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/training-split');
                      },
                    ),
                  ),
                  _buildProgressIndicator(isDark),
                ],
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Show header inline only on phone
                  Consumer(builder: (context, ref, _) {
                    final windowState = ref.watch(windowModeProvider);
                    if (FoldableQuizScaffold.shouldUseFoldableLayout(windowState)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildHeader(isDark, textPrimary, textSecondary),
                    );
                  }),

                  // --- Privacy section ---
                  const SizedBox(height: 12),
                  _buildSectionLabel('Your Data', Icons.lock_outline, isDark ? AppColors.cyan : AppColorsLight.cyan, isDark, textPrimary, 0),
                  const SizedBox(height: 10),
                  _buildCompactPoint(
                    icon: Icons.cloud_sync_outlined,
                    text: 'Your chats, food photos, and form videos are sent securely to models that generate personalized guidance',
                    delay: 50,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.lock_outline,
                    text: 'Encrypted in transit and at rest; access is restricted to the services needed to run the app',
                    delay: 100,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.history_toggle_off_outlined,
                    text: 'Chat history kept up to 12 months, then automatically deleted. Export or delete anytime.',
                    delay: 150,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.block_outlined,
                    text: 'Never sold to third parties, never used for advertising, never used to train outside models',
                    delay: 175,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                  ),

                  // --- Health & Safety section ---
                  const SizedBox(height: 18),
                  _buildSectionLabel('Health & Safety', Icons.health_and_safety_outlined, isDark ? AppColors.warning : AppColorsLight.warning, isDark, textPrimary, 200),
                  const SizedBox(height: 10),
                  _buildCompactPoint(
                    icon: Icons.phone_android_outlined,
                    text: 'Not a medical device or substitute for professional advice',
                    delay: 250,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.warning : AppColorsLight.warning,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.medical_services_outlined,
                    text: 'Consult your doctor before starting any exercise program',
                    delay: 300,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.warning : AppColorsLight.warning,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.hearing_outlined,
                    text: 'Stop if you feel pain or dizziness — AI Chat is always available',
                    delay: 350,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.warning : AppColorsLight.warning,
                  ),
                  const SizedBox(height: 8),
                  _buildCompactPoint(
                    icon: Icons.accessibility_new_outlined,
                    text: 'Workouts adapt to your injuries and limitations automatically',
                    delay: 375,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    accentColor: isDark ? AppColors.warning : AppColorsLight.warning,
                  ),

                  // Links row
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLink('Privacy Details', () {
                        HapticFeedback.selectionClick();
                        context.push('/settings/ai-data-usage');
                      }, isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('·', style: TextStyle(color: textSecondary, fontSize: 14)),
                      ),
                      _buildLink('Full Disclaimer', () {
                        HapticFeedback.selectionClick();
                        launchUrl(Uri.parse('${AppLinks.website}/health-disclaimer'), mode: LaunchMode.externalApplication);
                      }, isDark),
                    ],
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            button: _buildBottomButton(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cyan : AppColorsLight.cyan,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy & Safety',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'How we protect you and your data',
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn().slideY(begin: -0.1),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    const orange = Color(0xFFF97316);
    final inactiveColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    const currentStep = 3; // Privacy is step 4 (0-based: 3)

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _buildStepDot(1, 'Sign In', true, orange, isDark, 0),
          _buildProgressLine(0, currentStep, orange, inactiveColor, 1),
          _buildStepDot(2, 'About You', true, orange, isDark, 2),
          _buildProgressLine(1, currentStep, orange, inactiveColor, 3),
          _buildStepDot(3, 'Split', true, orange, isDark, 4),
          _buildProgressLine(2, currentStep, orange, inactiveColor, 5),
          _buildStepDot(4, 'Privacy', true, orange, isDark, 6),
          _buildProgressLine(3, currentStep, orange, inactiveColor, 7),
          _buildStepDot(5, 'Coach', false, orange, isDark, 8),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int segmentIndex, int currentStep, Color activeColor, Color inactiveColor, int animOrder) {
    final isComplete = segmentIndex < currentStep;
    final delay = 100 + (animOrder * 80);

    return Expanded(
      child: Container(
        height: 2,
        color: inactiveColor,
        child: isComplete
            ? Container(height: 2, color: activeColor)
                .animate()
                .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft,
                    delay: Duration(milliseconds: delay), duration: 300.ms,
                    curve: Curves.easeOut)
            : null,
      ),
    );
  }

  Widget _buildStepDot(int step, String label, bool isComplete, Color activeColor, bool isDark, int animOrder) {
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final delay = 100 + (animOrder * 80);

    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isComplete ? activeColor : (isDark ? AppColors.glassSurface : AppColorsLight.glassSurface),
            shape: BoxShape.circle,
            border: Border.all(
              color: isComplete ? activeColor : (isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              width: 2,
            ),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                    ),
                  ),
          ),
        ).animate()
         .scaleXY(begin: 0, end: 1, delay: Duration(milliseconds: delay), duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isComplete ? activeColor : textSecondary,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, Color color, bool isDark, Color textPrimary, int delay) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }

  Widget _buildCompactPoint({
    required IconData icon,
    required String text,
    required int delay,
    required bool isDark,
    required Color textPrimary,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + delay)).slideX(begin: 0.03);
  }

  Widget _buildLink(String label, VoidCallback onTap, bool isDark) {
    final linkColor = isDark ? AppColors.cyan : AppColorsLight.cyan;
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: linkColor,
          decoration: TextDecoration.underline,
          decorationColor: linkColor,
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite).withValues(alpha: 0),
            isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: PressAndHoldButton(
          label: 'Hold to Agree',
          onConfirmed: _onConfirmed,
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
      ),
    );
  }
}
